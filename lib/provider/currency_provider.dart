import 'package:easy_wallet/class/exchange_rates.dart';
import 'package:easy_wallet/enum/currency.dart';
import 'package:easy_wallet/managers/exchange_rate_service.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CurrencyProvider with ChangeNotifier {

  Currency _currency = Currency.usd;
  Currency get currency => _currency;

  ExchangeRates? _rates;

  /// Rates for converting subscriptions billed in another currency. Null until
  /// they were fetched once; conversions then simply do not happen.
  ExchangeRates? get rates => _rates;

  Future<void> loadCurrency() async {
    final prefs = await SharedPreferences.getInstance();
    String name = prefs.getString('currency') ?? Currency.usd.name;
    _currency = Currency.findByName(name);
    notifyListeners();
  }

  /// Fetches the conversion rates. Deliberately separate from loadCurrency:
  /// reading the setting must not depend on the network, and callers that do
  /// not convert anything should not pay for a request.
  Future<void> loadRates() async {
    try {
      _rates = await ExchangeRateService().ratesFor(_currency.name);
      notifyListeners();
    } catch (_) {
      // Conversion stays off; amounts are shown as entered.
    }
  }
}
