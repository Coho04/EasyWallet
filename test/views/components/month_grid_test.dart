import 'package:easy_wallet/views/components/month_grid.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MonthGrid Widget Tests', () {
    // September 2026 starts on a Tuesday and has 30 days.
    final month = DateTime(2026, 9, 1);

    // The app is Cupertino-only, so the grid must render without a Material
    // ancestor anywhere above it.
    Widget wrap(Widget child) {
      return CupertinoApp(
        home: CupertinoPageScaffold(child: child),
      );
    }

    // Siblings need distinct keys, so repeated elements are keyed by index and
    // matched on their prefix.
    Finder byKeyPrefix(String prefix) => find.byWidgetPredicate(
          (widget) =>
              widget.key is ValueKey<String> &&
              (widget.key as ValueKey<String>).value.startsWith(prefix),
        );

    testWidgets('renders every day of the month with weekday headers',
        (WidgetTester tester) async {
      await tester.pumpWidget(wrap(
        MonthGrid(
          month: month,
          selectedDay: null,
          markers: const {},
          onDaySelected: (_) {},
        ),
      ));

      expect(tester.takeException(), isNull);
      expect(find.byKey(const ValueKey('day-2026-09-01')), findsOneWidget);
      expect(find.byKey(const ValueKey('day-2026-09-30')), findsOneWidget);
      expect(find.byKey(const ValueKey('day-2026-09-31')), findsNothing);
      expect(byKeyPrefix('weekday-header'), findsNWidgets(7));
    });

    testWidgets('pads the first week so the month starts on its weekday',
        (WidgetTester tester) async {
      await tester.pumpWidget(wrap(
        MonthGrid(
          month: month,
          selectedDay: null,
          markers: const {},
          onDaySelected: (_) {},
        ),
      ));

      // Tuesday, so exactly one blank cell in a week starting on Monday.
      expect(byKeyPrefix('blank-cell'), findsNWidgets(1));
    });

    testWidgets('renders the given markers only on days that have billings',
        (WidgetTester tester) async {
      await tester.pumpWidget(wrap(
        MonthGrid(
          month: month,
          selectedDay: null,
          markers: {
            DateTime(2026, 9, 11): const [
              SizedBox(key: ValueKey('marker-0')),
              SizedBox(key: ValueKey('marker-1')),
            ],
          },
          onDaySelected: (_) {},
        ),
      ));

      expect(find.byKey(const ValueKey('markers-2026-09-11')), findsOneWidget);
      expect(find.byKey(const ValueKey('markers-2026-09-12')), findsNothing);
    });

    testWidgets('caps the markers per day and shows the overflow count',
        (WidgetTester tester) async {
      await tester.pumpWidget(wrap(
        MonthGrid(
          month: month,
          selectedDay: null,
          markers: {
            DateTime(2026, 9, 11): const [
              SizedBox(key: ValueKey('marker-0')),
              SizedBox(key: ValueKey('marker-1')),
              SizedBox(key: ValueKey('marker-2')),
              SizedBox(key: ValueKey('marker-3')),
              SizedBox(key: ValueKey('marker-4')),
            ],
          },
          onDaySelected: (_) {},
        ),
      ));

      // Only the first three markers are drawn, the rest is counted.
      expect(byKeyPrefix('marker-'), findsNWidgets(3));
      expect(find.byKey(const ValueKey('marker-0')), findsOneWidget);
      expect(find.byKey(const ValueKey('marker-3')), findsNothing);
      expect(find.text('+2'), findsOneWidget);
    });

    testWidgets('fits its markers into a narrow screen',
        (WidgetTester tester) async {
      // A 320pt wide screen leaves roughly 44pt per cell.
      tester.view.physicalSize = const Size(320 * 3, 800 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(wrap(
        MonthGrid(
          month: month,
          selectedDay: null,
          markers: {
            DateTime(2026, 9, 11): const [
              SizedBox(key: ValueKey('marker-0')),
              SizedBox(key: ValueKey('marker-1')),
              SizedBox(key: ValueKey('marker-2')),
            ],
          },
          onDaySelected: (_) {},
        ),
      ));

      expect(tester.takeException(), isNull);
    });

    testWidgets('reports the tapped day', (WidgetTester tester) async {
      DateTime? tapped;

      await tester.pumpWidget(wrap(
        MonthGrid(
          month: month,
          selectedDay: null,
          markers: const {},
          onDaySelected: (day) => tapped = day,
        ),
      ));

      await tester.tap(find.byKey(const ValueKey('day-2026-09-11')));

      expect(tapped, DateTime(2026, 9, 11));
    });

    testWidgets('highlights the selected day', (WidgetTester tester) async {
      await tester.pumpWidget(wrap(
        MonthGrid(
          month: month,
          selectedDay: DateTime(2026, 9, 11),
          markers: const {},
          onDaySelected: (_) {},
        ),
      ));

      expect(find.byKey(const ValueKey('selected-day')), findsOneWidget);
    });
  });
}
