import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/dio_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/mbongo_theme.dart';
import '../../features/auth/presentation/auth_notifier.dart';
import '../../widgets/common/app_scaffold.dart';

class AgentCashInScreen extends ConsumerStatefulWidget {
  const AgentCashInScreen({super.key});

  @override
  ConsumerState<AgentCashInScreen> createState() => _AgentCashInScreenState();
}

class _AgentCashInScreenState extends ConsumerState<AgentCashInScreen> {
  final _phoneCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  bool _loading = false;
  bool _success = false;
  Map<String, dynamic>? _result;

  Future<void> _submit() async {
    final phone = _phoneCtrl.text.trim();
    final amountText = _amountCtrl.text.trim().replaceAll(',', '').replaceAll(' ', '');
    final amount = double.tryParse(amountText);

    if (phone.isEmpty) { _snack('Entrez le numéro du client.'); return; }
    if (amount == null || amount <= 0) { _snack('Montant invalide.'); return; }

    setState(() => _loading = true);
    try {
      final me = ref.read(authProvider.notifier).currentUser;
      final client = ref.read(dioClientProvider);

      // Resolve customer by phone
      final userResp = await client.get('/users/by-phone/$phone');
      final userId = userResp['id']?.toString() ?? userResp['data']?['id']?.toString();
      if (userId == null) { _snack('Client introuvable pour ce numéro.'); return; }

      final resp = await client.post('/transactions/deposit', {
        'userId': userId,
        'amount': amount,
        'source': 'agent_cashin',
        'description': _descCtrl.text.trim().isNotEmpty
            ? _descCtrl.text.trim()
            : 'Cash-In via agent',
        'agentName': me?.name ?? '',
        'agentId': me?.id ?? '',
      });

      if (!mounted) return;
      setState(() {
        _success = true;
        _result = Map<String, dynamic>.from(resp as Map);
      });
    } catch (e) {
      if (!mounted) return;
      _snack(e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  void _reset() => setState(() {
        _success = false;
        _result = null;
        _phoneCtrl.clear();
        _amountCtrl.clear();
        _descCtrl.clear();
      });

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _amountCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = MbongoThemeController.current;

    if (_success) return _SuccessView(result: _result, onReset: _reset, type: 'Cash-In');

    return AppScaffold(
      title: 'Cash-In',
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _header(palette,
              icon: Icons.arrow_downward_rounded,
              color: AppColors.green,
              title: 'Cash-In',
              subtitle: 'Déposez de l\'argent sur le compte d\'un client'),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: palette.panelAlt,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border.withValues(alpha: 0.24)),
            ),
            child: Column(
              children: [
                TextField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Téléphone du client',
                    prefixIcon: Icon(Icons.person_outline),
                    hintText: '0990000000',
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _amountCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Montant (CDF)',
                    prefixIcon: Icon(Icons.attach_money_rounded),
                    hintText: '10000',
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _descCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Note (optionnel)',
                    prefixIcon: Icon(Icons.notes_rounded),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _loading ? null : _submit,
                    icon: _loading
                        ? const SizedBox(
                            width: 18, height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.arrow_downward_rounded),
                    label: const Text('Confirmer le Cash-In'),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.green),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.green.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.green.withValues(alpha: 0.2)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline_rounded, color: AppColors.green, size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Le montant sera crédité immédiatement sur le compte du client.',
                    style: TextStyle(color: AppColors.textSoft, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AgentCashOutScreen extends ConsumerStatefulWidget {
  const AgentCashOutScreen({super.key});

  @override
  ConsumerState<AgentCashOutScreen> createState() => _AgentCashOutScreenState();
}

class _AgentCashOutScreenState extends ConsumerState<AgentCashOutScreen> {
  final _phoneCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  bool _loading = false;
  bool _success = false;
  Map<String, dynamic>? _result;

  Future<void> _submit() async {
    final phone = _phoneCtrl.text.trim();
    final amountText = _amountCtrl.text.trim().replaceAll(',', '').replaceAll(' ', '');
    final amount = double.tryParse(amountText);

    if (phone.isEmpty) { _snack('Entrez le numéro du client.'); return; }
    if (amount == null || amount <= 0) { _snack('Montant invalide.'); return; }

    setState(() => _loading = true);
    try {
      final me = ref.read(authProvider.notifier).currentUser;
      final client = ref.read(dioClientProvider);

      final userResp = await client.get('/users/by-phone/$phone');
      final userId = userResp['id']?.toString() ?? userResp['data']?['id']?.toString();
      if (userId == null) { _snack('Client introuvable pour ce numéro.'); return; }

      final resp = await client.post('/transactions/withdraw', {
        'userId': userId,
        'amount': amount,
        'channel': 'agent_cashout',
        'reference': 'AGENT-${DateTime.now().millisecondsSinceEpoch}',
        'phone': phone,
        'agentName': me?.name ?? '',
        'agentId': me?.id ?? '',
      });

      if (!mounted) return;
      setState(() {
        _success = true;
        _result = Map<String, dynamic>.from(resp as Map);
      });
    } catch (e) {
      if (!mounted) return;
      _snack(e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  void _reset() => setState(() {
        _success = false;
        _result = null;
        _phoneCtrl.clear();
        _amountCtrl.clear();
      });

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = MbongoThemeController.current;

    if (_success) return _SuccessView(result: _result, onReset: _reset, type: 'Cash-Out');

    return AppScaffold(
      title: 'Cash-Out',
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _header(palette,
              icon: Icons.arrow_upward_rounded,
              color: AppColors.orange,
              title: 'Cash-Out',
              subtitle: 'Retirez de l\'argent du compte d\'un client'),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: palette.panelAlt,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border.withValues(alpha: 0.24)),
            ),
            child: Column(
              children: [
                TextField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Téléphone du client',
                    prefixIcon: Icon(Icons.person_outline),
                    hintText: '0990000000',
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _amountCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Montant (CDF)',
                    prefixIcon: Icon(Icons.attach_money_rounded),
                    hintText: '10000',
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _loading ? null : _submit,
                    icon: _loading
                        ? const SizedBox(
                            width: 18, height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.arrow_upward_rounded),
                    label: const Text('Confirmer le Cash-Out'),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.orange),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.orange.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.orange.withValues(alpha: 0.2)),
            ),
            child: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: AppColors.orange, size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Le montant sera débité immédiatement du compte du client.',
                    style: TextStyle(color: AppColors.textSoft, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Shared header builder
Widget _header(dynamic palette, {
  required IconData icon,
  required Color color,
  required String title,
  required String subtitle,
}) {
  return Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [color.withValues(alpha: 0.18), color.withValues(alpha: 0.06)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: color.withValues(alpha: 0.3)),
    ),
    child: Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 26),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      color: AppColors.text, fontSize: 18, fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              Text(subtitle,
                  style: const TextStyle(
                      color: AppColors.textSoft, fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    ),
  );
}

class _SuccessView extends StatelessWidget {
  final Map<String, dynamic>? result;
  final VoidCallback onReset;
  final String type;

  const _SuccessView({required this.result, required this.onReset, required this.type});

  @override
  Widget build(BuildContext context) {
    final palette = MbongoThemeController.current;
    final color = type == 'Cash-In' ? AppColors.green : AppColors.orange;
    final amount = result?['amount']?.toString() ?? '—';
    final ref = result?['reference']?.toString() ?? result?['id']?.toString() ?? '—';

    return AppScaffold(
      title: type,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.13),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check_circle_rounded, color: color, size: 48),
              ),
              const SizedBox(height: 20),
              Text('$type réussi !',
                  style: const TextStyle(
                      color: AppColors.text, fontSize: 22, fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              Text('Montant: $amount CDF',
                  style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text('Réf: $ref',
                  style: const TextStyle(color: AppColors.textSoft, fontSize: 12)),
              const SizedBox(height: 32),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: palette.panelAlt,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border.withValues(alpha: 0.24)),
                ),
                child: Column(
                  children: [
                    ElevatedButton.icon(
                      onPressed: onReset,
                      icon: const Icon(Icons.refresh_rounded),
                      label: Text('Nouvelle opération $type'),
                      style: ElevatedButton.styleFrom(backgroundColor: color),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Retour au dashboard'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
