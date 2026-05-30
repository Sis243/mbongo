import 'dart:async';

/// Broadcasts tab-switch requests triggered by FCM notification taps.
/// Use [NotificationNavigation.navigateToTab] to fire an event,
/// and subscribe to [NotificationNavigation.stream] in the shell.
class NotificationNavigation {
  NotificationNavigation._();

  static final _controller = StreamController<int>.broadcast();

  static Stream<int> get stream => _controller.stream;

  static void navigateToTab(int index) => _controller.add(index);
}

/// Maps FCM notification type → bottom-nav tab index in MainShell.
/// 0 = Accueil (transactions), 1 = Comptes, 2 = Wallet, 3 = Profil
int tabIndexForNotificationType(String type) {
  switch (type) {
    case 'KYC_REVIEW':
      return 3;
    case 'TRANSFER_RECEIVED':
    case 'DEPOSIT_SUCCESS':
    case 'WITHDRAWAL_SUCCESS':
    case 'BILL_PAYMENT_SUCCESS':
    case 'AIRTIME_SUCCESS':
    case 'TV_PAYMENT_SUCCESS':
    case 'TRANSACTION_REVERSED':
      return 0;
    default:
      return 0;
  }
}
