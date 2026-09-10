import 'package:easy_wallet/generated/l10n.dart';
import 'package:easy_wallet/views/components/tour_overlay.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget hosting(Widget overlay, {Locale locale = const Locale('en')}) {
    return CupertinoApp(
      locale: locale,
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: S.delegate.supportedLocales,
      home: CupertinoPageScaffold(
        child: Stack(
          children: [
            const Center(child: Text('the app underneath')),
            overlay,
          ],
        ),
      ),
    );
  }

  TourOverlay overlay({
    int stepNumber = 1,
    int stepCount = 5,
    VoidCallback? onNext,
    VoidCallback? onSkip,
  }) =>
      TourOverlay(
        title: 'Your subscriptions',
        body: 'Every subscription lands here.',
        stepNumber: stepNumber,
        stepCount: stepCount,
        onNext: onNext ?? () {},
        onSkip: onSkip ?? () {},
      );

  testWidgets('shows what the step says', (tester) async {
    await tester.pumpWidget(hosting(overlay()));

    expect(find.text('Your subscriptions'), findsOneWidget);
    expect(find.text('Every subscription lands here.'), findsOneWidget);
  });

  testWidgets('says where in the tour the user is', (tester) async {
    await tester.pumpWidget(hosting(overlay(stepNumber: 2, stepCount: 5)));

    expect(find.text(S.current.tourProgress(2, 5)), findsOneWidget);
  });

  testWidgets('leaves the app visible behind it', (tester) async {
    // The whole point of a guided tour over slides: the user looks at the
    // real screen while it is explained.
    await tester.pumpWidget(hosting(overlay()));

    expect(find.text('the app underneath'), findsOneWidget);
  });

  testWidgets('offers the next step while there are more', (tester) async {
    await tester.pumpWidget(hosting(overlay(stepNumber: 1, stepCount: 5)));

    expect(find.text(S.current.tourNext), findsOneWidget);
    expect(find.text(S.current.tourDone), findsNothing);
  });

  testWidgets('offers to finish on the last step', (tester) async {
    await tester.pumpWidget(hosting(overlay(stepNumber: 5, stepCount: 5)));

    expect(find.text(S.current.tourDone), findsOneWidget);
    expect(find.text(S.current.tourNext), findsNothing);
  });

  testWidgets('lets the user out on any step, including the last',
      (tester) async {
    await tester.pumpWidget(hosting(overlay(stepNumber: 5, stepCount: 5)));

    expect(find.text(S.current.tourSkip), findsOneWidget);
  });

  testWidgets('reports the next step', (tester) async {
    var advanced = 0;
    await tester.pumpWidget(hosting(overlay(onNext: () => advanced++)));

    await tester.tap(find.text(S.current.tourNext));
    await tester.pump();

    expect(advanced, 1);
  });

  testWidgets('reports being skipped', (tester) async {
    var skipped = 0;
    await tester.pumpWidget(hosting(overlay(onSkip: () => skipped++)));

    await tester.tap(find.text(S.current.tourSkip));
    await tester.pump();

    expect(skipped, 1);
  });

  testWidgets('draws one dot per station', (tester) async {
    await tester.pumpWidget(hosting(overlay(stepNumber: 2, stepCount: 4)));

    final dots = tester.widgetList<Container>(find.byType(Container)).where(
        (container) =>
            (container.decoration as BoxDecoration?)?.shape == BoxShape.circle);

    expect(dots, hasLength(4));
  });

  testWidgets('keeps the app underneath from being tapped', (tester) async {
    var tappedThrough = false;
    await tester.pumpWidget(
      CupertinoApp(
        locale: const Locale('en'),
        localizationsDelegates: const [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: S.delegate.supportedLocales,
        home: CupertinoPageScaffold(
          child: Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => tappedThrough = true,
                ),
              ),
              overlay(),
            ],
          ),
        ),
      ),
    );

    // Anywhere well clear of the card at the bottom.
    await tester.tapAt(const Offset(200, 100));
    await tester.pump();

    expect(tappedThrough, isFalse);
  });

  testWidgets('follows the app language', (tester) async {
    await tester.pumpWidget(hosting(overlay(), locale: const Locale('de')));
    await tester.pump();

    expect(find.text('Überspringen'), findsOneWidget);
    expect(find.text('Weiter'), findsOneWidget);
  });
}
