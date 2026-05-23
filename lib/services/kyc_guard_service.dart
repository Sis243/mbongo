import '../core/api/dio_client.dart';
import '../core/storage/app_storage.dart';
import 'auth_service.dart';

class KycAccess {
  final bool allowed;
  final String status;
  final String message;

  const KycAccess({
    required this.allowed,
    required this.status,
    required this.message,
  });
}

class KycGuardService {
  static Future<String> syncRemoteStatus() async {
    try {
      final client = DioClient(AppStorage());
      final remote = await client.get('/kyc/me');
      if (remote.isEmpty) return AuthService.getKycStatus();

      final remoteStatus = remote['status']?.toString().toUpperCase();
      final localStatus = switch (remoteStatus) {
        'SUBMITTED' => 'en_attente',
        'APPROVED' => 'valide',
        'REJECTED' => 'refuse',
        _ => 'non_commence',
      };

      await AuthService.setKycStatus(localStatus);
      await AuthService.setKycDocumentType(
          remote['documentType']?.toString() ?? '');
      await AuthService.setKycRefusalReason(
          remote['rejectionReason']?.toString() ?? '');
      await AuthService.setKycSubmittedAt(
          remote['submittedAt']?.toString() ?? '');
      await AuthService.setKycSubmitted(localStatus != 'non_commence');

      return localStatus;
    } on ApiException {
      return AuthService.getKycStatus();
    } catch (_) {
      return AuthService.getKycStatus();
    }
  }

  static Future<KycAccess> sensitiveOperationAccess() async {
    final status = await syncRemoteStatus();

    switch (status) {
      case 'valide':
        return const KycAccess(
          allowed: true,
          status: 'valide',
          message: '',
        );
      case 'en_attente':
        return const KycAccess(
          allowed: false,
          status: 'en_attente',
          message:
              'Votre verification est en attente. Cette operation reste bloquee pour le moment.',
        );
      case 'refuse':
        return const KycAccess(
          allowed: false,
          status: 'refuse',
          message:
              'Votre verification a ete refusee. Reprenez le dossier KYC avant de continuer.',
        );
      default:
        return const KycAccess(
          allowed: false,
          status: 'non_commence',
          message:
              'Completez votre verification d identite pour debloquer cette operation.',
        );
    }
  }
}
