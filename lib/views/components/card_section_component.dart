import 'package:easy_wallet/easy_wallet_app.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CardSection extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final String? subtitle;

  const CardSection({
    super.key,
    required this.title,
    this.subtitle,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode =
        MediaQuery.of(context).platformBrightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: isDarkMode
            ? CupertinoColors.darkBackgroundGray
            : CupertinoColors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: const [
          BoxShadow(
            color: CupertinoColors.systemGrey,
            blurRadius: 5.0,
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
              context,
              bold: true,
              color: isDarkMode ? CupertinoColors.white : CupertinoColors.black,
            ),
          ),
          const SizedBox(height: 10),
          if (subtitle != null)
            Text(
              subtitle!,
              style: EasyWalletApp.responsiveTextStyle(
                context,
                bold: false,
                color:
                    isDarkMode ? CupertinoColors.white : CupertinoColors.black,
              ),
            ),
          if (subtitle != null) const SizedBox(height: 10),
          ...List.generate(children.length, (index) {
            return Column(
              children: [
                if (index > 0) const Divider(),
                children[index],
              ],
            );
          }),
        ],
      ),
    );
  }
}

class CardDetailRow extends StatelessWidget {
  final String label;
  final dynamic value;
  final bool softBreak;

  const CardDetailRow(
      {super.key,
      required this.label,
      required this.value,
      this.softBreak = false});

  @override
  Widget build(BuildContext context) {
    return CupertinoFormRow(
      prefix: _buildPrefix(context),
      child: _buildValue(context),
    );
  }

  Widget _buildPrefix(BuildContext context) {
    final isDarkMode =
        MediaQuery.of(context).platformBrightness == Brightness.dark;
    if (softBreak) {
      return Expanded(
        flex: 2,
        child: Text(
          label,
          style: EasyWalletApp.responsiveTextStyle(
            context,
            color: isDarkMode
                ? CupertinoColors.systemGrey4
                : CupertinoColors.systemGrey,
          ),
          softWrap: true,
          overflow: TextOverflow.visible,
        ),
      );
    } else {
      return Text(
        label,
        style: EasyWalletApp.responsiveTextStyle(
          context,
          color: isDarkMode
              ? CupertinoColors.systemGrey3
              : CupertinoColors.systemGrey,
        ),
        softWrap: true,
        overflow: TextOverflow.visible,
      );
    }
  }

  Widget _buildValue(BuildContext context) {
    final isDarkMode =
        MediaQuery.of(context).platformBrightness == Brightness.dark;
    if (value is Future<String>) {
      return FutureBuilder<String>(
        future: value,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Text(
              Intl.message('loading'),
              style: EasyWalletApp.responsiveTextStyle(
                context,
                color:
                    isDarkMode ? CupertinoColors.white : CupertinoColors.black,
              ),
            );
          } else if (snapshot.hasError) {
            return Text(
              'Error: ${snapshot.error}',
              style: EasyWalletApp.responsiveTextStyle(
                context,
                color:
                    isDarkMode ? CupertinoColors.white : CupertinoColors.black,
              ),
            );
          } else if (snapshot.hasData) {
            return Text(
              snapshot.data!,
              style: EasyWalletApp.responsiveTextStyle(
                context,
                color:
                    isDarkMode ? CupertinoColors.white : CupertinoColors.black,
              ),
            );
          } else {
            return Text(
              Intl.message('noData'),
              style: EasyWalletApp.responsiveTextStyle(
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
  final VoidCallback onPressed;
  final Color? color;

  const CardActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode =
        MediaQuery.of(context).platformBrightness == Brightness.dark;
    return CupertinoFormRow(
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: EasyWalletApp.responsiveTextStyle(context,
                  color: color ??
                      (isDarkMode
                          ? CupertinoColors.systemGrey4
                          : CupertinoColors.systemGrey)),
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
