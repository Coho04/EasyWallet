import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_wallet/class/billing_schedule.dart';
import 'package:easy_wallet/class/money.dart';
import 'package:easy_wallet/class/upcoming_payments.dart';
import 'package:easy_wallet/class/widget_payload.dart';
import 'package:easy_wallet/enum/currency.dart';
import 'package:easy_wallet/model/category.dart' as model;
import 'package:easy_wallet/model/subscription.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Publishes what the home screen widgets show.
///
/// Both widgets used to be rendered here as one picture each. A picture is
/// frozen: it keeps the light background when the phone switches to dark mode,
/// and it never looks like the platform it sits on. So this only describes the
/// rows as JSON now and the native side draws them with its own colours and
/// fonts. Only the subscription icons stay pictures, because downloading them
/// natively would mean network access from a widget extension.
class HomeWidgetBridge {
  const HomeWidgetBridge._();

  /// Shared container between the app and the iOS widget extension. Must match
  /// the App Group configured for both targets.
  static const String appGroupId = 'group.de.golden-developer.EasyWallet';

  static const String upcomingWidgetAndroid = 'NextPaymentWidgetProvider';
  static const String upcomingWidgetIOS = 'NextPaymentWidget';
  static const String calendarWidgetAndroid = 'CalendarWidgetProvider';
  static const String calendarWidgetIOS = 'CalendarWidget';

  /// What the last refresh did, readable in the settings. A widget that stays
  /// empty on a device is otherwise impossible to tell apart from an app that
  /// never wrote anything.
  static const String statusKey = 'widgetStatus';

  static const String keyUpcoming = 'upcomingData';
  static const String keyCalendar = 'calendarData';

  /// One rendered favicon per subscription, addressed by id.
  static String iconKey(int id) => 'icon_$id';

  /// How many billings the list shows.
  static const int rowCount = 10;

  /// Recomputes both widgets and asks the system to redraw them. Failures are
  /// swallowed: a widget that cannot update must never take the app down.
  static Future<void> refresh() async {
    if (kIsWeb) return;

    SharedPreferences? prefs;
    try {
      prefs = await SharedPreferences.getInstance();
      final groupSet = await HomeWidget.setAppGroupId(appGroupId);

      final currency = Currency.findByName(
          prefs.getString('currency') ?? Currency.usd.name);
      final showAmount = prefs.getBool('includeCostInNotifications') ?? false;

      final subscriptions = await Subscription.all();
      final now = DateTime.now();

      final categories = await model.Category.forAllSubscriptions();
      Color? colorOf(int? id) =>
          id == null ? null : categories[id]?.firstOrNull?.color;

      await _publishUpcoming(
          subscriptions, now, currency, showAmount, colorOf);
      await _publishCalendar(subscriptions, now, currency, colorOf);

      await HomeWidget.updateWidget(
        androidName: upcomingWidgetAndroid,
        iOSName: upcomingWidgetIOS,
      );
      await HomeWidget.updateWidget(
        androidName: calendarWidgetAndroid,
        iOSName: calendarWidgetIOS,
      );

      // Read back what was written. If this comes back empty the app and the
      // widget are not sharing a container, which is what a missing App Group
      // looks like from in here.
      final stored = await HomeWidget.getWidgetData<String>(keyUpcoming);
      final shared = stored != null && stored.isNotEmpty;

      await prefs.setString(
        statusKey,
        shared
            ? 'ok · ${DateFormat('dd.MM. HH:mm').format(DateTime.now())}'
            : 'written, but not readable from the App Group '
                '(setAppGroupId: $groupSet)',
      );
    } catch (e) {
      debugPrint('Could not refresh the home screen widgets: $e');
      await prefs?.setString(statusKey, 'failed: $e');
    }
  }

  static Future<void> _publishUpcoming(
    List<Subscription> subscriptions,
    DateTime now,
    Currency currency,
    bool showAmount,
    Color? Function(int?) colorOf,
  ) async {
    final payments =
        UpcomingPayments.next(subscriptions, now: now, count: rowCount);
    final iconPaths = await _renderIcons(payments.map((p) => p.subscription));

    await HomeWidget.saveWidgetData(
      keyUpcoming,
      jsonEncode(WidgetPayload.upcoming(
        payments: payments,
        iconPaths: iconPaths,
        colors: {
          for (final payment in payments)
            if (payment.subscription.id != null)
              payment.subscription.id!: colorOf(payment.subscription.id),
        },
        currencySymbol: currency.symbol,
        showAmount: showAmount,
      )),
    );
  }

  static Future<void> _publishCalendar(
    List<Subscription> subscriptions,
    DateTime now,
    Currency currency,
    Color? Function(int?) colorOf,
  ) async {
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 0);
    final byDay = BillingSchedule.byDay(subscriptions, monthStart, monthEnd);

    await HomeWidget.saveWidgetData(
      keyCalendar,
      jsonEncode(WidgetPayload.calendar(
        month: monthStart,
        today: now,
        markers: {
          for (final entry in byDay.entries)
            entry.key: [
              for (final occurrence in entry.value)
                colorOf(occurrence.subscription.id),
            ],
        },
        title: DateFormat.yMMMM().format(monthStart),
        total: Money.format(BillingSchedule.total(byDay), currency.symbol),
      )),
    );
  }

  /// Renders one favicon per subscription into the shared container and
  /// returns where each landed.
  ///
  /// The icon has to be in the image cache first: rendering happens in one
  /// pass and does not wait for a download. A widget extension has no business
  /// fetching these itself, so they are handed over as files.
  static Future<Map<int, String>> _renderIcons(
      Iterable<Subscription> subscriptions) async {
    final paths = <int, String>{};

    for (final subscription in subscriptions) {
      final id = subscription.id;
      if (id == null || paths.containsKey(id)) continue;
      final url = subscription.url;
      if (url == null || url.isEmpty) continue;

      final provider = CachedNetworkImageProvider(subscription.getFaviconUrl());
      try {
        await _awaitImage(provider).timeout(const Duration(seconds: 5));
        final path = await HomeWidget.renderFlutterWidget(
          Image(image: provider, fit: BoxFit.contain),
          key: iconKey(id),
          logicalSize: const Size(64, 64),
          pixelRatio: 3,
        );
        if (path.isNotEmpty) paths[id] = path;
      } catch (_) {
        // No icon is better than no widget.
      }
    }

    return paths;
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
