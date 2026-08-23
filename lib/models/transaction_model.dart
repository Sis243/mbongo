class TransactionModel {
  final String id;
  final String type;
  final String title;
  final String currency;
  final double amount;
  final String target;
  final String reason;
  final String status;
  final DateTime createdAt;

  const TransactionModel({
    required this.id,
    required this.type,
    required this.title,
    required this.currency,
    required this.amount,
    required this.target,
    required this.reason,
    required this.status,
    required this.createdAt,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) => TransactionModel(
        id: json['id']?.toString() ?? '',
        type: json['type']?.toString() ?? '',
        title: json['title']?.toString() ?? '',
        currency: json['currency']?.toString() ?? 'CDF',
        amount: ((json['amount'] ?? 0) as num).toDouble(),
        target: json['target']?.toString() ?? '',
        reason: json['reason']?.toString() ?? '',
        status: json['status']?.toString() ?? '',
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
            : DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'title': title,
        'currency': currency,
        'amount': amount,
        'target': target,
        'reason': reason,
        'status': status,
        'createdAt': createdAt.toIso8601String(),
      };
}