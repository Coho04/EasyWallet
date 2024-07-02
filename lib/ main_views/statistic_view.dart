import 'package:flutter/cupertino.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:easy_wallet/model/subscription.dart';
import 'package:easy_wallet/persistence_controller.dart';

class StatisticView extends StatefulWidget {
  const StatisticView({super.key});

  @override
  _StatisticViewState createState() => _StatisticViewState();
}

class _StatisticViewState extends State<StatisticView> {
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

      if (subscription.isPinned) {
        pinnedCount++;
      } else {
        unpinnedCount++;
      }

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
        middle: Text('Statistiken'),
      ),
      child: SingleChildScrollView(
        child: Column(
          children: [
            _buildChart('Jährliche vs Monatliche Ausgaben', _makeYearlyToMonthlyData()),
            _buildChart('Gepinnt vs Nicht Gepinnt Abonnements', _makePinnedData()),
            _buildChart('Pausiert vs Aktive Abonnements', _makePausedData()),
          ],
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
      ChartData('Monatlich', monthlyExpenses, CupertinoColors.systemBlue),
      ChartData('Jährlich', yearlyExpenses, CupertinoColors.systemRed),
    ];
  }

  List<ChartData> _makePinnedData() {
    return [
      ChartData('Gepinnt', pinnedCount.toDouble(), CupertinoColors.systemBlue),
      ChartData('Nicht Gepinnt', unpinnedCount.toDouble(), CupertinoColors.systemRed),
    ];
  }

  List<ChartData> _makePausedData() {
    int activeCount = nextDueSubscriptions.length - nextDueSubscriptions.where((sub) => sub.isPaused).length;
    int pausedCount = nextDueSubscriptions.where((sub) => sub.isPaused).length;
    return [
      ChartData('Aktiv', activeCount.toDouble(), CupertinoColors.systemBlue),
      ChartData('Pausiert', pausedCount.toDouble(), CupertinoColors.systemRed),
    ];
  }
}

class ChartData {
  final String label;
  final double value;
  final Color color;

  ChartData(this.label, this.value, this.color);
}
