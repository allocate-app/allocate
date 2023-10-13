import 'package:flutter/material.dart';

class PaddedDivider extends StatelessWidget {
  const PaddedDivider({
    Key? key,
    required this.padding,
  }) : super(key: key);

  final double padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: padding),
      child: const Divider(),
    );
  }
}
