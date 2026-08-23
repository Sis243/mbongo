import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/theme/app_colors.dart';
import '../services/api_service.dart';

class UpdateInfo {
  final bool hasUpdate;
  final bool forceUpdate;
  final String latestVersion;
  final String? downloadUrl;
  final String message;

  const UpdateInfo({
    required this.hasUpdate,
    required this.forceUpdate,
    required this.latestVersion,
    this.downloadUrl,
    required this.message,
  });
}

class UpdateService {
  static Future<UpdateInfo> checkForUpdate() async {
    final info = await PackageInfo.fromPlatform();
    final current = info.version; // e.g. "3.0.0"

    final resp = await ApiService.getAppVersion();
    final latest = resp['latestVersion']?.toString() ?? current;
    final force = resp['forceUpdate'] == true;
    final url = resp['downloadUrl']?.toString();
    final msg = resp['message']?.toString() ??
        'Une nouvelle version est disponible.';

    return UpdateInfo(
      hasUpdate: _isNewer(latest, current),
      forceUpdate: force,
      latestVersion: latest,
      downloadUrl: url,
      message: msg,
    );
  }

  static bool _isNewer(String latest, String current) {
    final l = latest.split('.').map(int.tryParse).toList();
    final c = current.split('.').map(int.tryParse).toList();
    for (var i = 0; i < 3; i++) {
      final lv = i < l.length ? (l[i] ?? 0) : 0;
      final cv = i < c.length ? (c[i] ?? 0) : 0;
      if (lv > cv) return true;
      if (lv < cv) return false;
    }
    return false;
  }

  static void showUpdateDialog(BuildContext context, UpdateInfo info) {
    showDialog<void>(
      context: context,
      barrierDismissible: !info.forceUpdate,
      builder: (_) => _UpdateDialog(info: info),
    );
  }
}

class _UpdateDialog extends StatelessWidget {
  final UpdateInfo info;
  const _UpdateDialog({required this.info});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !info.forceUpdate,
      child: AlertDialog(
        backgroundColor: const Color(0xFF0D1B2A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        contentPadding: const EdgeInsets.all(0),
        content: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0D1B2A), Color(0xFF162840)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.system_update_rounded, color: AppColors.primary, size: 30),
              ),
              const SizedBox(height: 16),
              const Text(
                'Mise à jour disponible',
                style: TextStyle(color: AppColors.text, fontSize: 18, fontWeight: FontWeight.w900),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.green.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Version ${info.latestVersion}',
                  style: const TextStyle(color: AppColors.green, fontSize: 13, fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                info.message,
                style: const TextStyle(color: AppColors.textSoft, fontSize: 13, height: 1.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final url = info.downloadUrl;
                    if (url != null && url.isNotEmpty) {
                      final uri = Uri.tryParse(url);
                      if (uri != null && await canLaunchUrl(uri)) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      }
                    }
                    if (context.mounted) Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.download_rounded),
                  label: const Text('Mettre à jour'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              if (!info.forceUpdate) ...[
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Plus tard', style: TextStyle(color: AppColors.textSoft)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
