import 'package:easy_wallet/views/subscription/show.dart';
import 'package:flutter/cupertino.dart';
import 'package:easy_wallet/model/subscription.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../model/chart_data.dart';

class ChartDetailPage extends StatefulWidget {
  final String title;
  final List<CartesianSeries<ChartData, String>>? chartData;
  final List<PieChartSectionData>? pieChartData;
  final List<Subscription> subscriptions;
  final String dataType;

  const ChartDetailPage(
      {super.key,
      required this.title,
      this.chartData,
      this.pieChartData,
      required this.subscriptions,
      this.dataType = 'StackedColumn100Series'});

  @override
  ChartDetailPageState createState() => ChartDetailPageState();
}

class ChartDetailPageState extends State<ChartDetailPage> {
  int? _selectedSubscriptionId;

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          middle: Text(widget.title),
        ),
        child: SafeArea(
            child: Center(
                child: ListView(children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: _buildChart(context),
          ),
          _buildSubscriptionList(context)
        ]))));
  }

  Widget _buildChart(context) {
    final isDarkMode =
        MediaQuery.of(context).platformBrightness == Brightness.dark;
    if (widget.chartData != null) {
      return SizedBox(
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
          series: widget.chartData!.map((series) {
            return buildSeries(series);
          }).toList(),
        ),
      );
    } else if (widget.pieChartData != null) {
      return AspectRatio(
        aspectRatio: 1.3,
        child: PieChart(
          PieChartData(
            sections: widget.pieChartData!,
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
      children: widget.subscriptions.map((subscription) {
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
          leading: subscription.buildImage(
              width: (_selectedSubscriptionId != null &&
                      _selectedSubscriptionId == subscription.id)
                  ? 80
                  : 40),
          backgroundColor: (_selectedSubscriptionId != null &&
                  _selectedSubscriptionId == subscription.id)
              ? null
              : (_selectedSubscriptionId == null)
                  ? null
                  : CupertinoColors.systemGrey.withOpacity(0.3),
          trailing: const SizedBox(
            width: 40,
            height: 40,
            child: Icon(CupertinoIcons.right_chevron),
          ),
        );
      }).toList(),
    );
  }

  StackedSeriesBase buildSeries(series) {
   if (widget.dataType == 'StackedColumn100Series') {
     return StackedColumn100Series<ChartData, String>(
       dataSource: series.dataSource,
       xValueMapper: series.xValueMapper,
       yValueMapper: (ChartData data, _) => data.value,
       pointColorMapper: (ChartData data, _) {
         var color = data.color;
         if (_selectedSubscriptionId != null && widget.subscriptions.isNotEmpty) {
           Iterable<Subscription> filteredSubs = widget.subscriptions.where((sub) => sub.title == data.label);
           if (filteredSubs.isEmpty) {
             return color;
           }
           int? id = filteredSubs.first.id;
           if (id != null) {
             final isSelected = _selectedSubscriptionId == id;
             if (!isSelected) {
               color = color.withOpacity(0.5);
             }
           }
         }
         return color;
       },
       name: series.name,
       onPointTap: (pointDetails) {
         setState(() {
           final tappedData =
           series.dataSource?[pointDetails.pointIndex!];
           final tappedSubscription = widget.subscriptions
               .firstWhere((sub) => sub.title == tappedData?.label);

           if (_selectedSubscriptionId == tappedSubscription.id) {
             _selectedSubscriptionId = null;
           } else {
             _selectedSubscriptionId = tappedSubscription.id;
           }
         });
       },
       borderColor: Colors.black54,
       borderWidth: 0.01,
       dataLabelSettings: const DataLabelSettings(isVisible: false),
     );
   } else {
     return StackedColumnSeries<ChartData, String>(
       dataSource: series.dataSource,
       xValueMapper: series.xValueMapper,
       yValueMapper: (ChartData data, _) => data.value,
       pointColorMapper: (ChartData data, _) {
         var color = data.color;
         if (_selectedSubscriptionId != null) {
           final isSelected = widget.subscriptions
               .firstWhere((sub) => sub.title == data.label)
               .id ==
               _selectedSubscriptionId;
           if (!isSelected) {
             color = color.withOpacity(0.5);
           }
         }
         return color;
       },
       name: series.name,
       onPointTap: (pointDetails) {
         setState(() {
           final tappedData =
           series.dataSource?[pointDetails.pointIndex!];
           final tappedSubscription = widget.subscriptions
               .firstWhere((sub) => sub.title == tappedData?.label);

           if (_selectedSubscriptionId == tappedSubscription.id) {
             _selectedSubscriptionId = null;
           } else {
             _selectedSubscriptionId = tappedSubscription.id;
           }
         });
       },
       borderColor: Colors.black54,
       borderWidth: 0.01,
       dataLabelSettings: const DataLabelSettings(isVisible: false),
     );
   }
  }
}
