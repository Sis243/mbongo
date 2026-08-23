class WalletInfo {
  final String id;
  final double balance;
  final String currency;

  const WalletInfo({
    required this.id,
    required this.balance,
    required this.currency,
  });

  factory WalletInfo.fromMap(Map<String, dynamic> map) => WalletInfo(
        id: map['id']?.toString() ?? '',
        balance: ((map['balance'] ?? 0) as num).toDouble(),
        currency: map['currency']?.toString() ?? 'CDF',
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'balance': balance,
        'currency': currency,
      };

  WalletInfo copyWith({double? balance}) => WalletInfo(
        id: id,
        balance: balance ?? this.balance,
        currency: currency,
      );
}

class AppUser {
  final String id;
  final String name;
  final String phone;
  final String? email;
  final String? kycStatus;
  final WalletInfo wallet;

  const AppUser({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
    this.kycStatus,
    required this.wallet,
  });

  factory AppUser.fromMap(Map<String, dynamic> map) {
    final walletMap = Map<String, dynamic>.from(
      (map['wallet'] as Map?)?.cast<String, dynamic>() ?? {},
    );
    return AppUser(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      phone: map['phone']?.toString() ?? '',
      email: map['email']?.toString(),
      kycStatus: map['kycStatus']?.toString(),
      wallet: WalletInfo.fromMap(walletMap),
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'phone': phone,
        if (email != null) 'email': email,
        'kycStatus': kycStatus,
        'wallet': wallet.toMap(),
      };
}
