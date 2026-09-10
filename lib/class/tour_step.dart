import 'package:intl/intl.dart';

/// One station of the guided tour: the tab it shows and what it says about it.
///
/// The texts are held as translation keys rather than strings so a step stays
/// plain data — the tour can be reasoned about and tested without a widget
/// tree or a loaded locale.
class TourStep {
  const TourStep({
    required this.tabIndex,
    required this.titleKey,
    required this.bodyKey,
  });

  /// The tab this step talks about, as indexed by the tab bar in MainView.
  final int tabIndex;

  final String titleKey;
  final String bodyKey;

  String title() => Intl.message(titleKey);

  String body() => Intl.message(bodyKey);

  /// The tour, in the order the tabs are arranged. Walking the app in the
  /// order the tab bar already suggests means the user ends the tour with a
  /// map that matches what they see.
  static const List<TourStep> all = [
    TourStep(
      tabIndex: 0,
      titleKey: 'tourSubscriptionsTitle',
      bodyKey: 'tourSubscriptionsBody',
    ),
    TourStep(
      tabIndex: 1,
      titleKey: 'tourCategoriesTitle',
      bodyKey: 'tourCategoriesBody',
    ),
    TourStep(
      tabIndex: 2,
      titleKey: 'tourCalendarTitle',
      bodyKey: 'tourCalendarBody',
    ),
    TourStep(
      tabIndex: 3,
      titleKey: 'tourStatisticsTitle',
      bodyKey: 'tourStatisticsBody',
    ),
    TourStep(
      tabIndex: 4,
      titleKey: 'tourSettingsTitle',
      bodyKey: 'tourSettingsBody',
    ),
  ];
}
