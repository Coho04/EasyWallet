import 'dart:math';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:easy_wallet/easy_wallet_app.dart';
import 'package:flutter/material.dart';


class AutoText extends StatelessWidget {
  final String text;
  final bool bold;
  final Color? color;
  final int maxLines;
  final double minFontSize;
  final double maxFontSize;
  final bool softWrap;
  final TextOverflow overflow;

  const AutoText({
    super.key,
    required this.text,
    this.bold = false,
    this.softWrap = true,
    this.overflow = TextOverflow.ellipsis,
    this.color,
    this.maxLines = 1,
    this.minFontSize = 12,
    this.maxFontSize = 24,
  });

  @override
  Widget build(BuildContext context) {
    return AutoSizeText(
      text,
      maxLines: maxLines,
      // minFontSize: minFontSize,
      // maxFontSize: maxFontSize,
      softWrap: softWrap,
      overflow: overflow,
      textScaleFactor: textScaleFactor(context),
      style: EasyWalletApp.responsiveTextStyle(context, bold: bold, color: color),
    );
  }

  static double textScaleFactor(BuildContext context, {double maxTextScaleFactor = 2}) {
    final width = MediaQuery.of(context).size.width;
    double val = (width / 1400) * maxTextScaleFactor;
    return max(1.1, min(val, maxTextScaleFactor));
  }
}

