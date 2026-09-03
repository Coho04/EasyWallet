import 'dart:convert';

import 'package:easy_wallet/class/exchange_rates.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Fetches exchange rates from https://frankfurter.dev and keeps the last
/// answer, so the app keeps converting when it is offline.
class ExchangeRateService {
  ExchangeRateService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const String _prefsKey = 'exchangeRates';
  static const String _host = 'api.frankfurter.dev';

  /// Rates for [base]. Returns the cached ones while they are fresh, refreshes
  /// them otherwise, and falls back to whatever was cached if the request
  /// fails. Null only when nothing was ever fetched.
  Future<ExchangeRates?> ratesFor(String base, {DateTime? now}) async {
    final at = now ?? DateTime.now();
    final prefs = await SharedPreferences.getInstance();
    final cached = _readCache(prefs);

    final usable = cached != null &&
        cached.base.toUpperCase() == base.toUpperCase() &&
        !cached.isStaleAt(at);
    if (usable) {
      return cached;
    }

    try {
      final response = await _client.get(
        Uri.https(_host, '/v1/latest', {'base': base.toUpperCase()}),
      );
      if (response.statusCode != 200) {
        return cached;
      }
      final fresh = ExchangeRates.fromApi(
        jsonDecode(response.body) as Map<String, dynamic>,
        fetchedAt: at,
      );
      await prefs.setString(_prefsKey, jsonEncode(fresh.toJson()));
      return fresh;
    } catch (_) {
      // Offline or the service is down: the old rates beat no rates.
      return cached;
    }
  }

  ExchangeRates? _readCache(SharedPreferences prefs) {
    final raw = prefs.getString(_prefsKey);
    if (raw == null) {
      return null;
    }
    try {
      return ExchangeRates.fromJson(
          jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }
}
