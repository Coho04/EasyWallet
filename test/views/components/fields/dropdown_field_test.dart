import 'package:easy_wallet/enum/payment_rate.dart';
import 'package:easy_wallet/enum/remember_cycle.dart';
import 'package:easy_wallet/views/components/auto_text.dart';
import 'package:easy_wallet/views/components/form_fields/dropdown_field.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EasyWalletDropdownField Widget Tests', () {
    late ValueChanged<String?> onChanged;

    setUp(() {
      onChanged = (String? newValue) {
      };
    });

    testWidgets('renders correctly with light mode', (WidgetTester tester) async {
      await tester.pumpWidget(
        CupertinoApp(
          home: Material(
            child: EasyWalletDropdownField(
              label: 'Payment Rate',
              currentValue: PaymentRate.monthly.value,
              options: PaymentRate.values,
              onChanged: onChanged,
              isDarkMode: false,
            ),
          ),
        ),
      );

      expect(find.text('Payment Rate'), findsOneWidget);
      expect(find.text('Monthly'), findsOneWidget);
      expect(find.byIcon(CupertinoIcons.chevron_down), findsOneWidget);
    });

    testWidgets('renders correctly with dark mode', (WidgetTester tester) async {
      await tester.pumpWidget(
        CupertinoApp(
          theme: const CupertinoThemeData(brightness: Brightness.dark),
          home: Material(
            child: EasyWalletDropdownField(
              label: 'Payment Rate',
              currentValue: PaymentRate.yearly.value,
              options: PaymentRate.values,
              onChanged: onChanged,
              isDarkMode: true,
            ),
          ),
        ),
      );

      expect(find.text('Payment Rate'), findsOneWidget);
      expect(find.text('Yearly'), findsOneWidget);

      final AutoText labelText = tester.widget<AutoText>(find.byType(AutoText).first);
      expect(labelText.color, CupertinoColors.white);

      final Container container = tester.widget<Container>(find.byType(Container));
      final BoxDecoration decoration = container.decoration as BoxDecoration;
      expect(decoration.color, CupertinoColors.darkBackgroundGray);
    });

    testWidgets('onChanged callback is called with correct value when option is selected', (WidgetTester tester) async {
      String selectedValue = PaymentRate.monthly.value;

      await tester.pumpWidget(
        CupertinoApp(
          home: Material(
            child: EasyWalletDropdownField(
              label: 'Payment Rate',
              currentValue: PaymentRate.monthly.value,
              options: PaymentRate.values,
              onChanged: (value) {
                selectedValue = value!;
              },
              isDarkMode: false,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(GestureDetector));
      await tester.pumpAndSettle();

      final yearlyOptionFinder = find.descendant(
        of: find.byType(CupertinoActionSheet),
        matching: find.text('Yearly'),
      );
      expect(yearlyOptionFinder, findsOneWidget);

      await tester.tap(yearlyOptionFinder);
      await tester.pumpAndSettle();
      expect(selectedValue, PaymentRate.yearly.value);
    });

    testWidgets('displays the correct translated and capitalized value', (WidgetTester tester) async {
      await tester.pumpWidget(
        CupertinoApp(
          home: Material(
            child: EasyWalletDropdownField(
              label: 'Remember Cycle',
              currentValue: RememberCycle.sameDay.value,
              options: RememberCycle.values,
              onChanged: onChanged,
              isDarkMode: false,
            ),
          ),
        ),
      );
      expect(find.text('SameDay'), findsOneWidget);
    });

  });
}
