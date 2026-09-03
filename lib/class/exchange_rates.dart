/// Exchange rates relative to one base currency, as delivered by
/// https://frankfurter.dev.
///
/// Pure data with the conversion arithmetic on top: no network, no clock.
class ExchangeRates {
  const ExchangeRates({
    required this.base,
    required this.rates,
    required this.fetchedAt,
  });

  final String base;

  /// Currency code to its value in one unit of [base].
  final Map<String, double> rates;
  final DateTime fetchedAt;

  /// Rates older than this are refreshed when the network allows it. Frankfurter
  /// publishes once per working day, so half a day is plenty.
  static const Duration maxAge = Duration(hours: 12);

  bool isStaleAt(DateTime now) => now.difference(fetchedAt) > maxAge;

  /// [amount] expressed in [to]. Returns the amount unchanged when a rate is
  /// missing, so a gap in the data can never silently distort a total.
  double convert(double amount, {required String from, required String to}) {
    final source = from.toUpperCase();
    final target = to.toUpperCase();
    if (source == target) {
      return amount;
    }

    final fromRate = _rateOf(source);
    final toRate = _rateOf(target);
    if (fromRate == null || toRate == null) {
      return amount;
    }

    return amount / fromRate * toRate;
  }

  /// One unit of [code] expressed in [base]; the base itself is 1.
  double? _rateOf(String code) {
    if (code == base.toUpperCase()) {
      return 1;
    }
    return rates[code];
  }

  Map<String, dynamic> toJson() => {
        'base': base,
        'rates': rates,
        'fetchedAt': fetchedAt.toIso8601String(),
      };

  factory ExchangeRates.fromJson(Map<String, dynamic> json) => ExchangeRates(
        base: json['base'] as String,
        rates: (json['rates'] as Map).map(
          (key, value) => MapEntry(key.toString(), (value as num).toDouble()),
        ),
        fetchedAt: DateTime.parse(json['fetchedAt'] as String),
      );

  /// The shape frankfurter.dev answers with.
  factory ExchangeRates.fromApi(
    Map<String, dynamic> json, {
    required DateTime fetchedAt,
  }) =>
      ExchangeRates(
        base: json['base'] as String,
        rates: (json['rates'] as Map).map(
          (key, value) => MapEntry(key.toString(), (value as num).toDouble()),
        ),
        fetchedAt: fetchedAt,
      );
}
