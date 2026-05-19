class CashAgentOption {
  final String id;
  final String code;
  final String name;
  final String? phone;
  final String? location;
  final double dailyCashInLimit;
  final double dailyCashOutLimit;

  const CashAgentOption({
    required this.id,
    required this.code,
    required this.name,
    required this.dailyCashInLimit,
    required this.dailyCashOutLimit,
    this.phone,
    this.location,
  });

  factory CashAgentOption.fromJson(Map<String, dynamic> json) {
    return CashAgentOption(
      id: (json['id'] ?? '').toString(),
      code: (json['code'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      phone: json['phone']?.toString(),
      location: json['location']?.toString(),
      dailyCashInLimit:
          double.tryParse((json['dailyCashInLimit'] ?? 0).toString()) ?? 0,
      dailyCashOutLimit:
          double.tryParse((json['dailyCashOutLimit'] ?? 0).toString()) ?? 0,
    );
  }

  String get label {
    final place = (location ?? '').trim();
    return place.isEmpty ? name : '$name - $place';
  }
}
