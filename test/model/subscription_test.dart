import 'package:easy_wallet/model/subscription.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:http/http.dart' as http;

class MockClient extends Mock implements http.Client {}

void main() {
  group('Subscription Tests', () {
    test('fromJson factory correctly populates fields', () {
      var json = {
        'id': 1,
        'amount': 99.99,
        'date': '2020-01-01T00:00:00Z',
        'isPaused': 1,
        'isPinned': 1,
        'notes': 'Monthly subscription',
        'rememberCycle': 'same_day',
        'repeating': 1,
        'repeatPattern': 'monthly',
        'timestamp': '2020-01-01T00:00:00Z',
        'title': 'Netflix',
        'url': 'http://netflix.com'
      };

      var subscription = Subscription.fromJson(json);
      expect(subscription.id, equals(1));
      expect(subscription.amount, equals(99.99));
      expect(subscription.date, DateTime.parse('2020-01-01T00:00:00Z'));
      expect(subscription.isPaused, isTrue);
      expect(subscription.isPinned, isTrue);
      expect(subscription.notes, 'Monthly subscription');
      expect(subscription.rememberCycle, 'same_day');
      expect(subscription.repeating, isTrue);
      expect(subscription.repeatPattern, 'monthly');
      expect(subscription.timestamp, DateTime.parse('2020-01-01T00:00:00Z'));
      expect(subscription.title, 'Netflix');
      expect(subscription.url, 'http://netflix.com');
    });

    test('toJson serializes data correctly', () {
      var subscription = Subscription(
          id: 1,
          amount: 99.99,
          date: DateTime.parse('2020-01-01T00:00:00Z'),
          isPaused: true,
          isPinned: true,
          notes: 'Monthly subscription',
          rememberCycle: 'same_day',
          repeating: true,
          repeatPattern: 'monthly',
          timestamp: DateTime.parse('2020-01-01T00:00:00Z'),
          title: 'Netflix',
          url: 'http://netflix.com'
      );

      var json = subscription.toJson();
      expect(json['id'], equals(1));
      expect(json['amount'], equals(99.99));
      expect(json['date'], '2020-01-01T00:00:00.000Z');
      expect(json['isPaused'], equals(1));
      expect(json['isPinned'], equals(1));
      expect(json['notes'], 'Monthly subscription');
      expect(json['rememberCycle'], 'same_day');
      expect(json['repeating'], equals(1));
      expect(json['repeatPattern'], 'monthly');
      expect(json['timestamp'], '2020-01-01T00:00:00.000Z');
      expect(json['title'], 'Netflix');
      expect(json['url'], 'http://netflix.com');
    });
  });
}
