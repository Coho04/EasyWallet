import 'package:easy_wallet/enum/payment_rate.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

void main() {
  group('PaymentRate Tests', () {
    setUp(() {
      Intl.defaultLocale = 'en_US';
    });

    test('translate returns correct value', () {
      expect(PaymentRate.yearly.translate(), equals("yearly"));
      expect(PaymentRate.monthly.translate(), equals("monthly"));
    });

    test('findByName finds correct PaymentRate or defaults', () {
      expect(PaymentRate.findByName("yearly"), equals(PaymentRate.yearly));
      expect(PaymentRate.findByName("daily"), equals(PaymentRate.monthly));
    });

    test('all returns list of all payment rate values', () {
      List<String> expectedValues = ["yearly", "monthly"];
      expect(PaymentRate.all(), equals(expectedValues));
    });
  });
}
