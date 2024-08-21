import 'package:easy_wallet/views/components/auto_text.dart';
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
          AutoText(
            text: title,
            bold: true,
            color: isDarkMode ? CupertinoColors.white : CupertinoColors.black,
          ),
          const SizedBox(height: 10),
          if (subtitle != null)
            AutoText(
              text: subtitle!,
              bold: false,
              color: isDarkMode ? CupertinoColors.white : CupertinoColors.black,
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
  final int maxLines;

  const CardDetailRow(
      {super.key,
      required this.label,
      required this.value,
      this.softBreak = false,
      this.maxLines = 1});

  @override
  Widget build(BuildContext context) {
    return CupertinoFormRow(
      padding: EdgeInsets.zero,
      prefix: _buildPrefix(context),
      child: _buildValue(context),
    );
  }

  Widget _buildPrefix(BuildContext context) {
    final isDarkMode =
        MediaQuery.of(context).platformBrightness == Brightness.dark;
    return Flexible(
        flex: maxLines,
        child: AutoText(
          text: label,
          maxLines: maxLines,
          softWrap: softBreak,
          color: isDarkMode
              ? CupertinoColors.systemGrey2
              : CupertinoColors.systemGrey,
        ));
  }

  Widget _buildValue(BuildContext context) {
    final isDarkMode =
        MediaQuery.of(context).platformBrightness == Brightness.dark;
    if (value is Future<String>) {
      return FutureBuilder<String>(
        future: value,
        builder: (context, snapshot) {
          String text = Intl.message('loading');
          if (snapshot.connectionState == ConnectionState.waiting) {
            text = Intl.message('loading');
          } else if (snapshot.hasError) {
            return AutoText(
              text: 'Error: ${snapshot.error}',
              color: isDarkMode ? CupertinoColors.white : CupertinoColors.black,
            );
          } else if (snapshot.hasData) {
            text = snapshot.data!;
          } else {
            text = Intl.message('noData');
          }
          return AutoText(
            text: text,
            maxLines: maxLines,
            softWrap: softBreak,
            color: isDarkMode ? CupertinoColors.white : CupertinoColors.black,
          );
        },
      );
    } else {
      return  AutoText(
        text: value.toString(),
        maxLines: 2,
        softWrap: softBreak,
        color: isDarkMode ? CupertinoColors.white : CupertinoColors.black,
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
            AutoText(
                text: label,
                color: color ??
                    (isDarkMode
                        ? CupertinoColors.systemGrey4
                        : CupertinoColors.systemGrey)),
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
