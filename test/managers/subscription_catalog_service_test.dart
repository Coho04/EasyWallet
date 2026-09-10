import 'dart:convert';

import 'package:easy_wallet/managers/subscription_catalog_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const baseUrl = 'http://127.0.0.1:8000';

  String catalogBody({
    String slug = 'netflix',
    String name = 'Netflix',
    int currentPage = 1,
    int lastPage = 1,
  }) =>
      jsonEncode({
        'data': [
          {
            'slug': slug,
            'name': name,
            'category': 'streaming_video',
            'website_url': 'https://www.netflix.com',
            'plans': [
              {
                'name': 'Standard',
                'amount_minor': 1599,
                'currency': 'EUR',
                'interval': 'monthly',
                'region': 'DE',
                'source_url': 'https://help.netflix.com/de/node/24926',
                'price_checked_at': '2026-09-09',
              }
            ],
          }
        ],
        'meta': {
          'current_page': currentPage,
          'per_page': 25,
          'total': 1,
          'last_page': lastPage,
        },
      });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('request building', () {
    test('asks the catalog endpoint with the search and filters', () async {
      late Uri seen;
      final service = SubscriptionCatalogService(
        baseUrl: baseUrl,
        client: MockClient((request) async {
          seen = request.url;
          return http.Response(catalogBody(), 200);
        }),
      );

      await service.search(query: 'netflix', region: 'de', currency: 'eur');

      expect(seen.path, '/api/v1/subscription-services');
      expect(seen.queryParameters['q'], 'netflix');
      expect(seen.queryParameters['region'], 'DE');
      expect(seen.queryParameters['currency'], 'EUR');
      expect(seen.queryParameters.containsKey('page'), isFalse);
    });

    test('leaves out a search too short for the catalog to accept', () async {
      // The API answers 422 below two characters, so asking is pointless: an
      // absent q is the documented way to read the catalog itself.
      late Uri seen;
      final service = SubscriptionCatalogService(
        baseUrl: baseUrl,
        client: MockClient((request) async {
          seen = request.url;
          return http.Response(catalogBody(), 200);
        }),
      );

      await service.search(query: 'n');

      expect(seen.queryParameters.containsKey('q'), isFalse);
    });

    test('trims the search before measuring and sending it', () async {
      late Uri seen;
      final service = SubscriptionCatalogService(
        baseUrl: baseUrl,
        client: MockClient((request) async {
          seen = request.url;
          return http.Response(catalogBody(), 200);
        }),
      );

      await service.search(query: '  spotify  ');

      expect(seen.queryParameters['q'], 'spotify');
    });

    test('asks for a later page only when one was requested', () async {
      late Uri seen;
      final service = SubscriptionCatalogService(
        baseUrl: baseUrl,
        client: MockClient((request) async {
          seen = request.url;
          return http.Response(catalogBody(), 200);
        }),
      );

      await service.search(page: 3);

      expect(seen.queryParameters['page'], '3');
    });

    test('does not touch the network without a configured host', () async {
      var called = false;
      final service = SubscriptionCatalogService(
        baseUrl: '',
        client: MockClient((request) async {
          called = true;
          return http.Response(catalogBody(), 200);
        }),
      );

      final result = await service.search(query: 'netflix');

      expect(called, isFalse);
      expect(result.isEmpty, isTrue);
    });

    test('rejects a host that is not a usable URL', () async {
      var called = false;
      final service = SubscriptionCatalogService(
        baseUrl: 'not a host',
        client: MockClient((request) async {
          called = true;
          return http.Response(catalogBody(), 200);
        }),
      );

      expect((await service.search()).isEmpty, isTrue);
      expect(called, isFalse);
    });

    test('tolerates a host written with a trailing slash', () async {
      late Uri seen;
      final service = SubscriptionCatalogService(
        baseUrl: '$baseUrl/',
        client: MockClient((request) async {
          seen = request.url;
          return http.Response(catalogBody(), 200);
        }),
      );

      await service.search();

      expect(seen.path, '/api/v1/subscription-services');
    });
  });

  group('reading answers', () {
    test('returns the services of a successful answer', () async {
      final service = SubscriptionCatalogService(
        baseUrl: baseUrl,
        client: MockClient((_) async => http.Response(catalogBody(), 200)),
      );

      final result = await service.search(query: 'netflix');

      expect(result.templates, hasLength(1));
      expect(result.templates.single.name, 'Netflix');
      expect(result.isFromCache, isFalse);
      expect(result.hasMore, isFalse);
    });

    test('reports that the catalog holds further pages', () async {
      final service = SubscriptionCatalogService(
        baseUrl: baseUrl,
        client: MockClient((_) async =>
            http.Response(catalogBody(currentPage: 1, lastPage: 4), 200)),
      );

      expect((await service.search()).hasMore, isTrue);
    });

    test('reports no further pages on the last one', () async {
      final service = SubscriptionCatalogService(
        baseUrl: baseUrl,
        client: MockClient((_) async =>
            http.Response(catalogBody(currentPage: 4, lastPage: 4), 200)),
      );

      expect((await service.search()).hasMore, isFalse);
    });
  });

  group('caching', () {
    test('sends the stored tag back on the next identical query', () async {
      final tags = <String?>[];
      final service = SubscriptionCatalogService(
        baseUrl: baseUrl,
        client: MockClient((request) async {
          tags.add(request.headers['If-None-Match']);
          return http.Response(catalogBody(), 200, headers: {'etag': 'W/"v1"'});
        }),
      );

      await service.search(query: 'netflix');
      await service.search(query: 'netflix');

      expect(tags, [null, 'W/"v1"']);
    });

    test('answers a 304 from the stored body, and calls it current', () async {
      var requests = 0;
      final service = SubscriptionCatalogService(
        baseUrl: baseUrl,
        client: MockClient((request) async {
          requests++;
          if (requests == 1) {
            return http.Response(catalogBody(), 200, headers: {'etag': '"v1"'});
          }
          return http.Response('', 304);
        }),
      );

      await service.search(query: 'netflix');
      final result = await service.search(query: 'netflix');

      expect(result.templates.single.name, 'Netflix');
      // Nothing changed, so the answer is current rather than a fallback.
      expect(result.isFromCache, isFalse);
    });

    test('caches each query separately', () async {
      final service = SubscriptionCatalogService(
        baseUrl: baseUrl,
        client: MockClient((request) async {
          final q = request.url.queryParameters['q'];
          return http.Response(
              catalogBody(slug: q ?? 'all', name: q ?? 'all'), 200);
        }),
      );

      await service.search(query: 'netflix');
      await service.search(query: 'spotify');

      final offline = SubscriptionCatalogService(
        baseUrl: baseUrl,
        client: MockClient((_) async => throw const _Offline()),
      );

      expect((await offline.search(query: 'netflix')).templates.single.name,
          'netflix');
      expect((await offline.search(query: 'spotify')).templates.single.name,
          'spotify');
    });

    test('a malformed answer does not replace a good stored one', () async {
      var requests = 0;
      final service = SubscriptionCatalogService(
        baseUrl: baseUrl,
        client: MockClient((_) async {
          requests++;
          if (requests == 1) {
            return http.Response(catalogBody(), 200);
          }
          return http.Response('<html>proxy error</html>', 200);
        }),
      );

      await service.search(query: 'netflix');
      final result = await service.search(query: 'netflix');

      expect(result.templates.single.name, 'Netflix');
      expect(result.isFromCache, isTrue);
    });
  });

  group('failing without getting in the way', () {
    test('falls back to the stored answer when the network is gone', () async {
      final service = SubscriptionCatalogService(
        baseUrl: baseUrl,
        client: MockClient((_) async => http.Response(catalogBody(), 200)),
      );
      await service.search(query: 'netflix');

      final offline = SubscriptionCatalogService(
        baseUrl: baseUrl,
        client: MockClient((_) async => throw const _Offline()),
      );
      final result = await offline.search(query: 'netflix');

      expect(result.templates.single.name, 'Netflix');
      expect(result.isFromCache, isTrue);
    });

    test('returns nothing when offline with nothing stored', () async {
      final service = SubscriptionCatalogService(
        baseUrl: baseUrl,
        client: MockClient((_) async => throw const _Offline()),
      );

      final result = await service.search(query: 'netflix');

      expect(result.isEmpty, isTrue);
    });

    test('swallows a rejected query instead of throwing at the caller',
        () async {
      final service = SubscriptionCatalogService(
        baseUrl: baseUrl,
        client: MockClient((_) async => http.Response(
            jsonEncode({'message': 'invalid', 'errors': {}}), 422)),
      );

      expect((await service.search(query: 'netflix')).isEmpty, isTrue);
    });

    test('swallows a server error', () async {
      final service = SubscriptionCatalogService(
        baseUrl: baseUrl,
        client: MockClient((_) async =>
            http.Response(jsonEncode({'message': 'Server Error'}), 500)),
      );

      expect((await service.search()).isEmpty, isTrue);
    });
  });

  group('rate limiting', () {
    test('stops asking for as long as Retry-After says', () async {
      var now = DateTime(2026, 9, 9, 12);
      var requests = 0;
      final service = SubscriptionCatalogService(
        baseUrl: baseUrl,
        clock: () => now,
        client: MockClient((_) async {
          requests++;
          return http.Response(jsonEncode({'message': 'Too Many Requests'}), 429,
              headers: {'retry-after': '30'});
        }),
      );

      await service.search(query: 'netflix');
      expect(requests, 1);

      // Still inside the window: asking again would only earn another 429.
      now = now.add(const Duration(seconds: 10));
      await service.search(query: 'spotify');
      expect(requests, 1);

      now = now.add(const Duration(seconds: 25));
      await service.search(query: 'disney');
      expect(requests, 2);
    });

    test('waits out the rate window when Retry-After is unreadable', () async {
      var now = DateTime(2026, 9, 9, 12);
      var requests = 0;
      final service = SubscriptionCatalogService(
        baseUrl: baseUrl,
        clock: () => now,
        client: MockClient((_) async {
          requests++;
          return http.Response('', 429, headers: {'retry-after': 'soon'});
        }),
      );

      await service.search();
      now = now.add(const Duration(seconds: 59));
      await service.search();
      expect(requests, 1);

      now = now.add(const Duration(seconds: 2));
      await service.search();
      expect(requests, 2);
    });

    test('serves the stored answer while it is rate limited', () async {
      final warm = SubscriptionCatalogService(
        baseUrl: baseUrl,
        client: MockClient((_) async => http.Response(catalogBody(), 200)),
      );
      await warm.search(query: 'netflix');

      final limited = SubscriptionCatalogService(
        baseUrl: baseUrl,
        client: MockClient(
            (_) async => http.Response('', 429, headers: {'retry-after': '30'})),
      );
      final result = await limited.search(query: 'netflix');

      expect(result.templates.single.name, 'Netflix');
      expect(result.isFromCache, isTrue);
    });
  });

  group('cache housekeeping', () {
    test('keeps the stored answers bounded', () async {
      final service = SubscriptionCatalogService(
        baseUrl: baseUrl,
        client: MockClient((_) async => http.Response(catalogBody(), 200)),
      );

      for (var i = 0; i < 35; i++) {
        await service.search(query: 'service$i');
      }

      final prefs = await SharedPreferences.getInstance();
      final stored =
          prefs.getKeys().where((key) => key.startsWith('catalog:')).length;
      expect(stored, lessThanOrEqualTo(30));
    });

    test('drops the oldest answer first', () async {
      final service = SubscriptionCatalogService(
        baseUrl: baseUrl,
        client: MockClient((_) async => http.Response(catalogBody(), 200)),
      );

      for (var i = 0; i < 31; i++) {
        await service.search(query: 'service$i');
      }

      final offline = SubscriptionCatalogService(
        baseUrl: baseUrl,
        client: MockClient((_) async => throw const _Offline()),
      );

      expect((await offline.search(query: 'service0')).isEmpty, isTrue);
      expect((await offline.search(query: 'service30')).isEmpty, isFalse);
    });

    test('clearCache forgets every stored answer', () async {
      final service = SubscriptionCatalogService(
        baseUrl: baseUrl,
        client: MockClient((_) async => http.Response(catalogBody(), 200)),
      );
      await service.search(query: 'netflix');

      await SubscriptionCatalogService.clearCache();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getKeys().where((key) => key.startsWith('catalog:')),
          isEmpty);
    });
  });

  group('an empty catalog is not a failure', () {
    String emptyBody() => jsonEncode({
          'data': [],
          'meta': {
            'current_page': 1,
            'per_page': 25,
            'total': 0,
            'last_page': 1,
            'catalog_updated_at': '2026-09-09T12:15:22+00:00',
          },
        });

    test('a catalog that answered with nothing is reachable', () async {
      // A production deployment whose import has not run yet answers exactly
      // this. Reporting it as unreachable would send the user chasing their
      // network instead of showing them a plain "nothing in here yet".
      final service = SubscriptionCatalogService(
        baseUrl: baseUrl,
        client: MockClient((_) async => http.Response(emptyBody(), 200)),
      );

      final result = await service.search();

      expect(result.isEmpty, isTrue);
      expect(result.isUnavailable, isFalse);
      expect(result.isFromCache, isFalse);
    });

    test('a search that matched nothing is reachable too', () async {
      final service = SubscriptionCatalogService(
        baseUrl: baseUrl,
        client: MockClient((_) async => http.Response(emptyBody(), 200)),
      );

      expect((await service.search(query: 'nothing')).isUnavailable, isFalse);
    });

    test('being offline with nothing stored is unavailable', () async {
      final service = SubscriptionCatalogService(
        baseUrl: baseUrl,
        client: MockClient((_) async => throw const _Offline()),
      );

      expect((await service.search()).isUnavailable, isTrue);
    });

    test('a server error with nothing stored is unavailable', () async {
      final service = SubscriptionCatalogService(
        baseUrl: baseUrl,
        client: MockClient((_) async => http.Response('', 500)),
      );

      expect((await service.search()).isUnavailable, isTrue);
    });

    test('falling back to a stored answer is not unavailable', () async {
      final warm = SubscriptionCatalogService(
        baseUrl: baseUrl,
        client: MockClient((_) async => http.Response(catalogBody(), 200)),
      );
      await warm.search();

      final offline = SubscriptionCatalogService(
        baseUrl: baseUrl,
        client: MockClient((_) async => throw const _Offline()),
      );
      final result = await offline.search();

      expect(result.isUnavailable, isFalse);
      expect(result.isFromCache, isTrue);
    });

    test('an unconfigured host is unavailable', () async {
      final service = SubscriptionCatalogService(
        baseUrl: '',
        client: MockClient((_) async => http.Response(catalogBody(), 200)),
      );

      expect((await service.search()).isUnavailable, isTrue);
    });
  });
}

/// Stands in for the socket errors a device without a network produces.
class _Offline implements Exception {
  const _Offline();
}
