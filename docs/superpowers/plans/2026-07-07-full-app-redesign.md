# Full App Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Apply dark gradient header to all remaining screens, fix text color legibility (unresolved CupertinoDynamicColor), remove Material widget usage where possible.

**Architecture:** New shared `GradientHeader` widget → text color fix in statistic.dart → redesign each screen. 8 tasks total, each independently reviewable.

**Tech Stack:** Flutter/Dart, Cupertino, existing SubscriptionHeader/StatCard components.

## Global Constraints

- Dart SDK: `>=3.10.0 <4.0.0`
- iOS deployment target: 14.0
- Cupertino only — no new Material widget usage
- Do NOT add co-author to commits
- Gradient colors exactly: `[Color(0xFF1a1a2e), Color(0xFF16213e), Color(0xFF0f3460)]`
- Text colors: always use `CupertinoColors.label.resolveFrom(context)` — never `const TextStyle(color: CupertinoColors.label)` unresolved
- Do NOT modify `CardSection`, `CardDetailRow`, `CardActionButton` internals
- Do NOT change any business logic, only layout/styling
- Existing form field widgets (`EasyWalletTextField`, `AmountField`, `EasyWalletDropdownField`, `EasyWalletDatePickerField`, `MultiSelectDialogField`) stay unchanged

---

### Task 1: GradientHeader widget

**Files:**
- Create: `lib/views/components/gradient_header.dart`

**Interfaces:**
- Produces:
  ```dart
  class GradientHeader extends StatelessWidget {
    const GradientHeader({
      super.key,
      required this.title,
      this.showBackButton = false,
      this.trailing,
      this.onBack,
    });
    final String title;
    final bool showBackButton;
    final Widget? trailing;
    final VoidCallback? onBack;
  }
  ```

- [ ] **Step 1: Create the widget**

Create `lib/views/components/gradient_header.dart`:

```dart
import 'package:flutter/cupertino.dart';

class GradientHeader extends StatelessWidget {
  const GradientHeader({
    super.key,
    required this.title,
    this.showBackButton = false,
    this.trailing,
    this.onBack,
  });

  final String title;
  final bool showBackButton;
  final Widget? trailing;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1a1a2e), Color(0xFF16213e), Color(0xFF0f3460)],
        ),
      ),
      padding: EdgeInsets.fromLTRB(8, topPadding + 8, 8, 12),
      child: Row(
        children: [
          SizedBox(
            width: 44,
            child: showBackButton
                ? CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: onBack ?? () => Navigator.pop(context),
                    child: const Icon(
                      CupertinoIcons.back,
                      color: CupertinoColors.white,
                      size: 28,
                    ),
                  )
                : null,
          ),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: CupertinoColors.white,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(
            width: trailing != null ? null : 44,
            child: trailing,
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Verify it compiles**

```bash
flutter analyze lib/views/components/gradient_header.dart
```

Expected: `No issues found!`

- [ ] **Step 3: Commit**

```bash
git add lib/views/components/gradient_header.dart
git commit -m "Add GradientHeader shared component"
```

---

### Task 2: Fix text colors in statistic.dart

**Files:**
- Modify: `lib/views/main/statistic.dart`

**Problem:** `_statRow` and `_top3Row` use `const TextStyle(color: CupertinoColors.label)` — `CupertinoDynamicColor` is NOT auto-resolved in const TextStyles; always shows as black in dark mode.

**Interfaces:**
- Consumes: nothing from Task 1
- Produces: corrected `_statRow` and `_top3Row` methods

- [ ] **Step 1: Fix `_statRow`**

Find the `_statRow` method in `lib/views/main/statistic.dart`. Replace:

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
```

With:

```dart
Widget _statRow(String label, String value) {
  final labelColor = CupertinoColors.label.resolveFrom(context);
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(label,
              style: TextStyle(fontSize: 13, color: labelColor),
              overflow: TextOverflow.ellipsis),
        ),
        Text(value,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: labelColor)),
      ],
    ),
  );
}
```

- [ ] **Step 2: Fix `_top3Row`**

Find the `_top3Row` method. Replace the subscription title text style from bare `const TextStyle(fontSize: 13)` to:

```dart
Text(sub.title,
    style: TextStyle(fontSize: 13, color: CupertinoColors.label.resolveFrom(context)),
    overflow: TextOverflow.ellipsis),
```

- [ ] **Step 3: Fix `_chartDetailButton`**

Find the `_chartDetailButton` method. The button child has hardcoded `TextStyle(fontSize: 13, color: CupertinoColors.activeBlue)`. Ensure these use `resolveFrom`:

```dart
Text('Alle',
    style: TextStyle(
        fontSize: 13, color: CupertinoColors.activeBlue.resolveFrom(context))),
```

And the icon:
```dart
Icon(CupertinoIcons.chevron_right,
    size: 13, color: CupertinoColors.activeBlue.resolveFrom(context)),
```

- [ ] **Step 4: Run analyze**

```bash
flutter analyze lib/views/main/statistic.dart
```

Expected: no new issues.

- [ ] **Step 5: Commit**

```bash
git add lib/views/main/statistic.dart
git commit -m "Fix unresolved CupertinoDynamicColor in statistic text styles"
```

---

### Task 3: Redesign subscription/show.dart

**Files:**
- Modify: `lib/views/subscription/show.dart`

**Interfaces:**
- Consumes: `GradientHeader` from Task 1
  ```dart
  import 'package:easy_wallet/views/components/gradient_header.dart';
  ```
- Back button navigates `Navigator.pop(context)`
- Trailing: edit button (pencil icon → calls `openEditView(context)`)

**Current state:**
- `CupertinoNavigationBar` with title "subscriptions" + edit pencil trailing
- `_buildHeader()` has `isDarkMode` manual check for text color → fix to use `resolveFrom`
- `buildCategories()` uses `Material` widget + `Chip` (Material) → replace with Cupertino containers

- [ ] **Step 1: Replace nav bar with GradientHeader**

The current `build()` has:
```dart
return CupertinoPageScaffold(
  backgroundColor: CupertinoColors.systemGroupedBackground.resolveFrom(context),
  navigationBar: CupertinoNavigationBar(
    middle: Text(Intl.message('subscriptions'), ...),
    trailing: CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: () { openEditView(context); },
      child: const Icon(CupertinoIcons.pencil),
    ),
  ),
  child: SafeArea(
    minimum: const EdgeInsets.only(bottom: 20),
    top: true,
    bottom: true,
    child: ListView( ...
```

Replace the entire `build()` return with:

```dart
return CupertinoPageScaffold(
  backgroundColor: CupertinoColors.systemGroupedBackground.resolveFrom(context),
  child: Column(
    children: [
      GradientHeader(
        title: Intl.message('subscriptions'),
        showBackButton: true,
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => openEditView(context),
          child: const Icon(CupertinoIcons.pencil, color: CupertinoColors.white),
        ),
      ),
      Expanded(
        child: SafeArea(
          top: false,
          minimum: const EdgeInsets.only(bottom: 20),
          child: ListView(
            padding: const EdgeInsets.only(right: 16.0, left: 16.0, bottom: 20),
            children: <Widget>[
              const SizedBox(height: 20),
              _buildHeader(),
              const SizedBox(height: 5),
              buildCategories(),
              const SizedBox(height: 20),
              // ... all existing CardSection widgets unchanged ...
            ],
          ),
        ),
      ),
    ],
  ),
);
```

Keep all existing `CardSection` widgets (lines 72–170) exactly as they are — only the scaffold wrapper changes.

- [ ] **Step 2: Fix `_buildHeader()` text color**

Replace:
```dart
color: isDarkMode ? CupertinoColors.white : CupertinoColors.black,
```
With:
```dart
color: CupertinoColors.label.resolveFrom(context),
```

Remove the `isDarkMode` local variable if it's only used here.

- [ ] **Step 3: Fix `buildCategories()` — replace Material+Chip**

Replace the current `buildCategories()` method:
```dart
Widget buildCategories() {
  if (categories == null || categories!.isEmpty) return const SizedBox();
  return SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      children: categories!
          .map((cat) => Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: cat.color,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    cat.title,
                    style: const TextStyle(
                      color: CupertinoColors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ))
          .toList(),
    ),
  );
}
```

- [ ] **Step 4: Remove Material import**

Remove `import 'package:flutter/material.dart';` — it's no longer needed after removing Material widgets. Also remove `flutter/foundation.dart` if only used for `kIsWeb` check — keep it if `kIsWeb` is still referenced in `_deleteItem`.

Check: `kIsWeb` is in `flutter/foundation.dart` — keep that import.

- [ ] **Step 5: Load categories in initState**

The existing code has `List<category.Category>? categories;` declared but `initState` only sets `subscription = widget.subscription`. Categories never load, so `buildCategories()` always returns empty. Add:

```dart
@override
void initState() {
  super.initState();
  subscription = widget.subscription;
  _loadCategories();
}

Future<void> _loadCategories() async {
  final cats = await subscription.categories;
  if (mounted) {
    setState(() {
      categories = cats;
    });
  }
}
```

- [ ] **Step 6: Run analyze**

```bash
flutter analyze lib/views/subscription/show.dart
```

Expected: no new issues.

- [ ] **Step 7: Commit**

```bash
git add lib/views/subscription/show.dart
git commit -m "Redesign subscription detail: gradient header, fix category chips, fix text colors"
```

---

### Task 4: Redesign subscription/create.dart

**Files:**
- Modify: `lib/views/subscription/create.dart`

**Interfaces:**
- Consumes: `GradientHeader` from Task 1
- Back button: `Navigator.pop(context)`
- Trailing: save button (floppy_disk icon → calls `_saveItem(context)`)

**Current state:**
- `CupertinoNavigationBar` with "addSubscription" + save button
- `_buildImage()` uses `Icons.account_balance_wallet_rounded` (Material) → replace with `CupertinoIcons.creditcard`
- `isDarkMode` local var used for form field styling — keep as-is since form fields need it
- `Material` widget wrapping `MultiSelectDialogField` for background color

- [ ] **Step 1: Replace nav bar with GradientHeader**

The current `build()`:
```dart
return CupertinoPageScaffold(
  navigationBar: CupertinoNavigationBar(
    middle: AutoSizeText(Intl.message('addSubscription'), maxLines: 1, ...),
    trailing: CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: () => _saveItem(context),
      child: const Icon(CupertinoIcons.floppy_disk),
    ),
  ),
  child: SafeArea(
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        child: ListView( ...
```

Replace with:
```dart
return CupertinoPageScaffold(
  child: Column(
    children: [
      GradientHeader(
        title: Intl.message('addSubscription'),
        showBackButton: true,
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => _saveItem(context),
          child: const Icon(CupertinoIcons.floppy_disk, color: CupertinoColors.white),
        ),
      ),
      Expanded(
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              child: ListView(
                children: [ ... existing children unchanged ... ],
              ),
            ),
          ),
        ),
      ),
    ],
  ),
);
```

Add import at top:
```dart
import 'package:easy_wallet/views/components/gradient_header.dart';
```

- [ ] **Step 2: Fix icon in `_buildImage()`**

Replace:
```dart
return const Icon(
  Icons.account_balance_wallet_rounded,
  color: CupertinoColors.systemGrey,
  size: 40,
);
```

With:
```dart
return const Icon(
  CupertinoIcons.creditcard,
  color: CupertinoColors.systemGrey,
  size: 40,
);
```

- [ ] **Step 3: Remove unused Material import**

After fixing the icon, `flutter/material.dart` is no longer needed. Remove:
```dart
import 'package:flutter/material.dart';
```

Verify that no other Material-specific types remain in the file. The `MultiSelectDialogField` is from a separate package, not Material.

- [ ] **Step 4: Run analyze**

```bash
flutter analyze lib/views/subscription/create.dart
```

Expected: no new issues.

- [ ] **Step 5: Commit**

```bash
git add lib/views/subscription/create.dart
git commit -m "Redesign subscription create: gradient header, remove Material import"
```

---

### Task 5: Redesign subscription/edit.dart

**Files:**
- Modify: `lib/views/subscription/edit.dart`

**Interfaces:**
- Consumes: `GradientHeader` from Task 1
- Identical structural changes to Task 4

**Current state:** Very similar to create.dart — CupertinoNavigationBar + form content. Check if it also uses `Icons.*` from Material.

- [ ] **Step 1: Read the current build() method**

Read lines 85–200 of `lib/views/subscription/edit.dart` to find the navigationBar and scaffold structure.

- [ ] **Step 2: Replace nav bar with GradientHeader**

Replace `CupertinoNavigationBar` with `GradientHeader` following the same pattern as Task 4:
- `showBackButton: true`
- Trailing: save button (whatever icon the edit view uses)
- Wrap content in `Column` → `GradientHeader` + `Expanded(child: SafeArea(top: false, ...))`

Add import:
```dart
import 'package:easy_wallet/views/components/gradient_header.dart';
```

- [ ] **Step 3: Fix any Material icon usage**

Search for `Icons.` references and replace with `CupertinoIcons` equivalents.

- [ ] **Step 4: Remove flutter/material.dart import if unused**

Check if anything else uses Material. The `MultiSelectDialogField` usage does NOT require the Material import itself. Remove `import 'package:flutter/material.dart';` if unused.

- [ ] **Step 5: Run analyze**

```bash
flutter analyze lib/views/subscription/edit.dart
```

Expected: no new issues.

- [ ] **Step 6: Commit**

```bash
git add lib/views/subscription/edit.dart
git commit -m "Redesign subscription edit: gradient header, remove Material import"
```

---

### Task 6: Redesign categories/index.dart

**Files:**
- Modify: `lib/views/categories/index.dart`

**Interfaces:**
- Consumes: `GradientHeader` from Task 1
- No back button (tab-bar root)
- Header trailing: Row with sort button + add button
- Search bar moves below header (like subscription index)

**Current state:**
- `CupertinoNavigationBar` with search in middle, sort on leading, add on trailing
- Redundant 100px title section below nav bar
- `CircularProgressIndicator` (Material) → replace with `CupertinoActivityIndicator`
- `Material` widget usage

- [ ] **Step 1: Replace nav bar + title section**

Replace entire `build()` return:

```dart
@override
Widget build(BuildContext context) {
  return Consumer<CategoryProvider>(
    builder: (context, categoryProvider, child) {
      final categories = categoryProvider.categories;
      final sortedCategories = _sortCategories(categories);
      return CupertinoPageScaffold(
        backgroundColor: CupertinoColors.systemGroupedBackground.resolveFrom(context),
        child: Column(
          children: [
            GradientHeader(
              title: Intl.message('categories'),
              showBackButton: false,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    onPressed: _toggleSortDirection,
                    child: const Icon(
                      CupertinoIcons.arrow_up_arrow_down,
                      color: CupertinoColors.white,
                      size: 20,
                    ),
                  ),
                  CupertinoButton(
                    padding: const EdgeInsets.only(right: 4),
                    onPressed: () => _showAddCategoryDialog(context),
                    child: const Icon(
                      CupertinoIcons.add,
                      color: CupertinoColors.white,
                      size: 22,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: CupertinoSearchTextField(
                placeholder: Intl.message('search'),
                onChanged: (value) {
                  setState(() {
                    searchText = value;
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
                      : ListView.builder(
                          padding: const EdgeInsets.only(bottom: 85.0),
                          itemCount: sortedCategories.length,
                          itemBuilder: (context, index) {
                            return CategoryListComponent(
                              category: sortedCategories[index],
                              onUpdate: (updatedCategories) {
                                setState(() {
                                  _sortCategories(Provider.of<CategoryProvider>(
                                          context, listen: false)
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
    },
  );
}
```

Add import:
```dart
import 'package:easy_wallet/views/components/gradient_header.dart';
```

- [ ] **Step 2: Remove unused imports**

Remove `import 'package:flutter/material.dart';` if now unused. The `AlertDialog` in `_pickColor` still uses Material — check if it remains. If yes, keep the Material import.

Actually `_pickColor` uses `AlertDialog` and `showDialog` from Material — keep the import. Note this is OK since it's in an existing dialog method, not adding new Material widgets to the main UI.

- [ ] **Step 3: Run analyze**

```bash
flutter analyze lib/views/categories/index.dart
```

- [ ] **Step 4: Commit**

```bash
git add lib/views/categories/index.dart
git commit -m "Redesign categories list: gradient header, search below header, fix spinner"
```

---

### Task 7: Redesign categories/show.dart

**Files:**
- Modify: `lib/views/categories/show.dart`

**Interfaces:**
- Consumes: `GradientHeader` from Task 1
- Back button: yes (pushed screen)
- Trailing: color circle showing category color (decorative, indicates which category)

**Current state:**
- `CupertinoNavigationBar` with category title
- `CircularProgressIndicator` inside `_buildSubscriptions()` FutureBuilder
- Edit/delete cards: keep, but improve text colors

- [ ] **Step 1: Replace nav bar with GradientHeader**

Replace:
```dart
return CupertinoPageScaffold(
  backgroundColor: CupertinoColors.systemGroupedBackground.resolveFrom(context),
  navigationBar: CupertinoNavigationBar(
    middle: Text(category.title, ...),
  ),
  child: SafeArea(
    child: ListView( ...
```

With:
```dart
return CupertinoPageScaffold(
  backgroundColor: CupertinoColors.systemGroupedBackground.resolveFrom(context),
  child: Column(
    children: [
      GradientHeader(
        title: category.title,
        showBackButton: true,
        trailing: Container(
          width: 24,
          height: 24,
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            color: category.color,
            shape: BoxShape.circle,
            border: Border.all(color: CupertinoColors.white.withValues(alpha: 0.6), width: 1.5),
          ),
        ),
      ),
      Expanded(
        child: SafeArea(
          top: false,
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [ ...existing children unchanged... ],
          ),
        ),
      ),
    ],
  ),
);
```

- [ ] **Step 2: Fix CircularProgressIndicator in FutureBuilder**

In `_buildSubscriptions()`, the FutureBuilder snapshot waiting state shows `CircularProgressIndicator`. The FutureBuilder is inside a CardSection child. Replace:

```dart
if (snapshot.connectionState == ConnectionState.waiting) {
  return const Center(child: CircularProgressIndicator());
}
```

With:

```dart
if (snapshot.connectionState == ConnectionState.waiting) {
  return const Center(child: CupertinoActivityIndicator());
}
```

- [ ] **Step 3: Remove flutter/material.dart if unused**

Check if `AlertDialog` / `showDialog` / any Material widgets remain. The `_pickColor` method uses `AlertDialog` — keep the import if so.

- [ ] **Step 4: Run analyze**

```bash
flutter analyze lib/views/categories/show.dart
```

- [ ] **Step 5: Commit**

```bash
git add lib/views/categories/show.dart
git commit -m "Redesign category detail: gradient header, color indicator, fix spinner"
```

---

### Task 8: Redesign settings.dart

**Files:**
- Modify: `lib/views/main/settings.dart`

**Interfaces:**
- Consumes: `GradientHeader` from Task 1
- No back button (tab-bar root)
- No trailing action buttons needed

**Current state:**
- `CupertinoNavigationBar` with "settings" title + backgroundColor override
- All content is CardSections with CupertinoFormRow — stays unchanged
- `isDarkMode` / `textColor` local vars used throughout — keep as-is
- `AutoText` widgets use explicit `color: textColor` — fine as-is

- [ ] **Step 1: Replace nav bar with GradientHeader**

Replace:
```dart
return CupertinoPageScaffold(
    navigationBar: CupertinoNavigationBar(
      middle: Text(Intl.message('settings')),
      backgroundColor: backgroundColor,
    ),
    backgroundColor: CupertinoColors.systemGroupedBackground.resolveFrom(context),
    child: SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [ ...existing content... ],
      ),
    ));
```

With:
```dart
return CupertinoPageScaffold(
  backgroundColor: CupertinoColors.systemGroupedBackground.resolveFrom(context),
  child: Column(
    children: [
      GradientHeader(
        title: Intl.message('settings'),
        showBackButton: false,
      ),
      Expanded(
        child: SafeArea(
          top: false,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [ ...existing content unchanged... ],
          ),
        ),
      ),
    ],
  ),
);
```

Add import:
```dart
import 'package:easy_wallet/views/components/gradient_header.dart';
```

Remove `backgroundColor` local variable if only used for the nav bar background.

- [ ] **Step 2: Run analyze**

```bash
flutter analyze lib/views/main/settings.dart
```

- [ ] **Step 3: Run full test suite**

```bash
flutter test
```

- [ ] **Step 4: Commit**

```bash
git add lib/views/main/settings.dart
git commit -m "Redesign settings: gradient header replacing CupertinoNavigationBar"
```
