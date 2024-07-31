import 'package:easy_wallet/easy_wallet_app.dart';
import 'package:easy_wallet/views/components/card_section_component.dart';
import 'package:easy_wallet/views/subscription/edit.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
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
              isDarkMode: isDarkMode,
              children: [
                CardDetailRow(
                    label: Intl.message('costs'),
                    value: '${subscription.amount.toStringAsFixed(2)} €',
                    isDarkMode: isDarkMode),
                CardDetailRow(
                    label: Intl.message('repetitionRate'),
                    value: subscription.getRepeatPattern().translate(),
                    isDarkMode: isDarkMode),
              ],
            ),
            const SizedBox(height: 20),
            CardSection(
              title: Intl.message('invoiceInformation'),
              isDarkMode: isDarkMode,
              children: [
                CardDetailRow(
                    label: Intl.message('nextInvoice'),
                    value: _formatDate(subscription.calculateNextBillDate()),
                    isDarkMode: isDarkMode),
                CardDetailRow(
                    label: Intl.message('previousInvoice'),
                    value:
                        _formatDate(subscription.calculatePreviousBillDate()),
                    isDarkMode: isDarkMode),
                CardDetailRow(
                    label: Intl.message('firstDebit'),
                    value: _formatDate(subscription.date),
                    isDarkMode: isDarkMode),
                CardDetailRow(
                    label: Intl.message('createdOn'),
                    value: _formatDateTime(subscription.timestamp),
                    isDarkMode: isDarkMode),
              ],
            ),
            const SizedBox(height: 20),
            CardSection(
              title: Intl.message('additionalInformation'),
              isDarkMode: isDarkMode,
              children: [
                CardDetailRow(
                    label: Intl.message('previousDebits'),
                    value: subscription.countPayment().toString(),
                    isDarkMode: isDarkMode),
                CardDetailRow(
                    label: Intl.message('totalCosts'),
                    value: '${subscription.sumPayment().toStringAsFixed(2)} €',
                    isDarkMode: isDarkMode),
                if (subscription.notes != null &&
                    subscription.notes!.trim().isNotEmpty)
                  CardDetailRow(
                      label: Intl.message('notes'),
                      value: subscription.notes!,
                      isDarkMode: isDarkMode),
              ],
            ),
            const SizedBox(height: 20),
            CardSection(
              title: Intl.message('actions'),
              isDarkMode: isDarkMode,
              children: [
                _buildAction(
                  subscription.isPinned
                      ? Intl.message('unpinSubscription')
                      : Intl.message('pinSubscription'),
                  subscription.isPinned
                      ? CupertinoIcons.pin_slash
                      : CupertinoIcons.pin,
                  () => _togglePin(),
                  color:
                      subscription.isPinned ? CupertinoColors.systemBlue : null,
                  isDarkMode: isDarkMode,
                ),
                _buildAction(
                  subscription.isPaused
                      ? Intl.message('continueSubscription')
                      : Intl.message('pauseSubscription'),
                  subscription.isPaused
                      ? CupertinoIcons.play_arrow_solid
                      : CupertinoIcons.pause,
                  () => _togglePause(),
                  isDarkMode: isDarkMode,
                ),
                _buildAction(
                  Intl.message('deleteSubscription'),
                  CupertinoIcons.delete,
                  () => _deleteItem(),
                  color: CupertinoColors.destructiveRed,
                  isDarkMode: isDarkMode,
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
        _buildImage(),
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

  Widget _buildAction(String label, IconData icon, VoidCallback onTap,
      {Color? color, required bool isDarkMode}) {
    return CupertinoFormRow(
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: onTap,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: EasyWalletApp.responsiveTextStyle(16, context,
                  color: color ?? CupertinoColors.systemGrey),
            ),
            Icon(
              icon,
              color: color ??
                  (isDarkMode
                      ? CupertinoColors.systemGrey
                      : CupertinoColors.black),
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
          title: Text(Intl.message('hint'),
              style: EasyWalletApp.responsiveTextStyle(16, context)),
          content: Text(Intl.message('Deletion is not supported on the web'),
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
