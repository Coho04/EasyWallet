import 'package:auto_size_text/auto_size_text.dart';
import 'package:easy_wallet/easy_wallet_app.dart';
import 'package:easy_wallet/enum/currency.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';

class AmountField extends StatelessWidget {
  final Currency currency;
  final bool isDarkMode;
  final bool isValid;
  final TextEditingController controller;

  const AmountField({
    super.key,
    required this.currency,
    required this.isDarkMode,
    required this.controller,
    required this.isValid,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: CupertinoTextField(
            controller: controller,
            placeholder: Intl.message('costs'),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: EasyWalletApp.responsiveTextStyle(
              context,
              color: isDarkMode ? CupertinoColors.white : CupertinoColors.black,
            ),
            decoration: BoxDecoration(
              color: isDarkMode
                  ? CupertinoColors.darkBackgroundGray
                  : CupertinoColors.systemGrey6,
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(
                color: isValid
                    ? (isDarkMode
                        ? CupertinoColors.systemGrey
                        : CupertinoColors.systemGrey4)
                    : CupertinoColors.destructiveRed,
              ),
            ),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          ),
        ),
        const SizedBox(width: 8),
        AutoSizeText(
          maxLines: 1,
          currency.symbol,
          style: EasyWalletApp.responsiveTextStyle(
            context,
            color: isDarkMode ? CupertinoColors.white : CupertinoColors.black,
          ),
        ),
      ],
    );
  }
}
