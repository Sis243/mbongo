import 'package:flutter/material.dart';

import '../models/account_model.dart';
import '../models/banner_model.dart';
import '../models/service_item.dart';
import '../models/transaction_model.dart';

class MbongoStore {
  static final ValueNotifier<String> profileName =
      ValueNotifier<String>('Flory BOKAKO');

  static final ValueNotifier<String> profileType =
      ValueNotifier<String>('Standard');

  static final ValueNotifier<bool> profilePhotoVerified =
      ValueNotifier<bool>(false);

  static final ValueNotifier<bool> phoneVerified = ValueNotifier<bool>(true);

  static final ValueNotifier<bool> pinConfigured = ValueNotifier<bool>(true);

  static final ValueNotifier<bool> premiumEligible = ValueNotifier<bool>(true);

  static void refreshProfileType() {
    final isPremium = profilePhotoVerified.value &&
        phoneVerified.value &&
        pinConfigured.value &&
        premiumEligible.value;

    profileType.value = isPremium ? 'Premium' : 'Standard';
  }

  static final ValueNotifier<List<AccountModel>> accounts =
      ValueNotifier<List<AccountModel>>([
    const AccountModel(
      id: 'acc-cdf',
      type: 'Compte CDF',
      currency: 'CDF',
      number: '45101 - 00868396001',
      balance: 2500000,
      selected: true,
    ),
    const AccountModel(
      id: 'acc-usd',
      type: 'Compte USD',
      currency: 'USD',
      number: '45101 - 00186839601',
      balance: 1250,
    ),
  ]);

  static final ValueNotifier<List<AccountModel>> wallets =
      ValueNotifier<List<AccountModel>>([
    const AccountModel(
      id: 'wallet-cdf',
      type: 'Portefeuille CDF',
      currency: 'CDF',
      number: 'MBONGO-CDF',
      balance: 2530000,
      selected: true,
    ),
    const AccountModel(
      id: 'wallet-usd',
      type: 'Portefeuille USD',
      currency: 'USD',
      number: 'MBONGO-USD',
      balance: 320,
    ),
  ]);

  static final ValueNotifier<List<TransactionModel>> transactions =
      ValueNotifier<List<TransactionModel>>([
    TransactionModel(
      id: 'tx-001',
      type: 'deposit',
      title: 'Depot portefeuille',
      currency: 'CDF',
      amount: 3000000,
      target: 'MBONGO-CDF',
      reason: 'Approvisionnement initial',
      status: 'SUCCESS',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    TransactionModel(
      id: 'tx-002',
      type: 'payment',
      title: 'Paiement marchand',
      currency: 'CDF',
      amount: 470000,
      target: 'Marchand partenaire',
      reason: 'Reglement service',
      status: 'SUCCESS',
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
    ),
  ]);

  static final List<BannerModel> banners = [
    BannerModel(
      title: 'Transferts fluides',
      subtitle: 'CDF et USD en un seul geste',
      badge: 'Flash',
    ),
    BannerModel(
      title: 'Validation rapide',
      subtitle: 'Vos operations sensibles restent sous controle',
      badge: 'Safe',
    ),
    BannerModel(
      title: 'LIKELEMBA',
      subtitle: 'Cotisez, suivez les retours et restez ensemble',
      badge: 'Epargne',
    ),
  ];

  static final List<ServiceItem> homeServices = [
    ServiceItem(title: "Envoi d'argent", icon: Icons.send_rounded),
    ServiceItem(title: 'Demande argent', icon: Icons.request_quote_rounded),
    ServiceItem(title: 'Change', icon: Icons.currency_exchange_rounded),
    ServiceItem(title: 'International', icon: Icons.public_rounded),
    ServiceItem(title: 'Retrait', icon: Icons.download_rounded, isNew: true),
    ServiceItem(title: 'Cartes', icon: Icons.credit_card_rounded),
    ServiceItem(title: 'Airtime', icon: Icons.phone_android_rounded),
    ServiceItem(title: 'TV', icon: Icons.tv_rounded),
    ServiceItem(title: 'Appro', icon: Icons.account_balance_wallet_rounded),
    ServiceItem(title: 'Validation', icon: Icons.verified_rounded),
  ];

  static AccountModel getSelectedWallet() {
    return wallets.value.firstWhere(
      (wallet) => wallet.selected,
      orElse: () => wallets.value.first,
    );
  }

  static AccountModel getWalletByCurrency(String currency) {
    return wallets.value.firstWhere(
      (wallet) => wallet.currency == currency,
      orElse: () => wallets.value.first,
    );
  }

  static void selectWallet(String id) {
    wallets.value =
        wallets.value.map((wallet) => wallet.copyWith(selected: wallet.id == id)).toList();
  }

  static bool canSend({
    required String currency,
    required double amount,
  }) {
    final wallet = getWalletByCurrency(currency);
    return wallet.balance >= amount;
  }

  static bool debitWallet({
    required String currency,
    required double amount,
  }) {
    if (amount <= 0) return false;

    final currentWallets = [...wallets.value];
    final index = currentWallets.indexWhere((wallet) => wallet.currency == currency);
    if (index == -1) return false;

    final wallet = currentWallets[index];
    if (wallet.balance < amount) return false;

    currentWallets[index] = wallet.copyWith(balance: wallet.balance - amount);
    wallets.value = currentWallets;
    return true;
  }

  static bool creditWallet({
    required String currency,
    required double amount,
  }) {
    if (amount <= 0) return false;

    final currentWallets = [...wallets.value];
    final index = currentWallets.indexWhere((wallet) => wallet.currency == currency);
    if (index == -1) return false;

    final wallet = currentWallets[index];
    currentWallets[index] = wallet.copyWith(balance: wallet.balance + amount);
    wallets.value = currentWallets;
    return true;
  }

  static void addTransaction({
    required String type,
    required String title,
    required String currency,
    required double amount,
    required String target,
    required String reason,
    String status = 'SUCCESS',
    DateTime? createdAt,
  }) {
    final current = [...transactions.value];
    current.insert(
      0,
      TransactionModel(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        type: type,
        title: title,
        currency: currency,
        amount: amount,
        target: target,
        reason: reason,
        status: status,
        createdAt: createdAt ?? DateTime.now(),
      ),
    );
    transactions.value = current;
  }

  static bool sendMoney({
    required String mode,
    required String currency,
    required double amount,
    required String phone,
    required String reason,
  }) {
    final ok = debitWallet(currency: currency, amount: amount);
    if (!ok) return false;

    addTransaction(
      type: 'send_money',
      title: "Envoi d'argent",
      currency: currency,
      amount: amount,
      target: phone,
      reason: '$mode - $reason',
    );
    return true;
  }

  static bool exchangeMoney({
    required String fromCurrency,
    required String toCurrency,
    required double amount,
    required double convertedAmount,
  }) {
    if (amount <= 0 || convertedAmount <= 0) return false;
    if (fromCurrency == toCurrency) return false;

    final debited = debitWallet(currency: fromCurrency, amount: amount);
    if (!debited) return false;

    final credited = creditWallet(currency: toCurrency, amount: convertedAmount);
    if (!credited) {
      creditWallet(currency: fromCurrency, amount: amount);
      return false;
    }

    addTransaction(
      type: 'exchange_money',
      title: 'Change de devise',
      currency: fromCurrency,
      amount: amount,
      target: toCurrency,
      reason:
          '$fromCurrency ${amount.toStringAsFixed(2)} vers $toCurrency ${convertedAmount.toStringAsFixed(2)}',
    );
    return true;
  }

  static void requestMoney({
    required String mode,
    required String currency,
    required double amount,
    required String phone,
    required String reason,
  }) {
    addTransaction(
      type: 'request_money',
      title: "Demande d'argent",
      currency: currency,
      amount: amount,
      target: phone,
      reason: '$mode - $reason',
      status: 'PENDING',
    );
  }

  static List<Map<String, dynamic>> transactionMaps() {
    return transactions.value.map(_mapTransaction).toList();
  }

  static Map<String, dynamic> currentUserMap({
    required String phone,
  }) {
    final selected = getSelectedWallet();
    return {
      'id': 'local-user-1',
      'name': profileName.value,
      'phone': phone,
      'pin': '1234',
      'wallet': {
        'id': selected.id,
        'balance': selected.balance,
        'currency': selected.currency,
      },
    };
  }

  static Map<String, dynamic> _mapTransaction(TransactionModel tx) {
    final normalized = tx.type.toLowerCase();
    final isCredit = normalized == 'deposit' ||
        normalized == 'reception' ||
        normalized == 'request_money';

    final typeMap = <String, String>{
      'deposit': 'DEPOT',
      'payment': 'PAIEMENT',
      'send_money': 'TRANSFERT',
      'request_money': 'DEMANDE_ARGENT',
      'exchange_money': 'EXCHANGE',
      'airtime': 'AIRTIME',
      'tv': 'TV',
      'withdraw': 'RETRAIT',
      'reception': 'RECEPTION',
      'qr_pay': 'QR_PAY',
      'card': 'CARTE',
      'card_topup': 'CARTE_RECHARGE',
      'account': 'COMPTE',
    };

    return {
      'type': typeMap[normalized] ?? normalized.toUpperCase(),
      'label': tx.title,
      'amount': tx.amount,
      'currency': tx.currency,
      'target': tx.target,
      'motif': tx.reason,
      'status': tx.status,
      'isCredit': isCredit,
      'date': tx.createdAt.toIso8601String(),
    };
  }
}
