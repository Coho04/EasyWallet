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
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:palette_generator/palette_generator.dart';

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
      String faviconUrl =
          'https://www.google.com/s2/favicons?sz=64&domain_url=${Uri.parse(subscription.url!).host}';
      futures.add(getDominantColorFromUrl(faviconUrl).then((color) {
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
          child: SingleChildScrollView(
        child: FutureBuilder<void>(
          future: _initDataFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              return Padding(
                  padding: const EdgeInsets.all(10),
                  child: Wrap(
                    spacing: 20,
                    runSpacing: 20,
                    children: [
                      CardSection(
                        title: Intl.message('App Stats'),
                        isDarkMode: false,
                        children: [
                          CardDetailRow(
                              label: Intl.message('numberOfSubscriptions'),
                              value: '${allSubscriptions.length}',
                              isDarkMode: false),
                          CardDetailRow(
                              label:
                                  Intl.message('expensesSinceAppInstallation'),
                              value:
                                  '${calculateExpensesSinceInstallation().toStringAsFixed(2)} €',
                              isDarkMode: false),
                        ],
                      ),
                      CardSection(
                        title: Intl.message('Insgesamt Kosten'),
                        isDarkMode: false,
                        children: [
                          CardDetailRow(
                              label: Intl.message('expenditureThisYear'),
                              value:
                                  '${(monthlyExpenses + yearlyExpenses).toStringAsFixed(2)} €',
                              isDarkMode: false),
                          CardDetailRow(
                              label:
                                  Intl.message('issuesOfMonthlySubscriptions'),
                              value: '${monthlyExpenses.toStringAsFixed(2)} €',
                              isDarkMode: false,
                              softBreak: true),
                          CardDetailRow(
                              label:
                                  Intl.message('issuesOfAnnualSubscriptions'),
                              value: '${yearlyExpenses.toStringAsFixed(2)} €',
                              isDarkMode: false,
                              softBreak: true),
                        ],
                      ),
                      CardSection(
                        title: Intl.message('Verbleibende Kosten'),
                        isDarkMode: false,
                        children: [
                          CardDetailRow(
                              label: Intl.message(
                                  'expenditureUntilTheEndOfTheMonth'),
                              value: calculateExpensesToEndOfMonth(),
                              isDarkMode: false),
                          CardDetailRow(
                              label: Intl.message(
                                  'expenditureUntilTheEndOfTheYear'),
                              value: calculateExpensesToEndOfYear(),
                              isDarkMode: false),
                        ],
                      ),
                      CardSection(
                        title: Intl.message('Kostenanteil'),
                        isDarkMode: false,
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
                                    title: Intl.message('Kostenanteil'),
                                    pieChartData: buildPieChartSections(allSubscriptions),
                                    subscriptions: allSubscriptions,
                                  ),
                                ),
                              );
                            },
                            color: CupertinoColors.activeBlue,
                            isDarkMode: false,
                          ),
                        ],
                      ),
                      CardSection(
                        title: Intl.message('yearlyVsMonthlyExpenses'),
                        isDarkMode: false,
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
                                    title: Intl.message('yearlyVsMonthlyExpenses'),
                                    chartData: _makeYearlyToMonthlyData(),
                                    subscriptions: allSubscriptions,
                                  ),
                                ),
                              );
                            },
                            color: CupertinoColors.activeBlue,
                            isDarkMode: false,
                          ),
                        ],
                      ),
                      CardSection(
                        title: Intl.message('pinnedVsUnpinned'),
                        isDarkMode: false,
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
                            isDarkMode: false,
                          ),
                        ],
                      ),
                      CardSection(
                        title: Intl.message('pausedVsActive'),
                        isDarkMode: false,
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
                            isDarkMode: false,
                          ),
                        ],
                      ),
                    ],
                  ));
            } else {
              return const Center(child: CircularProgressIndicator());
            }
          },
        ),
      )),
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

  List<PieChartSectionData> buildPieChartSections(
      List<Subscription> subscriptions) {
    double totalExpenses =
        subscriptions.fold(0, (sum, item) => sum + item.amount);
    return List.generate(subscriptions.length, (index) {
      final subscription = subscriptions[index];
      double percentage = (subscription.amount / totalExpenses) * 100;
      String faviconUrl =
          'https://www.google.com/s2/favicons?sz=64&domain_url=${Uri.parse(subscription.url!).host}';
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
        badgeWidget: _Badge(imageUrl: faviconUrl, size: widgetSize),
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

  Future<Color> getDominantColorFromUrl(String imageUrl) async {
    var response = await http.get(Uri.parse(imageUrl));
    if (response.statusCode == 200) {
      img.Image? image = img.decodeImage(response.bodyBytes);
      if (image != null) {
        var paletteGenerator = await PaletteGenerator.fromImageProvider(
            Image.network(imageUrl).image);
        return paletteGenerator.dominantColor?.color ?? Colors.grey;
      }
    }
    return Colors.grey;
  }

  void onUpdate(Subscription updatedSubscription) {
    // Logik, um eine Subscription zu aktualisieren
  }

  void onDelete(Subscription deletedSubscription) {
    setState(() {
      allSubscriptions.remove(deletedSubscription);
    });
    // Weitere Logik zum Löschen, z.B. API-Aufrufe
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
      DateTime nextDueDate = getNextDueDate(subscription, today)!;
      if (nextDueDate.isBefore(endOfYear.add(const Duration(days: 1)))) {
        if (subscription.repeatPattern == PaymentRate.monthly.value) {
          while (nextDueDate.isBefore(endOfYear.add(const Duration(days: 1)))) {
            yearlyExpenses += subscription.amount;
            nextDueDate = DateTime(
                nextDueDate.year, nextDueDate.month + 1, nextDueDate.day);
          }
        } else if (subscription.repeatPattern == PaymentRate.yearly.value) {
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

  Widget _buildChart(List<ChartData> data) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          SizedBox(
            height: 300,
            child: SfCartesianChart(
              primaryXAxis: const CategoryAxis(),
              series: <CartesianSeries>[
                ColumnSeries<ChartData, String>(
                  dataSource: data,
                  xValueMapper: (ChartData data, _) => data.label,
                  yValueMapper: (ChartData data, _) => data.value,
                  pointColorMapper: (ChartData data, _) => data.color,
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<ChartData> _makeYearlyToMonthlyData() {
    return [
      ChartData(
          Intl.message('monthly'), monthlyExpenses, CupertinoColors.systemBlue),
      ChartData(
          Intl.message('yearly'), yearlyExpenses, CupertinoColors.systemRed),
    ];
  }

  List<ChartData> _makePinnedData() {
    return [
      ChartData(Intl.message('pinned'), pinnedCount.toDouble(),
          CupertinoColors.systemBlue),
      ChartData(Intl.message('unpinned'), unpinnedCount.toDouble(),
          CupertinoColors.systemRed),
    ];
  }

  List<ChartData> _makePausedData() {
    int activeCount = nextDueSubscriptions.length -
        nextDueSubscriptions.where((sub) => sub.isPaused).length;
    int pausedCount = nextDueSubscriptions.where((sub) => sub.isPaused).length;
    return [
      ChartData(Intl.message('active'), activeCount.toDouble(),
          CupertinoColors.systemBlue),
      ChartData(Intl.message('paused'), pausedCount.toDouble(),
          CupertinoColors.systemRed),
    ];
  }
}

class _Badge extends StatelessWidget {
  final String imageUrl;
  final double size;

  const _Badge({
    required this.imageUrl,
    required this.size,
  });

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
        child: Image.network(
          imageUrl,
          fit: BoxFit.cover,
          width: size,
          height: size,
        ),
      ),
    );
  }
}

class ChartData {
  final String label;
  final double value;
  final Color color;

  ChartData(this.label, this.value, this.color);
}
