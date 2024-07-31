import 'package:easy_wallet/views/main/statistic.dart';
import 'package:easy_wallet/views/subscription/show.dart';
import 'package:flutter/cupertino.dart';
import 'package:easy_wallet/model/subscription.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:fl_chart/fl_chart.dart';

class ChartDetailPage extends StatelessWidget {
  final String title;
  final List<ChartData>? chartData;
  final List<PieChartSectionData>? pieChartData;
  final List<Subscription> subscriptions;

  const ChartDetailPage({
    super.key,
    required this.title,
    this.chartData,
    this.pieChartData,
    required this.subscriptions,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(title),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: _buildChart(),
            ),
            Expanded(child: _buildSubscriptionList(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildChart() {
    if (chartData != null) {
      return SizedBox(
        height: 300,
        child: SfCartesianChart(
          primaryXAxis: const CategoryAxis(),
          series: <CartesianSeries>[
            ColumnSeries<ChartData, String>(
              dataSource: chartData!,
              xValueMapper: (ChartData data, _) => data.label,
              yValueMapper: (ChartData data, _) => data.value,
              pointColorMapper: (ChartData data, _) => data.color,
            ),
          ],
        ),
      );
    } else if (pieChartData != null) {
      return AspectRatio(
        aspectRatio: 1.3,
        child: PieChart(
          PieChartData(
            sections: pieChartData!,
            borderData: FlBorderData(show: false),
            sectionsSpace: 1,
            centerSpaceRadius: 0,
          ),
        ),
      );
    }
    return Container();
  }

  Widget _buildSubscriptionList(context) {
    return CupertinoListSection(
      children: subscriptions.map((subscription) {
        return CupertinoListTile(
          onTap: () {
            Navigator.of(context).push(
              CupertinoPageRoute(
                builder: (context) => SubscriptionShowView(
                  subscription: subscription,
                  onUpdate: (updatedSubscription) {},
                  onDelete: (deletedSubscription) {},
                ),
              ),
            );
          },
          title: Text(subscription.title),
          additionalInfo: Text('${subscription.amount} €'),
          leading: subscription.buildImage(),
          trailing: const SizedBox(
            width: 40,
            height: 40,
            child:  Icon(CupertinoIcons.right_chevron),
          ),
        );
      }).toList(),
    );
  }

}
