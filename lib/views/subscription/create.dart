import 'package:easy_wallet/enum/currency.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_wallet/easy_wallet_app.dart';
import 'package:easy_wallet/enum/payment_rate.dart';
import 'package:easy_wallet/enum/remember_cycle.dart';
import 'package:easy_wallet/managers/subscription_catalog_service.dart';
import 'package:easy_wallet/model/subscription.dart';
import 'package:easy_wallet/model/subscription_template.dart';
import 'package:easy_wallet/views/subscription/template_picker.dart';
import 'package:easy_wallet/provider/currency_provider.dart';
import 'package:easy_wallet/provider/subscription_provider.dart';
import 'package:easy_wallet/views/components/form_fields/amount_field.dart';
import 'package:easy_wallet/views/components/auto_text.dart';
import 'package:easy_wallet/views/components/form_fields/date_picker_field.dart';
import 'package:easy_wallet/views/components/form_fields/dropdown_field.dart';
import 'package:easy_wallet/views/components/form_fields/text_field.dart';
import 'package:easy_wallet/views/components/gradient_header.dart';
import 'package:flutter/cupertino.dart';
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
  DateTime? _endDate;
  DateTime? _trialEndDate;
  String? _currencyCode;
  final _splitCountController = TextEditingController();
  String _selectedPayRate = PaymentRate.monthly.value;
  String _selectedPayMethode = PaymentMethode.invoice.value;
  String _selectedRememberCycle = RememberCycle.sameDay.value;

  List<category.Category> _selectedCategories = [];

  /// The catalog tariff the amount was filled in from, kept so the form can
  /// say how old that price is. Null once the user edits the amount.
  TemplatePlan? _catalogPlan;

  /// The amount exactly as the catalog filled it in. Once the field says
  /// something else the number is the user's own and the origin note goes.
  String? _catalogAmountText;

  bool _isTitleValid = true;
  bool _isAmountValid = true;

  @override
  void initState() {
    super.initState();
    _amountController.addListener(_forgetCatalogPriceOnEdit);
  }

  @override
  void dispose() {
    _amountController.removeListener(_forgetCatalogPriceOnEdit);
    super.dispose();
  }

  /// Drops the origin note as soon as the user changes the amount: it would
  /// otherwise date a number the catalog never supplied.
  void _forgetCatalogPriceOnEdit() {
    if (_catalogPlan == null) {
      return;
    }
    if (_amountController.text != _catalogAmountText) {
      setState(() {
        _catalogPlan = null;
        _catalogAmountText = null;
      });
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
        child: Column(
          children: [
            GradientHeader(
              title: Intl.message('addSubscription'),
              showBackButton: true,
              trailing: CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () => _saveItem(context),
                child: const Icon(CupertinoIcons.floppy_disk,
                    color: CupertinoColors.white),
              ),
            ),
            Expanded(
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    child: ListView(
                      children: [
                  if (SubscriptionCatalogService.isConfigured) ...[
                    _buildCatalogButton(isDarkMode),
                    const SizedBox(height: 16),
                  ],
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
                  if (_catalogPlan != null) _buildPriceOrigin(),
                  const SizedBox(height: 16),
                  EasyWalletDatePickerField(
                      label: Intl.message('startDate'),
                      date: _selectedDate,
                      onTap: _pickDate,
                      isDarkMode: isDarkMode),
                  const SizedBox(height: 16),
                  EasyWalletDatePickerField(
                      label: Intl.message('endDate'),
                      date: _endDate,
                      placeholder: Intl.message('noEndDate'),
                      onTap: _pickEndDate,
                      onClear: () => setState(() => _endDate = null),
                      isDarkMode: isDarkMode),
                  const SizedBox(height: 16),
                  EasyWalletDatePickerField(
                      label: Intl.message('trialEndDate'),
                      date: _trialEndDate,
                      placeholder: Intl.message('noTrial'),
                      onTap: _pickTrialEndDate,
                      onClear: () => setState(() => _trialEndDate = null),
                      isDarkMode: isDarkMode),
                  const SizedBox(height: 16),
                  Text(
                    Intl.message('splitCount'),
                    style: TextStyle(
                      color: isDarkMode
                          ? CupertinoColors.white
                          : CupertinoColors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  EasyWalletTextField(
                    controller: _splitCountController,
                    placeholder: Intl.message('notShared'),
                    keyboardType: TextInputType.number,
                    isDarkMode: isDarkMode,
                  ),
                  const SizedBox(height: 16),
                  EasyWalletDatePickerField(
                      label: Intl.message('subscriptionCurrency'),
                      date: null,
                      placeholder: _currencyCode ?? Intl.message('appCurrency'),
                      onTap: _selectSubscriptionCurrency,
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
                        return Container(
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
          ),
        ],
      ),
    );
    });
  }

  /// Opens the catalog of known services. Only ever an offer: the form below
  /// stays fully usable, and everything the catalog fills in stays editable.
  Widget _buildCatalogButton(bool isDarkMode) {
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: isDarkMode
          ? CupertinoColors.darkBackgroundGray
          : CupertinoColors.systemGrey6,
      borderRadius: BorderRadius.circular(8.0),
      onPressed: _pickFromCatalog,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(CupertinoIcons.square_grid_2x2,
              size: 20, color: CupertinoColors.activeBlue),
          const SizedBox(width: 8),
          Flexible(
            child: AutoText(
              text: Intl.message('chooseFromCatalog'),
              color: CupertinoColors.activeBlue,
            ),
          ),
        ],
      ),
    );
  }

  /// Where the prefilled amount comes from and how old it is. Catalog prices
  /// are researched snapshots, and a stale price shown as fact is worse in a
  /// finance app than no price at all.
  Widget _buildPriceOrigin() {
    final plan = _catalogPlan!;
    final checkedAt = plan.priceCheckedAt;
    final origin = checkedAt == null
        ? Intl.message('catalogPriceIsSuggestion')
        : '${Intl.message('catalogPriceFrom')} ${DateFormat.yMd().format(checkedAt)}'
            ' · ${Intl.message('catalogPriceIsSuggestion')}';

    return Padding(
      padding: const EdgeInsets.only(top: 6, left: 4),
      child: Text(
        origin,
        style: const TextStyle(fontSize: 12, color: CupertinoColors.systemGrey),
      ),
    );
  }

  Future<void> _pickFromCatalog() async {
    final selection = await Navigator.of(context).push<TemplateSelection>(
      CupertinoPageRoute(builder: (_) => const TemplatePickerView()),
    );
    if (selection == null || !mounted) {
      return;
    }
    _applySelection(selection);
  }

  /// Fills the form from a catalog entry. Overwrites only what the catalog
  /// actually knows, so a user who picks a service after filling in half the
  /// form does not lose the other half.
  void _applySelection(TemplateSelection selection) {
    final template = selection.template;
    final plan = selection.plan;

    setState(() {
      _titleController.text = template.name;
      _isTitleValid = true;
      if (template.websiteUrl != null) {
        _urlController.text = template.websiteUrl!;
      }
      if (plan != null) {
        // Written without grouping separators on purpose: the field parses
        // its own text back, and a thousands dot would turn 1490 into 1.49.
        _catalogAmountText = plan.amountAsFieldText;
        _amountController.text = _catalogAmountText!;
        _isAmountValid = true;
        _currencyCode = plan.currency.name;
        _selectedPayRate = plan.rate.value;
      }
      _catalogPlan = plan;
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
        CupertinoIcons.creditcard,
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

  Future<void> _selectSubscriptionCurrency() async {
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        title: Text(Intl.message('subscriptionCurrency')),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              setState(() => _currencyCode = null);
              Navigator.pop(context);
            },
            child: Text(Intl.message('appCurrency')),
          ),
          for (final code in Currency.all())
            CupertinoActionSheetAction(
              onPressed: () {
                setState(() => _currencyCode = code);
                Navigator.pop(context);
              },
              child: Text(code),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: Text(Intl.message('cancel')),
        ),
      ),
    );
  }

Future<void> _pickTrialEndDate() async {
    var draft = _trialEndDate ?? DateTime.now();
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: 260,
          color: CupertinoColors.systemBackground.resolveFrom(context),
          child: Column(
            children: [
              SizedBox(
                height: 200,
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.date,
                  initialDateTime: draft,
                  use24hFormat: true,
                  onDateTimeChanged: (DateTime newDate) => draft = newDate,
                ),
              ),
              CupertinoButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK',
                    style: TextStyle(color: CupertinoColors.activeBlue)),
              ),
            ],
          ),
        );
      },
    );
    setState(() => _trialEndDate = draft);
  }

  Future<void> _pickEndDate() async {
    var draft = _endDate ?? DateTime.now();
    await showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: 260,
          color: CupertinoColors.systemBackground.resolveFrom(context),
          child: Column(
            children: [
              SizedBox(
                height: 200,
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.date,
                  initialDateTime: draft,
                  use24hFormat: true,
                  onDateTimeChanged: (DateTime newDate) => draft = newDate,
                ),
              ),
              CupertinoButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const AutoText(
                    text: 'OK', color: CupertinoColors.activeBlue),
              ),
            ],
          ),
        );
      },
    );
    setState(() => _endDate = draft);
  }

  Future<void> _saveItem(BuildContext context) async {
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
        endDate: _endDate,
        trialEndDate: _trialEndDate,
        splitCount: int.tryParse(_splitCountController.text.trim()),
        currencyCode: _currencyCode,
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

      if (!context.mounted) return;
      Navigator.of(context).pop(true);
    }
  }
}
