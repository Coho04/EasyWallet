import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'subscription_edit_view.dart';
import 'package:easy_wallet/model/subscription.dart';
import 'package:easy_wallet/persistence_controller.dart';

class SubscriptionDetailView extends StatefulWidget {
  final Subscription subscription;

  const SubscriptionDetailView({super.key, required this.subscription});

  @override
  SubscriptionDetailViewState createState() => SubscriptionDetailViewState();
}

class SubscriptionDetailViewState extends State<SubscriptionDetailView> {
  late Subscription subscription;

  @override
  void initState() {
    super.initState();
    subscription = widget.subscription;
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Abonnements'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () {
            Navigator.push(
              context,
              CupertinoPageRoute(
                builder: (context) => SubscriptionEditView(subscription: subscription),
              ),
            );
          },
          child: const Icon(CupertinoIcons.pencil),
        ),
      ),
      child: SafeArea(
        top: true,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          children: <Widget>[
            const SizedBox(height: 20),
            _buildHeader(),
            const SizedBox(height: 20),
            _buildCardSection('Allgemeine Informationen', [
              _buildDetailRow('Kosten', '${subscription.amount.toStringAsFixed(2)} €'),
              _buildDetailRow('Wiederholungsrate', _repeatPattern(subscription)),
            ]),
            const SizedBox(height: 20),
            _buildCardSection('Rechnungsinformationen', [
              _buildDetailRow('Nächste Rechnung', _formatDate(_calculateNextBillDate(subscription))),
              _buildDetailRow('Vorherige Rechnung', _formatDate(_calculatePreviousBillDate(subscription))),
              _buildDetailRow('Erste Abbuchung', _formatDate(subscription.date)),
              _buildDetailRow('Erstellt am', _formatDateTime(subscription.timestamp)),
            ]),
            const SizedBox(height: 20),
            _buildCardSection('Zusätzliche Informationen', [
              _buildDetailRow('Bisherige Abbuchungen', _countPayment(subscription).toString()),
              _buildDetailRow('Kosten insgesamt', '${_sumPayment(subscription).toStringAsFixed(2)} €'),
              if (subscription.notes != null && subscription.notes!.trim().isNotEmpty)
                _buildDetailRow('Notizen', subscription.notes!),
            ]),
            const SizedBox(height: 20),
            _buildCardSection('Aktionen', [
              _buildAction(
                subscription.isPinned ? 'Dieses Abonnement lösen' : 'Dieses Abonnement anheften',
                subscription.isPinned ? CupertinoIcons.pin_slash : CupertinoIcons.pin,
                    () => _togglePin(),
                color: subscription.isPinned ? CupertinoColors.systemBlue : null,
              ),
              _buildAction(
                subscription.isPaused ? 'Dieses Abonnement fortsetzen' : 'Dieses Abonnement pausieren',
                subscription.isPaused ? CupertinoIcons.play_arrow_solid : CupertinoIcons.pause,
                    () => _togglePause(),
              ),
              _buildAction(
                'Dieses Abonnement löschen',
                CupertinoIcons.delete,
                    () => _deleteItem(),
                color: CupertinoColors.destructiveRed,
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildCardSection(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: const [
          BoxShadow(
            color: CupertinoColors.systemGrey4,
            blurRadius: 10.0,
            spreadRadius: 1.0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        CachedNetworkImage(
          imageUrl: _subscriptionUrl(),
          placeholder: (context, url) => const CupertinoActivityIndicator(),
          errorWidget: (context, url, error) => const Icon(CupertinoIcons.exclamationmark_triangle),
          width: 40,
          height: 40,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            subscription.title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return CupertinoFormRow(
      prefix: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: CupertinoColors.systemGrey,
        ),
      ),
      child: Text(value, style: const TextStyle(fontSize: 16)),
    );
  }

  Widget _buildAction(String label, IconData icon, VoidCallback onTap, {Color? color}) {
    return CupertinoFormRow(
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: onTap,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                color: color ?? CupertinoColors.systemGrey,
              ),
            ),
            Icon(icon, color: color ?? CupertinoColors.systemGrey),
          ],
        ),
      ),
    );
  }

  void _togglePin() {
    setState(() {
      subscription.isPinned = !subscription.isPinned;
    });
    _saveItem();
  }

  void _togglePause() {
    setState(() {
      subscription.isPaused = !subscription.isPaused;
    });
    _saveItem();
  }

  String _subscriptionUrl() {
    if (subscription.url != null) {
      return 'https://www.google.com/s2/favicons?sz=64&domain_url=${Uri.parse(subscription.url!).host}';
    }
    return '';
  }

  Future<void> _deleteItem() async {
    if (kIsWeb) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Hinweis'),
          content: const Text('Löschen wird im Web nicht unterstützt'),
          actions: [
            CupertinoDialogAction(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      );
    } else {
      final persistenceController = PersistenceController.instance;
      await persistenceController.deleteSubscription(subscription);
      Navigator.of(context).pop();
    }
  }

  void _saveItem() async {
    final persistenceController = PersistenceController.instance;
    await persistenceController.saveSubscription(subscription);
  }

  String _repeatPattern(Subscription subscription) {
    switch (subscription.repeatPattern) {
      case 'monthly':
        return 'Monatlich';
      case 'yearly':
        return 'Jährlich';
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

  int _countPayment(Subscription subscription) {
    if (subscription.date == null) {
      return 0;
    }
    final today = DateTime.now();
    DateTime nextBillDate = subscription.date!;
    Duration interval;
    if (subscription.repeatPattern == 'yearly') {
      interval = const Duration(days: 365);
    } else {
      interval = const Duration(days: 30);
    }

    int count = 0;
    while (nextBillDate.isBefore(today)) {
      nextBillDate = nextBillDate.add(interval);
      count++;
    }
    return count;
  }

  double _sumPayment(Subscription subscription) {
    if (subscription.date == null) {
      return 0.0;
    }
    final today = DateTime.now();
    DateTime nextBillDate = subscription.date!;
    Duration interval;
    if (subscription.repeatPattern == 'yearly') {
      interval = const Duration(days: 365);
    } else {
      interval = const Duration(days: 30);
    }

    double sum = 0;
    while (nextBillDate.isBefore(today)) {
      nextBillDate = nextBillDate.add(interval);
      sum += subscription.amount;
    }
    return sum;
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Unbekannt';
    return DateFormat.yMMMd().format(date);
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return 'Unbekannt';
    return DateFormat('EEEE, dd.MM.yyyy HH:mm').format(dateTime);
  }
}
