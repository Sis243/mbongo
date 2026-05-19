import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/mbongo_theme.dart';

class VirtualBankCard extends StatelessWidget {
  final String brand;
  final String holderName;
  final String maskedPan;
  final String currency;
  final String status;
  final String? expiry;
  final bool compact;

  const VirtualBankCard({
    super.key,
    required this.brand,
    required this.holderName,
    required this.maskedPan,
    required this.currency,
    required this.status,
    this.expiry,
    this.compact = false,
  });

  bool get _isMastercard => brand.toUpperCase().contains('MASTER');

  @override
  Widget build(BuildContext context) {
    final palette = MbongoThemeController.current;
    final titleColor = Colors.white;
    final subtitleColor = const Color(0xFFE6EDF9);
    final active = status.toUpperCase() == 'ACTIVE';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 18 : 22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _isMastercard
              ? const [
                  Color(0xFF171717),
                  Color(0xFF2A2A2A),
                  Color(0xFF101114),
                ]
              : [
                  palette.bannerGradient.first.withValues(alpha: 0.98),
                  palette.bannerGradient.last.withValues(alpha: 0.98),
                  palette.accentStrong.withValues(alpha: 0.92),
                ],
        ),
        borderRadius: BorderRadius.circular(compact ? 18 : 22),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -10,
            top: -10,
            child: Container(
              width: compact ? 110 : 140,
              height: compact ? 110 : 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          Positioned(
            left: 30,
            bottom: -18,
            child: Container(
              width: compact ? 120 : 170,
              height: compact ? 120 : 170,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.04),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _chip(),
                  const Spacer(),
                  _brandMark(),
                ],
              ),
              SizedBox(height: compact ? 22 : 30),
              Text(
                maskedPan,
                style: TextStyle(
                  color: titleColor,
                  fontSize: compact ? 18 : 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: compact ? 1.1 : 1.6,
                ),
              ),
              SizedBox(height: compact ? 18 : 22),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PORTEUR',
                          style: TextStyle(
                            color: subtitleColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          holderName.isEmpty ? 'CLIENT MBONGO' : holderName.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: titleColor,
                            fontSize: compact ? 13 : 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if ((expiry ?? '').isNotEmpty) ...[
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'EXPIRE',
                          style: TextStyle(
                            color: subtitleColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          expiry!,
                          style: TextStyle(
                            color: titleColor,
                            fontSize: compact ? 13 : 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
              SizedBox(height: compact ? 14 : 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      currency,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    active ? 'Active' : 'Bloquee',
                    style: TextStyle(
                      color: active ? Colors.white : AppColors.red,
                      fontWeight: FontWeight.w900,
                      fontSize: 11,
                      letterSpacing: 0.6,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip() {
    return Container(
      width: 42,
      height: 32,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: const LinearGradient(
          colors: [
            Color(0xFFE7C66A),
            Color(0xFFC79B34),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Stack(
        children: [
          Positioned(
            left: 12,
            top: 4,
            bottom: 4,
            child: Container(width: 1.2, color: Colors.white.withValues(alpha: 0.35)),
          ),
          Positioned(
            left: 20,
            top: 4,
            bottom: 4,
            child: Container(width: 1.2, color: Colors.white.withValues(alpha: 0.35)),
          ),
          Positioned(
            left: 28,
            top: 4,
            bottom: 4,
            child: Container(width: 1.2, color: Colors.white.withValues(alpha: 0.35)),
          ),
        ],
      ),
    );
  }

  Widget _brandMark() {
    if (_isMastercard) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFEB001B).withValues(alpha: 0.92),
            ),
          ),
          Transform.translate(
            offset: const Offset(-10, 0),
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFF79E1B).withValues(alpha: 0.92),
              ),
            ),
          ),
          Transform.translate(
            offset: const Offset(-6, 0),
            child: const Text(
              'mastercard',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ),
        ],
      );
    }

    return const Text(
      'VISA',
      style: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w900,
        fontSize: 24,
        letterSpacing: 0.5,
      ),
    );
  }
}
