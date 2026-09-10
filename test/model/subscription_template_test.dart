import 'dart:convert';

import 'package:easy_wallet/enum/currency.dart';
import 'package:easy_wallet/enum/payment_rate.dart';
import 'package:easy_wallet/enum/template_category.dart';
import 'package:easy_wallet/model/subscription_template.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // The example response from the catalog API contract, verbatim.
  //
  // The amounts are a snapshot of what Netflix charged when the contract was
  // written. They are fixture data, nothing more: if a real price moves, this
  // file is what is out of date, not the API. Assert on the shape here, never
  // treat a changed number as a broken contract.
  const netflixResponse = '''
{
  "data": [
    {
      "slug": "netflix",
      "name": "Netflix",
      "category": "streaming_video",
      "website_url": "https://www.netflix.com",
      "plans": [
        {
          "name": "Standard mit Werbung",
          "amount_minor": 699,
          "currency": "EUR",
          "interval": "monthly",
          "region": "DE",
          "source_url": "https://help.netflix.com/de/node/24926",
          "price_checked_at": "2026-09-09"
        },
        {
          "name": "Premium",
          "amount_minor": 2199,
          "currency": "EUR",
          "interval": "monthly",
          "region": "DE",
          "source_url": "https://help.netflix.com/de/node/24926",
          "price_checked_at": "2026-09-09"
        }
      ],
      "updated_at": "2026-09-09T10:00:00+00:00"
    }
  ],
  "links": {"first": "…", "last": "…", "prev": null, "next": null},
  "meta": {"current_page": 1, "per_page": 25, "total": 1, "last_page": 1}
}
''';

  Map<String, dynamic> decode(String source) =>
      jsonDecode(source) as Map<String, dynamic>;

  group('SubscriptionTemplate.listFromResponse', () {
    test('reads the services of a paginated response', () {
      final templates =
          SubscriptionTemplate.listFromResponse(decode(netflixResponse));

      expect(templates, hasLength(1));
      final netflix = templates.single;
      expect(netflix.slug, 'netflix');
      expect(netflix.name, 'Netflix');
      expect(netflix.category, TemplateCategory.streamingVideo);
      expect(netflix.websiteUrl, 'https://www.netflix.com');
      expect(netflix.plans, hasLength(2));
      expect(netflix.hasPlans, isTrue);
    });

    test('reads a plan with its price, currency and interval', () {
      final netflix =
          SubscriptionTemplate.listFromResponse(decode(netflixResponse)).single;
      final premium = netflix.plans.last;

      expect(premium.name, 'Premium');
      expect(premium.amountMinor, 2199);
      expect(premium.amount, closeTo(21.99, 0.001));
      expect(premium.currency, Currency.eur);
      expect(premium.rate, PaymentRate.monthly);
      expect(premium.region, 'DE');
      expect(premium.isGlobal, isFalse);
      expect(premium.priceCheckedAt, DateTime(2026, 9, 9));
      expect(premium.sourceUrl, 'https://help.netflix.com/de/node/24926');
    });

    test('returns nothing for a response that is not shaped like one', () {
      expect(SubscriptionTemplate.listFromResponse(decode('{}')), isEmpty);
      expect(SubscriptionTemplate.listFromResponse(decode('{"data": {}}')),
          isEmpty);
      expect(SubscriptionTemplate.listFromResponse('not json at all'), isEmpty);
      expect(SubscriptionTemplate.listFromResponse(null), isEmpty);
    });

    test('skips a malformed service instead of losing the whole list', () {
      final templates = SubscriptionTemplate.listFromResponse(decode('''
{"data": [
  {"name": "No slug", "plans": []},
  {"slug": "spotify", "name": "Spotify", "category": "streaming_music",
   "website_url": "https://www.spotify.com", "plans": []},
  {"slug": "no-name", "plans": []}
]}'''));

      expect(templates.map((t) => t.slug), ['spotify']);
    });
  });

  group('SubscriptionTemplate.fromJson', () {
    test('accepts a service whose plans do not fit the requested filter', () {
      // Filtering by region narrows the plans, not the services, so an empty
      // plan array is a normal answer and not a reason to drop the service.
      final template = SubscriptionTemplate.fromJson(decode('''
{"slug": "dropbox", "name": "Dropbox", "category": "cloud_storage",
 "website_url": "https://www.dropbox.com", "plans": []}'''));

      expect(template, isNotNull);
      expect(template!.plans, isEmpty);
      expect(template.hasPlans, isFalse);
    });

    test('survives a missing plans key', () {
      final template = SubscriptionTemplate.fromJson(
          decode('{"slug": "s", "name": "S", "category": "software"}'));

      expect(template, isNotNull);
      expect(template!.plans, isEmpty);
    });

    test('falls back to other for a category this version does not know', () {
      final template = SubscriptionTemplate.fromJson(decode('''
{"slug": "x", "name": "X", "category": "pet_insurance", "plans": []}'''));

      expect(template!.category, TemplateCategory.other);
    });

    test('keeps a service without a website, the icon is what is lost', () {
      final template = SubscriptionTemplate.fromJson(
          decode('{"slug": "x", "name": "X", "plans": []}'));

      expect(template, isNotNull);
      expect(template!.websiteUrl, isNull);
    });
  });

  group('TemplatePlan.fromJson', () {
    TemplatePlan? plan(String source) =>
        TemplatePlan.fromJson(decode(source));

    test('reads an amount in minor units with the currency decimals', () {
      expect(
        plan('{"amount_minor": 1599, "currency": "EUR", "interval": "monthly"}')!
            .amount,
        closeTo(15.99, 0.001),
      );
    });

    test('does not divide a currency that has no minor unit', () {
      // 1490 JPY is 1490 yen, not 14.90. Hardcoding /100 would be wrong here.
      final japanese =
          plan('{"amount_minor": 1490, "currency": "JPY", "interval": "monthly"}')!;

      expect(japanese.currency, Currency.jpy);
      expect(japanese.amount, 1490);
    });

    test('drops a plan in a currency the app cannot store', () {
      expect(
        plan('{"amount_minor": 500, "currency": "KWD", "interval": "monthly"}'),
        isNull,
      );
    });

    test('drops a plan whose interval the app cannot store', () {
      // A weekly price silently stored as monthly would be a wrong number in
      // every total the app shows.
      expect(
        plan('{"amount_minor": 500, "currency": "EUR", "interval": "weekly"}'),
        isNull,
      );
      expect(
        plan('{"amount_minor": 500, "currency": "EUR", "interval": "quarterly"}'),
        isNull,
      );
    });

    test('drops a plan without a usable amount', () {
      expect(plan('{"currency": "EUR", "interval": "monthly"}'), isNull);
      expect(
        plan('{"amount_minor": "1599", "currency": "EUR", "interval": "monthly"}'),
        isNull,
      );
      expect(
        plan('{"amount_minor": 15.99, "currency": "EUR", "interval": "monthly"}'),
        isNull,
      );
      expect(
        plan('{"amount_minor": -100, "currency": "EUR", "interval": "monthly"}'),
        isNull,
      );
    });

    test('reads a null region as a price that applies everywhere', () {
      final global = plan(
          '{"amount_minor": 999, "currency": "USD", "interval": "yearly", "region": null}')!;

      expect(global.region, isNull);
      expect(global.isGlobal, isTrue);
      expect(global.rate, PaymentRate.yearly);
    });

    test('leaves a nameless plan nameless', () {
      expect(
        plan('{"amount_minor": 999, "currency": "EUR", "interval": "monthly"}')!
            .name,
        isNull,
      );
    });

    test('ignores an unparsable checked-at date rather than failing', () {
      expect(
        plan('''
{"amount_minor": 999, "currency": "EUR", "interval": "monthly",
 "price_checked_at": "gestern"}''')!
            .priceCheckedAt,
        isNull,
      );
    });

    test('is forgiving about the case of codes and intervals', () {
      final relaxed = plan('''
{"amount_minor": 999, "currency": "eur", "interval": "MONTHLY", "region": "de"}''')!;

      expect(relaxed.currency, Currency.eur);
      expect(relaxed.rate, PaymentRate.monthly);
      expect(relaxed.region, 'DE');
    });
  });

  group('round trip', () {
    test('a template survives being written and read again', () {
      final original =
          SubscriptionTemplate.listFromResponse(decode(netflixResponse)).single;
      final restored = SubscriptionTemplate.fromJson(
          jsonDecode(jsonEncode(original.toJson())) as Map<String, dynamic>)!;

      expect(restored.slug, original.slug);
      expect(restored.name, original.name);
      expect(restored.category, original.category);
      expect(restored.websiteUrl, original.websiteUrl);
      expect(restored.plans, hasLength(original.plans.length));
      expect(restored.plans.first.amountMinor, original.plans.first.amountMinor);
      expect(restored.plans.first.currency, original.plans.first.currency);
      expect(restored.plans.first.rate, original.plans.first.rate);
      expect(restored.plans.first.region, original.plans.first.region);
      expect(
          restored.plans.first.priceCheckedAt, original.plans.first.priceCheckedAt);
    });
  });

  group('SubscriptionTemplate.plansSorted', () {
    TemplatePlan plan(String name, {String? region, Currency? currency}) =>
        TemplatePlan(
          name: name,
          amountMinor: 999,
          currency: currency ?? Currency.eur,
          rate: PaymentRate.monthly,
          region: region,
        );

    SubscriptionTemplate withPlans(List<TemplatePlan> plans) =>
        SubscriptionTemplate(
          slug: 's',
          name: 'S',
          category: TemplateCategory.other,
          plans: plans,
        );

    test('puts the plans for the preferred region first', () {
      final sorted = withPlans([
        plan('AT', region: 'AT'),
        plan('global'),
        plan('DE', region: 'DE'),
      ]).plansSorted(preferredRegion: 'DE');

      expect(sorted.map((p) => p.name), ['DE', 'global', 'AT']);
    });

    test('puts worldwide prices ahead of other countries', () {
      final sorted = withPlans([
        plan('US', region: 'US'),
        plan('global'),
      ]).plansSorted(preferredRegion: 'DE');

      expect(sorted.map((p) => p.name), ['global', 'US']);
    });

    test('prefers the currency the user works in, within a group', () {
      final sorted = withPlans([
        plan('usd', region: 'DE', currency: Currency.usd),
        plan('eur', region: 'DE', currency: Currency.eur),
      ]).plansSorted(preferredRegion: 'DE', preferredCurrency: Currency.eur);

      expect(sorted.map((p) => p.name), ['eur', 'usd']);
    });

    test('keeps the order the catalog chose for equally relevant plans', () {
      // The provider lists its own tiers in a meaningful order; nothing here
      // is a good enough reason to shuffle them.
      final sorted = withPlans([
        plan('Standard mit Werbung', region: 'DE'),
        plan('Standard', region: 'DE'),
        plan('Premium', region: 'DE'),
      ]).plansSorted(preferredRegion: 'DE');

      expect(sorted.map((p) => p.name),
          ['Standard mit Werbung', 'Standard', 'Premium']);
    });

    test('never drops a plan', () {
      final all = withPlans([
        plan('a', region: 'US'),
        plan('b'),
        plan('c', region: 'DE'),
      ]);

      expect(all.plansSorted(preferredRegion: 'DE'), hasLength(3));
      expect(all.plansSorted(), hasLength(3));
    });

    test('works without a preferred region', () {
      final sorted = withPlans([
        plan('DE', region: 'DE'),
        plan('global'),
      ]).plansSorted();

      expect(sorted.map((p) => p.name), ['global', 'DE']);
    });

    test('matches the region regardless of how it is written', () {
      final sorted = withPlans([
        plan('global'),
        plan('DE', region: 'DE'),
      ]).plansSorted(preferredRegion: ' de ');

      expect(sorted.first.name, 'DE');
    });
  });

  group('TemplatePlan.amountAsFieldText', () {
    TemplatePlan priced(int minor, Currency currency) => TemplatePlan(
          amountMinor: minor,
          currency: currency,
          rate: PaymentRate.monthly,
        );

    test('writes an amount the form can read back', () {
      expect(priced(1599, Currency.eur).amountAsFieldText, '15.99');
      expect(priced(699, Currency.eur).amountAsFieldText, '6.99');
    });

    test('writes a currency without minor units as a whole number', () {
      expect(priced(1490, Currency.jpy).amountAsFieldText, '1490');
    });

    test('never groups thousands', () {
      // "1.490" would be parsed back as 1.49, "1,490" as 1.49 as well since
      // the form swaps commas for dots.
      final text = priced(149000, Currency.eur).amountAsFieldText;

      expect(text, '1490.00');
      expect(double.parse(text.replaceAll(',', '.')), 1490.0);
    });

    test('round trips through the parsing the form does', () {
      for (final plan in [
        priced(1599, Currency.eur),
        priced(1490, Currency.jpy),
        priced(0, Currency.usd),
        priced(999999, Currency.gbp),
      ]) {
        expect(
          double.parse(plan.amountAsFieldText.replaceAll(',', '.')),
          closeTo(plan.amount, 0.001),
        );
      }
    });
  });

  group('plans that differ only by interval', () {
    // Verbatim from the running catalog: Disney+ offers "Standard" and
    // "Premium" both monthly and yearly. Keying plans by name anywhere would
    // silently swallow the yearly ones.
    const disneyResponse = '''
{"data": [{
  "slug": "disney-plus",
  "name": "Disney+",
  "category": "streaming_video",
  "website_url": "https://www.disneyplus.com",
  "plans": [
    {"name":"Standard mit Werbung","amount_minor":699,"currency":"EUR","interval":"monthly","region":"DE","source_url":"https://www.disneyplus.com/de-de","price_checked_at":"2026-09-09"},
    {"name":"Standard","amount_minor":1099,"currency":"EUR","interval":"monthly","region":"DE","source_url":"https://www.disneyplus.com/de-de","price_checked_at":"2026-09-09"},
    {"name":"Premium","amount_minor":1599,"currency":"EUR","interval":"monthly","region":"DE","source_url":"https://www.disneyplus.com/de-de","price_checked_at":"2026-09-09"},
    {"name":"Standard","amount_minor":10990,"currency":"EUR","interval":"yearly","region":"DE","source_url":"https://www.disneyplus.com/de-de","price_checked_at":"2026-09-09"},
    {"name":"Premium","amount_minor":15990,"currency":"EUR","interval":"yearly","region":"DE","source_url":"https://www.disneyplus.com/de-de","price_checked_at":"2026-09-09"}
  ],
  "updated_at": "2026-09-09T12:15:22+00:00"
}],
"links": {"first":"...","last":"...","prev":null,"next":null},
"meta": {"current_page":1,"per_page":25,"total":1,"last_page":1,"catalog_updated_at":"2026-09-09T12:15:22+00:00"}}
''';

    test('keeps every plan, repeated names and all', () {
      final disney =
          SubscriptionTemplate.listFromResponse(decode(disneyResponse)).single;

      expect(disney.plans, hasLength(5));
      expect(
        disney.plans.where((p) => p.name == 'Standard'),
        hasLength(2),
      );
      expect(
        disney.plans.where((p) => p.name == 'Premium'),
        hasLength(2),
      );
    });

    test('tells the monthly and the yearly plan of a name apart', () {
      final disney =
          SubscriptionTemplate.listFromResponse(decode(disneyResponse)).single;
      final standard =
          disney.plans.where((p) => p.name == 'Standard').toList();

      final monthly =
          standard.firstWhere((p) => p.rate == PaymentRate.monthly);
      final yearly = standard.firstWhere((p) => p.rate == PaymentRate.yearly);

      expect(monthly.amount, closeTo(10.99, 0.001));
      expect(yearly.amount, closeTo(109.90, 0.001));
    });

    test('sorting does not collapse plans sharing a name', () {
      final disney =
          SubscriptionTemplate.listFromResponse(decode(disneyResponse)).single;

      expect(disney.plansSorted(preferredRegion: 'DE'), hasLength(5));
      expect(disney.plansSorted(), hasLength(5));
    });

    test('reads the fields the catalog actually sends', () {
      // Shape, not amounts: the prices are a snapshot and may move.
      final disney =
          SubscriptionTemplate.listFromResponse(decode(disneyResponse)).single;

      expect(disney.slug, 'disney-plus');
      expect(disney.category, TemplateCategory.streamingVideo);
      expect(disney.websiteUrl, 'https://www.disneyplus.com');
      for (final plan in disney.plans) {
        expect(plan.name, isNotNull);
        expect(plan.amountMinor, greaterThan(0));
        expect(plan.currency, Currency.eur);
        expect(plan.region, 'DE');
        expect(plan.sourceUrl, isNotNull);
        expect(plan.priceCheckedAt, isNotNull);
      }
    });
  });
}
