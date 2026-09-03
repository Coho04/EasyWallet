import 'package:easy_wallet/views/components/settings_row.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SettingsRow', () {
    // The app is Cupertino only, so no Material ancestor may be required.
    Widget wrap(Widget child) => CupertinoApp(
          home: CupertinoPageScaffold(child: Column(children: [child])),
        );

    testWidgets('a toggle row shows its label and state',
        (WidgetTester tester) async {
      var changed = false;

      await tester.pumpWidget(wrap(
        SettingsRow.toggle(
          label: 'Benachrichtigungen aktivieren',
          value: true,
          onChanged: (_) => changed = true,
        ),
      ));

      expect(tester.takeException(), isNull);
      expect(find.text('Benachrichtigungen aktivieren'), findsOneWidget);
      expect(tester.widget<CupertinoSwitch>(find.byType(CupertinoSwitch)).value,
          isTrue);

      await tester.tap(find.byType(CupertinoSwitch));
      expect(changed, isTrue);
    });

    testWidgets('a value row is tappable across its whole width',
        (WidgetTester tester) async {
      var taps = 0;

      await tester.pumpWidget(wrap(
        SettingsRow.value(
          label: 'Währung',
          value: 'Euro',
          onTap: () => taps++,
        ),
      ));

      expect(find.text('Währung'), findsOneWidget);
      expect(find.text('Euro'), findsOneWidget);

      // Tapping the label, not the value, must work too.
      await tester.tap(find.text('Währung'));
      expect(taps, 1);
    });

    testWidgets('a value row points out that it opens something',
        (WidgetTester tester) async {
      await tester.pumpWidget(wrap(
        SettingsRow.value(label: 'Währung', value: 'Euro', onTap: () {}),
      ));

      expect(find.byIcon(CupertinoIcons.chevron_forward), findsOneWidget);
    });

    testWidgets('a link row marks itself as leaving the app',
        (WidgetTester tester) async {
      var taps = 0;

      await tester.pumpWidget(wrap(
        SettingsRow.link(label: 'Impressum', onTap: () => taps++),
      ));

      expect(find.byIcon(CupertinoIcons.arrow_up_right_square), findsOneWidget);
      await tester.tap(find.text('Impressum'));
      expect(taps, 1);
    });

    testWidgets('an info row carries no affordance', (WidgetTester tester) async {
      await tester.pumpWidget(wrap(
        SettingsRow.info(label: 'Version', value: '1.1.8 (1)'),
      ));

      expect(find.text('1.1.8 (1)'), findsOneWidget);
      expect(find.byIcon(CupertinoIcons.chevron_forward), findsNothing);
      expect(find.byIcon(CupertinoIcons.arrow_up_right_square), findsNothing);
    });

    testWidgets('labels keep one size instead of shrinking to fit',
        (WidgetTester tester) async {
      await tester.pumpWidget(wrap(
        Column(
          children: [
            SettingsRow.value(label: 'Währung', value: 'Euro', onTap: () {}),
            SettingsRow.value(
              label: 'Kosten in Benachrichtigungen anzeigen',
              value: 'An',
              onTap: () {},
            ),
          ],
        ),
      ));

      final short = tester.widget<Text>(find.text('Währung'));
      final long =
          tester.widget<Text>(find.text('Kosten in Benachrichtigungen anzeigen'));

      expect(short.style?.fontSize, isNotNull);
      expect(long.style?.fontSize, short.style?.fontSize);
    });

    testWidgets('rows are at least 44 points tall',
        (WidgetTester tester) async {
      await tester.pumpWidget(wrap(
        SettingsRow.value(label: 'Währung', value: 'Euro', onTap: () {}),
      ));

      expect(tester.getSize(find.byType(SettingsRow)).height,
          greaterThanOrEqualTo(44));
    });
  });
}
