import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_wallet/class/money.dart';
import 'package:easy_wallet/managers/subscription_catalog_service.dart';
import 'package:easy_wallet/model/subscription_template.dart';
import 'package:easy_wallet/provider/currency_provider.dart';
import 'package:easy_wallet/views/components/gradient_header.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

/// What the user picked out of the catalog: the service, and the tariff whose
/// price should be filled in. The plan is null when the service has no price
/// on file — name and website are still worth having.
class TemplateSelection {
  const TemplateSelection({required this.template, this.plan});

  final SubscriptionTemplate template;
  final TemplatePlan? plan;
}

/// Lets the user pick a known service instead of typing its name, address and
/// price by hand.
///
/// Pops with a [TemplateSelection], or with null when the user backs out — in
/// which case the create form stays exactly as they left it.
class TemplatePickerView extends StatefulWidget {
  const TemplatePickerView({super.key, this.service});

  /// Injectable for tests; the view builds its own otherwise.
  final SubscriptionCatalogService? service;

  @override
  State<TemplatePickerView> createState() => TemplatePickerViewState();
}

class TemplatePickerViewState extends State<TemplatePickerView> {
  /// Long enough that typing a word is one request rather than six, short
  /// enough that the list does not feel like it is lagging behind.
  static const Duration _debounce = Duration(milliseconds: 350);

  late final SubscriptionCatalogService _catalog =
      widget.service ?? SubscriptionCatalogService();
  final TextEditingController _searchController = TextEditingController();

  Timer? _debounceTimer;

  /// Counts the searches so a slow answer to an old query cannot overwrite the
  /// results of a newer one.
  int _searchToken = 0;

  List<SubscriptionTemplate> _templates = const [];
  bool _isLoading = true;
  bool _isFromCache = false;
  bool _isUnavailable = false;

  @override
  void initState() {
    super.initState();
    _search('');
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onQueryChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounce, () => _search(query));
  }

  Future<void> _search(String query) async {
    final token = ++_searchToken;
    setState(() => _isLoading = true);

    final result = await _catalog.search(query: query);

    if (!mounted || token != _searchToken) {
      return;
    }
    setState(() {
      _templates = result.templates;
      _isFromCache = result.isFromCache;
      _isUnavailable = result.isUnavailable;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: Column(
        children: [
          GradientHeader(
            title: Intl.message('catalogTitle'),
            showBackButton: true,
          ),
          Container(
            color: CupertinoColors.systemGroupedBackground.resolveFrom(context),
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
            child: CupertinoSearchTextField(
              controller: _searchController,
              placeholder: Intl.message('catalogSearchPlaceholder'),
              onChanged: _onQueryChanged,
            ),
          ),
          if (_isFromCache) _cachedNotice(context),
          Expanded(
            child: SafeArea(
              top: false,
              child: _body(context),
            ),
          ),
        ],
      ),
    );
  }

  /// Says the list may be out of date rather than passing stored results off
  /// as current ones.
  Widget _cachedNotice(BuildContext context) {
    return Container(
      width: double.infinity,
      color: CupertinoColors.systemGroupedBackground.resolveFrom(context),
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 8),
      child: Row(
        children: [
          const Icon(CupertinoIcons.wifi_slash,
              size: 14, color: CupertinoColors.systemGrey),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              Intl.message('catalogCachedNotice'),
              style: const TextStyle(
                  fontSize: 12, color: CupertinoColors.systemGrey),
            ),
          ),
        ],
      ),
    );
  }

  Widget _body(BuildContext context) {
    if (_isLoading && _templates.isEmpty) {
      return const Center(child: CupertinoActivityIndicator());
    }
    if (_templates.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            _emptyMessage(),
            textAlign: TextAlign.center,
            style: const TextStyle(color: CupertinoColors.systemGrey),
          ),
        ),
      );
    }

    return ListView.separated(
      itemCount: _templates.length,
      separatorBuilder: (_, _) => Container(
        margin: const EdgeInsets.only(left: 62),
        height: 0.5,
        color: CupertinoColors.separator.resolveFrom(context),
      ),
      itemBuilder: (context, index) => _templateRow(context, _templates[index]),
    );
  }

  /// Tells the three empty cases apart. A catalog that answered and holds
  /// nothing — a freshly deployed one before its import has run — must not be
  /// dressed up as a connection problem the user could act on.
  String _emptyMessage() {
    if (_isUnavailable) {
      return Intl.message('catalogEmptyOffline');
    }
    if (_searchController.text.trim().isNotEmpty) {
      return Intl.message('catalogNoResults');
    }
    return Intl.message('catalogEmpty');
  }

  Widget _templateRow(BuildContext context, SubscriptionTemplate template) {
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      onPressed: () => _pick(template),
      child: Row(
        children: [
          _icon(template),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  template.name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: CupertinoColors.label.resolveFrom(context),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  template.hasPlans
                      ? template.category.translate()
                      : '${template.category.translate()} · ${Intl.message('catalogNoPlans')}',
                  style: const TextStyle(
                      fontSize: 12, color: CupertinoColors.systemGrey),
                ),
              ],
            ),
          ),
          const Icon(CupertinoIcons.chevron_forward,
              size: 16, color: CupertinoColors.systemGrey3),
        ],
      ),
    );
  }

  Widget _icon(SubscriptionTemplate template) {
    final host = _hostOf(template.websiteUrl);
    if (host == null) {
      return const SizedBox(
        width: 36,
        height: 36,
        child: Icon(CupertinoIcons.creditcard,
            color: CupertinoColors.systemGrey, size: 28),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: CachedNetworkImage(
        imageUrl: 'https://www.google.com/s2/favicons?sz=64&domain_url=$host',
        width: 36,
        height: 36,
        fit: BoxFit.cover,
        placeholder: (_, _) => const CupertinoActivityIndicator(),
        errorWidget: (_, _, _) => const Icon(CupertinoIcons.creditcard,
            color: CupertinoColors.systemGrey, size: 28),
      ),
    );
  }

  /// Picks the service. With a single plan there is nothing to choose, so the
  /// tariff step is skipped; without any plan the price is left to the user.
  Future<void> _pick(SubscriptionTemplate template) async {
    final plans = template.plansSorted(
      preferredRegion: _deviceRegion(context),
      preferredCurrency: context.read<CurrencyProvider>().currency,
    );

    if (plans.isEmpty) {
      Navigator.of(context).pop(TemplateSelection(template: template));
      return;
    }
    if (plans.length == 1) {
      Navigator.of(context)
          .pop(TemplateSelection(template: template, plan: plans.single));
      return;
    }

    final selection = await Navigator.of(context).push<TemplateSelection>(
      CupertinoPageRoute(
        builder: (_) => _PlanPickerView(template: template, plans: plans),
      ),
    );
    if (selection != null && mounted) {
      Navigator.of(context).pop(selection);
    }
  }
}

/// The tariff step, shown only when a service is offered under more than one.
class _PlanPickerView extends StatelessWidget {
  const _PlanPickerView({required this.template, required this.plans});

  final SubscriptionTemplate template;
  final List<TemplatePlan> plans;

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: Column(
        children: [
          GradientHeader(
            title: template.name,
            showBackButton: true,
          ),
          Container(
            width: double.infinity,
            color: CupertinoColors.systemGroupedBackground.resolveFrom(context),
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
            child: Text(
              Intl.message('catalogPriceIsSuggestion'),
              style: const TextStyle(
                  fontSize: 12, color: CupertinoColors.systemGrey),
            ),
          ),
          Expanded(
            child: SafeArea(
              top: false,
              child: ListView.separated(
                itemCount: plans.length,
                separatorBuilder: (_, _) => Container(
                  margin: const EdgeInsets.only(left: 14),
                  height: 0.5,
                  color: CupertinoColors.separator.resolveFrom(context),
                ),
                itemBuilder: (context, index) => _planRow(context, plans[index]),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _planRow(BuildContext context, TemplatePlan plan) {
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      onPressed: () => Navigator.of(context)
          .pop(TemplateSelection(template: template, plan: plan)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  plan.name ?? template.name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: CupertinoColors.label.resolveFrom(context),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _subtitleOf(plan),
                  style: const TextStyle(
                      fontSize: 12, color: CupertinoColors.systemGrey),
                ),
              ],
            ),
          ),
          Text(
            '${Money.format(plan.amount, plan.currency.symbol)}/${plan.rate.translate()}',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: CupertinoColors.label.resolveFrom(context),
            ),
          ),
        ],
      ),
    );
  }

  /// Where the price applies and when it was last verified — the two things
  /// that decide whether the user should trust the number above it.
  String _subtitleOf(TemplatePlan plan) {
    final parts = <String>[
      plan.region ?? Intl.message('catalogRegionGlobal'),
    ];
    final checkedAt = plan.priceCheckedAt;
    if (checkedAt != null) {
      parts.add(
          '${Intl.message('catalogPriceFrom')} ${DateFormat.yMd().format(checkedAt)}');
    }
    return parts.join(' · ');
  }
}

/// The country the device is set to, used to float the prices that apply here
/// to the top. Null when the locale carries no country.
String? _deviceRegion(BuildContext context) {
  final country = Localizations.maybeLocaleOf(context)?.countryCode ??
      WidgetsBinding.instance.platformDispatcher.locale.countryCode;
  if (country == null || country.isEmpty) {
    return null;
  }
  return country.toUpperCase();
}

/// The host of [url], or null when there is nothing to derive an icon from.
String? _hostOf(String? url) {
  if (url == null) {
    return null;
  }
  final host = Uri.tryParse(url)?.host;
  return (host == null || host.isEmpty) ? null : host;
}
