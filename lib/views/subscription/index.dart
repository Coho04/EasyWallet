import 'dart:async';

import 'package:easy_wallet/easy_wallet_app.dart';
import 'package:easy_wallet/enum/payment_rate.dart';
import 'package:easy_wallet/enum/sort_option.dart';
import 'package:easy_wallet/model/subscription.dart';
import 'package:easy_wallet/persistence_controller.dart';
import 'package:easy_wallet/provider/category_provider.dart';
import 'package:easy_wallet/provider/currency_provider.dart';
import 'package:easy_wallet/provider/subscription_provider.dart';
import 'package:easy_wallet/views/components/subscription_header.dart';
import 'package:easy_wallet/views/components/subscription_list_component.dart';
import 'package:easy_wallet/views/components/upcoming_strip.dart';
import 'package:easy_wallet/views/subscription/create.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SubscriptionIndexView extends StatefulWidget {
  const SubscriptionIndexView({super.key});

  @override
  SubscriptionIndexViewState createState() => SubscriptionIndexViewState();
}

class SubscriptionIndexViewState extends State<SubscriptionIndexView> {
  String _searchText = '';
  SortOption _sortOption = SortOption.remainingDaysAscending;
  bool _isLoading = true;
  bool _displayCategories = true;
  double _monthlyLimit = 0.0;
  final Map<String, Color> _colorCache = {};
  Timer? _debounce;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    _displayCategories = prefs.getBool('displayCategories') ?? true;
    _monthlyLimit = prefs.getDouble('monthlyLimit') ?? 0.0;

    if (prefs.getBool('syncWithGoogleDrive') ?? false) {
      final cloud = await PersistenceController.instance.googleDrive;
      await cloud.syncFrom();
    }

    if (!mounted) return;
    final subP = Provider.of<SubscriptionProvider>(context, listen: false);
    final curP = Provider.of<CurrencyProvider>(context, listen: false);
    final catP = Provider.of<CategoryProvider>(context, listen: false);
    await subP.loadSubscriptions();
    await curP.loadCurrency();
    await catP.loadCategories();

    setState(() => _isLoading = false);
  }

  Future<Color> _accentColor(Subscription sub) async {
    final key = sub.getFaviconUrl();
    if (_colorCache.containsKey(key)) return _colorCache[key]!;
    final color = await sub.getDominantColorFromUrl(customUrl: key);
    _colorCache[key] = color;
    return color;
  }

  List<Subscription> _sorted(List<Subscription> subs) {
    final filtered = subs.where((s) =>
        s.title.toLowerCase().contains(_searchText.toLowerCase())).toList();

    filtered.sort((a, b) {
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;
      if (a.isPaused && !b.isPaused) return 1;
      if (!a.isPaused && b.isPaused) return -1;
      switch (_sortOption) {
        case SortOption.alphabeticalAscending:
          return a.title.compareTo(b.title);
        case SortOption.alphabeticalDescending:
          return b.title.compareTo(a.title);
        case SortOption.costAscending:
          return a.amount.compareTo(b.amount);
        case SortOption.costDescending:
          return b.amount.compareTo(a.amount);
        case SortOption.remainingDaysAscending:
          return a.remainingDays().compareTo(b.remainingDays());
        case SortOption.remainingDaysDescending:
          return b.remainingDays().compareTo(a.remainingDays());
      }
    });
    return filtered;
  }

  double _calcMonthly(List<Subscription> subs) {
    final now = DateTime.now();
    return subs.where((s) {
      if (s.isPaused) return false;
      final next = s.getNextBillDate();
      return next.month == now.month && next.year == now.year;
    }).fold(0.0, (sum, s) => sum + s.amount);
  }

  double _calcYearly(List<Subscription> subs) {
    final now = DateTime.now();
    final endOfYear = DateTime(now.year, 12, 31);
    double total = 0.0;
    for (final s in subs) {
      if (s.isPaused) continue;
      DateTime next = s.getNextBillDate();
      if (s.repeatPattern == PaymentRate.yearly.value) {
        if (next.year == now.year) total += s.amount;
      } else if (s.repeatPattern == PaymentRate.monthly.value) {
        while (next.isBefore(endOfYear.add(const Duration(days: 1)))) {
          total += s.amount;
          next = DateTime(next.year, next.month + 1, next.day);
        }
      }
    }
    return total;
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 200), () {
      setState(() => _searchText = value);
    });
  }

  void _togglePin(Subscription sub) {
    sub.isPinned = !sub.isPinned;
    Provider.of<SubscriptionProvider>(context, listen: false)
        .saveSubscription(sub);
  }

  void _togglePause(Subscription sub) {
    sub.isPaused = !sub.isPaused;
    Provider.of<SubscriptionProvider>(context, listen: false)
        .saveSubscription(sub);
  }

  void _delete(Subscription sub) {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Löschen?'),
        content: Text('"${sub.title}" wird unwiderruflich gelöscht.'),
        actions: [
          CupertinoDialogAction(
            child: const Text('Abbrechen'),
            onPressed: () => Navigator.pop(ctx),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.pop(ctx);
              Provider.of<SubscriptionProvider>(context, listen: false)
                  .deleteSubscription(sub);
            },
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
  }

  void _showSortSheet() {
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: Text(
          Intl.message('sortOptions'),
          style: EasyWalletApp.responsiveTextStyle(ctx,
              color: CupertinoColors.systemGrey),
        ),
        actions: SortOption.values
            .map((opt) => CupertinoActionSheetAction(
                  onPressed: () {
                    setState(() => _sortOption = opt);
                    Navigator.pop(ctx);
                  },
                  child: Text(
                    opt.translate(),
                    style: EasyWalletApp.responsiveTextStyle(ctx,
                        color: CupertinoColors.activeBlue),
                  ),
                ))
            .toList(),
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(ctx),
          child: Text(
            Intl.message('cancel'),
            style: EasyWalletApp.responsiveTextStyle(ctx,
                color: CupertinoColors.systemGrey),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<SubscriptionProvider, CurrencyProvider>(
      builder: (context, subProvider, currProvider, _) {
        final currency = currProvider.currency;
        final sorted = _sorted(subProvider.subscriptions);
        final monthly = _calcMonthly(subProvider.subscriptions);
        final yearly = _calcYearly(subProvider.subscriptions);
        final upcoming = sorted
            .where((s) => !s.isPaused && s.remainingDays() <= 7)
            .toList();

        return CupertinoPageScaffold(
          child: CustomScrollView(
            slivers: [
              // Fixed header (not in sliver — use SliverToBoxAdapter)
              SliverToBoxAdapter(
                child: SubscriptionHeader(
                  monthlySpent: monthly,
                  yearlySpent: yearly,
                  currencySymbol: currency.symbol,
                  budgetLimit: _monthlyLimit > 0 ? _monthlyLimit : null,
                  onSortTap: _showSortSheet,
                  onAddTap: () => Navigator.push(
                    context,
                    CupertinoPageRoute(
                      builder: (_) => const SubscriptionCreateView(),
                    ),
                  ).then((_) => _init()),
                ),
              ),
              // Search bar
              SliverToBoxAdapter(
                child: Container(
                  color: CupertinoColors.systemGroupedBackground
                      .resolveFrom(context),
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
                  child: CupertinoSearchTextField(
                    controller: _searchController,
                    placeholder: Intl.message('search'),
                    onChanged: _onSearchChanged,
                  ),
                ),
              ),
              // Upcoming strip
              if (upcoming.isNotEmpty)
                SliverToBoxAdapter(
                  child: UpcomingStrip(
                    upcomingSubscriptions: upcoming,
                    currencySymbol: currency.symbol,
                  ),
                ),
              // Section header
              SliverToBoxAdapter(
                child: Container(
                  color: CupertinoColors.systemGroupedBackground
                      .resolveFrom(context),
                  padding: const EdgeInsets.fromLTRB(14, 6, 14, 2),
                  child: const Text(
                    'ALLE ABONNEMENTS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: CupertinoColors.label,
                    ),
                  ),
                ),
              ),
              // List
              if (_isLoading)
                const SliverFillRemaining(
                  child: Center(child: CupertinoActivityIndicator()),
                )
              else if (sorted.isEmpty)
                SliverFillRemaining(child: _emptyState())
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final sub = sorted[index];
                      return FutureBuilder<Color>(
                        future: _accentColor(sub),
                        builder: (context, snap) => SubscriptionListComponent(
                          subscription: sub,
                          currency: currency,
                          displayCategories: _displayCategories,
                          accentColor: snap.data,
                          onTogglePin: () => _togglePin(sub),
                          onTogglePause: () => _togglePause(sub),
                          onDelete: () => _delete(sub),
                        ),
                      );
                    },
                    childCount: sorted.length,
                  ),
                ),
              const SliverPadding(padding: EdgeInsets.only(bottom: 85)),
            ],
          ),
        );
      },
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            Intl.message('noSubscriptionsAvailable'),
            style: const TextStyle(color: CupertinoColors.systemGrey),
          ),
          const SizedBox(height: 16),
          CupertinoButton.filled(
            onPressed: () => Navigator.push(
              context,
              CupertinoPageRoute(
                builder: (_) => const SubscriptionCreateView(),
              ),
            ).then((_) => _init()),
            child: Text(
              Intl.message('addNewSubscription'),
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: CupertinoColors.white),
            ),
          ),
        ],
      ),
    );
  }
}
