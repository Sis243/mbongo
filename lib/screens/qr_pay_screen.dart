import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api/dio_client.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/mbongo_theme.dart';
import '../features/wallet/presentation/wallet_notifier.dart';
import '../services/auth_service.dart';
import 'merchant/pos_ticket_details_screen.dart';
import '../widgets/common/mbongo_money_particles.dart';
import '../widgets/common/mbongo_sub_app_bar.dart';
import '../widgets/common/transaction_confirm_sheet.dart';

final _merchantsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  try {
    final resp = await ref.read(dioClientProvider).get('/merchant/accounts');
    final list = resp['data'];
    if (list is List) return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  } catch (_) {}
  return [];
});

final _terminalsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  try {
    final resp = await ref.read(dioClientProvider).get('/merchant/terminals');
    final list = resp['data'];
    if (list is List) return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  } catch (_) {}
  return [];
});

final _posReceiptsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  try {
    final resp = await ref.read(dioClientProvider).get('/merchant/pos-receipts');
    final list = resp['data'];
    if (list is List) return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  } catch (_) {}
  return [];
});

final _merchantRolesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  try {
    final resp = await ref.read(dioClientProvider).get('/merchant/roles');
    final list = resp['data'];
    if (list is List) return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  } catch (_) {}
  return [];
});

class QrPayScreen extends ConsumerStatefulWidget {
  const QrPayScreen({super.key});

  @override
  ConsumerState<QrPayScreen> createState() => _QrPayScreenState();
}

class _QrPayScreenState extends ConsumerState<QrPayScreen> {
  final merchantCtrl = TextEditingController(text: 'Marchand demo');
  final terminalCtrl = TextEditingController(text: 'POS-KIN-07');
  final amountCtrl = TextEditingController(text: '25000');
  final locationCtrl = TextEditingController(text: 'Point de vente A');

  String selectedMethod = 'Appareil';
  bool faceReady = false;
  bool palmReady = false;
  bool nfcReady = true;
  bool loading = true;

  final List<_MerchantMethod> methods = const [
    _MerchantMethod('Appareil', Icons.devices_rounded, 'Scan du telephone ou appareil client'),
    _MerchantMethod('Carte', Icons.credit_card_rounded, 'Lecture carte bancaire ou virtuelle'),
    _MerchantMethod('NFC', Icons.nfc_rounded, 'Sans contact terminal a terminal'),
    _MerchantMethod('Visage', Icons.face_retouching_natural_rounded, 'Verification faciale locale'),
    _MerchantMethod('Main', Icons.back_hand_rounded, 'Validation paume ou main'),
  ];

  @override
  void initState() {
    super.initState();
    _loadSecurityReadiness();
  }

  Future<void> _loadSecurityReadiness() async {
    faceReady = await AuthService.isFaceRecognitionEnabled();
    palmReady = await AuthService.isPalmRecognitionEnabled();
    nfcReady = await AuthService.isNfcPaymentsEnabled();
    if (!mounted) return;
    setState(() => loading = false);
  }

  @override
  void dispose() {
    merchantCtrl.dispose();
    terminalCtrl.dispose();
    amountCtrl.dispose();
    locationCtrl.dispose();
    super.dispose();
  }

  String money(num n) {
    return n.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]} ',
    );
  }

  Future<void> doPayment() async {
    final merchant = merchantCtrl.text.trim();
    final terminal = terminalCtrl.text.trim();
    final amount = double.tryParse(amountCtrl.text.trim()) ?? 0;
    final location = locationCtrl.text.trim();

    if (merchant.isEmpty || terminal.isEmpty || amount <= 0) {
      _toast('Renseignez le marchand, le terminal et le montant.');
      return;
    }

    if (selectedMethod == 'Visage' && !faceReady) {
      _toast('Activez d abord la reconnaissance faciale dans Securite.');
      return;
    }

    if (selectedMethod == 'Main' && !palmReady) {
      _toast('Activez d abord la reconnaissance de la main dans Securite.');
      return;
    }

    if (selectedMethod == 'NFC' && !nfcReady) {
      _toast('Le paiement NFC n est pas encore active sur cet appareil.');
      return;
    }

    final balance = ref.read(walletProvider).valueOrNull?.balance ?? 0.0;
    if (amount > balance) {
      _toast('Solde insuffisant.');
      return;
    }

    final confirmed = await showTransactionConfirmSheet(
      context: context,
      title: 'Paiement POS',
      icon: Icons.qr_code_scanner_rounded,
      rows: [
        ConfirmRow(label: 'Marchand', value: merchant),
        ConfirmRow(label: 'Terminal', value: terminal),
        ConfirmRow(label: 'Méthode', value: selectedMethod),
        ConfirmRow(label: 'Montant', value: '${money(amount)} CDF', bold: true, valueColor: const Color(0xFFD4A843)),
      ],
    );
    if (!mounted || !confirmed) return;

    try {
      await ref.read(dioClientProvider).post('/transactions/merchant-pay', {
        'merchant': merchant,
        'amount': amount,
        'method': selectedMethod,
        'location': location,
      });
      ref.refresh(walletProvider.future).ignore();
      ref.refresh(_posReceiptsProvider.future).ignore();
      _toast('Paiement POS ${selectedMethod.toLowerCase()} de ${money(amount)} CDF confirme.');
    } catch (e) {
      _toast(e.toString());
    }
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  List<String> _validationSteps() {
    switch (selectedMethod) {
      case 'Visage':
        return const [
          'Detection du terminal marchand',
          'Capture locale du visage',
          'Controle de presence actif',
          'Confirmation du debit',
          'Emission du ticket',
        ];
      case 'Main':
        return const [
          'Detection du terminal marchand',
          'Lecture paume ou main',
          'Controle de liveness',
          'Confirmation du debit',
          'Emission du ticket',
        ];
      case 'NFC':
        return const [
          'Lecteur NFC arme',
          'Approche du support client',
          'Authentification terminal',
          'Confirmation du debit',
          'Emission du ticket',
        ];
      case 'Carte':
        return const [
          'Lecture carte',
          'Controle support et terminal',
          'Autorisation locale',
          'Confirmation du debit',
          'Emission du ticket',
        ];
      default:
        return const [
          'Scan de l appareil client',
          'Association terminal',
          'Autorisation locale',
          'Confirmation du debit',
          'Emission du ticket',
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = MbongoThemeController.current;
    final merchants = ref.watch(_merchantsProvider).valueOrNull ?? [];
    final terminals = ref.watch(_terminalsProvider).valueOrNull ?? [];
    final receipts = ref.watch(_posReceiptsProvider).valueOrNull ?? [];
    final roles = ref.watch(_merchantRolesProvider).valueOrNull ?? [];

    return Scaffold(
      backgroundColor: palette.shellBottom,
      appBar: MbongoSubAppBar(title: 'POS Marchand'),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
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
                      color: palette.accent,
                      count: 18,
                      opacity: 0.1,
                    ),
                  ),
                ),
                ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _hero(palette),
                    const SizedBox(height: 18),
                    _readinessStrip(),
                    const SizedBox(height: 18),
                    _quickActions(merchants),
                    const SizedBox(height: 18),
                    _methodsBand(),
                    const SizedBox(height: 18),
                    _scanPreview(),
                    const SizedBox(height: 18),
                    _validationBand(),
                    const SizedBox(height: 18),
                    _formCard(),
                    const SizedBox(height: 18),
                    const _SectionTitle('Comptes marchands'),
                    const SizedBox(height: 12),
                    ...merchants.take(3).map(_merchantCard),
                    const SizedBox(height: 18),
                    const _SectionTitle('Journal des terminaux'),
                    const SizedBox(height: 12),
                    ...terminals.take(4).map(_terminalCard),
                    const SizedBox(height: 18),
                    const _SectionTitle('Permissions'),
                    const SizedBox(height: 12),
                    ...roles.take(4).map(_roleCard),
                    const SizedBox(height: 18),
                    const _SectionTitle('Tickets et historique POS'),
                    const SizedBox(height: 12),
                    ...receipts.take(5).map(_receiptCard),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _hero(MbongoThemePalette palette) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            palette.bannerGradient.first.withValues(alpha: 0.96),
            palette.bannerGradient.last.withValues(alpha: 0.96),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'POS intelligent',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const Spacer(),
              const Icon(Icons.point_of_sale_rounded, color: Colors.white),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Paiement marchand nouvelle generation',
            style: TextStyle(
              color: Colors.white,
              fontSize: 23,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Le terminal peut preparer un reglement par appareil, carte, NFC, visage ou main selon le niveau de securite active.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget _readinessStrip() {
    return Row(
      children: [
        Expanded(child: _statusCell('NFC', nfcReady ? 'Pret' : 'A activer', nfcReady)),
        const SizedBox(width: 10),
        Expanded(child: _statusCell('Visage', faceReady ? 'Pret' : 'A activer', faceReady)),
        const SizedBox(width: 10),
        Expanded(child: _statusCell('Main', palmReady ? 'Pret' : 'A activer', palmReady)),
      ],
    );
  }

  Widget _quickActions(List<Map<String, dynamic>> merchants) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _showMerchantForm,
            icon: const Icon(Icons.store_mall_directory_rounded),
            label: const Text('Nouveau marchand'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: merchants.isEmpty ? null : () => _showTerminalForm(merchants.first),
            icon: const Icon(Icons.memory_rounded),
            label: const Text('Onboard POS'),
          ),
        ),
      ],
    );
  }

  Widget _statusCell(String label, String value, bool ready) {
    final color = ready ? AppColors.green : AppColors.orange;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSoft,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Widget _methodsBand() {
    final palette = MbongoThemeController.current;
    return SizedBox(
      height: 108,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: methods.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, index) {
          final method = methods[index];
          final selected = method.label == selectedMethod;

          return GestureDetector(
            onTap: () => setState(() => selectedMethod = method.label),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 150,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: selected ? palette.panelAlt : palette.panel,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: selected
                      ? palette.accent.withValues(alpha: 0.5)
                      : AppColors.border.withValues(alpha: 0.8),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(method.icon, color: selected ? palette.accent : AppColors.textSoft),
                  const Spacer(),
                  Text(
                    method.label,
                    style: TextStyle(
                      color: selected ? AppColors.darkText : AppColors.text,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    method.subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: selected ? AppColors.darkMuted : AppColors.textSoft,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _scanPreview() {
    final palette = MbongoThemeController.current;
    final icon = methods.firstWhere((item) => item.label == selectedMethod).icon;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: palette.panelAlt,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Simulation de capture POS',
                  style: TextStyle(
                    color: AppColors.darkText,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                selectedMethod,
                style: TextStyle(
                  color: MbongoThemeController.current.accent,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          AspectRatio(
            aspectRatio: 1.4,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    MbongoThemeController.current.bannerGradient.first.withValues(alpha: 0.96),
                    MbongoThemeController.current.bannerGradient.last.withValues(alpha: 0.96),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Stack(
                children: [
                  Align(
                    alignment: Alignment.center,
                    child: Icon(icon, size: 92, color: Colors.white),
                  ),
                  Align(
                    alignment: Alignment.topLeft,
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text(
                          'Scan pret',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Text(
                        _scanHint(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _validationBand() {
    final steps = _validationSteps();
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: MbongoThemeController.current.panelAlt,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Validation multi-etapes',
            style: TextStyle(
              color: AppColors.darkText,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          ...List.generate(steps.length, (index) {
            final step = steps[index];
            final active = index < 3;
            return Padding(
              padding: EdgeInsets.only(bottom: index == steps.length - 1 ? 0 : 10),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: active
                          ? MbongoThemeController.current.accent
                          : MbongoThemeController.current.panel,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          color: active ? Colors.white : AppColors.textSoft,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      step,
                      style: const TextStyle(
                        color: AppColors.darkText,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  String _scanHint() {
    switch (selectedMethod) {
      case 'Carte':
        return 'Lecture de carte physique ou virtuelle par terminal marchand.';
      case 'NFC':
        return 'Approchez l appareil ou la carte du lecteur sans contact.';
      case 'Visage':
        return 'Le terminal verifie le visage local avant confirmation du debit.';
      case 'Main':
        return 'Le terminal prepare une validation paume ou main pour environnements premium.';
      default:
        return 'Le POS identifie l appareil client et prepare le debit marchand.';
    }
  }

  Widget _formCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: MbongoThemeController.current.panelAlt,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(color: AppColors.shadow, blurRadius: 12, offset: Offset(0, 5)),
        ],
      ),
      child: Column(
        children: [
          TextField(
            controller: merchantCtrl,
            style: const TextStyle(color: AppColors.darkText, fontWeight: FontWeight.w700),
            decoration: const InputDecoration(
              hintText: 'Nom du marchand',
              prefixIcon: Icon(Icons.storefront_rounded),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: terminalCtrl,
            style: const TextStyle(color: AppColors.darkText, fontWeight: FontWeight.w700),
            decoration: const InputDecoration(
              hintText: 'Reference POS',
              prefixIcon: Icon(Icons.memory_rounded),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: locationCtrl,
            style: const TextStyle(color: AppColors.darkText, fontWeight: FontWeight.w700),
            decoration: const InputDecoration(
              hintText: 'Emplacement commercial',
              prefixIcon: Icon(Icons.place_outlined),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: amountCtrl,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: AppColors.darkText, fontWeight: FontWeight.w700),
            decoration: const InputDecoration(
              hintText: 'Montant (CDF)',
              prefixIcon: Icon(Icons.payments_rounded),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: doPayment,
              icon: const Icon(Icons.check_circle_outline_rounded),
              label: Text('Confirmer par $selectedMethod'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _merchantCard(Map<String, dynamic> merchant) {
    final volume = ((merchant['dailyVolume'] ?? 0) as num).toDouble();
    return GestureDetector(
      onTap: () => _showMerchantForm(merchant: merchant),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: MbongoThemeController.current.panelAlt,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: MbongoThemeController.current.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.store_mall_directory_rounded,
                color: MbongoThemeController.current.accent,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    merchant['name'].toString(),
                    style: const TextStyle(
                      color: AppColors.darkText,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${merchant['category']} - ${merchant['location']}',
                    style: const TextStyle(
                      color: AppColors.darkMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'CDF ${money(volume)}',
                  style: TextStyle(
                    color: MbongoThemeController.current.accent,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                TextButton(
                  onPressed: () => _showRoleForm(merchant),
                  child: const Text('Roles'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _terminalCard(Map<String, dynamic> terminal) {
    final healthy = (terminal['health'] ?? 'healthy') == 'healthy';
    return GestureDetector(
      onTap: () => _showTerminalForm(
        {'id': terminal['merchantId'], 'name': terminal['merchant']},
        terminal: terminal,
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: MbongoThemeController.current.panelAlt,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    terminal['id'].toString(),
                    style: const TextStyle(
                      color: AppColors.darkText,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Text(
                  terminal['status'].toString(),
                  style: TextStyle(
                    color: healthy ? AppColors.green : AppColors.orange,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${terminal['merchant']} - ${terminal['location']}',
              style: const TextStyle(color: AppColors.darkMuted, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              'Derniere methode: ${terminal['lastMethod']} • ${terminal['transactionsCount']} passages',
              style: const TextStyle(
                color: AppColors.darkText,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _roleCard(Map<String, dynamic> role) {
    final permissions = List<String>.from(role['permissions'] ?? const <String>[]);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MbongoThemeController.current.panelAlt,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  role['name'].toString(),
                  style: const TextStyle(color: AppColors.darkText, fontWeight: FontWeight.w900),
                ),
              ),
              Text(
                role['role'].toString(),
                style: TextStyle(
                  color: MbongoThemeController.current.accent,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            role['merchant'].toString(),
            style: const TextStyle(color: AppColors.darkMuted, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: permissions.map((permission) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: MbongoThemeController.current.panel,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  permission,
                  style: const TextStyle(
                    color: AppColors.textSoft,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _receiptCard(Map<String, dynamic> receipt) {
    final steps = List<String>.from(receipt['steps'] ?? const <String>[]);
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => PosTicketDetailsScreen(receipt: receipt)),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: MbongoThemeController.current.panelAlt,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${receipt['merchant']} - ${receipt['method']}',
                    style: const TextStyle(
                      color: AppColors.darkText,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Text(
                  '${receipt['currency']} ${money((receipt['amount'] ?? 0) as num)}',
                  style: TextStyle(
                    color: MbongoThemeController.current.accent,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${receipt['terminalId']} • ${receipt['location']} • ${receipt['createdAt']}',
              style: const TextStyle(
                color: AppColors.darkMuted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ref client: ${receipt['customerRef']}',
              style: const TextStyle(
                color: AppColors.darkText,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (steps.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: steps.map((step) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: MbongoThemeController.current.panel,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      step,
                      style: const TextStyle(
                        color: AppColors.textSoft,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _showMerchantForm({Map<String, dynamic>? merchant}) async {
    final nameCtrl = TextEditingController(text: merchant?['name']?.toString() ?? '');
    final categoryCtrl = TextEditingController(text: merchant?['category']?.toString() ?? '');
    final locCtrl = TextEditingController(text: merchant?['location']?.toString() ?? '');

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(merchant == null ? 'Nouveau marchand' : 'Editer le marchand'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Nom du marchand'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: categoryCtrl,
                  decoration: const InputDecoration(labelText: 'Activite'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: locCtrl,
                  decoration: const InputDecoration(labelText: 'Localisation'),
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
                try {
                  await ref.read(dioClientProvider).post('/merchant/accounts', {
                    'name': nameCtrl.text.trim().isEmpty ? 'Marchand' : nameCtrl.text.trim(),
                    'category': categoryCtrl.text.trim().isEmpty ? 'General' : categoryCtrl.text.trim(),
                    'location': locCtrl.text.trim().isEmpty ? 'Point de vente' : locCtrl.text.trim(),
                  });
                  ref.refresh(_merchantsProvider.future).ignore();
                } catch (_) {}
                if (dialogContext.mounted) Navigator.pop(dialogContext);
              },
              child: const Text('Enregistrer'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showTerminalForm(
    Map<String, dynamic> merchant, {
    Map<String, dynamic>? terminal,
  }) async {
    final terminalIdCtrl = TextEditingController(
      text: terminal?['id']?.toString() ?? 'POS-KIN-${DateTime.now().second}',
    );
    final locCtrl = TextEditingController(
      text: terminal?['location']?.toString() ?? 'Point de vente',
    );

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Onboarding terminal POS'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  merchant['name'].toString(),
                  style: const TextStyle(
                    color: AppColors.darkText,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: terminalIdCtrl,
                  decoration: const InputDecoration(labelText: 'Reference terminal'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: locCtrl,
                  decoration: const InputDecoration(labelText: 'Localisation'),
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
                try {
                  await ref.read(dioClientProvider).post('/merchant/terminals', {
                    'merchantId': merchant['id'].toString(),
                    'merchantName': merchant['name'].toString(),
                    'terminalId': terminalIdCtrl.text.trim(),
                    'location': locCtrl.text.trim().isEmpty ? 'Point de vente' : locCtrl.text.trim(),
                  });
                  ref.refresh(_terminalsProvider.future).ignore();
                } catch (_) {}
                if (dialogContext.mounted) Navigator.pop(dialogContext);
              },
              child: const Text('Activer'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showRoleForm(Map<String, dynamic> merchant) async {
    final nameCtrl = TextEditingController();
    String role = 'caissier';

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Permissions marchand'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      merchant['name'].toString(),
                      style: const TextStyle(
                        color: AppColors.darkText,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(labelText: 'Nom utilisateur'),
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
                        if (value != null) setDialogState(() => role = value);
                      },
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
                    try {
                      await ref.read(dioClientProvider).post('/merchant/roles', {
                        'merchantId': merchant['id'].toString(),
                        'merchantName': merchant['name'].toString(),
                        'name': nameCtrl.text.trim().isEmpty ? 'Utilisateur POS' : nameCtrl.text.trim(),
                        'role': role,
                      });
                      ref.refresh(_merchantRolesProvider.future).ignore();
                    } catch (_) {}
                    if (dialogContext.mounted) Navigator.pop(dialogContext);
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
}

class _MerchantMethod {
  final String label;
  final IconData icon;
  final String subtitle;

  const _MerchantMethod(this.label, this.icon, this.subtitle);
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: AppColors.text,
        fontSize: 18,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}
