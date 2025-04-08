import 'package:auto_size_text/auto_size_text.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_wallet/easy_wallet_app.dart';
import 'package:easy_wallet/enum/payment_rate.dart';
import 'package:easy_wallet/enum/remember_cycle.dart';
import 'package:easy_wallet/model/subscription.dart';
import 'package:easy_wallet/provider/currency_provider.dart';
import 'package:easy_wallet/provider/subscription_provider.dart';
import 'package:easy_wallet/views/components/form_fields/amount_field.dart';
import 'package:easy_wallet/views/components/form_fields/date_picker_field.dart';
import 'package:easy_wallet/views/components/form_fields/dropdown_field.dart';
import 'package:easy_wallet/views/components/form_fields/text_field.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:multi_select_flutter/util/multi_select_item.dart';
import 'package:multi_select_flutter/util/multi_select_list_type.dart';
import 'package:provider/provider.dart';

import '../../enum/payment_methode.dart';
import '../../model/category.dart';
import '../../provider/category_provider.dart';
import '../components/form_fields/multi_select_dialog_field.dart';

class SubscriptionEditView extends StatefulWidget {
  final Subscription subscription;
  List<Category> selectedCategories;

  SubscriptionEditView(
      {super.key,
      required this.subscription,
      required this.selectedCategories});

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
  String _selectedPayMethode = PaymentMethode.invoice.value;

  bool _titleValid = true;
  bool _amountValid = true;

  @override
  void initState() {
    super.initState();
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
    _selectedPayMethode = widget.subscription.paymentMethode ?? PaymentMethode.invoice.value;
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

  void _saveItem(context) async {
    if (_validateForm()) {
      var subscription = widget.subscription;
      subscription.title = _titleController.text.trim();
      if (_urlController.text == 'https://') {
        subscription.url = '';
      } else {
        subscription.url = _urlController.text;
      }
      subscription.amount =
          double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0.0;
      subscription.date = _date;
      subscription.notes = _notesController.text.trim();
      subscription.repeatPattern = _paymentRate;
      subscription.rememberCycle = _rememberCycle;
      subscription.paymentMethode = _selectedPayMethode;
      subscription =
          await Provider.of<SubscriptionProvider>(context, listen: false)
              .saveSubscription(subscription);
      subscription.assignCategories(widget.selectedCategories);
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode =
        MediaQuery.of(context).platformBrightness == Brightness.dark;
    return Consumer<CurrencyProvider>(
        builder: (context, currencyProvider, child) {
      final currency = currencyProvider.currency;
      return CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          middle: AutoSizeText(
            Intl.message('editSubscription'),
            maxLines: 1,
            style: EasyWalletApp.responsiveTextStyle(context),
          ),
          trailing: CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () => _saveItem(context),
            child: const Icon(CupertinoIcons.floppy_disk),
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
                  EasyWalletTextField(
                    controller: _urlController,
                    placeholder: 'URL',
                    isDarkMode: isDarkMode,
                    keyboardType: TextInputType.url,
                    autocorrect: false,
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
                  AmountField(
                    isDarkMode: isDarkMode,
                    currency: currency,
                    controller: _amountController,
                    isValid: _amountValid,
                  ),
                  const SizedBox(height: 16),
                  EasyWalletDatePickerField(
                      label: Intl.message('startDate'),
                      date: _date,
                      onTap: _pickDate,
                      isDarkMode: isDarkMode),
                  const SizedBox(height: 16),
                  EasyWalletDropdownField(
                    label: Intl.message('paymentRate'),
                    currentValue: _paymentRate,
                    options: PaymentRate.values,
                    onChanged: (value) {
                      setState(() {
                        _paymentRate = value!;
                      });
                    },
                    isDarkMode: isDarkMode,
                  ),
                  EasyWalletDropdownField(
                    label: Intl.message('paymentMethode'),
                    currentValue: _selectedPayMethode,
                    options: PaymentMethode.values,
                    onChanged: (value) {
                      setState(() {
                        _selectedPayMethode = value!;
                      });
                    },
                    isDarkMode: isDarkMode,
                  ),
                  const SizedBox(height: 16),
                  EasyWalletDropdownField(
                    label: Intl.message('remembering'),
                    currentValue: _rememberCycle,
                    options: RememberCycle.values,
                    onChanged: (value) {
                      setState(() {
                        _rememberCycle = value!;
                      });
                    },
                    isDarkMode: isDarkMode,
                  ),
                  const SizedBox(height: 16),
                  EasyWalletTextField(
                      controller: _notesController,
                      placeholder: Intl.message('notes'),
                      maxLines: 5,
                      isDarkMode: isDarkMode),
                  const SizedBox(height: 16),
                  Text(
                    Intl.message('categories'),
                    style: TextStyle(
                      color: isDarkMode
                          ? CupertinoColors.white
                          : CupertinoColors.black,
                    ),
                  ),
                  Consumer<CategoryProvider>(
                      builder: (context, categoryProvider, child) {
                    return Material(
                        color:
                            CupertinoTheme.of(context).scaffoldBackgroundColor,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: buildMultiSelectDialogField(
                              categoryProvider.categories),
                        ));
                  }),
                ],
              ),
            ),
          ),
        ),
      );
    });
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
            style: EasyWalletApp.responsiveTextStyle(
              context,
              color: isDarkMode ? CupertinoColors.white : CupertinoColors.black,
            ),
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
                  use24hFormat: true,
                  onDateTimeChanged: (DateTime newDate) {
                    setState(() {
                      _date = newDate;
                    });
                  },
                ),
              ),
              CupertinoButton(
                child: AutoSizeText(
                  maxLines: 1,
                  'OK',
                  style: EasyWalletApp.responsiveTextStyle(
                    context,
                    color: CupertinoColors.activeBlue,
                  ),
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
    if (pickedDate != null && pickedDate != _date) {
      setState(() {
        _date = pickedDate;
      });
    }
  }

  Widget buildMultiSelectDialogField(List<Category> categories) {
    final isDarkMode =
        MediaQuery.of(context).platformBrightness == Brightness.dark;
    var textColor = isDarkMode ? CupertinoColors.white : CupertinoColors.black;

    List<MultiSelectItem<String>> items = categories.map((category) {
      return MultiSelectItem<String>(category.title, category.title);
    }).toList();

    var textStyle = TextStyle(color: textColor);

    return MultiSelectDialogField<String>(
      backgroundColor: CupertinoTheme.of(context).barBackgroundColor,
      searchTextStyle: textStyle,
      searchHintStyle: textStyle,
      itemsTextStyle: textStyle,
      selectedItemsTextStyle: textStyle,
      unselectedColor: isDarkMode
          ? CupertinoColors.darkBackgroundGray
          : CupertinoColors.systemGrey6,
      decoration: BoxDecoration(
        color: CupertinoTheme.of(context).barBackgroundColor,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(
            color: isDarkMode
                ? CupertinoColors.systemGrey
                : CupertinoColors.systemGrey4),
      ),
      selectedColor: CupertinoColors.activeBlue,
      searchable: true,
      separateSelectedItems: true,
      buttonText: Text(Intl.message('select'), style: TextStyle(
        color: isDarkMode
            ? CupertinoColors.systemGrey
            : CupertinoColors.systemGrey4
      )),
      title: Text(Intl.message('categories'), style: TextStyle(
          color: CupertinoColors.systemBlue
      )),
      checkColor: CupertinoColors.white,
      cancelText: Text(Intl.message('cancel'),
          style: const TextStyle(color: CupertinoColors.activeBlue)),
      closeSearchIcon: const Icon(CupertinoIcons.clear),
      confirmText: Text(Intl.message('confirm'),
          style: const TextStyle(color: CupertinoColors.activeBlue)),
      initialValue: widget.selectedCategories.map((e) => e.title).toList(),
      items: items,
      listType: MultiSelectListType.CHIP,
      onConfirm: (List<String> values) {
        widget.selectedCategories.clear();
        List<Category> newCategories = categories
            .where((element) => values.contains(element.title))
            .toList();
        widget.selectedCategories.addAll(newCategories);
      },
    );
  }
}
