<?php
/**
 * Plugin Name:       Mbongo Payment Gateway
 * Plugin URI:        https://mbongo-backend.vercel.app
 * Description:       Acceptez les paiements Mbongo (Mobile Money, QR Code, Virement) sur votre boutique WooCommerce.
 * Version:           1.0.0
 * Author:            Mbongo RDC
 * Author URI:        https://mbongo-backend.vercel.app
 * License:           GPL-2.0+
 * Text Domain:       mbongo-gateway
 * Domain Path:       /languages
 * Requires at least: 6.0
 * Requires PHP:      8.0
 * WC requires at least: 7.0
 * WC tested up to:   8.9
 */

defined('ABSPATH') || exit;

define('MBONGO_GATEWAY_VERSION', '1.0.0');
define('MBONGO_GATEWAY_FILE', __FILE__);
define('MBONGO_GATEWAY_DIR', plugin_dir_path(__FILE__));
define('MBONGO_GATEWAY_URL', plugin_dir_url(__FILE__));
define('MBONGO_API_BASE_PROD', 'https://mbongo-backend.vercel.app');
define('MBONGO_API_BASE_SANDBOX', 'https://sandbox.mbongo-backend.vercel.app');

/* ── WooCommerce HPOS compatibility ─────────────────────── */
add_action('before_woocommerce_init', function () {
    if (class_exists(\Automattic\WooCommerce\Utilities\FeaturesUtil::class)) {
        \Automattic\WooCommerce\Utilities\FeaturesUtil::declare_compatibility(
            'custom_order_tables',
            __FILE__,
            true
        );
    }
});

/* ── Bootstrap ──────────────────────────────────────────── */
add_action('plugins_loaded', function () {
    if (!class_exists('WC_Payment_Gateway')) {
        add_action('admin_notices', function () {
            echo '<div class="error"><p><strong>Mbongo Gateway</strong> nécessite WooCommerce activé.</p></div>';
        });
        return;
    }
    require_once MBONGO_GATEWAY_DIR . 'includes/class-wc-gateway-mbongo.php';
    require_once MBONGO_GATEWAY_DIR . 'includes/class-mbongo-api.php';
    require_once MBONGO_GATEWAY_DIR . 'includes/class-mbongo-webhook.php';
});

add_filter('woocommerce_payment_gateways', function ($gateways) {
    $gateways[] = 'WC_Gateway_Mbongo';
    return $gateways;
});

/* ── Plugin action links ─────────────────────────────────── */
add_filter('plugin_action_links_' . plugin_basename(__FILE__), function ($links) {
    $settings = '<a href="' . admin_url('admin.php?page=wc-settings&tab=checkout&section=mbongo_gateway') . '">Paramètres</a>';
    array_unshift($links, $settings);
    return $links;
});
