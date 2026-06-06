import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/dio_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/mbongo_theme.dart';
import '../../core/utils/money.dart';
import '../../features/wallet/presentation/wallet_notifier.dart';
import '../../widgets/common/transaction_confirm_sheet.dart';
import '../appro/appro_mbongo_screen.dart';
import '../transfer/qr_scanner_screen.dart';
import '../transfer/send_money_screen.dart';

/// Point d'entrée : scanner puis router automatiquement
Future<void> scanAndRoute(BuildContext context) async {
  final result = await Navigator.push<QrScanResult>(
    context,
    MaterialPageRoute(builder: (_) => const QrScannerScreen()),
  );
  if (result == null || !context.mounted) return;
  routeQrResult(context, result);
}

/// Router un résultat de scan vers le bon écran
void routeQrResult(BuildContext context, QrScanResult result) {
  switch (result.role) {
    case QrRole.client:
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => SendMoneyScreen(prefilledPhone: result.phone, prefilledName: result.name)),
      );
    case QrRole.agent:
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ApproMbongoScreen(prefilledAgentPhone: result.phone, prefilledAgentName: result.name)),
      );
    case QrRole.merchant:
      showModalBottomSheet<void>(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (_) => _QrMerchantPaySheet(result: result),
      );
    case QrRole.unknown:
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('QR non reconnu.')),
      );
  }
}

// ─────────────────────────────────────────────────────────
// Sheet paiement marchand depuis QR
// ─────────────────────────────────────────────────────────
class _QrMerchantPaySheet extends ConsumerStatefulWidget {
  final QrScanResult result;
  const _QrMerchantPaySheet({required this.result});

  @override
  ConsumerState<_QrMerchantPaySheet> createState() => _QrMerchantPaySheetState();
}

class _QrMerchantPaySheetState extends ConsumerState<_QrMerchantPaySheet> {
  final _amountCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.result.amount != null) {
      _amountCtrl.text = widget.result.amount!.toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _pay() async {
    final amount = double.tryParse(_amountCtrl.text.trim().replaceAll(',', '.')) ?? 0;
    if (amount <= 0) { setState(() => _error = 'Montant invalide'); return; }

    final balance = ref.read(walletProvider).valueOrNull?.balance ?? 0;
    if (amount > balance) { setState(() => _error = 'Solde insuffisant'); return; }

    final confirmed = await showTransactionConfirmSheet(
      context: context,
      title: 'Paiement marchand',
      icon: Icons.storefront_rounded,
      rows: [
        ConfirmRow(label: 'Marchand', value: widget.result.name.isNotEmpty ? widget.result.name : widget.result.phone),
        ConfirmRow(label: 'Montant', value: Money.format(amount, 'CDF'), bold: true, valueColor: const Color(0xFFD4A843)),
      ],
    );
    if (!confirmed || !mounted) return;

    setState(() { _loading = true; _error = null; });
    try {
      await ref.read(dioClientProvider).post('/transactions/merchant-pay', {
        'merchant': widget.result.name.isNotEmpty ? widget.result.name : widget.result.phone,
        'amount': amount,
        'method': 'QR',
        'location': '',
      });
      ref.read(walletProvider.notifier).refresh();
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.green,
            content: Text('Paiement de ${Money.format(amount, 'CDF')} effectué.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) setState(() { _loading = false; _error = e.toString(); });
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = MbongoThemeController.current;
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final name = widget.result.name.isNotEmpty ? widget.result.name : widget.result.phone;
    final hasFixedAmount = widget.result.amount != null;

    return Container(
      margin: EdgeInsets.only(left: 12, right: 12, bottom: bottom > 0 ? 0 : 8),
      decoration: BoxDecoration(
        color: palette.panel,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.3)),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 16, 20, bottom > 0 ? bottom + 16 : 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 20),
              Row(children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(color: palette.accent.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(14)),
                  child: Icon(Icons.storefront_rounded, color: palette.accent),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(name, style: const TextStyle(color: AppColors.text, fontSize: 16, fontWeight: FontWeight.w900)),
                  const Text('Paiement marchand', style: TextStyle(color: AppColors.textSoft, fontSize: 12)),
                ])),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: AppColors.green.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                  child: const Text('QR', style: TextStyle(color: AppColors.green, fontSize: 11, fontWeight: FontWeight.w900)),
                ),
              ]),
              const SizedBox(height: 20),
              if (_error != null) ...[
                Text(_error!, style: const TextStyle(color: AppColors.red, fontSize: 12)),
                const SizedBox(height: 8),
              ],
              TextField(
                controller: _amountCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                readOnly: hasFixedAmount,
                style: const TextStyle(color: AppColors.text, fontSize: 22, fontWeight: FontWeight.w900),
                decoration: InputDecoration(
                  labelText: 'Montant (CDF)',
                  labelStyle: const TextStyle(color: AppColors.textSoft),
                  suffixText: hasFixedAmount ? 'Fixé' : null,
                ),
              ),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(child: OutlinedButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Annuler'))),
                const SizedBox(width: 12),
                Expanded(flex: 2, child: ElevatedButton(
                  onPressed: _loading ? null : _pay,
                  child: _loading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                      : const Text('Payer'),
                )),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}
