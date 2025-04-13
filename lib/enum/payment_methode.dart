import 'package:easy_wallet/class/translatable_enum.dart';
import 'package:flutter/material.dart';

enum PaymentMethode with TranslatableEnum {
  creditCard(value: 'creditCard', color: Colors.yellowAccent),
  paypal(value: 'paypal', color: Colors.blue),
  sepa(value: 'sepa', color: Colors.cyan),
  applePay(value: 'apple_pay', color: Colors.grey),
  googlePay(value: 'google_pay', color: Colors.greenAccent),
  invoice(value: 'invoice', color: Colors.orange);

  const PaymentMethode({
    required this.value,
    required this.color,
  });

  static PaymentMethode findByName(String name) {
    return PaymentMethode.values.firstWhere(
          (e) => e.value == name,
    );
  }

  static List<String> all() {
    return PaymentMethode.values.map((e) => e.value).toList();
  }

  @override
  final String value;
  final Color color;
}
