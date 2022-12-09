import 'package:flutter/material.dart';

class CustomBorders extends StatelessWidget {
  final image, top, left, bottom, right;
  CustomBorders(
      {@required this.image, this.top, this.left, this.right, this.bottom});

  @override
  Widget build(BuildContext context) {
    return Positioned(
        top: top?.toDouble(),
        left: left?.toDouble(),
        right: right?.toDouble(),
        bottom: bottom?.toDouble(),
        child: Image.asset("assets/images/${image.toString()}",color: Colors.white,height: 20,));
  }
}
