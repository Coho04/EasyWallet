import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_wallet/model/subscription_icon.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Draws the icon of a subscription: the one the user chose, otherwise the
/// favicon of its website.
///
/// Every place that shows a subscription icon goes through here, including
/// the form previews and the home screen widget, so a chosen icon cannot show
/// up in one view and be missing in the next.
class SubscriptionIconView extends StatelessWidget {
  const SubscriptionIconView({
    super.key,
    this.icon,
    this.url,
    this.width = 40,
    this.height = 40,
    this.fit = BoxFit.cover,
    this.errorImgSize = 40,
    this.borderRadius = 8.0,
    this.fallback,
  });

  final SubscriptionIcon? icon;
  final String? url;
  final double width;
  final double height;
  final BoxFit fit;
  final double errorImgSize;
  final double borderRadius;

  /// Shown when there is neither a chosen icon nor a URL. Without it a missing
  /// URL is a warning and an empty one a wallet, as the lists always had it.
  final IconData? fallback;

  @override
  Widget build(BuildContext context) {
    final chosen = icon;
    if (chosen != null && chosen.isRenderable) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: SizedBox(
          width: width,
          height: height,
          child: _buildChosen(chosen),
        ),
      );
    }

    final address = url;
    if (address == null || address.isEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Icon(
          fallback ??
              (address == null
                  ? CupertinoIcons.exclamationmark_triangle
                  : Icons.account_balance_wallet_rounded),
          color: CupertinoColors.systemGrey,
          size: errorImgSize,
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: CachedNetworkImage(
        imageUrl: faviconUrlFor(address),
        placeholder: (context, url) => const CupertinoActivityIndicator(),
        errorWidget: (context, url, error) => const Icon(
          CupertinoIcons.exclamationmark_triangle,
          color: CupertinoColors.systemGrey,
          size: 40,
        ),
        fit: fit,
        width: width,
        height: height,
      ),
    );
  }

  Widget _buildChosen(SubscriptionIcon chosen) {
    final side = math.min(width, height);
    switch (chosen.kind!) {
      case IconKind.symbol:
        final background = chosen.symbolColor;
        // The glyph has to stay readable on whatever colour was picked.
        final glyph =
            ThemeData.estimateBrightnessForColor(background) == Brightness.dark
            ? CupertinoColors.white
            : CupertinoColors.black;
        return ColoredBox(
          color: background,
          child: Center(
            child: Icon(chosen.symbol, color: glyph, size: side * 0.62),
          ),
        );
      case IconKind.emoji:
        return Center(
          child: Text(
            chosen.value,
            textAlign: TextAlign.center,
            textDirection: TextDirection.ltr,
            style: TextStyle(
              fontSize: side * 0.72,
              height: 1,
              decoration: TextDecoration.none,
            ),
          ),
        );
      case IconKind.image:
        return Image.memory(
          chosen.imageBytes!,
          fit: fit,
          width: width,
          height: height,
          gaplessPlayback: true,
          errorBuilder: (context, error, stack) => Icon(
            CupertinoIcons.exclamationmark_triangle,
            color: CupertinoColors.systemGrey,
            size: errorImgSize,
          ),
        );
    }
  }
}
