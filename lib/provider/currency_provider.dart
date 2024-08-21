import 'package:easy_wallet/enum/currency.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CurrencyProvider with ChangeNotifier {

  Currency _currency = Currency.usd;
  Currency get currency => _currency;

  Future<void> loadCurrency() async {
    final prefs = await SharedPreferences.getInstance();
    String name = prefs.getString('currency') ?? Currency.usd.name;
    _currency = Currency.findByName(name);
    notifyListeners();
  }
}
