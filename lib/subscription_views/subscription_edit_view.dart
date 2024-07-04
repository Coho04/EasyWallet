import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_wallet/enum/payment_rate.dart';
import 'package:easy_wallet/enum/remember_cycle.dart';
import 'package:easy_wallet/model/subscription.dart';
import 'package:easy_wallet/settings.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:easy_wallet/persistence_controller.dart';

class SubscriptionEditView extends StatefulWidget {
  final Subscription subscription;
  final ValueChanged<Subscription> onUpdate;

  const SubscriptionEditView(
      {super.key, required this.subscription, required this.onUpdate});

  @override
  SubscriptionEditViewState createState() => SubscriptionEditViewState();
}

class SubscriptionEditViewState extends State<SubscriptionEditView> {
  late TextEditingController _titleController;
  late TextEditingController _urlController;
  late TextEditingController _amountController;
  late TextEditingController _notesController;
  DateTime _date = DateTime.now();
  String _paymentRate = PaymentRate.monthly.value;
  String _rememberCycle = RememberCycle.dayBefore.value;

  bool _titleValid = true;
  bool _amountValid = true;

  String _currency = 'USD';

  Future<void> _loadCurrency() async {
    final currency = await Settings.getCurrency();
    setState(() {
      _currency = currency.name;
    });
  }

  @override
  void initState() {
    super.initState();
    _loadCurrency();
    _titleController = TextEditingController(text: widget.subscription.title);
    _urlController = TextEditingController(text: widget.subscription.url ?? '');
    _amountController =
        TextEditingController(text: widget.subscription.amount.toString());
    _notesController =
        TextEditingController(text: widget.subscription.notes ?? '');
    _date = widget.subscription.date ?? DateTime.now();
    _paymentRate =
        widget.subscription.repeatPattern ?? PaymentRate.monthly.value;
    _rememberCycle =
        widget.subscription.rememberCycle ?? RememberCycle.dayBefore.value;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _urlController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  bool _validateForm() {
    final amount = double.tryParse(_amountController.text.replaceAll(',', '.'));
    setState(() {
      _titleValid = _titleController.text.isNotEmpty;
      _amountValid = amount != null && amount >= 0 && amount <= 10000;
    });
    return _titleValid && _amountValid;
  }

  void _saveItem() {
    if (_validateForm()) {
      final subscription = widget.subscription;
      subscription.title = _titleController.text;
      if (_urlController.text == 'https://') {
        subscription.url = '';
      } else {
        subscription.url = _urlController.text;
      }
      subscription.amount =
          double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0.0;
      subscription.date = _date;
      subscription.notes = _notesController.text;
      subscription.repeatPattern = _paymentRate;
      subscription.rememberCycle = _rememberCycle;

      final viewContext = PersistenceController.instance;
      viewContext.saveSubscription(subscription);
      widget.onUpdate(subscription);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode =
        MediaQuery.of(context).platformBrightness == Brightness.dark;

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(Intl.message('editSubscription')),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _saveItem,
          child: Text(Intl.message('save')),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            child: ListView(
              children: [
                _buildHeader(isDarkMode),
                const SizedBox(height: 16),
                _buildTextField(
                  _urlController,
                  'URL',
                  isDarkMode: isDarkMode,
                  keyboardType: TextInputType.url,
                  onChanged: (value) {
                    if (!value.startsWith('https://')) {
                      _urlController.text =
                      'https://${value.replaceFirst('https://', '')}';
                      _urlController.selection = TextSelection.fromPosition(
                          TextPosition(offset: _urlController.text.length));
                    }
                  },
                ),
                const SizedBox(height: 16),
                _buildAmountField(isDarkMode),
                const SizedBox(height: 16),
                _buildDropdownField(
                  Intl.message('paymentRate'),
                  _paymentRate,
                  PaymentRate.values,
                      (value) {
                    setState(() {
                      _paymentRate = value!;
                    });
                  },
                  isDarkMode,
                ),
                const SizedBox(height: 16),
                _buildDatePickerField(
                  Intl.message('startDate'),
                  _date,
                  _pickDate,
                  isDarkMode,
                ),
                const SizedBox(height: 16),
                _buildDropdownField(
                  Intl.message('remembering'),
                  _rememberCycle,
                  RememberCycle.values,
                      (value) {
                    setState(() {
                      _rememberCycle = value!;
                    });
                  },
                  isDarkMode,
                ),
                const SizedBox(height: 16),
                _buildTextField(_notesController, Intl.message('notes'),
                    maxLines: 5, isDarkMode: isDarkMode),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDarkMode) {
    return Row(
      children: [
        _buildImage(),
        const SizedBox(width: 16),
        Expanded(
          child: CupertinoTextField(
            controller: _titleController,
            placeholder: Intl.message('Title'),
            style: TextStyle(
                color:
                isDarkMode ? CupertinoColors.white : CupertinoColors.black),
            decoration: BoxDecoration(
              color: isDarkMode
                  ? CupertinoColors.darkBackgroundGray
                  : CupertinoColors.systemGrey6,
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(
                color: _titleValid
                    ? (isDarkMode
                    ? CupertinoColors.systemGrey
                    : CupertinoColors.systemGrey4)
                    : CupertinoColors.destructiveRed,
              ),
            ),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildImage() {
    if (_urlController.text.isEmpty) {
      return const Icon(
        Icons.account_balance_wallet_rounded,
        color: CupertinoColors.systemGrey,
        size: 40,
      );
    } else {
      return CachedNetworkImage(
        imageUrl:
        'https://www.google.com/s2/favicons?sz=64&domain_url=${Uri.parse(_urlController.text).host}',
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

  Widget _buildTextField(TextEditingController controller, String placeholder,
      {TextInputType keyboardType = TextInputType.text,
        int maxLines = 1,
        required bool isDarkMode,
        ValueChanged<String>? onChanged}) {
    return CupertinoTextField(
      controller: controller,
      placeholder: placeholder,
      keyboardType: keyboardType,
      onChanged: onChanged,
      style: TextStyle(
          color: isDarkMode ? CupertinoColors.white : CupertinoColors.black),
      decoration: BoxDecoration(
        color: isDarkMode
            ? CupertinoColors.darkBackgroundGray
            : CupertinoColors.systemGrey6,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(
          color: isDarkMode
              ? CupertinoColors.systemGrey
              : CupertinoColors.systemGrey6,
          width: 1.0,
        ),
      ),
      maxLines: maxLines,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
    );
  }

  Widget _buildAmountField(bool isDarkMode) {
    return Row(
      children: [
        Expanded(
          child: CupertinoTextField(
            controller: _amountController,
            placeholder: Intl.message('Costs'),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: TextStyle(
                color:
                isDarkMode ? CupertinoColors.white : CupertinoColors.black),
            decoration: BoxDecoration(
              color: isDarkMode
                  ? CupertinoColors.darkBackgroundGray
                  : CupertinoColors.systemGrey6,
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(
                color: _amountValid
                    ? (isDarkMode
                    ? CupertinoColors.systemGrey
                    : CupertinoColors.systemGrey4)
                    : CupertinoColors.destructiveRed,
              ),
            ),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          ),
        ),
        const SizedBox(width: 8),
        Text(_currency,
            style: TextStyle(
                color: isDarkMode
                    ? CupertinoColors.white
                    : CupertinoColors.black)),
      ],
    );
  }

  Widget _buildDropdownField<T>(String label, String currentValue,
      List<T> options, ValueChanged<String?> onChanged, bool isDarkMode) {
    return CupertinoFormRow(
      prefix: Padding(
        padding: const EdgeInsets.only(right: 16.0),
        child: Text(label,
            style: TextStyle(
                color: isDarkMode
                    ? CupertinoColors.white
                    : CupertinoColors.black)),
      ),
      child: GestureDetector(
        onTap: () => _showOptions(context, options, onChanged, isDarkMode),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: isDarkMode
                ? CupertinoColors.darkBackgroundGray
                : CupertinoColors.systemGrey6,
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(
                color: isDarkMode
                    ? CupertinoColors.systemGrey
                    : CupertinoColors.systemGrey4),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _capitalize(_translateEnum(currentValue, options)),
                style: TextStyle(
                    fontSize: 16,
                    color: isDarkMode
                        ? CupertinoColors.white
                        : CupertinoColors.inactiveGray),
              ),
              Icon(
                CupertinoIcons.chevron_down,
                size: 20,
                color: isDarkMode
                    ? CupertinoColors.white
                    : CupertinoColors.inactiveGray,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDatePickerField(
      String label, DateTime date, VoidCallback onTap, bool isDarkMode) {
    return CupertinoFormRow(
      prefix: Padding(
        padding: const EdgeInsets.only(right: 16.0),
        child: Text(label,
            style: TextStyle(
                color: isDarkMode
                    ? CupertinoColors.white
                    : CupertinoColors.black)),
      ),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: isDarkMode
                ? CupertinoColors.darkBackgroundGray
                : CupertinoColors.systemGrey6,
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(
                color: isDarkMode
                    ? CupertinoColors.systemGrey
                    : CupertinoColors.systemGrey4),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DateFormat('dd.MM.yyyy').format(date),
                style: TextStyle(
                    fontSize: 16,
                    color: isDarkMode
                        ? CupertinoColors.white
                        : CupertinoColors.inactiveGray),
              ),
              Icon(
                CupertinoIcons.calendar,
                size: 20,
                color: isDarkMode
                    ? CupertinoColors.white
                    : CupertinoColors.inactiveGray,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final DateTime? pickedDate = await showCupertinoModalPopup(
      context: context,
      builder: (context) {
        return Container(
          height: 260,
          color: CupertinoColors.systemBackground.resolveFrom(context),
          child: Column(
            children: [
              SizedBox(
                height: 200,
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.date,
                  initialDateTime: _date,
                  onDateTimeChanged: (DateTime newDate) {
                    setState(() {
                      _date = newDate;
                    });
                  },
                ),
              ),
              CupertinoButton(
                child: const Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
    if (pickedDate != null && pickedDate != _date) {
      setState(() {
        _date = pickedDate;
      });
    }
  }

  Future<void> _showOptions<T>(BuildContext context, List<T> options,
      ValueChanged<String?> onChanged, bool isDarkMode) async {
    await showCupertinoModalPopup<String>(
      context: context,
      builder: (BuildContext context) {
        return CupertinoActionSheet(
          actions: options.map((option) {
            final String value = (option is PaymentRate) ? option.value : (option as RememberCycle).value;
            return CupertinoActionSheetAction(
              child: Text(_capitalize(_translateEnum(value, options))),
              onPressed: () {
                onChanged(value);
                Navigator.pop(context);
              },
            );
          }).toList(),
          cancelButton: CupertinoActionSheetAction(
            child: Text(Intl.message('cancel')),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        );
      },
    );
  }

  String _capitalize(String s) {
    if (s.isEmpty) {
      return s;
    }
    return s[0].toUpperCase() + s.substring(1);
  }

  String _translateEnum<T>(String value, List<T> options) {
    for (var option in options) {
      if (option is PaymentRate && option.value == value) {
        return option.translate();
      } else if (option is RememberCycle && option.value == value) {
        return option.translate();
      }
    }
    return value;
  }
}
