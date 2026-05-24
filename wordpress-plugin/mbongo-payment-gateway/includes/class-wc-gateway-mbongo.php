<?php
defined('ABSPATH') || exit;

class WC_Gateway_Mbongo extends WC_Payment_Gateway {

    public function __construct() {
        $this->id                 = 'mbongo_gateway';
        $this->icon               = MBONGO_GATEWAY_URL . 'assets/mbongo-icon.png';
        $this->has_fields         = false;
        $this->method_title       = 'Mbongo';
        $this->method_description = 'Paiement sécurisé via Mbongo — Mobile Money, QR Code, Virement instantané.';
        $this->supports           = ['products', 'refunds'];

        $this->init_form_fields();
        $this->init_settings();

        $this->title       = $this->get_option('title');
        $this->description = $this->get_option('description');

        add_action('woocommerce_update_options_payment_gateways_' . $this->id, [$this, 'process_admin_options']);
        add_action('woocommerce_api_mbongo_callback', [$this, 'handle_redirect_callback']);
        add_action('woocommerce_thankyou_' . $this->id, [$this, 'thankyou_page']);
    }

    /* ── Settings fields ─────────────────────────────────── */
    public function init_form_fields(): void {
        $this->form_fields = [
            'enabled' => [
                'title'   => 'Activer',
                'type'    => 'checkbox',
                'label'   => 'Activer Mbongo Gateway',
                'default' => 'yes',
            ],
            'title' => [
                'title'       => 'Titre',
                'type'        => 'text',
                'description' => 'Titre affiché au client lors du paiement.',
                'default'     => 'Mbongo — Mobile Money & QR',
                'desc_tip'    => true,
            ],
            'description' => [
                'title'       => 'Description',
                'type'        => 'textarea',
                'description' => 'Description affichée sur la page de paiement.',
                'default'     => 'Payez en toute sécurité avec votre application Mbongo — Mobile Money, QR Code ou virement instantané.',
            ],
            'api_key' => [
                'title'       => 'Clé API',
                'type'        => 'password',
                'description' => 'Votre clé secrète Mbongo (disponible dans l\'interface marchande).',
                'default'     => '',
                'desc_tip'    => true,
            ],
            'webhook_secret' => [
                'title'       => 'Secret Webhook',
                'type'        => 'password',
                'description' => 'Secret pour vérifier l\'authenticité des webhooks Mbongo.',
                'default'     => '',
                'desc_tip'    => true,
            ],
            'sandbox' => [
                'title'   => 'Mode Sandbox',
                'type'    => 'checkbox',
                'label'   => 'Activer le mode test (sandbox)',
                'default' => 'no',
            ],
            'currency' => [
                'title'       => 'Devise de règlement',
                'type'        => 'select',
                'options'     => ['CDF' => 'Franc Congolais (CDF)', 'USD' => 'Dollar américain (USD)'],
                'default'     => 'CDF',
                'description' => 'Devise dans laquelle les paiements sont traités.',
                'desc_tip'    => true,
            ],
            'expiry_minutes' => [
                'title'       => 'Expiration du lien (minutes)',
                'type'        => 'number',
                'default'     => '30',
                'description' => 'Durée de validité du lien de paiement généré.',
                'desc_tip'    => true,
            ],
        ];
    }

    /* ── Process payment ─────────────────────────────────── */
    public function process_payment($order_id): array {
        $order   = wc_get_order($order_id);
        $api_key = $this->get_option('api_key');
        $sandbox = $this->get_option('sandbox') === 'yes';
        $currency = $this->get_option('currency', 'CDF');
        $expiry  = (int) $this->get_option('expiry_minutes', 30);

        if (empty($api_key)) {
            wc_add_notice('Mbongo Gateway non configuré. Contactez l\'administrateur.', 'error');
            return ['result' => 'failure'];
        }

        $api     = new Mbongo_API($api_key, $sandbox);
        $amount  = (float) $order->get_total();
        $callback_url = add_query_arg(
            ['wc-api' => 'mbongo_callback', 'order_id' => $order_id, 'key' => $order->get_order_key()],
            home_url('/')
        );

        $result = $api->create_payment_link([
            'amount'      => $amount,
            'currency'    => $currency,
            'description' => sprintf('Commande #%s — %s', $order->get_order_number(), get_bloginfo('name')),
            'expiresAt'   => gmdate('Y-m-d\TH:i:s\Z', time() + ($expiry * 60)),
            'callbackUrl' => $callback_url,
            'metadata'    => [
                'orderId'     => $order_id,
                'orderKey'    => $order->get_order_key(),
                'customerEmail' => $order->get_billing_email(),
                'customerName'  => $order->get_formatted_billing_full_name(),
            ],
        ]);

        if (is_wp_error($result)) {
            wc_add_notice('Erreur Mbongo: ' . $result->get_error_message(), 'error');
            return ['result' => 'failure'];
        }

        $link_id  = $result['id'] ?? $result['linkId'] ?? null;
        $pay_url  = $result['url'] ?? $result['paymentUrl'] ?? null;

        if (!$pay_url) {
            wc_add_notice('Impossible de créer le lien de paiement Mbongo.', 'error');
            return ['result' => 'failure'];
        }

        // Store link ID for status check
        $order->update_meta_data('_mbongo_link_id', $link_id);
        $order->update_meta_data('_mbongo_pay_url', $pay_url);
        $order->update_meta_data('_mbongo_sandbox', $sandbox ? '1' : '0');
        $order->update_status('pending', 'Lien de paiement Mbongo généré. En attente de confirmation.');
        $order->save();

        // Reduce stock
        wc_reduce_stock_levels($order_id);
        WC()->cart->empty_cart();

        return [
            'result'   => 'success',
            'redirect' => $pay_url,
        ];
    }

    /* ── Thank-you page ──────────────────────────────────── */
    public function thankyou_page(int $order_id): void {
        $order   = wc_get_order($order_id);
        $pay_url = $order->get_meta('_mbongo_pay_url');

        if ($order->has_status('pending') && $pay_url) {
            echo '<div class="mbongo-pending-notice" style="background:#fff8e1;border:1px solid #ffc107;border-radius:8px;padding:16px 20px;margin:20px 0;">';
            echo '<strong style="color:#856404;">⏳ Paiement en attente</strong><br>';
            echo '<p style="margin:8px 0 12px;">Votre lien de paiement Mbongo est actif. Si vous n\'avez pas encore payé, cliquez ci-dessous :</p>';
            echo '<a href="' . esc_url($pay_url) . '" class="button" style="background:#1B4EAA;color:#fff;padding:10px 20px;border-radius:6px;text-decoration:none;">Payer avec Mbongo</a>';
            echo '</div>';
        }

        if ($order->has_status(['processing', 'completed'])) {
            echo '<div style="background:#e8f5e9;border:1px solid #4caf50;border-radius:8px;padding:16px 20px;margin:20px 0;">';
            echo '<strong style="color:#2e7d32;">✅ Paiement confirmé</strong><br>';
            echo '<p style="margin:8px 0 0;">Merci ! Votre paiement Mbongo a été reçu et confirmé.</p>';
            echo '</div>';
        }
    }

    /* ── Redirect callback (return from Mbongo app) ─────── */
    public function handle_redirect_callback(): void {
        $order_id  = absint($_GET['order_id'] ?? 0);
        $order_key = sanitize_text_field($_GET['key'] ?? '');
        $status    = sanitize_text_field($_GET['status'] ?? '');

        if (!$order_id) {
            wp_die('Paramètres manquants.', 'Mbongo', ['response' => 400]);
        }

        $order = wc_get_order($order_id);

        if (!$order || !hash_equals($order->get_order_key(), $order_key)) {
            wp_die('Commande invalide.', 'Mbongo', ['response' => 403]);
        }

        if ($status === 'success' || $status === 'completed') {
            // Will be confirmed via webhook; redirect to thank-you
            wp_safe_redirect($order->get_checkout_order_received_url());
        } else {
            wc_add_notice('Paiement annulé ou échoué. Veuillez réessayer.', 'error');
            wp_safe_redirect(wc_get_checkout_url());
        }
        exit;
    }

    /* ── Process refund ──────────────────────────────────── */
    public function process_refund($order_id, $amount = null, $reason = ''): bool|WP_Error {
        return new WP_Error('mbongo_no_refund', 'Les remboursements automatiques ne sont pas encore supportés. Contactez le support Mbongo.');
    }

    /* ── Admin order meta box ────────────────────────────── */
    public function get_transaction_url($order): string {
        $link_id = $order->get_meta('_mbongo_link_id');
        if ($link_id) {
            $sandbox = $order->get_meta('_mbongo_sandbox') === '1';
            $base    = $sandbox ? MBONGO_API_BASE_SANDBOX : MBONGO_API_BASE_PROD;
            $this->view_transaction_url = $base . '/transactions/%s';
        }
        return parent::get_transaction_url($order);
    }
}
