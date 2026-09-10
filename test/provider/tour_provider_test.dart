import 'package:easy_wallet/class/tour_step.dart';
import 'package:easy_wallet/provider/tour_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const steps = [
    TourStep(tabIndex: 0, titleKey: 'aTitle', bodyKey: 'aBody'),
    TourStep(tabIndex: 1, titleKey: 'bTitle', bodyKey: 'bBody'),
    TourStep(tabIndex: 2, titleKey: 'cTitle', bodyKey: 'cBody'),
  ];

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('running the tour', () {
    test('is not running until it is started', () {
      final tour = TourController(steps: steps);

      expect(tour.isRunning, isFalse);
      expect(tour.step, isNull);
    });

    test('starts at the first station', () {
      final tour = TourController(steps: steps)..start();

      expect(tour.isRunning, isTrue);
      expect(tour.step, steps.first);
      expect(tour.stepNumber, 1);
      expect(tour.stepCount, 3);
      expect(tour.isOnLastStep, isFalse);
    });

    test('moves one station at a time', () {
      final tour = TourController(steps: steps)..start();

      tour.next();
      expect(tour.step, steps[1]);
      expect(tour.stepNumber, 2);

      tour.next();
      expect(tour.step, steps[2]);
      expect(tour.isOnLastStep, isTrue);
    });

    test('ends itself after the last station', () {
      final tour = TourController(steps: steps)..start();
      tour.next();
      tour.next();

      tour.next();

      expect(tour.isRunning, isFalse);
      expect(tour.step, isNull);
    });

    test('can be left at any point', () {
      final tour = TourController(steps: steps)..start();
      tour.next();

      tour.finish();

      expect(tour.isRunning, isFalse);
    });

    test('starts over from the beginning when asked again', () {
      final tour = TourController(steps: steps)..start();
      tour.next();
      tour.finish();

      tour.start();

      expect(tour.stepNumber, 1);
      expect(tour.step, steps.first);
    });

    test('ignores being advanced or ended while it is not running', () {
      final tour = TourController(steps: steps);

      tour.next();
      tour.finish();

      expect(tour.isRunning, isFalse);
      expect(tour.stepNumber, 1);
    });

    test('stays put when there is nothing to show', () {
      final tour = TourController(steps: const [])..start();

      expect(tour.isRunning, isFalse);
    });
  });

  group('telling the views', () {
    test('announces every move', () {
      var notifications = 0;
      final tour = TourController(steps: steps)
        ..addListener(() => notifications++);

      tour.start();
      tour.next();
      tour.finish();

      expect(notifications, 3);
    });

    test('stays quiet when nothing changed', () {
      var notifications = 0;
      final tour = TourController(steps: steps)
        ..addListener(() => notifications++);

      tour.next();
      tour.finish();

      expect(notifications, 0);
    });
  });

  group('showing it only once unasked', () {
    test('runs on a first launch', () async {
      final tour = TourController(steps: steps);

      await tour.startIfUnseen();

      expect(tour.isRunning, isTrue);
    });

    test('does not run again on the next launch', () async {
      await TourController(steps: steps).startIfUnseen();

      final second = TourController(steps: steps);
      await second.startIfUnseen();

      expect(second.isRunning, isFalse);
    });

    test('counts as seen the moment it starts, not when it ends', () async {
      // Someone who closes the app half way through has made their point.
      final first = TourController(steps: steps);
      await first.startIfUnseen();
      // No finish() — the app is gone.

      final second = TourController(steps: steps);
      await second.startIfUnseen();

      expect(second.isRunning, isFalse);
    });

    test('can still be asked for by hand once it was seen', () async {
      await TourController(steps: steps).startIfUnseen();

      final again = TourController(steps: steps)..start();

      expect(again.isRunning, isTrue);
    });

    test('does not restart a tour that is already running', () async {
      final tour = TourController(steps: steps)..start();
      tour.next();

      await tour.startIfUnseen();

      expect(tour.stepNumber, 2);
    });

    test('offers itself again once the flag is forgotten', () async {
      await TourController(steps: steps).startIfUnseen();

      await TourController.forgetSeen();

      final tour = TourController(steps: steps);
      await tour.startIfUnseen();
      expect(tour.isRunning, isTrue);
    });

    test('respects a flag that was already set', () async {
      SharedPreferences.setMockInitialValues({TourController.seenKey: true});
      final tour = TourController(steps: steps);

      await tour.startIfUnseen();

      expect(tour.isRunning, isFalse);
    });
  });

  group('the real tour', () {
    test('uses the app tour when no steps are given', () {
      expect(TourController().steps, TourStep.all);
    });
  });
}
