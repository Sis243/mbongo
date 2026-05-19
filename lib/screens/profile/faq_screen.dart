import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/mbongo_theme.dart';
import '../../widgets/common/app_scaffold.dart';

class FaqScreen extends StatelessWidget {
  const FaqScreen({super.key});

  void _copySupport(BuildContext context) {
    Clipboard.setData(
      const ClipboardData(text: 'contact@mbongo.cd'),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Support copie : contact@mbongo.cd'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = MbongoThemeController.current;
    const items = [
      (
        'Connexion',
        'Utilisez votre empreinte digitale, la reconnaissance faciale ou un code PIN. L\'OTP est envoye par SMS si la biometrie n\'est pas disponible.',
      ),
      (
        'KYC',
        'Soumettez votre piece d\'identite (recto/verso) et un selfie depuis Profil > Statut KYC. La validation est effectuee par l\'equipe MBONGO sous 24 heures.',
      ),
      (
        'Transfert',
        'Saisissez le numero de telephone du beneficiaire, choisissez le montant et le motif. Le destinataire doit etre un compte MBONGO actif.',
      ),
      (
        'Retrait',
        'Choisissez un agent CADECO ou un DAB, generez la reference de retrait et presentez-la au guichet. La reference expire apres 24 heures.',
      ),
      (
        'Rechargement',
        'Deposez des fonds CDF ou USD via un agent CADECO agree pres de chez vous. Le credit est disponible instantanement apres confirmation de l\'agent.',
      ),
      (
        'Change',
        'Convertissez vos CDF en USD ou l\'inverse au taux officiel MBONGO. Le montant converti est credite immediatement dans votre second portefeuille.',
      ),
      (
        'International',
        'Envoyez de l\'argent a l\'etranger depuis l\'onglet International. Une verification de conformite supplementaire peut etre requise selon le montant.',
      ),
      (
        'Airtime',
        'Rechargez votre telephone ou un numero tiers en unites ou forfait data depuis Unites. Operateurs compatibles : Vodacom, Airtel, Orange, Africell.',
      ),
      (
        'Carte',
        'Creez jusqu\'a 3 cartes virtuelles VISA ou Mastercard USD depuis Mes Cartes. Rechargez, bloquez ou consultez les details a tout moment.',
      ),
      (
        'Validation',
        'Les operations sensibles (transfert eleve, change, retrait) passent dans la file d\'approbation avant execution. Un validateur autorise confirme ou rejette.',
      ),
      (
        'Securite',
        'Activez la biometrie, les alertes de connexion et le controle de presence depuis Profil > Securite. Ne partagez jamais votre code PIN.',
      ),
      (
        'Photo',
        'Ajoutez ou remplacez votre photo de profil depuis l\'icone portrait dans Profil. La photo est stockee localement sur votre appareil.',
      ),
    ];

    return MbongoPageScaffold(
      title: 'FAQ',
      child: ListView(
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: palette.bannerGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Aide rapide',
                  style: TextStyle(
                    color: palette.accentStrong,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Questions frequentes',
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Retrouvez les reponses essentielles avant de contacter le support MBONGO.',
                  style: TextStyle(
                    color: AppColors.textSoft,
                    fontSize: 13,
                    height: 1.35,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: palette.panelAlt,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: AppColors.border.withValues(alpha: 0.24),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: palette.accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.support_agent_rounded,
                    color: palette.accent,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Support MBONGO',
                        style: TextStyle(
                          color: AppColors.darkText,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'contact@mbongo.cd',
                        style: TextStyle(
                          color: AppColors.darkMuted,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => _copySupport(context),
                  style: TextButton.styleFrom(
                    foregroundColor: palette.accent,
                  ),
                  child: const Text('Copier'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          ...items.map(
            (item) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: palette.panelAlt,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: AppColors.border.withValues(alpha: 0.24),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: palette.accent.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _iconForTopic(item.$1),
                      color: palette.accent,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.$1,
                          style: const TextStyle(
                            color: AppColors.darkText,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          item.$2,
                          style: const TextStyle(
                            color: AppColors.darkMuted,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            height: 1.35,
                          ),
                        ),
                      ],
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

  IconData _iconForTopic(String topic) {
    return switch (topic) {
      'Connexion' => Icons.fingerprint_rounded,
      'KYC' => Icons.badge_rounded,
      'Transfert' => Icons.send_rounded,
      'Retrait' => Icons.download_rounded,
      'Rechargement' => Icons.account_balance_wallet_rounded,
      'Change' => Icons.currency_exchange_rounded,
      'International' => Icons.public_rounded,
      'Airtime' => Icons.phone_android_rounded,
      'Carte' => Icons.credit_card_rounded,
      'Validation' => Icons.verified_user_rounded,
      'Securite' => Icons.shield_outlined,
      'Photo' => Icons.camera_alt_rounded,
      _ => Icons.help_outline_rounded,
    };
  }
}
