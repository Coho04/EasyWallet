enum Currency {
  usd("US Dollar", "\$"),
  eur("Euro", "€"),
  gbp("British Pound", "£"),
  jpy("Japanese Yen", "¥"),
  chf("Swiss Franc", "CHF"),
  aud("Australian Dollar", "A\$"),
  cad("Canadian Dollar", "C\$"),
  cny("Chinese Yuan", "¥"),
  sek("Swedish Krona", "kr"),
  nzd("New Zealand Dollar", "NZ\$"),
  mxn("Mexican Peso", "\$"),
  sgd("Singapore Dollar", "S\$"),
  hkd("Hong Kong Dollar", "HK\$"),
  nok("Norwegian Krone", "kr"),
  krw("South Korean Won", "₩"),
  tRy("Turkish Lira", "₺"),
  rub("Russian Ruble", "₽"),
  int("Indian Rupee", "₹"),
  brl("Brazilian Real", "R\$"),
  zar("South African Rand", "R"),
  dkk("Danish Krone", "kr"),
  pln("Polish Zloty", "zł"),
  thb("Thai Baht", "฿"),
  myr("Malaysian Ringgit", "RM"),
  idr("Indonesian Rupiah", "Rp"),
  czk("Czech Koruna", "Kč"),
  huf("Hungarian Forint", "Ft"),
  php("Philippine Peso", "₱"),
  aed("United Arab Emirates Dirham", "د.إ"),
  sar("Saudi Riyal", "ر.س"),
  ils("Israeli New Shekel", "₪"),
  bgn("Bulgarian Lev", "лв"),
  ron("Romanian Leu", "lei"),
  clp("Chilean Peso", "\$"),
  vnd("Vietnamese Dong", "₫"),
  pkr("Pakistani Rupee", "₨"),
  bdt("Bangladeshi Taka", "৳"),
  ngn("Nigerian Naira", "₦"),
  uah("Ukrainian Hryvnia", "₴"),
  kzt("Kazakhstani Tenge", "₸"),
  qar("Qatari Riyal", "ر.ق"),
  egp("Egyptian Pound", "£");

  final String name;
  final String symbol;

  const Currency(this.name, this.symbol);

  static List<String> all() {
    return Currency.values.map((e) => e.name).toList();
  }

  static Currency findByName(String name) {
    return Currency.values.firstWhere((e) => e.name == name, orElse: () => Currency.eur);
  }

  @override
  String toString() => name;
}
