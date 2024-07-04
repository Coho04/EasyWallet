import 'package:easy_wallet/enum/payment_rate.dart';
import 'package:flutter/cupertino.dart';
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
      navigationBar: CupertinoNavigationBar(
        middle: Text(Intl.message('statistics')),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Text(
                  '${Intl.message('totalExpenses')}: ${(monthlyExpenses + yearlyExpenses).toStringAsFixed(2)} €',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              _buildChart(Intl.message('monthlyExpenses'), [
                ChartData(Intl.message('monthly'), monthlyExpenses,
                    CupertinoColors.systemBlue),
              ]),
              _buildChart(Intl.message('yearlyExpenses'), [
                ChartData(Intl.message('yearly'), yearlyExpenses,
                    CupertinoColors.systemRed),
              ]),
              _buildChart(Intl.message('yearlyVsMonthlyExpenses'),
                  _makeYearlyToMonthlyData()),
              _buildChart(Intl.message('pinnedVsUnpinnedSubscriptions'),
                  _makePinnedData()),
              _buildChart(Intl.message('pausedVsActiveSubscriptions'),
                  _makePausedData()),
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
      ChartData(Intl.message('active'), activeCount.toDouble(), CupertinoColors.systemBlue),
      ChartData(Intl.message('paused'), pausedCount.toDouble(), CupertinoColors.systemRed),
    ];
  }
}

class ChartData {
  final String label;
  final double value;
  final Color color;

  ChartData(this.label, this.value, this.color);
}
