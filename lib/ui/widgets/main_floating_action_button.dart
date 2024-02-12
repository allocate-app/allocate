import 'package:allocate/ui/blurred_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_expandable_fab/flutter_expandable_fab.dart';

import '../../util/constants.dart';
import '../views/sub_views/create_deadline.dart';
import '../views/sub_views/create_reminder.dart';
import '../views/sub_views/create_todo.dart';

class MainFloatingActionButton extends StatefulWidget {
  const MainFloatingActionButton({super.key, this.fabKey});

  final GlobalKey<ExpandableFabState>? fabKey;

  @override
  State<MainFloatingActionButton> createState() => _MainFloatingActionButton();
}

class _MainFloatingActionButton extends State<MainFloatingActionButton> {
  late final GlobalKey<ExpandableFabState> _key;

  @override
  void initState() {
    super.initState();
    _key = widget.fabKey ?? GlobalKey<ExpandableFabState>();
  }

  // This
  @override
  Widget build(BuildContext context) {
    return ExpandableFab(
      key: _key,
      overlayStyle: ExpandableFabOverlayStyle(blur: Constants.overlayBlur),
      openButtonBuilder: RotateFloatingActionButtonBuilder(
        fabSize: ExpandableFabSize.regular,
        child: const Icon(Icons.add_rounded),
        shape: const CircleBorder(),
      ),
      closeButtonBuilder: RotateFloatingActionButtonBuilder(
        fabSize: ExpandableFabSize.small,
        child: const Icon(Icons.close_rounded),
        shape: const CircleBorder(),
      ),
      children: [
        FloatingActionButton(
          shape: const CircleBorder(),
          onPressed: () async {
            final ExpandableFabState? state = _key.currentState;
            if (null != state) {
              state.toggle();
            }
            await blurredNonDismissible(
                context: context, dialog: const CreateToDoScreen());
          },
          child: const Tooltip(
              message: "New Task", child: Icon(Icons.task_rounded)),
        ),
        FloatingActionButton(
            shape: const CircleBorder(),
            child: const Tooltip(
                message: "New Deadline",
                child: Icon(Icons.announcement_rounded)),
            onPressed: () async {

              final ExpandableFabState? state = _key.currentState;
              if (null != state) {
                state.toggle();
              }

              await blurredNonDismissible(
                  context: context, dialog: const CreateDeadlineScreen());
            }),
        FloatingActionButton(
            shape: const CircleBorder(),
            child: const Tooltip(
                message: "New Reminder", child: Icon(Icons.push_pin_rounded)),
            onPressed: () async {
              final ExpandableFabState? state = _key.currentState;
              if (null != state) {
                state.toggle();
              }

              await blurredNonDismissible(
                  context: context, dialog: const CreateReminderScreen());
            }),
      ],
    );
  }
}
