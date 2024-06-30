import 'package:easy_wallet/model/subscription.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'subscription_edit_view.dart'; // Assuming this file contains SubscriptionEditView class
import 'package:easy_wallet/persistence_controller.dart'; // Assuming this file contains PersistenceController class

class SubscriptionDetailView extends StatelessWidget {
  final Subscription subscription;

  const SubscriptionDetailView({super.key, required this.subscription});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Subscriptions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        SubscriptionEditView(subscription: subscription)),
              );
            },
          ),
        ],
      ),
      body: ListView(
        children: [
          if (subscription.url != null)
            ListTile(
              leading: CachedNetworkImage(
                imageUrl:
                    'https://www.google.com/s2/favicons?sz=64&domain_url=${Uri.parse(subscription.url!).host}',
                placeholder: (context, url) =>
                    const CircularProgressIndicator(),
                errorWidget: (context, url, error) => const Icon(Icons.error),
                width: 20,
                height: 20,
              ),
              title: Text(subscription.title ?? 'Unknown',
                  style: const TextStyle(fontSize: 24)),
            ),
          _buildDetailRow('Costs',
              '${subscription.amount.toStringAsFixed(2)} € ${_repeatPattern(subscription)}'),
          _buildDetailRow(
              'Next invoice',
              _calculateNextBillDate(subscription) != null
                  ? DateFormat.yMMMd()
                      .format(_calculateNextBillDate(subscription)!)
                  : ''),
          _buildDetailRow(
              'Previous invoice',
              _calculatePreviousBillDate(subscription) != null
                  ? DateFormat.yMMMd()
                      .format(_calculatePreviousBillDate(subscription)!)
                  : ''),
          _buildDetailRow(
              'Created on',
              subscription.timestamp != null
                  ? DateFormat('EEEE, dd.MM.yyyy HH:mm')
                      .format(subscription.timestamp!)
                  : 'Unknown'),
          if (subscription.notes != null &&
              subscription.notes!.trim().isNotEmpty)
            _buildDetailRow('Notes', subscription.notes!),
          _buildActions(context),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return ListTile(
      title: Text(label,
          style:
              const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
      subtitle: Text(value),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Column(
      children: [
        _buildAction(
          context,
          subscription.isPinned
              ? 'Unpin this subscription.'
              : 'Pin this subscription',
          subscription.isPinned ? Icons.push_pin_outlined : Icons.push_pin,
          () => _togglePin(context),
        ),
        _buildAction(
          context,
          subscription.isPaused
              ? 'Continue this subscription'
              : 'Pause this subscription',
          subscription.isPaused ? Icons.play_arrow : Icons.pause,
          () => _togglePause(context),
        ),
        _buildAction(
          context,
          'Delete this subscription',
          Icons.delete,
          () => _deleteItem(context),
          color: Colors.red,
        ),
      ],
    );
  }

  Widget _buildAction(
      BuildContext context, String label, IconData icon, VoidCallback onTap,
      {Color? color}) {
    return ListTile(
      title: Text(label),
      trailing: Icon(icon, color: color),
      onTap: onTap,
    );
  }

  void _togglePin(BuildContext context) {
    subscription.isPinned = !subscription.isPinned;
    _saveItem(context);
  }

  void _togglePause(BuildContext context) {
    subscription.isPaused = !subscription.isPaused;
    _saveItem(context);
  }

  Future<void> _deleteItem(BuildContext context) async {
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Deletion is not supported on the web')),
      );
    } else {
      final persistenceController = PersistenceController.instance;
      await persistenceController.deleteSubscription(subscription);
      Navigator.of(context).pop();
    }
  }

  void _saveItem(BuildContext context) {
    final viewContext = PersistenceController.instance;
    viewContext.saveSubscription(subscription);
  }

  String _repeatPattern(Subscription subscription) {
    switch (subscription.repeatPattern) {
      case 'monthly':
        return 'Monthly';
      case 'yearly':
        return 'Yearly';
      default:
        return '';
    }
  }

  DateTime? _calculatePreviousBillDate(Subscription subscription) {
    if (subscription.date == null || subscription.repeatPattern == null) {
      return null;
    }
    final today = DateTime.now();
    final startBillDate = subscription.date!;
    DateTime potentialPreviousBillDate = startBillDate;
    Duration interval;
    if (subscription.repeatPattern == 'monthly') {
      interval = const Duration(days: 30);
    } else if (subscription.repeatPattern == 'yearly') {
      interval = const Duration(days: 365);
    } else {
      return null;
    }

    DateTime? lastBillDate;
    while (potentialPreviousBillDate.isBefore(today)) {
      lastBillDate = potentialPreviousBillDate;
      potentialPreviousBillDate = potentialPreviousBillDate.add(interval);
    }

    return lastBillDate;
  }

  DateTime? _calculateNextBillDate(Subscription subscription) {
    if (subscription.date == null) {
      return null;
    }
    final today = DateTime.now();
    DateTime nextBillDate = subscription.date!;
    Duration interval;
    if (subscription.repeatPattern == 'monthly') {
      interval = const Duration(days: 30);
    } else if (subscription.repeatPattern == 'yearly') {
      interval = const Duration(days: 365);
    } else {
      return null;
    }

    while (nextBillDate.isBefore(today)) {
      nextBillDate = nextBillDate.add(interval);
    }
    return nextBillDate;
  }
}
