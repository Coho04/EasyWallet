import 'dart:math';

import 'package:easy_wallet/enum/payment_rate.dart';
import 'package:easy_wallet/provider/subscription_provider.dart';
import 'package:easy_wallet/views/components/card_section_component.dart';
import 'package:easy_wallet/views/statistics/show.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
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

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    final subscriptions = context.read<SubscriptionProvider>().subscriptions;
    await prefetchColors(subscriptions);
    _calculateStatistics(subscriptions);
    setState(() {
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
    return Consumer<SubscriptionProvider>(
      builder: (context, subscriptionProvider, child) {
        final subscriptions = subscriptionProvider.subscriptions;
        return CupertinoPageScaffold(
          backgroundColor:
              CupertinoColors.systemGroupedBackground.resolveFrom(context),
          navigationBar: CupertinoNavigationBar(
            middle: Text(Intl.message('statistics')),
          ),
          child: SafeArea(
            child: Center(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Wrap(
                          spacing: 20,
                          runSpacing: 20,
                          children: [
                            CardSection(
                              title: Intl.message('appStats'),
                              children: [
                                CardDetailRow(
                                  label: Intl.message('numberOfSubscriptions'),
                                  value: '${subscriptions.length}',
                                ),
                                CardDetailRow(
                                  label: Intl.message(
                                      'expensesSinceAppInstallation'),
                                  value:
                                      '${calculateExpensesSinceInstallation(subscriptions).toStringAsFixed(2)} €',
                                  softBreak: true,
                                ),
                              ],
                            ),
                            CardSection(
                              title: Intl.message('totalExpenses'),
                              children: [
                                CardDetailRow(
                                  label: Intl.message('expenditureThisYear'),
                                  value:
                                      '${calculateTotalSpentThisYear(subscriptions).toStringAsFixed(2)} €',
                                ),
                                CardDetailRow(
                                  label: Intl.message(
                                      'issuesOfMonthlySubscriptions'),
                                  value:
                                      '${monthlyExpenses.toStringAsFixed(2)} €',
                                  softBreak: true,
                                ),
                                CardDetailRow(
                                  label: Intl.message(
                                      'issuesOfAnnualSubscriptions'),
                                  value:
                                      '${yearlyExpenses.toStringAsFixed(2)} €',
                                  softBreak: true,
                                ),
                              ],
                            ),
                            CardSection(
                              title: Intl.message('remainingCosts'),
                              children: [
                                CardDetailRow(
                                  label: Intl.message(
                                      'expenditureUntilTheEndOfTheMonth'),
                                  value: calculateExpensesToEndOfMonth(
                                      subscriptions),
                                  softBreak: true,
                                ),
                                CardDetailRow(
                                  label: Intl.message(
                                      'expenditureUntilTheEndOfTheYear'),
                                  value: calculateExpensesToEndOfYear(
                                      subscriptions),
                                  softBreak: true,
                                ),
                              ],
                            ),
                            if (subscriptions.isNotEmpty)
                              CardSection(
                                title: Intl.message('costShare'),
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(
                                        top: 10, bottom: 40),
                                    child: buildPieChart(subscriptions),
                                  ),
                                  CardActionButton(
                                    label: Intl.message('overview'),
                                    icon: CupertinoIcons.right_chevron,
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        CupertinoPageRoute(
                                          builder: (context) => ChartDetailPage(
                                            title: Intl.message('costShare'),
                                            pieChartData: buildPieChartSections(
                                                subscriptions),
                                            subscriptions: subscriptions,
                                          ),
                                        ),
                                      );
                                    },
                                    color: CupertinoColors.activeBlue,
                                  ),
                                ],
                              ),
                            if (subscriptions.isNotEmpty)
                              CardSection(
                                title: Intl.message('yearlyVsMonthlyExpenses'),
                                subtitle: Intl.message(
                                    'yearlyVsMonthlyExpensesSubtitle'),
                                children: [
                                  _buildChart(
                                      _makeYearlyToMonthlyData(subscriptions)),
                                  CardActionButton(
                                    label: Intl.message('overview'),
                                    icon: CupertinoIcons.right_chevron,
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        CupertinoPageRoute(
                                          builder: (context) => ChartDetailPage(
                                            title: Intl.message(
                                                'yearlyVsMonthlyExpenses'),
                                            chartData: _makeYearlyToMonthlyData(
                                                subscriptions),
                                            subscriptions: subscriptions,
                                            dataType: 'StackedSeriesBase',
                                          ),
                                        ),
                                      );
                                    },
                                    color: CupertinoColors.activeBlue,
                                  ),
                                ],
                              ),
                            if (subscriptions.isNotEmpty)
                              CardSection(
                                title: Intl.message('pinnedVsUnpinned'),
                                children: [
                                  _buildChart(_makePinnedData(subscriptions)),
                                  CardActionButton(
                                    label: Intl.message('overview'),
                                    icon: CupertinoIcons.right_chevron,
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        CupertinoPageRoute(
                                          builder: (context) => ChartDetailPage(
                                            title: Intl.message(
                                                'pinnedVsUnpinned'),
                                            chartData:
                                                _makePinnedData(subscriptions),
                                            subscriptions: subscriptions,
                                          ),
                                        ),
                                      );
                                    },
                                    color: CupertinoColors.activeBlue,
                                  ),
                                ],
                              ),
                            if (subscriptions.isNotEmpty)
                              CardSection(
                                title: Intl.message('pausedVsActive'),
                                children: [
                                  _buildChart(_makePausedData(subscriptions)),
                                  CardActionButton(
                                    label: Intl.message('overview'),
                                    icon: CupertinoIcons.right_chevron,
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        CupertinoPageRoute(
                                          builder: (context) => ChartDetailPage(
                                            title:
                                                Intl.message('pausedVsActive'),
                                            chartData:
                                                _makePausedData(subscriptions),
                                            subscriptions: subscriptions,
                                          ),
                                        ),
                                      );
                                    },
                                    color: CupertinoColors.activeBlue,
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ),
            ),
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
      List<Subscription> subscriptions) async {
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
    return '${monthlyExpenses.toStringAsFixed(2)} €';
  }

  Future<String> calculateExpensesToEndOfYear(
      List<Subscription> subscriptions) async {
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
    return '${yearlyExpenses.toStringAsFixed(2)} €';
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
