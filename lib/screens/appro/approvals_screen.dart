import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/mbongo_theme.dart';
import '../../features/wallet/data/wallet_repository.dart';
import '../../widgets/common/mbongo_money_particles.dart';
import '../../widgets/common/mbongo_sub_app_bar.dart';

class ApprovalsScreen extends ConsumerStatefulWidget {
  const ApprovalsScreen({super.key});

  @override
  ConsumerState<ApprovalsScreen> createState() => _ApprovalsScreenState();
}

class _ApprovalsScreenState extends ConsumerState<ApprovalsScreen> {
  List<Map<String, dynamic>> _approvals = [];
  bool _loading = true;
  String? _error;
  final Set<String> _processing = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await ref.read(walletRepositoryProvider).fetchPendingApprovals();
      if (!mounted) return;
      setState(() {
        _approvals = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _approve(String id) async {
    setState(() => _processing.add(id));
    try {
      await ref.read(walletRepositoryProvider).approveRequest(id);
      if (!mounted) return;
      setState(() {
        final idx = _approvals.indexWhere((a) => a['id']?.toString() == id);
        if (idx != -1) _approvals[idx] = {..._approvals[idx], 'status': 'SUCCESS'};
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _processing.remove(id));
    }
  }

  Future<void> _reject(String id) async {
    setState(() => _processing.add(id));
    try {
      await ref.read(walletRepositoryProvider).rejectRequest(id);
      if (!mounted) return;
      setState(() {
        final idx = _approvals.indexWhere((a) => a['id']?.toString() == id);
        if (idx != -1) _approvals[idx] = {..._approvals[idx], 'status': 'FAILED'};
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _processing.remove(id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = MbongoThemeController.current;

    return Scaffold(
      backgroundColor: palette.shellBottom,
      appBar: MbongoSubAppBar(title: 'Approbations'),
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [palette.shellTop, palette.shellBottom],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: MbongoMoneyParticles(
                color: palette.accentStrong,
                count: 19,
                opacity: 0.11,
              ),
            ),
          ),
          SafeArea(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? _buildError(palette)
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView(
                          padding: const EdgeInsets.all(16),
                          children: [
                            _header(palette),
                            const SizedBox(height: 18),
                            if (_approvals.isEmpty)
                              _buildEmpty(palette)
                            else
                              ..._approvals.map((item) => _buildCard(item, palette)),
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(MbongoThemePalette palette) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 56, color: AppColors.red),
            const SizedBox(height: 12),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.darkMuted),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh),
              label: const Text('Reessayer'),
              style: ElevatedButton.styleFrom(backgroundColor: palette.accentStrong),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(MbongoThemePalette palette) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: palette.panelAlt,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.24)),
      ),
      child: Column(
        children: [
          Icon(Icons.check_circle_outline, size: 56, color: AppColors.green),
          const SizedBox(height: 12),
          const Text(
            'Aucune demande en attente',
            style: TextStyle(
              color: AppColors.darkText,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Toutes les demandes ont ete traitees.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.darkMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> item, MbongoThemePalette palette) {
    final id = item['id']?.toString() ?? '';
    final status = (item['status'] ?? 'PENDING').toString().toUpperCase();
    final isPending = status == 'PENDING';
    final isProcessing = _processing.contains(id);

    final amount = ((item['amount'] ?? 0) as num).toDouble();
    final currency = item['currency']?.toString() ?? 'CDF';
    final requester = item['senderPhone']?.toString() ??
        item['requesterPhone']?.toString() ??
        item['senderId']?.toString() ??
        'Inconnu';
    final reason = item['description']?.toString() ??
        item['reason']?.toString() ??
        'Demande d\'argent';

    String statusLabel;
    Color statusColor;
    switch (status) {
      case 'SUCCESS':
        statusLabel = 'APPROUVE';
        statusColor = AppColors.green;
        break;
      case 'FAILED':
        statusLabel = 'REJETE';
        statusColor = AppColors.red;
        break;
      default:
        statusLabel = 'EN ATTENTE';
        statusColor = palette.accentStrong;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
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
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: palette.accent.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.verified_user_rounded, color: palette.accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reason,
                      style: const TextStyle(
                        color: AppColors.darkText,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      requester,
                      style: const TextStyle(
                        color: AppColors.darkMuted,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Montant',
                  style: TextStyle(color: AppColors.darkMuted, fontWeight: FontWeight.w700),
                ),
              ),
              Text(
                '$currency ${amount.toStringAsFixed(2)}',
                style: const TextStyle(color: AppColors.darkText, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Statut',
                  style: TextStyle(color: AppColors.darkMuted, fontWeight: FontWeight.w700),
                ),
              ),
              Text(
                statusLabel,
                style: TextStyle(color: statusColor, fontWeight: FontWeight.w900),
              ),
            ],
          ),
          if (isPending) ...[
            const SizedBox(height: 16),
            isProcessing
                ? const Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)))
                : Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _reject(id),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.red,
                            side: const BorderSide(color: AppColors.red),
                          ),
                          child: const Text('Rejeter'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _approve(id),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.green,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Approuver'),
                        ),
                      ),
                    ],
                  ),
          ],
        ],
      ),
    );
  }

  Widget _header(MbongoThemePalette palette) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: palette.bannerGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.24)),
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
              Icon(Icons.verified_rounded, color: palette.accentStrong),
              const SizedBox(width: 8),
              const Text(
                "Centre d'approbation",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Demandes en attente',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 24,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Validez ou rejetez les operations soumises dans votre espace MBONGO.',
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
}
