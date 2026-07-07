# Statistics Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the flat Statistics screen with a dark-gradient-header layout and 5 focused stat cards matching the subscription list visual style.

**Architecture:** Three tasks in sequence — new `StatCard` widget → `ChartDetailPage` gradient header → full `StatisticView` overhaul. `SubscriptionHeader` is reused from the subscription list redesign. Async costs-to-end-of-month/year values are preloaded in `_initializeData()` and stored in state.

**Tech Stack:** Flutter/Dart, Cupertino, fl_chart, syncfusion_flutter_charts, existing SubscriptionHeader widget.

## Global Constraints

- Dart SDK: `>=3.10.0 <4.0.0`
- iOS deployment target: 14.0
- Cupertino only — no new Material widget usage
- Do NOT add co-author to commits
- Gradient colors exactly: `[Color(0xFF1a1a2e), Color(0xFF16213e), Color(0xFF0f3460)]`
- `CardSection`, `CardDetailRow`, `CardActionButton` must remain unchanged (other screens use them)
- `monthlyLimit` SharedPreferences key (double, 0.0 = no budget)

---

### Task 1: StatCard widget

**Files:**
- Create: `lib/views/components/stat_card.dart`

**Interfaces:**
- Consumes: nothing from earlier tasks
- Produces:
  ```dart
  class StatCard extends StatelessWidget {
    const StatCard({
      super.key,
      required this.title,
      required this.icon,
      required this.children,
    });
    final String title;
    final IconData icon;
    final List<Widget> children;
  }
  ```

- [ ] **Step 1: Create the widget**

Create `lib/views/components/stat_card.dart`:

```dart
import 'package:flutter/cupertino.dart';

class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: CupertinoColors.secondarySystemGroupedBackground.resolveFrom(context),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: CupertinoColors.secondaryLabel.resolveFrom(context)),
              const SizedBox(width: 6),
              Text(
                title.toUpperCase(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
                ),
              ),
            ],
          ),
          Container(
            margin: const EdgeInsets.only(top: 8, bottom: 4),
            height: 0.5,
            color: CupertinoColors.separator.resolveFrom(context),
          ),
          ...children,
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Verify it compiles**

```bash
flutter analyze lib/views/components/stat_card.dart
```

Expected: `No issues found!`

- [ ] **Step 3: Commit**

```bash
git add lib/views/components/stat_card.dart
git commit -m "Add StatCard widget"
```

---

### Task 2: ChartDetailPage gradient header

**Files:**
- Modify: `lib/views/statistics/show.dart`

**Interfaces:**
- Consumes: nothing from Task 1
- Produces: `ChartDetailPage` with gradient header instead of `CupertinoNavigationBar`

- [ ] **Step 1: Read the current build method**

Read lines 33–50 of `lib/views/statistics/show.dart` to find the `CupertinoPageScaffold` + `CupertinoNavigationBar`.

- [ ] **Step 2: Replace the scaffold**

Replace the entire `build()` method in `ChartDetailPageState`:

```dart
@override
Widget build(BuildContext context) {
  final topPadding = MediaQuery.paddingOf(context).top;
  return CupertinoPageScaffold(
    child: Column(
      children: [
        // Gradient header with safe-area
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1a1a2e), Color(0xFF16213e), Color(0xFF0f3460)],
            ),
          ),
          padding: EdgeInsets.fromLTRB(8, topPadding + 8, 16, 12),
          child: Row(
            children: [
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () => Navigator.pop(context),
                child: const Icon(
                  CupertinoIcons.back,
                  color: CupertinoColors.white,
                  size: 28,
                ),
              ),
              Expanded(
                child: Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: CupertinoColors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 44), // balance back button
            ],
          ),
        ),
        Expanded(
          child: SafeArea(
            top: false,
            child: ListView(children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: _buildChart(context),
              ),
              _buildSubscriptionList(context),
            ]),
          ),
        ),
      ],
    ),
  );
}
```

- [ ] **Step 3: Remove unused Material import if present**

Check if `flutter/material.dart` is still needed. If only used for `Colors.grey`, replace with `CupertinoColors.systemGrey`. Remove the `material.dart` import if it becomes unused.

- [ ] **Step 4: Verify it compiles**

```bash
flutter analyze lib/views/statistics/show.dart
```

Expected: `No issues found!`

- [ ] **Step 5: Commit**

```bash
git add lib/views/statistics/show.dart
git commit -m "Replace ChartDetailPage nav bar with gradient header"
```

---

### Task 3: StatisticView overhaul

**Files:**
- Modify: `lib/views/main/statistic.dart`

**Interfaces:**
- Consumes:
  - `StatCard` from Task 1 — `import 'package:easy_wallet/views/components/stat_card.dart'`
  - `SubscriptionHeader` — `import 'package:easy_wallet/views/components/subscription_header.dart'`
    ```dart
    SubscriptionHeader({
      required double monthlySpent,
      required double yearlySpent,
      required String currencySymbol,
      double? budgetLimit,
      required VoidCallback onSortTap,
      required VoidCallback onAddTap,
    })
    ```
  - `Subscription.buildImage({double width, double height, double borderRadius})` — Widget
  - `Subscription.displayConvertedPrice(Currency)` — String
  - `Subscription.isPaused` — bool
  - `Subscription.url` — String?
  - `Subscription.repeatPattern` — String?
  - `Subscription.amount` — double

- [ ] **Step 1: Add new state fields**

In `StatisticViewState`, add these fields alongside the existing ones:

```dart
double _monthlyLimit = 0.0;
String _costToMonthEnd = '';
String _costToYearEnd = '';
```

- [ ] **Step 2: Update `_initializeData()`**

Replace the existing `_initializeData()` method:

```dart
@override
void initState() {
  super.initState();
  _initializeData();
}

Future<void> _initializeData() async {
  final prefs = await SharedPreferences.getInstance();
  _monthlyLimit = prefs.getDouble('monthlyLimit') ?? 0.0;

  if (!mounted) return;
  final subscriptions = context.read<SubscriptionProvider>().subscriptions;
  final currency = context.read<CurrencyProvider>().currency;

  await prefetchColors(subscriptions);
  _calculateStatistics(subscriptions);

  final toMonth = await calculateExpensesToEndOfMonth(subscriptions, currency);
  final toYear = await calculateExpensesToEndOfYear(subscriptions, currency);

  if (!mounted) return;
  setState(() {
    _costToMonthEnd = toMonth;
    _costToYearEnd = toYear;
    _isLoading = false;
  });
}
```

Add import at top of file:
```dart
import 'package:shared_preferences/shared_preferences.dart';
```

- [ ] **Step 3: Replace the `build()` method**

Replace the entire `build()` method with:

```dart
@override
Widget build(BuildContext context) {
  return Consumer2<CurrencyProvider, SubscriptionProvider>(
    builder: (context, currencyProvider, subProvider, _) {
      final currency = currencyProvider.currency;
      final subscriptions = subProvider.subscriptions;

      if (_isLoading) {
        return const CupertinoPageScaffold(
          child: Center(child: CupertinoActivityIndicator()),
        );
      }

      final top3 = _top3Subscriptions(subscriptions);

      return CupertinoPageScaffold(
        backgroundColor: CupertinoColors.systemGroupedBackground.resolveFrom(context),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: SubscriptionHeader(
                monthlySpent: monthlyExpenses,
                yearlySpent: yearlyExpenses,
                currencySymbol: currency.symbol,
                budgetLimit: _monthlyLimit > 0 ? _monthlyLimit : null,
                onSortTap: () {},
                onAddTap: () {},
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Card 1: Verbleibend
                  StatCard(
                    title: 'Verbleibend',
                    icon: CupertinoIcons.calendar_badge_minus,
                    children: [
                      _statRow('Bis Monatsende', _costToMonthEnd),
                      _statRow('Bis Jahresende', _costToYearEnd),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Card 2: Top 3
                  StatCard(
                    title: 'Top Abonnements',
                    icon: CupertinoIcons.star,
                    children: top3.isEmpty
                        ? [const Text('Keine aktiven Abonnements',
                            style: TextStyle(fontSize: 13, color: CupertinoColors.secondaryLabel))]
                        : top3.map((s) => _top3Row(s, currency)).toList(),
                  ),
                  const SizedBox(height: 12),
                  // Card 3: Kostenverteilung
                  if (subscriptions.isNotEmpty) ...[
                    StatCard(
                      title: 'Kostenverteilung',
                      icon: CupertinoIcons.chart_pie,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 8, bottom: 8),
                          child: buildPieChart(subscriptions),
                        ),
                        _chartDetailButton('Alle', subscriptions, null,
                            buildPieChartSections(subscriptions), context),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                  // Card 4: Verlauf
                  StatCard(
                    title: 'Monatlicher Verlauf',
                    icon: CupertinoIcons.chart_bar,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 8, bottom: 8),
                        child: _buildChart(_makeYearlyToMonthlyData(subscriptions)),
                      ),
                      _chartDetailButton('Alle', subscriptions,
                          _makeYearlyToMonthlyData(subscriptions), null, context),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Card 5: App Gesamt
                  StatCard(
                    title: 'Gesamt',
                    icon: CupertinoIcons.info_circle,
                    children: [
                      _statRow('Ausgaben seit Installation',
                          '${calculateExpensesSinceInstallation(subscriptions).toStringAsFixed(2)} ${currency.symbol}'),
                      _statRow('Aktive Abonnements',
                          '${subscriptions.where((s) => !s.isPaused).length}'),
                      _statRow('Pausiert',
                          '${subscriptions.where((s) => s.isPaused).length}'),
                    ],
                  ),
                  const SizedBox(height: 85),
                ]),
              ),
            ),
          ],
        ),
      );
    },
  );
}
```

- [ ] **Step 4: Add helper methods**

Add these private helpers to `StatisticViewState` (after `_calculateStatistics`):

```dart
Widget _statRow(String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(label,
              style: const TextStyle(fontSize: 13, color: CupertinoColors.label),
              overflow: TextOverflow.ellipsis),
        ),
        Text(value,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: CupertinoColors.label)),
      ],
    ),
  );
}

Widget _top3Row(Subscription sub, Currency currency) {
  final equiv = sub.repeatPattern == 'yearly'
      ? sub.amount / 12
      : sub.amount;
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: GestureDetector(
      onTap: () => Navigator.push(
        context,
        CupertinoPageRoute(
          builder: (_) => SubscriptionShowView(subscription: sub),
        ),
      ),
      child: Row(
        children: [
          sub.buildImage(width: 28, height: 28, borderRadius: 7),
          const SizedBox(width: 10),
          Expanded(
            child: Text(sub.title,
                style: const TextStyle(fontSize: 13),
                overflow: TextOverflow.ellipsis),
          ),
          Text(
            '${equiv.toStringAsFixed(2)} ${currency.symbol}/Mo',
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: CupertinoColors.secondaryLabel),
          ),
        ],
      ),
    ),
  );
}

Widget _chartDetailButton(
  String label,
  List<Subscription> subscriptions,
  List<CartesianSeries<ChartData, String>>? chartData,
  List<PieChartSectionData>? pieData,
  BuildContext context,
) {
  return CupertinoButton(
    padding: EdgeInsets.zero,
    minSize: 0,
    onPressed: () => Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (_) => ChartDetailPage(
          title: label,
          chartData: chartData,
          pieChartData: pieData,
          subscriptions: subscriptions,
        ),
      ),
    ),
    child: const Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text('Alle',
            style: TextStyle(
                fontSize: 13, color: CupertinoColors.activeBlue)),
        SizedBox(width: 4),
        Icon(CupertinoIcons.chevron_right,
            size: 13, color: CupertinoColors.activeBlue),
      ],
    ),
  );
}

List<Subscription> _top3Subscriptions(List<Subscription> subscriptions) {
  final active = subscriptions.where((s) => !s.isPaused).toList();
  active.sort((a, b) {
    final aEquiv = a.repeatPattern == 'yearly' ? a.amount / 12 : a.amount;
    final bEquiv = b.repeatPattern == 'yearly' ? b.amount / 12 : b.amount;
    return bEquiv.compareTo(aEquiv);
  });
  return active.take(3).toList();
}
```

Also add import for `SubscriptionShowView` and `StatCard` and `SubscriptionHeader` at the top:
```dart
import 'package:easy_wallet/views/components/stat_card.dart';
import 'package:easy_wallet/views/components/subscription_header.dart';
import 'package:easy_wallet/views/subscription/show.dart';
import 'package:shared_preferences/shared_preferences.dart';
```

- [ ] **Step 5: Run full analyze**

```bash
flutter analyze lib/views/main/statistic.dart lib/views/components/stat_card.dart
```

Expected: `No issues found!`

- [ ] **Step 6: Run tests**

```bash
flutter test
```

Expected: All tests pass.

- [ ] **Step 7: Commit**

```bash
git add lib/views/main/statistic.dart lib/views/components/stat_card.dart
git commit -m "Overhaul StatisticView: gradient header, 5 stat cards, Top 3 subscriptions"
```
