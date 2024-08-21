import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mockito/mockito.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:easy_wallet/main.dart';

class MockSpan extends Mock implements ISentrySpan {}

void main() {
  group('checkAuthenticationSetting', () {
    test('returns true if authentication setting is true', () async {
      SharedPreferences.setMockInitialValues({'require_authentication': true});
      final result = await checkAuthenticationSetting();
      expect(result, true);
    });

    test('returns false if authentication setting is false', () async {
      SharedPreferences.setMockInitialValues({'require_authentication': false});
      final result = await checkAuthenticationSetting();
      expect(result, false);
    });

    test('returns false if authentication setting is not set', () async {
      SharedPreferences.setMockInitialValues({});
      final result = await checkAuthenticationSetting();
      expect(result, false);
    });
  });
}
