import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/dio_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/mbongo_theme.dart';
import '../../widgets/common/mbongo_money_particles.dart';
import '../../widgets/common/mbongo_sub_app_bar.dart';

final _agentsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final client = ref.read(dioClientProvider);
  final resp = await client.get('/transactions/cash-agents');
  final list = resp['data'];
  if (list is List) {
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }
  return [];
});

class AgentsScreen extends ConsumerStatefulWidget {
  const AgentsScreen({super.key});

  @override
  ConsumerState<AgentsScreen> createState() => _AgentsScreenState();
}

class _AgentsScreenState extends ConsumerState<AgentsScreen> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  String _fmt(num v) {
    return v.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]} ',
        );
  }

  List<Map<String, dynamic>> _filter(List<Map<String, dynamic>> agents) {
    if (_query.isEmpty) return agents;
    final q = _query.toLowerCase();
    return agents.where((a) {
      final name = (a['name'] ?? '').toString().toLowerCase();
      final location = (a['location'] ?? '').toString().toLowerCase();
      final code = (a['code'] ?? '').toString().toLowerCase();
      final phone = (a['phone'] ?? '').toString().toLowerCase();
      return name.contains(q) ||
          location.contains(q) ||
          code.contains(q) ||
          phone.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final palette = MbongoThemeController.current;
    final agentsAsync = ref.watch(_agentsProvider);

    return Scaffold(
      backgroundColor: palette.shellBottom,
      appBar: MbongoSubAppBar(
        title: 'Agents de cash',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.text),
            onPressed: () => ref.refresh(_agentsProvider),
          ),
        ],
      ),
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
                  count: 12,
                  opacity: 0.07,
                  height: 0,
                ),
              ),
            ),
            SafeArea(
              child: agentsAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.wifi_off_rounded,
                          color: AppColors.muted, size: 48),
                      const SizedBox(height: 12),
                      const Text('Impossible de charger les agents.',
                          style: TextStyle(
                              color: AppColors.muted,
                              fontWeight: FontWeight.w700)),
                      const SizedBox(height: 14),
                      ElevatedButton(
                        onPressed: () => ref.refresh(_agentsProvider),
                        child: const Text('Reessayer'),
                      ),
                    ],
                  ),
                ),
                data: (agents) {
                  final filtered = _filter(agents);
                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                        child: _buildHeader(palette, agents.length),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
                        child: _buildSearchBar(palette),
                      ),
                      Expanded(
                        child: filtered.isEmpty
                            ? _buildEmpty(palette)
                            : RefreshIndicator(
                                onRefresh: () => ref.refresh(_agentsProvider.future),
                                child: ListView.builder(
                                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                                  itemCount: filtered.length,
                                  itemBuilder: (_, i) => Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: _agentTile(palette, filtered[i]),
                                  ),
                                ),
                              ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(MbongoThemePalette palette, int count) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: palette.bannerGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: palette.glow.withValues(alpha: 0.18),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.store_rounded,
                color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Agents de cash',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 2),
                Text(
                  '$count agents actifs pres de vous',
                  style: const TextStyle(
                      color: Color(0xFFD0DDEE),
                      fontSize: 12,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(MbongoThemePalette palette) {
    return TextField(
      controller: _search,
      style: const TextStyle(color: AppColors.text, fontSize: 14),
      decoration: InputDecoration(
        hintText: 'Nom, code, lieu, telephone...',
        hintStyle:
            const TextStyle(color: AppColors.textSoft, fontSize: 13),
        prefixIcon:
            Icon(Icons.search_rounded, color: palette.accent, size: 20),
        suffixIcon: _query.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.close_rounded,
                    color: AppColors.muted, size: 18),
                onPressed: () {
                  _search.clear();
                  setState(() => _query = '');
                },
              )
            : null,
        filled: true,
        fillColor: palette.panel,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              BorderSide(color: AppColors.border.withValues(alpha: 0.30)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              BorderSide(color: AppColors.border.withValues(alpha: 0.30)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: palette.accent, width: 1.4),
        ),
      ),
      onChanged: (v) => setState(() => _query = v.trim()),
    );
  }

  Widget _agentTile(MbongoThemePalette palette, Map<String, dynamic> a) {
    final name = (a['name'] ?? '').toString();
    final code = (a['code'] ?? '').toString();
    final phone = (a['phone'] ?? '').toString();
    final location = (a['location'] ?? '').toString();
    final cashIn = ((a['dailyCashInLimit'] ?? 0) as num).toDouble();
    final cashOut = ((a['dailyCashOutLimit'] ?? 0) as num).toDouble();

    return Container(
      decoration: BoxDecoration(
        color: palette.panelAlt,
        borderRadius: BorderRadius.circular(18),
        border:
            Border.all(color: AppColors.border.withValues(alpha: 0.22)),
        boxShadow: const [
          BoxShadow(
              color: AppColors.shadow,
              blurRadius: 8,
              offset: Offset(0, 3)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: palette.accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.store_rounded,
                      color: palette.accent, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          color: AppColors.text,
                          fontWeight: FontWeight.w900,
                          fontSize: 14.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.location_on_rounded,
                              color: AppColors.textSoft, size: 12),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              location.isEmpty ? 'Localisation inconnue' : location,
                              style: const TextStyle(
                                  color: AppColors.textSoft,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: palette.accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    code,
                    style: TextStyle(
                      color: palette.accent,
                      fontWeight: FontWeight.w900,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            if (phone.isNotEmpty) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.phone_rounded,
                      color: AppColors.muted, size: 13),
                  const SizedBox(width: 5),
                  Text(
                    phone,
                    style: const TextStyle(
                        color: AppColors.textSoft,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _limitCell(
                      'Depot / jour',
                      '${_fmt(cashIn)} CDF',
                      AppColors.green),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _limitCell(
                      'Retrait / jour',
                      '${_fmt(cashOut)} CDF',
                      AppColors.orange),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _limitCell(String label, String value, Color color) {
    final palette = MbongoThemeController.current;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: palette.panel,
        borderRadius: BorderRadius.circular(10),
        border:
            Border.all(color: AppColors.border.withValues(alpha: 0.20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  color: AppColors.darkMuted,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 3),
          Text(value,
              style: TextStyle(
                  color: color,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Widget _buildEmpty(MbongoThemePalette palette) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off_rounded,
                size: 48, color: AppColors.darkMuted),
            const SizedBox(height: 12),
            Text(
              _query.isNotEmpty
                  ? 'Aucun agent ne correspond a "$_query".'
                  : 'Aucun agent disponible pour le moment.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: AppColors.darkText, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}
