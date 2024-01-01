import 'package:flutter/material.dart';

class PaddedDivider extends StatelessWidget {
  const PaddedDivider({
    super.key,
    required this.padding,
    this.color,
  });

  final double padding;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: padding),
      child: Divider(
        color: color ?? Theme.of(context).colorScheme.outlineVariant,
      ),
    );
  }
}
