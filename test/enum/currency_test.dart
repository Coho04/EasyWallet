import 'package:easy_wallet/enum/currency.dart';
import 'package:flutter_test/flutter_test.dart';


void main() {
  group('Currency Tests', () {
    test('toString returns correct name', () {
      expect(Currency.usd.toString(), equals("US Dollar"));
      expect(Currency.eur.toString(), equals("Euro"));
    });

    test('all returns list of all currency names', () {
      List<String> expectedNames = [
        "US Dollar", "Euro", "British Pound", "Japanese Yen", "Swiss Franc",
        "Australian Dollar", "Canadian Dollar", "Chinese Yuan", "Swedish Krona",
        "New Zealand Dollar", "Mexican Peso", "Singapore Dollar",
        "Hong Kong Dollar", "Norwegian Krone", "South Korean Won",
        "Turkish Lira", "Russian Ruble", "Indian Rupee", "Brazilian Real",
        "South African Rand", "Danish Krone", "Polish Zloty", "Thai Baht",
        "Malaysian Ringgit", "Indonesian Rupiah", "Czech Koruna",
        "Hungarian Forint", "Philippine Peso", "United Arab Emirates Dirham",
        "Saudi Riyal", "Israeli New Shekel", "Bulgarian Lev", "Romanian Leu",
        "Chilean Peso", "Vietnamese Dong", "Pakistani Rupee", "Bangladeshi Taka",
        "Nigerian Naira", "Ukrainian Hryvnia", "Kazakhstani Tenge",
        "Qatari Riyal", "Egyptian Pound"
      ];
      expect(Currency.all(), equals(expectedNames));
    });

    test('findByName finds correct currency', () {
      var currency = Currency.findByName("Euro");
      expect(currency.name, equals("Euro"));
      expect(currency.symbol, equals("€"));
    });

    test('findByName returns default currency for non-existing currency', () {
      final result = Currency.findByName("Martian Dollar");
      expect(result, equals(Currency.eur)); 
    });
  });
}
