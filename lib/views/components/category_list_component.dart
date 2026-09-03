import 'package:easy_wallet/model/category.dart';
import 'package:flutter/cupertino.dart';

/// One row of the category list.
///
/// The whole row is the tap target, the way iOS lists behave; the chevron is
/// decoration, not a button. The label is set at a fixed size rather than
/// through AutoText, which shrinks each string until it fits and leaves
/// neighbouring rows at different sizes.
class CategoryListComponent extends StatelessWidget {
  const CategoryListComponent({
    super.key,
    required this.category,
    required this.subscriptionCount,
    required this.subtitle,
    required this.monthlyTotal,
    required this.onTap,
  });

  final Category category;

  /// How many subscriptions carry this category.
  final int subscriptionCount;

  /// Already translated, for instance "3 subscriptions".
  final String subtitle;

  /// What they cost per month, already formatted.
  final String monthlyTotal;
  final VoidCallback onTap;

  static const double _minHeight = 44;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: _minHeight),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: category.color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      category.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        color: CupertinoColors.label.resolveFrom(context),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color:
                            CupertinoColors.secondaryLabel.resolveFrom(context),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (subscriptionCount > 0)
                Text(
                  monthlyTotal,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: CupertinoColors.label.resolveFrom(context),
                  ),
                ),
              const SizedBox(width: 6),
              Icon(
                CupertinoIcons.chevron_forward,
                size: 16,
                color: CupertinoColors.tertiaryLabel.resolveFrom(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
