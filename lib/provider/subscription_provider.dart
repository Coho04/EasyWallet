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

  Future<Subscription> saveSubscription(Subscription subscription) async {
    var sub = await subscription.save();
    await loadSubscriptions();
    return sub;
  }

  Future<void> deleteSubscription(Subscription subscription) async {
    await subscription.delete();
    await loadSubscriptions();
  }
}
