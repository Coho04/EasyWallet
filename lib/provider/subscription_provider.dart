import 'package:flutter/foundation.dart';
import 'package:easy_wallet/model/subscription.dart';
import 'package:easy_wallet/persistence_controller.dart';

class SubscriptionProvider with ChangeNotifier {
  List<Subscription> _subscriptions = [];

  List<Subscription> get subscriptions => _subscriptions;

  Future<void> loadSubscriptions() async {
    if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.iOS)) {
      await PersistenceController.instance.syncWithCloud();
    }
    _subscriptions = await Subscription.all();
    notifyListeners();
  }

  Future<void> saveSubscription(Subscription subscription) async {
    await subscription.save();
    await loadSubscriptions();
  }

  Future<void> deleteSubscription(Subscription subscription) async {
    await subscription.delete();
    await loadSubscriptions();
  }
}
