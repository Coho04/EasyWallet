import 'package:easy_wallet/enum/payment_methode.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PaymentMethode', () {
    test('finds every method by the name it is stored under', () {
      // These strings sit in the database of every installed copy of the app.
      for (final method in PaymentMethode.values) {
        expect(PaymentMethode.findByName(method.value), method);
      }
    });

    test('falls back to invoice for an unknown value instead of throwing', () {
      // A backup from a newer version may carry a method this one lacks.
      expect(PaymentMethode.findByName('crypto'), PaymentMethode.invoice);
      expect(PaymentMethode.findByName(''), PaymentMethode.invoice);
    });

    test('stores every method under its own value', () {
      final values = PaymentMethode.all();
      expect(values.toSet().length, values.length);
    });

    test('offers the store and transfer methods', () {
      expect(
        PaymentMethode.all(),
        containsAll(<String>[
          'app_store',
          'google_play',
          'klarna',
          'amazon_pay',
          'bank_transfer',
          'cash',
        ]),
      );
    });
  });
}
