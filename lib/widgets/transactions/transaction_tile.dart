import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/mbongo_theme.dart';
import '../../core/utils/money.dart';
import '../../models/transaction_model.dart';

class TransactionTile extends StatelessWidget {
  final TransactionModel tx;

  const TransactionTile({
    super.key,
    required this.tx,
  });

  @override
  Widget build(BuildContext context) {
    final palette = MbongoThemeController.current;
    final isDebit = tx.type == "send_money" ||
        tx.type == "airtime" ||
        tx.type == "exchange_money";
    final isPending = tx.status == "PENDING";

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.panelAlt,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.border.withValues(alpha: 0.55),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: palette.panel,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              isPending
                  ? Icons.hourglass_top_rounded
                  : (isDebit ? Icons.north_east_rounded : Icons.south_west_rounded),
              color: isPending
                  ? palette.accent
                  : (isDebit ? AppColors.red : AppColors.green),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.title,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  tx.target,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  tx.reason,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 12,
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
                "${isDebit ? "-" : "+"} ${Money.format(tx.amount, tx.currency)}",
                style: TextStyle(
                  color: isPending
                      ? palette.accent
                      : (isDebit ? AppColors.red : AppColors.green),
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                tx.status,
                style: TextStyle(
                  color: isPending ? palette.accent : AppColors.green,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
