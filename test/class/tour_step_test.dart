import 'package:easy_wallet/class/tour_step.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TourStep.all', () {
    test('visits every tab of the app', () {
      // Five tabs in MainView, five stations. A tab nobody explains is a tab
      // the tour quietly pretends does not exist.
      expect(TourStep.all.map((step) => step.tabIndex), [0, 1, 2, 3, 4]);
    });

    test('walks the tabs in the order the tab bar shows them', () {
      final indices = TourStep.all.map((step) => step.tabIndex).toList();
      final ascending = [...indices]..sort();

      expect(indices, ascending);
    });

    test('never sends the user to the same tab twice', () {
      final indices = TourStep.all.map((step) => step.tabIndex).toList();

      expect(indices.toSet().length, indices.length);
    });

    test('carries a title and a body for every station', () {
      for (final step in TourStep.all) {
        expect(step.titleKey, isNotEmpty);
        expect(step.bodyKey, isNotEmpty);
        expect(step.titleKey, isNot(step.bodyKey));
      }
    });

    test('gives every station its own texts', () {
      final keys = [
        ...TourStep.all.map((step) => step.titleKey),
        ...TourStep.all.map((step) => step.bodyKey),
      ];

      expect(keys.toSet().length, keys.length);
    });

    test('resolves its texts through the translations', () {
      // Without a loaded locale Intl hands the key back, which is exactly what
      // makes the untranslated case visible instead of blank.
      final step = TourStep.all.first;

      expect(step.title(), step.titleKey);
      expect(step.body(), step.bodyKey);
    });
  });
}
