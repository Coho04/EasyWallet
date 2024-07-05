import 'package:easy_wallet/managers/data_migration_manager.dart';
import 'package:easy_wallet/provider/subscription_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'easy_wallet_app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Rufen Sie die Datenmigration auf
  await DataMigrationManager().migrateData();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SubscriptionProvider()),
      ],
      child: const EasyWalletApp(),
    ),
  );
}
