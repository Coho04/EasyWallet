import 'package:easy_wallet/views/components/auto_text.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';

class EasyWalletDatePickerField extends StatelessWidget {
  final String label;
  final DateTime date;
  final VoidCallback onTap;
  final bool isDarkMode;

  const EasyWalletDatePickerField({
    super.key,
    required this.isDarkMode,
    required this.label,
    required this.date,
    required this.onTap,
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
                      text: DateFormat('dd.MM.yyyy').format(date),
                      color: CupertinoColors.inactiveGray),
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
