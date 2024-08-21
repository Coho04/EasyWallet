import 'package:easy_wallet/views/components/form_fields/text_field.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EasyWalletTextField Widget Tests', () {
    late TextEditingController controller;

    setUp(() {
      controller = TextEditingController();
    });

    testWidgets('renders correctly in light mode', (WidgetTester tester) async {
      await tester.pumpWidget(
        CupertinoApp(
          home: Material(
            child: EasyWalletTextField(
              controller: controller,
              placeholder: 'Enter text',
              isDarkMode: false,
            ),
          ),
        ),
      );

      final textFieldFinder = find.byType(CupertinoTextField);

      expect(textFieldFinder, findsOneWidget);
      expect(find.text('Enter text'), findsOneWidget);

      final CupertinoTextField textField = tester.widget(textFieldFinder);
      expect(textField.decoration?.color, CupertinoColors.systemGrey6);
    });

    testWidgets('renders correctly in dark mode with valid input', (WidgetTester tester) async {
      await tester.pumpWidget(
        CupertinoApp(
          theme: const CupertinoThemeData(brightness: Brightness.dark),
          home: Material(
            child: EasyWalletTextField(
              controller: controller,
              placeholder: 'Enter text',
              isDarkMode: true,
            ),
          ),
        ),
      );

      final textFieldFinder = find.byType(CupertinoTextField);

      expect(textFieldFinder, findsOneWidget);
      expect(find.text('Enter text'), findsOneWidget);

      final CupertinoTextField textField = tester.widget(textFieldFinder);
      final BoxDecoration decoration = textField.decoration as BoxDecoration;

      expect(decoration.color, CupertinoColors.darkBackgroundGray);

      final border = decoration.border as Border;
      expect(border.top.color, CupertinoColors.systemGrey);
    });


    testWidgets('renders correctly with validation error', (WidgetTester tester) async {
      await tester.pumpWidget(
        CupertinoApp(
          home: Material(
            child: EasyWalletTextField(
              controller: controller,
              placeholder: 'Enter text',
              isDarkMode: false,
              isValid: false,
            ),
          ),
        ),
      );

      final textFieldFinder = find.byType(CupertinoTextField);

      expect(textFieldFinder, findsOneWidget);

      final CupertinoTextField textField = tester.widget(textFieldFinder);
      final BoxDecoration decoration = textField.decoration as BoxDecoration;

      final border = decoration.border as Border;
      expect(border.top.color, CupertinoColors.systemRed);
      expect(decoration.color, CupertinoColors.systemRed.withOpacity(0.1));
    });

    testWidgets('calls onChanged when text changes', (WidgetTester tester) async {
      String changedText = '';
      await tester.pumpWidget(
        CupertinoApp(
          home: Material(
            child: EasyWalletTextField(
              controller: controller,
              placeholder: 'Enter text',
              isDarkMode: false,
              onChanged: (value) {
                changedText = value;
              },
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(CupertinoTextField), 'Hello');
      expect(changedText, 'Hello');
    });

    testWidgets('renders multiline correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        CupertinoApp(
          home: Material(
            child: EasyWalletTextField(
              controller: controller,
              placeholder: 'Enter text',
              isDarkMode: false,
              maxLines: 3,
            ),
          ),
        ),
      );

      final textFieldFinder = find.byType(CupertinoTextField);

      expect(textFieldFinder, findsOneWidget);

      final CupertinoTextField textField = tester.widget(textFieldFinder);
      expect(textField.maxLines, 3);
    });
  });
}
