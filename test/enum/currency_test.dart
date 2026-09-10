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

    test('code returns the ISO 4217 code', () {
      expect(Currency.eur.code, equals("EUR"));
      expect(Currency.usd.code, equals("USD"));
    });

    test('code is spelled out where the enum constant cannot be', () {
      // `try` is a Dart keyword, so the constant has to be spelled otherwise.
      expect(Currency.tRy.code, equals("TRY"));
    });

    test('every currency carries a distinct ISO code', () {
      final codes = Currency.values.map((e) => e.code).toList();
      expect(codes.toSet().length, equals(codes.length));
      expect(codes.every((c) => RegExp(r'^[A-Z]{3}$').hasMatch(c)), isTrue);
    });

    test('findByCode finds the currency for a code', () {
      expect(Currency.findByCode("EUR"), equals(Currency.eur));
      expect(Currency.findByCode("INR"), equals(Currency.inr));
    });

    test('findByCode ignores case and surrounding whitespace', () {
      expect(Currency.findByCode(" eur "), equals(Currency.eur));
    });

    test('findByCode returns null for a code the app does not carry', () {
      expect(Currency.findByCode("XYZ"), isNull);
      expect(Currency.findByCode(""), isNull);
    });
  });
}
