import 'package:background_fetch/background_fetch.dart';
import 'package:easy_wallet/managers/background_fetch_manager.dart';
import 'package:easy_wallet/provider/category_provider.dart';
import 'package:easy_wallet/provider/currency_provider.dart';
import 'package:easy_wallet/provider/subscription_provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'easy_wallet_app.dart';
import 'package:local_auth/local_auth.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  BackgroundFetch.registerHeadlessTask(backgroundFetchHeadlessTask);
  initializeSentry();
}

void initializeSentry() async {
  await SentryFlutter.init(
    (options) {
      options.dsn = kDebugMode
          ? ''
          : 'https://b2c887d934a80f2a6aaa9a3cf4aa9d48@o4504089255804929.ingest.us.sentry.io/4507566119321600';
      options.tracesSampleRate = 1.0;
      options.profilesSampleRate = 1.0;
    },
    appRunner: () async {
      runApp(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => SubscriptionProvider()),
            ChangeNotifierProvider(create: (_) => CategoryProvider()),
            ChangeNotifierProvider(create: (_) => CurrencyProvider()),
          ],
          child: const EasyWalletApp(),
        ),
      );
      final backgroundFetchManager = BackgroundFetchManager();
      await backgroundFetchManager.init();
    },
  );
}

void backgroundFetchHeadlessTask(String taskId) async {
  final manager = BackgroundFetchManager();
  await manager.init();
  BackgroundFetch.finish(taskId);
}

Future<void> processOrderBatch(ISentrySpan span) async {
  final innerSpan = span.startChild('task', description: 'operation');
  try {
    await Future.delayed(const Duration(seconds: 2));
  } catch (exception) {
    innerSpan.throwable = exception;
    innerSpan.status = const SpanStatus.notFound();
  } finally {
    await innerSpan.finish();
  }
}

Future<bool> checkAuthenticationSetting() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.getBool('require_authentication') ?? false;
}

Future<bool> authenticateWithBiometrics() async {
  final LocalAuthentication auth = LocalAuthentication();
  bool canAuthenticate = false;

  try {
    canAuthenticate =
        await auth.canCheckBiometrics || await auth.isDeviceSupported();
  } on PlatformException {
    return false;
  }

  if (!canAuthenticate) {
    return false;
  }

  try {
    final List<BiometricType> availableBiometrics =
        await auth.getAvailableBiometrics();
    if (availableBiometrics.isEmpty) {
      return false;
    }

    if (!availableBiometrics.contains(BiometricType.face)) {
      return false;
    }

    final bool didAuthenticate = await auth.authenticate(
      localizedReason:
          Intl.message('pleaseAuthenticateYourselfToViewYourSubscriptions'),
      options: const AuthenticationOptions(
        biometricOnly: true,
        useErrorDialogs: true,
        stickyAuth: true,
      ),
    );
    return didAuthenticate;
  } on PlatformException {
    return false;
  }
}
