import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../core/theme/mbongo_theme.dart';
import '../../widgets/common/mbongo_sub_app_bar.dart';

// ─────────────────────────────────────────────────────────
// Modèle résultat de scan
// ─────────────────────────────────────────────────────────
enum QrRole { client, agent, merchant, unknown }

class QrScanResult {
  final String phone;
  final String name;
  final QrRole role;
  final double? amount;
  final String? agentCode;
  final String? merchantId;

  const QrScanResult({
    required this.phone,
    required this.name,
    required this.role,
    this.amount,
    this.agentCode,
    this.merchantId,
  });

  /// Parse mbongo://pay?phone=...&name=...&role=...&amount=...
  static QrScanResult? parse(String raw) {
    try {
      final uri = Uri.parse(raw.trim());
      if (uri.scheme == 'mbongo' && uri.host == 'pay') {
        final phone = uri.queryParameters['phone'] ?? '';
        if (phone.isEmpty) return null;
        final name = Uri.decodeComponent(uri.queryParameters['name'] ?? '');
        final roleStr = uri.queryParameters['role'] ?? 'client';
        final role = _parseRole(roleStr);
        final amountStr = uri.queryParameters['amount'];
        final amount = amountStr != null ? double.tryParse(amountStr) : null;
        return QrScanResult(
          phone: phone,
          name: name,
          role: role,
          amount: amount,
          agentCode: uri.queryParameters['agentCode'],
          merchantId: uri.queryParameters['merchantId'],
        );
      }
      // Fallback : numéro brut
      if (RegExp(r'^\+?\d{7,}$').hasMatch(raw.trim())) {
        return QrScanResult(phone: raw.trim(), name: '', role: QrRole.client);
      }
    } catch (_) {}
    return null;
  }

  static QrRole _parseRole(String s) {
    switch (s.toLowerCase()) {
      case 'agent': return QrRole.agent;
      case 'merchant': return QrRole.merchant;
      default: return QrRole.client;
    }
  }

  /// Construit le deep link pour ce résultat
  static String buildLink({
    required String phone,
    required String name,
    required QrRole role,
    double? amount,
    String? agentCode,
    String? merchantId,
  }) {
    final params = <String, String>{
      'phone': phone,
      'name': Uri.encodeComponent(name),
      'role': role.name,
    };
    if (amount != null) params['amount'] = amount.toStringAsFixed(0);
    if (agentCode != null && agentCode.isNotEmpty) params['agentCode'] = agentCode;
    if (merchantId != null && merchantId.isNotEmpty) params['merchantId'] = merchantId;
    return Uri(scheme: 'mbongo', host: 'pay', queryParameters: params).toString();
  }
}

// ─────────────────────────────────────────────────────────
// Écran scanner
// ─────────────────────────────────────────────────────────
class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final _controller = MobileScannerController();
  bool _scanned = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_scanned) return;
    final raw = capture.barcodes.firstOrNull?.rawValue;
    if (raw == null) return;

    final result = QrScanResult.parse(raw);
    if (result != null) {
      _scanned = true;
      _controller.stop();
      Navigator.of(context).pop(result);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('QR non reconnu — utilisez un QR MBONGO.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = MbongoThemeController.current;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: MbongoSubAppBar(title: 'Scanner un QR MBONGO'),
      body: Stack(
        children: [
          MobileScanner(controller: _controller, onDetect: _onDetect),

          // Viseur centré
          Center(
            child: Container(
              width: 240, height: 240,
              decoration: BoxDecoration(
                border: Border.all(color: palette.accent, width: 3),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),

          // Overlay sombre
          ColorFiltered(
            colorFilter: const ColorFilter.mode(Colors.black54, BlendMode.srcOut),
            child: Stack(children: [
              Container(decoration: const BoxDecoration(color: Colors.black, backgroundBlendMode: BlendMode.dstOut)),
              Align(
                alignment: Alignment.center,
                child: Container(
                  width: 240, height: 240,
                  decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(20)),
                ),
              ),
            ]),
          ),

          // Instruction bas
          Positioned(
            bottom: 48, left: 16, right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.65), borderRadius: BorderRadius.circular(16)),
              child: Column(children: [
                Icon(Icons.qr_code_scanner_rounded, color: palette.accent, size: 28),
                const SizedBox(height: 8),
                const Text('Pointez vers le QR de la personne', textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                const Text('Client, agent ou marchand — l\'app ouvre le bon écran',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFF8EACC9), fontSize: 12)),
              ]),
            ),
          ),

          // Torche
          Positioned(
            top: 12, right: 16,
            child: IconButton(
              icon: const Icon(Icons.flashlight_on_rounded, color: Colors.white),
              onPressed: () => _controller.toggleTorch(),
            ),
          ),
        ],
      ),
    );
  }
}
