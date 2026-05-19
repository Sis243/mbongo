class AccountModel {
  final String id;
  final String type;
  final String currency;
  final String number;
  final double balance;
  final bool selected;

  const AccountModel({
    required this.id,
    required this.type,
    required this.currency,
    required this.number,
    required this.balance,
    this.selected = false,
  });

  AccountModel copyWith({
    String? id,
    String? type,
    String? currency,
    String? number,
    double? balance,
    bool? selected,
  }) {
    return AccountModel(
      id: id ?? this.id,
      type: type ?? this.type,
      currency: currency ?? this.currency,
      number: number ?? this.number,
      balance: balance ?? this.balance,
      selected: selected ?? this.selected,
    );
  }
}