import 'package:easy_wallet/enum/remember_cycle.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

void main() {
  group('RememberCycle Tests', () {
    setUp(() {
      Intl.defaultLocale = 'en_US';
    });

    test('translate returns correct value', () {
      expect(RememberCycle.sameDay.translate(), equals("sameDay"));
      expect(RememberCycle.dayBefore.translate(), equals("dayBefore"));
    });

    test('migrate returns correct RememberCycle or defaults', () {
      expect(RememberCycle.migrate("SameDay"), equals(RememberCycle.sameDay));
      expect(RememberCycle.migrate("OneCenturyBefore"), equals(RememberCycle.dayBefore));
    });

    test('findByName finds correct RememberCycle or defaults', () {
      expect(RememberCycle.findByName("same_day"), equals(RememberCycle.sameDay));
      expect(RememberCycle.findByName("unknown_day"), equals(RememberCycle.dayBefore));
    });

    test('all returns list of all remember cycle values', () {
      List<String> expectedValues = ["same_day", "day_before", "two_days_before", "week_before"];
      expect(RememberCycle.all(), equals(expectedValues));
    });
  });
}
