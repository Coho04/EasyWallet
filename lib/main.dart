import 'dart:io';
import 'package:easy_wallet/managers/data_migration_manager.dart';
import 'package:easy_wallet/provider/subscription_provider.dart';
import 'package:easy_wallet/views/splash_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'easy_wallet_app.dart';
import 'package:local_auth/local_auth.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  bool shouldAuthenticate = await checkAuthenticationSetting();

  if (shouldAuthenticate) {
    bool isAuthenticated = await authenticateWithBiometrics();
    if (!isAuthenticated) {
      exit(0);
    }
  }

  runApp(const CupertinoApp(
    home: SplashScreen(),
  ));

  await Future.wait([
    initializeSentry(),
    DataMigrationManager().migrateData(),
  ]);
}

Future<void> initializeSentry() async {
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
          ],
          child: const EasyWalletApp(),
        ),
      );
    },
  );
}

Future<void> migrateData() async {
  if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.iOS)) {
    await DataMigrationManager().migrateData();
  }
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
  } on PlatformException catch (e) {
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
      localizedReason: Intl.message('pleaseAuthenticateYourselfToViewYourSubscriptions'),
      options: const AuthenticationOptions(
        biometricOnly: true,
        useErrorDialogs: true,
        stickyAuth: true,
      ),
    );
    return didAuthenticate;
  } on PlatformException catch (e) {
    return false;
  }
}
