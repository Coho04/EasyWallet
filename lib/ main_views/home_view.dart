import 'package:easy_wallet/model/subscription.dart';
import 'package:easy_wallet/model/subscription_item.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:easy_wallet/persistence_controller.dart';
import 'package:easy_wallet/subscription_views/subscription_create_view.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  _HomeViewState createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  double monthlyLimit = 0.0;
  bool isAnnual = false;
  String searchText = "";
  SortOption sortOption = SortOption.remainingDaysAscending;

  List<Subscription> subscriptions = [];

  @override
  void initState() {
    super.initState();
    _loadSubscriptions();
  }

  Future<void> _loadSubscriptions() async {
    try {
      if (!kIsWeb) {
        final persistenceController = PersistenceController.instance;
        final loadedSubscriptions = await persistenceController.getAllSubscriptions();
        setState(() {
          subscriptions = loadedSubscriptions;
        });
      } else {
        // Handle web version
        setState(() {
          subscriptions = [
            Subscription(
              id: 1,
              amount: 10.0,
              date: DateTime.now().subtract(const Duration(days: 10)),
              isPaused: false,
              isPinned: true,
              repeating: true,
              repeatPattern: 'monthly',
              title: 'Netflix',
              url: 'https://www.netflix.com',
            ),
            // Add more subscriptions as needed
          ];
        });
      }
    } catch (error) {
      if (kDebugMode) {
        print("Failed to load subscriptions: $error");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredSubscriptions = subscriptions.where((subscription) {
      return subscription.title!.toLowerCase().contains(searchText.toLowerCase());
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Subscriptions'),
        actions: const [
          // Add sorting and navigation actions here
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Search',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  searchText = value;
                });
              },
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filteredSubscriptions.length,
              itemBuilder: (context, index) {
                return SubscriptionItem(
                  subscription: filteredSubscriptions[index],
                  isAnnual: isAnnual,
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SubscriptionCreateView()),
          ).then((value) {
            // Reload the subscriptions after returning from the create view
            _loadSubscriptions();
          });
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

enum SortOption {
  alphabeticalAscending,
  alphabeticalDescending,
  costAscending,
  costDescending,
  remainingDaysAscending,
  remainingDaysDescending,
}
