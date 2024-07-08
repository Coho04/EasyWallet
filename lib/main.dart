import 'package:easy_wallet/managers/data_migration_manager.dart';
import 'package:easy_wallet/provider/subscription_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'easy_wallet_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DataMigrationManager().migrateData();

  await SentryFlutter.init(
        (options) {
      options.dsn =
      'https://b2c887d934a80f2a6aaa9a3cf4aa9d48@o4504089255804929.ingest.us.sentry.io/4507566119321600';
      options.tracesSampleRate = 1.0;
      options.profilesSampleRate = 1.0;
    },
    appRunner: () {
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
