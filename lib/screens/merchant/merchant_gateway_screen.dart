import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/mbongo_theme.dart';
import '../../widgets/common/app_scaffold.dart';
import 'merchant_api_key_screen.dart';

class MerchantGatewayScreen extends StatelessWidget {
  const MerchantGatewayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = MbongoThemeController.current;
    return AppScaffold(
      title: 'Passerelle de paiement',
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _heroBanner(),
          const SizedBox(height: 20),
          _sectionTitle('Méthodes d\'intégration'),
          const SizedBox(height: 12),
          _IntegrationCard(
            icon: Icons.code_rounded,
            title: 'API REST',
            subtitle: 'Intégrez directement via nos endpoints HTTP',
            color: AppColors.cyan,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MerchantApiKeyScreen())),
          ),
          const SizedBox(height: 10),
          _IntegrationCard(
            icon: Icons.shopping_cart_rounded,
            title: 'Plugin WooCommerce',
            subtitle: 'Acceptez Mbongo sur votre boutique WordPress',
            color: AppColors.green,
            badge: 'Bientôt',
            onTap: () {},
          ),
          const SizedBox(height: 10),
          _IntegrationCard(
            icon: Icons.phone_android_rounded,
            title: 'SDK Mobile',
            subtitle: 'Flutter / Android / iOS SDK',
            color: AppColors.gold,
            badge: 'Bientôt',
            onTap: () {},
          ),
          const SizedBox(height: 10),
          _IntegrationCard(
            icon: Icons.webhook_rounded,
            title: 'Webhooks',
            subtitle: 'Recevez des notifications en temps réel',
            color: AppColors.orange,
            badge: 'Bientôt',
            onTap: () {},
          ),
          const SizedBox(height: 24),
          _sectionTitle('Paramètres de la passerelle'),
          const SizedBox(height: 12),
          _GatewaySettings(palette: palette),
          const SizedBox(height: 24),
          _sectionTitle('Flux de paiement'),
          const SizedBox(height: 12),
          _FlowDiagram(palette: palette),
        ],
      ),
    );
  }

  Widget _heroBanner() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0E2346), Color(0xFF1A3A6A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cyan.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.payment_rounded, color: AppColors.cyan, size: 28),
              SizedBox(width: 10),
              Text('Mbongo Gateway',
                  style: TextStyle(color: AppColors.text, fontSize: 20, fontWeight: FontWeight.w900)),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Intégrez la passerelle de paiement Mbongo en quelques lignes de code. '
            'Acceptez les paiements mobiles, les virements et les QR codes.',
            style: TextStyle(color: AppColors.textSoft, fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _badge('REST API', AppColors.cyan),
              const SizedBox(width: 8),
              _badge('Webhooks', AppColors.green),
              const SizedBox(width: 8),
              _badge('Sandbox', AppColors.gold),
            ],
          ),
        ],
      ),
    );
  }

  Widget _badge(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w800)),
      );

  Widget _sectionTitle(String title) => Text(
        title,
        style: const TextStyle(color: AppColors.text, fontSize: 15, fontWeight: FontWeight.w900),
      );
}

class _IntegrationCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final String? badge;
  final VoidCallback onTap;

  const _IntegrationCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final palette = MbongoThemeController.current;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: palette.panelAlt,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Container(
              width: 46, height: 46,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.13),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(color: AppColors.text, fontSize: 14, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 3),
                  Text(subtitle,
                      style: const TextStyle(color: AppColors.textSoft, fontSize: 12)),
                ],
              ),
            ),
            if (badge != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(badge!,
                    style: const TextStyle(color: AppColors.gold, fontSize: 10, fontWeight: FontWeight.w800)),
              )
            else
              const Icon(Icons.chevron_right_rounded, color: AppColors.textSoft),
          ],
        ),
      ),
    );
  }
}

class _GatewaySettings extends StatefulWidget {
  final dynamic palette;
  const _GatewaySettings({required this.palette});

  @override
  State<_GatewaySettings> createState() => _GatewaySettingsState();
}

class _GatewaySettingsState extends State<_GatewaySettings> {
  bool _webhooksEnabled = false;
  bool _sandboxMode = true;
  bool _autoConfirm = true;
  String _currency = 'CDF';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.palette.panelAlt,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.24)),
      ),
      child: Column(
        children: [
          _ToggleRow(
            label: 'Mode Sandbox',
            subtitle: 'Activer pour les tests',
            value: _sandboxMode,
            color: AppColors.gold,
            onChanged: (v) => setState(() => _sandboxMode = v),
          ),
          const Divider(height: 20, color: AppColors.border),
          _ToggleRow(
            label: 'Webhooks',
            subtitle: 'Notifications en temps réel',
            value: _webhooksEnabled,
            color: AppColors.cyan,
            onChanged: (v) => setState(() => _webhooksEnabled = v),
          ),
          const Divider(height: 20, color: AppColors.border),
          _ToggleRow(
            label: 'Confirmation automatique',
            subtitle: 'Valider les paiements automatiquement',
            value: _autoConfirm,
            color: AppColors.green,
            onChanged: (v) => setState(() => _autoConfirm = v),
          ),
          const Divider(height: 20, color: AppColors.border),
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Devise par défaut',
                        style: TextStyle(color: AppColors.text, fontSize: 13, fontWeight: FontWeight.w700)),
                    Text('Monnaie de règlement',
                        style: TextStyle(color: AppColors.textSoft, fontSize: 11)),
                  ],
                ),
              ),
              DropdownButton<String>(
                value: _currency,
                dropdownColor: MbongoThemeController.current.panel,
                style: const TextStyle(color: AppColors.text, fontWeight: FontWeight.w700),
                underline: const SizedBox(),
                items: ['CDF', 'USD'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) => setState(() => _currency = v!),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final String label;
  final String subtitle;
  final bool value;
  final Color color;
  final ValueChanged<bool> onChanged;

  const _ToggleRow({
    required this.label,
    required this.subtitle,
    required this.value,
    required this.color,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(color: AppColors.text, fontSize: 13, fontWeight: FontWeight.w700)),
              Text(subtitle,
                  style: const TextStyle(color: AppColors.textSoft, fontSize: 11)),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: color,
          activeTrackColor: color.withValues(alpha: 0.4),
        ),
      ],
    );
  }
}

class _FlowDiagram extends StatelessWidget {
  final dynamic palette;
  const _FlowDiagram({required this.palette});

  @override
  Widget build(BuildContext context) {
    final steps = [
      ('Client', 'Initie le paiement', Icons.person_rounded, AppColors.cyan),
      ('Mbongo Gateway', 'Traite la transaction', Icons.payment_rounded, AppColors.gold),
      ('Webhook', 'Notifie votre serveur', Icons.webhook_rounded, AppColors.orange),
      ('Confirmation', 'Livraison / accès accordé', Icons.check_circle_rounded, AppColors.green),
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.panelAlt,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.24)),
      ),
      child: Column(
        children: steps.asMap().entries.map((entry) {
          final i = entry.key;
          final (title, subtitle, icon, color) = entry.value;
          return Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.13),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title,
                            style: const TextStyle(color: AppColors.text, fontSize: 13, fontWeight: FontWeight.w800)),
                        Text(subtitle,
                            style: const TextStyle(color: AppColors.textSoft, fontSize: 11)),
                      ],
                    ),
                  ),
                  Container(
                    width: 22, height: 22,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text('${i + 1}',
                          style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w900)),
                    ),
                  ),
                ],
              ),
              if (i < steps.length - 1)
                Padding(
                  padding: const EdgeInsets.only(left: 19),
                  child: Container(
                    width: 2, height: 20,
                    color: AppColors.border.withValues(alpha: 0.4),
                  ),
                ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
