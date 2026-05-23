import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/dio_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/mbongo_theme.dart';
import '../../widgets/common/mbongo_money_particles.dart';
import '../../widgets/common/mbongo_sub_app_bar.dart';

final _myDisputesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final client = ref.read(dioClientProvider);
  final resp = await client.get('/transactions/disputes');
  final list = resp['data'];
  if (list is List) {
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }
  return [];
});

class DisputeScreen extends ConsumerStatefulWidget {
  final String? prefilledTransactionId;

  const DisputeScreen({super.key, this.prefilledTransactionId});

  @override
  ConsumerState<DisputeScreen> createState() => _DisputeScreenState();
}

class _DisputeScreenState extends ConsumerState<DisputeScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;
  final txIdCtrl = TextEditingController();
  final subjectCtrl = TextEditingController();
  final descCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    if (widget.prefilledTransactionId != null) {
      txIdCtrl.text = widget.prefilledTransactionId!;
    }
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    txIdCtrl.dispose();
    subjectCtrl.dispose();
    descCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (txIdCtrl.text.trim().isEmpty) {
      _toast('Veuillez saisir l\'ID de la transaction.');
      return;
    }
    if (subjectCtrl.text.trim().isEmpty) {
      _toast('Veuillez saisir un objet.');
      return;
    }
    if (descCtrl.text.trim().isEmpty) {
      _toast('Veuillez decrire le probleme.');
      return;
    }

    setState(() => _submitting = true);
    try {
      final client = ref.read(dioClientProvider);
      await client.post('/transactions/${txIdCtrl.text.trim()}/dispute', {
        'subject': subjectCtrl.text.trim(),
        'description': descCtrl.text.trim(),
      });
      if (!mounted) return;
      _toast('Litige soumis avec succes. Notre equipe vous recontactera.');
      txIdCtrl.clear();
      subjectCtrl.clear();
      descCtrl.clear();
      // ignore: unused_result
      ref.refresh(_myDisputesProvider.future);
      _tabCtrl.animateTo(1);
    } catch (e) {
      if (!mounted) return;
      _toast(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final palette = MbongoThemeController.current;

    return Scaffold(
      backgroundColor: palette.shellBottom,
      appBar: MbongoSubAppBar(title: 'Litiges & Réclamations'),
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
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: palette.panelAlt,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border.withValues(alpha: 0.3)),
                      ),
                      child: TabBar(
                        controller: _tabCtrl,
                        indicator: BoxDecoration(
                          color: palette.accentStrong,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        indicatorSize: TabBarIndicatorSize.tab,
                        labelColor: Colors.white,
                        unselectedLabelColor: AppColors.darkMuted,
                        labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
                        dividerColor: Colors.transparent,
                        tabs: const [
                          Tab(text: 'Nouveau litige'),
                          Tab(text: 'Mes litiges'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: TabBarView(
                      controller: _tabCtrl,
                      children: [
                        _buildNewDisputeTab(palette),
                        _buildMyDisputesTab(palette),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewDisputeTab(MbongoThemePalette palette) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        _buildHeaderCard(palette),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: palette.panelAlt,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.border.withValues(alpha: 0.24)),
            boxShadow: const [
              BoxShadow(color: AppColors.shadow, blurRadius: 14, offset: Offset(0, 7)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.report_problem_outlined, color: palette.accent),
                  const SizedBox(width: 8),
                  const Text(
                    'Soumettre un litige',
                    style: TextStyle(color: AppColors.darkText, fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _field(
                palette: palette,
                controller: txIdCtrl,
                label: 'ID de la transaction',
                hint: 'Collez l\'ID depuis votre historique',
                icon: Icons.receipt_outlined,
              ),
              const SizedBox(height: 14),
              _field(
                palette: palette,
                controller: subjectCtrl,
                label: 'Objet du litige',
                hint: 'Ex: Transaction non reconnue, montant incorrect...',
                icon: Icons.subject_rounded,
              ),
              const SizedBox(height: 14),
              _field(
                palette: palette,
                controller: descCtrl,
                label: 'Description detaillee',
                hint: 'Decrivez le probleme avec tous les details necessaires...',
                icon: Icons.edit_note_rounded,
                maxLines: 4,
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        ElevatedButton.icon(
          onPressed: _submitting ? null : _submit,
          icon: _submitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.send_rounded),
          label: Text(_submitting ? 'Envoi en cours...' : 'Soumettre le litige'),
          style: ElevatedButton.styleFrom(
            backgroundColor: palette.accentStrong,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.gold.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.gold.withValues(alpha: 0.22)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline_rounded, color: AppColors.gold, size: 18),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Notre equipe de support traite les litiges dans un delai de 2 a 5 jours ouvrables. Vous serez notifie par l\'application.',
                  style: TextStyle(
                    color: AppColors.darkMuted,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMyDisputesTab(MbongoThemePalette palette) {
    final disputesAsync = ref.watch(_myDisputesProvider);

    return disputesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, color: AppColors.muted, size: 48),
            const SizedBox(height: 12),
            const Text('Impossible de charger vos litiges.',
                style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700)),
            const SizedBox(height: 14),
            ElevatedButton(
              onPressed: () => ref.refresh(_myDisputesProvider),
              child: const Text('Reessayer'),
            ),
          ],
        ),
      ),
      data: (disputes) {
        if (disputes.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: palette.panelAlt,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.gavel_rounded,
                      size: 48,
                      color: palette.accent.withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Aucun litige',
                    style: TextStyle(
                      color: AppColors.darkText,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Vous n\'avez soumis aucun litige pour le moment.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.darkMuted, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => ref.refresh(_myDisputesProvider.future),
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            itemCount: disputes.length,
            itemBuilder: (_, i) => _disputeTile(palette, disputes[i]),
          ),
        );
      },
    );
  }

  Widget _disputeTile(MbongoThemePalette palette, Map<String, dynamic> d) {
    final status = (d['status'] ?? 'OPEN').toString();
    final subject = (d['subject'] ?? '').toString();
    final resolution = (d['resolution'] ?? '').toString();
    final createdAt = DateTime.tryParse(d['createdAt']?.toString() ?? '') ?? DateTime.now();

    Color statusColor;
    String statusLabel;
    switch (status) {
      case 'RESOLVED':
        statusColor = AppColors.green;
        statusLabel = 'Resolu';
        break;
      case 'REJECTED':
        statusColor = AppColors.red;
        statusLabel = 'Rejete';
        break;
      case 'IN_REVIEW':
        statusColor = AppColors.gold;
        statusLabel = 'En cours';
        break;
      default:
        statusColor = palette.accent;
        statusLabel = 'Ouvert';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.panelAlt,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  subject,
                  style: const TextStyle(
                    color: AppColors.darkText,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          if (resolution.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Resolution: $resolution',
              style: const TextStyle(
                color: AppColors.darkMuted,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 6),
          Text(
            'Soumis le ${createdAt.day.toString().padLeft(2, '0')}/${createdAt.month.toString().padLeft(2, '0')}/${createdAt.year}',
            style: const TextStyle(
              color: AppColors.darkMuted,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCard(MbongoThemePalette palette) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: palette.bannerGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
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
              Icon(Icons.gavel_rounded, color: palette.accentStrong),
              const SizedBox(width: 8),
              const Text(
                'Litiges & Reclamations',
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Signalez un probleme',
            style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          const Text(
            'Si vous constatez une transaction incorrecte ou non autorisee sur votre compte, soumettez un litige et notre equipe traitera votre demande rapidement.',
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

  Widget _field({
    required MbongoThemePalette palette,
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: AppColors.text, fontWeight: FontWeight.w700),
      decoration: InputDecoration(
        filled: true,
        fillColor: palette.panel,
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(color: AppColors.muted),
        hintStyle: const TextStyle(color: AppColors.muted),
        prefixIcon: Icon(icon, color: AppColors.primary),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: AppColors.border.withValues(alpha: 0.24)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: palette.accent, width: 1.4),
        ),
      ),
    );
  }
}
