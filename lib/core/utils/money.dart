import 'package:intl/intl.dart';

class Money {
  static String format(num value, String currency) {
    final formatter = NumberFormat("#,##0.00", "fr_FR");
    final text = formatter.format(value);
    if (currency == "USD") return "\$ $text";
    return "CDF $text";
  }

  static String symbol(String currency) {
    return currency == "USD" ? "USD" : "CDF";
  }
}