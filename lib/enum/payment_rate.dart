import 'package:intl/intl.dart';

enum PaymentRate {
  yearly(value: 'yearly'),
  monthly(value: 'monthly');

  const PaymentRate({
    required this.value,
  });

  final String value;

  String translate() {
    return Intl.message(value);
  }

  static List<String> all() {
    return PaymentRate.values.map((e) => e.value).toList();
  }
}
