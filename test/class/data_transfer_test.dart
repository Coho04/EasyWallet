import 'dart:typed_data';

import 'package:easy_wallet/class/data_transfer.dart';
import 'package:easy_wallet/enum/payment_rate.dart';
import 'package:easy_wallet/model/category.dart';
import 'package:easy_wallet/model/subscription.dart';
import 'package:easy_wallet/model/subscription_icon.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

Subscription sub({
  String title = 'Netflix',
  double amount = 9.99,
  String repeatPattern = 'monthly',
}) {
  return Subscription(
    id: 1,
    amount: amount,
    date: DateTime(2026, 1, 10),
    endDate: DateTime(2027, 1, 10),
    trialEndDate: DateTime(2026, 2, 1),
    splitCount: 2,
    noticePeriodDays: 92,
    isPaused: false,
    isPinned: true,
    repeating: true,
    repeatPattern: repeatPattern,
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
      expect(restored.noticePeriodDays, 92);
      expect(restored.isPinned, isTrue);
      expect(restored.repeatPattern, 'monthly');
      expect(restored.rememberCycle, 'day_before');
    });


    test('carries every billing interval through a backup', () {
      // A backup is the one place a subscription leaves the app and comes
      // back. An interval lost here turns into a monthly subscription on
      // restore, with every total three or twelve times off.
      for (final rate in PaymentRate.values) {
        final json = DataTransfer.encode(
          subscriptions: [sub(repeatPattern: rate.value)],
          categories: [],
        );

        final restored = DataTransfer.decode(json).subscriptions.single;

        expect(restored.repeatPattern, rate.value, reason: rate.value);
        expect(restored.rate, rate, reason: rate.value);
      }
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

    test('carries a chosen icon through a backup', () {
      // Pictures are embedded in the record precisely so that a backup or a
      // synced copy brings them back without any files next to it.
      final picture = Uint8List.fromList(List.generate(300, (i) => i % 256));
      for (final icon in [
        SubscriptionIcon.symbol('tv', const Color(0xFF34C759)),
        SubscriptionIcon.emoji('🎬'),
        SubscriptionIcon.image(picture),
      ]) {
        final json = DataTransfer.encode(
          subscriptions: [sub()..icon = icon],
          categories: [],
        );

        final restored = DataTransfer.decode(json).subscriptions.single;

        expect(restored.icon, icon, reason: icon.type);
      }
      final restoredPicture = DataTransfer.decode(DataTransfer.encode(
        subscriptions: [sub()..icon = SubscriptionIcon.image(picture)],
        categories: [],
      )).subscriptions.single.icon!;
      expect(restoredPicture.imageBytes, picture);
    });

    test('reads a backup written before icons existed', () {
      final backup = DataTransfer.decode(
        '{"version":1,"subscriptions":[{"id":3,"amount":4.99,'
        '"title":"Spotify","url":"https://spotify.com","isPaused":0,'
        '"isPinned":0,"repeating":1,"repeatPattern":"monthly"}],'
        '"categories":[]}',
      );

      final restored = backup.subscriptions.single;
      expect(restored.title, 'Spotify');
      expect(restored.icon, isNull);
      expect(restored.chosenIcon, isNull);
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
