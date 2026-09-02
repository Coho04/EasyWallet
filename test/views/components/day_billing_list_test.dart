import 'package:easy_wallet/class/billing_schedule.dart';
import 'package:easy_wallet/model/subscription.dart';
import 'package:easy_wallet/views/components/day_billing_list.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

Subscription sub(String title, {double amount = 9.99, bool isPaused = false}) {
  return Subscription(
    amount: amount,
    date: DateTime(2026, 9, 11),
    isPaused: isPaused,
    isPinned: false,
    repeating: true,
    repeatPattern: 'monthly',
    title: title,
  );
}

BillingOccurrence occurrence(Subscription subscription) => BillingOccurrence(
      subscription: subscription,
      date: DateTime(2026, 9, 11),
    );

void main() {
  group('DayBillingList Widget Tests', () {
    // The app is Cupertino-only: no Material ancestor may be required.
    Widget wrap(Widget child) => CupertinoApp(
          home: CupertinoPageScaffold(child: child),
        );

    testWidgets('lists every billing of the day with its amount',
        (WidgetTester tester) async {
      await tester.pumpWidget(wrap(
        DayBillingList(
          occurrences: [
            occurrence(sub('Netflix', amount: 17.99)),
            occurrence(sub('Spotify', amount: 10.99)),
          ],
          currencySymbol: '€',
          emptyLabel: 'Keine Abbuchungen',
          onSubscriptionSelected: (_) {},
        ),
      ));

      expect(tester.takeException(), isNull);
      expect(find.text('Netflix'), findsOneWidget);
      expect(find.text('17.99 €'), findsOneWidget);
      expect(find.text('Spotify'), findsOneWidget);
      expect(find.text('10.99 €'), findsOneWidget);
    });

    testWidgets('shows the empty label when nothing is billed',
        (WidgetTester tester) async {
      await tester.pumpWidget(wrap(
        DayBillingList(
          occurrences: const [],
          currencySymbol: '€',
          emptyLabel: 'Keine Abbuchungen',
          onSubscriptionSelected: (_) {},
        ),
      ));

      expect(find.text('Keine Abbuchungen'), findsOneWidget);
    });

    testWidgets('marks paused subscriptions', (WidgetTester tester) async {
      await tester.pumpWidget(wrap(
        DayBillingList(
          occurrences: [
            occurrence(sub('Netflix')),
            occurrence(sub('Gym', isPaused: true)),
          ],
          currencySymbol: '€',
          emptyLabel: 'Keine Abbuchungen',
          onSubscriptionSelected: (_) {},
        ),
      ));

      expect(find.byKey(const ValueKey('paused-1')), findsOneWidget);
      expect(find.byKey(const ValueKey('paused-0')), findsNothing);
    });

    testWidgets('reports the tapped subscription', (WidgetTester tester) async {
      Subscription? tapped;

      await tester.pumpWidget(wrap(
        DayBillingList(
          occurrences: [
            occurrence(sub('Netflix')),
            occurrence(sub('Spotify')),
          ],
          currencySymbol: '€',
          emptyLabel: 'Keine Abbuchungen',
          onSubscriptionSelected: (subscription) => tapped = subscription,
        ),
      ));

      await tester.tap(find.byKey(const ValueKey('occurrence-1')));

      expect(tapped?.title, 'Spotify');
    });
  });
}
