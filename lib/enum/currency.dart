import 'dart:math' as math;

enum Currency {
  usd("US Dollar", "\$", "USD"),
  eur("Euro", "€", "EUR"),
  gbp("British Pound", "£", "GBP"),
  jpy("Japanese Yen", "¥", "JPY", decimalDigits: 0),
  chf("Swiss Franc", "CHF", "CHF"),
  aud("Australian Dollar", "A\$", "AUD"),
  cad("Canadian Dollar", "C\$", "CAD"),
  cny("Chinese Yuan", "¥", "CNY"),
  sek("Swedish Krona", "kr", "SEK"),
  nzd("New Zealand Dollar", "NZ\$", "NZD"),
  mxn("Mexican Peso", "\$", "MXN"),
  sgd("Singapore Dollar", "S\$", "SGD"),
  hkd("Hong Kong Dollar", "HK\$", "HKD"),
  nok("Norwegian Krone", "kr", "NOK"),
  krw("South Korean Won", "₩", "KRW", decimalDigits: 0),
  tRy("Turkish Lira", "₺", "TRY"),
  rub("Russian Ruble", "₽", "RUB"),
  inr("Indian Rupee", "₹", "INR"),
  brl("Brazilian Real", "R\$", "BRL"),
  zar("South African Rand", "R", "ZAR"),
  dkk("Danish Krone", "kr", "DKK"),
  pln("Polish Zloty", "zł", "PLN"),
  thb("Thai Baht", "฿", "THB"),
  myr("Malaysian Ringgit", "RM", "MYR"),
  idr("Indonesian Rupiah", "Rp", "IDR"),
  czk("Czech Koruna", "Kč", "CZK"),
  huf("Hungarian Forint", "Ft", "HUF"),
  php("Philippine Peso", "₱", "PHP"),
  aed("United Arab Emirates Dirham", "د.إ", "AED"),
  sar("Saudi Riyal", "ر.س", "SAR"),
  ils("Israeli New Shekel", "₪", "ILS"),
  bgn("Bulgarian Lev", "лв", "BGN"),
  ron("Romanian Leu", "lei", "RON"),
  clp("Chilean Peso", "\$", "CLP", decimalDigits: 0),
  vnd("Vietnamese Dong", "₫", "VND", decimalDigits: 0),
  pkr("Pakistani Rupee", "₨", "PKR"),
  bdt("Bangladeshi Taka", "৳", "BDT"),
  ngn("Nigerian Naira", "₦", "NGN"),
  uah("Ukrainian Hryvnia", "₴", "UAH"),
  kzt("Kazakhstani Tenge", "₸", "KZT"),
  qar("Qatari Riyal", "ر.ق", "QAR"),
  egp("Egyptian Pound", "£", "EGP");

  final String name;
  final String symbol;

  /// ISO 4217 code. Kept explicit because [tRy] cannot spell its own code:
  /// `try` is a Dart keyword.
  final String code;

  /// Digits after the decimal point per ISO 4217. Almost every currency has
  /// two; yen, won, dong and the Chilean peso have none. Needed to read an
  /// amount given in minor units: 1599 EUR is 15.99, 1490 JPY is 1490.
  final int decimalDigits;

  const Currency(this.name, this.symbol, this.code, {this.decimalDigits = 2});

  /// [minor] minor units as this currency's amount, e.g. 1599 -> 15.99 for EUR.
  double amountFromMinor(int minor) {
    if (decimalDigits == 0) {
      return minor.toDouble();
    }
    return minor / math.pow(10, decimalDigits);
  }

  static List<String> all() {
    return Currency.values.map((e) => e.name).toList();
  }

  static Currency findByName(String name) {
    return Currency.values.firstWhere((e) => e.name == name, orElse: () => Currency.eur);
  }

  /// The currency for an ISO 4217 code, or null when it is unknown. Null
  /// instead of a default: a wrong currency silently distorts an amount, so a
  /// caller has to decide what to do with a code the app does not carry.
  static Currency? findByCode(String code) {
    final wanted = code.trim().toUpperCase();
    for (final currency in Currency.values) {
      if (currency.code == wanted) {
        return currency;
      }
    }
    return null;
  }

  @override
  String toString() => name;
}
