import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_wallet/easy_wallet_app.dart';
import 'package:easy_wallet/enum/currency.dart';
import 'package:easy_wallet/enum/payment_rate.dart';
import 'package:easy_wallet/enum/remember_cycle.dart';
import 'package:easy_wallet/model/subscription.dart';
import 'package:easy_wallet/settings.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:easy_wallet/persistence_controller.dart';

class SubscriptionCreateView extends StatefulWidget {
  const SubscriptionCreateView({super.key});

  @override
  SubscriptionCreateViewState createState() => SubscriptionCreateViewState();
}

class SubscriptionCreateViewState extends State<SubscriptionCreateView> {
  final _titleController = TextEditingController();
  final _urlController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  String _selectedPayRate = PaymentRate.monthly.value;
  String _selectedRememberCycle = RememberCycle.sameDay.value;
  String _currency = Currency.usd.symbol;

  bool _isTitleValid = true;
  bool _isAmountValid = true;

  @override
  void initState() {
    super.initState();
    _loadCurrency();
  }

  Future<void> _loadCurrency() async {
    final currency = await Settings.getCurrency();
    setState(() {
      _currency = currency.symbol;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode =
        MediaQuery.of(context).platformBrightness == Brightness.dark;

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(
          Intl.message('addSubscription'),
          style: EasyWalletApp.responsiveTextStyle(20, context),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _saveItem,
          child: Text(
            Intl.message('save'),
            style: EasyWalletApp.responsiveTextStyle(16, context,
                color: isDarkMode
                    ? CupertinoColors.white
                    : CupertinoColors.activeBlue),
          ),
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
                  autocorrect: false,
                  onChanged: (value) {
                    if (!value.startsWith('https://') &&
                        !value.startsWith('http://')) {
                      _urlController.text = 'https://$value';
                      _urlController.selection = TextSelection.fromPosition(
                          TextPosition(offset: _urlController.text.length));
                    }
                    setState(() {});
                  },
                ),
                const SizedBox(height: 16),
                _buildAmountField(isDarkMode),
                const SizedBox(height: 16),
                _buildDatePickerField(Intl.message('startDate'), _selectedDate,
                    _pickDate, isDarkMode),
                const SizedBox(height: 16),
                _buildDropdownField(
                  Intl.message('paymentRate'),
                  _selectedPayRate,
                  PaymentRate.values,
                  (value) {
                    setState(() {
                      _selectedPayRate = value!;
                    });
                  },
                  isDarkMode,
                ),
                const SizedBox(height: 16),
                _buildDropdownField(
                  Intl.message('remembering'),
                  _selectedRememberCycle,
                  RememberCycle.values,
                  (value) {
                    setState(() {
                      _selectedRememberCycle = value!;
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

  Widget _buildTextField(TextEditingController controller, String placeholder,
      {TextInputType keyboardType = TextInputType.text,
      bool autocorrect = false,
      ValueChanged<String>? onChanged,
      int maxLines = 1,
      required bool isDarkMode,
      bool isValid = true}) {
    return CupertinoTextField(
      controller: controller,
      placeholder: placeholder,
      keyboardType: keyboardType,
      autocorrect: autocorrect,
      onChanged: onChanged,
      style: TextStyle(
          color: isDarkMode ? CupertinoColors.white : CupertinoColors.black),
      decoration: BoxDecoration(
        color: isDarkMode
            ? CupertinoColors.darkBackgroundGray
            : isValid
                ? CupertinoColors.systemGrey6
                : CupertinoColors.systemRed.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(
          color: isValid
              ? (isDarkMode
                  ? CupertinoColors.systemGrey
                  : CupertinoColors.systemGrey6)
              : CupertinoColors.systemRed,
          width: 1.0,
        ),
      ),
      maxLines: maxLines,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
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
            placeholder: Intl.message('title'),
            style: TextStyle(
                color:
                    isDarkMode ? CupertinoColors.white : CupertinoColors.black),
            decoration: BoxDecoration(
              color: isDarkMode
                  ? CupertinoColors.darkBackgroundGray
                  : CupertinoColors.systemGrey6,
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(
                color: _isTitleValid
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
        errorListener: (exception) {
          if (kDebugMode) {
            print('Image loading failed: $exception');
          }
        },
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

  Widget _buildAmountField(bool isDarkMode) {
    return Row(
      children: [
        Expanded(
          child: _buildTextField(
            _amountController,
            Intl.message('costs'),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            isValid: _isAmountValid,
            isDarkMode: isDarkMode,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          _currency,
          style: EasyWalletApp.responsiveTextStyle(16, context,
              color:
                  isDarkMode ? CupertinoColors.white : CupertinoColors.black),
        ),
      ],
    );
  }

  Widget _buildDatePickerField(
      String label, DateTime date, VoidCallback onTap, bool isDarkMode) {
    return CupertinoFormRow(
      prefix: Padding(
        padding: const EdgeInsets.only(right: 16.0),
        child: Text(
          label,
          style: EasyWalletApp.responsiveTextStyle(16, context,
              color:
                  isDarkMode ? CupertinoColors.white : CupertinoColors.black),
        ),
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
                style: EasyWalletApp.responsiveTextStyle(16, context,
                    color: CupertinoColors.inactiveGray),
              ),
              const Icon(
                CupertinoIcons.calendar,
                size: 20,
                color: CupertinoColors.inactiveGray,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownField<T>(String label, String currentValue,
      List<T> options, ValueChanged<String?> onChanged, bool isDarkMode) {
    return CupertinoFormRow(
      prefix: Padding(
        padding: const EdgeInsets.only(right: 16.0),
        child: Text(
          label,
          style: EasyWalletApp.responsiveTextStyle(16, context,
              color:
                  isDarkMode ? CupertinoColors.white : CupertinoColors.black),
        ),
      ),
      child: GestureDetector(
        onTap: () => _showOptions(context, options, onChanged),
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
                style: EasyWalletApp.responsiveTextStyle(16, context,
                    color: CupertinoColors.inactiveGray),
              ),
              const Icon(
                CupertinoIcons.chevron_down,
                size: 20,
                color: CupertinoColors.inactiveGray,
              ),
            ],
          ),
        ),
      ),
    );
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
                  initialDateTime: _selectedDate,
                  use24hFormat: true,
                  onDateTimeChanged: (DateTime newDate) {
                    setState(() {
                      _selectedDate = newDate;
                    });
                  },
                ),
              ),
              CupertinoButton(
                child: Text(
                  'OK',
                  style: EasyWalletApp.responsiveTextStyle(20, context,
                      color: CupertinoColors.activeBlue),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  Future<void> _showOptions<T>(BuildContext context, List<T> options,
      ValueChanged<String?> onChanged) async {
    await showCupertinoModalPopup<String>(
      context: context,
      builder: (BuildContext context) {
        return CupertinoActionSheet(
          actions: options.map((option) {
            final String value = (option is PaymentRate)
                ? option.value
                : (option as RememberCycle).value;
            return CupertinoActionSheetAction(
              child: Text(_capitalize(_translateEnum(value, options)),
                  style: EasyWalletApp.responsiveTextStyle(20, context,
                      color: CupertinoColors.activeBlue)),
              onPressed: () {
                onChanged(value);
                Navigator.pop(context);
              },
            );
          }).toList(),
          cancelButton: CupertinoActionSheetAction(
            child: Text(Intl.message('cancel'),
                style: EasyWalletApp.responsiveTextStyle(20, context,
                    color: CupertinoColors.activeBlue)),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        );
      },
    );
  }

  void _saveItem() {
    final title = _titleController.text.trim();
    final amount = double.tryParse(_amountController.text.replaceAll(',', '.'));
    final url = _urlController.text;
    final notes = _notesController.text.trim();

    setState(() {
      _isTitleValid = title.isNotEmpty;
      _isAmountValid = amount != null && amount >= 0 && amount <= 10000;
    });

    if (_isTitleValid && _isAmountValid) {
      final newSubscription = Subscription(
        title: title,
        amount: amount!,
        date: _selectedDate,
        repeatPattern: _selectedPayRate,
        notes: notes,
        url: url,
        rememberCycle: _selectedRememberCycle,
        timestamp: DateTime.now(),
        isPaused: false,
        isPinned: false,
        repeating: true,
      );

      final viewContext = PersistenceController.instance;
      viewContext.saveSubscription(newSubscription);
      Navigator.of(context).pop();
    }
  }

  String _capitalize(String s) {
    if (s.isEmpty) {
      return s;
    }
    return s[0].toUpperCase() + s.substring(1);
  }
}
