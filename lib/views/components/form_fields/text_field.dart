import 'package:easy_wallet/easy_wallet_app.dart';
import 'package:flutter/cupertino.dart';

class EasyWalletTextField extends StatelessWidget {
  final TextEditingController controller;
  final String placeholder;
  final TextInputType keyboardType;
  final bool autocorrect;
  final ValueChanged<String>? onChanged;
  final int maxLines;
  final bool isDarkMode;
  final bool isValid;

  const EasyWalletTextField({
    super.key,
    required this.controller,
    required this.placeholder,
    required this.isDarkMode,
    this.keyboardType = TextInputType.text,
    this.autocorrect = false,
    this.onChanged,
    this.maxLines = 1,
    this.isValid = true,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoTextField(
      controller: controller,
      placeholder: placeholder,
      keyboardType: keyboardType,
      autocorrect: autocorrect,
      onChanged: onChanged,
            style: EasyWalletApp.responsiveTextStyle(
        context,
        color: isDarkMode ? CupertinoColors.white : CupertinoColors.black,
      ),
      decoration: BoxDecoration(
        color: isDarkMode
            ? CupertinoColors.darkBackgroundGray
            : isValid
            ? CupertinoColors.systemGrey6
            : CupertinoColors.systemRed.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(
          color: isValid
              ? (isDarkMode
              ? CupertinoColors.systemGrey
              : CupertinoColors.systemGrey4)
              : CupertinoColors.systemRed,
          width: 1.0,
        ),
      ),
      maxLines: maxLines,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
    );
  }
}
