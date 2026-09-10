import 'dart:convert';

import 'package:easy_wallet/generated/l10n.dart';
import 'package:easy_wallet/managers/subscription_catalog_service.dart';
import 'package:easy_wallet/provider/currency_provider.dart';
import 'package:easy_wallet/views/subscription/template_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const baseUrl = 'http://127.0.0.1:8000';

  Map<String, dynamic> plan(
    String name,
    int amountMinor, {
    String currency = 'EUR',
    String interval = 'monthly',
    String? region = 'DE',
  }) =>
      {
        'name': name,
        'amount_minor': amountMinor,
        'currency': currency,
        'interval': interval,
        'region': region,
        'price_checked_at': '2026-09-09',
      };

  Map<String, dynamic> service(
    String slug,
    String name, {
    List<Map<String, dynamic>> plans = const [],
    String category = 'streaming_video',
  }) =>
      {
        'slug': slug,
        'name': name,
        'category': category,
        'website_url': 'https://www.$slug.com',
        'plans': plans,
      };

  String body(List<Map<String, dynamic>> services) => jsonEncode({
        'data': services,
        'meta': {
          'current_page': 1,
          'per_page': 25,
          'total': services.length,
          'last_page': 1,
        },
      });

  /// Hosts the picker the way the app does, and records what it pops with.
  Widget host(
    SubscriptionCatalogService catalog, {
    void Function(TemplateSelection?)? onResult,
  }) {
    return ChangeNotifierProvider<CurrencyProvider>(
      create: (_) => CurrencyProvider(),
      child: CupertinoApp(
        locale: const Locale('en'),
        localizationsDelegates: const [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: S.delegate.supportedLocales,
        home: Builder(
          builder: (context) => CupertinoPageScaffold(
            child: Center(
              child: CupertinoButton(
                child: const Text('open'),
                onPressed: () async {
                  final selection =
                      await Navigator.of(context).push<TemplateSelection>(
                    CupertinoPageRoute(
                      builder: (_) => TemplatePickerView(service: catalog),
                    ),
                  );
                  onResult?.call(selection);
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  SubscriptionCatalogService catalogReturning(
    String Function(Uri uri) responder, {
    void Function(Uri uri)? onRequest,
  }) =>
      SubscriptionCatalogService(
        baseUrl: baseUrl,
        client: MockClient((request) async {
          onRequest?.call(request.url);
          return http.Response(responder(request.url), 200);
        }),
      );

  /// Pumps a fixed number of frames instead of settling. The rows show a
  /// favicon whose placeholder is a spinner that never stops in a test, so
  /// pumpAndSettle would wait for an animation that has no end.
  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));
  }

  Future<void> openPicker(WidgetTester tester) async {
    await tester.tap(find.text('open'));
    await settle(tester);
  }

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('lists the services the catalog answers with', (tester) async {
    final catalog = catalogReturning((_) => body([
          service('netflix', 'Netflix', plans: [plan('Standard', 1599)]),
          service('spotify', 'Spotify', plans: [plan('Premium', 1099)]),
        ]));

    await tester.pumpWidget(host(catalog));
    await openPicker(tester);

    expect(find.text('Netflix'), findsOneWidget);
    expect(find.text('Spotify'), findsOneWidget);
  });

  testWidgets('picking a service with one plan returns it straight away',
      (tester) async {
    TemplateSelection? result;
    final catalog = catalogReturning((_) => body([
          service('netflix', 'Netflix', plans: [plan('Standard', 1599)]),
        ]));

    await tester.pumpWidget(host(catalog, onResult: (s) => result = s));
    await openPicker(tester);
    await tester.tap(find.text('Netflix'));
    await settle(tester);

    expect(result, isNotNull);
    expect(result!.template.slug, 'netflix');
    expect(result!.plan, isNotNull);
    expect(result!.plan!.amount, closeTo(15.99, 0.001));
  });

  testWidgets('picking a service with several plans asks which one',
      (tester) async {
    TemplateSelection? result;
    final catalog = catalogReturning((_) => body([
          service('netflix', 'Netflix', plans: [
            plan('Standard mit Werbung', 699),
            plan('Standard', 1599),
            plan('Premium', 2199),
          ]),
        ]));

    await tester.pumpWidget(host(catalog, onResult: (s) => result = s));
    await openPicker(tester);
    await tester.tap(find.text('Netflix'));
    await settle(tester);

    // The tariff step, with every plan and its price.
    expect(find.text('Premium'), findsOneWidget);
    expect(find.text('Standard mit Werbung'), findsOneWidget);
    expect(result, isNull);

    await tester.tap(find.text('Premium'));
    await settle(tester);

    expect(result!.plan!.amount, closeTo(21.99, 0.001));
    expect(result!.template.name, 'Netflix');
  });

  testWidgets('a service without prices is still pickable', (tester) async {
    // Region and currency filter the plans, not the services, so a service
    // can arrive with nothing priced. Its name and address are worth having.
    TemplateSelection? result;
    final catalog =
        catalogReturning((_) => body([service('dropbox', 'Dropbox')]));

    await tester.pumpWidget(host(catalog, onResult: (s) => result = s));
    await openPicker(tester);
    await tester.tap(find.text('Dropbox'));
    await settle(tester);

    expect(result, isNotNull);
    expect(result!.template.slug, 'dropbox');
    expect(result!.plan, isNull);
  });

  testWidgets('backing out returns nothing at all', (tester) async {
    var called = false;
    TemplateSelection? result;
    final catalog =
        catalogReturning((_) => body([service('netflix', 'Netflix')]));

    await tester.pumpWidget(host(catalog, onResult: (s) {
      called = true;
      result = s;
    }));
    await openPicker(tester);
    await tester.tap(find.byIcon(CupertinoIcons.back));
    await settle(tester);

    expect(called, isTrue);
    expect(result, isNull);
  });

  testWidgets('waits for a pause before searching', (tester) async {
    final asked = <String?>[];
    final catalog = catalogReturning(
      (_) => body([service('netflix', 'Netflix')]),
      onRequest: (uri) => asked.add(uri.queryParameters['q']),
    );

    await tester.pumpWidget(host(catalog));
    await openPicker(tester);
    expect(asked, [null]); // the opening request for the catalog itself

    // Typing a word must not be a request per letter.
    await tester.enterText(find.byType(CupertinoSearchTextField), 'ne');
    await tester.pump(const Duration(milliseconds: 100));
    await tester.enterText(find.byType(CupertinoSearchTextField), 'net');
    await tester.pump(const Duration(milliseconds: 100));
    await tester.enterText(find.byType(CupertinoSearchTextField), 'netf');
    expect(asked, hasLength(1));

    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();
    expect(asked, [null, 'netf']);
  });

  testWidgets('says so when the results are stored ones', (tester) async {
    final warm = SubscriptionCatalogService(
      baseUrl: baseUrl,
      client: MockClient(
          (_) async => http.Response(body([service('netflix', 'Netflix')]), 200)),
    );
    await warm.search(query: '');

    final offline = SubscriptionCatalogService(
      baseUrl: baseUrl,
      client: MockClient((_) async => throw Exception('offline')),
    );

    await tester.pumpWidget(host(offline));
    await openPicker(tester);

    expect(find.text('Netflix'), findsOneWidget);
    expect(find.text(S.current.catalogCachedNotice), findsOneWidget);
  });

  testWidgets('says the catalog is unreachable when nothing is stored',
      (tester) async {
    final offline = SubscriptionCatalogService(
      baseUrl: baseUrl,
      client: MockClient((_) async => throw Exception('offline')),
    );

    await tester.pumpWidget(host(offline));
    await openPicker(tester);

    expect(find.text(S.current.catalogEmptyOffline), findsOneWidget);
  });

  testWidgets('shows how old a suggested price is', (tester) async {
    final catalog = catalogReturning((_) => body([
          service('netflix', 'Netflix', plans: [
            plan('Standard', 1599),
            plan('Premium', 2199),
          ]),
        ]));

    await tester.pumpWidget(host(catalog));
    await openPicker(tester);
    await tester.tap(find.text('Netflix'));
    await settle(tester);

    expect(find.text(S.current.catalogPriceIsSuggestion), findsOneWidget);
    expect(find.textContaining(S.current.catalogPriceFrom), findsWidgets);
  });

  testWidgets('an empty catalog reads as empty, not as a failure',
      (tester) async {
    // The first production deploy answers 200 with nothing until the import
    // has run. Telling the user they are offline would be a lie they would
    // waste time acting on.
    final catalog = catalogReturning((_) => jsonEncode({
          'data': [],
          'meta': {
            'current_page': 1,
            'per_page': 25,
            'total': 0,
            'last_page': 1,
          },
        }));

    await tester.pumpWidget(host(catalog));
    await openPicker(tester);

    expect(find.text(S.current.catalogEmpty), findsOneWidget);
    expect(find.text(S.current.catalogEmptyOffline), findsNothing);
  });

  testWidgets('a search that found nothing says so', (tester) async {
    final catalog = catalogReturning((uri) => uri.queryParameters['q'] == null
        ? body([service('netflix', 'Netflix')])
        : jsonEncode({
            'data': [],
            'meta': {
              'current_page': 1,
              'per_page': 25,
              'total': 0,
              'last_page': 1,
            },
          }));

    await tester.pumpWidget(host(catalog));
    await openPicker(tester);
    await tester.enterText(find.byType(CupertinoSearchTextField), 'nothing');
    await tester.pump(const Duration(milliseconds: 400));
    await settle(tester);

    expect(find.text(S.current.catalogNoResults), findsOneWidget);
    expect(find.text(S.current.catalogEmptyOffline), findsNothing);
  });

  testWidgets('lists a service whose plans repeat a name', (tester) async {
    // Disney+ offers Standard and Premium both monthly and yearly.
    TemplateSelection? result;
    final catalog = catalogReturning((_) => body([
          service('disney-plus', 'Disney+', plans: [
            plan('Standard', 1099),
            plan('Premium', 1599),
            plan('Standard', 10990, interval: 'yearly'),
            plan('Premium', 15990, interval: 'yearly'),
          ]),
        ]));

    await tester.pumpWidget(host(catalog, onResult: (s) => result = s));
    await openPicker(tester);
    await tester.tap(find.text('Disney+'));
    await settle(tester);

    // Both of each name are offered, told apart by the price beside them.
    expect(find.text('Standard'), findsNWidgets(2));
    expect(find.text('Premium'), findsNWidgets(2));

    await tester.tap(find.text('Standard').last);
    await settle(tester);

    expect(result!.plan!.rate.value, 'yearly');
    expect(result!.plan!.amount, closeTo(109.90, 0.001));
  });
}
