enum Currency {
  USD("US Dollar", "\$"),
  EUR("Euro", "€"),
  GBP("British Pound", "£"),
  JPY("Japanese Yen", "¥"),
  CHF("Swiss Franc", "CHF"),
  AUD("Australian Dollar", "A\$"),
  CAD("Canadian Dollar", "C\$"),
  CNY("Chinese Yuan", "¥"),
  SEK("Swedish Krona", "kr"),
  NZD("New Zealand Dollar", "NZ\$"),
  MXN("Mexican Peso", "\$"),
  SGD("Singapore Dollar", "S\$"),
  HKD("Hong Kong Dollar", "HK\$"),
  NOK("Norwegian Krone", "kr"),
  KRW("South Korean Won", "₩"),
  TRY("Turkish Lira", "₺"),
  RUB("Russian Ruble", "₽"),
  INR("Indian Rupee", "₹"),
  BRL("Brazilian Real", "R\$"),
  ZAR("South African Rand", "R"),
  DKK("Danish Krone", "kr"),
  PLN("Polish Zloty", "zł"),
  THB("Thai Baht", "฿"),
  MYR("Malaysian Ringgit", "RM"),
  IDR("Indonesian Rupiah", "Rp"),
  CZK("Czech Koruna", "Kč"),
  HUF("Hungarian Forint", "Ft"),
  PHP("Philippine Peso", "₱"),
  AED("United Arab Emirates Dirham", "د.إ"),
  SAR("Saudi Riyal", "ر.س"),
  ILS("Israeli New Shekel", "₪"),
  BGN("Bulgarian Lev", "лв"),
  RON("Romanian Leu", "lei"),
  CLP("Chilean Peso", "\$"),
  VND("Vietnamese Dong", "₫"),
  PKR("Pakistani Rupee", "₨"),
  BDT("Bangladeshi Taka", "৳"),
  NGN("Nigerian Naira", "₦"),
  UAH("Ukrainian Hryvnia", "₴"),
  KZT("Kazakhstani Tenge", "₸"),
  QAR("Qatari Riyal", "ر.ق"),
  EGP("Egyptian Pound", "£");

  final String name;
  final String symbol;

  const Currency(this.name, this.symbol);

  static List<String> all() {
    return Currency.values.map((e) => e.name).toList();
  }

  static Currency findByName(String name) {
    return Currency.values.firstWhere((e) => e.name == name);
  }

  @override
  String toString() => name;
}
