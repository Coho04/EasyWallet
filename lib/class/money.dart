import 'package:intl/intl.dart';

/// One place for how amounts are written, so every view shows them the same
/// way: the amount first, then the currency symbol, with the separators of
/// the active locale.
class Money {
  const Money._();

  /// Formats [amount] for display, e.g. `17,99 €` in German and `17.99 €` in
  /// English. [locale] defaults to the locale the app is running in.
  static String format(double amount, String symbol, {String? locale}) {
    final formatter = NumberFormat.decimalPatternDigits(
      locale: locale ?? Intl.getCurrentLocale(),
      decimalDigits: 2,
    );
    return '${formatter.format(amount)} $symbol';
  }
}
