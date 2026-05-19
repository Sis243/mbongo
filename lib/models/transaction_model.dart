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
}