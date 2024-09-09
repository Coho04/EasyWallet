import 'package:easy_wallet/model/category.dart';
import 'package:easy_wallet/views/categories/show.dart';
import 'package:easy_wallet/views/components/auto_text.dart';
import 'package:easy_wallet/views/components/color_circle.dart';
import 'package:flutter/cupertino.dart';

class CategoryListComponent extends StatelessWidget {
  final Category category;
  final Function(Category) onUpdate;
  final Function(Category) onDelete;

  const CategoryListComponent(
      {super.key,
      required this.category,
      required this.onUpdate,
      required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final isDarkMode =
        MediaQuery.of(context).platformBrightness == Brightness.dark;

    return GestureDetector(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: CupertinoColors.separator,
            ),
          ),
        ),
        child: Row(
          children: [
            const SizedBox(width: 16.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      ColorCircle(color: category.color),
                      const SizedBox(width: 16.0),
                      Expanded(
                        child: AutoText(
                            text: category.title,
                            maxLines: 3,
                            softWrap: true,
                            bold: true),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16.0),
            Row(
              children: [
                CupertinoButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      CupertinoPageRoute(
                        builder: (context) => CategoryShowView(
                          category: category,
                          onUpdate: onUpdate,
                          onDelete: onDelete,
                        ),
                      ),
                    ).then((_) => onUpdate(category));
                  },
                  child: Icon(
                    CupertinoIcons.right_chevron,
                    color: isDarkMode
                        ? CupertinoColors.systemGrey2
                        : CupertinoColors.systemGrey,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
