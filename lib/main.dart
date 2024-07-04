import 'package:easy_wallet/background_task_manager.dart';
import 'package:flutter/cupertino.dart';
import 'easy_wallet_app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final backgroundTaskManager = BackgroundTaskManager();
  await backgroundTaskManager.init();

  runApp(const EasyWalletApp());
}
