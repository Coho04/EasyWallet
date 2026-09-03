import 'package:easy_wallet/views/components/auto_text.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';

class EasyWalletDatePickerField extends StatelessWidget {
  final String label;

  /// Null renders [placeholder] instead, for optional dates.
  final DateTime? date;
  final String? placeholder;
  final VoidCallback onTap;

  /// When given and a date is set, an button to remove the date is shown.
  final VoidCallback? onClear;
  final bool isDarkMode;

  const EasyWalletDatePickerField({
    super.key,
    required this.isDarkMode,
    required this.label,
    required this.date,
    required this.onTap,
    this.placeholder,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoFormRow(
      prefix: Padding(
        padding: const EdgeInsets.only(right: 16.0),
        child: AutoText(
            text: label,
            color: isDarkMode ? CupertinoColors.white : CupertinoColors.black),
      ),
      child: GestureDetector(
          onTap: onTap,
          child: FittedBox(
            child: Container(
              constraints: const BoxConstraints(
                minWidth: 180,
                maxWidth: double.infinity,
              ),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: isDarkMode
                    ? CupertinoColors.darkBackgroundGray
                    : CupertinoColors.systemGrey6,
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(
                    color: isDarkMode
                        ? CupertinoColors.systemGrey
                        : CupertinoColors.systemGrey4),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  AutoText(
                      text: date == null
                          ? (placeholder ?? '')
                          : DateFormat('dd.MM.yyyy').format(date!),
                      color: CupertinoColors.inactiveGray),
                  if (date != null && onClear != null)
                    GestureDetector(
                      key: const ValueKey('clear-date'),
                      onTap: onClear,
                      child: const Padding(
                        padding: EdgeInsets.only(left: 8, right: 4),
                        child: Icon(
                          CupertinoIcons.clear_circled_solid,
                          size: 18,
                          color: CupertinoColors.inactiveGray,
                        ),
                      ),
                    ),
                  const Icon(
                    CupertinoIcons.calendar,
                    size: 20,
                    color: CupertinoColors.inactiveGray,
                  ),
                ],
              ),
            ),
          )),
    );
  }
}
