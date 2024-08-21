import 'package:easy_wallet/views/components/form_fields/amount_field.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:easy_wallet/enum/currency.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

void main() {
  group('AmountField Widget Tests', () {
    late TextEditingController controller;

    setUp(() {
      controller = TextEditingController();
    });

    testWidgets('renders correctly in light mode', (WidgetTester tester) async {
      await tester.pumpWidget(
        CupertinoApp(
          home: Material(
            child: AmountField(
              currency: Currency.usd,
              isDarkMode: false,
              isValid: true,
              controller: controller,
            ),
          ),
        ),
      );

      expect(find.byType(CupertinoTextField), findsOneWidget);
      expect(find.text('\$'), findsOneWidget);
    });

    testWidgets('renders correctly in dark mode', (WidgetTester tester) async {
      await tester.pumpWidget(
        CupertinoApp(
          theme: const CupertinoThemeData(brightness: Brightness.dark),
          home: Material(
            child: AmountField(
              currency: Currency.eur,
              isDarkMode: true,
              isValid: true,
              controller: controller,
            ),
          ),
        ),
      );

      expect(find.byType(CupertinoTextField), findsOneWidget);
      expect(find.text('€'), findsOneWidget);
    });

    testWidgets('shows validation error when isValid is false', (WidgetTester tester) async {
      await tester.pumpWidget(
        CupertinoApp(
          home: Material(
            child: AmountField(
              currency: Currency.usd,
              isDarkMode: false,
              isValid: false,
              controller: controller,
            ),
          ),
        ),
      );

      final textFieldFinder = find.byType(CupertinoTextField);
      final textFieldWidget = tester.widget<CupertinoTextField>(textFieldFinder);
      final decoration = textFieldWidget.decoration as BoxDecoration;

      final border = decoration.border as Border;
      expect(border.top.color, CupertinoColors.destructiveRed);
    });

    testWidgets('displays the correct currency symbol', (WidgetTester tester) async {
      await tester.pumpWidget(
        CupertinoApp(
          home: Material(
            child: AmountField(
              currency: Currency.gbp,
              isDarkMode: false,
              isValid: true,
              controller: controller,
            ),
          ),
        ),
      );

      expect(find.text('£'), findsOneWidget);
    });

    testWidgets('displays correct style based on dark mode', (WidgetTester tester) async {
      await tester.pumpWidget(
        CupertinoApp(
          home: Material(
            child: AmountField(
              currency: Currency.jpy,
              isDarkMode: true,
              isValid: true,
              controller: controller,
            ),
          ),
        ),
      );

      final textFieldFinder = find.byType(CupertinoTextField);
      final textFieldWidget = tester.widget<CupertinoTextField>(textFieldFinder);

      expect(textFieldWidget.style?.color, CupertinoColors.white);
    });
  });
}
