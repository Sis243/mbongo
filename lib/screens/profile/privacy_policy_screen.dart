import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/mbongo_theme.dart';
import '../../widgets/common/mbongo_sub_app_bar.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = MbongoThemeController.current;
    return Scaffold(
      backgroundColor: palette.shellBottom,
      appBar: const MbongoSubAppBar(title: 'Politique de confidentialité'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 32),
        children: const [
          _Section(
            title: '1. Responsable du traitement',
            body:
                'MBONGO, opéré par CADECO (Caisse d\'Épargne du Congo), est responsable du traitement de vos données personnelles. Siège social : Kinshasa, République Démocratique du Congo. Contact : privacy@mbongo.cd',
          ),
          _Section(
            title: '2. Données collectées',
            body:
                'Nous collectons les données suivantes :\n'
                '• Identité : nom complet, numéro de téléphone\n'
                '• Documents KYC : pièce d\'identité (recto/verso), selfie avec feuille MBONGO\n'
                '• Données financières : solde, historique des transactions\n'
                '• Données techniques : identifiant appareil, token Firebase, logs d\'erreur\n'
                '• Données biométriques (optionnelles) : empreinte digitale ou reconnaissance faciale pour l\'authentification rapide — stockées uniquement sur votre appareil',
          ),
          _Section(
            title: '3. Finalités du traitement',
            body:
                'Vos données sont utilisées pour :\n'
                '• Créer et gérer votre compte MBONGO\n'
                '• Vérifier votre identité (KYC) conformément aux exigences réglementaires\n'
                '• Traiter vos transactions financières\n'
                '• Vous envoyer des notifications de transaction\n'
                '• Assurer la sécurité et prévenir la fraude\n'
                '• Respecter nos obligations légales (BCC, loi n°04/016)',
          ),
          _Section(
            title: '4. Base légale',
            body:
                'Le traitement repose sur :\n'
                '• L\'exécution du contrat de service (compte MBONGO)\n'
                '• Le respect des obligations légales (réglementation BCC)\n'
                '• Notre intérêt légitime en matière de sécurité et prévention de la fraude',
          ),
          _Section(
            title: '5. Conservation des données',
            body:
                'Vos données sont conservées pendant la durée de votre compte et jusqu\'à 10 ans après sa clôture, conformément aux obligations légales congolaises en matière de lutte contre le blanchiment d\'argent.',
          ),
          _Section(
            title: '6. Partage des données',
            body:
                'Vos données ne sont pas vendues. Elles peuvent être partagées avec :\n'
                '• CADECO (partenaire opérateur)\n'
                '• Les autorités réglementaires (BCC, justice) sur obligation légale\n'
                '• Nos prestataires techniques (hébergement cloud sécurisé)',
          ),
          _Section(
            title: '7. Vos droits',
            body:
                'Conformément à la loi congolaise sur la protection des données, vous disposez des droits suivants :\n'
                '• Accès à vos données personnelles\n'
                '• Rectification des données inexactes\n'
                '• Suppression du compte et des données associées\n'
                '• Portabilité de vos données\n\n'
                'Pour exercer ces droits : privacy@mbongo.cd',
          ),
          _Section(
            title: '8. Sécurité',
            body:
                'Nous mettons en œuvre des mesures techniques et organisationnelles adaptées : chiffrement des données sensibles (AES-256), connexions sécurisées (HTTPS/TLS), authentification forte (PIN + biométrie), et surveillance continue des accès.',
          ),
          _Section(
            title: '9. Cookies et analytiques',
            body:
                'L\'application mobile n\'utilise pas de cookies. Nous utilisons Firebase Analytics de manière anonymisée pour améliorer nos services. Aucune donnée personnelle identifiable n\'est transmise à des fins publicitaires.',
          ),
          _Section(
            title: '10. Modifications',
            body:
                'Cette politique peut être mise à jour. Vous serez notifié par notification push en cas de modification substantielle. La version en vigueur est datée du 1er juin 2026.',
          ),
          _Section(
            title: '11. Contact',
            body:
                'Pour toute question relative à vos données :\n'
                '📧 privacy@mbongo.cd\n'
                '📍 CADECO, Kinshasa, RDC\n'
                '📞 +243 XX XXX XXXX',
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String body;
  const _Section({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    final palette = MbongoThemeController.current;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.panel,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.darkText,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: const TextStyle(
              color: AppColors.textSoft,
              fontSize: 13,
              fontWeight: FontWeight.w500,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
