import 'package:easy_wallet/class/translatable_enum.dart';
import 'package:intl/intl.dart';

enum PaymentMethode with TranslatableEnum {
  creditCard(value: 'creditCard'),
  paypal(value: 'paypal'),
  sepa(value: 'sepa'),
  applePay(value: 'apple_pay'),
  googlePay(value: 'google_pay'),
  invoice(value: 'invoice');

  const PaymentMethode({
    required this.value,
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
}
