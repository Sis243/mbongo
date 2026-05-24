<?php
defined('ABSPATH') || exit;

class Mbongo_API {

    private string $api_key;
    private string $base_url;
    private int    $timeout = 30;

    public function __construct(string $api_key, bool $sandbox = false) {
        $this->api_key  = $api_key;
        $this->base_url = $sandbox ? MBONGO_API_BASE_SANDBOX : MBONGO_API_BASE_PROD;
    }

    /* ── Create payment link ──────────────────────────────── */
    public function create_payment_link(array $data): array|WP_Error {
        return $this->request('POST', '/transactions/payment-link', $data);
    }

    /* ── Get payment link status ──────────────────────────── */
    public function get_payment_link(string $link_id): array|WP_Error {
        return $this->request('GET', "/transactions/payment-link/{$link_id}");
    }

    /* ── Verify webhook signature ─────────────────────────── */
    public static function verify_signature(string $payload, string $signature, string $secret): bool {
        $expected = hash_hmac('sha256', $payload, $secret);
        return hash_equals($expected, $signature);
    }

    /* ── HTTP helper ──────────────────────────────────────── */
    private function request(string $method, string $path, array $body = []): array|WP_Error {
        $url  = $this->base_url . $path;
        $args = [
            'method'  => $method,
            'timeout' => $this->timeout,
            'headers' => [
                'Authorization' => 'Bearer ' . $this->api_key,
                'Content-Type'  => 'application/json',
                'Accept'        => 'application/json',
            ],
        ];

        if (!empty($body)) {
            $args['body'] = wp_json_encode($body);
        }

        $response = wp_remote_request($url, $args);

        if (is_wp_error($response)) {
            return $response;
        }

        $code = wp_remote_retrieve_response_code($response);
        $body = json_decode(wp_remote_retrieve_body($response), true);

        if ($code < 200 || $code >= 300) {
            $message = $body['message'] ?? $body['error'] ?? "Erreur API Mbongo ({$code})";
            return new WP_Error('mbongo_api_error', $message, ['status' => $code]);
        }

        return $body ?? [];
    }
}
