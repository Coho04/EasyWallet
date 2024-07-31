import 'package:easy_wallet/easy_wallet_app.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';

class CardSection extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final bool isDarkMode;

  const CardSection(
      {super.key,
      required this.title,
      required this.children,
      required this.isDarkMode});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: isDarkMode
            ? CupertinoColors.darkBackgroundGray
            : CupertinoColors.systemGrey6,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: isDarkMode
                ? CupertinoColors.black
                : CupertinoColors.systemGrey4,
            blurRadius: 10.0,
            spreadRadius: 1.0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: EasyWalletApp.responsiveTextStyle(
              16,
              context,
              bold: true,
              color: isDarkMode ? CupertinoColors.white : CupertinoColors.black,
            ),
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }
}

class CardDetailRow extends StatelessWidget {
  final String label;
  final dynamic value;
  final bool isDarkMode;
  final bool softBreak;

  const CardDetailRow(
      {super.key,
      required this.label,
      required this.value,
      required this.isDarkMode,
      this.softBreak = false});

  @override
  Widget build(BuildContext context) {
    return CupertinoFormRow(
      prefix: _buildPrefix(context),
      child: _buildValue(context),
    );
  }

  Widget _buildPrefix(BuildContext context) {
    if (softBreak) {
      return Expanded(
        flex: 2,
        child: Text(
          label,
          style: EasyWalletApp.responsiveTextStyle(
            16,
            context,
            bold: true,
            color: CupertinoColors.systemGrey,
          ),
          softWrap: true,
          overflow: TextOverflow.visible,
        ),
      );
    } else {
      return Text(
        label,
        style: EasyWalletApp.responsiveTextStyle(
          16,
          context,
          bold: true,
          color: CupertinoColors.systemGrey,
        ),
        softWrap: true,
        overflow: TextOverflow.visible,
      );
    }
  }

  Widget _buildValue(BuildContext context) {
    if (value is Future<String>) {
      return FutureBuilder<String>(
        future: value,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Text(
              Intl.message('Loading...'),
              style: EasyWalletApp.responsiveTextStyle(
                16,
                context,
                color:
                    isDarkMode ? CupertinoColors.white : CupertinoColors.black,
              ),
            );
          } else if (snapshot.hasError) {
            return Text(
              'Error: ${snapshot.error}',
              style: EasyWalletApp.responsiveTextStyle(
                16,
                context,
                color:
                    isDarkMode ? CupertinoColors.white : CupertinoColors.black,
              ),
            );
          } else if (snapshot.hasData) {
            return Text(
              snapshot.data!,
              style: EasyWalletApp.responsiveTextStyle(
                16,
                context,
                color:
                    isDarkMode ? CupertinoColors.white : CupertinoColors.black,
              ),
            );
          } else {
            return Text(
              Intl.message('No Data'),
              style: EasyWalletApp.responsiveTextStyle(
                16,
                context,
                color:
                    isDarkMode ? CupertinoColors.white : CupertinoColors.black,
              ),
            );
          }
        },
      );
    } else {
      return Text(
        value.toString(),
        style: EasyWalletApp.responsiveTextStyle(
          16,
          context,
          color: isDarkMode ? CupertinoColors.white : CupertinoColors.black,
        ),
      );
    }
  }
}


class CardActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isDarkMode;
  final VoidCallback onPressed;
  final Color? color;

  const CardActionButton(
      {super.key,
        required this.label,
        required this.icon,
        required this.isDarkMode,
        required this.onPressed,
        this.color,
      });

  @override
  Widget build(BuildContext context) {
    return CupertinoFormRow(
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: EasyWalletApp.responsiveTextStyle(16, context,
                  color: color ?? CupertinoColors.systemGrey),
            ),
            Icon(
              icon,
              color: color ??
                  (isDarkMode
                      ? CupertinoColors.systemGrey
                      : CupertinoColors.black),
            ),
          ],
        ),
      ),
    );
  }



}