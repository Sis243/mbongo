import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;

import '../../core/api/dio_client.dart';
import '../../core/storage/app_storage.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/mbongo_theme.dart';
import '../../services/auth_service.dart';
import '../../services/biometric_service.dart';

class ConfirmRow {
  final String label;
  final String value;
  final Color? valueColor;
  final bool bold;
  const ConfirmRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.bold = false,
  });
}

/// Affiche un bottom sheet de confirmation avec résumé + saisie PIN.
/// Retourne true si le PIN est validé, false si annulé ou PIN incorrect.
Future<bool> showTransactionConfirmSheet({
  required BuildContext context,
  required String title,
  required IconData icon,
  required List<ConfirmRow> rows,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    isDismissible: true,
    builder: (_) => _ConfirmSheet(title: title, icon: icon, rows: rows),
  );
  return result == true;
}

class _ConfirmSheet extends StatefulWidget {
  final String title;
  final IconData icon;
  final List<ConfirmRow> rows;

  const _ConfirmSheet({
    required this.title,
    required this.icon,
    required this.rows,
  });

  @override
  State<_ConfirmSheet> createState() => _ConfirmSheetState();
}

class _ConfirmSheetState extends State<_ConfirmSheet> {
  final _pinCtrl = TextEditingController();
  bool _loading = false;
  String? _error;
  bool _obscure = true;
  bool _biometricAvailable = false;
  bool _biometricEnabled = false;

  @override
  void initState() {
    super.initState();
    BiometricService.canCheck().then((v) {
      if (mounted) setState(() => _biometricAvailable = v);
    });
    AuthService.isBiometricEnabled().then((v) {
      if (mounted) setState(() => _biometricEnabled = v);
    });
  }

  @override
  void dispose() {
    _pinCtrl.dispose();
    super.dispose();
  }

  Future<void> _confirmWithBiometric() async {
    setState(() { _loading = true; _error = null; });
    final ok = await BiometricService.authenticate();
    if (!mounted) return;
    if (ok) {
      HapticFeedback.heavyImpact();
      Navigator.of(context).pop(true);
    } else {
      HapticFeedback.vibrate();
      setState(() { _loading = false; _error = 'Authentification biométrique échouée.'; });
    }
  }

  Future<void> _confirm() async {
    final pin = _pinCtrl.text.trim();
    if (pin.isEmpty) {
      setState(() => _error = 'Veuillez entrer votre code PIN.');
      return;
    }
    setState(() { _loading = true; _error = null; });

    try {
      // Try local bio credentials first (fast, offline)
      final creds = await AppStorage().getBioCredentials();
      if (creds.pin != null && creds.pin!.isNotEmpty && pin == creds.pin) {
        HapticFeedback.heavyImpact();
        if (mounted) Navigator.of(context).pop(true);
        return;
      }

      // Local credentials absent or mismatch — verify via API (authoritative)
      final client = DioClient(AppStorage());
      await client.post('/auth/verify-pin', {'pin': pin});
      HapticFeedback.heavyImpact();
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      HapticFeedback.vibrate();
      if (mounted) setState(() { _loading = false; _error = e.message; });
    } catch (_) {
      HapticFeedback.vibrate();
      if (mounted) setState(() { _loading = false; _error = 'Code PIN incorrect.'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = MbongoThemeController.current;
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      margin: EdgeInsets.only(left: 12, right: 12, bottom: bottom > 0 ? 0 : 8),
      decoration: BoxDecoration(
        color: palette.panel,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.3)),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 16, 20, bottom > 0 ? bottom + 16 : 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),

              // Title
              Row(
                children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: palette.accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(widget.icon, color: palette.accent, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: const TextStyle(
                          color: AppColors.text,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const Text(
                        'Vérifiez les détails avant de confirmer',
                        style: TextStyle(color: AppColors.textSoft, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Summary rows
              Container(
                decoration: BoxDecoration(
                  color: palette.panelAlt,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border.withValues(alpha: 0.2)),
                ),
                child: Column(
                  children: [
                    for (int i = 0; i < widget.rows.length; i++) ...[
                      if (i > 0)
                        Divider(height: 1, color: AppColors.border.withValues(alpha: 0.15)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              widget.rows[i].label,
                              style: const TextStyle(
                                color: AppColors.textSoft,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Flexible(
                              child: Text(
                                widget.rows[i].value,
                                textAlign: TextAlign.end,
                                style: TextStyle(
                                  color: widget.rows[i].valueColor ?? AppColors.text,
                                  fontSize: widget.rows[i].bold ? 15 : 13,
                                  fontWeight: widget.rows[i].bold
                                      ? FontWeight.w900
                                      : FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Biometric shortcut
              if (_biometricAvailable && _biometricEnabled) ...[
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _loading ? null : _confirmWithBiometric,
                    icon: const Icon(Icons.fingerprint_rounded, size: 22),
                    label: const Text('Confirmer par biométrie'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                const Row(
                  children: [
                    Expanded(child: Divider()),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Text('ou', style: TextStyle(color: AppColors.muted, fontSize: 12)),
                    ),
                    Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 10),
              ],

              // PIN input
              TextField(
                controller: _pinCtrl,
                obscureText: _obscure,
                keyboardType: TextInputType.number,
                autofocus: true,
                onSubmitted: (_) => _confirm(),
                decoration: InputDecoration(
                  labelText: 'Code PIN de confirmation',
                  prefixIcon: const Icon(Icons.lock_rounded),
                  errorText: _error,
                  suffixIcon: IconButton(
                    icon: Icon(_obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _loading ? null : () => Navigator.of(context).pop(false),
                      child: const Text('Annuler'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _confirm,
                      child: _loading
                          ? const SizedBox(
                              width: 20, height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                            )
                          : const Text('Confirmer'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
