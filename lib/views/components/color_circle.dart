import 'dart:ui';

import 'package:flutter/cupertino.dart';

class ColorCircle extends StatelessWidget {
  final Color color;
  final double size;

  const ColorCircle({
    super.key,
    required this.color,
    this.size = 30.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.systemGrey.withOpacity(0.5),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
    );
  }
}