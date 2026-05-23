import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/dio_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/mbongo_theme.dart';
import '../../widgets/common/app_scaffold.dart';

final _apiKeyProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final client = ref.read(dioClientProvider);
  try {
    final resp = await client.get('/merchant/api-key');
    return Map<String, dynamic>.from(resp as Map);
  } catch (_) {
    return {};
  }
});

class MerchantApiKeyScreen extends ConsumerWidget {
  const MerchantApiKeyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = MbongoThemeController.current;
    final keyAsync = ref.watch(_apiKeyProvider);

    return AppScaffold(
      title: 'Clé API',
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _header(palette),
          const SizedBox(height: 20),
          keyAsync.when(
            data: (data) => _KeyCard(data: data, palette: palette, ref: ref),
            loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
            error: (_, __) => _KeyCard(data: const {}, palette: palette, ref: ref),
          ),
          const SizedBox(height: 20),
          _usageSection(palette),
        ],
      ),
    );
  }

  Widget _header(dynamic palette) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0E2346), Color(0xFF14305D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cyan.withValues(alpha: 0.2)),
      ),
      child: const Row(
        children: [
          Icon(Icons.vpn_key_rounded, color: AppColors.cyan, size: 28),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Clé API Mbongo',
                    style: TextStyle(color: AppColors.text, fontSize: 17, fontWeight: FontWeight.w900)),
                SizedBox(height: 4),
                Text('Utilisez cette clé pour intégrer Mbongo dans vos applications.',
                    style: TextStyle(color: AppColors.textSoft, fontSize: 12, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _usageSection(dynamic palette) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.panelAlt,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Exemple d\'utilisation',
              style: TextStyle(color: AppColors.text, fontSize: 14, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          _codeBlock('''curl -X POST https://mbongo-backend.vercel.app/transactions/payment-link \\
  -H "Authorization: Bearer YOUR_API_KEY" \\
  -H "Content-Type: application/json" \\
  -d '{"amount": 5000, "currency": "CDF", "description": "Commande #123"}'
'''),
          const SizedBox(height: 12),
          const Text('Environnements',
              style: TextStyle(color: AppColors.text, fontSize: 14, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          _envRow('Production', 'https://mbongo-backend.vercel.app', AppColors.green),
          const SizedBox(height: 6),
          _envRow('Sandbox', 'https://sandbox.mbongo-backend.vercel.app', AppColors.orange),
        ],
      ),
    );
  }

  Widget _codeBlock(String code) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0A1628),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.3)),
      ),
      child: Text(
        code,
        style: const TextStyle(
          color: Color(0xFF7FD6A0),
          fontSize: 10.5,
          fontFamily: 'monospace',
          height: 1.5,
        ),
      ),
    );
  }

  Widget _envRow(String label, String url, Color color) {
    return Row(
      children: [
        Container(
          width: 8, height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(label,
            style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(url,
              style: const TextStyle(color: AppColors.textSoft, fontSize: 11),
              overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}

class _KeyCard extends ConsumerWidget {
  final Map<String, dynamic> data;
  final dynamic palette;
  final WidgetRef ref;

  const _KeyCard({required this.data, required this.palette, required this.ref});

  @override
  Widget build(BuildContext context, WidgetRef widgetRef) {
    final apiKey = data['key']?.toString() ?? data['apiKey']?.toString() ?? 'mbongo_live_••••••••••••••••••••';
    final preview = data['preview']?.toString() ?? apiKey;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: palette.panelAlt,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cyan.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Clé secrète',
              style: TextStyle(color: AppColors.textSoft, fontSize: 12, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF0A1628),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.key_rounded, color: AppColors.cyan, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    preview,
                    style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 12.5,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w700,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: apiKey));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Clé copiée dans le presse-papiers')),
                    );
                  },
                  child: const Icon(Icons.copy_rounded, color: AppColors.cyan, size: 18),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.green.withValues(alpha: 0.25)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_outline_rounded, color: AppColors.green, size: 16),
                      SizedBox(width: 6),
                      Text('Clé active',
                          style: TextStyle(color: AppColors.green, fontSize: 12, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _confirmRegen(context, widgetRef),
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text('Régénérer', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.orange,
                    side: const BorderSide(color: AppColors.orange),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _confirmRegen(BuildContext context, WidgetRef widgetRef) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: MbongoThemeController.current.panel,
        title: const Text('Régénérer la clé API ?',
            style: TextStyle(color: AppColors.text, fontWeight: FontWeight.w800)),
        content: const Text(
          'L\'ancienne clé sera immédiatement invalidée. Toutes les intégrations utilisant cette clé cesseront de fonctionner.',
          style: TextStyle(color: AppColors.textSoft, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              widgetRef.invalidate(_apiKeyProvider);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.orange),
            child: const Text('Régénérer'),
          ),
        ],
      ),
    );
  }
}
