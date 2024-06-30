// import 'package:flutter/material.dart';
// import 'package:charts_flutter/flutter.dart' as charts;
//
// class StatisticView extends StatefulWidget {
//   @override
//   _StatisticViewState createState() => _StatisticViewState();
// }
//
// class _StatisticViewState extends State<StatisticView> {
//   double monthlyExpenses = 0.0;
//   double yearlyExpenses = 0.0;
//   List<Subscription> nextDueSubscriptions = [];
//   int pinnedCount = 0;
//   int unpinnedCount = 0;
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Statistics'),
//       ),
//       body: SingleChildScrollView(
//         child: Column(
//           children: [
//             // Add UI elements here
//           ],
//         ),
//       ),
//     );
//   }
//
//   List<charts.Series<ChartData, String>> makeYearlyToMonthlyData() {
//     // Logic
//   }
//
//   List<charts.Series<ChartData, String>> makePinnedData() {
//     // Logic
//   }
//
//   List<charts.Series<ChartData, String>> makePausedData() {
//     // Logic
//   }
// }
//
// class Subscription {
//   // Define Subscription model here
// }
//
// class ChartData {
//   final String label;
//   final int value;
//   final charts.Color color;
//
//   ChartData(this.label, this.value, this.color);
// }
