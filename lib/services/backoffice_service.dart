import 'package:flutter/foundation.dart';

enum IntegrationMode { sandbox, live }

class BackofficeMetric {
  final String id;
  final String label;
  final String value;
  final String hint;

  const BackofficeMetric({
    required this.id,
    required this.label,
    required this.value,
    required this.hint,
  });
}

class KycReviewItem {
  final String id;
  final String name;
  final String phone;
  final String status;
  final String submittedAt;

  const KycReviewItem({
    required this.id,
    required this.name,
    required this.phone,
    required this.status,
    required this.submittedAt,
  });
}

class IntegrationChannel {
  final String id;
  final String name;
  final String category;
  final bool enabled;
  final IntegrationMode mode;
  final String health;
  final String webhookUrl;
  final int successRate;
  final int pendingEvents;
  final String apiKeyPreview;
  final String updatedAt;

  const IntegrationChannel({
    required this.id,
    required this.name,
    required this.category,
    required this.enabled,
    required this.mode,
    required this.health,
    required this.webhookUrl,
    required this.successRate,
    required this.pendingEvents,
    required this.apiKeyPreview,
    required this.updatedAt,
  });

  IntegrationChannel copyWith({
    bool? enabled,
    IntegrationMode? mode,
    String? health,
    String? webhookUrl,
    int? successRate,
    int? pendingEvents,
    String? apiKeyPreview,
    String? updatedAt,
  }) {
    return IntegrationChannel(
      id: id,
      name: name,
      category: category,
      enabled: enabled ?? this.enabled,
      mode: mode ?? this.mode,
      health: health ?? this.health,
      webhookUrl: webhookUrl ?? this.webhookUrl,
      successRate: successRate ?? this.successRate,
      pendingEvents: pendingEvents ?? this.pendingEvents,
      apiKeyPreview: apiKeyPreview ?? this.apiKeyPreview,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class BackofficeService {
  static final ValueNotifier<List<IntegrationChannel>> channels =
      ValueNotifier<List<IntegrationChannel>>(
    const [
      IntegrationChannel(
        id: 'mobile-money',
        name: 'Mobile Money',
        category: 'Collection',
        enabled: true,
        mode: IntegrationMode.live,
        health: 'healthy',
        webhookUrl: 'https://api.mbongo.app/webhooks/mobile-money',
        successRate: 98,
        pendingEvents: 4,
        apiKeyPreview: 'mm_live_72A9X',
        updatedAt: 'Aujourd hui',
      ),
      IntegrationChannel(
        id: 'cards',
        name: 'Cartes',
        category: 'Paiement',
        enabled: true,
        mode: IntegrationMode.sandbox,
        health: 'warning',
        webhookUrl: 'https://api.mbongo.app/webhooks/cards',
        successRate: 93,
        pendingEvents: 11,
        apiKeyPreview: 'card_sb_18QPL',
        updatedAt: 'Aujourd hui',
      ),
      IntegrationChannel(
        id: 'airtime-tv',
        name: 'Airtime et TV',
        category: 'Facturation',
        enabled: true,
        mode: IntegrationMode.live,
        health: 'healthy',
        webhookUrl: 'https://api.mbongo.app/webhooks/billers',
        successRate: 97,
        pendingEvents: 3,
        apiKeyPreview: 'bill_live_9D7MS',
        updatedAt: 'Aujourd hui',
      ),
      IntegrationChannel(
        id: 'kyc-orchestrator',
        name: 'KYC Orchestrator',
        category: 'Compliance',
        enabled: true,
        mode: IntegrationMode.sandbox,
        health: 'healthy',
        webhookUrl: 'https://api.mbongo.app/webhooks/kyc',
        successRate: 96,
        pendingEvents: 7,
        apiKeyPreview: 'kyc_sb_55RTE',
        updatedAt: 'Aujourd hui',
      ),
      IntegrationChannel(
        id: 'merchant-qr',
        name: 'QR Marchands',
        category: 'Merchant',
        enabled: false,
        mode: IntegrationMode.sandbox,
        health: 'offline',
        webhookUrl: 'https://api.mbongo.app/webhooks/qr',
        successRate: 0,
        pendingEvents: 0,
        apiKeyPreview: 'qr_sb_00OFF',
        updatedAt: 'Aujourd hui',
      ),
    ],
  );

  static List<BackofficeMetric> get metrics {
    final list = channels.value;
    final enabled = list.where((item) => item.enabled).length;
    final live = list.where((item) => item.mode == IntegrationMode.live).length;
    final pending = list.fold<int>(0, (sum, item) => sum + item.pendingEvents);
    final health = list.where((item) => item.health == 'healthy').length;

    return [
      BackofficeMetric(
        id: 'ops',
        label: 'Canaux actifs',
        value: '$enabled',
        hint: '$live en production',
      ),
      BackofficeMetric(
        id: 'integrators',
        label: 'Integrateurs',
        value: '${list.length}',
        hint: '$health stables',
      ),
      BackofficeMetric(
        id: 'events',
        label: 'Evenements',
        value: '$pending',
        hint: 'Dans la file',
      ),
      const BackofficeMetric(
        id: 'kyc',
        label: 'KYC a revoir',
        value: '6',
        hint: 'Demandes a traiter',
      ),
    ];
  }

  static List<KycReviewItem> get kycQueue => const [
        KycReviewItem(
          id: 'kyc-001',
          name: 'Grace M.',
          phone: '+243 970 001 122',
          status: 'en_attente',
          submittedAt: 'Aujourd hui, 08:10',
        ),
        KycReviewItem(
          id: 'kyc-002',
          name: 'Patrick L.',
          phone: '+243 994 125 881',
          status: 'valide',
          submittedAt: 'Aujourd hui, 07:32',
        ),
        KycReviewItem(
          id: 'kyc-003',
          name: 'Sarah K.',
          phone: '+243 812 448 908',
          status: 'en_attente',
          submittedAt: 'Hier, 18:15',
        ),
        KycReviewItem(
          id: 'kyc-004',
          name: 'Michel A.',
          phone: '+243 998 312 004',
          status: 'refuse',
          submittedAt: 'Hier, 16:48',
        ),
      ];

  static void toggleChannel(String id, bool enabled) {
    channels.value = [
      for (final channel in channels.value)
        if (channel.id == id)
          channel.copyWith(enabled: enabled, updatedAt: 'A l instant')
        else
          channel,
    ];
  }

  static void toggleMode(String id) {
    channels.value = [
      for (final channel in channels.value)
        if (channel.id == id)
          channel.copyWith(
            mode: channel.mode == IntegrationMode.live
                ? IntegrationMode.sandbox
                : IntegrationMode.live,
            updatedAt: 'A l instant',
          )
        else
          channel,
    ];
  }

  static void rotateApiKey(String id) {
    channels.value = [
      for (final channel in channels.value)
        if (channel.id == id)
          channel.copyWith(
            apiKeyPreview:
                '${channel.id.substring(0, channel.id.length > 4 ? 4 : channel.id.length)}_${channel.mode == IntegrationMode.live ? 'live' : 'sb'}_${DateTime.now().millisecond.toString().padLeft(3, '0')}',
            updatedAt: 'A l instant',
          )
        else
          channel,
    ];
  }

  static void updateWebhook(String id, String webhookUrl) {
    channels.value = [
      for (final channel in channels.value)
        if (channel.id == id)
          channel.copyWith(
            webhookUrl: webhookUrl,
            updatedAt: 'A l instant',
          )
        else
          channel,
    ];
  }
}
