import 'package:easy_wallet/model/subscription_icon.dart';
import 'package:easy_wallet/views/components/icon_picker_sheet.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Icons;
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SubscriptionIconPicker', () {
    // Without loaded translations Intl.message returns the key, which is what
    // these tests look for.
    Future<List<SubscriptionIcon?>> pumpPicker(
      WidgetTester tester, {
      SubscriptionIcon? icon,
    }) async {
      final changes = <SubscriptionIcon?>[];
      await tester.pumpWidget(
        CupertinoApp(
          home: CupertinoPageScaffold(
            child: Center(
              child: SubscriptionIconPicker(
                icon: icon,
                url: '',
                onChanged: changes.add,
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byType(SubscriptionIconPicker));
      await tester.pumpAndSettle();
      return changes;
    }

    testWidgets('picks a symbol', (tester) async {
      final changes = await pumpPicker(tester);

      await tester.tap(find.text('iconSymbol'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.tv_rounded));
      await tester.pumpAndSettle();

      expect(changes.single!.kind, IconKind.symbol);
      expect(changes.single!.value, 'tv');
    });

    testWidgets('picks an emoji from the grid', (tester) async {
      final changes = await pumpPicker(tester);

      await tester.tap(find.text('iconEmoji'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('🎮'));
      await tester.pumpAndSettle();

      expect(changes.single, SubscriptionIcon.emoji('🎮'));
    });

    testWidgets('keeps only one character in the emoji field', (tester) async {
      final changes = await pumpPicker(tester);

      await tester.tap(find.text('iconEmoji'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(CupertinoTextField), '🇩🇪🎬');
      await tester.pump();
      await tester.tap(find.text('done'));
      await tester.pumpAndSettle();

      expect(changes.single, SubscriptionIcon.emoji('🎬'));
    });

    testWidgets('offers the way back to the website icon only when needed', (
      tester,
    ) async {
      await pumpPicker(tester);
      expect(find.text('iconFromWebsite'), findsNothing);
      await tester.tap(find.text('cancel'));
      await tester.pumpAndSettle();

      final changes = await pumpPicker(
        tester,
        icon: SubscriptionIcon.emoji('🎬'),
      );
      await tester.tap(find.text('iconFromWebsite'));
      await tester.pumpAndSettle();

      expect(changes, [null]);
    });

    testWidgets('cancelling changes nothing', (tester) async {
      final changes = await pumpPicker(tester);

      await tester.tap(find.text('cancel'));
      await tester.pumpAndSettle();

      expect(changes, isEmpty);
    });
  });
}
