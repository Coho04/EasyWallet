import 'package:flutter/foundation.dart';
import 'package:easy_wallet/model/subscription.dart';
import 'package:easy_wallet/persistence_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SubscriptionProvider with ChangeNotifier {
  List<Subscription> _subscriptions = [];

  List<Subscription> get subscriptions => _subscriptions;

  Future<void> loadSubscriptions() async {
    final prefs = await SharedPreferences.getInstance();
    if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.iOS)) {
      if (prefs.getBool('syncWithICloud') ?? false) {
        await PersistenceController.instance.syncFromICloud();
      }
      if (prefs.getBool('syncWithGoogleDrive') ?? false) {
        await PersistenceController.instance.syncFromGoogleDrive();
      }
    }
    _subscriptions = await PersistenceController.instance.getAllSubscriptions();
    notifyListeners();
  }

  Future<void> addSubscription(Subscription subscription) async {
    await PersistenceController.instance.saveSubscription(subscription);
    await loadSubscriptions();
  }

  Future<void> updateSubscription(Subscription subscription) async {
    await PersistenceController.instance.saveSubscription(subscription);
    await loadSubscriptions();
  }

  Future<void> deleteSubscription(Subscription subscription) async {
    await PersistenceController.instance.deleteSubscription(subscription);
    await loadSubscriptions();
  }
}
