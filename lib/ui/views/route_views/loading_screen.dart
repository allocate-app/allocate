import 'package:flutter/material.dart';

import '../../widgets/debug_placeholder.dart';

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});

  // This should just play some sort of loading animation while things happen in the background.
  @override
  Widget build(BuildContext context) {
    return const DebugPlaceholder(
      debugName: 'LOADING',
    );
  }
}
