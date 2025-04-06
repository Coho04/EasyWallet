import 'package:easy_wallet/class/translatable_enum.dart';
import 'package:easy_wallet/easy_wallet_app.dart';
import 'package:easy_wallet/enum/payment_methode.dart';
import 'package:easy_wallet/enum/payment_rate.dart';
import 'package:easy_wallet/enum/remember_cycle.dart';
import 'package:easy_wallet/views/components/auto_text.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';

class EasyWalletDropdownField extends StatelessWidget {
  final String label;
  final String currentValue;
  final List options;
  final ValueChanged<String?> onChanged;
  final bool isDarkMode;

  const EasyWalletDropdownField({
    super.key,
    required this.label,
    required this.currentValue,
    required this.options,
    required this.onChanged,
    required this.isDarkMode,
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
          onTap: () => _showOptions(context, options, onChanged),
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
                      text: _capitalize(_translateEnum(currentValue, options)),
                      color: CupertinoColors.inactiveGray),
                  const Icon(
                    CupertinoIcons.chevron_down,
                    size: 20,
                    color: CupertinoColors.inactiveGray,
                  ),
                ],
              ),
            ),
          )),
    );
  }

  Future<void> _showOptions<T>(BuildContext context, List<T> options,
      ValueChanged<String?> onChanged) async {
    await showCupertinoModalPopup<String>(
      context: context,
      builder: (BuildContext context) {
        return CupertinoActionSheet(
          actions: options.map((option) {
            final String value = (option is PaymentRate) ? option.value
                : (option is RememberCycle) ? option.value
                : (option as PaymentMethode).value;
            return CupertinoActionSheetAction(
              child: Text(_capitalize(_translateEnum(value, options)),
                  style: EasyWalletApp.responsiveTextStyle(context,
                      color: CupertinoColors.activeBlue)),
              onPressed: () {
                onChanged(value);
                Navigator.pop(context);
              },
            );
          }).toList(),
          cancelButton: CupertinoActionSheetAction(
            child: Text(Intl.message('cancel'),
                style: EasyWalletApp.responsiveTextStyle(context,
                    color: CupertinoColors.activeBlue)),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        );
      },
    );
  }

  String _translateEnum<T>(String value, List<T> options) {
    final TranslatableEnum match = options
        .whereType<TranslatableEnum>()
        .firstWhere((o) => o.value == value);
    return match.translate() ?? value;
  }

  String _capitalize(String s) {
    if (s.isEmpty) {
      return s;
    }
    return s[0].toUpperCase() + s.substring(1);
  }
}
