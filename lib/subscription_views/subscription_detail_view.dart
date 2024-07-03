import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'subscription_edit_view.dart';
import 'package:easy_wallet/model/subscription.dart';
import 'package:easy_wallet/persistence_controller.dart';

class SubscriptionDetailView extends StatefulWidget {
  final Subscription subscription;
  final ValueChanged<Subscription> onUpdate;
  final ValueChanged<Subscription> onDelete;

  const SubscriptionDetailView({super.key, required this.subscription, required this.onUpdate, required this.onDelete});

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
    final isDarkMode = MediaQuery.of(context).platformBrightness == Brightness.dark;

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Abonnements'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () {
            Navigator.push(
              context,
              CupertinoPageRoute(
                builder: (context) => SubscriptionEditView(
                  subscription: subscription,
                  onUpdate: (updatedSubscription) {
                    setState(() {
                      subscription = updatedSubscription;
                    });
                    widget.onUpdate(updatedSubscription);
                  },
                ),
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
            _buildHeader(isDarkMode),
            const SizedBox(height: 20),
            _buildCardSection(
              'Allgemeine Informationen',
              [
                _buildDetailRow('Kosten', '${subscription.amount.toStringAsFixed(2)} €', isDarkMode),
                _buildDetailRow('Wiederholungsrate', _repeatPattern(subscription), isDarkMode),
              ],
              isDarkMode,
            ),
            const SizedBox(height: 20),
            _buildCardSection(
              'Rechnungsinformationen',
              [
                _buildDetailRow('Nächste Rechnung', _formatDate(_calculateNextBillDate(subscription)), isDarkMode),
                _buildDetailRow('Vorherige Rechnung', _formatDate(_calculatePreviousBillDate(subscription)), isDarkMode),
                _buildDetailRow('Erste Abbuchung', _formatDate(subscription.date), isDarkMode),
                _buildDetailRow('Erstellt am', _formatDateTime(subscription.timestamp), isDarkMode),
              ],
              isDarkMode,
            ),
            const SizedBox(height: 20),
            _buildCardSection(
              'Zusätzliche Informationen',
              [
                _buildDetailRow('Bisherige Abbuchungen', _countPayment(subscription).toString(), isDarkMode),
                _buildDetailRow('Kosten insgesamt', '${_sumPayment(subscription).toStringAsFixed(2)} €', isDarkMode),
                if (subscription.notes != null && subscription.notes!.trim().isNotEmpty)
                  _buildDetailRow('Notizen', subscription.notes!, isDarkMode),
              ],
              isDarkMode,
            ),
            const SizedBox(height: 20),
            _buildCardSection(
              'Aktionen',
              [
                _buildAction(
                  subscription.isPinned ? 'Dieses Abonnement lösen' : 'Dieses Abonnement anheften',
                  subscription.isPinned ? CupertinoIcons.pin_slash : CupertinoIcons.pin,
                      () => _togglePin(),
                  color: subscription.isPinned ? CupertinoColors.systemBlue : null,
                  isDarkMode: isDarkMode,
                ),
                _buildAction(
                  subscription.isPaused ? 'Dieses Abonnement fortsetzen' : 'Dieses Abonnement pausieren',
                  subscription.isPaused ? CupertinoIcons.play_arrow_solid : CupertinoIcons.pause,
                      () => _togglePause(),
                  isDarkMode: isDarkMode,
                ),
                _buildAction(
                  'Dieses Abonnement löschen',
                  CupertinoIcons.delete,
                      () => _deleteItem(),
                  color: CupertinoColors.destructiveRed,
                  isDarkMode: isDarkMode,
                ),
              ],
              isDarkMode,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardSection(String title, List<Widget> children, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: isDarkMode ? CupertinoColors.darkBackgroundGray : CupertinoColors.systemGrey6,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: isDarkMode ? CupertinoColors.black : CupertinoColors.systemGrey4,
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
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? CupertinoColors.white : CupertinoColors.black,
            ),
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDarkMode) {
    return Row(
      children: [
        _buildImage(),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            subscription.title,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? CupertinoColors.white : CupertinoColors.black,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, bool isDarkMode) {
    return CupertinoFormRow(
      prefix: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: isDarkMode ? CupertinoColors.systemGrey : CupertinoColors.systemGrey,
        ),
      ),
      child: Text(
        value,
        style: TextStyle(
          fontSize: 16,
          color: isDarkMode ? CupertinoColors.white : CupertinoColors.black,
        ),
      ),
    );
  }

  Widget _buildAction(String label, IconData icon, VoidCallback onTap, {Color? color, required bool isDarkMode}) {
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
                color: color ?? (isDarkMode ? CupertinoColors.systemGrey : CupertinoColors.black),
              ),
            ),
            Icon(
              icon,
              color: color ?? (isDarkMode ? CupertinoColors.systemGrey : CupertinoColors.black),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage() {
    if (subscription.url == null) {
      return const Icon(
        CupertinoIcons.exclamationmark_triangle,
        color: CupertinoColors.systemGrey,
        size: 40,
      );
    } else if (subscription.url!.isEmpty) {
      return const Icon(
        Icons.account_balance_wallet_rounded,
        color: CupertinoColors.systemGrey,
        size: 40,
      );
    } else {
      return CachedNetworkImage(
        imageUrl:
        'https://www.google.com/s2/favicons?sz=64&domain_url=${Uri.parse(subscription.url!).host}',
        placeholder: (context, url) => const CupertinoActivityIndicator(),
        errorWidget: (context, url, error) => const Icon(
          CupertinoIcons.exclamationmark_triangle,
          color: CupertinoColors.systemGrey,
          size: 40,
        ),
        width: 40,
        height: 40,
      );
    }
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
      widget.onDelete(subscription);
      Navigator.of(context).pop();
    }
  }

  void _saveItem() async {
    final persistenceController = PersistenceController.instance;
    await persistenceController.saveSubscription(subscription);
    widget.onUpdate(subscription);
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
