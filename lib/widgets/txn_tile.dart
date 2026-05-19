import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/mbongo_theme.dart';

class TxnTile extends StatelessWidget {
  final Map<String, dynamic> txn;

  const TxnTile({
    super.key,
    required this.txn,
  });

  double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  String _formatAmount(double n) {
    return n.toStringAsFixed(2).replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]} ',
    );
  }

  DateTime _parseDate(dynamic raw) {
    if (raw is DateTime) return raw;
    return DateTime.tryParse(raw.toString()) ?? DateTime.now();
  }

  String _formatDate(DateTime date) {
    final dd = date.day.toString().padLeft(2, '0');
    final mm = date.month.toString().padLeft(2, '0');
    final yyyy = date.year.toString();
    final hh = date.hour.toString().padLeft(2, '0');
    final min = date.minute.toString().padLeft(2, '0');
    return '$dd/$mm/$yyyy $hh:$min';
  }

  String _resolveCategory(String type) {
    switch (type) {
      case 'TRANSFERT':
      case 'SEND_MONEY':
        return 'TRANSFERT';
      case 'DEMANDE_ARGENT':
      case 'REQUEST_MONEY':
        return 'DEMANDE';
      case 'RETRAIT':
      case 'WITHDRAW':
        return 'RETRAIT';
      case 'DEPOT':
      case 'RECEPTION':
      case 'RECEIVE':
        return 'DEPOT';
      case 'AIRTIME':
        return 'UNITES';
      case 'TV':
        return 'TV';
      case 'EXCHANGE':
        return 'ECHANGE';
      case 'CARTE':
      case 'CARTE_RECHARGE':
      case 'CARD':
        return 'CARTE';
      case 'QR_PAY':
      case 'PAIEMENT':
      case 'PAYMENT':
        return 'PAIEMENT';
      default:
        return 'AUTRE';
    }
  }

  IconData _iconForType(String type, bool isCredit) {
    switch (type) {
      case 'TRANSFERT':
      case 'SEND_MONEY':
        return Icons.send_rounded;
      case 'DEMANDE_ARGENT':
      case 'REQUEST_MONEY':
        return Icons.request_page_rounded;
      case 'RETRAIT':
      case 'WITHDRAW':
        return Icons.download_rounded;
      case 'DEPOT':
      case 'RECEPTION':
      case 'RECEIVE':
        return Icons.south_west_rounded;
      case 'AIRTIME':
        return Icons.phone_android_rounded;
      case 'TV':
        return Icons.tv_rounded;
      case 'EXCHANGE':
        return Icons.currency_exchange_rounded;
      case 'CARTE':
      case 'CARTE_RECHARGE':
      case 'CARD':
        return Icons.credit_card_rounded;
      case 'QR_PAY':
      case 'PAIEMENT':
      case 'PAYMENT':
        return Icons.qr_code_scanner_rounded;
      default:
        return isCredit
            ? Icons.south_west_rounded
            : Icons.north_east_rounded;
    }
  }

  Color _colorForType(String type, bool isCredit) {
    switch (type) {
      case 'RETRAIT':
      case 'WITHDRAW':
        return AppColors.red;
      case 'AIRTIME':
        return AppColors.orange;
      case 'TV':
        return AppColors.gold;
      case 'EXCHANGE':
        return AppColors.cyan;
      case 'CARTE':
      case 'CARTE_RECHARGE':
      case 'CARD':
        return MbongoThemeController.current.accent;
      case 'DEMANDE_ARGENT':
      case 'REQUEST_MONEY':
        return AppColors.cyan;
      case 'PAIEMENT':
      case 'PAYMENT':
      case 'QR_PAY':
        return MbongoThemeController.current.accentStrong;
      default:
        return isCredit ? AppColors.green : MbongoThemeController.current.accent;
    }
  }

  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'SUCCESS':
      case 'SUCCES':
      case 'SUCCESSFUL':
      case 'COMPLETED':
      case 'TERMINE':
        return AppColors.green;
      case 'PENDING':
      case 'EN_ATTENTE':
        return AppColors.orange;
      case 'FAILED':
      case 'ECHEC':
      case 'CANCELLED':
      case 'ANNULE':
        return AppColors.red;
      default:
        return MbongoThemeController.current.accent;
    }
  }

  String _statusLabel(String status) {
    final s = status.toUpperCase();
    switch (s) {
      case 'SUCCESS':
      case 'SUCCESSFUL':
      case 'COMPLETED':
        return 'VALIDE';
      case 'PENDING':
        return 'EN ATTENTE';
      case 'FAILED':
        return 'ECHEC';
      case 'CANCELLED':
        return 'ANNULE';
      default:
        return status.isEmpty ? 'TRAITE' : status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = MbongoThemeController.current;
    final label = (txn['label'] ?? 'Transaction').toString();
    final type = (txn['type'] ?? '').toString().toUpperCase();
    final status = (txn['status'] ?? 'SUCCESS').toString();
    final currency = (txn['currency'] ?? 'CDF').toString().toUpperCase();
    final amount = _toDouble(txn['amount']);
    final isCredit = (txn['isCredit'] ?? false) == true;
    final date = _parseDate(txn['date']);
    final category = _resolveCategory(type);
    final leadingColor = _colorForType(type, isCredit);
    final leadingIcon = _iconForType(type, isCredit);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.panelAlt,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppColors.border.withValues(alpha: 0.24),
        ),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 12,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: leadingColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: leadingColor.withValues(alpha: 0.18),
              ),
            ),
            child: Icon(
              leadingIcon,
              color: leadingColor,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.darkText,
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  category,
                  style: const TextStyle(
                    color: AppColors.darkMuted,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  _formatDate(date),
                  style: const TextStyle(
                    color: AppColors.darkMuted,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isCredit ? '+' : '-'} ${currency == 'USD' ? '\$' : 'CDF'} ${_formatAmount(amount)}',
                style: TextStyle(
                  color: isCredit ? AppColors.green : palette.accent,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _statusColor(status).withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: _statusColor(status).withValues(alpha: 0.20),
                  ),
                ),
                child: Text(
                  _statusLabel(status),
                  style: TextStyle(
                    color: _statusColor(status),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
