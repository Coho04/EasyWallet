import 'package:flutter/cupertino.dart';

/// Picks the language to load before the first frame.
///
/// The notification categories are labelled from the translations, and they
/// are built at startup - before the widget tree has resolved a locale. This
/// mirrors what the app's own localeResolutionCallback does, so both agree.
class StartupLocale {
  const StartupLocale._();

  static const Locale fallback = Locale('en');

  static Locale resolve(Locale? device, List<Locale> supported) {
    if (supported.isEmpty) return fallback;
    if (device != null) {
      for (final locale in supported) {
        if (locale.languageCode == device.languageCode) return locale;
      }
    }
    return supported.first;
  }
}
