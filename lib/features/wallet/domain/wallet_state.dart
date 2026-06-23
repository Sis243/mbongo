class TxEntry {
  final String id;
  final String type;
  final String label;
  final double amount;
  final String currency;
  final String target;
  final String motif;
  final String status;
  final bool isCredit;
  final DateTime date;

  const TxEntry({
    required this.id,
    required this.type,
    required this.label,
    required this.amount,
    required this.currency,
    required this.target,
    required this.motif,
    required this.status,
    required this.isCredit,
    required this.date,
  });

  factory TxEntry.fromMap(Map<String, dynamic> m) {
    final type = (m['type'] ?? '').toString().toLowerCase();
    final isCredit = m['isCredit'] == true ||
        type == 'depot' ||
        type == 'reception' ||
        type == 'demande_argent';
    return TxEntry(
      id: m['id']?.toString() ?? '',
      type: type,
      label: m['label']?.toString() ?? m['description']?.toString() ?? type,
      amount: ((m['amount'] ?? 0) as num).toDouble(),
      currency: m['currency']?.toString() ?? 'CDF',
      target: m['target']?.toString() ?? m['receiverPhone']?.toString() ?? '',
      motif: m['motif']?.toString() ?? m['description']?.toString() ?? '',
      status: m['status']?.toString() ?? 'SUCCESS',
      isCredit: isCredit,
      date: m['date'] != null
          ? DateTime.tryParse(m['date'].toString()) ?? DateTime.now()
          : m['createdAt'] != null
              ? DateTime.tryParse(m['createdAt'].toString()) ?? DateTime.now()
              : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'type': type,
        'label': label,
        'amount': amount,
        'currency': currency,
        'target': target,
        'motif': motif,
        'status': status,
        'isCredit': isCredit,
        'date': date.toIso8601String(),
      };
}

class WalletData {
  final String id;
  final double balance;
  final String currency;
  final List<TxEntry> transactions;
  // Extra balances for multi-currency display: [{currency: 'USD', balance: 0.0}, ...]
  final List<Map<String, dynamic>> extraBalances;
  // true quand les données viennent du cache local (hors ligne)
  final bool fromCache;

  const WalletData({
    required this.id,
    required this.balance,
    required this.currency,
    required this.transactions,
    this.extraBalances = const [],
    this.fromCache = false,
  });

  WalletData copyWith({
    double? balance,
    List<TxEntry>? transactions,
    List<Map<String, dynamic>>? extraBalances,
  }) =>
      WalletData(
        id: id,
        balance: balance ?? this.balance,
        currency: currency,
        transactions: transactions ?? this.transactions,
        extraBalances: extraBalances ?? this.extraBalances,
        fromCache: fromCache,
      );

  double get totalOutgoing => transactions
      .where((t) => !t.isCredit && t.status != 'FAILED')
      .fold(0, (s, t) => s + t.amount);

  double get totalIncoming => transactions
      .where((t) => t.isCredit && t.status != 'FAILED')
      .fold(0, (s, t) => s + t.amount);

  int get pendingCount =>
      transactions.where((t) => t.status.toUpperCase() == 'PENDING').length;
}
