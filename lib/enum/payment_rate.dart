enum PaymentRate {
  yearly(value: 'yearly'),
  monthly(value: 'monthly');

  const PaymentRate({
    required this.value,
  });

  final String value;

  static List<String> all() {
    return PaymentRate.values.map((e) => e.value).toList();
  }
}
