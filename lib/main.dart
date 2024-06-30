import 'package:easy_wallet/background_taskmanager.dart';
import 'package:easy_wallet/home_view.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final manager = BackgroundTaskManager();
  await manager.init();
  runApp(EasyWalletApp());
}

class EasyWalletApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => PersistenceController(),
      child: MaterialApp(
        home: HomeView(),
      ),
    );
  }
}

class PersistenceController with ChangeNotifier {
  static final PersistenceController _instance = PersistenceController._internal();
  factory PersistenceController() {
    return _instance;
  }
  PersistenceController._internal();
}
