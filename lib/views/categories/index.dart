import 'package:easy_wallet/views/categories/show.dart';
import 'package:easy_wallet/generated/l10n.dart';
import 'package:easy_wallet/provider/subscription_provider.dart';
import 'package:easy_wallet/provider/currency_provider.dart';
import 'package:easy_wallet/model/subscription.dart';
import 'package:easy_wallet/enum/payment_rate.dart';
import 'package:easy_wallet/class/money.dart';
import 'package:easy_wallet/views/components/color_picker_sheet.dart';
import 'package:easy_wallet/model/category.dart';
import 'package:easy_wallet/provider/category_provider.dart';
import 'package:easy_wallet/views/components/auto_text.dart';
import 'package:easy_wallet/views/components/category_list_component.dart';
import 'package:easy_wallet/views/components/gradient_header.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class CategoryIndexView extends StatefulWidget {
  const CategoryIndexView({super.key});

  @override
  CategoryIndexViewState createState() => CategoryIndexViewState();
}

class CategoryIndexViewState extends State<CategoryIndexView> {
  Map<int, List<Category>> _categoriesBySubscription = {};
  String searchText = "";
  bool _isLoading = true;
  bool _isAscending = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CategoryProvider>(
        builder: (context, categoryProvider, child) {
      final categories = categoryProvider.categories;
      final sortedCategories = _sortCategories(categories);
      return CupertinoPageScaffold(
        child: Column(
          children: [
            GradientHeader(
              title: Intl.message('categories'),
              showBackButton: false,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: _toggleSortDirection,
                    child: const Icon(CupertinoIcons.arrow_up_arrow_down,
                        color: CupertinoColors.white),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      _showAddCategoryDialog(context);
                    },
                    child: const Icon(CupertinoIcons.add,
                        color: CupertinoColors.white),
                  ),
                ],
              ),
            ),
            if (categories.isNotEmpty)
              Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: CupertinoSearchTextField(
                placeholder: Intl.message('search'),
                onChanged: (value) {
                  setState(() {
                    searchText = value;
                    _sortCategories(categories);
                  });
                },
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _isLoading
                  ? const Center(child: CupertinoActivityIndicator())
                  : sortedCategories.isEmpty
                      ? _buildEmptyState()
                      // One grouped card, like the rest of the app, instead
                      // of a grey slab running edge to edge.
                      : ListView(
                          padding: const EdgeInsets.fromLTRB(14, 0, 14, 85),
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: CupertinoColors
                                    .secondarySystemGroupedBackground
                                    .resolveFrom(context),
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: CupertinoColors.black
                                        .withValues(alpha: 0.06),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  for (var i = 0;
                                      i < sortedCategories.length;
                                      i++) ...[
                                    if (i > 0)
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(left: 38),
                                        child: Container(
                                          height: 0.5,
                                          color: CupertinoColors.separator
                                              .resolveFrom(context),
                                        ),
                                      ),
                                    _categoryRow(sortedCategories[i]),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
            ),
          ],
        ),
      );
    });
  }

  Future<void> _loadCategories() async {
    try {
      await Provider.of<CategoryProvider>(context, listen: false)
          .loadCategories();
      if (!mounted) return;
      // Tabs are built lazily, so this view cannot rely on the subscription
      // tab having filled the providers before it is opened.
      await Provider.of<SubscriptionProvider>(context, listen: false)
          .loadSubscriptions();
      if (!mounted) return;
      final currencyProvider =
          Provider.of<CurrencyProvider>(context, listen: false);
      await currencyProvider.loadCurrency();
      await currencyProvider.loadRates();
    } catch (e) {
      Sentry.captureException(e);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
    // Needed for the count and the monthly sum per category.
    final assignments = await Category.forAllSubscriptions();
    if (!mounted) return;
    setState(() => _categoriesBySubscription = assignments);
  }

  /// Deleting a category cannot be undone, so it is confirmed first.
  Future<bool> _confirmDelete(BuildContext context) async {
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (BuildContext context) => CupertinoAlertDialog(
        title: Text(Intl.message('deleteCategoryQuestion')),
        content: Text(Intl.message('deleteCategoryHint')),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(Intl.message('cancel')),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(Intl.message('delete')),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

/// A row with what the category actually holds: how many subscriptions and
  /// what they cost per month.
  Widget _categoryRow(Category category) {
    final subscriptions = _subscriptionsOf(category);
    final currency =
        Provider.of<CurrencyProvider>(context, listen: false).currency;
    final rates = Provider.of<CurrencyProvider>(context, listen: false).rates;

    var monthly = 0.0;
    for (final subscription in subscriptions) {
      if (subscription.isPaused || subscription.isExpired) continue;
      final share = subscription.shareIn(currency.name, rates);
      monthly += subscription.repeatPattern == PaymentRate.yearly.value
          ? share / 12
          : share;
    }

    final count = subscriptions.length;
    final subtitle = count == 0
        ? Intl.message('noSubscriptions')
        : count == 1
            ? Intl.message('oneSubscription')
            : S.of(context).countSubscriptions(count);

    return CategoryListComponent(
      category: category,
      subscriptionCount: count,
      subtitle: subtitle,
      monthlyTotal: Money.format(monthly, currency.symbol),
      onTap: () {
        Navigator.push(
          context,
          CupertinoPageRoute(
            builder: (context) => CategoryShowView(
              category: category,
              onUpdate: (_) => setState(() {}),
              onDelete: (deleted) async {
                if (!await _confirmDelete(context)) return;
                if (!mounted) return;
                await Provider.of<CategoryProvider>(context, listen: false)
                    .deleteCategory(deleted);
                if (mounted) setState(() {});
              },
            ),
          ),
        ).then((_) => _loadCategories());
      },
    );
  }

  List<Subscription> _subscriptionsOf(Category category) {
    final subscriptions =
        Provider.of<SubscriptionProvider>(context, listen: false).subscriptions;
    return subscriptions
        .where((s) =>
            _categoriesBySubscription[s.id]?.any((c) => c.id == category.id) ??
            false)
        .toList();
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 16),
          AutoText(
            text: Intl.message('noCategoriesAvailable'),
            color: CupertinoColors.systemGrey,
          ),
          const SizedBox(height: 16),
          CupertinoButton.filled(
            sizeStyle: CupertinoButtonSize.medium,
            onPressed: () {
              _showAddCategoryDialog(context);
            },
            child: Text(Intl.message('addNewCategory')),
          ),
        ],
      ),
    );
  }

  void _showAddCategoryDialog(BuildContext context) {
    TextEditingController titleController = TextEditingController();
    Color pickerColor = CupertinoColors.activeBlue;
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: Text(Intl.message('addNewCategory')),
          content: Column(
            children: [
              const SizedBox(height: 20),
              CupertinoTextField(
                controller: titleController,
                placeholder: Intl.message('title'),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 80,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    GestureDetector(
                      onTap: () async {
                        pickerColor =
                            await showColorPickerSheet(context, pickerColor) ?? pickerColor;
                        setState(() {});
                      },
                      child: Row(
                        children: [
                          Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: pickerColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            Intl.message('chooseColor'),
                            style: const TextStyle(
                              fontSize: 16,
                              color: CupertinoColors.activeBlue,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            CupertinoDialogAction(
              child: Text(Intl.message('cancel')),
              onPressed: () => Navigator.pop(context),
            ),
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () {
                if (titleController.text.isNotEmpty) {
                  Provider.of<CategoryProvider>(context, listen: false)
                      .saveCategory(
                    Category(
                      title: titleController.text,
                      color: pickerColor,
                    ),
                  );
                  Navigator.pop(context);
                }
              },
              child: Text(Intl.message('add')),
            ),
          ],
        );
      },
    );
  }


  List<Category> _sortCategories(List<Category> categories) {
    List<Category> filteredCategories = categories.where((category) {
      return searchText.isEmpty ||
          category.title.toLowerCase().contains(searchText.toLowerCase());
    }).toList();

    filteredCategories.sort((a, b) {
      if (_isAscending) {
        return a.title.toLowerCase().compareTo(b.title.toLowerCase());
      } else {
        return b.title.toLowerCase().compareTo(a.title.toLowerCase());
      }
    });
    return filteredCategories;
  }

  void _toggleSortDirection() {
    setState(() {
      _isAscending = !_isAscending;
    });
  }
}
