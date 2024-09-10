import 'package:easy_wallet/provider/category_provider.dart';
import 'package:easy_wallet/provider/currency_provider.dart';
import 'package:easy_wallet/views/components/card_section_component.dart';
import 'package:easy_wallet/views/subscription/show.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:intl/intl.dart';
import 'package:easy_wallet/model/category.dart';
import 'package:provider/provider.dart';

class CategoryShowView extends StatefulWidget {
  final Category category;
  final ValueChanged<Category> onUpdate;
  final ValueChanged<Category> onDelete;

  const CategoryShowView({
    super.key,
    required this.category,
    required this.onUpdate,
    required this.onDelete,
  });

  @override
  CategoryShowViewState createState() => CategoryShowViewState();
}

class CategoryShowViewState extends State<CategoryShowView> {
  late Category category;

  @override
  void initState() {
    super.initState();
    category = widget.category;
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode =
        MediaQuery.of(context).platformBrightness == Brightness.dark;

    return CupertinoPageScaffold(
      backgroundColor:
          CupertinoColors.systemGroupedBackground.resolveFrom(context),
      navigationBar: CupertinoNavigationBar(
        middle: Text(
          category.title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
        ),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildEditCard(context, isDarkMode),
                const SizedBox(width: 20),
                _buildDeleteCard(context, isDarkMode),
              ],
            ),
            const SizedBox(height: 20),
            CardSection(title: Intl.message('subscriptions'), children: [
              FutureBuilder<List<Widget>>(
                future: _buildSubscriptions(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  } else {
                    return Column(children: snapshot.data!);
                  }
                },
              ),
            ])
          ],
        ),
      ),
    );
  }

  Widget _buildEditCard(BuildContext context, bool isDarkMode) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: isDarkMode
              ? CupertinoColors.darkBackgroundGray
              : CupertinoColors.white,
          borderRadius: BorderRadius.circular(12.0),
          boxShadow: [
            BoxShadow(
              color: CupertinoColors.systemGrey.withOpacity(0.5),
              blurRadius: 10,
              spreadRadius: 1,
            ),
          ],
        ),
        child: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _showEditCategoryDialog,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(CupertinoIcons.pen, color: CupertinoColors.activeBlue),
              const SizedBox(width: 8),
              Text(Intl.message('edit'),
                  style: const TextStyle(color: CupertinoColors.activeBlue)),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditCategoryDialog() {
    TextEditingController titleController =
        TextEditingController(text: category.title);
    Color currentColor = category.color;

    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: Text(Intl.message("editCategory")),
          content: Column(
            children: <Widget>[
              CupertinoTextField(
                controller: titleController,
                placeholder: Intl.message("categoryTitle"),
              ),
              SizedBox(
                height: 80,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    GestureDetector(
                      onTap: () async {
                        currentColor =
                            await _pickColor(currentColor) ?? currentColor;
                        setState(() {});
                      },
                      child: Row(
                        children: [
                          Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: currentColor,
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
          actions: <Widget>[
            CupertinoDialogAction(
              isDefaultAction: true,
              child: Text(Intl.message('cancel')),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              child: Text(Intl.message('save')),
              onPressed: () {
                Provider.of<CategoryProvider>(context, listen: false)
                    .saveCategory(Category(
                        id: category.id,
                        title: titleController.text,
                        color: currentColor));
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildDeleteCard(BuildContext context, bool isDarkMode) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: isDarkMode
              ? CupertinoColors.darkBackgroundGray
              : CupertinoColors.white,
          borderRadius: BorderRadius.circular(12.0),
          boxShadow: [
            BoxShadow(
              color: CupertinoColors.systemGrey.withOpacity(0.5),
              blurRadius: 10,
              spreadRadius: 1,
            ),
          ],
        ),
        child: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () {
            Provider.of<CategoryProvider>(context, listen: false)
                .deleteCategory(category);
            Navigator.of(context).pop();
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(CupertinoIcons.trash,
                  color: CupertinoColors.systemRed),
              const SizedBox(width: 8),
              Text(Intl.message('delete'),
                  style: const TextStyle(color: CupertinoColors.systemRed)),
            ],
          ),
        ),
      ),
    );
  }

  Future<List<Widget>> _buildSubscriptions() async {
    final isDarkMode =
        MediaQuery.of(context).platformBrightness == Brightness.dark;
    var currency =
        Provider.of<CurrencyProvider>(context, listen: false).currency;
    var subscriptions = await category.getSubscriptions();
    if (subscriptions.isEmpty) {
      return [Text(Intl.message('noEntriesFound'))];
    }
    return subscriptions.map((subscription) {
      return CupertinoListTile(
        onTap: () {
          Navigator.of(context).push(
            CupertinoPageRoute(
              builder: (context) => SubscriptionShowView(
                subscription: subscription,
              ),
            ),
          );
        },
        title: Text(subscription.title),
        additionalInfo: Text('${subscription.amount} ${currency.symbol}'),
        leading: subscription.buildImage(errorImgSize: 30),
        backgroundColor: isDarkMode
            ? CupertinoColors.darkBackgroundGray
            : CupertinoColors.white,
        trailing: const SizedBox(
          width: 40,
          height: 40,
          child: Icon(CupertinoIcons.right_chevron),
        ),
      );
    }).toList();
  }

  Future<Color?> _pickColor(Color currentColor) async {
    final isDarkMode =
        MediaQuery.of(context).platformBrightness == Brightness.dark;

    Color? pickedColor;
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: isDarkMode
              ? CupertinoColors.darkBackgroundGray
              : CupertinoColors.white,
          title: Text(Intl.message('pickAColor')),
          titleTextStyle: TextStyle(
            color: isDarkMode
                ? CupertinoColors.white
                : CupertinoColors.black,
          ),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: currentColor,
              onColorChanged: (Color color) {
                pickedColor = color;
              },
              showLabel: false,
              labelTextStyle: TextStyle(
                color:
                    isDarkMode ? CupertinoColors.white : CupertinoColors.black,
              ),
              pickerAreaHeightPercent: 0.8,
            ),
          ),
          actions: <Widget>[
            CupertinoButton(
              child: Text(Intl.message('done')),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
    return pickedColor;
  }
}
