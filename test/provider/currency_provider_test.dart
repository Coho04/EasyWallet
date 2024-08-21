import 'package:easy_wallet/provider/currency_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:easy_wallet/enum/currency.dart';

class MockSharedPreferences extends Mock implements SharedPreferences {}

void main() {
  group('CurrencyProvider Tests', () {
    late MockSharedPreferences mockPrefs;
    late CurrencyProvider currencyProvider;

    setUp(() {
      mockPrefs = MockSharedPreferences();
      currencyProvider = CurrencyProvider();
    });

    test('Initial currency is USD', () {
      expect(currencyProvider.currency, equals(Currency.usd));
    });

    test('loadCurrency loads currency from SharedPreferences', () async {
      when(mockPrefs.getString('currency')).thenReturn('eur');
      SharedPreferences.setMockInitialValues({'currency': 'eur'});
      await currencyProvider.loadCurrency();
      expect(currencyProvider.currency, equals(Currency.eur));
    });

    test('loadCurrency defaults to USD if no preference set', () async {
      when(mockPrefs.getString('currency')).thenReturn(null);
      SharedPreferences.setMockInitialValues({});

      await currencyProvider.loadCurrency();
      expect(currencyProvider.currency, equals(Currency.usd));
    });

    test('loadCurrency calls notifyListeners', () async {
      var notifyListenersCalled = false;
      currencyProvider.addListener(() {
        notifyListenersCalled = true;
      });

      await currencyProvider.loadCurrency();
      expect(notifyListenersCalled, isTrue);
    });
  });
}
