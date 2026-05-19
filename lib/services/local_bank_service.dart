import 'package:flutter/material.dart';

import '../models/account_model.dart';
import '../models/transaction_model.dart';
import '../store/mbongo_store.dart';
import 'api_service.dart';
import 'auth_service.dart';

class LocalBankService {
  static String _phone = '0990000000';
  static String _pin = '1234';
  static String? _remoteUserId;
  static final bool _bindingsReady = _attachBindings();

  static final ValueNotifier<Map<String, dynamic>> currentUser =
      ValueNotifier<Map<String, dynamic>>(_buildCurrentUser());

  static final ValueNotifier<List<Map<String, dynamic>>> transactions =
      ValueNotifier<List<Map<String, dynamic>>>(MbongoStore.transactionMaps());

  static final ValueNotifier<List<Map<String, dynamic>>> virtualCards =
      ValueNotifier<List<Map<String, dynamic>>>([]);

  static final ValueNotifier<List<Map<String, dynamic>>> currencies =
      ValueNotifier<List<Map<String, dynamic>>>([]);

  static final ValueNotifier<List<Map<String, dynamic>>> merchantAccounts =
      ValueNotifier<List<Map<String, dynamic>>>([]);

  static final ValueNotifier<List<Map<String, dynamic>>> merchantTerminals =
      ValueNotifier<List<Map<String, dynamic>>>([]);

  static final ValueNotifier<List<Map<String, dynamic>>> posReceipts =
      ValueNotifier<List<Map<String, dynamic>>>([]);

  static final ValueNotifier<List<Map<String, dynamic>>> merchantRoles =
      ValueNotifier<List<Map<String, dynamic>>>([]);

  static bool _attachBindings() {
    MbongoStore.wallets.addListener(_syncState);
    MbongoStore.transactions.addListener(_syncState);
    return true;
  }

  static Map<String, dynamic> _buildCurrentUser() {
    final user = MbongoStore.currentUserMap(phone: _phone);
    return {
      ...user,
      'pin': _pin,
    };
  }

  static Map<String, dynamic> _normalizeUser(Map<String, dynamic> user) {
    final wallet =
        Map<String, dynamic>.from(user['wallet'] ?? const <String, dynamic>{});
    return {
      'id': user['id']?.toString() ?? 'local-user-1',
      'name': user['name']?.toString() ?? MbongoStore.profileName.value,
      'phone': user['phone']?.toString() ?? _phone,
      'wallet': {
        'id': wallet['id']?.toString() ?? 'wallet-cdf',
        'balance': ((wallet['balance'] ?? 0) as num).toDouble(),
        'currency': (wallet['currency'] ?? 'CDF').toString(),
      },
    };
  }

  static void _applyCurrentUser(Map<String, dynamic> user) {
    final normalized = _normalizeUser(user);
    _remoteUserId = normalized['id']?.toString();
    _phone = normalized['phone']?.toString() ?? _phone;
    MbongoStore.profileName.value =
        normalized['name']?.toString() ?? MbongoStore.profileName.value;
    currentUser.value = normalized;
    _setWalletBalance(
      balance:
          ((normalized['wallet'] as Map<String, dynamic>)['balance'] as num)
              .toDouble(),
      currency:
          ((normalized['wallet'] as Map<String, dynamic>)['currency'] ?? 'CDF')
              .toString(),
      walletId:
          ((normalized['wallet'] as Map<String, dynamic>)['id'] ?? 'wallet-cdf')
              .toString(),
    );
  }

  static void _applyTransactions(List<Map<String, dynamic>> items) {
    final mapped = items.map(_mapRemoteTransaction).toList();
    transactions.value = mapped;
    MbongoStore.transactions.value = items.map(_toTransactionModel).toList();
  }

  static void _applyLedgerEntries(List<Map<String, dynamic>> items) {
    final mapped = items.map(_mapLedgerEntry).toList();
    transactions.value = mapped;
    MbongoStore.transactions.value =
        items.map(_ledgerToTransactionModel).toList();
  }

  static void _applyVirtualCards(List<Map<String, dynamic>> items) {
    virtualCards.value = items.map(_mapRemoteVirtualCard).toList();
  }

  static Map<String, dynamic> _mapRemoteVirtualCard(Map<String, dynamic> item) {
    final maskedPan = (item['maskedPan'] ?? '**** **** **** ****').toString();
    return {
      'id': item['id']?.toString() ?? '',
      'holderName': item['holderName']?.toString() ?? 'CLIENT MBONGO',
      'currency': item['currency']?.toString() ?? 'CDF',
      'brand': item['brand']?.toString() ?? 'VISA',
      'pan': maskedPan,
      'maskedPan': maskedPan,
      'cvv': '***',
      'expiry': item['expiry']?.toString() ?? '',
      'balance': ((item['balance'] ?? 0) as num).toDouble(),
      'status': item['status']?.toString() ?? 'ACTIVE',
      'createdAt':
          item['createdAt']?.toString() ?? DateTime.now().toIso8601String(),
      'updatedAt':
          item['updatedAt']?.toString() ?? DateTime.now().toIso8601String(),
    };
  }

  static Map<String, dynamic> _mapRemoteTransaction(Map<String, dynamic> item) {
    final type = (item['type'] ?? 'TRANSACTION').toString();
    final amount = ((item['amount'] ?? 0) as num).toDouble();
    final senderId = item['senderId']?.toString();
    final receiverId = item['receiverId']?.toString();
    final normalizedType =
        type.startsWith('TRANSFER') ? 'TRANSFERT' : type.toUpperCase();
    final isCredit = receiverId != null && receiverId == _remoteUserId;

    return {
      'type': normalizedType,
      'label':
          normalizedType == 'TRANSFERT' ? 'Transfert Mbongo' : normalizedType,
      'amount': amount,
      'currency': 'CDF',
      'target': isCredit ? (senderId ?? 'MBONGO') : (receiverId ?? 'MBONGO'),
      'motif': type,
      'status': 'SUCCESS',
      'isCredit': isCredit,
      'date': item['createdAt']?.toString() ?? DateTime.now().toIso8601String(),
    };
  }

  static Map<String, dynamic> _mapLedgerEntry(Map<String, dynamic> item) {
    final direction = (item['direction'] ?? '').toString().toUpperCase();
    final entryType =
        (item['entryType'] ?? 'TRANSACTION').toString().toUpperCase();
    final description = (item['description'] ?? '').toString();
    final metadata = (item['metadata'] ?? '').toString();
    final transaction = item['transaction'] is Map<String, dynamic>
        ? Map<String, dynamic>.from(item['transaction'] as Map<String, dynamic>)
        : item['transaction'] is Map
            ? Map<String, dynamic>.from(item['transaction'] as Map)
            : <String, dynamic>{};
    final amount = ((item['amount'] ?? 0) as num).toDouble();
    final isCredit = direction == 'CREDIT';
    final type = switch (entryType) {
      'DEPOSIT' => 'DEPOT',
      'WITHDRAW' => 'RETRAIT',
      'TRANSFER' => 'TRANSFERT',
      _ => entryType,
    };
    final label = switch (entryType) {
      'DEPOSIT' => 'Depot wallet',
      'WITHDRAW' => 'Retrait',
      'TRANSFER' => 'Transfert Mbongo',
      _ => description.isEmpty ? 'Mouvement wallet' : description,
    };

    return {
      'id': item['id']?.toString() ?? '',
      'type': type,
      'label': label,
      'amount': amount,
      'currency': 'CDF',
      'target': transaction['receiverId']?.toString() ??
          transaction['senderId']?.toString() ??
          'MBONGO',
      'motif': description.isEmpty ? entryType : description,
      'status': 'SUCCESS',
      'isCredit': isCredit,
      'date': item['createdAt']?.toString() ?? DateTime.now().toIso8601String(),
      'description': description,
      'metadata': metadata,
      'balanceBefore': ((item['balanceBefore'] ?? 0) as num).toDouble(),
      'balanceAfter': ((item['balanceAfter'] ?? 0) as num).toDouble(),
      'entryType': entryType,
    };
  }

  static TransactionModel _toTransactionModel(Map<String, dynamic> item) {
    final mapped = _mapRemoteTransaction(item);
    return TransactionModel(
      id: item['id']?.toString() ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      type: mapped['type']?.toString().toLowerCase() ?? 'transaction',
      title: mapped['label']?.toString() ?? 'Transaction',
      currency: mapped['currency']?.toString() ?? 'CDF',
      amount: ((mapped['amount'] ?? 0) as num).toDouble(),
      target: mapped['target']?.toString() ?? 'MBONGO',
      reason: mapped['motif']?.toString() ?? '',
      status: mapped['status']?.toString() ?? 'SUCCESS',
      createdAt:
          DateTime.tryParse(mapped['date']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  static TransactionModel _ledgerToTransactionModel(Map<String, dynamic> item) {
    final mapped = _mapLedgerEntry(item);
    return TransactionModel(
      id: mapped['id']?.toString() ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      type: mapped['type']?.toString().toLowerCase() ?? 'transaction',
      title: mapped['label']?.toString() ?? 'Mouvement wallet',
      currency: mapped['currency']?.toString() ?? 'CDF',
      amount: ((mapped['amount'] ?? 0) as num).toDouble(),
      target: mapped['target']?.toString() ?? 'MBONGO',
      reason: mapped['motif']?.toString() ?? '',
      status: mapped['status']?.toString() ?? 'SUCCESS',
      createdAt:
          DateTime.tryParse(mapped['date']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  static void _setWalletBalance({
    required double balance,
    required String currency,
    required String walletId,
  }) {
    final wallets = [...MbongoStore.wallets.value];
    final selectedIndex =
        wallets.indexWhere((wallet) => wallet.currency == currency);

    if (selectedIndex == -1) {
      wallets.insert(
        0,
        AccountModel(
          id: walletId,
          type: 'Portefeuille $currency',
          currency: currency,
          number: 'MBONGO-$currency',
          balance: balance,
          selected: true,
        ),
      );
      MbongoStore.wallets.value = wallets;
      return;
    }

    wallets[selectedIndex] = wallets[selectedIndex].copyWith(
      id: walletId,
      balance: balance,
      selected: true,
    );
    MbongoStore.wallets.value = [
      for (var i = 0; i < wallets.length; i++)
        wallets[i].copyWith(selected: i == selectedIndex),
    ];
  }

  static Future<void> refreshRemoteState() async {
    final user = await AuthService.getCurrentUser();
    final userId = user?['id']?.toString();
    if (userId == null || userId.isEmpty) {
      return;
    }

    _remoteUserId = userId;

    try {
      final walletSummary = await ApiService.getWalletSummary(userId);
      final remoteCards = await ApiService.getVirtualCards(userId);
      final wallet = Map<String, dynamic>.from(
          walletSummary['wallet'] ?? const <String, dynamic>{});
      final recentLedgerEntries =
          ((walletSummary['recentLedgerEntries'] as List?) ?? const [])
              .map((item) => Map<String, dynamic>.from(item as Map))
              .toList();

      final mergedUser = {
        ...user!,
        'wallet': {
          'id': wallet['id']?.toString() ?? 'wallet-cdf',
          'balance': ((wallet['balance'] ?? 0) as num).toDouble(),
          'currency': 'CDF',
        },
      };

      _applyCurrentUser(mergedUser);
      _applyVirtualCards(remoteCards);
      if (recentLedgerEntries.isNotEmpty) {
        _applyLedgerEntries(recentLedgerEntries);
      } else {
        final fallbackTransactions =
            ((walletSummary['recentTransactions'] as List?) ?? const [])
                .map((item) => Map<String, dynamic>.from(item as Map))
                .toList();
        _applyTransactions(fallbackTransactions);
      }
      await AuthService.setCurrentUser(mergedUser);

      // Load merchant data in background — non-blocking
      _refreshMerchantData();
    } on ApiException {
      final refreshed = await ApiService.refreshSession();
      final tokens = Map<String, dynamic>.from(
          refreshed['tokens'] ?? const <String, dynamic>{});
      final refreshedUser = Map<String, dynamic>.from(
          refreshed['user'] ?? const <String, dynamic>{});

      await AuthService.saveSession(
        accessToken: tokens['accessToken']?.toString() ?? '',
        refreshToken: tokens['refreshToken']?.toString() ?? '',
        user: refreshedUser,
      );

      _applyCurrentUser(refreshedUser);
      await refreshRemoteState();
    }
  }

  static Future<void> _refreshMerchantData() async {
    try {
      final results = await Future.wait([
        ApiService.getCurrencies(),
        ApiService.getMerchantAccounts(),
        ApiService.getMerchantTerminals(),
        ApiService.getMerchantReceipts(),
        ApiService.getMerchantRoles(),
      ]);
      currencies.value = results[0];
      merchantAccounts.value = results[1];
      merchantTerminals.value = results[2];
      posReceipts.value = results[3];
      merchantRoles.value = results[4];
    } catch (_) {
      // Keep existing values if API unavailable
    }
  }

  static void _syncState() {
    if (!_bindingsReady) return;
    currentUser.value = _buildCurrentUser();
    transactions.value = MbongoStore.transactionMaps();
  }

  static String _idempotencyKey(String prefix) {
    final userPart =
        (_remoteUserId ?? _phone).replaceAll(RegExp(r'[^A-Za-z0-9]'), '');
    return '$prefix-$userPart-${DateTime.now().microsecondsSinceEpoch}';
  }

  static Future<void> restoreSession() async {
    final user = await AuthService.getCurrentUser();
    if (user == null) {
      _syncState();
      return;
    }

    _applyCurrentUser(user);
    await refreshRemoteState();
  }

  static Future<void> login({
    required String phone,
    required String pin,
  }) async {
    final response = await ApiService.login(phone: phone, pin: pin);
    final user = Map<String, dynamic>.from(
        response['user'] ?? const <String, dynamic>{});
    final tokens = Map<String, dynamic>.from(
        response['tokens'] ?? const <String, dynamic>{});

    await AuthService.saveSession(
      accessToken: tokens['accessToken']?.toString() ?? '',
      refreshToken: tokens['refreshToken']?.toString() ?? '',
      user: user,
    );

    _pin = pin;
    _applyCurrentUser(user);
    await refreshRemoteState();
  }

  static Future<void> register({
    required String name,
    required String phone,
    required String pin,
  }) async {
    final response =
        await ApiService.register(name: name, phone: phone, pin: pin);
    final user = Map<String, dynamic>.from(
        response['user'] ?? const <String, dynamic>{});
    final tokens = Map<String, dynamic>.from(
        response['tokens'] ?? const <String, dynamic>{});

    await AuthService.saveSession(
      accessToken: tokens['accessToken']?.toString() ?? '',
      refreshToken: tokens['refreshToken']?.toString() ?? '',
      user: user,
    );

    _pin = pin;
    _applyCurrentUser(user);
    await refreshRemoteState();
  }

  static Future<bool> sendMoney({
    required String to,
    required double amount,
    required String motif,
    String currency = 'CDF',
  }) async {
    if ((_remoteUserId ?? '').isEmpty) {
      throw const ApiException('Session utilisateur introuvable');
    }

    if (currency != 'CDF') {
      throw const ApiException(
          'Le transfert API est actuellement disponible en CDF');
    }

    await ApiService.transfer(
      senderId: _remoteUserId!,
      receiverPhone: to,
      amount: amount,
      description: motif,
      idempotencyKey: _idempotencyKey('transfer'),
    );

    await refreshRemoteState();
    return true;
  }

  static bool requestMoney({
    required String phone,
    required double amount,
    required String motif,
    String mode = 'Illico',
    String currency = 'CDF',
  }) {
    if (amount <= 0 || phone.trim().isEmpty) return false;

    MbongoStore.requestMoney(
      mode: mode,
      currency: currency,
      amount: amount,
      phone: phone,
      reason: motif,
    );
    _syncState();
    return true;
  }

  static void recordExchange({
    required String fromCurrency,
    required String toCurrency,
    required double amount,
    required double convertedAmount,
  }) {
    _syncState();
  }

  static Future<bool> buyAirtime({
    required String operatorName,
    required String phone,
    required double amount,
    String currency = 'CDF',
  }) async {
    if ((_remoteUserId ?? '').isEmpty) {
      throw const ApiException('Session utilisateur introuvable');
    }

    if (currency != 'CDF') {
      throw const ApiException(
          "L'achat d'unites API est actuellement disponible en CDF");
    }

    await ApiService.buyAirtime(
      userId: _remoteUserId!,
      operatorName: operatorName,
      phone: phone,
      amount: amount,
      idempotencyKey: _idempotencyKey('airtime'),
    );

    await refreshRemoteState();
    return true;
  }

  static Future<bool> payTvSubscription({
    required String providerName,
    required String subscriberId,
    required String bouquetName,
    required double amount,
    String currency = 'CDF',
  }) async {
    if ((_remoteUserId ?? '').isEmpty) {
      throw const ApiException('Session utilisateur introuvable');
    }

    if (currency != 'CDF') {
      throw const ApiException(
          'Le paiement TV API est actuellement disponible en CDF');
    }

    await ApiService.payTv(
      userId: _remoteUserId!,
      providerName: providerName,
      subscriberId: subscriberId,
      bouquetName: bouquetName,
      amount: amount,
      idempotencyKey: _idempotencyKey('tv'),
    );

    await refreshRemoteState();
    return true;
  }

  static Future<bool> withdrawMoney({
    required double amount,
    required String mode,
    required String reference,
    String currency = 'CDF',
    String? phone,
    String? agentName,
    String? agentId,
  }) async {
    if ((_remoteUserId ?? '').isEmpty) {
      throw const ApiException('Session utilisateur introuvable');
    }

    if (currency != 'CDF') {
      throw const ApiException(
          'Le retrait API est actuellement disponible en CDF');
    }

    await ApiService.withdraw(
      userId: _remoteUserId!,
      amount: amount,
      channel: mode,
      reference: reference,
      phone: phone,
      agentName: agentName,
      agentId: agentId,
      idempotencyKey: _idempotencyKey('withdraw'),
    );

    await refreshRemoteState();
    return true;
  }

  static Future<void> receiveMoney({
    required String from,
    required double amount,
    String currency = 'CDF',
    String? agentName,
    String? agentId,
  }) async {
    if ((_remoteUserId ?? '').isEmpty) {
      throw const ApiException('Session utilisateur introuvable');
    }

    if (currency != 'CDF') {
      throw const ApiException(
          'Le depot API est actuellement disponible en CDF');
    }

    await ApiService.deposit(
      userId: _remoteUserId!,
      amount: amount,
      source: from,
      description: 'Credit entrant',
      agentName: agentName,
      agentId: agentId,
      idempotencyKey: _idempotencyKey('deposit'),
    );

    await refreshRemoteState();
  }

  static Future<void> payMerchant({
    required String merchant,
    required double amount,
    String currency = 'CDF',
    String method = 'QR',
    String? terminalLabel,
    String? location,
  }) async {
    if ((_remoteUserId ?? '').isEmpty) {
      throw const ApiException('Session utilisateur introuvable');
    }

    if (currency != 'CDF') {
      throw const ApiException(
          'Le paiement marchand API est actuellement disponible en CDF');
    }

    final terminalId = terminalLabel?.trim().isNotEmpty == true
        ? terminalLabel!.trim()
        : 'POS-GEN-01';
    final ticketId = 'rcpt-${DateTime.now().millisecondsSinceEpoch}';
    final scanRef = switch (method) {
      'Carte' =>
        'CARD-${DateTime.now().millisecond.toString().padLeft(4, '0')}',
      'NFC' => 'NFC-${DateTime.now().millisecond.toString().padLeft(4, '0')}',
      'Visage' =>
        'FACE-${DateTime.now().millisecond.toString().padLeft(4, '0')}',
      'Main' => 'PALM-${DateTime.now().millisecond.toString().padLeft(4, '0')}',
      _ => 'APP-${DateTime.now().millisecond.toString().padLeft(4, '0')}',
    };

    final steps = switch (method) {
      'Visage' => [
          'Terminal detecte',
          'Visage verifie',
          'Debit confirme',
          'Ticket emis'
        ],
      'Main' => [
          'Terminal detecte',
          'Paume analysee',
          'Debit confirme',
          'Ticket emis'
        ],
      'NFC' => [
          'Lecteur NFC pret',
          'Support rapproche',
          'Debit confirme',
          'Ticket emis'
        ],
      'Carte' => [
          'Carte lue',
          'Controle terminal',
          'Debit confirme',
          'Ticket emis'
        ],
      _ => [
          'Appareil scanne',
          'Session etablie',
          'Debit confirme',
          'Ticket emis'
        ],
    };

    await ApiService.payMerchant(
      userId: _remoteUserId!,
      merchant: merchant,
      amount: amount,
      method: method,
      terminalLabel: terminalLabel,
      location: location,
      idempotencyKey: _idempotencyKey('merchant'),
    );

    final receipts = List<Map<String, dynamic>>.from(posReceipts.value);
    receipts.insert(0, {
      'id': ticketId,
      'merchant': merchant,
      'terminalId': terminalId,
      'method': method,
      'amount': amount,
      'currency': currency,
      'status': 'SUCCESS',
      'location': location?.trim().isNotEmpty == true
          ? location!.trim()
          : 'Point de vente',
      'customerRef': scanRef,
      'createdAt': 'A l instant',
      'steps': steps,
    });
    posReceipts.value = receipts;

    final terminals = List<Map<String, dynamic>>.from(merchantTerminals.value);
    final terminalIndex =
        terminals.indexWhere((item) => item['id'] == terminalId);
    if (terminalIndex == -1) {
      terminals.insert(0, {
        'id': terminalId,
        'merchant': merchant,
        'location': location?.trim().isNotEmpty == true
            ? location!.trim()
            : 'Point de vente',
        'status': 'ONLINE',
        'lastMethod': method,
        'lastSeen': 'A l instant',
        'transactionsCount': 1,
        'health': 'healthy',
      });
    } else {
      final terminal = Map<String, dynamic>.from(terminals[terminalIndex]);
      terminal['merchant'] = merchant;
      terminal['location'] = location?.trim().isNotEmpty == true
          ? location!.trim()
          : terminal['location'];
      terminal['status'] = 'ONLINE';
      terminal['lastMethod'] = method;
      terminal['lastSeen'] = 'A l instant';
      terminal['transactionsCount'] =
          ((terminal['transactionsCount'] ?? 0) as num).toInt() + 1;
      terminal['health'] = method == 'Main' || method == 'Visage'
          ? 'healthy'
          : terminal['health'];
      terminals[terminalIndex] = terminal;
    }
    merchantTerminals.value = terminals;

    final accounts = List<Map<String, dynamic>>.from(merchantAccounts.value);
    final accountIndex =
        accounts.indexWhere((item) => item['name'] == merchant);
    if (accountIndex == -1) {
      accounts.insert(0, {
        'id': 'merch-${DateTime.now().microsecondsSinceEpoch}',
        'name': merchant,
        'category': 'Merchant',
        'location': location?.trim().isNotEmpty == true
            ? location!.trim()
            : 'Point de vente',
        'status': 'ACTIVE',
        'terminals': 1,
        'dailyVolume': amount,
      });
    } else {
      final account = Map<String, dynamic>.from(accounts[accountIndex]);
      account['dailyVolume'] =
          ((account['dailyVolume'] ?? 0) as num).toDouble() + amount;
      account['location'] = location?.trim().isNotEmpty == true
          ? location!.trim()
          : account['location'];
      account['status'] = 'ACTIVE';
      accounts[accountIndex] = account;
    }
    merchantAccounts.value = accounts;
    await refreshRemoteState();
  }

  static void upsertMerchantAccount({
    String? merchantId,
    required String name,
    required String category,
    required String location,
  }) {
    final accounts = List<Map<String, dynamic>>.from(merchantAccounts.value);
    final existingIndex = merchantId == null
        ? -1
        : accounts.indexWhere((item) => item['id'] == merchantId);

    if (existingIndex == -1) {
      accounts.insert(0, {
        'id': 'merch-${DateTime.now().microsecondsSinceEpoch}',
        'name': name,
        'category': category,
        'location': location,
        'status': 'ACTIVE',
        'terminals': 0,
        'dailyVolume': 0.0,
      });
    } else {
      final merchant = Map<String, dynamic>.from(accounts[existingIndex]);
      merchant['name'] = name;
      merchant['category'] = category;
      merchant['location'] = location;
      accounts[existingIndex] = merchant;

      merchantTerminals.value = [
        for (final terminal in merchantTerminals.value)
          if (terminal['merchantId'] == merchantId ||
              terminal['merchant'] == merchant['name'])
            {
              ...terminal,
              'merchant': name,
            }
          else
            terminal,
      ];
    }

    merchantAccounts.value = accounts;
  }

  static void onboardTerminal({
    required String merchantId,
    required String merchantName,
    required String terminalId,
    required String location,
  }) {
    final terminals = List<Map<String, dynamic>>.from(merchantTerminals.value);
    final existingIndex =
        terminals.indexWhere((item) => item['id'] == terminalId);

    if (existingIndex == -1) {
      terminals.insert(0, {
        'id': terminalId,
        'merchantId': merchantId,
        'merchant': merchantName,
        'location': location,
        'status': 'ONLINE',
        'lastMethod': 'Aucun',
        'lastSeen': 'A l instant',
        'transactionsCount': 0,
        'health': 'healthy',
      });
    } else {
      final terminal = Map<String, dynamic>.from(terminals[existingIndex]);
      terminal['merchantId'] = merchantId;
      terminal['merchant'] = merchantName;
      terminal['location'] = location;
      terminal['status'] = 'ONLINE';
      terminal['lastSeen'] = 'A l instant';
      terminals[existingIndex] = terminal;
    }

    merchantTerminals.value = terminals;

    merchantAccounts.value = [
      for (final merchant in merchantAccounts.value)
        if (merchant['id'] == merchantId)
          {
            ...merchant,
            'terminals': (((merchant['terminals'] ?? 0) as num).toInt()) + 1,
          }
        else
          merchant,
    ];
  }

  static void assignMerchantRole({
    required String merchantId,
    required String merchantName,
    required String name,
    required String role,
  }) {
    final permissions = switch (role) {
      'admin' => ['dashboard', 'tickets', 'terminals', 'refunds', 'users'],
      'commercial' => ['dashboard', 'payments', 'tickets'],
      _ => ['payments', 'tickets'],
    };

    merchantRoles.value = [
      {
        'id': 'role-${DateTime.now().microsecondsSinceEpoch}',
        'merchantId': merchantId,
        'merchant': merchantName,
        'name': name,
        'role': role,
        'permissions': permissions,
      },
      ...merchantRoles.value,
    ];
  }

  static Future<void> createVirtualCard({
    required String holderName,
    required String currency,
    required String brand,
  }) async {
    if ((_remoteUserId ?? '').isEmpty) {
      throw const ApiException('Session utilisateur introuvable');
    }

    await ApiService.createVirtualCard(
      userId: _remoteUserId!,
      holderName: holderName,
      currency: currency,
      brand: brand,
    );
    await refreshRemoteState();
  }

  static Future<bool> topupVirtualCard({
    required String cardId,
    required double amount,
  }) async {
    if (amount <= 0) return false;

    if ((_remoteUserId ?? '').isEmpty) {
      throw const ApiException('Session utilisateur introuvable');
    }

    await ApiService.topupVirtualCard(
      userId: _remoteUserId!,
      cardId: cardId,
      amount: amount,
      idempotencyKey: _idempotencyKey('card-topup'),
    );
    await refreshRemoteState();
    return true;
  }

  static Future<void> toggleVirtualCardStatus(String cardId) async {
    if ((_remoteUserId ?? '').isEmpty) {
      throw const ApiException('Session utilisateur introuvable');
    }

    await ApiService.toggleVirtualCardStatus(
      userId: _remoteUserId!,
      cardId: cardId,
    );
    await refreshRemoteState();
  }

  static Future<void> logout() async {
    try {
      await ApiService.logoutSession();
    } on ApiException {
      // Local logout must still work when the API is offline.
    }

    _remoteUserId = null;
    _phone = '0990000000';
    _pin = '1234';
    virtualCards.value = [];
    await AuthService.logout();
    _syncState();
  }
}
