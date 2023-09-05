import 'package:flutter/material.dart';

import '../../widgets/debug_placeholder.dart';

class CompletedListScreen extends StatefulWidget {
  const CompletedListScreen({Key? key}) : super(key: key);

  @override
  State<CompletedListScreen> createState() => _CompletedListScreen();
}

class _CompletedListScreen extends State<CompletedListScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const DebugPlaceholder(debugName: "COMPLETED_SCREEN");
  }
}
