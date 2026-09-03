import 'package:easy_wallet/class/money.dart';
import 'package:easy_wallet/class/upcoming_payments.dart';
import 'package:flutter/cupertino.dart';

/// What the home screen widgets are told to draw.
///
/// The widgets used to show a picture rendered here. A picture cannot follow
/// the system switching to dark mode and never looks like the platform, so the
/// native side lays out the rows itself and this class only describes them.
/// Everything is plain JSON so iOS and Android read the same thing.
class WidgetPayload {
  const WidgetPayload._();

  static Map<String, dynamic> upcoming({
    required List<UpcomingPayment> payments,
    required Map<int, String> iconPaths,
    required Map<int, Color?> colors,
    required String currencySymbol,
    required bool showAmount,
  }) {
    return {
      'items': [
        for (final payment in payments)
          {
            'days': payment.daysUntil,
            'title': payment.title,
            'amount': showAmount
                ? Money.format(payment.amount, currencySymbol)
                : '',
            'icon': iconPaths[payment.subscription.id] ?? '',
            'color': _hex(colors[payment.subscription.id]),
          },
      ],
    };
  }

  static Map<String, dynamic> calendar({
    required DateTime month,
    required DateTime today,
    required Map<DateTime, List<Color?>> markers,
    required String title,
    required String total,
  }) {
    final firstDay = DateTime(month.year, month.month, 1);
    final dayCount = DateTime(month.year, month.month + 1, 0).day;
    final inShownMonth = today.year == month.year && today.month == month.month;

    return {
      'title': title,
      'total': total,
      'dayCount': dayCount,
      // DateTime.weekday counts Monday as 1, which is the column a week
      // starts with here.
      'leadingBlanks': firstDay.weekday - 1,
      'today': inShownMonth ? today.day : 0,
      'marks': {
        for (final entry in markers.entries)
          if (entry.key.year == month.year && entry.key.month == month.month)
            '${entry.key.day}': [
              for (final color in entry.value) _hex(color),
            ],
      },
    };
  }

  /// Without a category the native side falls back to its own accent colour,
  /// which is what an empty string means.
  static String _hex(Color? color) {
    if (color == null) return '';
    final value = color.toARGB32() & 0xFFFFFF;
    return '#${value.toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }
}
