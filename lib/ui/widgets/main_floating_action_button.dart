import 'package:flutter/material.dart';
import 'package:flutter_expandable_fab/flutter_expandable_fab.dart';
import 'package:provider/provider.dart';

import '../../providers/application/event_provider.dart';
import '../../providers/model/deadline_provider.dart';
import '../../providers/model/group_provider.dart';
import '../../providers/model/reminder_provider.dart';
import '../../providers/model/routine_provider.dart';
import '../../providers/model/subtask_provider.dart';
import '../../providers/model/todo_provider.dart';
import '../../providers/model/user_provider.dart';
import '../../util/constants.dart';
import '../blurred_dialog.dart';
import '../views/sub_views/create_deadline.dart';
import '../views/sub_views/create_reminder.dart';
import '../views/sub_views/create_todo.dart';

class MainFloatingActionButton extends StatefulWidget {
  const MainFloatingActionButton({
    super.key,
    this.fabKey,
  });

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
    return ValueListenableBuilder(
        valueListenable:
            Provider.of<UserProvider>(context, listen: false).isConnected,
        builder: (BuildContext context, bool isConnected, Widget? child) {
          return ExpandableFab(
            key: _key,
            fanAngle: (isConnected) ? 110 : 90,
            overlayStyle:
                const ExpandableFabOverlayStyle(blur: Constants.overlayBlur),
            openButtonBuilder: RotateFloatingActionButtonBuilder(
              heroTag: UniqueKey(),
              fabSize: ExpandableFabSize.regular,
              child: const Icon(Icons.add_rounded),
              shape: const CircleBorder(),
            ),
            closeButtonBuilder: RotateFloatingActionButtonBuilder(
              heroTag: UniqueKey(),
              fabSize: ExpandableFabSize.small,
              child: const Icon(Icons.close_rounded),
              shape: const CircleBorder(),
            ),
            children: [
              FloatingActionButton(
                heroTag: UniqueKey(),
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
                  heroTag: UniqueKey(),
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
                  heroTag: UniqueKey(),
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
              if (isConnected)
                FloatingActionButton(
                    heroTag: UniqueKey(),
                    shape: const CircleBorder(),
                    child: const Tooltip(
                      message: "Refresh now",
                      child: Icon(Icons.sync_rounded),
                    ),
                    onPressed: () async {
                      final ExpandableFabState? state = _key.currentState;
                      final EventProvider ep =
                          Provider.of<EventProvider>(context, listen: false);
                      if (null != state) {
                        state.toggle();
                      }

                      _resetProviderRefresh();

                      await Future.wait([
                        Provider.of<ToDoProvider>(context, listen: false)
                            .refreshRepo(),
                        Provider.of<RoutineProvider>(context, listen: false)
                            .refreshRepo(),
                        Provider.of<DeadlineProvider>(context, listen: false)
                            .refreshRepo(),
                        Provider.of<ReminderProvider>(context, listen: false)
                            .refreshRepo(),
                        Provider.of<GroupProvider>(context, listen: false)
                            .refreshRepo(),
                        Provider.of<SubtaskProvider>(context, listen: false)
                            .refreshRepo(),
                        Provider.of<UserProvider>(context, listen: false)
                            .syncUser(),
                      ]);

                      await Future.delayed(const Duration(seconds: 1));

                      await ep.resetCalendar();
                    })
            ],
          );
        });
  }

  void _resetProviderRefresh() {
    // For preempting refresh state. Current implementation has potential for deadlock.
    Provider.of<ToDoProvider>(context, listen: false).forceRefreshState();
    Provider.of<RoutineProvider>(context, listen: false).forceRefreshState();
    Provider.of<DeadlineProvider>(context, listen: false).forceRefreshState();
    Provider.of<ReminderProvider>(context, listen: false).forceRefreshState();
    Provider.of<GroupProvider>(context, listen: false).forceRefreshState();
    Provider.of<SubtaskProvider>(context, listen: false).forceRefreshState();
    Provider.of<UserProvider>(context, listen: false).forceRefreshState();
  }
}
