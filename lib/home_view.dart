import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HomeView extends StatefulWidget {
  @override
  _HomeViewState createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  double monthlyLimit = 0.0;
  bool isAnnual = false;
  String searchText = "";
  SortOption sortOption = SortOption.remainingDaysAscending;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Subscriptions'),
        actions: [
          // Add sorting and navigation actions here
        ],
      ),
      body: Column(
        children: [
          // Add UI elements here
        ],
      ),
    );
  }
}

enum SortOption {
  alphabeticalAscending, alphabeticalDescending, costAscending, costDescending, remainingDaysAscending, remainingDaysDescending
}

class Subscription {
  // Define Subscription model here
}
