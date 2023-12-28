import "package:flutter/material.dart";

import "../../widgets/debug_placeholder.dart";

class UserSettingsScreen extends StatefulWidget {
  const UserSettingsScreen({super.key});

  @override
  State<UserSettingsScreen> createState() => _UserSettingsScreen();
}

// This needs to be a dialog.
class _UserSettingsScreen extends State<UserSettingsScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return const DebugPlaceholder(
      debugName: 'USER_SETTINGS',
    );
  }
}
