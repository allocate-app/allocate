import 'package:flutter/material.dart';

class PaddedDivider extends StatelessWidget {
  const PaddedDivider({
    super.key,
    required this.padding,
  });

  final double padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: padding),
      child: const Divider(),
    );
  }
}
