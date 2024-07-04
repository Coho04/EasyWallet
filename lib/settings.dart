import 'package:easy_wallet/enum/currency.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Settings {

  static Future<Currency> getCurrency() async {
    final prefs = await SharedPreferences.getInstance();
    String name = prefs.getString('currency') ?? Currency.USD.name;
    return Currency.findByName(name);
  }
}