import 'package:flutter/material.dart';

class DebugPlaceholder extends StatelessWidget {
  const DebugPlaceholder({
    super.key,
    required this.debugName,
  });

  final String debugName;

  @override
  Widget build(BuildContext context) {
    return Wrap(
        alignment: WrapAlignment.spaceEvenly,
        children: [Text("$debugName TEST")]);
  }
}
