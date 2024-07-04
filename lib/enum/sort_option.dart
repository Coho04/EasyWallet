import 'package:intl/intl.dart';

enum SortOption {
  alphabeticalAscending(
      value: 'alphabetical_ascending', translationKey: 'alphabeticalAscending'),
  alphabeticalDescending(
      value: 'alphabetical_descending', translationKey: 'alphabeticalDescending'
  ),
  costAscending(
    value: 'cost_ascending', translationKey: 'costAscending'
  ),
  costDescending(
    value: 'cost_descending', translationKey: 'costDescending'
  ),
  remainingDaysAscending(
    value: 'remaining_days_ascending', translationKey: 'daysRemainingAscending'
  ),
  remainingDaysDescending(
    value: 'remaining_days_descending', translationKey: 'daysRemainingDescending'
  );

  const SortOption({
    required this.value,
    required this.translationKey,
  });

  String translate() {
    return Intl.message(translationKey);
  }

  final String value;
  final String translationKey;
}