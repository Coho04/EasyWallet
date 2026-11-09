import 'package:easy_wallet/class/translatable_enum.dart';
import 'package:flutter/material.dart';

enum PaymentMethode with TranslatableEnum {
  creditCard(value: 'creditCard', color: Colors.yellowAccent),
  paypal(value: 'paypal', color: Colors.blue),
  sepa(value: 'sepa', color: Colors.cyan),
  applePay(value: 'apple_pay', color: Colors.grey),
  googlePay(value: 'google_pay', color: Colors.greenAccent),
  appStore(value: 'app_store', color: Colors.blueGrey),
  googlePlay(value: 'google_play', color: Colors.green),
  klarna(value: 'klarna', color: Colors.pinkAccent),
  amazonPay(value: 'amazon_pay', color: Colors.amber),
  bankTransfer(value: 'bank_transfer', color: Colors.indigo),
  cash(value: 'cash', color: Colors.brown),
  invoice(value: 'invoice', color: Colors.orange);

  const PaymentMethode({
    required this.value,
    required this.color,
  });

  /// Falls back to [invoice] for a value this version does not know — e.g.
  /// from a backup made by a newer version — instead of throwing.
  static PaymentMethode findByName(String name) {
    return PaymentMethode.values.firstWhere(
      (e) => e.value == name,
      orElse: () => PaymentMethode.invoice,
    );
  }

  static List<String> all() {
    return PaymentMethode.values.map((e) => e.value).toList();
  }

  @override
  final String value;
  final Color color;
}
