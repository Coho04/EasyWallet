import 'package:auto_size_text/auto_size_text.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_wallet/easy_wallet_app.dart';
import 'package:easy_wallet/enum/payment_rate.dart';
import 'package:easy_wallet/enum/remember_cycle.dart';
import 'package:easy_wallet/model/subscription.dart';
import 'package:easy_wallet/provider/currency_provider.dart';
import 'package:easy_wallet/provider/subscription_provider.dart';
import 'package:easy_wallet/views/components/form_fields/amount_field.dart';
import 'package:easy_wallet/views/components/auto_text.dart';
import 'package:easy_wallet/views/components/form_fields/date_picker_field.dart';
import 'package:easy_wallet/views/components/form_fields/dropdown_field.dart';
import 'package:easy_wallet/views/components/form_fields/text_field.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:multi_select_flutter/util/multi_select_item.dart';
import 'package:multi_select_flutter/util/multi_select_list_type.dart';
import 'package:provider/provider.dart';
import 'package:easy_wallet/model/category.dart' as category;
import '../../enum/payment_methode.dart';
import '../../provider/category_provider.dart';
import '../components/form_fields/multi_select_dialog_field.dart';

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
  String _selectedPayMethode = PaymentMethode.invoice.value;
  String _selectedRememberCycle = RememberCycle.sameDay.value;

  List<category.Category> _selectedCategories = [];

  bool _isTitleValid = true;
  bool _isAmountValid = true;

  @override
  void initState() {
    super.initState();
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
            Intl.message('addSubscription'),
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
                  AmountField(
                    isDarkMode: isDarkMode,
                    currency: currency,
                    controller: _amountController,
                    isValid: _isAmountValid,
                  ),
                  const SizedBox(height: 16),
                  EasyWalletDatePickerField(
                      label: Intl.message('startDate'),
                      date: _selectedDate,
                      onTap: _pickDate,
                      isDarkMode: isDarkMode),
                  const SizedBox(height: 16),
                  EasyWalletDropdownField(
                    label: Intl.message('paymentRate'),
                    currentValue: _selectedPayRate,
                    options: PaymentRate.values,
                    onChanged: (value) {
                      setState(() {
                        _selectedPayRate = value!;
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
                    currentValue: _selectedRememberCycle,
                    options: RememberCycle.values,
                    onChanged: (value) {
                      setState(() {
                        _selectedRememberCycle = value!;
                      });
                    },
                    isDarkMode: isDarkMode,
                  ),
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
                        var categories = categoryProvider.categories;
                        return Material(
                            color: isDarkMode
                                ? CupertinoColors.black
                                : CupertinoColors.systemGrey6,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: MultiSelectDialogField(
                                backgroundColor: isDarkMode
                                    ? CupertinoColors.darkBackgroundGray
                                    : CupertinoColors.systemGrey6,
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
                                selectedColor: CupertinoColors.activeBlue,
                                searchable: true,
                                separateSelectedItems: true,
                                selectedItemsTextStyle: TextStyle(
                                    color: CupertinoColors.white
                                ),
                                buttonText: Text(Intl.message('select'), style: TextStyle(
                                    color: isDarkMode
                                        ? CupertinoColors.systemGrey
                                        : CupertinoColors.systemGrey4
                                )),
                                title: Text(Intl.message('categories'), style: TextStyle(
                                    color: CupertinoColors.systemBlue
                                )),
                                checkColor: CupertinoColors.white,
                                cancelText: Text(Intl.message('cancel')),
                                closeSearchIcon: const Icon(CupertinoIcons.clear),
                                confirmText: Text(Intl.message('confirm')),
                                items: categories
                                    .map((e) => MultiSelectItem(e, e.title))
                                    .toList(),
                                listType: MultiSelectListType.CHIP,
                                onConfirm: (values) {
                                  _selectedCategories = values;
                                },
                              ),
                            ));
                      }),
                  const SizedBox(height: 16),
                  EasyWalletTextField(
                      controller: _notesController,
                      placeholder: Intl.message('notes'),
                      maxLines: 5,
                      isDarkMode: isDarkMode),
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
                child: const AutoText(
                    text: 'OK',
                    color: CupertinoColors.activeBlue),
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

  Future<void> _saveItem(context) async {
    final title = _titleController.text.trim();
    final amount = double.tryParse(_amountController.text.replaceAll(',', '.'));
    final url = _urlController.text;
    final notes = _notesController.text.trim();

    setState(() {
      _isTitleValid = title.isNotEmpty;
      _isAmountValid = amount != null && amount >= 0 && amount <= 10000;
    });

    if (_isTitleValid && _isAmountValid) {
      var newSubscription = Subscription(
        title: title,
        amount: amount!,
        date: _selectedDate,
        repeatPattern: _selectedPayRate,
        notes: notes,
        url: url,
        rememberCycle: _selectedRememberCycle,
        paymentMethode: _selectedPayMethode,
        timestamp: DateTime.now(),
        isPaused: false,
        isPinned: false,
        repeating: true,
      );
      newSubscription =
          await Provider.of<SubscriptionProvider>(context, listen: false)
              .saveSubscription(newSubscription);
      newSubscription.assignCategories(_selectedCategories);

      Navigator.of(context).pop(true);
    }
  }
}
