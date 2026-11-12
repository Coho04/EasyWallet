import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';

/// Where a chosen icon comes from.
enum IconKind {
  symbol('symbol'),
  emoji('emoji'),
  image('image');

  const IconKind(this.value);

  /// What is stored in the `iconType` column and in backups.
  final String value;

  static IconKind? findByValue(String? value) {
    for (final kind in values) {
      if (kind.value == value) return kind;
    }
    return null;
  }
}

/// The address of the favicon the app shows for a website.
///
/// The one place this URL is assembled; the subscription model, the form
/// previews and the catalog all used to spell it out on their own.
String faviconUrlFor(String url) {
  return 'https://www.google.com/s2/favicons?sz=64&domain_url=${Uri.parse(url).host}';
}

/// An icon the user picked explicitly instead of the website favicon.
///
/// Stored as three plain values ([type], [value], [color]) so it travels
/// through the database, backups and cloud sync like every other field. The
/// raw [type] is kept even when this build does not know it: a subscription
/// synced from a newer version must not lose its icon by passing through an
/// older one.
@immutable
class SubscriptionIcon {
  SubscriptionIcon({required this.type, required this.value, this.color});

  /// A symbol from [iconSymbols], drawn in [color].
  SubscriptionIcon.symbol(String key, Color color)
    : this(type: IconKind.symbol.value, value: key, color: color.toARGB32());

  /// A single emoji or other character.
  SubscriptionIcon.emoji(String emoji)
    : this(type: IconKind.emoji.value, value: emoji);

  /// A small picture, already downscaled. Embedded as Base64 rather than kept
  /// as a file, so it survives export, iCloud and Google Drive without any of
  /// them having to know about files.
  SubscriptionIcon.image(Uint8List bytes)
    : this(type: IconKind.image.value, value: base64Encode(bytes));

  final String type;

  /// The symbol key, the emoji, or the Base64 encoded picture.
  final String value;

  /// ARGB colour of a symbol. Unused for the other kinds.
  final int? color;

  /// Reads the icon from a subscription row or backup record. Null when the
  /// record carries none, which is every record written before icons existed.
  static SubscriptionIcon? fromJson(Map<String, dynamic> json) {
    final type = json['iconType'];
    final value = json['iconValue'];
    if (type is! String || type.isEmpty || value is! String || value.isEmpty) {
      return null;
    }
    final color = json['iconColor'];
    return SubscriptionIcon(
      type: type,
      value: value,
      color: color is int ? color : int.tryParse(color?.toString() ?? ''),
    );
  }

  IconKind? get kind => IconKind.findByValue(type);

  /// The glyph of a symbol icon. Null for other kinds and for keys this build
  /// does not ship.
  IconData? get symbol => kind == IconKind.symbol ? iconSymbols[value] : null;

  Color get symbolColor => Color(color ?? _defaultSymbolColor);

  /// The decoded picture of an image icon, or null if there is none or it is
  /// damaged. Decoded once per instance, not on every rebuild of a list row.
  late final Uint8List? imageBytes = _decodeImage();

  Uint8List? _decodeImage() {
    if (kind != IconKind.image) return null;
    try {
      return base64Decode(value);
    } on FormatException {
      return null;
    }
  }

  /// Whether this build can draw the icon. When it cannot, the subscription
  /// falls back to its website favicon as if nothing had been chosen.
  bool get isRenderable {
    switch (kind) {
      case IconKind.symbol:
        return symbol != null;
      case IconKind.emoji:
        return value.trim().isNotEmpty;
      case IconKind.image:
        return imageBytes != null && imageBytes!.isNotEmpty;
      case null:
        return false;
    }
  }

  /// File extension matching [imageBytes], for handing them to the widget.
  String get imageExtension {
    final bytes = imageBytes;
    final isPng =
        bytes != null &&
        bytes.length >= 4 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47;
    return isPng ? 'png' : 'jpg';
  }

  /// Identifies this icon in colour caches, the way the favicon URL does for
  /// icons from a website.
  String get cacheKey => switch (kind) {
    IconKind.image => 'image:${value.length}:${value.hashCode}',
    _ => '$type:$value:${color ?? ''}',
  };

  /// The colour a subscription with this icon is drawn in.
  ///
  /// A symbol has the colour the user picked with it. A picture gets its
  /// dominant colour, like a favicon. An emoji has no single colour worth
  /// taking, so it gets [fallback].
  Future<Color> accentColor({Color fallback = Colors.grey}) async {
    switch (kind) {
      case IconKind.symbol:
        return symbolColor;
      case IconKind.image:
        final bytes = imageBytes;
        if (bytes == null) return fallback;
        try {
          final palette = await PaletteGenerator.fromImageProvider(
            MemoryImage(bytes),
          );
          return palette.dominantColor?.color ?? fallback;
        } catch (_) {
          return fallback;
        }
      case IconKind.emoji:
      case null:
        return fallback;
    }
  }

  @override
  bool operator ==(Object other) =>
      other is SubscriptionIcon &&
      other.type == type &&
      other.value == value &&
      other.color == color;

  @override
  int get hashCode => Object.hash(type, value, color);
}

/// systemBlue, the colour a symbol gets until the user picks another.
const int _defaultSymbolColor = 0xFF007AFF;

/// The symbols a user can pick from, by the key that is stored.
///
/// Stored by key and not by code point on purpose: release builds strip every
/// glyph from the icon fonts that is not referenced by a constant, so an
/// `IconData` rebuilt from a stored code point would draw nothing. A key that
/// is not in here any more simply makes the subscription fall back to its
/// favicon. Keys must therefore never be renamed; append new ones instead.
const Map<String, IconData> iconSymbols = {
  // Streaming and entertainment
  'tv': Icons.tv_rounded,
  'movie': Icons.movie_rounded,
  'play': Icons.play_circle_rounded,
  'live_tv': Icons.live_tv_rounded,
  'music': Icons.music_note_rounded,
  'headphones': Icons.headphones_rounded,
  'radio': Icons.radio_rounded,
  'podcast': Icons.podcasts_rounded,
  'gaming': Icons.sports_esports_rounded,
  'book': Icons.menu_book_rounded,
  'news': Icons.newspaper_rounded,
  'magazine': Icons.auto_stories_rounded,
  // Software and cloud
  'cloud': Icons.cloud_rounded,
  'storage': Icons.storage_rounded,
  'apps': Icons.apps_rounded,
  'code': Icons.code_rounded,
  'ai': Icons.auto_awesome_rounded,
  'design': Icons.brush_rounded,
  'photo': Icons.photo_camera_rounded,
  'email': Icons.email_rounded,
  'security': Icons.shield_rounded,
  'vpn': Icons.vpn_lock_rounded,
  // Phone and internet
  'phone': Icons.smartphone_rounded,
  'internet': Icons.wifi_rounded,
  'router': Icons.router_rounded,
  // Money and insurance
  'insurance': Icons.health_and_safety_rounded,
  'bank': Icons.account_balance_rounded,
  'card': Icons.credit_card_rounded,
  'wallet': Icons.account_balance_wallet_rounded,
  'savings': Icons.savings_rounded,
  'invest': Icons.trending_up_rounded,
  'receipt': Icons.receipt_long_rounded,
  // Mobility
  'car': Icons.directions_car_rounded,
  'fuel': Icons.local_gas_station_rounded,
  'charging': Icons.ev_station_rounded,
  'transit': Icons.directions_transit_rounded,
  'bike': Icons.pedal_bike_rounded,
  'flight': Icons.flight_rounded,
  'parking': Icons.local_parking_rounded,
  // Health and fitness
  'fitness': Icons.fitness_center_rounded,
  'sports': Icons.sports_soccer_rounded,
  'health': Icons.favorite_rounded,
  'medical': Icons.medical_services_rounded,
  'pharmacy': Icons.medication_rounded,
  // Shopping and food
  'shopping': Icons.shopping_cart_rounded,
  'bag': Icons.shopping_bag_rounded,
  'delivery': Icons.local_shipping_rounded,
  'food': Icons.restaurant_rounded,
  'coffee': Icons.local_cafe_rounded,
  // Home
  'home': Icons.home_rounded,
  'electricity': Icons.bolt_rounded,
  'water': Icons.water_drop_rounded,
  'heating': Icons.local_fire_department_rounded,
  'rent': Icons.key_rounded,
  'cleaning': Icons.cleaning_services_rounded,
  // Learning, family and the rest
  'education': Icons.school_rounded,
  'language': Icons.translate_rounded,
  'pets': Icons.pets_rounded,
  'child': Icons.child_care_rounded,
  'gift': Icons.card_giftcard_rounded,
  'charity': Icons.volunteer_activism_rounded,
  'club': Icons.groups_rounded,
  'work': Icons.work_rounded,
  'travel': Icons.luggage_rounded,
  'star': Icons.star_rounded,
};
