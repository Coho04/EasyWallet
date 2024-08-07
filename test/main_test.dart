import 'package:easy_wallet/main.dart';
import 'package:easy_wallet/managers/data_migration_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:provider/provider.dart';

class MockSentryFlutter extends Mock implements SentryFlutter {}
class MockDataMigrationManager extends Mock implements DataMigrationManager {}

void main_test() {
  group('App Initialization', () {
    testWidgets('Initializes app correctly on iOS', (tester) async {
      // Setzen einer Mock-Umgebung für Tests
      final mockSentryFlutter = MockSentryFlutter();
      final mockDataMigrationManager = MockDataMigrationManager();

      when(mockDataMigrationManager.migrateData()).thenAnswer((_) async {});
      // Füge hier weitere Mock-Initialisierungen hinzu, falls erforderlich

      // Führe die main Funktion aus
      main();

      // Überprüfen, ob die runApp Methode aufgerufen wurde
      expect(find.byType(MultiProvider), findsOneWidget);
    });
  });
}
