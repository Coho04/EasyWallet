# Subscription List Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Redesign the subscription list screen with a dark gradient header, budget warning, upcoming payments strip, swipe actions, and improved card design.

**Architecture:** Five new/modified widgets compose into an overhauled `SubscriptionIndexView`. `flutter_slidable` handles swipe gestures. SharedPreferences state (`monthlyLimit`, `displayCategories`) loads once in the parent instead of per list row.

**Tech Stack:** Flutter/Dart, Cupertino, flutter_slidable ^3.1.1, existing SharedPreferences + Provider stack.

## Global Constraints

- Dart SDK: `>=3.10.0 <4.0.0`
- iOS deployment target: 14.0
- Existing key `monthlyLimit` (double, 0.0 = disabled) in SharedPreferences — do not rename
- Existing key `displayCategories` (bool) in SharedPreferences — do not rename
- Follow Cupertino style; no Material widgets except where already present
- Dark mode must work — test with `MediaQuery.of(context).platformBrightness`
- No changes to data model, providers, or persistence layer

---

### Task 1: Add flutter_slidable dependency

**Files:**
- Modify: `pubspec.yaml`

**Interfaces:**
- Produces: `flutter_slidable` package available for import in Tasks 5+

- [ ] **Step 1: Add dependency**

In `pubspec.yaml`, under `dependencies:`, add after `multi_select_flutter`:

```yaml
  flutter_slidable: ^3.1.1
```

- [ ] **Step 2: Install**

```bash
flutter pub get
```

Expected output: `Got dependencies!` (no errors)

- [ ] **Step 3: Verify import works**

```bash
flutter build ios --config-only --no-codesign 2>&1 | tail -3
```

Expected: no dependency errors.

- [ ] **Step 4: Commit**

```bash
git add pubspec.yaml pubspec.lock
git commit -m "Add flutter_slidable dependency"
```

---

### Task 2: BudgetWarningBanner widget

**Files:**
- Create: `lib/views/components/budget_warning_banner.dart`

**Interfaces:**
- Consumes: nothing from earlier tasks
- Produces:
  ```dart
  class BudgetWarningBanner extends StatelessWidget {
    const BudgetWarningBanner({
      super.key,
      required this.spent,
      required this.limit,
      required this.currencySymbol,
    });
    final double spent;
    final double limit;
    final String currencySymbol;
  }
  ```

- [ ] **Step 1: Create the widget**

Create `lib/views/components/budget_warning_banner.dart`:

```dart
import 'package:flutter/cupertino.dart';

class BudgetWarningBanner extends StatelessWidget {
  const BudgetWarningBanner({
    super.key,
    required this.spent,
    required this.limit,
    required this.currencySymbol,
  });

  final double spent;
  final double limit;
  final String currencySymbol;

  @override
  Widget build(BuildContext context) {
    final over = spent - limit;
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1a1a2e), Color(0xFF16213e), Color(0xFF0f3460)],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0x26FF3B30),
          border: Border.all(color: const Color(0x59FF3B30)),
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: const Color(0x40FF3B30),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(
                CupertinoIcons.exclamationmark_triangle_fill,
                color: Color(0xFFFF6B6B),
                size: 14,
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Monatsbudget überschritten',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFFF6B6B),
                  ),
                ),
                Text(
                  'Limit $currencySymbol ${limit.toStringAsFixed(2)} · +$currencySymbol ${over.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xA8FF6B6B),
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
```

- [ ] **Step 2: Verify it compiles**

```bash
flutter analyze lib/views/components/budget_warning_banner.dart
```

Expected: `No issues found!`

- [ ] **Step 3: Commit**

```bash
git add lib/views/components/budget_warning_banner.dart
git commit -m "Add BudgetWarningBanner widget"
```

---

### Task 3: SubscriptionHeader widget

**Files:**
- Create: `lib/views/components/subscription_header.dart`

**Interfaces:**
- Consumes:
  ```dart
  // BudgetWarningBanner from Task 2
  BudgetWarningBanner(spent, limit, currencySymbol)
  ```
- Produces:
  ```dart
  class SubscriptionHeader extends StatelessWidget {
    const SubscriptionHeader({
      super.key,
      required this.monthlySpent,
      required this.yearlySpent,
      required this.currencySymbol,
      this.budgetLimit,       // null or 0.0 = no budget set
      required this.onSortTap,
      required this.onAddTap,
    });
    final double monthlySpent;
    final double yearlySpent;
    final String currencySymbol;
    final double? budgetLimit;
    final VoidCallback onSortTap;
    final VoidCallback onAddTap;
  }
  ```

- [ ] **Step 1: Create the widget**

Create `lib/views/components/subscription_header.dart`:

```dart
import 'package:easy_wallet/views/components/budget_warning_banner.dart';
import 'package:flutter/cupertino.dart';

class SubscriptionHeader extends StatelessWidget {
  const SubscriptionHeader({
    super.key,
    required this.monthlySpent,
    required this.yearlySpent,
    required this.currencySymbol,
    this.budgetLimit,
    required this.onSortTap,
    required this.onAddTap,
  });

  final double monthlySpent;
  final double yearlySpent;
  final String currencySymbol;
  final double? budgetLimit;
  final VoidCallback onSortTap;
  final VoidCallback onAddTap;

  bool get _budgetExceeded =>
      budgetLimit != null && budgetLimit! > 0 && monthlySpent > budgetLimit!;

  double get _budgetProgress =>
      (budgetLimit != null && budgetLimit! > 0)
          ? (monthlySpent / budgetLimit!).clamp(0.0, 1.0)
          : 0.0;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildGradientHeader(),
        if (_budgetExceeded)
          BudgetWarningBanner(
            spent: monthlySpent,
            limit: budgetLimit!,
            currencySymbol: currencySymbol,
          ),
      ],
    );
  }

  Widget _buildGradientHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1a1a2e), Color(0xFF16213e), Color(0xFF0f3460)],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: onSortTap,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: const Color(0x1FFFFFFF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    CupertinoIcons.arrow_up_arrow_down,
                    color: CupertinoColors.white,
                    size: 14,
                  ),
                ),
              ),
              const Text(
                'EasyWallet',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: CupertinoColors.white,
                ),
              ),
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: onAddTap,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: const Color(0x1FFFFFFF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    CupertinoIcons.add,
                    color: CupertinoColors.white,
                    size: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildSpendCard('Diesen Monat', monthlySpent, currencySymbol)),
              const SizedBox(width: 8),
              Expanded(child: _buildSpendCard('Dieses Jahr', yearlySpent, currencySymbol)),
            ],
          ),
          if (budgetLimit != null && budgetLimit! > 0) ...[
            const SizedBox(height: 10),
            _buildBudgetBar(),
          ],
        ],
      ),
    );
  }

  Widget _buildSpendCard(String label, double value, String symbol) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0x1AFFFFFF),
        border: Border.all(color: const Color(0x26FFFFFF)),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 10,
              color: Color(0x8CFFFFFF),
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '$symbol ${value.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: CupertinoColors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetBar() {
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: _budgetProgress,
              minHeight: 3,
              backgroundColor: const Color(0x33FFFFFF),
              valueColor: AlwaysStoppedAnimation<Color>(
                _budgetProgress >= 1.0
                    ? const Color(0xFFFF3B30)
                    : _budgetProgress >= 0.8
                        ? const Color(0xFFFF9500)
                        : const Color(0xFF30D158),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          _budgetExceeded
              ? '€ ${(monthlySpent - budgetLimit!).toStringAsFixed(2)} über'
              : '${(100 * _budgetProgress).toStringAsFixed(0)}%',
          style: const TextStyle(fontSize: 10, color: Color(0x72FFFFFF)),
        ),
      ],
    );
  }
}
```

- [ ] **Step 2: Verify it compiles**

```bash
flutter analyze lib/views/components/subscription_header.dart
```

Expected: `No issues found!`

- [ ] **Step 3: Commit**

```bash
git add lib/views/components/subscription_header.dart
git commit -m "Add SubscriptionHeader widget with gradient and budget bar"
```

---

### Task 4: UpcomingStrip widget

**Files:**
- Create: `lib/views/components/upcoming_strip.dart`

**Interfaces:**
- Consumes: `Subscription.remainingDays()`, `Subscription.buildImage(width, height, borderRadius)`
- Produces:
  ```dart
  class UpcomingStrip extends StatelessWidget {
    const UpcomingStrip({
      super.key,
      required this.upcomingSubscriptions, // pre-filtered: !isPaused && remainingDays() <= 7
      required this.currencySymbol,
    });
    final List<Subscription> upcomingSubscriptions;
    final String currencySymbol;
  }
  ```

- [ ] **Step 1: Create the widget**

Create `lib/views/components/upcoming_strip.dart`:

```dart
import 'package:easy_wallet/model/subscription.dart';
import 'package:flutter/cupertino.dart';

class UpcomingStrip extends StatelessWidget {
  const UpcomingStrip({
    super.key,
    required this.upcomingSubscriptions,
    required this.currencySymbol,
  });

  final List<Subscription> upcomingSubscriptions;
  final String currencySymbol;

  Color _daysColor(int days) {
    if (days <= 2) return const Color(0xFFFF3B30);
    if (days <= 5) return const Color(0xFFFF9500);
    return const Color(0xFF8E8E93);
  }

  @override
  Widget build(BuildContext context) {
    if (upcomingSubscriptions.isEmpty) return const SizedBox.shrink();

    return Container(
      color: CupertinoColors.systemGroupedBackground.resolveFrom(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 6, 14, 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'NÄCHSTE 7 TAGE',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: CupertinoColors.label,
                  ),
                ),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  minSize: 0,
                  onPressed: () {},
                  child: const Text(
                    'Alle →',
                    style: TextStyle(fontSize: 12, color: CupertinoColors.activeBlue),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 80,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
              itemCount: upcomingSubscriptions.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final sub = upcomingSubscriptions[index];
                final days = sub.remainingDays();
                return Container(
                  width: 72,
                  decoration: BoxDecoration(
                    color: CupertinoColors.secondarySystemGroupedBackground
                        .resolveFrom(context),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: CupertinoColors.black.withOpacity(0.06),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      sub.buildImage(width: 28, height: 28, borderRadius: 7),
                      const SizedBox(height: 4),
                      Text(
                        sub.title,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: CupertinoColors.label,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        '$days T',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: days <= 2 ? FontWeight.w700 : FontWeight.w400,
                          color: _daysColor(days),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Verify it compiles**

```bash
flutter analyze lib/views/components/upcoming_strip.dart
```

Expected: `No issues found!`

- [ ] **Step 3: Commit**

```bash
git add lib/views/components/upcoming_strip.dart
git commit -m "Add UpcomingStrip widget"
```

---

### Task 5: SubscriptionListComponent redesign

**Files:**
- Modify: `lib/views/components/subscription_list_component.dart`

**Interfaces:**
- Consumes: `flutter_slidable` (Task 1), `Subscription` model methods
- Produces:
  ```dart
  class SubscriptionListComponent extends StatefulWidget {
    const SubscriptionListComponent({
      super.key,
      required this.subscription,
      required this.currency,
      required this.displayCategories,  // was loaded per-item, now passed from parent
      this.accentColor,                 // optional dominant color from favicon
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
  }
  ```

- [ ] **Step 1: Replace the file**

Replace the full content of `lib/views/components/subscription_list_component.dart`:

```dart
import 'package:easy_wallet/enum/currency.dart';
import 'package:easy_wallet/model/category.dart';
import 'package:easy_wallet/views/subscription/show.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
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
                                        : '${DateFormat.MMMd('de').format(sub.getNextBillDate())} · ${_cycleLabel()}',
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
              const Divider(height: 0.5, thickness: 0.5),
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
              .map((cat) => Chip(
                    label: Text(cat.title,
                        style: const TextStyle(
                            color: CupertinoColors.white, fontSize: 11)),
                    padding: EdgeInsets.zero,
                    backgroundColor: cat.color,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ))
              .toList(),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Verify it compiles**

```bash
flutter analyze lib/views/components/subscription_list_component.dart
```

Expected: `No issues found!`

- [ ] **Step 3: Commit**

```bash
git add lib/views/components/subscription_list_component.dart
git commit -m "Redesign SubscriptionListComponent: swipe actions, accent bar, badges"
```

---

### Task 6: SubscriptionIndexView overhaul

**Files:**
- Modify: `lib/views/subscription/index.dart`

**Interfaces:**
- Consumes: `SubscriptionHeader` (Task 3), `UpcomingStrip` (Task 4), `SubscriptionListComponent` (Task 5)
- Produces: complete redesigned main screen

- [ ] **Step 1: Replace the file**

Replace the full content of `lib/views/subscription/index.dart`:

```dart
import 'dart:async';

import 'package:easy_wallet/easy_wallet_app.dart';
import 'package:easy_wallet/enum/payment_rate.dart';
import 'package:easy_wallet/enum/sort_option.dart';
import 'package:easy_wallet/model/subscription.dart';
import 'package:easy_wallet/persistence_controller.dart';
import 'package:easy_wallet/provider/category_provider.dart';
import 'package:easy_wallet/provider/currency_provider.dart';
import 'package:easy_wallet/provider/subscription_provider.dart';
import 'package:easy_wallet/views/components/subscription_header.dart';
import 'package:easy_wallet/views/components/subscription_list_component.dart';
import 'package:easy_wallet/views/components/upcoming_strip.dart';
import 'package:easy_wallet/views/subscription/create.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SubscriptionIndexView extends StatefulWidget {
  const SubscriptionIndexView({super.key});

  @override
  SubscriptionIndexViewState createState() => SubscriptionIndexViewState();
}

class SubscriptionIndexViewState extends State<SubscriptionIndexView> {
  String _searchText = '';
  SortOption _sortOption = SortOption.remainingDaysAscending;
  bool _isLoading = true;
  bool _displayCategories = true;
  double _monthlyLimit = 0.0;
  Map<String, Color> _colorCache = {};
  Timer? _debounce;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    _displayCategories = prefs.getBool('displayCategories') ?? true;
    _monthlyLimit = prefs.getDouble('monthlyLimit') ?? 0.0;

    if (prefs.getBool('syncWithGoogleDrive') ?? false) {
      final cloud = await PersistenceController.instance.googleDrive;
      await cloud.syncFrom();
    }

    if (!mounted) return;
    await Provider.of<SubscriptionProvider>(context, listen: false)
        .loadSubscriptions();
    await Provider.of<CurrencyProvider>(context, listen: false).loadCurrency();
    await Provider.of<CategoryProvider>(context, listen: false).loadCategories();

    setState(() => _isLoading = false);
  }

  Future<Color> _accentColor(Subscription sub) async {
    final key = sub.getFaviconUrl();
    if (_colorCache.containsKey(key)) return _colorCache[key]!;
    final color = await sub.getDominantColorFromUrl(customUrl: key);
    _colorCache[key] = color;
    return color;
  }

  List<Subscription> _sorted(List<Subscription> subs) {
    final filtered = subs.where((s) =>
        s.title.toLowerCase().contains(_searchText.toLowerCase())).toList();

    filtered.sort((a, b) {
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;
      if (a.isPaused && !b.isPaused) return 1;
      if (!a.isPaused && b.isPaused) return -1;
      switch (_sortOption) {
        case SortOption.alphabeticalAscending:
          return a.title.compareTo(b.title);
        case SortOption.alphabeticalDescending:
          return b.title.compareTo(a.title);
        case SortOption.costAscending:
          return a.amount.compareTo(b.amount);
        case SortOption.costDescending:
          return b.amount.compareTo(a.amount);
        case SortOption.remainingDaysAscending:
          return a.remainingDays().compareTo(b.remainingDays());
        case SortOption.remainingDaysDescending:
          return b.remainingDays().compareTo(a.remainingDays());
        default:
          return 0;
      }
    });
    return filtered;
  }

  double _calcMonthly(List<Subscription> subs) {
    final now = DateTime.now();
    return subs.where((s) {
      if (s.isPaused) return false;
      final next = s.getNextBillDate();
      return next.month == now.month && next.year == now.year;
    }).fold(0.0, (sum, s) => sum + s.amount);
  }

  double _calcYearly(List<Subscription> subs) {
    final now = DateTime.now();
    final endOfYear = DateTime(now.year, 12, 31);
    double total = 0.0;
    for (final s in subs) {
      if (s.isPaused) continue;
      DateTime next = s.getNextBillDate();
      if (s.repeatPattern == PaymentRate.yearly.value) {
        if (next.year == now.year) total += s.amount;
      } else if (s.repeatPattern == PaymentRate.monthly.value) {
        while (next.isBefore(endOfYear.add(const Duration(days: 1)))) {
          total += s.amount;
          next = DateTime(next.year, next.month + 1, next.day);
        }
      }
    }
    return total;
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 200), () {
      setState(() => _searchText = value);
    });
  }

  void _togglePin(Subscription sub) {
    sub.isPinned = !sub.isPinned;
    Provider.of<SubscriptionProvider>(context, listen: false)
        .saveSubscription(sub);
  }

  void _togglePause(Subscription sub) {
    sub.isPaused = !sub.isPaused;
    Provider.of<SubscriptionProvider>(context, listen: false)
        .saveSubscription(sub);
  }

  void _delete(Subscription sub) {
    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Löschen?'),
        content: Text('"${sub.title}" wird unwiderruflich gelöscht.'),
        actions: [
          CupertinoDialogAction(
            child: const Text('Abbrechen'),
            onPressed: () => Navigator.pop(ctx),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.pop(ctx);
              Provider.of<SubscriptionProvider>(context, listen: false)
                  .deleteSubscription(sub);
            },
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
  }

  void _showSortSheet() {
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: Text(
          Intl.message('sortOptions'),
          style: EasyWalletApp.responsiveTextStyle(ctx,
              color: CupertinoColors.systemGrey),
        ),
        actions: SortOption.values
            .map((opt) => CupertinoActionSheetAction(
                  onPressed: () {
                    setState(() => _sortOption = opt);
                    Navigator.pop(ctx);
                  },
                  child: Text(
                    opt.translate(),
                    style: EasyWalletApp.responsiveTextStyle(ctx,
                        color: CupertinoColors.activeBlue),
                  ),
                ))
            .toList(),
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(ctx),
          child: Text(
            Intl.message('cancel'),
            style: EasyWalletApp.responsiveTextStyle(ctx,
                color: CupertinoColors.systemGrey),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<SubscriptionProvider, CurrencyProvider>(
      builder: (context, subProvider, currProvider, _) {
        final currency = currProvider.currency;
        final sorted = _sorted(subProvider.subscriptions);
        final monthly = _calcMonthly(subProvider.subscriptions);
        final yearly = _calcYearly(subProvider.subscriptions);
        final upcoming = sorted
            .where((s) => !s.isPaused && s.remainingDays() <= 7)
            .toList();

        return CupertinoPageScaffold(
          child: CustomScrollView(
            slivers: [
              // Fixed header (not in sliver — use SliverToBoxAdapter)
              SliverToBoxAdapter(
                child: SubscriptionHeader(
                  monthlySpent: monthly,
                  yearlySpent: yearly,
                  currencySymbol: currency.symbol,
                  budgetLimit: _monthlyLimit > 0 ? _monthlyLimit : null,
                  onSortTap: _showSortSheet,
                  onAddTap: () => Navigator.push(
                    context,
                    CupertinoPageRoute(
                      builder: (_) => const SubscriptionCreateView(),
                    ),
                  ).then((_) => _init()),
                ),
              ),
              // Search bar
              SliverToBoxAdapter(
                child: Container(
                  color: CupertinoColors.systemGroupedBackground
                      .resolveFrom(context),
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
                  child: CupertinoSearchTextField(
                    controller: _searchController,
                    placeholder: Intl.message('search'),
                    onChanged: _onSearchChanged,
                  ),
                ),
              ),
              // Upcoming strip
              if (upcoming.isNotEmpty)
                SliverToBoxAdapter(
                  child: UpcomingStrip(
                    upcomingSubscriptions: upcoming,
                    currencySymbol: currency.symbol,
                  ),
                ),
              // Section header
              SliverToBoxAdapter(
                child: Container(
                  color: CupertinoColors.systemGroupedBackground
                      .resolveFrom(context),
                  padding: const EdgeInsets.fromLTRB(14, 6, 14, 2),
                  child: const Text(
                    'ALLE ABONNEMENTS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: CupertinoColors.label,
                    ),
                  ),
                ),
              ),
              // List
              if (_isLoading)
                const SliverFillRemaining(
                  child: Center(child: CupertinoActivityIndicator()),
                )
              else if (sorted.isEmpty)
                SliverFillRemaining(child: _emptyState())
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final sub = sorted[index];
                      return FutureBuilder<Color>(
                        future: _accentColor(sub),
                        builder: (context, snap) => SubscriptionListComponent(
                          subscription: sub,
                          currency: currency,
                          displayCategories: _displayCategories,
                          accentColor: snap.data,
                          onTogglePin: () => _togglePin(sub),
                          onTogglePause: () => _togglePause(sub),
                          onDelete: () => _delete(sub),
                        ),
                      );
                    },
                    childCount: sorted.length,
                  ),
                ),
              const SliverPadding(padding: EdgeInsets.only(bottom: 85)),
            ],
          ),
        );
      },
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            Intl.message('noSubscriptionsAvailable'),
            style: const TextStyle(color: CupertinoColors.systemGrey),
          ),
          const SizedBox(height: 16),
          CupertinoButton.filled(
            onPressed: () => Navigator.push(
              context,
              CupertinoPageRoute(
                builder: (_) => const SubscriptionCreateView(),
              ),
            ).then((_) => _init()),
            child: Text(
              Intl.message('addNewSubscription'),
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: CupertinoColors.white),
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Run analyzer**

```bash
flutter analyze lib/views/subscription/index.dart
```

Expected: `No issues found!` (fix any `unused import` warnings)

- [ ] **Step 3: Full analyze**

```bash
flutter analyze lib/
```

Expected: `No issues found!`

- [ ] **Step 4: Build check**

```bash
flutter build ios --config-only --no-codesign 2>&1 | tail -5
```

Expected: no build errors.

- [ ] **Step 5: Commit**

```bash
git add lib/views/subscription/index.dart
git commit -m "Overhaul SubscriptionIndexView: gradient header, upcoming strip, swipe actions"
```

---

### Task 7: Smoke test on device / simulator

**Files:** none

- [ ] **Step 1: Run on iOS simulator**

```bash
flutter run -d "iPhone 16"
```

- [ ] **Step 2: Verify checklist**

Walk through manually:
- [ ] Dark gradient header shows with correct monthly + yearly totals
- [ ] Budget bar visible when `monthlyLimit > 0` in Settings
- [ ] Budget warning banner appears when monthly spend > limit
- [ ] Upcoming strip shows subscriptions due within 7 days (red badge ≤ 2 days, orange ≤ 5 days)
- [ ] Swipe right on any row → Pin button appears in blue
- [ ] Swipe left on any row → Pause (orange) + Delete (red) buttons appear
- [ ] Delete triggers confirmation dialog, then removes item
- [ ] Pause grays out the row; resume restores it
- [ ] Search filters list with 200ms debounce (no flicker on fast typing)
- [ ] Dark mode looks correct (switch in iOS Settings)
- [ ] Existing Create / Edit / Detail flows still work

- [ ] **Step 3: Commit final**

```bash
git add -A
git commit -m "Subscription list redesign complete — smoke tested"
```
