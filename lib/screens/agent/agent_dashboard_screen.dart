import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/api/dio_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/mbongo_theme.dart';
import '../../widgets/common/mbongo_money_particles.dart';
import 'agent_cashin_screen.dart';

final agentProfileProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final client = ref.read(dioClientProvider);
  try {
    final resp = await client.get('/transactions/agent/profit-log');
    return Map<String, dynamic>.from(resp as Map);
  } catch (_) {
    return {};
  }
});

class AgentDashboardScreen extends ConsumerWidget {
  const AgentDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = MbongoThemeController.current;
    final statsAsync = ref.watch(agentProfileProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: RefreshIndicator(
        color: AppColors.orange,
        onRefresh: () => ref.refresh(agentProfileProvider.future),
        child: CustomScrollView(
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
                        statsAsync.when(
                          data: (agent) => Text(
                            agent['agentName']?.toString() ?? 'Tableau de bord',
                            style: const TextStyle(
                              color: AppColors.text,
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          loading: () => const Text(
                            'Tableau de bord',
                            style: TextStyle(
                              color: AppColors.text,
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          error: (_, __) => const SizedBox(),
                        ),
                        const SizedBox(height: 16),
                        statsAsync.when(
                          data: (agent) => _CommissionBanner(agent: agent),
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
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AgentCashInScreen())),
                  ),
                  const SizedBox(height: 12),
                  _ActionCard(
                    icon: Icons.arrow_upward_rounded,
                    color: AppColors.orange,
                    title: 'Cash-Out',
                    subtitle: 'Retirer de l\'argent du compte d\'un client',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AgentCashOutScreen())),
                  ),
                  const SizedBox(height: 18),
                  statsAsync.when(
                    data: (agent) => _CommissionChart(agent: agent),
                    loading: () => const SizedBox(),
                    error: (_, __) => const SizedBox(),
                  ),
                  const SizedBox(height: 12),
                  statsAsync.when(
                    data: (agent) => _AgentInfoCard(agent: agent),
                    loading: () => const SizedBox(),
                    error: (_, __) => const SizedBox(),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CommissionBanner extends StatelessWidget {
  final Map<String, dynamic> agent;
  const _CommissionBanner({required this.agent});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0', 'fr_FR');
    final balance = (agent['commissionBalance'] as num?)?.toDouble() ?? 0;
    final balanceUSD = (agent['commissionBalanceUSD'] as num?)?.toDouble();
    final code = agent['agentCode']?.toString() ?? '';
    final cashIn = (agent['dailyCashInLimit'] as num?)?.toDouble() ?? 0;
    final cashOut = (agent['dailyCashOutLimit'] as num?)?.toDouble() ?? 0;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.orange.withValues(alpha: 0.13),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.orange.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.account_balance_wallet_rounded, color: AppColors.orange, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Commissions disponibles',
                        style: TextStyle(color: AppColors.textSoft, fontSize: 11, fontWeight: FontWeight.w700)),
                    Text('${fmt.format(balance)} CDF',
                        style: const TextStyle(
                            color: AppColors.orange, fontSize: 20, fontWeight: FontWeight.w900)),
                    if (balanceUSD != null)
                      Text('≈ \$${balanceUSD.toStringAsFixed(2)} USD',
                          style: TextStyle(
                              color: AppColors.orange.withValues(alpha: 0.7),
                              fontSize: 12,
                              fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
              if (code.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.orange.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(code,
                      style: const TextStyle(
                          color: AppColors.orange, fontSize: 11, fontWeight: FontWeight.w900)),
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _LimitChip(label: 'Limite Cash-In', value: '${fmt.format(cashIn)} CDF', color: AppColors.green),
            const SizedBox(width: 10),
            _LimitChip(label: 'Limite Cash-Out', value: '${fmt.format(cashOut)} CDF', color: AppColors.orange),
          ],
        ),
      ],
    );
  }
}

class _LimitChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _LimitChip({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.28)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(value,
                style: const TextStyle(color: AppColors.text, fontSize: 12, fontWeight: FontWeight.w900)),
          ],
        ),
      ),
    );
  }
}

class _CommissionChart extends StatelessWidget {
  final Map<String, dynamic> agent;
  const _CommissionChart({required this.agent});

  @override
  Widget build(BuildContext context) {
    final palette = MbongoThemeController.current;
    final txns = (agent['transactions'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    if (txns.isEmpty) return const SizedBox();

    // Group commissions by day (last 7 entries)
    final Map<String, double> byDay = {};
    for (final t in txns.take(20)) {
      final raw = t['createdAt']?.toString() ?? '';
      final date = DateTime.tryParse(raw);
      if (date == null) continue;
      final key = '${date.day}/${date.month}';
      final commission = (t['commission'] as num?)?.toDouble() ?? 0;
      byDay[key] = (byDay[key] ?? 0) + commission;
    }

    final keys = byDay.keys.toList().reversed.take(7).toList().reversed.toList();
    final values = keys.map((k) => byDay[k] ?? 0).toList();
    final maxVal = values.fold<double>(0, (a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: palette.panelAlt,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.bar_chart_rounded, color: AppColors.orange, size: 18),
              SizedBox(width: 8),
              Text('Commissions par jour',
                  style: TextStyle(
                      color: AppColors.darkText, fontSize: 15, fontWeight: FontWeight.w900)),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 150,
            child: keys.isEmpty
                ? const Center(
                    child: Text('Aucune donnée',
                        style: TextStyle(color: AppColors.darkMuted)))
                : BarChart(
                    BarChartData(
                      maxY: maxVal <= 0 ? 10 : maxVal * 1.2,
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (_) => FlLine(
                          color: AppColors.border.withValues(alpha: 0.18),
                          strokeWidth: 1,
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, _) {
                              final i = value.toInt();
                              if (i < 0 || i >= keys.length) return const SizedBox();
                              return Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(keys[i],
                                    style: const TextStyle(
                                        color: AppColors.darkMuted,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700)),
                              );
                            },
                          ),
                        ),
                      ),
                      barGroups: List.generate(keys.length, (i) {
                        return BarChartGroupData(
                          x: i,
                          barRods: [
                            BarChartRodData(
                              toY: values[i],
                              color: AppColors.orange,
                              width: 18,
                              borderRadius: BorderRadius.circular(6),
                              backDrawRodData: BackgroundBarChartRodData(
                                show: true,
                                toY: maxVal <= 0 ? 10 : maxVal * 1.2,
                                color: AppColors.orange.withValues(alpha: 0.08),
                              ),
                            ),
                          ],
                        );
                      }),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _AgentInfoCard extends StatelessWidget {
  final Map<String, dynamic> agent;
  const _AgentInfoCard({required this.agent});

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
          const Row(
            children: [
              Icon(Icons.badge_rounded, color: AppColors.cyan, size: 18),
              SizedBox(width: 8),
              Text('Informations agent',
                  style: TextStyle(color: AppColors.text, fontSize: 14, fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 12),
          _InfoRow(label: 'Nom', value: agent['agentName']?.toString() ?? '—'),
          _InfoRow(label: 'Téléphone', value: agent['phone']?.toString() ?? '—'),
          _InfoRow(label: 'Zone', value: agent['zone']?.toString() ?? '—'),
          _InfoRow(label: 'Code', value: agent['agentCode']?.toString() ?? '—'),
          _InfoRow(
              label: 'Commission fixe',
              value: '${agent['commissionFixe'] ?? 0} CDF'),
          _InfoRow(
              label: 'Commission %',
              value: '${agent['commissionPercent'] ?? 0}%'),
          _InfoRow(
              label: 'Statut',
              value: (agent['isActive'] == true) ? 'Actif' : 'Inactif'),
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
    return Column(
      children: [
        Container(
          height: 64,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: List.generate(
              2,
              (_) => Expanded(
                    child: Container(
                      margin: const EdgeInsets.only(right: 10),
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  )),
        ),
      ],
    );
  }
}
