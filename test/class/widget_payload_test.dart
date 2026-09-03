import 'package:easy_wallet/class/upcoming_payments.dart';
import 'package:easy_wallet/class/widget_payload.dart';
import 'package:easy_wallet/model/subscription.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

Subscription sub({int id = 1, String title = 'Netflix', double amount = 9.99}) =>
    Subscription(
      id: id,
      amount: amount,
      date: DateTime(2026, 9, 7),
      isPaused: false,
      isPinned: false,
      repeating: true,
      repeatPattern: 'monthly',
      title: title,
    );

UpcomingPayment payment({int id = 1, String title = 'Netflix', int days = 4}) =>
    UpcomingPayment(
      subscription: sub(id: id, title: title),
      date: DateTime(2026, 9, 7),
      daysUntil: days,
    );

void main() {
  group('WidgetPayload.upcoming', () {
    test('describes one row per billing, in order', () {
      final json = WidgetPayload.upcoming(
        payments: [
          payment(id: 1, title: 'Netflix', days: 4),
          payment(id: 2, title: 'Spotify', days: 8),
        ],
        iconPaths: const {},
        colors: const {},
        currencySymbol: '€',
        showAmount: false,
      );

      final items = json['items'] as List;
      expect(items.map((e) => e['title']), ['Netflix', 'Spotify']);
      expect(items.map((e) => e['days']), [4, 8]);
    });

    test('leaves the amount out when the setting is off', () {
      final json = WidgetPayload.upcoming(
        payments: [payment()],
        iconPaths: const {},
        colors: const {},
        currencySymbol: '€',
        showAmount: false,
      );

      expect((json['items'] as List).single['amount'], '');
    });

    test('formats the amount when the setting is on', () {
      final json = WidgetPayload.upcoming(
        payments: [payment()],
        iconPaths: const {},
        colors: const {},
        currencySymbol: '€',
        showAmount: true,
      );

      expect((json['items'] as List).single['amount'], contains('9.99'));
    });

    test('passes the icon file through for the subscriptions that have one',
        () {
      final json = WidgetPayload.upcoming(
        payments: [payment(id: 1), payment(id: 2, title: 'Spotify')],
        iconPaths: const {1: '/tmp/netflix.png'},
        colors: const {},
        currencySymbol: '€',
        showAmount: false,
      );

      final items = json['items'] as List;
      expect(items[0]['icon'], '/tmp/netflix.png');
      expect(items[1]['icon'], '');
    });

    test('hands the category colour over as a hex string', () {
      final json = WidgetPayload.upcoming(
        payments: [payment(id: 1)],
        iconPaths: const {},
        colors: const {1: Color(0xFFFF3B30)},
        currencySymbol: '€',
        showAmount: false,
      );

      expect((json['items'] as List).single['color'], '#FF3B30');
    });

    test('says so when nothing is due', () {
      final json = WidgetPayload.upcoming(
        payments: const [],
        iconPaths: const {},
        colors: const {},
        currencySymbol: '€',
        showAmount: false,
      );

      expect(json['items'], isEmpty);
    });
  });

  group('WidgetPayload.calendar', () {
    // September 2026 starts on a Tuesday and has 30 days.
    final month = DateTime(2026, 9, 1);

    test('counts the days of the month', () {
      final json = WidgetPayload.calendar(
        month: month,
        today: DateTime(2026, 9, 4),
        markers: const {},
        title: 'September 2026',
        total: '123,45 €',
      );

      expect(json['dayCount'], 30);
      expect(json['title'], 'September 2026');
      expect(json['total'], '123,45 €');
    });

    test('leaves the columns before the first day empty, Monday first', () {
      final json = WidgetPayload.calendar(
        month: month,
        today: DateTime(2026, 9, 4),
        markers: const {},
        title: '',
        total: '',
      );

      // Tuesday is the second column.
      expect(json['leadingBlanks'], 1);
    });

    test('marks a day with the colours billed on it', () {
      final json = WidgetPayload.calendar(
        month: month,
        today: DateTime(2026, 9, 4),
        markers: {
          DateTime(2026, 9, 7): [const Color(0xFFFF3B30)],
          DateTime(2026, 9, 11): [
            const Color(0xFF30D158),
            const Color(0xFF007AFF),
          ],
        },
        title: '',
        total: '',
      );

      expect(json['marks'], {
        '7': ['#FF3B30'],
        '11': ['#30D158', '#007AFF'],
      });
    });

    test('points out today when it falls in the shown month', () {
      final json = WidgetPayload.calendar(
        month: month,
        today: DateTime(2026, 9, 4),
        markers: const {},
        title: '',
        total: '',
      );

      expect(json['today'], 4);
    });

    test('points at no day when today is in another month', () {
      final json = WidgetPayload.calendar(
        month: month,
        today: DateTime(2026, 10, 4),
        markers: const {},
        title: '',
        total: '',
      );

      expect(json['today'], 0);
    });
  });
}
