import 'package:flutter/material.dart';

class DebugPlaceholder extends StatelessWidget {
  const DebugPlaceholder({
    Key? key,
    required this.debugName,
  }) : super(key: key);

  final String debugName;

  @override
  Widget build(BuildContext context) {
    return Wrap(
        alignment: WrapAlignment.spaceEvenly,
        children: [Text("$debugName TEST")]);
  }
}
