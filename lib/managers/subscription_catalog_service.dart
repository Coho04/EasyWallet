import 'dart:convert';

import 'package:easy_wallet/model/subscription_template.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// What one catalog query answered with.
class CatalogResult {
  const CatalogResult({
    required this.templates,
    required this.isFromCache,
    this.hasMore = false,
    this.isUnavailable = false,
  });

  /// The catalog could not be read at all — unreachable, and nothing stored.
  /// Distinct from a catalog that answered and happens to hold nothing.
  const CatalogResult.unavailable()
      : templates = const [],
        isFromCache = false,
        hasMore = false,
        isUnavailable = true;

  final List<SubscriptionTemplate> templates;

  /// True when the answer is a stored one because the catalog could not be
  /// reached, or answered 304. The picker says so, rather than passing off a
  /// stale list as fresh.
  final bool isFromCache;

  /// Whether the catalog holds further pages for this query.
  final bool hasMore;

  /// True when the catalog could not be reached and there was nothing stored
  /// to fall back on. An empty result with this false means the catalog was
  /// read and simply had nothing to say — a freshly deployed, not yet imported
  /// catalog answers exactly that, and it must not be reported as a failure.
  final bool isUnavailable;

  bool get isEmpty => templates.isEmpty;
}

/// Reads the subscription catalog: the services users can pick instead of
/// typing a subscription out by hand.
///
/// Deliberately incapable of failing loudly. Every error path ends in the last
/// stored answer or in an empty result, because the catalog is a shortcut and
/// never a gate — a user whose network is down still creates subscriptions by
/// hand, and nothing here may get in the way of that.
class SubscriptionCatalogService {
  SubscriptionCatalogService({
    http.Client? client,
    String? baseUrl,
    DateTime Function()? clock,
  })  : _client = client ?? http.Client(),
        _baseUrl = _normalizeBaseUrl(baseUrl ?? configuredBaseUrl),
        _clock = clock ?? DateTime.now;

  /// Host of the catalog API, without a trailing slash.
  ///
  /// Override per build with
  /// `--dart-define=EASYWALLET_API_BASE_URL=http://127.0.0.1:8000`.
  /// The default is empty until the production host is decided; while it is,
  /// [isConfigured] is false and the app hides the catalog rather than
  /// offering a feature that cannot work.
  static const String configuredBaseUrl = String.fromEnvironment(
    'EASYWALLET_API_BASE_URL',
    defaultValue: '',
  );

  /// Whether a catalog host is configured for this build.
  static bool get isConfigured => _normalizeBaseUrl(configuredBaseUrl) != null;

  static const String _path = '/api/v1/subscription-services';

  /// The API rejects a search shorter than this with 422.
  static const int minQueryLength = 2;

  static const String _cachePrefix = 'catalog:';
  static const String _cacheIndexKey = 'catalogCacheKeys';

  /// How many answers to keep. Enough that going back to a previous search is
  /// instant, small enough that the preferences file stays a preferences file.
  static const int _maxCacheEntries = 30;

  final http.Client _client;
  final String? _baseUrl;
  final DateTime Function() _clock;

  /// Set when the catalog answered 429. Until it passes, queries are served
  /// from the cache without touching the network.
  DateTime? _blockedUntil;

  /// The services matching [query], or the start of the catalog when [query] is
  /// too short to search with.
  ///
  /// [region] narrows the plans to one country plus the ones priced the same
  /// everywhere; [currency] narrows them to one currency. Neither hides a
  /// service, so a result can carry services with no plans at all.
  Future<CatalogResult> search({
    String? query,
    String? region,
    String? currency,
    int page = 1,
  }) async {
    final baseUrl = _baseUrl;
    if (baseUrl == null) {
      return const CatalogResult.unavailable();
    }

    final trimmed = query?.trim() ?? '';
    final uri = Uri.parse('$baseUrl$_path').replace(queryParameters: {
      if (trimmed.length >= minQueryLength) 'q': trimmed,
      if (region != null) 'region': region.toUpperCase(),
      if (currency != null) 'currency': currency.toUpperCase(),
      if (page > 1) 'page': '$page',
    });

    return _get(uri);
  }

  Future<CatalogResult> _get(Uri uri) async {
    final prefs = await SharedPreferences.getInstance();
    final cached = _readCache(prefs, uri);

    // A 429 is an instruction to stop asking, not to ask more carefully.
    final blockedUntil = _blockedUntil;
    if (blockedUntil != null && _clock().isBefore(blockedUntil)) {
      return _fromCache(cached);
    }

    try {
      final response = await _client.get(uri, headers: {
        'Accept': 'application/json',
        if (cached?.etag != null) 'If-None-Match': cached!.etag!,
      });

      switch (response.statusCode) {
        case 200:
          return await _store(prefs, uri, response);
        case 304:
          // Nothing changed; the stored body is still the right answer.
          return _fromCache(cached, isFromCache: false);
        case 429:
          _blockUntil(response.headers['retry-after']);
          return _fromCache(cached);
        default:
          debugPrint('Catalog answered ${response.statusCode} for $uri');
          return _fromCache(cached);
      }
    } catch (error) {
      // Offline, DNS gone, timeout: the stored answer beats no answer.
      debugPrint('Could not reach the catalog: $error');
      return _fromCache(cached);
    }
  }

  Future<CatalogResult> _store(
    SharedPreferences prefs,
    Uri uri,
    http.Response response,
  ) async {
    // The body is decoded before it is stored, so a malformed answer never
    // replaces a good cached one.
    final decoded = _decode(response.body);
    if (decoded == null) {
      return _fromCache(_readCache(prefs, uri));
    }

    await _writeCache(
      prefs,
      uri,
      _CachedResponse(body: response.body, etag: response.headers['etag']),
    );
    return _resultOf(decoded, isFromCache: false);
  }

  CatalogResult _fromCache(_CachedResponse? cached, {bool isFromCache = true}) {
    if (cached == null) {
      return const CatalogResult.unavailable();
    }
    final decoded = _decode(cached.body);
    if (decoded == null) {
      return const CatalogResult.unavailable();
    }
    return _resultOf(decoded, isFromCache: isFromCache);
  }

  CatalogResult _resultOf(
    Map<String, dynamic> json, {
    required bool isFromCache,
  }) {
    return CatalogResult(
      templates: SubscriptionTemplate.listFromResponse(json),
      isFromCache: isFromCache,
      hasMore: _hasMore(json['meta']),
    );
  }

  static bool _hasMore(dynamic meta) {
    if (meta is! Map) {
      return false;
    }
    final current = meta['current_page'];
    final last = meta['last_page'];
    if (current is! int || last is! int) {
      return false;
    }
    return current < last;
  }

  static Map<String, dynamic>? _decode(String body) {
    try {
      final decoded = jsonDecode(body);
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (_) {
      return null;
    }
  }

  /// Honours `Retry-After`, which is a number of seconds. An absent or
  /// unreadable value falls back to a minute, the length of the rate window.
  void _blockUntil(String? retryAfter) {
    final seconds = int.tryParse(retryAfter?.trim() ?? '') ?? 60;
    _blockedUntil = _clock().add(Duration(seconds: seconds.clamp(1, 3600)));
  }

  _CachedResponse? _readCache(SharedPreferences prefs, Uri uri) {
    final raw = prefs.getString('$_cachePrefix$uri');
    if (raw == null) {
      return null;
    }
    try {
      return _CachedResponse.fromJson(
          jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> _writeCache(
    SharedPreferences prefs,
    Uri uri,
    _CachedResponse entry,
  ) async {
    final key = '$_cachePrefix$uri';
    await prefs.setString(key, jsonEncode(entry.toJson()));

    // Most recently written last, so the oldest entries fall off the front.
    final keys = prefs.getStringList(_cacheIndexKey)?.toList() ?? <String>[];
    keys.remove(key);
    keys.add(key);
    while (keys.length > _maxCacheEntries) {
      await prefs.remove(keys.removeAt(0));
    }
    await prefs.setStringList(_cacheIndexKey, keys);
  }

  /// Drops every stored answer. For the moment the user asks to, not something
  /// the app does on its own.
  static Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    for (final key in prefs.getStringList(_cacheIndexKey) ?? const <String>[]) {
      await prefs.remove(key);
    }
    await prefs.remove(_cacheIndexKey);
  }

  /// The host without a trailing slash, or null when none is configured.
  static String? _normalizeBaseUrl(String value) {
    final trimmed = value.trim().replaceAll(RegExp(r'/+$'), '');
    if (trimmed.isEmpty) {
      return null;
    }
    final uri = Uri.tryParse(trimmed);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      return null;
    }
    return trimmed;
  }
}

/// One stored answer, with the tag that lets the app ask whether it is still
/// the current one.
class _CachedResponse {
  const _CachedResponse({required this.body, this.etag});

  final String body;
  final String? etag;

  Map<String, dynamic> toJson() => {'body': body, 'etag': etag};

  factory _CachedResponse.fromJson(Map<String, dynamic> json) =>
      _CachedResponse(
        body: json['body'] as String,
        etag: json['etag'] as String?,
      );
}
