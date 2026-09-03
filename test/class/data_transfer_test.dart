import 'package:easy_wallet/class/data_transfer.dart';
import 'package:easy_wallet/model/category.dart';
import 'package:easy_wallet/model/subscription.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

Subscription sub({String title = 'Netflix', double amount = 9.99}) {
  return Subscription(
    id: 1,
    amount: amount,
    date: DateTime(2026, 1, 10),
    endDate: DateTime(2027, 1, 10),
    trialEndDate: DateTime(2026, 2, 1),
    splitCount: 2,
    isPaused: false,
    isPinned: true,
    repeating: true,
    repeatPattern: 'monthly',
    rememberCycle: 'day_before',
    title: title,
  );
}

void main() {
  group('DataTransfer', () {
    test('a backup carries the subscriptions and the categories', () {
      final json = DataTransfer.encode(
        subscriptions: [sub()],
        categories: [Category(id: 7, title: 'Streaming')],
      );

      final backup = DataTransfer.decode(json);

      expect(backup.subscriptions.single.title, 'Netflix');
      expect(backup.categories.single.title, 'Streaming');
    });

    test('survives a round trip with every field intact', () {
      final json = DataTransfer.encode(subscriptions: [sub()], categories: []);

      final restored = DataTransfer.decode(json).subscriptions.single;

      expect(restored.amount, 9.99);
      expect(restored.date, DateTime(2026, 1, 10));
      expect(restored.endDate, DateTime(2027, 1, 10));
      expect(restored.trialEndDate, DateTime(2026, 2, 1));
      expect(restored.splitCount, 2);
      expect(restored.isPinned, isTrue);
      expect(restored.repeatPattern, 'monthly');
      expect(restored.rememberCycle, 'day_before');
    });

    test('records which version wrote the backup', () {
      final backup = DataTransfer.decode(
        DataTransfer.encode(subscriptions: [], categories: []),
      );

      expect(backup.version, DataTransfer.formatVersion);
    });

    test('rejects something that is not a backup', () {
      expect(() => DataTransfer.decode('not json at all'),
          throwsA(isA<FormatException>()));
      expect(() => DataTransfer.decode('{"something": 1}'),
          throwsA(isA<FormatException>()));
    });

    test('reads a backup without categories', () {
      final backup = DataTransfer.decode(
        '{"version":1,"subscriptions":[],"categories":[]}',
      );

      expect(backup.subscriptions, isEmpty);
      expect(backup.categories, isEmpty);
    });
  });
}
