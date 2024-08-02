import 'package:easy_wallet/model/subscription.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class BadgeComponent extends StatelessWidget {
  final String imageUrl;
  final double size;
  final Subscription subscription;

  const BadgeComponent(
      {super.key,
      required this.imageUrl,
      required this.size,
      required this.subscription});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(
          color: CupertinoColors.black,
          width: 2,
        ),
        boxShadow: const [
          BoxShadow(
            spreadRadius: 4,
            offset: Offset(0, 0),
            blurRadius: 3,
          ),
        ],
      ),
      child: ClipOval(
        child: subscription.buildImage(
            width: size, height: size, boxFit: BoxFit.cover, errorImgSize: 30),
      ),
    );
  }
}
