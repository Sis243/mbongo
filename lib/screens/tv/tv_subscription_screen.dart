import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/dio_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/mbongo_theme.dart';
import '../../core/utils/money.dart';
import '../../features/wallet/data/wallet_repository.dart';
import '../../features/wallet/presentation/wallet_notifier.dart';
import '../../models/account_model.dart';
import '../../widgets/cards/wallet_card.dart';
import '../../widgets/common/mbongo_money_particles.dart';
import 'tv_subscription_success_screen.dart';
import '../../widgets/common/mbongo_sub_app_bar.dart';

class TvSubscriptionScreen extends ConsumerStatefulWidget {
  const TvSubscriptionScreen({super.key});

  @override
  ConsumerState<TvSubscriptionScreen> createState() => _TvSubscriptionScreenState();
}

class _TvSubscriptionScreenState extends ConsumerState<TvSubscriptionScreen> {
  int providerIndex = 0;
  int bouquetIndex = 0;

  final subscriberController = TextEditingController();

  final List<Map<String, dynamic>> providers = const [
    {
      "name": "Canal+",
      "color": Color(0xFF111111),
      "icon": Icons.tv_rounded,
    },
    {
      "name": "EasyTV",
      "color": Color(0xFF0057B8),
      "icon": Icons.live_tv_rounded,
    },
    {
      "name": "StarTimes",
      "color": Color(0xFFFFB000),
      "icon": Icons.connected_tv_rounded,
    },
    {
      "name": "DRTV",
      "color": Color(0xFFE53B2C),
      "icon": Icons.ondemand_video_rounded,
    },
    {
      "name": "AzamTV",
      "color": Color(0xFF027A48),
      "icon": Icons.live_tv_rounded,
    },
  ];

  final Map<String, List<Map<String, dynamic>>> bouquets = const {
    "Canal+": [
      {"name": "Access", "cdf": 25000.0, "usd": 10.0},
      {"name": "Evasion", "cdf": 45000.0, "usd": 18.0},
      {"name": "Tout Canal+", "cdf": 95000.0, "usd": 38.0},
    ],
    "EasyTV": [
      {"name": "Basic", "cdf": 15000.0, "usd": 6.0},
      {"name": "Classic", "cdf": 30000.0, "usd": 12.0},
      {"name": "Premium", "cdf": 55000.0, "usd": 22.0},
    ],
    "StarTimes": [
      {"name": "Nova", "cdf": 12000.0, "usd": 5.0},
      {"name": "Smart", "cdf": 22000.0, "usd": 9.0},
      {"name": "Super", "cdf": 42000.0, "usd": 17.0},
    ],
    "DRTV": [
      {"name": "Start", "cdf": 10000.0, "usd": 4.0},
      {"name": "Family", "cdf": 18000.0, "usd": 7.0},
      {"name": "Max", "cdf": 35000.0, "usd": 14.0},
    ],
    "AzamTV": [
      {"name": "Lite", "cdf": 14000.0, "usd": 6.0},
      {"name": "Plus", "cdf": 26000.0, "usd": 10.0},
      {"name": "Elite", "cdf": 49000.0, "usd": 20.0},
    ],
  };

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    subscriberController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final walletData = ref.read(walletProvider).valueOrNull;
    final currency = walletData?.currency ?? 'CDF';
    final provider = providers[providerIndex]["name"].toString();
    final providerBouquets = bouquets[provider]!;
    final bouquet = providerBouquets[bouquetIndex]["name"].toString();

    final amount = currency == "USD"
        ? (providerBouquets[bouquetIndex]["usd"] as double)
        : (providerBouquets[bouquetIndex]["cdf"] as double);

    if (subscriberController.text.trim().isEmpty) {
      _toast("Veuillez renseigner le numero d'abonne.");
      return;
    }

    try {
      await ref.read(walletRepositoryProvider).payTv(
            providerName: provider,
            subscriberId: subscriberController.text.trim(),
            bouquetName: bouquet,
            amount: amount,
          );

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TvSubscriptionSuccessScreen(
            providerName: provider,
            subscriberId: subscriberController.text.trim(),
            bouquetName: bouquet,
            amount: amount,
            currency: currency,
          ),
        ),
      );
    } on ApiException catch (error) {
      _toast(error.message);
    } catch (_) {
      _toast("Operation impossible pour le moment.");
    }
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final walletData = ref.watch(walletProvider).valueOrNull;
    final selectedWallet = walletData != null
        ? AccountModel(
            id: walletData.id,
            type: 'Portefeuille ${walletData.currency}',
            currency: walletData.currency,
            number: 'MBONGO-${walletData.currency}',
            balance: walletData.balance,
            selected: true,
          )
        : AccountModel(
            id: '',
            type: 'Portefeuille CDF',
            currency: 'CDF',
            number: 'MBONGO-CDF',
            balance: 0,
            selected: true,
          );
    final palette = MbongoThemeController.current;
    final provider = providers[providerIndex]["name"].toString();
    final providerBouquets = bouquets[provider]!;
    final selectedBouquet = providerBouquets[bouquetIndex];
    final price = selectedWallet.currency == "USD"
        ? selectedBouquet["usd"]
        : selectedBouquet["cdf"];

    return Scaffold(
      backgroundColor: palette.shellBottom,
      appBar: MbongoSubAppBar(title: 'Reabonnement TV'),
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
                  color: palette.accentStrong,
                  count: 14,
                  opacity: 0.08,
                  height: 0,
                ),
              ),
            ),
            SafeArea(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildHeaderCard(palette),
                  const SizedBox(height: 18),
                  const Text(
                    "Portefeuille selectionne",
                    style: TextStyle(
                      color: AppColors.text,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 14),
                  WalletCard(
                    wallet: selectedWallet,
                    gradient: selectedWallet.currency == "CDF"
                        ? palette.cardGradient
                        : [palette.cardGradient.first, palette.accentStrong],
                  ),
                  const SizedBox(height: 18),
                  _buildSectionCard(
                    title: "Fournisseur TV",
                    icon: Icons.tv_rounded,
                    palette: palette,
                    child: GridView.builder(
                      itemCount: providers.length,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        mainAxisExtent: 88,
                      ),
                      itemBuilder: (_, i) {
                        final item = providers[i];
                        final selected = i == providerIndex;
                        final color = item["color"] as Color;

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              providerIndex = i;
                              bouquetIndex = 0;
                            });
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: selected
                                  ? const Color(0xFF102A55)
                                  : palette.panel,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: selected
                                    ? color
                                    : AppColors.border.withValues(alpha: 0.24),
                                width: selected ? 1.5 : 1,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  item["icon"] as IconData,
                                  color: selected ? Colors.white : color,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  item["name"].toString(),
                                  style: TextStyle(
                                    color: selected ? Colors.white : AppColors.text,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildSectionCard(
                    title: "Bouquet",
                    icon: Icons.subscriptions_rounded,
                    palette: palette,
                    child: Column(
                      children: List.generate(providerBouquets.length, (i) {
                        final item = providerBouquets[i];
                        final selected = i == bouquetIndex;
                        final amount = selectedWallet.currency == "USD"
                            ? item["usd"]
                            : item["cdf"];

                        return GestureDetector(
                          onTap: () => setState(() => bouquetIndex = i),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: selected
                                  ? const Color(0xFF102A55)
                                  : palette.panel,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: selected
                                    ? palette.accent
                                    : AppColors.border.withValues(alpha: 0.24),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    item["name"].toString(),
                                    style: TextStyle(
                                      color: selected ? Colors.white : AppColors.text,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                Text(
                                  "${selectedWallet.currency} $amount",
                                  style: TextStyle(
                                    color: selected ? Colors.white : palette.accent,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildSectionCard(
                    title: "Informations d'abonnement",
                    icon: Icons.confirmation_number_outlined,
                    palette: palette,
                    child: Column(
                      children: [
                        TextField(
                          controller: subscriberController,
                          style: const TextStyle(
                            color: AppColors.text,
                            fontWeight: FontWeight.w700,
                          ),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: palette.panel,
                            labelText: "Numero d'abonne",
                            hintText: "Ex: 1234567890",
                            labelStyle: const TextStyle(color: AppColors.muted),
                            hintStyle: const TextStyle(color: AppColors.muted),
                            prefixIcon: const Icon(
                              Icons.badge_outlined,
                              color: AppColors.primary,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: BorderSide(
                                color: AppColors.border.withValues(alpha: 0.24),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: BorderSide(
                                color: palette.accent,
                                width: 1.4,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: palette.panel,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.payments_outlined,
                                color: AppColors.gold,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  "Montant du bouquet : ${Money.symbol(selectedWallet.currency)} $price",
                                  style: const TextStyle(
                                    color: AppColors.text,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: palette.accentStrong,
                    ),
                    child: const Text("Valider le reabonnement"),
                  ),
                ],
              ),
            ),
          ],
        ),
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
              Icon(Icons.tv_rounded, color: palette.accentStrong),
              const SizedBox(width: 8),
              const Text(
                "Reabonnement TV",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            "Canal+, StarTimes, EasyTV et plus",
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            "Renouvelez l'acces de votre numero abonne en quelques secondes. Choisissez le fournisseur, selectionnez le bouquet et saisissez votre numero d'abonne avant de valider.",
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

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required MbongoThemePalette palette,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: palette.panelAlt,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.24)),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 14,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, color: palette.accent),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.darkText,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}
