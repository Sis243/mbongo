import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/mbongo_theme.dart';
import '../../core/utils/money.dart';
import '../../features/auth/presentation/auth_notifier.dart';
import '../../features/wallet/presentation/wallet_notifier.dart';
import '../../widgets/cards/wallet_card.dart';
import '../../widgets/common/mbongo_money_particles.dart';
import '../../widgets/common/mbongo_sub_app_bar.dart';
import '../../models/account_model.dart';

class PaymentLinksScreen extends ConsumerStatefulWidget {
  const PaymentLinksScreen({super.key});

  @override
  ConsumerState<PaymentLinksScreen> createState() => _PaymentLinksScreenState();
}

class _PaymentLinksScreenState extends ConsumerState<PaymentLinksScreen> {
  final amountController = TextEditingController();
  final reasonController = TextEditingController();
  String? _generatedLink;
  bool _copied = false;

  @override
  void dispose() {
    amountController.dispose();
    reasonController.dispose();
    super.dispose();
  }

  void _generate() {
    final user = ref.read(authProvider).valueOrNull;
    final walletData = ref.read(walletProvider).valueOrNull;
    final currency = walletData?.currency ?? 'CDF';

    if (user == null) {
      _toast('Session expirée. Reconnectez-vous.');
      return;
    }

    final amountText = amountController.text.trim().replaceAll(',', '.');
    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      _toast('Veuillez saisir un montant valide.');
      return;
    }

    if (reasonController.text.trim().isEmpty) {
      _toast('Veuillez saisir un motif.');
      return;
    }

    final phone = Uri.encodeComponent(user.phone);
    final reason = Uri.encodeComponent(reasonController.text.trim());
    final link =
        'https://mbongo.app/pay?to=$phone&amount=${amount.toStringAsFixed(2)}&currency=$currency&reason=$reason';

    setState(() {
      _generatedLink = link;
      _copied = false;
    });
  }

  Future<void> _copyLink() async {
    if (_generatedLink == null) return;
    await Clipboard.setData(ClipboardData(text: _generatedLink!));
    setState(() => _copied = true);
    _toast('Lien copié dans le presse-papier.');
  }

  void _reset() {
    setState(() {
      _generatedLink = null;
      _copied = false;
      amountController.clear();
      reasonController.clear();
    });
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = MbongoThemeController.current;
    final walletData = ref.watch(walletProvider).valueOrNull;
    final currency = walletData?.currency ?? 'CDF';
    final selectedWallet = walletData != null
        ? AccountModel(
            id: walletData.id,
            type: 'Portefeuille ${walletData.currency}',
            currency: walletData.currency,
            number: 'MBONGO-${walletData.currency}',
            balance: walletData.balance,
            selected: true,
          )
        : AccountModel(
            id: '',
            type: 'Portefeuille CDF',
            currency: 'CDF',
            number: 'MBONGO-CDF',
            balance: 0,
            selected: true,
          );

    return Scaffold(
      backgroundColor: palette.shellBottom,
      appBar: MbongoSubAppBar(title: 'Lien de paiement'),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [palette.shellTop, palette.shellBottom],
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: MbongoMoneyParticles(
                  color: palette.accent,
                  count: 14,
                  opacity: 0.08,
                  height: 0,
                ),
              ),
            ),
            SafeArea(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildHeaderCard(palette),
                  const SizedBox(height: 18),
                  const Text(
                    'Portefeuille selectionne',
                    style: TextStyle(
                      color: AppColors.text,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 14),
                  WalletCard(
                    wallet: selectedWallet,
                    gradient: selectedWallet.currency == 'CDF'
                        ? palette.cardGradient
                        : [palette.cardGradient.first, palette.accentStrong],
                  ),
                  const SizedBox(height: 18),
                  if (_generatedLink == null) ...[
                    _buildFormCard(palette, currency),
                    const SizedBox(height: 18),
                    ElevatedButton(
                      onPressed: _generate,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: palette.accentStrong,
                      ),
                      child: const Text('Generer le lien'),
                    ),
                  ] else ...[
                    _buildResultCard(palette, currency),
                    const SizedBox(height: 14),
                    ElevatedButton.icon(
                      onPressed: _copyLink,
                      icon: Icon(_copied ? Icons.check_rounded : Icons.copy_rounded),
                      label: Text(_copied ? 'Lien copie !' : 'Copier le lien'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _copied ? AppColors.green : palette.accentStrong,
                      ),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton(
                      onPressed: _reset,
                      child: const Text('Creer un nouveau lien'),
                    ),
                  ],
                  const SizedBox(height: 18),
                  _buildInfoCard(palette),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard(MbongoThemePalette palette) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: palette.bannerGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: palette.glow.withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.link_rounded, color: palette.accentStrong),
              const SizedBox(width: 8),
              const Text(
                'Lien de paiement',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Recevez de l\'argent',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Generez un lien personnalise et partagez-le avec n\'importe qui pour recevoir un paiement instantane sur votre portefeuille MBONGO.',
            style: TextStyle(
              color: Color(0xFFE8EEF8),
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard(MbongoThemePalette palette, String currency) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: palette.panelAlt,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.24)),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 14,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.tune_rounded, color: palette.accent),
              const SizedBox(width: 8),
              const Text(
                'Parametres du lien',
                style: TextStyle(
                  color: AppColors.darkText,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(
              color: AppColors.text,
              fontWeight: FontWeight.w700,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: palette.panel,
              labelText: 'Montant',
              hintText: '0.00',
              labelStyle: const TextStyle(color: AppColors.muted),
              hintStyle: const TextStyle(color: AppColors.muted),
              prefixIcon: Container(
                width: 80,
                alignment: Alignment.center,
                child: Text(
                  Money.symbol(currency),
                  style: TextStyle(
                    color: currency == 'CDF' ? palette.accent : palette.accentStrong,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide(
                  color: AppColors.border.withValues(alpha: 0.24),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide(color: palette.accent, width: 1.4),
              ),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: reasonController,
            maxLines: 2,
            style: const TextStyle(
              color: AppColors.text,
              fontWeight: FontWeight.w700,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: palette.panel,
              labelText: 'Motif',
              hintText: 'Ex: Paiement de service, Remboursement...',
              labelStyle: const TextStyle(color: AppColors.muted),
              hintStyle: const TextStyle(color: AppColors.muted),
              prefixIcon: const Icon(Icons.edit_note_rounded, color: AppColors.primary),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide(
                  color: AppColors.border.withValues(alpha: 0.24),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide(color: palette.accent, width: 1.4),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard(MbongoThemePalette palette, String currency) {
    final amountText = amountController.text.trim().replaceAll(',', '.');
    final amount = double.tryParse(amountText) ?? 0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: palette.panelAlt,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: palette.accent.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: palette.glow.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.green.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.check_circle_rounded, color: AppColors.green, size: 20),
              ),
              const SizedBox(width: 10),
              const Text(
                'Lien genere avec succes',
                style: TextStyle(
                  color: AppColors.green,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _detailRow('Montant demande', '${Money.symbol(currency)} ${amount.toStringAsFixed(2)}', palette),
          const SizedBox(height: 10),
          _detailRow('Motif', reasonController.text.trim(), palette),
          const SizedBox(height: 14),
          const Text(
            'Lien de paiement',
            style: TextStyle(
              color: AppColors.darkMuted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: palette.panel,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: palette.accent.withValues(alpha: 0.3)),
            ),
            child: Text(
              _generatedLink!,
              style: TextStyle(
                color: palette.accent,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                fontFamily: 'monospace',
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: palette.accent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.share_rounded, color: palette.accent, size: 18),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Partagez ce lien par WhatsApp, SMS, email ou reseaux sociaux.',
                    style: TextStyle(
                      color: AppColors.darkMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value, MbongoThemePalette palette) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.darkMuted,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.darkText,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(MbongoThemePalette palette) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.accent.withValues(alpha: 0.22)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: palette.accent),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Le lien genere contient votre numero MBONGO. Le payeur peut l\'utiliser pour vous envoyer le montant indique directement depuis l\'application.',
              style: TextStyle(
                color: AppColors.text,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
