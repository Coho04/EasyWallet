import 'package:easy_wallet/enum/currency.dart';
import 'package:easy_wallet/model/category.dart';
import 'package:easy_wallet/views/subscription/show.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:easy_wallet/model/subscription.dart';
import 'package:intl/intl.dart';

class SubscriptionListComponent extends StatefulWidget {
  const SubscriptionListComponent({
    super.key,
    required this.subscription,
    required this.currency,
    required this.displayCategories,
    this.accentColor,
    required this.onTogglePin,
    required this.onTogglePause,
    required this.onDelete,
  });

  final Subscription subscription;
  final Currency currency;
  final bool displayCategories;
  final Color? accentColor;
  final VoidCallback onTogglePin;
  final VoidCallback onTogglePause;
  final VoidCallback onDelete;

  @override
  SubscriptionListComponentState createState() =>
      SubscriptionListComponentState();
}

class SubscriptionListComponentState
    extends State<SubscriptionListComponent> {
  List<Category>? _categories;

  @override
  void initState() {
    super.initState();
    if (widget.displayCategories) _loadCategories();
  }

  Future<void> _loadCategories() async {
    final has = await widget.subscription.hasCategories();
    if (has) {
      final cats = await widget.subscription.categories;
      if (mounted) setState(() => _categories = cats);
    }
  }

  Color _badgeColor(int days) {
    if (days <= 2) return const Color(0xFFFF3B30);
    if (days <= 13) return const Color(0xFFFF9500);
    return const Color(0xFF30D158);
  }

  String _cycleLabel() {
    final pattern = widget.subscription.repeatPattern;
    if (pattern == 'yearly') return 'jährlich';
    if (pattern == 'monthly') return 'monatlich';
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final sub = widget.subscription;
    final isPaused = sub.isPaused;
    final days = sub.remainingDays();
    final accent = widget.accentColor ?? CupertinoColors.activeBlue;
    final isDark =
        MediaQuery.of(context).platformBrightness == Brightness.dark;

    return Slidable(
      key: ValueKey(sub.id),
      startActionPane: ActionPane(
        motion: const DrawerMotion(),
        extentRatio: 0.25,
        children: [
          SlidableAction(
            onPressed: (_) => widget.onTogglePin(),
            backgroundColor: CupertinoColors.activeBlue,
            foregroundColor: CupertinoColors.white,
            icon: sub.isPinned ? CupertinoIcons.pin_slash : CupertinoIcons.pin_fill,
            label: sub.isPinned ? 'Unpin' : 'Pin',
            borderRadius: BorderRadius.zero,
          ),
        ],
      ),
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        extentRatio: 0.50,
        children: [
          SlidableAction(
            onPressed: (_) => widget.onTogglePause(),
            backgroundColor: const Color(0xFFFF9500),
            foregroundColor: CupertinoColors.white,
            icon: sub.isPaused
                ? CupertinoIcons.play_arrow_solid
                : CupertinoIcons.pause_fill,
            label: sub.isPaused ? 'Weiter' : 'Pause',
            borderRadius: BorderRadius.zero,
          ),
          SlidableAction(
            onPressed: (_) => widget.onDelete(),
            backgroundColor: CupertinoColors.destructiveRed,
            foregroundColor: CupertinoColors.white,
            icon: CupertinoIcons.delete,
            label: 'Löschen',
            borderRadius: BorderRadius.zero,
          ),
        ],
      ),
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          CupertinoPageRoute(
            builder: (_) => SubscriptionShowView(subscription: sub),
          ),
        ),
        child: Container(
          color: isPaused
              ? (isDark
                  ? const Color(0xFF2C2C2E)
                  : const Color(0xFFF9F9F9))
              : (isDark
                  ? const Color(0xFF1C1C1E)
                  : CupertinoColors.white),
          child: Column(
            children: [
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Accent bar
                    Container(
                      width: 3,
                      decoration: BoxDecoration(
                        color: isPaused
                            ? const Color(0xFFD1D1D6)
                            : accent,
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(2),
                          bottomRight: Radius.circular(2),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(11, 10, 14, 10),
                        child: Row(
                          children: [
                            sub.buildImage(width: 36, height: 36, borderRadius: 9),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          sub.title,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: isPaused
                                                ? const Color(0xFFAEAEB2)
                                                : CupertinoColors.label
                                                    .resolveFrom(context),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (sub.isPinned)
                                        const Icon(
                                          CupertinoIcons.pin_fill,
                                          size: 10,
                                          color: Color(0xFFC7C7CC),
                                        ),
                                    ],
                                  ),
                                  Text(
                                    isPaused
                                        ? 'Pausiert'
                                        : () {
                                            final label = _cycleLabel();
                                            final dateStr = DateFormat.MMMd('de').format(sub.getNextBillDate());
                                            return label.isEmpty ? dateStr : '$dateStr · $label';
                                          }(),
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: isPaused
                                          ? const Color(0xFFC7C7CC)
                                          : CupertinoColors.secondaryLabel
                                              .resolveFrom(context),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  sub.displayConvertedPrice(widget.currency),
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: isPaused
                                        ? const Color(0xFFAEAEB2)
                                        : CupertinoColors.label
                                            .resolveFrom(context),
                                  ),
                                ),
                                if (!isPaused)
                                  Container(
                                    margin: const EdgeInsets.only(top: 2),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: _badgeColor(days),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '$days T',
                                      style: const TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                        color: CupertinoColors.white,
                                      ),
                                    ),
                                  )
                                else
                                  const Text(
                                    '⏸',
                                    style: TextStyle(fontSize: 11),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.displayCategories && _categories != null && _categories!.isNotEmpty)
                _buildCategories(),
              Container(
                height: 0.5,
                color: CupertinoColors.separator.resolveFrom(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategories() {
    final isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;
    return Container(
      color: isDark ? const Color(0xFF1C1C1E) : CupertinoColors.white,
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Wrap(
          spacing: 6,
          children: _categories!
              .map((cat) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: cat.color,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      cat.title,
                      style: const TextStyle(
                        color: CupertinoColors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ))
              .toList(),
        ),
      ),
    );
  }
}
