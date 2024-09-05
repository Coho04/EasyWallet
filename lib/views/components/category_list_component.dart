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
      required this.onDelete
      });

  @override
  Widget build(BuildContext context) {
    final isDarkMode =
        MediaQuery.of(context).platformBrightness == Brightness.dark;

    return GestureDetector(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        decoration: BoxDecoration(
          border: const Border(
            bottom: BorderSide(
              color: CupertinoColors.separator,
            ),
          ),
          // color: category.isPaused
          //     ? (isDarkMode
          //         ? Colors.grey.withOpacity(0.5)
          //         : CupertinoColors.systemGrey5)
          //     : (isDarkMode ? CupertinoColors.darkBackgroundGray : null),
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
                            color: isDarkMode
                                ? CupertinoColors.white
                                : CupertinoColors.black,
                            bold: true),
                      ),
                      // if (subscription.isPinned)
                      //   const Icon(
                      //     CupertinoIcons.pin_fill,
                      //     color: CupertinoColors.systemGrey,
                      //   ),

                    ],
                  ),
                  // AutoText(
                  //     text:
                  //         '${category.amount.toStringAsFixed(2)} ${currency.symbol}',
                  //     maxLines: 1,
                  //     color: isDarkMode
                  //         ? CupertinoColors.systemGrey2
                  //         : CupertinoColors.systemGrey),
                ],
              ),
            ),
            const SizedBox(width: 16.0),
            Row(
              children: [
                Column(
                  children: [
                    // AutoText(
                    //     text:
                    //         '${subscription.remainingDays()} ${Intl.message('D')}',
                    //     color: isDarkMode
                    //         ? CupertinoColors.systemGrey2
                    //         : CupertinoColors.systemGrey),
                    // AutoText(
                    //     text: '(${_convertPrice(subscription)})',
                    //     color: isDarkMode
                    //         ? CupertinoColors.systemGrey2
                    //         : CupertinoColors.systemGrey),
                  ],
                ),
                // CupertinoButton(
                //   onPressed: () {
                //     deleteCategory(context, category);
                //   },
                //   child: Icon(
                //     CupertinoIcons.trash_circle,
                //     color: isDarkMode
                //         ? CupertinoColors.systemGrey2
                //         : CupertinoColors.systemGrey,
                //   ),
                // ),
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
      onTap: () {
        // Navigator.push(
        //   context,
        //   CupertinoPageRoute(
        //     builder: (context) => SubscriptionShowView(
        //       subscription: subscription,
        //       onUpdate: onUpdate,
        //       onDelete: onDelete,
        //     ),
        //   ),
        // ).then((_) => onUpdate(subscription));
      },
    );
  }
}
