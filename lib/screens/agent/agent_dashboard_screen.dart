import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/dio_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/mbongo_theme.dart';
import '../../core/utils/money.dart' as money_util;
import '../../widgets/common/mbongo_money_particles.dart';

final _agentStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final client = ref.read(dioClientProvider);
  try {
    final resp = await client.get('/transactions/cash-agents');
    final list = resp['data'] ?? resp;
    if (list is List && list.isNotEmpty) {
      return Map<String, dynamic>.from(list.first as Map);
    }
    return {};
  } catch (_) {
    return {};
  }
});

class AgentDashboardScreen extends ConsumerWidget {
  const AgentDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = MbongoThemeController.current;
    final statsAsync = ref.watch(_agentStatsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Stack(
              children: [
                MbongoMoneyParticles(
                  color: palette.accent,
                  count: 12,
                  opacity: 0.07,
                  height: 180,
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 52, 20, 24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: palette.bannerGradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.support_agent_rounded, color: AppColors.cyan, size: 22),
                          SizedBox(width: 8),
                          Text(
                            'Interface Agent',
                            style: TextStyle(
                              color: AppColors.textSoft,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Tableau de bord',
                        style: TextStyle(
                          color: AppColors.text,
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 16),
                      statsAsync.when(
                        data: (agent) => _AgentStats(agent: agent),
                        loading: () => const _StatsShimmer(),
                        error: (_, __) => const _StatsShimmer(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: 8),
                _ActionCard(
                  icon: Icons.arrow_downward_rounded,
                  color: AppColors.green,
                  title: 'Cash-In',
                  subtitle: 'Déposer de l\'argent sur le compte d\'un client',
                  onTap: () => Navigator.pushNamed(context, '/agent/cashin'),
                ),
                const SizedBox(height: 12),
                _ActionCard(
                  icon: Icons.arrow_upward_rounded,
                  color: AppColors.orange,
                  title: 'Cash-Out',
                  subtitle: 'Retirer de l\'argent du compte d\'un client',
                  onTap: () => Navigator.pushNamed(context, '/agent/cashout'),
                ),
                const SizedBox(height: 12),
                statsAsync.when(
                  data: (agent) => _LimitsCard(agent: agent),
                  loading: () => const SizedBox(),
                  error: (_, __) => const SizedBox(),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _AgentStats extends StatelessWidget {
  final Map<String, dynamic> agent;
  const _AgentStats({required this.agent});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatChip(
          label: 'Cash-In limite',
          value: money_util.Money.format(
            (agent['dailyCashInLimit'] as num?)?.toDouble() ?? 0, 'CDF'),
          color: AppColors.green,
        ),
        const SizedBox(width: 10),
        _StatChip(
          label: 'Cash-Out limite',
          value: money_util.Money.format(
            (agent['dailyCashOutLimit'] as num?)?.toDouble() ?? 0, 'CDF'),
          color: AppColors.orange,
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatChip({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.13),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(value,
                style: const TextStyle(
                    color: AppColors.text, fontSize: 13, fontWeight: FontWeight.w900)),
          ],
        ),
      ),
    );
  }
}

class _LimitsCard extends StatelessWidget {
  final Map<String, dynamic> agent;
  const _LimitsCard({required this.agent});

  @override
  Widget build(BuildContext context) {
    final palette = MbongoThemeController.current;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.panelAlt,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Informations agent',
              style: TextStyle(
                  color: AppColors.text, fontSize: 14, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          _InfoRow(label: 'Nom', value: agent['name']?.toString() ?? '—'),
          _InfoRow(label: 'Téléphone', value: agent['phone']?.toString() ?? '—'),
          _InfoRow(label: 'Zone', value: agent['zone']?.toString() ?? '—'),
          _InfoRow(
              label: 'Commission fixe',
              value: '${agent['commissionFixe'] ?? agent['fixedCommission'] ?? 0} FC'),
          _InfoRow(
              label: 'Commission %',
              value: '${agent['commissionPercent'] ?? agent['percentCommission'] ?? 0}%'),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
              flex: 2,
              child: Text(label,
                  style: const TextStyle(color: AppColors.textSoft, fontSize: 12))),
          Expanded(
              flex: 3,
              child: Text(value,
                  style: const TextStyle(
                      color: AppColors.text, fontSize: 12, fontWeight: FontWeight.w700))),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = MbongoThemeController.current;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: palette.panelAlt,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.13),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          color: AppColors.text,
                          fontSize: 16,
                          fontWeight: FontWeight.w900)),
                  const SizedBox(height: 4),
                  Text(subtitle,
                      style: const TextStyle(
                          color: AppColors.textSoft,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textSoft),
          ],
        ),
      ),
    );
  }
}

class _StatsShimmer extends StatelessWidget {
  const _StatsShimmer();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(
          2,
          (_) => Expanded(
                child: Container(
                  margin: const EdgeInsets.only(right: 10),
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              )),
    );
  }
}
