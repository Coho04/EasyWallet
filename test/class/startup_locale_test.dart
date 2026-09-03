import 'package:easy_wallet/class/startup_locale.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const supported = [Locale('en'), Locale('de')];

  group('StartupLocale.resolve', () {
    test('takes the device language when it is supported', () {
      expect(StartupLocale.resolve(const Locale('de'), supported),
          const Locale('de'));
    });

    test('ignores the region, a language is enough', () {
      expect(StartupLocale.resolve(const Locale('de', 'AT'), supported),
          const Locale('de'));
    });

    test('falls back to the first supported language', () {
      expect(StartupLocale.resolve(const Locale('fr'), supported),
          const Locale('en'));
    });

    test('falls back when the device reports nothing', () {
      expect(StartupLocale.resolve(null, supported), const Locale('en'));
    });

    test('falls back when nothing is supported at all', () {
      expect(StartupLocale.resolve(const Locale('de'), const []),
          const Locale('en'));
    });
  });
}
