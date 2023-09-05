import 'package:flutter/material.dart';

import '../../widgets/debug_placeholder.dart';

class GroupScreen extends StatefulWidget {
  const GroupScreen({Key? key}) : super(key: key);

  @override
  State<GroupScreen> createState() => _GroupScreen();
}

class _GroupScreen extends State<GroupScreen> {
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
    return const DebugPlaceholder(debugName: "GROUP_SCREEN");
  }
}
