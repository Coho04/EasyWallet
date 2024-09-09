import 'package:easy_wallet/model/category.dart';
import 'package:easy_wallet/provider/category_provider.dart';
import 'package:easy_wallet/views/components/auto_text.dart';
import 'package:easy_wallet/views/components/category_list_component.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class CategoryIndexView extends StatefulWidget {
  const CategoryIndexView({super.key});

  @override
  CategoryIndexViewState createState() => CategoryIndexViewState();
}

class CategoryIndexViewState extends State<CategoryIndexView> {
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
            onPressed: _toggleSortDirection,
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
                                  _sortCategories(Provider.of<CategoryProvider>(
                                          context,
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
      Sentry.captureException(e);
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
                            await _pickColor(pickerColor) ?? pickerColor;
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
            color: isDarkMode ? CupertinoColors.white : CupertinoColors.black,
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
