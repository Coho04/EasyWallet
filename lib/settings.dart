import 'package:easy_wallet/enum/currency.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Settings {

  static Future<Currency> getCurrency() async {
    final prefs = await SharedPreferences.getInstance();
    String name = prefs.getString('currency') ?? Currency.usd.name;
    return Currency.findByName(name);
  }
}