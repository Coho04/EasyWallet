import 'package:easy_wallet/model/category.dart';
import 'package:easy_wallet/provider/category_provider.dart';
import 'package:easy_wallet/views/components/auto_text.dart';
import 'package:easy_wallet/views/components/category_list_component.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class CategoryIndexView extends StatefulWidget {
  const CategoryIndexView({super.key});

  @override
  CategoryIndexViewState createState() => CategoryIndexViewState();
}

class CategoryIndexViewState extends State<CategoryIndexView> {
  String searchText = "";
  bool _isLoading = true;

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
        navigationBar: CupertinoNavigationBar(
          middle: Column(
            children: [
              SizedBox(
                height: 36,
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
            ],
          ),
          leading: CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () => /*_showSortOptions(context)*/ '',
            child: const Icon(CupertinoIcons.arrow_up_arrow_down,
                color: CupertinoColors.activeBlue),
          ),
          trailing: CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () {
              _showAddCategoryDialog(context);
            },
            child: const Icon(CupertinoIcons.add,
                color: CupertinoColors.activeBlue),
          ),
        ),
        child: Column(
          children: <Widget>[
            SizedBox(
              height: 100,
              child: Center(
                child: AutoText(
                  text: Intl.message('categories'),
                  bold: true,
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SizedBox(width: 10),
                  // Flexible(
                  //   child: Column(
                  //     crossAxisAlignment: CrossAxisAlignment.end,
                  //     children: [
                  //       AutoText(
                  //         text: Intl.message('openExpenditureYear'),
                  //         color: CupertinoColors.systemGrey,
                  //         maxLines: 2,
                  //       ),
                  //       AutoText(
                  //           text:
                  //           '${calculateYearlySpent(sortedSubscriptions).toStringAsFixed(2)} ${currency.symbol}',
                  //           bold: true),
                  //     ],
                  //   ),
                  // ),y
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : sortedCategories.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.only(bottom: 85.0),
                          itemCount: sortedCategories.length,
                          itemBuilder: (context, index) {
                            return CategoryListComponent(
                              category: sortedCategories[index],
                              onUpdate: (updatedCategories) {
                                setState(() {
                                  _sortCategories(
                                      Provider.of<CategoryProvider>(context,
                                              listen: false)
                                          .categories);
                                });
                              },
                              onDelete: (deletedCategory) {
                                setState(() {
                                  Provider.of<CategoryProvider>(context,
                                          listen: false)
                                      .deleteCategory(deletedCategory);
                                  _sortCategories(sortedCategories);
                                });
                              },
                            );
                          },
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
    } catch (e) {
      print('Error loading categories: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
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
            onPressed: () {
              _showAddCategoryDialog(context);
            },
            child: AutoText(
              text: Intl.message('addNewCategory'),
              bold: true,
              color: CupertinoColors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _showAddCategoryDialog(BuildContext context) {
    TextEditingController titleController = TextEditingController();
    Color pickerColor = CupertinoColors.activeBlue;

    void changeColor(Color color) {
      pickerColor = color;
    }

    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(Intl.message('addNewCategory')),
        content: Column(
          children: [
            const SizedBox(height: 20),
            CupertinoTextField(
              controller: titleController,
              placeholder: Intl.message('title'),
            ),
            const SizedBox(height: 20),
            CupertinoButton(
              child: Text('Farbe wählen'),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Wähle eine Farbe'),
                    content: SingleChildScrollView(
                      child: ColorPicker(
                        pickerColor: pickerColor,
                        onColorChanged: changeColor,
                        showLabel: true,
                        pickerAreaHeightPercent: 0.8,
                      ),
                    ),
                    actions: <Widget>[
                      TextButton(
                        child: const Text('Fertig'),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            child: Text(Intl.message('cancel')),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            child: Text('Hinzufügen'),
            isDefaultAction: true,
            onPressed: () {
              if (titleController.text.isNotEmpty) {
                Provider.of<CategoryProvider>(context, listen: false).saveCategory(
                  Category(
                    title: titleController.text,
                    color: pickerColor,
                  ),
                );
                Navigator.pop(context);
              }
            },
          ),
        ],
      ),
    );
  }


  List<Category> _sortCategories(List<Category> categories) {
    List<Category> filteredCategories =
    categories.where((category) {
      return category.title
          .toLowerCase()
          .contains(searchText.toLowerCase());
    }).toList();

    filteredCategories.sort((a, b) {
      return a.title.toLowerCase().compareTo(b.title.toLowerCase());
    });
    return filteredCategories;
  }
}
