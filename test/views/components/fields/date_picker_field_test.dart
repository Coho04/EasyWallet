import 'package:easy_wallet/views/components/auto_text.dart';
import 'package:easy_wallet/views/components/form_fields/date_picker_field.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EasyWalletDatePickerField Widget Tests', () {
    testWidgets('renders correctly with light mode', (WidgetTester tester) async {
      await tester.pumpWidget(
        CupertinoApp(
          home: Material(
            child: EasyWalletDatePickerField(
              label: 'Date',
              date: DateTime(2022, 1, 1),
              onTap: () {},
              isDarkMode: false,
            ),
          ),
        ),
      );

      expect(find.text('Date'), findsOneWidget);
      expect(find.text('01.01.2022'), findsOneWidget);
      expect(find.byIcon(CupertinoIcons.calendar), findsOneWidget);
    });

    testWidgets('renders correctly with dark mode', (WidgetTester tester) async {
      await tester.pumpWidget(
        CupertinoApp(
          theme: const CupertinoThemeData(brightness: Brightness.dark),
          home: Material(
            child: EasyWalletDatePickerField(
              label: 'Date',
              date: DateTime(2022, 1, 1),
              onTap: () {},
              isDarkMode: true,
            ),
          ),
        ),
      );

      final autoTextFinder = find.byType(AutoText);
      final iconFinder = find.byIcon(CupertinoIcons.calendar);

      expect(find.text('Date'), findsOneWidget);
      expect(find.text('01.01.2022'), findsOneWidget);
      expect(iconFinder, findsOneWidget);

      final AutoText labelText = tester.widget<AutoText>(autoTextFinder.first);
      expect(labelText.color, CupertinoColors.white);

      final Container container = tester.widget<Container>(find.byType(Container));
      final BoxDecoration decoration = container.decoration as BoxDecoration;
      expect(decoration.color, CupertinoColors.darkBackgroundGray);
    });

    testWidgets('onTap callback is called when tapped', (WidgetTester tester) async {
      var tapped = false;

      await tester.pumpWidget(
        CupertinoApp(
          home: Material(
            child: EasyWalletDatePickerField(
              label: 'Date',
              date: DateTime(2022, 1, 1),
              onTap: () {
                tapped = true;
              },
              isDarkMode: false,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(GestureDetector));
      expect(tapped, isTrue);
    });

    testWidgets('displays the correct date format', (WidgetTester tester) async {
      final testDate = DateTime(2023, 12, 25);

      await tester.pumpWidget(
        CupertinoApp(
          home: Material(
            child: EasyWalletDatePickerField(
              label: 'Select Date',
              date: testDate,
              onTap: () {},
              isDarkMode: false,
            ),
          ),
        ),
      );

      expect(find.text('25.12.2023'), findsOneWidget);
    });
  });
}
