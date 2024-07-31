import 'dart:math';

import 'package:easy_wallet/enum/payment_rate.dart';
import 'package:easy_wallet/views/components/card_section_component.dart';
import 'package:easy_wallet/views/statistics/show.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:easy_wallet/model/subscription.dart';
import 'package:easy_wallet/persistence_controller.dart';

class StatisticView extends StatefulWidget {
  const StatisticView({super.key});

  @override
  StatisticViewState createState() => StatisticViewState();
}

class StatisticViewState extends State<StatisticView> {
  double monthlyExpenses = 0.0;
  double yearlyExpenses = 0.0;
  List<Subscription> nextDueSubscriptions = [];
  List<Subscription> allSubscriptions = [];
  int pinnedCount = 0;
  int unpinnedCount = 0;
  Map<String, Color> colorCache = {};
  int touchedIndex = -1;
  late Future<void> _initDataFuture;

  @override
  void initState() {
    super.initState();
    _initDataFuture = _initializeData();
  }

  Future<void> _initializeData() async {
    await _loadStatistics();
    await prefetchColors(allSubscriptions);
  }

  Future<void> _loadStatistics() async {
    final persistenceController = PersistenceController.instance;
    final subscriptions = await persistenceController.getAllSubscriptions();

    int pinnedCount = 0;
    int unpinnedCount = 0;
    List<Subscription> nextDue = [];

    for (var subscription in subscriptions) {
      if (subscription.repeatPattern == PaymentRate.monthly.value) {
      } else if (subscription.repeatPattern == PaymentRate.yearly.value) {}

      subscription.isPinned ? pinnedCount++ : unpinnedCount++;
      if (subscription.date != null && !subscription.isPaused) {
        nextDue.add(subscription);
      }
    }

    double totalMonthlyExpenses = 0.0;
    double totalYearlyExpenses = 0.0;
    for (var subscription in subscriptions) {
      if (subscription.isPaused) continue;
      if (subscription.repeatPattern == PaymentRate.monthly.value) {
        totalMonthlyExpenses += subscription.amount;
      } else if (subscription.repeatPattern == PaymentRate.yearly.value) {
        totalYearlyExpenses += subscription.amount;
      }
    }

    setState(() {
      allSubscriptions = subscriptions;
      monthlyExpenses = totalMonthlyExpenses;
      yearlyExpenses = totalYearlyExpenses;
      this.pinnedCount = pinnedCount;
      this.unpinnedCount = unpinnedCount;
      nextDueSubscriptions = nextDue;
    });
  }

  Future<void> prefetchColors(List<Subscription> subscriptions) async {
    final futures = <Future>[];
    for (var subscription in subscriptions) {
      String faviconUrl = subscription.getFaviconUrl();
      futures.add(subscription.getDominantColorFromUrl(customUrl: faviconUrl).then((color) {
        colorCache[faviconUrl] = color;
      }).catchError((e) {
        colorCache[faviconUrl] = Colors.grey;
      }));
    }
    await Future.wait(futures);
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(Intl.message('statistics')),
      ),
      child: SafeArea(
        child: Center(
          child: FutureBuilder<void>(
            future: _initDataFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                return SingleChildScrollView(
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
                              value: '${allSubscriptions.length}',
                            ),
                            CardDetailRow(
                              label:
                                  Intl.message('expensesSinceAppInstallation'),
                              value:
                                  '${calculateExpensesSinceInstallation().toStringAsFixed(2)} €',
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
                                  '${calculateTotalSpentThisYear().toStringAsFixed(2)} €',
                            ),
                            CardDetailRow(
                              label:
                                  Intl.message('issuesOfMonthlySubscriptions'),
                              value: '${monthlyExpenses.toStringAsFixed(2)} €',
                              softBreak: true,
                            ),
                            CardDetailRow(
                              label:
                                  Intl.message('issuesOfAnnualSubscriptions'),
                              value: '${yearlyExpenses.toStringAsFixed(2)} €',
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
                              value: calculateExpensesToEndOfMonth(),
                              softBreak: true,
                            ),
                            CardDetailRow(
                              label: Intl.message(
                                  'expenditureUntilTheEndOfTheYear'),
                              value: calculateExpensesToEndOfYear(),
                              softBreak: true,
                            ),
                          ],
                        ),
                        if (allSubscriptions.isNotEmpty)
                          CardSection(
                            title: Intl.message('costShare'),
                            children: [
                              buildPieChart(allSubscriptions),
                              const Divider(),
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
                                            allSubscriptions),
                                        subscriptions: allSubscriptions,
                                      ),
                                    ),
                                  );
                                },
                                color: CupertinoColors.activeBlue,
                              ),
                            ],
                          ),
                        if (allSubscriptions.isNotEmpty)
                          CardSection(
                            title: Intl.message('yearlyVsMonthlyExpenses'),
                            subtitle:
                                Intl.message('yearlyVsMonthlyExpensesSubtitle'),
                            children: [
                              _buildChart(_makeYearlyToMonthlyData()),
                              const Divider(),
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
                                        chartData: _makeYearlyToMonthlyData(),
                                        subscriptions: allSubscriptions,
                                      ),
                                    ),
                                  );
                                },
                                color: CupertinoColors.activeBlue,
                              ),
                            ],
                          ),
                        if (allSubscriptions.isNotEmpty)
                          CardSection(
                            title: Intl.message('pinnedVsUnpinned'),
                            children: [
                              _buildChart(_makePinnedData()),
                              const Divider(),
                              CardActionButton(
                                label: Intl.message('overview'),
                                icon: CupertinoIcons.right_chevron,
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    CupertinoPageRoute(
                                      builder: (context) => ChartDetailPage(
                                        title: Intl.message('pinnedVsUnpinned'),
                                        chartData: _makePinnedData(),
                                        subscriptions: allSubscriptions,
                                      ),
                                    ),
                                  );
                                },
                                color: CupertinoColors.activeBlue,
                              ),
                            ],
                          ),
                        if (allSubscriptions.isNotEmpty)
                          CardSection(
                            title: Intl.message('pausedVsActive'),
                            children: [
                              _buildChart(_makePausedData()),
                              const Divider(),
                              CardActionButton(
                                label: Intl.message('overview'),
                                icon: CupertinoIcons.right_chevron,
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    CupertinoPageRoute(
                                      builder: (context) => ChartDetailPage(
                                        title: Intl.message('pausedVsActive'),
                                        chartData: _makePausedData(),
                                        subscriptions: allSubscriptions,
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
                );
              } else {
                return const Center(child: CircularProgressIndicator());
              }
            },
          ),
        ),
      ),
    );
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

  double calculateTotalSpentThisYear() {
    double totalExpenses = 0.0;
    for (var subscription in allSubscriptions) {
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
        badgeWidget: _Badge(
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

  double calculateExpensesSinceInstallation() {
    var amount = 0.0;
    for (var subscription in allSubscriptions) {
      int multiplier = subscription.countPayment();
      amount += (subscription.amount * multiplier);
    }
    return amount;
  }

  Future<String> calculateExpensesToEndOfMonth() async {
    double monthlyExpenses = 0.0;
    DateTime today = DateTime.now();
    DateTime endOfMonth = DateTime(today.year, today.month + 1, 0);
    for (var subscription in allSubscriptions) {
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

  Future<String> calculateExpensesToEndOfYear() async {
    double yearlyExpenses = 0.0;
    DateTime today = DateTime.now();
    DateTime endOfYear = DateTime(today.year, 12, 31);

    for (var subscription in allSubscriptions) {
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

  List<CartesianSeries<ChartData, String>> _makeYearlyToMonthlyData() {
    List<CartesianSeries<ChartData, String>> seriesList = [];
    double totalMonthlyAmount = allSubscriptions
        .where((subscription) => subscription.repeatPattern == PaymentRate.monthly.value)
        .fold(0.0, (sum, subscription) => sum + subscription.amount * 12);

    double totalYearlyAmount = allSubscriptions
        .where((subscription) => subscription.repeatPattern == PaymentRate.yearly.value)
        .fold(0.0, (sum, subscription) => sum + subscription.amount);

    double totalAmount = totalMonthlyAmount + totalYearlyAmount;

    for (var subscription in allSubscriptions) {
      String category = subscription.repeatPattern == PaymentRate.monthly.value
          ? Intl.message('monthly')
          : Intl.message('yearly');

      double actualAmount = subscription.repeatPattern == PaymentRate.monthly.value
          ? subscription.amount * 12
          : subscription.amount;

      double percentage = (actualAmount / totalAmount) * 100;

      Color? color = colorCache[subscription.getFaviconUrl()] ?? Colors.grey;
      seriesList.add(
        StackedColumnSeries<ChartData, String>(
          dataSource: [ChartData(subscription.title, percentage, color)],
          borderColor: Colors.black54,
          borderWidth: 0.01,
          dataLabelSettings: const DataLabelSettings(isVisible: false),
          xValueMapper: (ChartData data, _) => category,
          yValueMapper: (ChartData data, _) => data.value,
          pointColorMapper: (ChartData data, _) => data.color,
          name: subscription.title,
        ),
      );
    }
    return seriesList;
  }


  List<CartesianSeries<ChartData, String>> _makePinnedData() {
    List<CartesianSeries<ChartData, String>> seriesList = [];
    bool hasPinned =
        allSubscriptions.any((subscription) => subscription.isPinned);
    bool hasUnpinned =
        allSubscriptions.any((subscription) => !subscription.isPinned);

    if (!hasPinned || !hasUnpinned) {
      String placeholderCategory =
          hasUnpinned ? Intl.message('pinned') : Intl.message('unpinned');
      seriesList.add(
        StackedColumn100Series<ChartData, String>(
          dataSource: [
            ChartData(placeholderCategory, 0, CupertinoColors.systemGrey)
          ],
          dataLabelSettings: const DataLabelSettings(isVisible: false),
          xValueMapper: (ChartData data, _) => data.label,
          yValueMapper: (ChartData data, _) => data.value,
          pointColorMapper: (ChartData data, _) => data.color,
          name: placeholderCategory,
        ),
      );
    }

    for (var subscription in allSubscriptions) {
      String category = subscription.isPinned
          ? Intl.message('pinned')
          : Intl.message('unpinned');
      Color? color = colorCache[subscription.getFaviconUrl()] ?? Colors.grey;
      seriesList.add(
        StackedColumn100Series<ChartData, String>(
          dataSource: [ChartData(subscription.title, 1, color)],
          borderColor: Colors.black54,
          borderWidth: 0.01,
          dataLabelSettings: const DataLabelSettings(isVisible: false),
          xValueMapper: (ChartData data, _) => category,
          yValueMapper: (ChartData data, _) => data.value,
          pointColorMapper: (ChartData data, _) => data.color,
          name: subscription.title,
        ),
      );
    }

    return seriesList;
  }

  List<CartesianSeries<ChartData, String>> _makePausedData() {
    List<CartesianSeries<ChartData, String>> seriesList = [];
    bool hasActive =
        allSubscriptions.any((subscription) => !subscription.isPaused);
    bool hasPaused =
        allSubscriptions.any((subscription) => subscription.isPaused);

    if (hasActive && hasPaused) {
      if (!hasActive) {
        seriesList.add(
          StackedColumn100Series<ChartData, String>(
            dataSource: [
              ChartData(Intl.message('active'), 0, CupertinoColors.systemGrey)
            ],
            dataLabelSettings: const DataLabelSettings(isVisible: false),
            xValueMapper: (ChartData data, _) => data.label,
            yValueMapper: (ChartData data, _) => data.value,
            pointColorMapper: (ChartData data, _) => data.color,
            name: Intl.message('active'),
          ),
        );
      }
      if (!hasPaused) {
        seriesList.add(
          StackedColumn100Series<ChartData, String>(
            dataSource: [
              ChartData(Intl.message('paused'), 0, CupertinoColors.systemGrey)
            ],
            dataLabelSettings: const DataLabelSettings(isVisible: false),
            xValueMapper: (ChartData data, _) => data.label,
            yValueMapper: (ChartData data, _) => data.value,
            pointColorMapper: (ChartData data, _) => data.color,
            name: Intl.message('paused'),
          ),
        );
      }
    }
    for (var subscription in allSubscriptions) {
      String category = subscription.isPaused
          ? Intl.message('paused')
          : Intl.message('active');
      Color? color = colorCache[subscription.getFaviconUrl()] ?? Colors.grey;
      seriesList.add(
        StackedColumn100Series<ChartData, String>(
          dataSource: [
            ChartData(subscription.title, 1, color)
          ],
          borderColor: Colors.black54,
          borderWidth: 0.01,
          dataLabelSettings: const DataLabelSettings(isVisible: false),
          xValueMapper: (ChartData data, _) => category,
          yValueMapper: (ChartData data, _) => data.value,
          pointColorMapper: (ChartData data, _) => data.color,
          name: subscription.title,
        ),
      );
    }
    return seriesList;
  }
}

class _Badge extends StatelessWidget {
  final String imageUrl;
  final double size;
  final Subscription subscription;

  const _Badge(
      {required this.imageUrl, required this.size, required this.subscription});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(
          color: CupertinoColors.black,
          width: 2,
        ),
        boxShadow: const [
          BoxShadow(
            spreadRadius: 4,
            offset: Offset(0, 0),
            blurRadius: 3,
          ),
        ],
      ),
      child: ClipOval(
        child: subscription.buildImage(
            width: size, height: size, boxFit: BoxFit.cover, errorImgSize: 30),
      ),
    );
  }
}

class ChartData {
  final String label;
  final dynamic value;
  final Color color;

  ChartData(this.label, this.value, this.color);
}
