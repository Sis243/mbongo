class Txn {
  final String title;
  final String subtitle;
  final int amount;
  final bool isCredit;
  final String time;

  Txn({
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.isCredit,
    required this.time,
  });
}

class MockData {
  static const userName = "Flory Mbondo";
  static const phone = "+243 821 123 456";

  static const balance = 2530000;

  static List<Txn> transactionsToday() => [
        Txn(
          title: "Dépôt CADECO",
          subtitle: "Estacul Piku",
          amount: 500000,
          isCredit: true,
          time: "14:32",
        ),
        Txn(
          title: "Transfert à Amir M",
          subtitle: "Envoyé",
          amount: 200000,
          isCredit: false,
          time: "09:58",
        ),
        Txn(
          title: "Retrait ATM",
          subtitle: "Hier",
          amount: 50000,
          isCredit: false,
          time: "Hier",
        ),
      ];
}