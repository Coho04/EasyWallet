import 'package:easy_wallet/generated/l10n.dart';
import 'package:easy_wallet/enum/currency.dart';
import 'package:easy_wallet/model/subscription.dart';
import 'package:easy_wallet/views/components/budget_warning_banner.dart';
import 'package:easy_wallet/views/components/subscription_header.dart';
import 'package:easy_wallet/views/components/subscription_list_component.dart';
import 'package:easy_wallet/views/components/upcoming_strip.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

/// Every string the user sees has to follow the app language. These
/// components were written with German literals baked in.
Widget inLocale(Locale locale, Widget child) => CupertinoApp(
      locale: locale,
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: S.delegate.supportedLocales,
      home: CupertinoPageScaffold(child: SafeArea(child: child)),
    );

Subscription netflix() => Subscription(
      id: 1,
      amount: 17.99,
      date: DateTime(2026, 9, 7),
      isPaused: false,
      isPinned: false,
      repeating: true,
      repeatPattern: 'monthly',
      title: 'Netflix',
    );

void main() {
  group('English locale', () {
    testWidgets('the header labels the two spend cards in English',
        (WidgetTester tester) async {
      await tester.pumpWidget(inLocale(
        const Locale('en'),
        SubscriptionHeader(
          monthlySpent: 123.45,
          yearlySpent: 1571.30,
          currencySymbol: '€',
          onSortTap: () {},
          onAddTap: () {},
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('THIS MONTH'), findsOneWidget);
      expect(find.text('THIS YEAR'), findsOneWidget);
    });

    testWidgets('the upcoming strip has an English headline',
        (WidgetTester tester) async {
      await tester.pumpWidget(inLocale(
        const Locale('en'),
        UpcomingStrip(
          upcomingSubscriptions: [netflix()],
          currencySymbol: '€',
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('NEXT 7 DAYS'), findsOneWidget);
      // The day badge must not keep the German "T" abbreviation.
      expect(find.textContaining(' T'), findsNothing);
    });

    testWidgets('the budget banner warns in English',
        (WidgetTester tester) async {
      await tester.pumpWidget(inLocale(
        const Locale('en'),
        const BudgetWarningBanner(
          spent: 150,
          limit: 100,
          currencySymbol: '€',
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Monthly budget exceeded'), findsOneWidget);
    });

    testWidgets('a list row spells out the cycle in English',
        (WidgetTester tester) async {
      await tester.pumpWidget(inLocale(
        const Locale('en'),
        SubscriptionListComponent(
          subscription: netflix(),
          currency: Currency.eur,
          displayCategories: false,
          onTogglePin: () {},
          onTogglePause: () {},
          onDelete: () {},
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.textContaining('Monthly'), findsOneWidget);
    });
  });

  group('German locale', () {
    testWidgets('the header keeps its German labels',
        (WidgetTester tester) async {
      await tester.pumpWidget(inLocale(
        const Locale('de'),
        SubscriptionHeader(
          monthlySpent: 123.45,
          yearlySpent: 1571.30,
          currencySymbol: '€',
          onSortTap: () {},
          onAddTap: () {},
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('DIESEN MONAT'), findsOneWidget);
      expect(find.text('DIESES JAHR'), findsOneWidget);
    });
  });
}
