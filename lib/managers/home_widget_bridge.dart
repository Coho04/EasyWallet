import 'dart:async';
import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_wallet/class/billing_schedule.dart';
import 'package:easy_wallet/class/money.dart';
import 'package:easy_wallet/class/upcoming_payments.dart';
import 'package:easy_wallet/enum/currency.dart';
import 'package:easy_wallet/model/category.dart' as model;
import 'package:easy_wallet/model/subscription.dart';
import 'package:easy_wallet/views/home_widget/calendar_widget_view.dart';
import 'package:easy_wallet/views/home_widget/upcoming_payments_widget_view.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Publishes what the home screen widgets show.
///
/// Both widgets are rendered here as images. That keeps the native side to a
/// single image view on each platform, lets the calendar reuse MonthGrid, and
/// puts the favicons on the widget without downloading them natively. The cost
/// is that the picture only follows a light/dark switch at the next refresh.
class HomeWidgetBridge {
  const HomeWidgetBridge._();

  /// Shared container between the app and the iOS widget extension. Must match
  /// the App Group configured for both targets.
  static const String appGroupId = 'group.de.golden-developer.EasyWallet';

  static const String upcomingWidgetAndroid = 'NextPaymentWidgetProvider';
  static const String upcomingWidgetIOS = 'NextPaymentWidget';
  static const String calendarWidgetAndroid = 'CalendarWidgetProvider';
  static const String calendarWidgetIOS = 'CalendarWidget';

  static const String keyUpcomingImage = 'upcomingImage';
  static const String keyCalendarImage = 'calendarImage';

  /// How many billings the list shows.
  static const int rowCount = 10;

  /// Recomputes both widgets and asks the system to redraw them. Failures are
  /// swallowed: a widget that cannot update must never take the app down.
  static Future<void> refresh() async {
    if (kIsWeb) return;

    try {
      await HomeWidget.setAppGroupId(appGroupId);

      final prefs = await SharedPreferences.getInstance();
      final currency = Currency.findByName(
          prefs.getString('currency') ?? Currency.usd.name);
      final showAmount = prefs.getBool('includeCostInNotifications') ?? false;

      final subscriptions = await Subscription.all();
      final now = DateTime.now();

      await _renderUpcoming(subscriptions, now, currency, showAmount);
      await _renderCalendar(subscriptions, now, currency);

      await HomeWidget.updateWidget(
        androidName: upcomingWidgetAndroid,
        iOSName: upcomingWidgetIOS,
      );
      await HomeWidget.updateWidget(
        androidName: calendarWidgetAndroid,
        iOSName: calendarWidgetIOS,
      );
    } catch (e) {
      debugPrint('Could not refresh the home screen widgets: $e');
    }
  }

  static Future<void> _renderUpcoming(
    List<Subscription> subscriptions,
    DateTime now,
    Currency currency,
    bool showAmount,
  ) async {
    final payments =
        UpcomingPayments.next(subscriptions, now: now, count: rowCount);
    final icons = await _loadIcons(payments.map((p) => p.subscription));

    await HomeWidget.renderFlutterWidget(
      UpcomingPaymentsWidgetView(
        payments: payments,
        icons: icons,
        currencySymbol: currency.symbol,
        showAmount: showAmount,
        emptyLabel: 'Nothing due',
        headline: 'Upcoming',
      ),
      key: keyUpcomingImage,
      logicalSize: const Size(340, 340),
      appGroupId: appGroupId,
    );
  }

  static Future<void> _renderCalendar(
    List<Subscription> subscriptions,
    DateTime now,
    Currency currency,
  ) async {
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 0);
    final byDay = BillingSchedule.byDay(subscriptions, monthStart, monthEnd);

    final categories = await model.Category.forAllSubscriptions();
    final markers = {
      for (final entry in byDay.entries)
        entry.key: [
          for (final occurrence in entry.value)
            _dot(categories[occurrence.subscription.id]?.firstOrNull?.color),
        ],
    };

    await HomeWidget.renderFlutterWidget(
      CalendarWidgetView(
        month: monthStart,
        markers: markers,
        headline: DateFormat.yMMMM().format(monthStart),
        total: Money.format(
            BillingSchedule.total(byDay), currency.symbol),
      ),
      key: keyCalendarImage,
      logicalSize: const Size(340, 320),
      appGroupId: appGroupId,
    );
  }

  static Widget _dot(Color? color) => Container(
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: color ?? CupertinoColors.activeBlue,
          shape: BoxShape.circle,
        ),
      );

  /// Favicons have to be in the image cache before the widget is rendered:
  /// rendering happens in one pass and does not wait for a download.
  static Future<Map<int, ImageProvider>> _loadIcons(
      Iterable<Subscription> subscriptions) async {
    final icons = <int, ImageProvider>{};

    for (final subscription in subscriptions) {
      final id = subscription.id;
      if (id == null || icons.containsKey(id)) continue;
      final url = subscription.url;
      if (url == null || url.isEmpty) continue;

      final provider = CachedNetworkImageProvider(subscription.getFaviconUrl());
      try {
        await _awaitImage(provider).timeout(const Duration(seconds: 5));
        icons[id] = provider;
      } catch (_) {
        // No icon is better than no widget.
      }
    }

    return icons;
  }

  static Future<ui.Image> _awaitImage(ImageProvider provider) {
    final completer = Completer<ui.Image>();
    final stream = provider.resolve(ImageConfiguration.empty);
    late final ImageStreamListener listener;
    listener = ImageStreamListener(
      (info, _) {
        stream.removeListener(listener);
        if (!completer.isCompleted) completer.complete(info.image);
      },
      onError: (error, stack) {
        stream.removeListener(listener);
        if (!completer.isCompleted) completer.completeError(error);
      },
    );
    stream.addListener(listener);
    return completer.future;
  }
}
