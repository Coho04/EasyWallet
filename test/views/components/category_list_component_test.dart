import 'package:easy_wallet/model/category.dart';
import 'package:easy_wallet/views/components/category_list_component.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CategoryListComponent', () {
    final category = Category(
      id: 1,
      title: 'Streaming',
      color: CupertinoColors.systemRed,
    );

    // The app is Cupertino only: no Material ancestor may be required.
    Widget wrap(Widget child) => CupertinoApp(
          home: CupertinoPageScaffold(child: Column(children: [child])),
        );

    testWidgets('shows the name and how much the category costs',
        (WidgetTester tester) async {
      await tester.pumpWidget(wrap(
        CategoryListComponent(
          category: category,
          subscriptionCount: 3,
          subtitle: '3 Abonnements',
          monthlyTotal: '17,99 €',
          onTap: () {},
        ),
      ));

      expect(tester.takeException(), isNull);
      expect(find.text('Streaming'), findsOneWidget);
      expect(find.text('3 Abonnements'), findsOneWidget);
      expect(find.text('17,99 €'), findsOneWidget);
    });

    testWidgets('the whole row opens the category',
        (WidgetTester tester) async {
      var taps = 0;

      await tester.pumpWidget(wrap(
        CategoryListComponent(
          category: category,
          subscriptionCount: 0,
          subtitle: 'Keine Abonnements',
          monthlyTotal: '0,00 €',
          onTap: () => taps++,
        ),
      ));

      // Tapping the name, not the chevron, has to work.
      await tester.tap(find.text('Streaming'));
      expect(taps, 1);
    });

    testWidgets('points out that it opens something',
        (WidgetTester tester) async {
      await tester.pumpWidget(wrap(
        CategoryListComponent(
          category: category,
          subscriptionCount: 0,
          subtitle: 'Keine Abonnements',
          monthlyTotal: '0,00 €',
          onTap: () {},
        ),
      ));

      expect(find.byIcon(CupertinoIcons.chevron_forward), findsOneWidget);
    });

    testWidgets('keeps one type size regardless of the name length',
        (WidgetTester tester) async {
      await tester.pumpWidget(wrap(
        Column(
          children: [
            CategoryListComponent(
              category: category,
              subscriptionCount: 0,
              subtitle: 'Keine Abonnements',
              monthlyTotal: '0,00 €',
              onTap: () {},
            ),
            CategoryListComponent(
              category: Category(
                id: 2,
                title: 'Zeitschriften und Abonnements aller Art',
                color: CupertinoColors.systemBlue,
              ),
              subscriptionCount: 0,
              subtitle: 'Keine Abonnements',
              monthlyTotal: '0,00 €',
              onTap: () {},
            ),
          ],
        ),
      ));

      final short = tester.widget<Text>(find.text('Streaming'));
      final long = tester
          .widget<Text>(find.text('Zeitschriften und Abonnements aller Art'));

      expect(short.style?.fontSize, isNotNull);
      expect(long.style?.fontSize, short.style?.fontSize);
    });

    testWidgets('is at least 44 points tall', (WidgetTester tester) async {
      await tester.pumpWidget(wrap(
        CategoryListComponent(
          category: category,
          subscriptionCount: 0,
          subtitle: 'Keine Abonnements',
          monthlyTotal: '0,00 €',
          onTap: () {},
        ),
      ));

      expect(tester.getSize(find.byType(CategoryListComponent)).height,
          greaterThanOrEqualTo(44));
    });
  });
}
