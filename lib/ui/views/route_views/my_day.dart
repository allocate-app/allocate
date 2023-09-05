import 'package:flutter/material.dart';

import '../../widgets/debug_placeholder.dart';

class MyDayScreen extends StatefulWidget {
  const MyDayScreen({Key? key}) : super(key: key);

  @override
  State<MyDayScreen> createState() => _MyDayScreen();
}

class _MyDayScreen extends State<MyDayScreen> {
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
    return const DebugPlaceholder(debugName: "MY DAY");
  }
}
