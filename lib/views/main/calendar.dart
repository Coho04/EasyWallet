import 'package:easy_wallet/class/money.dart';
import 'package:easy_wallet/class/billing_schedule.dart';
import 'package:easy_wallet/model/category.dart' as category;
import 'package:easy_wallet/provider/currency_provider.dart';
import 'package:easy_wallet/provider/subscription_provider.dart';
import 'package:easy_wallet/views/components/day_billing_list.dart';
import 'package:easy_wallet/views/components/month_grid.dart';
import 'package:easy_wallet/views/subscription/show.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../generated/l10n.dart';

/// Shows on which day each subscription is billed. Everything is derived from
/// the subscriptions themselves, the calendar stores nothing of its own.
class CalendarView extends StatefulWidget {
  const CalendarView({super.key});

  @override
  CalendarViewState createState() => CalendarViewState();
}

class CalendarViewState extends State<CalendarView> {
  late DateTime _visibleMonth;
  late DateTime _selectedDay;
  Map<int, List<category.Category>> _categoriesBySubscription = {};

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    _visibleMonth = DateTime(today.year, today.month, 1);
    _selectedDay = DateTime(today.year, today.month, today.day);
    _load();
  }

  /// Loads everything the calendar shows. Tabs are built lazily, so this view
  /// cannot rely on another tab having filled the providers.
  Future<void> _load() async {
    final subscriptionProvider = context.read<SubscriptionProvider>();
    final currencyProvider = context.read<CurrencyProvider>();

    await subscriptionProvider.loadSubscriptions();
    await currencyProvider.loadCurrency();
    final categories = await category.Category.forAllSubscriptions();

    if (!mounted) return;
    setState(() => _categoriesBySubscription = categories);
  }

  void _showMonth(int offset) {
    setState(() {
      _visibleMonth =
          DateTime(_visibleMonth.year, _visibleMonth.month + offset, 1);
      final today = DateTime.now();
      final showsCurrentMonth = _visibleMonth.year == today.year &&
          _visibleMonth.month == today.month;
      _selectedDay = showsCurrentMonth
          ? DateTime(today.year, today.month, today.day)
          : _visibleMonth;
    });
  }

  /// A day marker: the subscription's icon, ringed in the colour of its first
  /// category so both what and which category stay readable at this size.
  /// Without a category there is no ring; paused subscriptions are dimmed.
  Widget _markerFor(BillingOccurrence occurrence) {
    final subscription = occurrence.subscription;
    final categories = _categoriesBySubscription[subscription.id];
    final ringColor = (categories == null || categories.isEmpty)
        ? null
        : categories.first.color;

    final marker = Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        border: ringColor == null
            ? null
            : Border.all(color: ringColor, width: 1.5),
      ),
      padding: const EdgeInsets.all(1),
      child: subscription.buildImage(
        width: 14,
        height: 14,
        errorImgSize: 14,
        borderRadius: 3,
      ),
    );

    return subscription.isPaused
        ? Opacity(opacity: 0.4, child: marker)
        : marker;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<CurrencyProvider, SubscriptionProvider>(
      builder: (context, currencyProvider, subscriptionProvider, _) {
        final monthStart =
            DateTime(_visibleMonth.year, _visibleMonth.month, 1);
        final monthEnd =
            DateTime(_visibleMonth.year, _visibleMonth.month + 1, 0);

        final byDay = BillingSchedule.byDay(
          subscriptionProvider.subscriptions,
          monthStart,
          monthEnd,
        );

        final markers = {
          for (final entry in byDay.entries)
            entry.key: entry.value.map(_markerFor).toList(),
        };

        return CupertinoPageScaffold(
          backgroundColor:
              CupertinoColors.systemGroupedBackground.resolveFrom(context),
          child: SafeArea(
            child: Column(
              children: [
                _header(
                  context,
                  BillingSchedule.total(
                    byDay,
                    targetCurrency: currencyProvider.currency.name,
                    rates: currencyProvider.rates,
                  ),
                  currencyProvider.currency.symbol,
                ),
                Container(
                  color: CupertinoColors.secondarySystemGroupedBackground
                      .resolveFrom(context),
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: MonthGrid(
                    month: _visibleMonth,
                    selectedDay: _selectedDay,
                    markers: markers,
                    onDaySelected: (day) => setState(() => _selectedDay = day),
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: SingleChildScrollView(
                    child: Container(
                      color: CupertinoColors.secondarySystemGroupedBackground
                          .resolveFrom(context),
                      child: DayBillingList(
                        occurrences: byDay[_selectedDay] ?? const [],
                        currencySymbol: currencyProvider.currency.symbol,
                        emptyLabel: S.of(context).noBillingsThisDay,
                        onSubscriptionSelected: (subscription) {
                          Navigator.of(context).push(
                            CupertinoPageRoute(
                              builder: (context) => SubscriptionShowView(
                                subscription: subscription,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _header(BuildContext context, double total, String currencySymbol) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
      child: Column(
        children: [
          Row(
            children: [
              CupertinoButton(
                padding: const EdgeInsets.all(8),
                onPressed: () => _showMonth(-1),
                child: const Icon(CupertinoIcons.chevron_left, size: 20),
              ),
              Expanded(
                child: Text(
                  DateFormat.yMMMM().format(_visibleMonth),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: CupertinoColors.label.resolveFrom(context),
                  ),
                ),
              ),
              CupertinoButton(
                padding: const EdgeInsets.all(8),
                onPressed: () => _showMonth(1),
                child: const Icon(CupertinoIcons.chevron_right, size: 20),
              ),
            ],
          ),
          Text(
            '${S.of(context).monthTotal}: '
            '${Money.format(total, currencySymbol)}',
            style: TextStyle(
              fontSize: 13,
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
            ),
          ),
        ],
      ),
    );
  }
}
