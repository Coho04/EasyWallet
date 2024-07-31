import 'package:easy_wallet/easy_wallet_app.dart';
import 'package:easy_wallet/views/components/card_section_component.dart';
import 'package:easy_wallet/views/subscription/edit.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:easy_wallet/model/subscription.dart';
import 'package:easy_wallet/persistence_controller.dart';

class SubscriptionShowView extends StatefulWidget {
  final Subscription subscription;
  final ValueChanged<Subscription> onUpdate;
  final ValueChanged<Subscription> onDelete;

  const SubscriptionShowView(
      {super.key,
      required this.subscription,
      required this.onUpdate,
      required this.onDelete});

  @override
  SubscriptionShowViewState createState() => SubscriptionShowViewState();
}

class SubscriptionShowViewState extends State<SubscriptionShowView> {
  late Subscription subscription;

  @override
  void initState() {
    super.initState();
    subscription = widget.subscription;
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode =
        MediaQuery.of(context).platformBrightness == Brightness.dark;

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(
          Intl.message('subscriptions'),
          style: EasyWalletApp.responsiveTextStyle(24, context),
        ),
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
            CardSection(
              title: Intl.message('generalInformation'),
              children: [
                CardDetailRow(
                  label: Intl.message('costs'),
                  value: '${subscription.amount.toStringAsFixed(2)} €',
                ),
                CardDetailRow(
                  label: Intl.message('repetitionRate'),
                  value: subscription.getRepeatPattern().translate(),
                ),
              ],
            ),
            const SizedBox(height: 20),
            CardSection(
              title: Intl.message('invoiceInformation'),
              children: [
                CardDetailRow(
                  label: Intl.message('nextInvoice'),
                  value: _formatDate(subscription.getNextBillDate()),
                ),
                CardDetailRow(
                  label: Intl.message('previousInvoice'),
                  value: _formatDate(subscription.calculatePreviousBillDate()),
                ),
                CardDetailRow(
                  label: Intl.message('firstDebit'),
                  value: _formatDate(subscription.date),
                ),
                CardDetailRow(
                  label: Intl.message('createdOn'),
                  value: _formatDateTime(subscription.timestamp),
                  softBreak: true,
                ),
              ],
            ),
            const SizedBox(height: 20),
            CardSection(
              title: Intl.message('additionalInformation'),
              children: [
                CardDetailRow(
                  label: Intl.message('previousDebits'),
                  value: subscription.countPayment().toString(),
                ),
                CardDetailRow(
                  label: Intl.message('totalCosts'),
                  value: '${subscription.sumPayment().toStringAsFixed(2)} €',
                ),
                if (subscription.notes != null &&
                    subscription.notes!.trim().isNotEmpty)
                  CardDetailRow(
                    label: Intl.message('notes'),
                    value: subscription.notes!,
                  ),
              ],
            ),
            const SizedBox(height: 20),
            CardSection(
              title: Intl.message('actions'),
              children: [
                CardActionButton(
                  label: subscription.isPinned
                      ? Intl.message('unpinSubscription')
                      : Intl.message('pinSubscription'),
                  icon: subscription.isPinned
                      ? CupertinoIcons.pin_slash
                      : CupertinoIcons.pin,
                  onPressed: () => _togglePin(),
                  color:
                      subscription.isPinned ? CupertinoColors.systemBlue : null,
                ),
                CardActionButton(
                  label: subscription.isPaused
                      ? Intl.message('continueSubscription')
                      : Intl.message('pauseSubscription'),
                  icon: subscription.isPaused
                      ? CupertinoIcons.play_arrow_solid
                      : CupertinoIcons.pause,
                  onPressed: () => _togglePause(),
                ),
                CardActionButton(
                  label: Intl.message('deleteSubscription'),
                  icon: CupertinoIcons.delete,
                  onPressed: () => _deleteItem(),
                  color: CupertinoColors.destructiveRed,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDarkMode) {
    return Row(
      children: [
        subscription.buildImage(),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            subscription.title,
            style: EasyWalletApp.responsiveTextStyle(
              24,
              context,
              bold: true,
              color: isDarkMode ? CupertinoColors.white : CupertinoColors.black,
            ),
          ),
        ),
      ],
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

  Future<void> _deleteItem() async {
    if (kIsWeb) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: Text(Intl.message('hint'),
              style: EasyWalletApp.responsiveTextStyle(16, context)),
          content: Text(Intl.message('deletionIsNotSupportedOnTheWeb'),
              style: EasyWalletApp.responsiveTextStyle(16, context)),
          actions: [
            CupertinoDialogAction(
              child: Text('OK',
                  style: EasyWalletApp.responsiveTextStyle(16, context)),
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

  String _formatDate(DateTime? date) {
    if (date == null) return Intl.message('unknown');
    return DateFormat.yMMMd().format(date);
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return Intl.message('unknown');
    return DateFormat('EEEE, dd.MM.yyyy HH:mm').format(dateTime);
  }
}
