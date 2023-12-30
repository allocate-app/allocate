import "package:flutter/material.dart";

import "../../widgets/debug_placeholder.dart";

class TrashScreen extends StatefulWidget {
  const TrashScreen({super.key});

  @override
  State<TrashScreen> createState() => _TrashScreen();
}

// This needs to be a dialog.
class _TrashScreen extends State<TrashScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return const DebugPlaceholder(
      debugName: 'TRASH SCREEN',
    );
  }
}
