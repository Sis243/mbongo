import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/mbongo_theme.dart';
import '../../features/cards/presentation/card_notifier.dart';
import '../../widgets/cards/virtual_bank_card.dart';
import '../../widgets/common/mbongo_money_particles.dart';
import 'create_virtual_card_screen.dart';
import 'topup_virtual_card_screen.dart';
import 'virtual_card_details_screen.dart';
import '../../widgets/common/mbongo_sub_app_bar.dart';

class VirtualCardsScreen extends ConsumerWidget {
  const VirtualCardsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = MbongoThemeController.current;
    final cards = ref.watch(cardProvider).valueOrNull ?? [];

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: MbongoSubAppBar(title: 'Cartes virtuelles'),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: palette.accentStrong,
        foregroundColor: Colors.white,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateVirtualCardScreen()),
          );
        },
        icon: const Icon(Icons.add_card_rounded),
        label: const Text('Nouvelle carte'),
      ),
      body: Stack(
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
          ListView(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
            children: [
              _header(cards.length, palette),
              const SizedBox(height: 18),
              if (cards.isEmpty) _emptyState(),
              ...cards.map(
                (card) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _VirtualCardTile(card: card),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _header(int count, MbongoThemePalette palette) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            palette.bannerGradient.first.withValues(alpha: 0.96),
            palette.bannerGradient.last.withValues(alpha: 0.96),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.75)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'Cartes securisees',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '$count active(s)',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Vos cartes virtuelles',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Gerez vos paiements en ligne, definissez vos plafonds et protegez vos operations avec une securite instantanee.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 13.2,
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: const [
              Expanded(child: _SignalPill(label: 'Web', value: 'Paiement')),
              SizedBox(width: 8),
              Expanded(child: _SignalPill(label: 'KYC', value: 'Verifie')),
              SizedBox(width: 8),
              Expanded(child: _SignalPill(label: 'Controle', value: 'Plafonds')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: MbongoThemeController.current.panelAlt,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.border.withValues(alpha: 0.24),
        ),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.credit_card_off_rounded,
            size: 44,
            color: AppColors.darkMuted,
          ),
          SizedBox(height: 10),
          Text(
            'Pas encore de carte',
            style: TextStyle(
              color: AppColors.darkText,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Creez votre premiere carte pour payer en ligne, gerer vos abonnements et controler vos depenses.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.darkMuted,
              fontSize: 13,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _VirtualCardTile extends StatelessWidget {
  final Map<String, dynamic> card;

  const _VirtualCardTile({required this.card});

  @override
  Widget build(BuildContext context) {
    final status = (card['status'] ?? 'ACTIVE').toString();
    final currency = (card['currency'] ?? 'USD').toString();
    final balance = ((card['balance'] ?? 0) as num).toDouble();
    final active = status == 'ACTIVE';
    final palette = MbongoThemeController.current;

    return Container(
      decoration: BoxDecoration(
        color: palette.panelAlt,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.border.withValues(alpha: 0.24),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: VirtualBankCard(
              brand: (card['brand'] ?? 'VISA').toString(),
              holderName: (card['holderName'] ?? 'CLIENT MBONGO').toString(),
              maskedPan: (card['maskedPan'] ?? '**** **** **** ****').toString(),
              currency: currency,
              status: status,
              expiry: (card['expiry'] ?? '').toString(),
              compact: true,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _infoBox('Solde', '$currency ${balance.toStringAsFixed(2)}'),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _infoBox(
                        'Statut',
                        active ? 'Active' : 'Bloquee',
                        valueColor: active ? AppColors.green : AppColors.red,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => VirtualCardDetailsScreen(card: card),
                            ),
                          );
                        },
                        icon: const Icon(Icons.visibility_outlined),
                        label: const Text('Voir'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => TopupVirtualCardScreen(card: card),
                            ),
                          );
                        },
                        icon: const Icon(Icons.add_circle_outline_rounded),
                        label: const Text('Recharger'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoBox(String title, String value, {Color? valueColor}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: MbongoThemeController.current.panel,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: valueColor ?? AppColors.text,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _SignalPill extends StatelessWidget {
  final String label;
  final String value;

  const _SignalPill({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final palette = MbongoThemeController.current;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: palette.panel.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFFE8EEF8),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
