import 'package:flutter/material.dart';
import 'package:easy_wallet/model/subscription.dart';
import 'package:easy_wallet/persistence_controller.dart';

class SubscriptionProvider with ChangeNotifier {
  List<Subscription> _subscriptions = [];

  List<Subscription> get subscriptions => _subscriptions;

  Future<void> loadSubscriptions() async {
    _subscriptions = await PersistenceController.instance.getAllSubscriptions();
    debugPrint('Loaded ${_subscriptions.length} subscriptions');
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
