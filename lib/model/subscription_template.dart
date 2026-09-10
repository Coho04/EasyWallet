import 'package:easy_wallet/enum/currency.dart';
import 'package:easy_wallet/enum/payment_rate.dart';
import 'package:easy_wallet/enum/template_category.dart';

/// A service from the subscription catalog, e.g. Netflix, with the tariffs it
/// is offered under.
///
/// This file is the only place that knows the wire format of the catalog API.
/// Everything downstream works on these classes, so a renamed field costs one
/// edit here and nothing anywhere else.
class SubscriptionTemplate {
  const SubscriptionTemplate({
    required this.slug,
    required this.name,
    required this.category,
    required this.plans,
    this.websiteUrl,
  });

  /// Stable identifier of the service. The only part worth persisting; the
  /// catalog deliberately does not expose its internal ids.
  final String slug;

  final String name;
  final TemplateCategory category;

  /// Homepage of the service. The app derives the icon from this, so no logo
  /// has to be shipped or hosted.
  final String? websiteUrl;

  /// The tariffs, already narrowed to the ones this app can express. May be
  /// empty: filtering by region or currency happens on the plans, not on the
  /// services, so a service can come back with nothing that fits.
  final List<TemplatePlan> plans;

  bool get hasPlans => plans.isNotEmpty;

  /// The plans, most relevant first: the ones priced for [preferredRegion],
  /// then the ones priced the same everywhere, then the rest; within each
  /// group the [preferredCurrency] leads.
  ///
  /// Only reorders, never hides. A price the user cannot see is a price they
  /// cannot correct, and every plan carries its region and currency in the
  /// list anyway.
  List<TemplatePlan> plansSorted({
    String? preferredRegion,
    Currency? preferredCurrency,
  }) {
    final region = preferredRegion?.trim().toUpperCase();

    int rankOf(TemplatePlan plan) {
      if (region != null && plan.region == region) {
        return 0;
      }
      if (plan.isGlobal) {
        return 1;
      }
      return 2;
    }

    // Decorated with the original index so plans that rank the same keep the
    // order the catalog put them in; List.sort is not stable on its own.
    final decorated = plans.indexed.toList()
      ..sort((a, b) {
        final byRank = rankOf(a.$2).compareTo(rankOf(b.$2));
        if (byRank != 0) {
          return byRank;
        }
        if (preferredCurrency != null) {
          final aPreferred = a.$2.currency == preferredCurrency ? 0 : 1;
          final bPreferred = b.$2.currency == preferredCurrency ? 0 : 1;
          if (aPreferred != bPreferred) {
            return aPreferred.compareTo(bPreferred);
          }
        }
        return a.$1.compareTo(b.$1);
      });
    return decorated.map((entry) => entry.$2).toList();
  }

  /// Reads one service. Returns null when it lacks what makes it usable — a
  /// slug and a name — so one malformed entry cannot empty the whole list.
  static SubscriptionTemplate? fromJson(Map<String, dynamic> json) {
    final slug = _nonEmptyString(json['slug']);
    final name = _nonEmptyString(json['name']);
    if (slug == null || name == null) {
      return null;
    }

    final rawPlans = json['plans'];
    final plans = <TemplatePlan>[];
    if (rawPlans is List) {
      for (final entry in rawPlans) {
        if (entry is Map<String, dynamic>) {
          final plan = TemplatePlan.fromJson(entry);
          if (plan != null) {
            plans.add(plan);
          }
        }
      }
    }

    return SubscriptionTemplate(
      slug: slug,
      name: name,
      category: TemplateCategory.findBySlug(_nonEmptyString(json['category'])),
      websiteUrl: _nonEmptyString(json['website_url']),
      plans: plans,
    );
  }

  /// The services out of a list response. Entries that cannot be read are
  /// skipped rather than thrown over: a single bad record in a catalog of
  /// hundreds must not cost the user the whole picker.
  static List<SubscriptionTemplate> listFromResponse(dynamic json) {
    if (json is! Map<String, dynamic>) {
      return const [];
    }
    final data = json['data'];
    if (data is! List) {
      return const [];
    }
    final templates = <SubscriptionTemplate>[];
    for (final entry in data) {
      if (entry is Map<String, dynamic>) {
        final template = SubscriptionTemplate.fromJson(entry);
        if (template != null) {
          templates.add(template);
        }
      }
    }
    return templates;
  }

  Map<String, dynamic> toJson() => {
        'slug': slug,
        'name': name,
        'category': category.slug,
        'website_url': websiteUrl,
        'plans': plans.map((plan) => plan.toJson()).toList(),
      };
}

/// One tariff of a [SubscriptionTemplate], e.g. Netflix Premium in Germany.
class TemplatePlan {
  const TemplatePlan({
    required this.amountMinor,
    required this.currency,
    required this.rate,
    this.name,
    this.region,
    this.sourceUrl,
    this.priceCheckedAt,
  });

  /// Name of the tariff, e.g. "Premium". Null when the service has just one.
  final String? name;

  /// The price in the smallest unit of [currency]. An integer on purpose:
  /// money never travels as a float. Use [amount] to read it.
  final int amountMinor;

  final Currency currency;
  final PaymentRate rate;

  /// Country the price applies to as ISO 3166-1 alpha-2. Null means the price
  /// is the same everywhere, not that the country is unknown.
  final String? region;

  /// Where the price was looked up. Catalog prices are researched snapshots,
  /// not live data.
  final String? sourceUrl;

  /// The day the price was last verified. Shown to the user, because a price
  /// presented as fact but months old is worse than no price at all.
  final DateTime? priceCheckedAt;

  bool get isGlobal => region == null;

  /// The price as an amount, e.g. 15.99 for 1599 EUR and 1490 for 1490 JPY.
  double get amount => currency.amountFromMinor(amountMinor);

  /// The amount written the way an amount input field can read back, e.g.
  /// "15.99" and "1490".
  ///
  /// Deliberately without grouping separators and without locale formatting:
  /// the field parses its own text again, and a German "1.490" would come
  /// back as 1.49. A dot for the decimal point is safe because the form
  /// accepts both separators.
  String get amountAsFieldText => amount.toStringAsFixed(currency.decimalDigits);

  /// Reads one tariff. Returns null when the app cannot express it: an amount
  /// that is not a whole number of minor units, a currency the app does not
  /// carry, or a billing interval it cannot store. Dropping such a tariff is
  /// the honest option — a wrong currency silently distorts the amount.
  static TemplatePlan? fromJson(Map<String, dynamic> json) {
    final amountMinor = json['amount_minor'];
    if (amountMinor is! int || amountMinor < 0) {
      return null;
    }

    final currencyCode = _nonEmptyString(json['currency']);
    if (currencyCode == null) {
      return null;
    }
    final currency = Currency.findByCode(currencyCode);
    if (currency == null) {
      return null;
    }

    final rate = _rateOf(_nonEmptyString(json['interval']));
    if (rate == null) {
      return null;
    }

    return TemplatePlan(
      name: _nonEmptyString(json['name']),
      amountMinor: amountMinor,
      currency: currency,
      rate: rate,
      region: _nonEmptyString(json['region'])?.toUpperCase(),
      sourceUrl: _nonEmptyString(json['source_url']),
      priceCheckedAt: _dateOf(_nonEmptyString(json['price_checked_at'])),
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'amount_minor': amountMinor,
        'currency': currency.code,
        'interval': rate.value,
        'region': region,
        'source_url': sourceUrl,
        'price_checked_at': priceCheckedAt?.toIso8601String(),
      };

  /// The billing interval, or null when it is one the app cannot store.
  /// [PaymentRate.findByName] falls back to monthly, which would turn a yearly
  /// price into a monthly one, so the lookup is done strictly here.
  static PaymentRate? _rateOf(String? interval) {
    if (interval == null) {
      return null;
    }
    final wanted = interval.trim().toLowerCase();
    for (final rate in PaymentRate.values) {
      if (rate.value == wanted) {
        return rate;
      }
    }
    return null;
  }

  static DateTime? _dateOf(String? value) {
    if (value == null) {
      return null;
    }
    return DateTime.tryParse(value);
  }
}

/// The trimmed string, or null when it is absent, not a string, or blank.
String? _nonEmptyString(dynamic value) {
  if (value is! String) {
    return null;
  }
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}
