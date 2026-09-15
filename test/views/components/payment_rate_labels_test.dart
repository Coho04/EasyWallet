import 'package:easy_wallet/enum/payment_rate.dart';
import 'package:easy_wallet/generated/l10n.dart';
import 'package:easy_wallet/views/components/form_fields/dropdown_field.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

/// A billing interval nobody can read is a billing interval nobody picks.
/// `translate()` falls back to the raw key when a translation is missing, so
/// an unlabelled interval shows up as "fourMonthly" instead of failing — these
/// tests are what turns that silence into a red test.
void main() {
  Widget hosting(Widget child, Locale locale) => CupertinoApp(
        locale: locale,
        localizationsDelegates: const [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: S.delegate.supportedLocales,
        home: CupertinoPageScaffold(child: child),
      );

  group('every interval is translated', () {
    for (final locale in const [Locale('de'), Locale('en')]) {
      testWidgets('in ${locale.languageCode}', (tester) async {
        await tester.pumpWidget(hosting(const SizedBox(), locale));
        await tester.pump();

        for (final rate in PaymentRate.values) {
          expect(
            rate.translate(),
            isNot(rate.value),
            reason: '${rate.value} has no ${locale.languageCode} translation',
          );
        }
      });

      testWidgets('abbreviation in ${locale.languageCode}', (tester) async {
        await tester.pumpWidget(hosting(const SizedBox(), locale));
        await tester.pump();

        for (final rate in PaymentRate.values) {
          final short = Intl.message(rate.shortLabelKey);
          expect(
            short,
            isNot(rate.shortLabelKey),
            reason: '${rate.value} has no ${locale.languageCode} abbreviation',
          );
          expect(short.length, lessThanOrEqualTo(3), reason: rate.value);
        }
      });
    }
  });

  testWidgets('German names the new intervals', (tester) async {
    await tester.pumpWidget(hosting(const SizedBox(), const Locale('de')));
    await tester.pump();

    expect(PaymentRate.monthly.translate(), 'Monatlich');
    expect(PaymentRate.quarterly.translate(), 'Vierteljährlich');
    expect(PaymentRate.fourMonthly.translate(), 'Alle 4 Monate');
    expect(PaymentRate.halfYearly.translate(), 'Halbjährlich');
    expect(PaymentRate.yearly.translate(), 'Jährlich');
  });

  testWidgets('the picker offers every interval', (tester) async {
    // What the user actually sees when creating a subscription.
    await tester.pumpWidget(hosting(
      EasyWalletDropdownField(
        label: 'Zahlungsintervall',
        currentValue: PaymentRate.monthly.value,
        options: PaymentRate.values,
        onChanged: (_) {},
        isDarkMode: false,
      ),
      const Locale('de'),
    ));
    await tester.pump();

    await tester.tap(find.byIcon(CupertinoIcons.chevron_down));
    await tester.pumpAndSettle();

    for (final rate in PaymentRate.values) {
      expect(find.text(rate.translate()), findsWidgets, reason: rate.value);
    }
  });
}
