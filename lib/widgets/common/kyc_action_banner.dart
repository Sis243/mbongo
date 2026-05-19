import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class KycActionBanner extends StatelessWidget {
  final String status;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const KycActionBanner({
    super.key,
    required this.status,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final color = status == 'refuse' ? AppColors.red : AppColors.gold;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.verified_user_outlined, color: color),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
          if (onAction != null && actionLabel != null) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: onAction,
                icon: Icon(
                  status == 'en_attente'
                      ? Icons.visibility_outlined
                      : Icons.arrow_forward_rounded,
                  color: color,
                ),
                label: Text(
                  actionLabel!,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: color.withValues(alpha: 0.28)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
