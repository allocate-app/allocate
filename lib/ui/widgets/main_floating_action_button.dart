import 'package:allocate/ui/blurred_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_expandable_fab/flutter_expandable_fab.dart';
import 'package:provider/provider.dart';

import '../../providers/model/deadline_provider.dart';
import '../../providers/model/group_provider.dart';
import '../../providers/model/reminder_provider.dart';
import '../../providers/model/routine_provider.dart';
import '../../providers/model/subtask_provider.dart';
import '../../providers/model/todo_provider.dart';
import '../../providers/model/user_provider.dart';
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
    return Stack(
      children: [
        if (Provider.of<UserProvider>(context, listen: false).isConnected.value)
          // This works poorly -> TODO: fix.
          Padding(
            padding: const EdgeInsets.only(
                bottom: Constants.quadPadding * 2 + Constants.doublePadding,
                right: Constants.triplePadding),
            child: Align(
              alignment: Alignment.bottomRight,
              child: FloatingActionButton.small(
                  shape: const CircleBorder(),
                  child: const Tooltip(
                    message: "Sync now",
                    child: Icon(Icons.sync_rounded),
                  ),
                  onPressed: () async {
                    await Future.wait([
                      Provider.of<ToDoProvider>(context, listen: false)
                          .syncRepo(),
                      Provider.of<RoutineProvider>(context, listen: false)
                          .syncRepo(),
                      Provider.of<DeadlineProvider>(context, listen: false)
                          .syncRepo(),
                      Provider.of<ReminderProvider>(context, listen: false)
                          .syncRepo(),
                      Provider.of<GroupProvider>(context, listen: false)
                          .syncRepo(),
                      Provider.of<SubtaskProvider>(context, listen: false)
                          .syncRepo(),
                      Provider.of<UserProvider>(context, listen: false)
                          .syncUser(),
                    ]);
                  }),
            ),
          ),
        ExpandableFab(
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
                    message: "New Reminder",
                    child: Icon(Icons.push_pin_rounded)),
                onPressed: () async {
                  final ExpandableFabState? state = _key.currentState;
                  if (null != state) {
                    state.toggle();
                  }

                  await blurredNonDismissible(
                      context: context, dialog: const CreateReminderScreen());
                }),
          ],
        ),
      ],
    );
  }
}
