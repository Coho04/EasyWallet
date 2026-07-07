import 'package:flutter/cupertino.dart';

class GradientHeader extends StatelessWidget {
  const GradientHeader({
    super.key,
    required this.title,
    this.showBackButton = false,
    this.trailing,
    this.onBack,
  });

  final String title;
  final bool showBackButton;
  final Widget? trailing;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1a1a2e), Color(0xFF16213e), Color(0xFF0f3460)],
        ),
      ),
      padding: EdgeInsets.fromLTRB(8, topPadding + 8, 8, 12),
      child: Row(
        children: [
          SizedBox(
            width: 44,
            child: showBackButton
                ? CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: onBack ?? () => Navigator.pop(context),
                    child: const Icon(
                      CupertinoIcons.back,
                      color: CupertinoColors.white,
                      size: 28,
                    ),
                  )
                : null,
          ),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: CupertinoColors.white,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(
            width: trailing != null ? null : 44,
            child: trailing,
          ),
        ],
      ),
    );
  }
}
