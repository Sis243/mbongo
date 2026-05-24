<?php
defined('ABSPATH') || exit;

/**
 * Handles incoming webhooks from Mbongo backend.
 * Register your webhook URL in Mbongo Gateway settings:
 * https://yoursite.com/wp-json/mbongo/v1/webhook
 */
class Mbongo_Webhook {

    public static function init(): void {
        add_action('rest_api_init', [self::class, 'register_routes']);
    }

    public static function register_routes(): void {
        register_rest_route('mbongo/v1', '/webhook', [
            'methods'             => 'POST',
            'callback'            => [self::class, 'handle'],
            'permission_callback' => '__return_true',
        ]);
    }

    public static function handle(WP_REST_Request $request): WP_REST_Response {
        $gateway = new WC_Gateway_Mbongo();
        $secret  = $gateway->get_option('webhook_secret');

        // Verify signature if secret is set
        if (!empty($secret)) {
            $sig = $request->get_header('x-mbongo-signature')
                ?? $request->get_header('x-signature')
                ?? '';

            if (!Mbongo_API::verify_signature($request->get_body(), $sig, $secret)) {
                return new WP_REST_Response(['error' => 'Invalid signature'], 401);
            }
        }

        $payload = $request->get_json_params();
        $event   = $payload['event'] ?? $payload['type'] ?? '';
        $data    = $payload['data'] ?? $payload;

        self::process_event($event, $data);

        return new WP_REST_Response(['received' => true], 200);
    }

    private static function process_event(string $event, array $data): void {
        $link_id = $data['id'] ?? $data['linkId'] ?? $data['paymentLinkId'] ?? null;
        $status  = strtoupper($data['status'] ?? '');

        if (!$link_id) {
            return;
        }

        // Find order by Mbongo link ID
        $orders = wc_get_orders([
            'meta_key'   => '_mbongo_link_id',
            'meta_value' => $link_id,
            'limit'      => 1,
        ]);

        if (empty($orders)) {
            // Fallback: try metadata orderId
            $order_id = $data['metadata']['orderId'] ?? null;
            if ($order_id) {
                $order = wc_get_order((int) $order_id);
            }
        } else {
            $order = $orders[0];
        }

        if (empty($order)) {
            return;
        }

        switch ($event) {
            case 'payment.completed':
            case 'payment_link.paid':
            case 'PAYMENT_SUCCESS':
                if (!$order->has_status(['processing', 'completed'])) {
                    $order->payment_complete($data['reference'] ?? $link_id);
                    $order->add_order_note(
                        sprintf(
                            'Paiement Mbongo confirmé. Réf: %s | Montant: %s %s',
                            $data['reference'] ?? $link_id,
                            $data['amount'] ?? '?',
                            $data['currency'] ?? 'CDF'
                        )
                    );
                }
                break;

            case 'payment.failed':
            case 'payment_link.expired':
            case 'PAYMENT_FAILED':
                if ($order->has_status('pending')) {
                    $order->update_status(
                        'failed',
                        'Paiement Mbongo échoué ou lien expiré.'
                    );
                }
                break;

            case 'payment.refunded':
            case 'PAYMENT_REFUNDED':
                $order->update_status('refunded', 'Remboursement reçu via Mbongo.');
                break;
        }

        $order->save();
    }
}

// Bootstrap webhook listener
add_action('plugins_loaded', ['Mbongo_Webhook', 'init'], 20);
