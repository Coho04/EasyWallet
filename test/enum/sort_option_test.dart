
import 'package:easy_wallet/enum/sort_option.dart';
import 'package:easy_wallet/generated/intl/messages_all.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

void main() {
  group('SortOption Tests', () {
    setUp(() {
      Intl.defaultLocale = 'en_US';
      initializeMessages('en_US');
    });

    test('translate returns correct localized value', () {
      expect(SortOption.alphabeticalAscending.translate(), equals("Alphabetical Ascending"));
      expect(SortOption.alphabeticalDescending.translate(), equals("Alphabetical Descending"));
      expect(SortOption.costAscending.translate(), equals("Cost Ascending"));
      expect(SortOption.costDescending.translate(), equals("Cost Descending"));
      expect(SortOption.remainingDaysAscending.translate(), equals("Days Remaining Ascending"));
      expect(SortOption.remainingDaysDescending.translate(), equals("Days Remaining Descending"));
    });

    test('enum values are correct', () {
      expect(SortOption.alphabeticalAscending.value, equals('alphabetical_ascending'));
      expect(SortOption.alphabeticalDescending.value, equals('alphabetical_descending'));
      expect(SortOption.costAscending.value, equals('cost_ascending'));
      expect(SortOption.costDescending.value, equals('cost_descending'));
      expect(SortOption.remainingDaysAscending.value, equals('remaining_days_ascending'));
      expect(SortOption.remainingDaysDescending.value, equals('remaining_days_descending'));
    });
  });
}
