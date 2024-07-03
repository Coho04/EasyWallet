import 'package:flutter/cupertino.dart';
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
  int pinnedCount = 0;
  int unpinnedCount = 0;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    final persistenceController = PersistenceController.instance;
    final subscriptions = await persistenceController.getAllSubscriptions();

    double totalMonthlyExpenses = 0.0;
    double totalYearlyExpenses = 0.0;
    int pinnedCount = 0;
    int unpinnedCount = 0;
    List<Subscription> nextDue = [];

    for (var subscription in subscriptions) {
      if (subscription.repeatPattern == 'monthly') {
        totalMonthlyExpenses += subscription.amount;
      } else if (subscription.repeatPattern == 'yearly') {
        totalYearlyExpenses += subscription.amount;
      }

      subscription.isPinned ? pinnedCount++ : unpinnedCount++;
      if (subscription.date != null && !subscription.isPaused) {
        nextDue.add(subscription);
      }
    }

    setState(() {
      monthlyExpenses = totalMonthlyExpenses;
      yearlyExpenses = totalYearlyExpenses;
      this.pinnedCount = pinnedCount;
      this.unpinnedCount = unpinnedCount;
      nextDueSubscriptions = nextDue;
    });
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Statistics'),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Text('Total Expenses: ${(monthlyExpenses + yearlyExpenses).toStringAsFixed(2)} €',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              _buildChart('Monthly Expenses', [
                ChartData('Monthly', monthlyExpenses, CupertinoColors.systemBlue),
              ]),
              _buildChart('Yearly Expenses', [
                ChartData('Yearly', yearlyExpenses, CupertinoColors.systemRed),
              ]),
              _buildChart('Yearly vs Monthly Expenses',
                  _makeYearlyToMonthlyData()),
              _buildChart(
                  'Pinned vs Unpinned Subscriptions', _makePinnedData()),
              _buildChart(
                  'Paused vs Active Subscriptions', _makePausedData()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChart(String title, List<ChartData> data) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
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
      ChartData('Monthly', monthlyExpenses, CupertinoColors.systemBlue),
      ChartData('Yearly', yearlyExpenses, CupertinoColors.systemRed),
    ];
  }

  List<ChartData> _makePinnedData() {
    return [
      ChartData('Pinned', pinnedCount.toDouble(), CupertinoColors.systemBlue),
      ChartData(
          'Unpinned', unpinnedCount.toDouble(), CupertinoColors.systemRed),
    ];
  }

  List<ChartData> _makePausedData() {
    int activeCount = nextDueSubscriptions.length - nextDueSubscriptions
        .where((sub) => sub.isPaused)
        .length;
    int pausedCount = nextDueSubscriptions
        .where((sub) => sub.isPaused)
        .length;
    return [
      ChartData('Active', activeCount.toDouble(), CupertinoColors.systemBlue),
      ChartData('Paused', pausedCount.toDouble(), CupertinoColors.systemRed),
    ];
  }
}

class ChartData {
  final String label;
  final double value;
  final Color color;

  ChartData(this.label, this.value, this.color);
}
