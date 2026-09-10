import 'package:easy_wallet/class/tour_step.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Drives the guided tour through the app's tabs.
///
/// Holds only where the tour is; the views react to that. Keeping the state
/// here rather than inside MainView is what lets the settings screen restart
/// the tour from inside a tab without reaching up through the widget tree.
class TourController with ChangeNotifier {
  TourController({List<TourStep>? steps}) : steps = steps ?? TourStep.all;

  final List<TourStep> steps;

  static const String seenKey = 'hasSeenTour';

  int? _index;

  bool get isRunning => _index != null;

  /// The step being shown, or null while the tour is not running.
  TourStep? get step => _index == null ? null : steps[_index!];

  /// The step's position, counted the way it is shown: the first step is 1.
  int get stepNumber => (_index ?? 0) + 1;

  int get stepCount => steps.length;

  bool get isOnLastStep => _index != null && _index == steps.length - 1;

  /// Runs the tour the first time the app is opened, and never unasked again.
  ///
  /// Marks the tour as seen the moment it starts, not when it ends. Someone
  /// who closes the app half way through has made their point; showing it to
  /// them again on the next launch would be nagging. It stays available in
  /// the settings for anyone who wants it back.
  Future<void> startIfUnseen() async {
    if (steps.isEmpty || isRunning) {
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(seenKey) ?? false) {
      return;
    }
    await prefs.setBool(seenKey, true);
    start();
  }

  /// Starts the tour from the beginning, however often the user asks for it.
  void start() {
    if (steps.isEmpty) {
      return;
    }
    _index = 0;
    notifyListeners();
  }

  /// Moves on, and ends the tour when there is nothing left to show.
  void next() {
    if (_index == null) {
      return;
    }
    if (isOnLastStep) {
      finish();
      return;
    }
    _index = _index! + 1;
    notifyListeners();
  }

  /// Ends the tour, whether the user walked all of it or skipped out.
  void finish() {
    if (_index == null) {
      return;
    }
    _index = null;
    notifyListeners();
  }

  /// Forgets that the tour was seen, so the next launch offers it again.
  /// Exists for the settings screen and for tests.
  static Future<void> forgetSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(seenKey);
  }
}
