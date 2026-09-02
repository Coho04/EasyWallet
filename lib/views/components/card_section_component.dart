import 'package:easy_wallet/views/components/auto_text.dart';
import 'package:intl/intl.dart';
import 'package:flutter/cupertino.dart';

/// A grouped card with a section header, styled like [StatCard] so the
/// settings, subscription and category views all read the same: a small
/// uppercase caption over a rounded card on the grouped background.
class CardSection extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final String? subtitle;
  final double itemPadding;

  const CardSection({
    super.key,
    required this.title,
    this.subtitle,
    required this.children,
    this.itemPadding = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        // System colours instead of a manual dark-mode branch, so the card
        // follows the platform in both appearances.
        color: CupertinoColors.secondarySystemGroupedBackground
            .resolveFrom(context),
        borderRadius: BorderRadius.circular(14.0),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
            ),
          ),
          Container(
            margin: const EdgeInsets.only(top: 8, bottom: 4),
            height: 0.5,
            color: CupertinoColors.separator.resolveFrom(context),
          ),
          if (subtitle != null) ...[
            AutoText(
              text: subtitle!,
              bold: false,
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
            ),
            const SizedBox(height: 10),
          ],
          ...List.generate(children.length, (index) {
            return Column(
              children: [
                if (index > 0)
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    height: 0.5,
                    color: CupertinoColors.separator.resolveFrom(context),
                  ),
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
