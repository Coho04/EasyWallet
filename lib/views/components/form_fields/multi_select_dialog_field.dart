import 'package:collection/collection.dart' show IterableExtension, ListEquality;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:multi_select_flutter/chip_display/multi_select_chip_display.dart';
import 'package:multi_select_flutter/dialog/mult_select_dialog.dart';
import 'package:multi_select_flutter/util/multi_select_item.dart';
import 'package:multi_select_flutter/util/multi_select_list_type.dart';

class MultiSelectDialogField<V> extends FormField<List<V>> {
  final MultiSelectListType? listType;
  final BoxDecoration? decoration;
  final Text? buttonText;
  final Icon? buttonIcon;
  final Widget? title;
  final List<MultiSelectItem<V>> items;
  final void Function(List<V>)? onSelectionChanged;
  final MultiSelectChipDisplay<V>? chipDisplay;
  final List<V> initialValue;
  final void Function(List<V>) onConfirm;
  final bool searchable;
  final Text? confirmText;
  final Text? cancelText;
  final Color? barrierColor;
  final Color? selectedColor;
  final double? dialogHeight;
  final double? dialogWidth;
  final String? searchHint;
  final Color Function(V)? colorator;
  final Color? backgroundColor;
  final Color? unselectedColor;
  final Icon? searchIcon;
  final Icon? closeSearchIcon;
  final TextStyle? itemsTextStyle;
  final TextStyle? selectedItemsTextStyle;
  final TextStyle? searchTextStyle;
  final TextStyle? searchHintStyle;
  final bool separateSelectedItems;
  final Color? checkColor;
  final bool isDismissible;
  final AutovalidateMode autovalidateMode;
  final FormFieldValidator<List<V>>? validator;
  final FormFieldSetter<List<V>>? onSaved;
  final GlobalKey<FormFieldState>? key;
  FormFieldState<List<V>>? state;

  MultiSelectDialogField({
    required this.items,
    required this.onConfirm,
    this.title,
    this.buttonText,
    this.buttonIcon,
    this.listType,
    this.decoration,
    this.onSelectionChanged,
    this.chipDisplay,
    this.searchable = false,
    this.confirmText,
    this.cancelText,
    this.barrierColor,
    this.selectedColor,
    this.searchHint,
    this.dialogHeight,
    this.dialogWidth,
    this.colorator,
    this.backgroundColor,
    this.unselectedColor,
    this.searchIcon,
    this.closeSearchIcon,
    this.itemsTextStyle,
    this.searchTextStyle,
    this.searchHintStyle,
    this.selectedItemsTextStyle,
    this.separateSelectedItems = false,
    this.checkColor,
    this.isDismissible = true,
    this.onSaved,
    this.validator,
    this.initialValue = const [],
    this.autovalidateMode = AutovalidateMode.disabled,
    this.key,
  }) : super(
            key: key,
            onSaved: onSaved,
            validator: validator,
            autovalidateMode: autovalidateMode,
            initialValue: initialValue,
            builder: (FormFieldState<List<V>> state) {
              _MultiSelectDialogFieldView<V> field =
                  _MultiSelectDialogFieldView<V>(
                title: title,
                items: items,
                buttonText: buttonText,
                buttonIcon: buttonIcon,
                chipDisplay: chipDisplay,
                decoration: decoration,
                listType: listType,
                onConfirm: onConfirm,
                onSelectionChanged: onSelectionChanged,
                initialValue: initialValue,
                searchable: searchable,
                confirmText: confirmText,
                cancelText: cancelText,
                barrierColor: barrierColor,
                selectedColor: selectedColor,
                searchHint: searchHint,
                dialogHeight: dialogHeight,
                dialogWidth: dialogWidth,
                colorator: colorator,
                backgroundColor: backgroundColor,
                unselectedColor: unselectedColor,
                searchIcon: searchIcon,
                closeSearchIcon: closeSearchIcon,
                itemsTextStyle: itemsTextStyle,
                searchTextStyle: searchTextStyle,
                searchHintStyle: searchHintStyle,
                selectedItemsTextStyle: selectedItemsTextStyle,
                separateSelectedItems: separateSelectedItems,
                checkColor: checkColor,
                isDismissible: isDismissible,
              );
              return _MultiSelectDialogFieldView<V>._withState(field, state);
            });
}

class _MultiSelectDialogFieldView<V> extends StatefulWidget {
  final MultiSelectListType? listType;
  final BoxDecoration? decoration;
  final Text? buttonText;
  final Icon? buttonIcon;
  final Widget? title;
  final List<MultiSelectItem<V>> items;
  final void Function(List<V>)? onSelectionChanged;
  final MultiSelectChipDisplay<V>? chipDisplay;
  final List<V> initialValue;
  final void Function(List<V>)? onConfirm;
  final bool? searchable;
  final Text? confirmText;
  final Text? cancelText;
  final Color? barrierColor;
  final Color? selectedColor;
  final double? dialogHeight;
  final double? dialogWidth;
  final String? searchHint;
  final Color Function(V)? colorator;
  final Color? backgroundColor;
  final Color? unselectedColor;
  final Icon? searchIcon;
  final Icon? closeSearchIcon;
  final TextStyle? itemsTextStyle;
  final TextStyle? selectedItemsTextStyle;
  final TextStyle? searchTextStyle;
  final TextStyle? searchHintStyle;
  final bool separateSelectedItems;
  final Color? checkColor;
  final bool isDismissible;
  FormFieldState<List<V>>? state;

  _MultiSelectDialogFieldView({
    required this.items,
    this.title,
    this.buttonText,
    this.buttonIcon,
    this.listType,
    this.decoration,
    this.onSelectionChanged,
    this.onConfirm,
    this.chipDisplay,
    this.initialValue = const [],
    this.searchable,
    this.confirmText,
    this.cancelText,
    this.barrierColor,
    this.selectedColor,
    this.searchHint,
    this.dialogHeight,
    this.dialogWidth,
    this.colorator,
    this.backgroundColor,
    this.unselectedColor,
    this.searchIcon,
    this.closeSearchIcon,
    this.itemsTextStyle,
    this.searchTextStyle,
    this.searchHintStyle,
    this.selectedItemsTextStyle,
    this.separateSelectedItems = false,
    this.checkColor,
    required this.isDismissible,
  });

  _MultiSelectDialogFieldView._withState(
      _MultiSelectDialogFieldView<V> field, FormFieldState<List<V>> state)
      : items = field.items,
        title = field.title,
        buttonText = field.buttonText,
        buttonIcon = field.buttonIcon,
        listType = field.listType,
        decoration = field.decoration,
        onSelectionChanged = field.onSelectionChanged,
        onConfirm = field.onConfirm,
        chipDisplay = field.chipDisplay,
        initialValue = field.initialValue,
        searchable = field.searchable,
        confirmText = field.confirmText,
        cancelText = field.cancelText,
        barrierColor = field.barrierColor,
        selectedColor = field.selectedColor,
        dialogHeight = field.dialogHeight,
        dialogWidth = field.dialogWidth,
        searchHint = field.searchHint,
        colorator = field.colorator,
        backgroundColor = field.backgroundColor,
        unselectedColor = field.unselectedColor,
        searchIcon = field.searchIcon,
        closeSearchIcon = field.closeSearchIcon,
        itemsTextStyle = field.itemsTextStyle,
        searchHintStyle = field.searchHintStyle,
        searchTextStyle = field.searchTextStyle,
        selectedItemsTextStyle = field.selectedItemsTextStyle,
        separateSelectedItems = field.separateSelectedItems,
        checkColor = field.checkColor,
        isDismissible = field.isDismissible,
        state = state;

  @override
  __MultiSelectDialogFieldViewState createState() =>
      __MultiSelectDialogFieldViewState<V>();
}

class __MultiSelectDialogFieldViewState<V>
    extends State<_MultiSelectDialogFieldView<V>> {
  List<V> _selectedItems = [];

  @override
  void initState() {
    super.initState();
    _selectedItems.addAll(widget.initialValue);
  }

  @override
  void didUpdateWidget(_MultiSelectDialogFieldView<V> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!const ListEquality().equals(oldWidget.initialValue, widget.initialValue)) {
      _selectedItems.clear();
      _selectedItems.addAll(widget.initialValue);
      setState(() {});
    }
  }

  Widget _buildInheritedChipDisplay() {
    List<MultiSelectItem<V>?> chipDisplayItems = [];
    chipDisplayItems = _selectedItems
        .map((e) =>
            widget.items.firstWhereOrNull((element) => e == element.value))
        .toList();
    chipDisplayItems.removeWhere((element) => element == null);
    if (widget.chipDisplay != null) {
      if (widget.chipDisplay!.disabled!) {
        return Container();
      } else {
        return MultiSelectChipDisplay<V>(
          items: chipDisplayItems,
          colorator: widget.chipDisplay!.colorator ?? widget.colorator,
          onTap: (item) {
            List<V>? newValues;
            if (widget.chipDisplay!.onTap != null) {
              dynamic result = widget.chipDisplay!.onTap!(item);
              if (result is List<V>) newValues = result;
            }
            if (newValues != null) {
              _selectedItems = newValues;
              if (widget.state != null) {
                widget.state!.didChange(_selectedItems);
              }
            }
          },
          decoration: widget.chipDisplay!.decoration,
          chipColor: widget.chipDisplay!.chipColor ??
              ((widget.selectedColor != null &&
                      widget.selectedColor != Colors.transparent)
                  ? widget.selectedColor!.withOpacity(0.35)
                  : null),
          alignment: widget.chipDisplay!.alignment,
          textStyle: widget.chipDisplay!.textStyle,
          icon: widget.chipDisplay!.icon,
          shape: widget.chipDisplay!.shape,
          scroll: widget.chipDisplay!.scroll,
          scrollBar: widget.chipDisplay!.scrollBar,
          height: widget.chipDisplay!.height,
          chipWidth: widget.chipDisplay!.chipWidth,
        );
      }
    } else {
      return MultiSelectChipDisplay<V>(
        items: chipDisplayItems,
        colorator: widget.colorator,
        chipColor: (widget.selectedColor != null &&
                widget.selectedColor != Colors.transparent)
            ? widget.selectedColor!.withOpacity(0.35)
            : null,
      );
    }
  }

  _showDialog(BuildContext ctx) async {
    await showCupertinoDialog(
      barrierDismissible: widget.isDismissible,
      context: context,
      builder: (ctx) {
        return MultiSelectDialog<V>(
          checkColor: widget.checkColor,
          selectedItemsTextStyle: widget.selectedItemsTextStyle,
          searchHintStyle: widget.searchHintStyle,
          searchTextStyle: widget.searchTextStyle,
          itemsTextStyle: widget.itemsTextStyle,
          searchIcon: widget.searchIcon,
          closeSearchIcon: widget.closeSearchIcon,
          unselectedColor: widget.unselectedColor,
          backgroundColor: widget.backgroundColor,
          colorator: widget.colorator,
          searchHint: widget.searchHint,
          selectedColor: widget.selectedColor,
          onSelectionChanged: widget.onSelectionChanged,
          height: widget.dialogHeight,
          width: widget.dialogWidth,
          listType: widget.listType,
          items: widget.items,
          title: widget.title ?? const Text("Select"),
          initialValue: _selectedItems,
          searchable: widget.searchable ?? false,
          confirmText: widget.confirmText,
          cancelText: widget.cancelText,
          separateSelectedItems: widget.separateSelectedItems,
          onConfirm: (selected) {
            _selectedItems = selected;
            if (widget.state != null) {
              widget.state!.didChange(_selectedItems);
            }
            if (widget.onConfirm != null) widget.onConfirm!(_selectedItems);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: <Widget>[
        InkWell(
          onTap: () {
            _showDialog(context);
          },
          child: Container(
            decoration: buildBoxDecoration(),
            padding: const EdgeInsets.all(10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                widget.buttonText ?? const Text("Select"),
                widget.buttonIcon ?? const Icon(CupertinoIcons.chevron_down),
              ],
            ),
          ),
        ),
        _buildInheritedChipDisplay(),
        ...buildErrorRow(),
      ],
    );
  }

  List buildErrorRow() {
    if (widget.state != null && widget.state!.hasError) {
      return List.of([
        const SizedBox(height: 5),
        Row(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Text(
                widget.state!.errorText!,
                style: TextStyle(
                  color: Colors.red[800],
                  fontSize: 12.5,
                ),
              ),
            ),
          ],
        )
      ]);
    } else {
      return List.of([Container()]);
    }
  }

  BoxDecoration buildBoxDecoration() {
    if (widget.decoration != null) {
      return widget.decoration!;
    }
    Color borderColor;
    if (widget.state != null && widget.state!.hasError) {
      borderColor = Colors.red.shade800.withOpacity(0.6);
    } else if (_selectedItems.isNotEmpty) {
      if (widget.selectedColor != null &&
          widget.selectedColor != Colors.transparent) {
        borderColor = widget.selectedColor!;
      } else {
        borderColor = CupertinoTheme.of(context).primaryColor;
      }
    } else {
      borderColor = Colors.black45;
    }

    double borderWidth;
    if (_selectedItems.isNotEmpty) {
      borderWidth = widget.state != null && widget.state!.hasError ? 1.4 : 1.8;
    } else {
      borderWidth = 1.2;
    }
    return BoxDecoration(
      border: Border(
        bottom: BorderSide(
          color: borderColor,
          width: borderWidth,
        ),
      ),
    );
  }
}
