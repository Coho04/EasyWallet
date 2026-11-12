import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_wallet/model/subscription.dart';
import 'package:easy_wallet/model/subscription_icon.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Icons;
import 'package:flutter_test/flutter_test.dart';

Subscription sub({
  String? url = 'https://netflix.com',
  SubscriptionIcon? icon,
}) {
  return Subscription(
    id: 1,
    amount: 9.99,
    isPaused: false,
    isPinned: false,
    repeating: true,
    repeatPattern: 'monthly',
    title: 'Netflix',
    url: url,
    icon: icon,
  );
}

void main() {
  group('SubscriptionIcon', () {
    test('survives a round trip through toJson and fromJson', () {
      for (final icon in [
        SubscriptionIcon.symbol('car', const Color(0xFFFF9500)),
        SubscriptionIcon.emoji('👨‍👩‍👧'),
        SubscriptionIcon.image(Uint8List.fromList([1, 2, 3, 4, 5])),
      ]) {
        final restored = Subscription.fromJson(sub(icon: icon).toJson());

        expect(restored.icon, icon, reason: icon.type);
      }
    });

    test('a record without icon fields has no icon', () {
      final restored = Subscription.fromJson({
        'amount': 9.99,
        'title': 'Netflix',
        'url': 'https://netflix.com',
        'repeatPattern': 'monthly',
      });

      expect(restored.icon, isNull);
      expect(restored.chosenIcon, isNull);
    });

    test('empty icon fields count as no icon', () {
      expect(
        SubscriptionIcon.fromJson({'iconType': '', 'iconValue': 'tv'}),
        isNull,
      );
      expect(
        SubscriptionIcon.fromJson({'iconType': 'symbol', 'iconValue': ''}),
        isNull,
      );
    });

    test('reads a colour stored as text', () {
      final icon = SubscriptionIcon.fromJson({
        'iconType': 'symbol',
        'iconValue': 'tv',
        'iconColor': '4294901760',
      });

      expect(icon!.color, 0xFFFF0000);
    });

    test('symbols are stored by key, not by code point', () {
      final icon = SubscriptionIcon.symbol('tv', const Color(0xFF007AFF));

      expect(icon.value, 'tv');
      expect(icon.symbol, Icons.tv_rounded);
    });

    test('an unknown symbol key is kept but not drawn', () {
      // A newer build may ship symbols this one does not know. The key has
      // to survive a save here, and until then the favicon stands in.
      final icon = SubscriptionIcon(
        type: 'symbol',
        value: 'not-a-symbol',
        color: 0xFFFF0000,
      );
      final subscription = sub(icon: icon);

      expect(icon.isRenderable, isFalse);
      expect(subscription.chosenIcon, isNull);
      expect(subscription.toJson()['iconValue'], 'not-a-symbol');
      expect(subscription.accentKey, subscription.getFaviconUrl());
    });

    test('an unknown icon type is kept but not drawn', () {
      final subscription = Subscription.fromJson({
        'amount': 1.0,
        'title': 'X',
        'repeatPattern': 'monthly',
        'iconType': 'hologram',
        'iconValue': 'abc',
      });

      expect(subscription.icon!.isRenderable, isFalse);
      expect(subscription.toJson()['iconType'], 'hologram');
    });

    test('a damaged picture is not drawn', () {
      final icon = SubscriptionIcon(type: 'image', value: '%%%not base64');

      expect(icon.imageBytes, isNull);
      expect(icon.isRenderable, isFalse);
    });

    test('a chosen icon takes over the accent colour key', () {
      final icon = SubscriptionIcon.symbol('tv', const Color(0xFF34C759));
      final subscription = sub(icon: icon);

      expect(subscription.chosenIcon, icon);
      expect(subscription.accentKey, icon.cacheKey);
      expect(subscription.accentKey, isNot(subscription.getFaviconUrl()));
    });

    test('a symbol is drawn in the colour picked with it', () async {
      final subscription = sub(
        icon: SubscriptionIcon.symbol('tv', const Color(0xFF34C759)),
      );

      expect((await subscription.accentColor()).toARGB32(), 0xFF34C759);
    });

    test('an emoji takes the neutral colour it is given', () async {
      final subscription = sub(icon: SubscriptionIcon.emoji('🎬'));

      expect(
        await subscription.accentColor(fallback: CupertinoColors.activeBlue),
        CupertinoColors.activeBlue,
      );
    });

    test('tells PNG from JPEG for the widget file', () {
      final png = SubscriptionIcon.image(
        Uint8List.fromList([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A]),
      );
      final jpeg = SubscriptionIcon.image(
        Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10]),
      );

      expect(png.imageExtension, 'png');
      expect(jpeg.imageExtension, 'jpg');
    });

    test('every symbol key is unique and has a glyph', () {
      expect(iconSymbols.length, greaterThanOrEqualTo(40));
      expect(iconSymbols.values.toSet().length, iconSymbols.length);
    });

    test('builds the favicon address from the host', () {
      expect(
        faviconUrlFor('https://www.netflix.com/browse'),
        'https://www.google.com/s2/favicons?sz=64&domain_url=www.netflix.com',
      );
    });
  });

  group('SubscriptionIconView', () {
    Widget wrap(Widget child) => CupertinoApp(
      home: CupertinoPageScaffold(child: Center(child: child)),
    );

    testWidgets('a chosen icon beats the favicon of the URL', (tester) async {
      await tester.pumpWidget(
        wrap(
          sub(
            icon: SubscriptionIcon.symbol('car', const Color(0xFFFF9500)),
          ).buildImage(),
        ),
      );

      expect(find.byType(CachedNetworkImage), findsNothing);
      expect(find.byIcon(Icons.directions_car_rounded), findsOneWidget);
    });

    testWidgets('without a chosen icon the favicon is shown as before', (
      tester,
    ) async {
      await tester.pumpWidget(wrap(sub().buildImage()));

      final image = tester.widget<CachedNetworkImage>(
        find.byType(CachedNetworkImage),
      );
      expect(
        image.imageUrl,
        'https://www.google.com/s2/favicons?sz=64&domain_url=netflix.com',
      );
    });

    testWidgets('an unknown symbol falls back to the favicon', (tester) async {
      await tester.pumpWidget(
        wrap(
          sub(
            icon: SubscriptionIcon(
              type: 'symbol',
              value: 'gone',
              color: 0xFF000000,
            ),
          ).buildImage(),
        ),
      );

      expect(find.byType(CachedNetworkImage), findsOneWidget);
    });

    testWidgets('keeps the old glyphs for a missing or empty URL', (
      tester,
    ) async {
      await tester.pumpWidget(wrap(sub(url: null).buildImage()));
      expect(
        find.byIcon(CupertinoIcons.exclamationmark_triangle),
        findsOneWidget,
      );

      await tester.pumpWidget(wrap(sub(url: '').buildImage()));
      expect(find.byIcon(Icons.account_balance_wallet_rounded), findsOneWidget);
    });

    testWidgets('draws an emoji', (tester) async {
      await tester.pumpWidget(
        wrap(sub(icon: SubscriptionIcon.emoji('🎬')).buildImage()),
      );

      expect(find.text('🎬'), findsOneWidget);
    });
  });
}
