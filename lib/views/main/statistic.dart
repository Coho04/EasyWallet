import 'dart:math';

import 'package:easy_wallet/enum/currency.dart';
import 'package:easy_wallet/enum/payment_rate.dart';
import 'package:easy_wallet/provider/currency_provider.dart';
import 'package:easy_wallet/provider/subscription_provider.dart';
import 'package:easy_wallet/views/components/stat_card.dart';
import 'package:easy_wallet/views/components/subscription_header.dart';
import 'package:easy_wallet/views/statistics/show.dart';
import 'package:easy_wallet/views/subscription/show.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:easy_wallet/model/subscription.dart';

import '../../model/chart_data.dart';
import '../components/badge_component.dart';

class StatisticView extends StatefulWidget {
  const StatisticView({super.key});

  @override
  StatisticViewState createState() => StatisticViewState();
}

class StatisticViewState extends State<StatisticView> {
  double monthlyExpenses = 0.0;
  double yearlyExpenses = 0.0;
  List<Subscription> nextDueSubscriptions = [];
  int pinnedCount = 0;
  int unpinnedCount = 0;
  Map<String, Color> colorCache = {};
  int touchedIndex = -1;
  int? _selectedSubscriptionId;
  bool _isLoading = true;
  double _monthlyLimit = 0.0;
  String _costToMonthEnd = '';
  String _costToYearEnd = '';

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    final prefs = await SharedPreferences.getInstance();
    _monthlyLimit = prefs.getDouble('monthlyLimit') ?? 0.0;

    if (!mounted) return;
    final subscriptions = context.read<SubscriptionProvider>().subscriptions;
    final currency = context.read<CurrencyProvider>().currency;

    await prefetchColors(subscriptions);
    _calculateStatistics(subscriptions);

    final toMonth = await calculateExpensesToEndOfMonth(subscriptions, currency);
    final toYear = await calculateExpensesToEndOfYear(subscriptions, currency);

    if (!mounted) return;
    setState(() {
      _costToMonthEnd = toMonth;
      _costToYearEnd = toYear;
      _isLoading = false;
    });
  }

  Future<void> prefetchColors(List<Subscription> subscriptions) async {
    final futures = <Future>[];
    for (var subscription in subscriptions) {
      String faviconUrl = subscription.getFaviconUrl();
      futures.add(subscription
          .getDominantColorFromUrl(customUrl: faviconUrl)
          .then((color) {
        colorCache[faviconUrl] = color;
      }).catchError((e) {
        colorCache[faviconUrl] = Colors.grey;
      }));
    }
    await Future.wait(futures);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<CurrencyProvider, SubscriptionProvider>(
      builder: (context, currencyProvider, subProvider, _) {
        final currency = currencyProvider.currency;
        final subscriptions = subProvider.subscriptions;

        if (_isLoading) {
          return const CupertinoPageScaffold(
            child: Center(child: CupertinoActivityIndicator()),
          );
        }

        final top3 = _top3Subscriptions(subscriptions);
        final monthly = _calcMonthly(subscriptions);
        final yearly = _calcYearly(subscriptions);

        return CupertinoPageScaffold(
          backgroundColor:
              CupertinoColors.systemGroupedBackground.resolveFrom(context),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: SubscriptionHeader(
                  monthlySpent: monthly,
                  yearlySpent: yearly,
                  currencySymbol: currency.symbol,
                  budgetLimit: _monthlyLimit > 0 ? _monthlyLimit : null,
                  onSortTap: () {},
                  onAddTap: () {},
                  showActions: false,
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Card 1: Verbleibend
                    StatCard(
                      title: 'Verbleibend',
                      icon: CupertinoIcons.calendar_badge_minus,
                      children: [
                        _statRow('Bis Monatsende', _costToMonthEnd),
                        _statRow('Bis Jahresende', _costToYearEnd),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Card 2: Top 3
                    StatCard(
                      title: 'Top Abonnements',
                      icon: CupertinoIcons.star,
                      children: top3.isEmpty
                          ? [
                              Text('Keine aktiven Abonnements',
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: CupertinoColors.secondaryLabel.resolveFrom(context)))
                            ]
                          : top3.map((s) => _top3Row(s, currency)).toList(),
                    ),
                    const SizedBox(height: 12),
                    // Card 3: Kostenverteilung
                    if (subscriptions.isNotEmpty) ...[
                      StatCard(
                        title: 'Kostenverteilung',
                        icon: CupertinoIcons.chart_pie,
                        children: [
                          Padding(
                            padding:
                                const EdgeInsets.only(top: 8, bottom: 8),
                            child: buildPieChart(subscriptions),
                          ),
                          _chartDetailButton('Alle', subscriptions, null,
                              buildPieChartSections(subscriptions), context,
                              pageTitle: 'Kostenverteilung'),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
                    // Card 4: Verlauf
                    StatCard(
                      title: 'Monatlicher Verlauf',
                      icon: CupertinoIcons.chart_bar,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 8, bottom: 8),
                          child: _buildChart(
                              _makeYearlyToMonthlyData(subscriptions)),
                        ),
                        _chartDetailButton(
                            'Alle',
                            subscriptions,
                            _makeYearlyToMonthlyData(subscriptions),
                            null,
                            context,
                            dataType: 'StackedSeriesBase',
                            pageTitle: 'Monatlicher Verlauf'),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Card 5: App Gesamt
                    StatCard(
                      title: 'Gesamt',
                      icon: CupertinoIcons.info_circle,
                      children: [
                        _statRow(
                            'Ausgaben seit Installation',
                            '${calculateExpensesSinceInstallation(subscriptions).toStringAsFixed(2)} ${currency.symbol}'),
                        _statRow(
                            'Aktive Abonnements',
                            '${subscriptions.where((s) => !s.isPaused).length}'),
                        _statRow(
                            'Pausiert',
                            '${subscriptions.where((s) => s.isPaused).length}'),
                      ],
                    ),
                    const SizedBox(height: 85),
                  ]),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _calculateStatistics(List<Subscription> subscriptions) {
    double totalMonthlyExpenses = 0.0;
    double totalYearlyExpenses = 0.0;
    int pinnedCount = 0;
    int unpinnedCount = 0;
    List<Subscription> nextDue = [];

    for (var subscription in subscriptions) {
      if (subscription.repeatPattern == PaymentRate.monthly.value) {
        totalMonthlyExpenses += subscription.amount;
      } else if (subscription.repeatPattern == PaymentRate.yearly.value) {
        totalYearlyExpenses += subscription.amount;
      }

      subscription.isPinned ? pinnedCount++ : unpinnedCount++;
      if (subscription.date != null && !subscription.isPaused) {
        nextDue.add(subscription);
      }
    }

    monthlyExpenses = totalMonthlyExpenses;
    yearlyExpenses = totalYearlyExpenses;
    this.pinnedCount = pinnedCount;
    this.unpinnedCount = unpinnedCount;
    nextDueSubscriptions = nextDue;
  }

  double _calcMonthly(List<Subscription> subs) {
    final now = DateTime.now();
    double total = 0.0;
    for (final s in subs) {
      if (s.isPaused) continue;
      if (s.repeatPattern == 'monthly') {
        total += s.amount;
      } else if (s.repeatPattern == 'yearly') {
        if (s.date != null && s.date!.month == now.month) {
          total += s.amount;
        }
      }
    }
    return total;
  }

  double _calcYearly(List<Subscription> subs) {
    double total = 0.0;
    for (final s in subs) {
      if (s.isPaused) continue;
      if (s.repeatPattern == 'monthly') {
        total += s.amount * 12;
      } else if (s.repeatPattern == 'yearly') {
        total += s.amount;
      }
    }
    return total;
  }

  Widget _statRow(String label, String value) {
    final labelColor = CupertinoColors.label.resolveFrom(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(label,
                style: TextStyle(fontSize: 13, color: labelColor),
                overflow: TextOverflow.ellipsis),
          ),
          Text(value,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: labelColor)),
        ],
      ),
    );
  }

  Widget _top3Row(Subscription sub, Currency currency) {
    final equiv =
        sub.repeatPattern == 'yearly' ? sub.amount / 12 : sub.amount;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          CupertinoPageRoute(
            builder: (_) => SubscriptionShowView(subscription: sub),
          ),
        ),
        child: Row(
          children: [
            sub.buildImage(width: 28, height: 28, borderRadius: 7),
            const SizedBox(width: 10),
            Expanded(
              child: Text(sub.title,
                  style: TextStyle(fontSize: 13, color: CupertinoColors.label.resolveFrom(context)),
                  overflow: TextOverflow.ellipsis),
            ),
            Text(
              '${equiv.toStringAsFixed(2)} ${currency.symbol}/Mo',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: CupertinoColors.secondaryLabel.resolveFrom(context)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chartDetailButton(
    String label,
    List<Subscription> subscriptions,
    List<CartesianSeries<ChartData, String>>? chartData,
    List<PieChartSectionData>? pieData,
    BuildContext context, {
    String dataType = 'StackedColumn100Series',
    String? pageTitle,
  }) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: const Size(0, 0),
      onPressed: () => Navigator.push(
        context,
        CupertinoPageRoute(
          builder: (_) => ChartDetailPage(
            title: pageTitle ?? label,
            chartData: chartData,
            pieChartData: pieData,
            subscriptions: subscriptions,
            dataType: dataType,
          ),
        ),
      ),
      child: Builder(
        builder: (BuildContext context) {
          final activeBlueColor = CupertinoColors.activeBlue.resolveFrom(context);
          return Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text('Alle',
                  style:
                      TextStyle(fontSize: 13, color: activeBlueColor)),
              const SizedBox(width: 4),
              Icon(CupertinoIcons.chevron_right,
                  size: 13, color: activeBlueColor),
            ],
          );
        },
      ),
    );
  }

  List<Subscription> _top3Subscriptions(List<Subscription> subscriptions) {
    final active = subscriptions.where((s) => !s.isPaused).toList();
    active.sort((a, b) {
      final aEquiv =
          a.repeatPattern == 'yearly' ? a.amount / 12 : a.amount;
      final bEquiv =
          b.repeatPattern == 'yearly' ? b.amount / 12 : b.amount;
      return bEquiv.compareTo(aEquiv);
    });
    return active.take(3).toList();
  }

  Widget buildPieChart(List<Subscription> subscriptions) {
    return AspectRatio(
      aspectRatio: 1.3,
      child: PieChart(
        PieChartData(
          sections: buildPieChartSections(subscriptions),
          pieTouchData: PieTouchData(
            touchCallback: (FlTouchEvent event, pieTouchResponse) {
              setState(() {
                if (!event.isInterestedForInteractions ||
                    pieTouchResponse == null ||
                    pieTouchResponse.touchedSection == null) {
                  touchedIndex = -1;
                  return;
                }
                touchedIndex =
                    pieTouchResponse.touchedSection!.touchedSectionIndex;
              });
            },
          ),
          borderData: FlBorderData(show: false),
          sectionsSpace: 1,
          centerSpaceRadius: 0,
        ),
      ),
    );
  }

  double calculateMonthlyExpenses(List<Subscription> subscriptions) {
    var totalMonthlyExpenses = 0.0;
    for (var subscription in subscriptions) {
      if (subscription.repeatPattern == PaymentRate.monthly.value) {
        totalMonthlyExpenses += subscription.amount;
      }
    }
    return totalMonthlyExpenses;
  }

  double calculateTotalSpentThisYear(List<Subscription> subscriptions) {
    double totalExpenses = 0.0;
    for (var subscription in subscriptions) {
      if (subscription.isPaused) continue;
      if (subscription.repeatPattern == PaymentRate.monthly.value) {
        totalExpenses += subscription.amount * 12;
      } else if (subscription.repeatPattern == PaymentRate.yearly.value) {
        totalExpenses += subscription.amount;
      }
    }
    return totalExpenses;
  }

  List<PieChartSectionData> buildPieChartSections(
      List<Subscription> subscriptions) {
    double totalExpenses =
        subscriptions.fold(0, (sum, item) => sum + item.amount);
    return List.generate(subscriptions.length, (index) {
      final subscription = subscriptions[index];
      double percentage = (subscription.amount / totalExpenses) * 100;
      String faviconUrl = subscription.getFaviconUrl();
      Color? color = colorCache.containsKey(faviconUrl)
          ? colorCache[faviconUrl]
          : getRandomColor();

      final isTouched = index == touchedIndex;
      final fontSize = isTouched ? 20.0 : 16.0;
      final radius = isTouched ? 110.0 : 100.0;
      final widgetSize = isTouched ? 55.0 : 40.0;

      return PieChartSectionData(
        color: color,
        value: subscription.amount,
        title: '${percentage.toStringAsFixed(1)}%',
        titlePositionPercentageOffset: 0.65,
        radius: radius,
        badgeWidget: BadgeComponent(
            imageUrl: faviconUrl, size: widgetSize, subscription: subscription),
        badgePositionPercentageOffset: 1.25,
        titleStyle: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: const Color(0xffffffff),
          shadows: const [Shadow(color: CupertinoColors.black, blurRadius: 3)],
        ),
      );
    });
  }

  Color getRandomColor() {
    Random random = Random();
    return Color.fromRGBO(
        random.nextInt(255), random.nextInt(255), random.nextInt(255), 1);
  }

  double calculateExpensesSinceInstallation(List<Subscription> subscriptions) {
    var amount = 0.0;
    for (var subscription in subscriptions) {
      int multiplier = subscription.countPayment();
      amount += (subscription.amount * multiplier);
    }
    return amount;
  }

  Future<String> calculateExpensesToEndOfMonth(
      List<Subscription> subscriptions, Currency currency) async {
    double monthlyExpenses = 0.0;
    DateTime today = DateTime.now();
    DateTime endOfMonth = DateTime(today.year, today.month + 1, 0);
    for (var subscription in subscriptions) {
      if (subscription.date == null || subscription.isPaused) continue;
      DateTime? nextDueDate = getNextDueDate(subscription, today);
      if (nextDueDate == null) continue;
      if (nextDueDate.isAfter(today) &&
          nextDueDate.isBefore(endOfMonth.add(const Duration(days: 1)))) {
        monthlyExpenses += subscription.amount;
      }
    }
    return '${monthlyExpenses.toStringAsFixed(2)} ${currency.symbol}';
  }

  Future<String> calculateExpensesToEndOfYear(
      List<Subscription> subscriptions, Currency currency) async {
    double yearlyExpenses = 0.0;
    DateTime today = DateTime.now();
    DateTime endOfYear = DateTime(today.year, 12, 31);

    for (var subscription in subscriptions) {
      if (subscription.isPaused) continue;
      DateTime nextDueDate = subscription.getNextBillDate();
      if (subscription.repeatPattern == PaymentRate.monthly.value) {
        while (nextDueDate.isBefore(endOfYear.add(const Duration(days: 1)))) {
          yearlyExpenses += subscription.amount;
          nextDueDate = DateTime(
              nextDueDate.year, nextDueDate.month + 1, nextDueDate.day);
        }
      } else if (subscription.repeatPattern == PaymentRate.yearly.value) {
        if (nextDueDate.isBefore(endOfYear.add(const Duration(days: 1)))) {
          yearlyExpenses += subscription.amount;
        }
      }
    }
    return '${yearlyExpenses.toStringAsFixed(2)} ${currency.symbol}';
  }

  DateTime? getNextDueDate(Subscription subscription, DateTime referenceDate) {
    if (subscription.date == null) return null;
    DateTime startDate = subscription.date!;
    if (startDate.isAfter(referenceDate)) {
      return startDate;
    }

    if (subscription.repeatPattern == PaymentRate.monthly.value) {
      DateTime nextDueDate =
          DateTime(startDate.year, startDate.month, startDate.day);
      while (nextDueDate.isBefore(referenceDate) ||
          nextDueDate.isAtSameMomentAs(referenceDate)) {
        nextDueDate = DateTime(nextDueDate.year, nextDueDate.month + 1, 1);
        int lastDayOfMonth =
            DateTime(nextDueDate.year, nextDueDate.month + 1, 0).day;
        nextDueDate = DateTime(nextDueDate.year, nextDueDate.month,
            min(startDate.day, lastDayOfMonth));
      }
      return nextDueDate;
    } else if (subscription.repeatPattern == PaymentRate.yearly.value) {
      DateTime nextDueDate =
          DateTime(startDate.year + 1, startDate.month, startDate.day);
      while (nextDueDate.isBefore(referenceDate) ||
          nextDueDate.isAtSameMomentAs(referenceDate)) {
        nextDueDate =
            DateTime(nextDueDate.year + 1, nextDueDate.month, startDate.day);
      }
      return nextDueDate;
    } else {
      return null;
    }
  }

  Widget _buildChart(data) {
    final isDarkMode =
        MediaQuery.of(context).platformBrightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          SizedBox(
            height: 300,
            child: SfCartesianChart(
                primaryXAxis: CategoryAxis(
                  labelStyle: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                primaryYAxis: NumericAxis(
                  majorGridLines: const MajorGridLines(width: 0),
                  labelStyle: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
                series: data),
          ),
        ],
      ),
    );
  }

  List<CartesianSeries<ChartData, String>> _makeYearlyToMonthlyData(
      List<Subscription> subscriptions) {
    List<CartesianSeries<ChartData, String>> seriesList = [];
    double totalMonthlyAmount = subscriptions
        .where((subscription) =>
            subscription.repeatPattern == PaymentRate.monthly.value)
        .fold(0.0, (sum, subscription) => sum + subscription.amount * 12);

    double totalYearlyAmount = subscriptions
        .where((subscription) =>
            subscription.repeatPattern == PaymentRate.yearly.value)
        .fold(0.0, (sum, subscription) => sum + subscription.amount);

    if (totalMonthlyAmount == 0 || totalYearlyAmount == 0) {
      String placeholderCategory =
          (totalMonthlyAmount == 0) ? 'monthly' : 'yearly';
      seriesList.add(
        buildPlaceholderSeries(placeholderCategory, stackedColumnSeries: true),
      );
    }
    double totalAmount = totalMonthlyAmount + totalYearlyAmount;

    for (var subscription in subscriptions) {
      String category = subscription.repeatPattern == PaymentRate.monthly.value
          ? 'monthly'
          : 'yearly';

      double actualAmount =
          subscription.repeatPattern == PaymentRate.monthly.value
              ? subscription.amount * 12
              : subscription.amount;

      double percentage = (actualAmount / totalAmount) * 100;

      seriesList.add(buildStackedColumn100Series(
          subscription, category, percentage,
          stackedColumnSeries: true));
    }
    return seriesList;
  }

  List<CartesianSeries<ChartData, String>> _makePinnedData(
      List<Subscription> subscriptions) {
    List<CartesianSeries<ChartData, String>> seriesList = [];
    var hasPinned = subscriptions.any((subscription) => subscription.isPinned);
    bool hasUnpinned =
        subscriptions.any((subscription) => !subscription.isPinned);
    if (!hasPinned || !hasUnpinned) {
      seriesList.add(
        buildPlaceholderSeries(hasUnpinned ? 'pinned' : 'unpinned'),
      );
    }

    for (var subscription in subscriptions) {
      seriesList.add(buildStackedColumn100Series(
          subscription, subscription.isPinned ? 'pinned' : 'unpinned', 1));
    }

    return seriesList;
  }

  List<CartesianSeries<ChartData, String>> _makePausedData(
      List<Subscription> subscriptions) {
    List<CartesianSeries<ChartData, String>> seriesList = [];
    var hasActive = subscriptions.any((subscription) => !subscription.isPaused);
    var hasPaused = subscriptions.any((subscription) => subscription.isPaused);

    if (!hasPaused || !hasActive) {
      seriesList.add(
        buildPlaceholderSeries(hasActive ? 'active' : 'paused'),
      );
    }

    for (var subscription in subscriptions) {
      seriesList.add(buildStackedColumn100Series(
          subscription, subscription.isPaused ? 'paused' : 'active', 1));
    }
    return seriesList;
  }

  dynamic buildPlaceholderSeries(category, {bool stackedColumnSeries = false}) {
    category = Intl.message(category);
    return stackedColumnSeries
        ? StackedColumnSeries<ChartData, String>(
            dataSource: [ChartData(category, 0, CupertinoColors.systemGrey)],
            dataLabelSettings: const DataLabelSettings(isVisible: false),
            xValueMapper: (ChartData data, _) => data.label,
            yValueMapper: (ChartData data, _) => data.value,
            pointColorMapper: (ChartData data, _) => data.color,
            name: category,
          )
        : StackedColumn100Series<ChartData, String>(
            dataSource: [ChartData(category, 0, CupertinoColors.systemGrey)],
            dataLabelSettings: const DataLabelSettings(isVisible: false),
            xValueMapper: (ChartData data, _) => data.label,
            yValueMapper: (ChartData data, _) => data.value,
            pointColorMapper: (ChartData data, _) => data.color,
            name: category,
          );
  }

  dynamic buildStackedColumn100Series(subscription, category, value,
      {bool stackedColumnSeries = false}) {
    Color? color = colorCache[subscription.getFaviconUrl()] ?? Colors.grey;
    bool isSelected = _selectedSubscriptionId == subscription.id;
    final isDarkMode =
        MediaQuery.of(context).platformBrightness == Brightness.dark;
    final commonSettings = {
      'onPointTap': (ChartPointDetails point) {
        setState(() {
          if (_selectedSubscriptionId == subscription.id) {
            _selectedSubscriptionId = null;
          } else {
            _selectedSubscriptionId = subscription.id;
          }
        });
      },
      'dataSource': [ChartData(subscription.title, value, color)],
      'borderColor': isDarkMode ? Colors.white : Colors.black,
      'borderWidth': isSelected ? 2.0 : 0.5,
      'opacity': _selectedSubscriptionId == null
          ? 1.0
          : isSelected
              ? 1.0
              : 0.7,
      'dataLabelSettings': const DataLabelSettings(isVisible: false),
      'xValueMapper': (ChartData data, _) => Intl.message(category),
      'yValueMapper': (ChartData data, _) => data.value as num,
      'pointColorMapper': (ChartData data, _) => data.color,
      'name': subscription.title,
    };
    return stackedColumnSeries
        ? StackedColumnSeries<ChartData, String>(
            onPointTap: commonSettings['onPointTap'],
            dataSource: commonSettings['dataSource'],
            borderColor: commonSettings['borderColor'],
            borderWidth: commonSettings['borderWidth'],
            opacity: commonSettings['opacity'],
            dataLabelSettings: commonSettings['dataLabelSettings'],
            xValueMapper: commonSettings['xValueMapper'],
            yValueMapper: commonSettings['yValueMapper'],
            pointColorMapper: commonSettings['pointColorMapper'],
            name: commonSettings['name'],
          )
        : StackedColumn100Series<ChartData, String>(
            onPointTap: commonSettings['onPointTap'],
            dataSource: commonSettings['dataSource'],
            borderColor: commonSettings['borderColor'],
            borderWidth: commonSettings['borderWidth'],
            opacity: commonSettings['opacity'],
            dataLabelSettings: commonSettings['dataLabelSettings'],
            xValueMapper: commonSettings['xValueMapper'],
            yValueMapper: commonSettings['yValueMapper'],
            pointColorMapper: commonSettings['pointColorMapper'],
            name: commonSettings['name'],
          );
  }
}
