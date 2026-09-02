import 'package:easy_wallet/views/components/form_fields/multi_select_dialog_field.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multi_select_flutter/util/multi_select_item.dart';
import 'package:multi_select_flutter/util/multi_select_list_type.dart';

void main() {
  group('MultiSelectDialogField Widget Tests', () {
    final items = [
      MultiSelectItem<String>('streaming', 'Streaming'),
      MultiSelectItem<String>('hosting', 'Hosting'),
    ];

    // Mirrors the real app: a Cupertino-only tree (no Material ancestor) with
    // the same localization delegates registered in easy_wallet_app.dart, and
    // the field placed inside a scrollable like the create/edit views do.
    Widget buildField({List<String> initialValue = const []}) {
      return CupertinoApp(
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: CupertinoPageScaffold(
          child: ListView(
            children: [
              MultiSelectDialogField<String>(
                items: items,
                initialValue: initialValue,
                listType: MultiSelectListType.CHIP,
                buttonText: const Text('Select'),
                onConfirm: (_) {},
              ),
            ],
          ),
        ),
      );
    }

    testWidgets('renders inside a Cupertino tree without a Material ancestor',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildField());

      expect(tester.takeException(), isNull);
      expect(find.text('Select'), findsOneWidget);
    });

    testWidgets('renders selected chips without a Material ancestor',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildField(initialValue: ['streaming']));

      expect(tester.takeException(), isNull);
      expect(find.text('Streaming'), findsOneWidget);
    });
  });
}
