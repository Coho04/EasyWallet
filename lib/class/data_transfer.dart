import 'dart:convert';

import 'package:easy_wallet/model/category.dart';
import 'package:easy_wallet/model/subscription.dart';

/// A decoded backup file.
class Backup {
  const Backup({
    required this.version,
    required this.subscriptions,
    required this.categories,
  });

  final int version;
  final List<Subscription> subscriptions;
  final List<Category> categories;
}

/// Reads and writes the backup format used for manual export and import.
///
/// Deliberately the same per-record shape the cloud sync already writes, so a
/// backup and a synced copy describe the data the same way.
class DataTransfer {
  const DataTransfer._();

  /// Raised when the format changes in a way older builds cannot read.
  static const int formatVersion = 1;

  static String encode({
    required List<Subscription> subscriptions,
    required List<Category> categories,
  }) {
    return jsonEncode({
      'version': formatVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'subscriptions': subscriptions.map((s) => s.toJson()).toList(),
      'categories': categories.map((c) => c.toJson()).toList(),
    });
  }

  /// Throws [FormatException] when the file is not a backup.
  static Backup decode(String source) {
    final dynamic raw;
    try {
      raw = jsonDecode(source);
    } on FormatException {
      rethrow;
    }

    if (raw is! Map<String, dynamic> ||
        raw['subscriptions'] is! List ||
        raw['categories'] is! List) {
      throw const FormatException('Not an EasyWallet backup');
    }

    return Backup(
      version: raw['version'] is int ? raw['version'] as int : 0,
      subscriptions: (raw['subscriptions'] as List)
          .map((e) => Subscription.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      categories: (raw['categories'] as List)
          .map((e) => Category.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}
