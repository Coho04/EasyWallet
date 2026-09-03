import 'package:easy_wallet/class/money.dart';
import 'package:easy_wallet/class/next_payment.dart';
import 'package:easy_wallet/enum/currency.dart';
import 'package:easy_wallet/model/subscription.dart';
import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Publishes the next upcoming payment to the home screen widgets.
///
/// The widgets read plain strings, so all formatting happens here: a widget
/// cannot reach the database or the app's locale.
class HomeWidgetBridge {
  const HomeWidgetBridge._();

  /// Shared container between the app and the iOS widget extension. Must match
  /// the App Group configured for both targets.
  static const String appGroupId = 'group.de.golden-developer.EasyWallet';

  static const String androidWidgetName = 'NextPaymentWidgetProvider';
  static const String iOSWidgetName = 'NextPaymentWidget';

  static const String keyTitle = 'nextPaymentTitle';
  static const String keyAmount = 'nextPaymentAmount';
  static const String keyDate = 'nextPaymentDate';
  static const String keyEmpty = 'nextPaymentEmpty';

  /// Recomputes what the widget shows and asks the system to redraw it.
  /// Failures are swallowed: a widget that cannot update must never take the
  /// app down with it.
  static Future<void> refresh() async {
    if (kIsWeb) return;

    try {
      await HomeWidget.setAppGroupId(appGroupId);

      final prefs = await SharedPreferences.getInstance();
      final currency = Currency.findByName(
          prefs.getString('currency') ?? Currency.usd.name);

      final next = NextPayment.of(await Subscription.all(), now: DateTime.now());

      if (next == null) {
        await HomeWidget.saveWidgetData<bool>(keyEmpty, true);
        await HomeWidget.saveWidgetData<String>(keyTitle, '');
        await HomeWidget.saveWidgetData<String>(keyAmount, '');
        await HomeWidget.saveWidgetData<String>(keyDate, '');
      } else {
        await HomeWidget.saveWidgetData<bool>(keyEmpty, false);
        await HomeWidget.saveWidgetData<String>(keyTitle, next.title);
        await HomeWidget.saveWidgetData<String>(
            keyAmount, Money.format(next.amount, currency.symbol));
        await HomeWidget.saveWidgetData<String>(
            keyDate, DateFormat.MMMd().format(next.date));
      }

      await HomeWidget.updateWidget(
        androidName: androidWidgetName,
        iOSName: iOSWidgetName,
      );
    } catch (e) {
      debugPrint('Could not refresh the home screen widget: $e');
    }
  }
}
