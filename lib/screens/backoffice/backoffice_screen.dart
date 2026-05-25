import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/dio_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/mbongo_theme.dart';
import '../../features/wallet/presentation/wallet_notifier.dart';
import '../../services/backoffice_service.dart';
import '../../widgets/common/mbongo_money_particles.dart';
import '../merchant/pos_ticket_details_screen.dart';

final _bMerchantsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  try {
    final resp = await ref.read(dioClientProvider).get('/merchant/accounts');
    final list = resp['data'];
    if (list is List) return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  } catch (_) {}
  return [];
});

final _bTerminalsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  try {
    final resp = await ref.read(dioClientProvider).get('/merchant/terminals');
    final list = resp['data'];
    if (list is List) return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  } catch (_) {}
  return [];
});

final _bReceiptsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  try {
    final resp = await ref.read(dioClientProvider).get('/merchant/pos-receipts');
    final list = resp['data'];
    if (list is List) return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  } catch (_) {}
  return [];
});

final _bAgentsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  try {
    final resp = await ref.read(dioClientProvider).get('/backoffice/agents');
    final list = resp['agents'] ?? resp['data'];
    if (list is List) return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  } catch (_) {}
  return [];
});

final _bRolesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  try {
    final resp = await ref.read(dioClientProvider).get('/merchant/roles');
    final list = resp['data'];
    if (list is List) return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  } catch (_) {}
  return [];
});

final _bCardsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  try {
    final resp = await ref.read(dioClientProvider).get('/cards/me');
    final list = resp['data'];
    if (list is List) return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  } catch (_) {}
  return [];
});

enum _AdminSection {
  overview,
  merchants,
  agents,
  terminals,
  tickets,
  integrations,
  kyc,
}

class BackofficeScreen extends ConsumerStatefulWidget {
  const BackofficeScreen({super.key});

  @override
  ConsumerState<BackofficeScreen> createState() => _BackofficeScreenState();
}

class _BackofficeScreenState extends ConsumerState<BackofficeScreen> {
  _AdminSection _section = _AdminSection.overview;

  @override
  Widget build(BuildContext context) {
    final merchants = ref.watch(_bMerchantsProvider).valueOrNull ?? [];
    final agents = ref.watch(_bAgentsProvider).valueOrNull ?? [];
    final terminals = ref.watch(_bTerminalsProvider).valueOrNull ?? [];
    final receipts = ref.watch(_bReceiptsProvider).valueOrNull ?? [];
    final roles = ref.watch(_bRolesProvider).valueOrNull ?? [];
    final virtualCards = ref.watch(_bCardsProvider).valueOrNull ?? [];
    final wallet = ref.watch(walletProvider).valueOrNull;
    final transactions = wallet?.transactions.map((t) => t.toMap()).toList() ?? [];

    return ValueListenableBuilder<List<IntegrationChannel>>(
      valueListenable: BackofficeService.channels,
      builder: (context, channels, _) {
        final palette = MbongoThemeController.current;
        final data = _AdminData(
          channels: channels,
          merchants: merchants,
          agents: agents,
          terminals: terminals,
          receipts: receipts,
          roles: roles,
          virtualCards: virtualCards,
          transactions: transactions,
          kycQueue: BackofficeService.kycQueue,
        );

        return Scaffold(
          backgroundColor: palette.shellBottom,
          body: Stack(
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [palette.shellTop, palette.shellBottom],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: IgnorePointer(
                  child: MbongoMoneyParticles(
                    color: palette.accentStrong,
                    count: 26,
                    opacity: 0.08,
                    height: 0,
                  ),
                ),
              ),
              SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final desktop = constraints.maxWidth >= 1100;
                    final sidebar = _AdminSidebar(
                      current: _section,
                      onSelect: (section) {
                        setState(() => _section = section);
                      },
                    );
                    final content = _AdminContent(
                      section: _section,
                      data: data,
                      onCreateMerchant: () => _showMerchantDialog(),
                      onCreateAgent: () => _showCreateAgentDialog(),
                      onCreateTerminal: () => _showTerminalDialog(data.merchants),
                      onAssignRole: () => _showRoleDialog(data.merchants),
                    );

                    if (desktop) {
                      return Row(
                        children: [
                          SizedBox(width: 290, child: sidebar),
                          Expanded(child: content),
                        ],
                      );
                    }

                    return Column(
                      children: [
                        SizedBox(height: 148, child: sidebar),
                        Expanded(child: content),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showMerchantDialog({Map<String, dynamic>? merchant}) async {
    final nameCtrl = TextEditingController(
      text: merchant == null ? '' : merchant['name']?.toString() ?? '',
    );
    final categoryCtrl = TextEditingController(
      text: merchant == null ? '' : merchant['category']?.toString() ?? '',
    );
    final locCtrl = TextEditingController(
      text: merchant == null ? '' : merchant['location']?.toString() ?? '',
    );

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final palette = MbongoThemeController.current;
        return AlertDialog(
          backgroundColor: palette.panel,
          title: Text(
            merchant == null ? 'Nouveau compte marchand' : 'Modifier le compte marchand',
            style: const TextStyle(color: AppColors.text),
          ),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Nom'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: categoryCtrl,
                  decoration: const InputDecoration(labelText: 'Activite'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: locCtrl,
                  decoration: const InputDecoration(labelText: 'Zone'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                try {
                  final body = {
                    'name': nameCtrl.text.trim().isEmpty
                        ? (merchant?['name']?.toString() ?? 'Marchand')
                        : nameCtrl.text.trim(),
                    'category': categoryCtrl.text.trim().isEmpty
                        ? (merchant?['category']?.toString() ?? 'Commerce')
                        : categoryCtrl.text.trim(),
                    'location': locCtrl.text.trim().isEmpty
                        ? (merchant?['location']?.toString() ?? 'Kinshasa')
                        : locCtrl.text.trim(),
                  };
                  if (merchant != null) {
                    await ref
                        .read(dioClientProvider)
                        .patch('/merchant/accounts/${merchant['id']}', body);
                  } else {
                    await ref.read(dioClientProvider).post('/merchant/accounts', body);
                  }
                  ref.refresh(_bMerchantsProvider.future).ignore();
                } catch (_) {}
              },
              child: const Text('Enregistrer'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showTerminalDialog(List<Map<String, dynamic>> merchants) async {
    final merchant = merchants.isNotEmpty ? merchants.first : null;
    String merchantId = merchant == null ? '' : merchant['id']?.toString() ?? '';
    String merchantName = merchant == null ? '' : merchant['name']?.toString() ?? '';
    final terminalCtrl = TextEditingController();
    final locCtrl = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final palette = MbongoThemeController.current;
            return AlertDialog(
              backgroundColor: palette.panel,
              title: const Text(
                'Onboarding terminal POS',
                style: TextStyle(color: AppColors.text),
              ),
              content: SizedBox(
                width: 440,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: merchantId.isEmpty ? null : merchantId,
                      items: merchants
                          .map(
                            (item) => DropdownMenuItem<String>(
                              value: item['id'].toString(),
                              child: Text(item['name'].toString()),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        final selected = merchants.firstWhere(
                          (item) => item['id'].toString() == value,
                          orElse: () => <String, dynamic>{},
                        );
                        setDialogState(() {
                          merchantId = value ?? '';
                          merchantName = selected['name']?.toString() ?? '';
                        });
                      },
                      decoration: const InputDecoration(labelText: 'Marchand'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: terminalCtrl,
                      decoration: const InputDecoration(labelText: 'ID terminal'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: locCtrl,
                      decoration: const InputDecoration(labelText: 'Emplacement'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Annuler'),
                ),
                ElevatedButton(
                  onPressed: merchantId.isEmpty
                      ? null
                      : () async {
                          Navigator.pop(dialogContext);
                          try {
                            await ref.read(dioClientProvider).post('/merchant/terminals', {
                              'merchantId': merchantId,
                              'merchantName': merchantName,
                              'terminalId': terminalCtrl.text.trim().isEmpty
                                  ? 'POS-${DateTime.now().millisecondsSinceEpoch}'
                                  : terminalCtrl.text.trim(),
                              'location': locCtrl.text.trim().isEmpty
                                  ? 'Point de vente'
                                  : locCtrl.text.trim(),
                            });
                            ref.refresh(_bTerminalsProvider.future).ignore();
                          } catch (_) {}
                        },
                  child: const Text('Activer'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showRoleDialog(List<Map<String, dynamic>> merchants) async {
    final merchant = merchants.isNotEmpty ? merchants.first : null;
    String merchantId = merchant == null ? '' : merchant['id']?.toString() ?? '';
    String merchantName = merchant == null ? '' : merchant['name']?.toString() ?? '';
    String role = 'admin';
    final nameCtrl = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final palette = MbongoThemeController.current;
            return AlertDialog(
              backgroundColor: palette.panel,
              title: const Text(
                'Permission marchand',
                style: TextStyle(color: AppColors.text),
              ),
              content: SizedBox(
                width: 440,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: merchantId.isEmpty ? null : merchantId,
                      items: merchants
                          .map(
                            (item) => DropdownMenuItem<String>(
                              value: item['id'].toString(),
                              child: Text(item['name'].toString()),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        final selected = merchants.firstWhere(
                          (item) => item['id'].toString() == value,
                          orElse: () => <String, dynamic>{},
                        );
                        setDialogState(() {
                          merchantId = value ?? '';
                          merchantName = selected['name']?.toString() ?? '';
                        });
                      },
                      decoration: const InputDecoration(labelText: 'Marchand'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(labelText: 'Collaborateur'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: role,
                      items: const [
                        DropdownMenuItem(value: 'admin', child: Text('Admin')),
                        DropdownMenuItem(value: 'commercial', child: Text('Commercial')),
                        DropdownMenuItem(value: 'caissier', child: Text('Caissier')),
                      ],
                      onChanged: (value) {
                        setDialogState(() => role = value ?? 'admin');
                      },
                      decoration: const InputDecoration(labelText: 'Role'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Annuler'),
                ),
                ElevatedButton(
                  onPressed: merchantId.isEmpty
                      ? null
                      : () async {
                          Navigator.pop(dialogContext);
                          try {
                            await ref.read(dioClientProvider).post('/merchant/roles', {
                              'merchantId': merchantId,
                              'merchantName': merchantName,
                              'name': nameCtrl.text.trim().isEmpty
                                  ? 'Nouveau profil'
                                  : nameCtrl.text.trim(),
                              'role': role,
                            });
                            ref.refresh(_bRolesProvider.future).ignore();
                          } catch (_) {}
                        },
                  child: const Text('Attribuer'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showCreateAgentDialog() async {
    final phoneCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final locationCtrl = TextEditingController();
    final cashInCtrl = TextEditingController(text: '5000000');
    final cashOutCtrl = TextEditingController(text: '5000000');

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final palette = MbongoThemeController.current;
        return AlertDialog(
          backgroundColor: palette.panel,
          title: const Text('Enregistrer un agent', style: TextStyle(color: AppColors.text)),
          content: SizedBox(
            width: 440,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Numero de telephone',
                    hintText: 'Ex: 0990000000',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Nom complet'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: locationCtrl,
                  decoration: const InputDecoration(labelText: 'Zone / Emplacement'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: cashInCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Limite Cash-In (CDF)'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: cashOutCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Limite Cash-Out (CDF)'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                final phone = phoneCtrl.text.trim();
                if (phone.isEmpty) return;
                Navigator.pop(dialogContext);
                try {
                  await ref.read(dioClientProvider).post('/backoffice/agents', {
                    'phone': phone,
                    if (nameCtrl.text.trim().isNotEmpty) 'name': nameCtrl.text.trim(),
                    if (locationCtrl.text.trim().isNotEmpty) 'location': locationCtrl.text.trim(),
                    'dailyCashInLimit': int.tryParse(cashInCtrl.text.trim()) ?? 5000000,
                    'dailyCashOutLimit': int.tryParse(cashOutCtrl.text.trim()) ?? 5000000,
                  });
                  ref.refresh(_bAgentsProvider.future).ignore();
                } catch (_) {}
              },
              child: const Text('Enregistrer'),
            ),
          ],
        );
      },
    );
  }
}

class _AdminData {
  final List<IntegrationChannel> channels;
  final List<Map<String, dynamic>> merchants;
  final List<Map<String, dynamic>> agents;
  final List<Map<String, dynamic>> terminals;
  final List<Map<String, dynamic>> receipts;
  final List<Map<String, dynamic>> roles;
  final List<Map<String, dynamic>> virtualCards;
  final List<Map<String, dynamic>> transactions;
  final List<KycReviewItem> kycQueue;

  const _AdminData({
    required this.channels,
    required this.merchants,
    required this.agents,
    required this.terminals,
    required this.receipts,
    required this.roles,
    required this.virtualCards,
    required this.transactions,
    required this.kycQueue,
  });
}

class _AdminSidebar extends StatelessWidget {
  final _AdminSection current;
  final ValueChanged<_AdminSection> onSelect;

  const _AdminSidebar({
    required this.current,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final palette = MbongoThemeController.current;
    final items = <({String label, IconData icon, _AdminSection section})>[
      (label: 'Vue globale', icon: Icons.dashboard_rounded, section: _AdminSection.overview),
      (label: 'Marchands', icon: Icons.storefront_rounded, section: _AdminSection.merchants),
      (label: 'Agents', icon: Icons.support_agent_rounded, section: _AdminSection.agents),
      (label: 'Terminaux POS', icon: Icons.point_of_sale_rounded, section: _AdminSection.terminals),
      (label: 'Tickets', icon: Icons.receipt_long_rounded, section: _AdminSection.tickets),
      (label: 'Integrations', icon: Icons.hub_rounded, section: _AdminSection.integrations),
      (label: 'KYC', icon: Icons.verified_user_rounded, section: _AdminSection.kyc),
    ];

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: palette.panel.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.24)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final desktop = constraints.maxHeight > 250;
          final nav = desktop
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: items
                      .map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _SidebarButton(
                            label: item.label,
                            icon: item.icon,
                            active: current == item.section,
                            onTap: () => onSelect(item.section),
                          ),
                        ),
                      )
                      .toList(),
                )
              : ListView(
                  scrollDirection: Axis.horizontal,
                  children: items
                      .map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: SizedBox(
                            width: 148,
                            child: _SidebarButton(
                              label: item.label,
                              icon: item.icon,
                              active: current == item.section,
                              onTap: () => onSelect(item.section),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'MBONGO ADMIN',
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Portail web backoffice avec le module marchand integre.',
                style: TextStyle(
                  color: AppColors.darkMuted,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: palette.accentStrong.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: palette.accentStrong.withValues(alpha: 0.24)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.language_rounded, color: palette.accentStrong, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Lien dedie admin web',
                        style: TextStyle(
                          color: AppColors.text,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Expanded(child: nav),
            ],
          );
        },
      ),
    );
  }
}

class _SidebarButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  const _SidebarButton({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = MbongoThemeController.current;
    return Material(
      color: active ? palette.accentStrong.withValues(alpha: 0.10) : Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: active
                  ? palette.accentStrong.withValues(alpha: 0.24)
                  : AppColors.border.withValues(alpha: 0.20),
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: active ? palette.accentStrong : AppColors.darkMuted),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: AppColors.text,
                    fontWeight: active ? FontWeight.w900 : FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminContent extends StatelessWidget {
  final _AdminSection section;
  final _AdminData data;
  final VoidCallback onCreateMerchant;
  final VoidCallback onCreateAgent;
  final VoidCallback onCreateTerminal;
  final VoidCallback onAssignRole;

  const _AdminContent({
    required this.section,
    required this.data,
    required this.onCreateMerchant,
    required this.onCreateAgent,
    required this.onCreateTerminal,
    required this.onAssignRole,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(0, 16, 16, 16),
      child: Column(
        children: [
          _AdminHero(data: data),
          const SizedBox(height: 16),
          _buildSection(context),
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context) {
    return switch (section) {
      _AdminSection.overview => _OverviewSection(data: data),
      _AdminSection.merchants => _MerchantsSection(
          data: data,
          onCreateMerchant: onCreateMerchant,
          onCreateTerminal: onCreateTerminal,
          onAssignRole: onAssignRole,
        ),
      _AdminSection.agents => _AgentsSection(
          data: data,
          onCreateAgent: onCreateAgent,
        ),
      _AdminSection.terminals => _TerminalsSection(
          data: data,
          onCreateTerminal: onCreateTerminal,
        ),
      _AdminSection.tickets => _TicketsSection(data: data),
      _AdminSection.integrations => _IntegrationsSection(data: data),
      _AdminSection.kyc => _KycSection(data: data),
    };
  }
}

class _AdminHero extends StatelessWidget {
  final _AdminData data;

  const _AdminHero({required this.data});

  @override
  Widget build(BuildContext context) {
    final palette = MbongoThemeController.current;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            palette.bannerGradient.first.withValues(alpha: 0.96),
            palette.bannerGradient.last.withValues(alpha: 0.96),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.24)),
      ),
      child: Wrap(
        runSpacing: 16,
        spacing: 16,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Acces administrateur web',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'Le backoffice centralise maintenant le marchand, les terminaux POS, les tickets, les integrations et la revue KYC dans un seul environnement d administration.',
                  style: TextStyle(
                    color: AppColors.textSoft,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _HeroSignal(
            label: 'Marchands',
            value: '${data.merchants.length}',
          ),
          _HeroSignal(
            label: 'POS actifs',
            value: '${data.terminals.length}',
          ),
          _HeroSignal(
            label: 'Tickets du jour',
            value: '${data.receipts.length}',
          ),
          _HeroSignal(
            label: 'Cartes',
            value: '${data.virtualCards.length}',
          ),
        ],
      ),
    );
  }
}

class _HeroSignal extends StatelessWidget {
  final String label;
  final String value;

  const _HeroSignal({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final palette = MbongoThemeController.current;
    return Container(
      width: 150,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.panel.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSoft,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _OverviewSection extends StatelessWidget {
  final _AdminData data;

  const _OverviewSection({required this.data});

  @override
  Widget build(BuildContext context) {
    final metrics = [
      ('Canaux actifs', '${data.channels.where((item) => item.enabled).length}', 'Routage ouvert'),
      ('Marchands', '${data.merchants.length}', 'Comptes supervises'),
      ('Cartes virtuelles', '${data.virtualCards.length}', 'Donnees backend'),
      ('Ledger', '${data.transactions.length}', 'Mouvements reels'),
    ];

    return Column(
      children: [
        Wrap(
          spacing: 14,
          runSpacing: 14,
          children: metrics
              .map(
                (item) => SizedBox(
                  width: 230,
                  child: _GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.$1,
                          style: const TextStyle(
                            color: AppColors.textSoft,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          item.$2,
                          style: const TextStyle(
                            color: AppColors.text,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          item.$3,
                          style: const TextStyle(
                            color: AppColors.textSoft,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _PanelTitle('Activite recente'),
                    const SizedBox(height: 12),
                    ...data.transactions.take(4).map(
                      (transaction) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _LedgerTile(transaction: transaction),
                      ),
                    ),
                    if (data.transactions.isEmpty)
                      const Text(
                        'Aucun mouvement ledger synchronise.',
                        style: TextStyle(
                          color: AppColors.darkMuted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _PanelTitle('KYC prioritaire'),
                    const SizedBox(height: 12),
                    ...data.kycQueue.take(4).map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _KycTile(item: item),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MerchantsSection extends StatelessWidget {
  final _AdminData data;
  final VoidCallback onCreateMerchant;
  final VoidCallback onCreateTerminal;
  final VoidCallback onAssignRole;

  const _MerchantsSection({
    required this.data,
    required this.onCreateMerchant,
    required this.onCreateTerminal,
    required this.onAssignRole,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ActionHeader(
          title: 'Comptes marchands',
          subtitle: 'Le marchand est maintenant inclus dans le backoffice administrateur.',
          actions: [
            _HeaderAction(label: 'Nouveau marchand', onTap: onCreateMerchant),
            _HeaderAction(label: 'Nouveau terminal', onTap: onCreateTerminal),
            _HeaderAction(label: 'Nouvelle permission', onTap: onAssignRole),
          ],
        ),
        const SizedBox(height: 14),
        ...data.merchants.map(
          (merchant) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _MerchantTile(
              merchant: merchant,
              roles: data.roles.where((role) => role['merchantId'] == merchant['id']).toList(),
              onEdit: () {
                final state = context.findAncestorStateOfType<_BackofficeScreenState>();
                state?._showMerchantDialog(merchant: merchant);
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _TerminalsSection extends StatelessWidget {
  final _AdminData data;
  final VoidCallback onCreateTerminal;

  const _TerminalsSection({
    required this.data,
    required this.onCreateTerminal,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ActionHeader(
          title: 'Journal des terminaux',
          subtitle: 'Suivi des POS, derniere methode de paiement et etat des appareils.',
          actions: [
            _HeaderAction(label: 'Onboarder un POS', onTap: onCreateTerminal),
          ],
        ),
        const SizedBox(height: 14),
        ...data.terminals.map(
          (terminal) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _TerminalTile(terminal: terminal),
          ),
        ),
      ],
    );
  }
}

class _TicketsSection extends StatelessWidget {
  final _AdminData data;

  const _TicketsSection({required this.data});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _ActionHeader(
          title: 'Tickets et recus POS',
          subtitle: 'Historique complet des transactions appareil, carte, NFC, visage et main.',
          actions: [],
        ),
        const SizedBox(height: 14),
        ...data.receipts.map(
          (receipt) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _ReceiptTile(
              receipt: receipt,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PosTicketDetailsScreen(receipt: receipt),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _IntegrationsSection extends StatelessWidget {
  final _AdminData data;

  const _IntegrationsSection({required this.data});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _ActionHeader(
          title: 'Canaux et interconnexions',
          subtitle: 'Parametres des integrateurs, webhooks, sandbox, production et rotation des cles.',
          actions: [],
        ),
        const SizedBox(height: 14),
        ...data.channels.map(
          (channel) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _IntegrationTile(channel: channel),
          ),
        ),
      ],
    );
  }
}

class _KycSection extends StatelessWidget {
  final _AdminData data;

  const _KycSection({required this.data});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _ActionHeader(
          title: 'Validation multi-etapes',
          subtitle: 'Revue documentaire, verification faciale, analyse paume et validation finale.',
          actions: [],
        ),
        const SizedBox(height: 14),
        ...data.kycQueue.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _KycTile(item: item, detailed: true),
          ),
        ),
      ],
    );
  }
}

class _ActionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<_HeaderAction> actions;

  const _ActionHeader({
    required this.title,
    required this.subtitle,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        runSpacing: 12,
        spacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.darkMuted,
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: actions
                .map(
                  (action) => ElevatedButton(
                    onPressed: action.onTap,
                    child: Text(action.label),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _HeaderAction {
  final String label;
  final VoidCallback onTap;

  const _HeaderAction({
    required this.label,
    required this.onTap,
  });
}

class _MerchantTile extends StatelessWidget {
  final Map<String, dynamic> merchant;
  final List<Map<String, dynamic>> roles;
  final VoidCallback onEdit;

  const _MerchantTile({
    required this.merchant,
    required this.roles,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final terminals = ((merchant['terminals'] ?? 0) as num).toInt();
    final volume = ((merchant['dailyVolume'] ?? 0) as num).toDouble();

    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      merchant['name'].toString(),
                      style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${merchant['category']} - ${merchant['location']}',
                      style: const TextStyle(
                        color: AppColors.darkMuted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              OutlinedButton(
                onPressed: onEdit,
                child: const Text('Modifier'),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _MiniPill(label: 'Statut', value: merchant['status'].toString()),
              _MiniPill(label: 'Terminaux', value: '$terminals'),
              _MiniPill(label: 'Volume', value: 'CDF ${volume.toStringAsFixed(0)}'),
              _MiniPill(label: 'Roles', value: '${roles.length}'),
            ],
          ),
          if (roles.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Text(
              'Permissions',
              style: TextStyle(
                color: AppColors.text,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: roles
                  .map(
                    (role) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${role['name']} - ${role['role']}',
                        style: const TextStyle(
                          color: AppColors.darkMuted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _TerminalTile extends StatelessWidget {
  final Map<String, dynamic> terminal;

  const _TerminalTile({required this.terminal});

  @override
  Widget build(BuildContext context) {
    final healthy = (terminal['health'] ?? 'healthy') == 'healthy';
    return _GlassCard(
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: (healthy ? AppColors.green : AppColors.gold).withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.point_of_sale_rounded,
              color: healthy ? AppColors.green : AppColors.gold,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  terminal['id'].toString(),
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${terminal['merchant']} - ${terminal['location']}',
                  style: const TextStyle(
                    color: AppColors.darkMuted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Derniere methode: ${terminal['lastMethod']} | Vu ${terminal['lastSeen']}',
                  style: const TextStyle(
                    color: AppColors.darkMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          _MiniPill(
            label: 'Etat',
            value: terminal['status'].toString(),
            color: healthy ? AppColors.green : AppColors.gold,
          ),
        ],
      ),
    );
  }
}

class _ReceiptTile extends StatelessWidget {
  final Map<String, dynamic> receipt;
  final VoidCallback? onTap;

  const _ReceiptTile({
    required this.receipt,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final steps = List<String>.from(receipt['steps'] ?? const <String>[]);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: _GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      receipt['merchant'].toString(),
                      style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  _MiniPill(label: 'Methode', value: receipt['method'].toString()),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${receipt['currency']} ${((receipt['amount'] ?? 0) as num).toStringAsFixed(0)} - ${receipt['terminalId']}',
                style: const TextStyle(
                  color: AppColors.darkMuted,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${receipt['customerRef']} | ${receipt['createdAt']}',
                style: const TextStyle(
                  color: AppColors.darkMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (steps.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: steps
                      .map((step) => _MiniPill(label: 'Etape', value: step, compact: true))
                      .toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _LedgerTile extends StatelessWidget {
  final Map<String, dynamic> transaction;

  const _LedgerTile({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final isCredit = transaction['isCredit'] == true;
    final amount = ((transaction['amount'] ?? 0) as num).toDouble();
    final before = ((transaction['balanceBefore'] ?? 0) as num).toDouble();
    final after = ((transaction['balanceAfter'] ?? 0) as num).toDouble();
    final entryType = (transaction['entryType'] ?? transaction['type'] ?? 'LEDGER').toString();

    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  (transaction['label'] ?? transaction['description'] ?? 'Mouvement wallet')
                      .toString(),
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              _MiniPill(
                label: isCredit ? 'Credit' : 'Debit',
                value: entryType,
                compact: true,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${transaction['currency'] ?? 'CDF'} ${amount.toStringAsFixed(0)}',
            style: TextStyle(
              color: isCredit ? AppColors.green : AppColors.gold,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Solde ${before.toStringAsFixed(0)} -> ${after.toStringAsFixed(0)}',
            style: const TextStyle(
              color: AppColors.darkMuted,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _IntegrationTile extends StatelessWidget {
  final IntegrationChannel channel;

  const _IntegrationTile({required this.channel});

  @override
  Widget build(BuildContext context) {
    final healthColor = switch (channel.health) {
      'healthy' => AppColors.green,
      'warning' => AppColors.gold,
      _ => AppColors.red,
    };

    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      channel.name,
                      style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      channel.category,
                      style: const TextStyle(
                        color: AppColors.darkMuted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: channel.enabled,
                onChanged: (value) => BackofficeService.toggleChannel(channel.id, value),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _MiniPill(label: 'Sante', value: channel.health, color: healthColor),
              _MiniPill(
                label: 'Mode',
                value: channel.mode == IntegrationMode.live ? 'Production' : 'Sandbox',
              ),
              _MiniPill(label: 'Succes', value: '${channel.successRate}%'),
              _MiniPill(label: 'File', value: '${channel.pendingEvents}'),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            channel.webhookUrl,
            style: const TextStyle(
              color: AppColors.textSoft,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => BackofficeService.toggleMode(channel.id),
                  child: const Text('Basculer le mode'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => BackofficeService.rotateApiKey(channel.id),
                  child: const Text('Rotation cle'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _KycTile extends StatelessWidget {
  final KycReviewItem item;
  final bool detailed;

  const _KycTile({
    required this.item,
    this.detailed = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = switch (item.status) {
      'valide' => AppColors.green,
      'refuse' => AppColors.red,
      _ => AppColors.gold,
    };

    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.phone,
                      style: const TextStyle(
                        color: AppColors.darkMuted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              _MiniPill(label: 'Statut', value: item.status, color: color),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Soumis ${item.submittedAt}',
            style: const TextStyle(
              color: AppColors.darkMuted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (detailed) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: const [
                _MiniPill(label: 'Document', value: 'Recu'),
                _MiniPill(label: 'Visage', value: 'Controle'),
                _MiniPill(label: 'Main', value: 'Controle'),
                _MiniPill(label: 'Final', value: 'Operateur'),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _MiniPill extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;
  final bool compact;

  const _MiniPill({
    required this.label,
    required this.value,
    this.color,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final accent = color ?? AppColors.cyan;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 12,
        vertical: compact ? 7 : 9,
      ),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.24)),
      ),
      child: Text(
        compact ? value : '$label: $value',
        style: TextStyle(
          color: color == null ? AppColors.text : accent,
          fontSize: compact ? 11.5 : 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _PanelTitle extends StatelessWidget {
  final String title;

  const _PanelTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;

  const _GlassCard({required this.child});

  @override
  Widget build(BuildContext context) {
    final palette = MbongoThemeController.current;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: palette.panel.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.24)),
      ),
      child: child,
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Section Agents
// ──────────────────────────────────────────────────────────────────────────────

class _AgentsSection extends StatelessWidget {
  final _AdminData data;
  final VoidCallback onCreateAgent;

  const _AgentsSection({required this.data, required this.onCreateAgent});

  @override
  Widget build(BuildContext context) {
    final agents = data.agents;
    final active = agents.where((a) => a['status'] == 'ACTIVE').length;
    final palette = MbongoThemeController.current;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header stats
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _agentStat('Total agents', '${agents.length}', AppColors.cyan),
            _agentStat('Actifs', '$active', AppColors.green),
            _agentStat('Suspendus', '${agents.length - active}', AppColors.orange),
          ],
        ),
        const SizedBox(height: 18),

        // Action bar
        Row(
          children: [
            const Text(
              'Agents enregistrés',
              style: TextStyle(
                color: AppColors.text,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: onCreateAgent,
              icon: const Icon(Icons.person_add_rounded, size: 16),
              label: const Text('Enregistrer un agent'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.orange,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Table
        Container(
          decoration: BoxDecoration(
            color: palette.panel.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border.withValues(alpha: 0.24)),
          ),
          child: agents.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.support_agent_rounded, size: 48, color: AppColors.orange),
                        SizedBox(height: 12),
                        Text(
                          'Aucun agent enregistré',
                          style: TextStyle(color: AppColors.textSoft, fontSize: 14),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Utilisez le bouton ci-dessus pour enregistrer un agent.',
                          style: TextStyle(color: AppColors.muted, fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: agents.map((agent) => _AgentRow(agent: agent)).toList(),
                ),
        ),
      ],
    );
  }

  Widget _agentStat(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value,
              style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(color: AppColors.textSoft, fontSize: 12, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _AgentRow extends StatelessWidget {
  final Map<String, dynamic> agent;
  const _AgentRow({required this.agent});

  @override
  Widget build(BuildContext context) {
    final name = agent['name']?.toString() ?? '—';
    final phone = agent['phone']?.toString() ?? '—';
    final location = agent['location']?.toString() ?? '—';
    final code = agent['code']?.toString() ?? '';
    final status = agent['status']?.toString() ?? 'ACTIVE';
    final isActive = status == 'ACTIVE';
    final statusColor = isActive ? AppColors.green : AppColors.orange;
    final statusLabel = isActive ? 'Actif' : 'Suspendu';

    final cashIn = (agent['cashIn'] as num?)?.toDouble() ?? 0;
    final cashOut = (agent['cashOut'] as num?)?.toDouble() ?? 0;
    final commission = (agent['commissionBalance'] as num?)?.toDouble() ?? 0;

    String fmt(double v) => v >= 1000000
        ? '${(v / 1000000).toStringAsFixed(1)}M'
        : v >= 1000
            ? '${(v / 1000).toStringAsFixed(0)}K'
            : v.toStringAsFixed(0);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border.withValues(alpha: 0.15))),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.orange.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.support_agent_rounded, color: AppColors.orange, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(name,
                        style: const TextStyle(
                            color: AppColors.text, fontSize: 13, fontWeight: FontWeight.w800)),
                    if (code.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.orange.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(code,
                            style: const TextStyle(
                                color: AppColors.orange, fontSize: 10, fontWeight: FontWeight.w800)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text('$phone — $location',
                    style: const TextStyle(color: AppColors.textSoft, fontSize: 11)),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('↓ ${fmt(cashIn)} CDF',
                    style: const TextStyle(color: AppColors.green, fontSize: 11, fontWeight: FontWeight.w700)),
                Text('↑ ${fmt(cashOut)} CDF',
                    style: const TextStyle(color: AppColors.orange, fontSize: 11, fontWeight: FontWeight.w700)),
                Text('Com. ${fmt(commission)} CDF',
                    style: const TextStyle(color: AppColors.cyan, fontSize: 11, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: statusColor.withValues(alpha: 0.3)),
            ),
            child: Text(statusLabel,
                style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }
}
