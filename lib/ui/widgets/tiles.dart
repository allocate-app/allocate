import 'package:allocate/ui/widgets/handle_repeatable_modal.dart';
import 'package:allocate/ui/widgets/paginating_listview.dart';
import 'package:allocate/ui/widgets/subtask_quick_entry.dart';
import 'package:allocate/ui/widgets/subtitles.dart';
import 'package:another_flushbar/flushbar.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:auto_size_text_field/auto_size_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:intl/intl.dart';
import 'package:jiffy/jiffy.dart';
import 'package:provider/provider.dart';

import '../../model/calendar_event.dart';
import '../../model/task/deadline.dart';
import '../../model/task/group.dart';
import '../../model/task/reminder.dart';
import '../../model/task/routine.dart';
import '../../model/task/subtask.dart';
import '../../model/task/todo.dart';
import '../../providers/deadline_provider.dart';
import '../../providers/group_provider.dart';
import '../../providers/reminder_provider.dart';
import '../../providers/routine_provider.dart';
import '../../providers/subtask_provider.dart';
import '../../providers/todo_provider.dart';
import '../../providers/user_provider.dart';
import '../../ui/widgets/time_dialog.dart';
import '../../util/constants.dart';
import '../../util/enums.dart';
import '../../util/exceptions.dart';
import '../../util/numbers.dart';
import '../views/sub_views/create_todo.dart';
import '../views/sub_views/update_deadline.dart';
import '../views/sub_views/update_group.dart';
import '../views/sub_views/update_reminder.dart';
import '../views/sub_views/update_routine.dart';
import '../views/sub_views/update_todo.dart';
import 'check_delete_dialog.dart';
import 'date_range_dialog.dart';
import 'date_time_dialog.dart';
import 'drain_bar.dart';
import 'duration_dialog.dart';
import 'energy_modal.dart';
import 'expanded_listtile.dart';
import 'flushbars.dart';
import 'frequency_dialog.dart';
import 'leading_widgets.dart';
import 'listviews.dart';
import 'search_recents_bar.dart';

class Tiles {
  /// ListView Tiles
  // TODO: fix these once subtasks are implemented.
  static Widget toDoListTile(
      {required BuildContext context,
      required int index,
      required ToDo toDo,
      bool smallScreen = false,
      Future<void> Function({required ToDo toDo, required int index})?
          checkboxAnimateBeforeUpdate,
      bool showHandle = false,
      bool checkDelete = false}) {
    UserProvider userProvider = Provider.of(context, listen: false);
    ToDoProvider toDoProvider = Provider.of(context, listen: false);
    return ListTile(
        tileColor: (toDo.myDay)
            ? Theme.of(context)
                .colorScheme
                .primaryContainer
                .withOpacity(Constants.myDayOpacity)
            : null,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: Constants.padding),
        key: ValueKey(toDo.id),
        shape: const RoundedRectangleBorder(
            borderRadius:
                BorderRadius.all(Radius.circular(Constants.roundedCorners))),
        leading: LeadingWidgets.toDoCheckbox(
            outerPadding:
                const EdgeInsets.symmetric(horizontal: Constants.halfPadding),
            scale: 1.1,
            completed: toDo.completed,
            onChanged: (bool? value) async {
              toDo.completed = value!;

              if (null != checkboxAnimateBeforeUpdate) {
                await checkboxAnimateBeforeUpdate(toDo: toDo, index: index);
              }

              await toDoProvider.updateToDo(toDo: toDo);
            }),
        title: AutoSizeText(toDo.name,
            overflow: TextOverflow.ellipsis,
            minFontSize: Constants.large,
            softWrap: false,
            maxLines: 2),
        subtitle: Subtitles.toDoSubtitle(
            smallScreen: smallScreen,
            context: context,
            id: toDo.groupID,
            dueDate: toDo.dueDate,
            priority: toDo.priority,
            onError: () async {
              toDo.groupID = null;
              await toDoProvider.updateToDo(toDo: toDo);
            }),
        onTap: () async {
          await showDialog(
              barrierDismissible: false,
              useRootNavigator: false,
              context: context,
              builder: (BuildContext context) =>
                  UpdateToDoScreen(initialToDo: toDo));
        },
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          Row(mainAxisSize: MainAxisSize.min, children: [
            Constants.batteryIcons[(toDo.taskType == TaskType.small)
                ? toDo.weight
                : clamp(
                        x: remap(
                            x: toDo.weight,
                            inMin: 0,
                            inMax: Constants.maxWeight,
                            outMin: 0,
                            outMax: 5),
                        ll: 0,
                        ul: 5)
                    .toInt()]!,
            AutoSizeText(
              "${toDo.weight}",
              overflow: TextOverflow.visible,
              minFontSize: Constants.medium,
              softWrap: false,
              maxLines: 1,
            ),
          ]),
          Padding(
              padding: EdgeInsets.zero,
              child: IconButton(
                icon: const Icon(Icons.delete_forever_rounded),
                onPressed: () async {
                  if (!checkDelete) {
                    return await deleteToDo(toDo: toDo, context: context);
                  }
                  return await showDialog<List<bool>?>(
                      barrierDismissible: true,
                      context: context,
                      builder: (BuildContext context) {
                        return CheckDeleteDialog(
                            dontAsk: !checkDelete, type: "Task");
                        // Dialog function.
                      }).then((results) async {
                    if (null == results) {
                      return;
                    }
                    userProvider.curUser?.checkDelete = results[1];
                    if (!results[0]) {
                      return;
                    }
                    await deleteToDo(
                        toDo: toDo,
                        context: context,
                        toDoProvider: toDoProvider);
                  });
                },
              )),
          (showHandle)
              ? ReorderableDragStartListener(
                  index: index, child: const Icon(Icons.drag_handle_rounded))
              : const SizedBox.shrink(),
        ]));
  }

  // Helper function to delete ToDos ->
  static Future<void> deleteToDo(
      {required ToDo toDo,
      required BuildContext context,
      ToDoProvider? toDoProvider}) async {
    toDoProvider =
        toDoProvider ?? Provider.of<ToDoProvider>(context, listen: false);
    // For repeating ToDos.
    if (toDo.frequency != Frequency.once) {
      await showModalBottomSheet<bool?>(
          showDragHandle: true,
          context: context,
          builder: (BuildContext context) {
            return const HandleRepeatableModal(action: "Delete");
          }).then((deleteSingle) async {
        if (null == deleteSingle) {
          return;
        }

        // If delete all.
        if (!deleteSingle) {
          return await toDoProvider!.deleteFutures(toDo: toDo).catchError((e) {
            Flushbar? error;

            error = Flushbars.createError(
              message: e.cause,
              context: context,
              dismissCallback: () => error?.dismiss(),
            );

            error.show(context);
          }, test: (e) => e is FailureToDeleteException);
        }

        // If delete one.
        await toDoProvider!.nextRepeat(toDo: toDo).catchError((e) {
          Flushbar? error;

          error = Flushbars.createError(
            message: e.cause,
            context: context,
            dismissCallback: () => error?.dismiss(),
          );

          error.show(context);
        },
            test: (e) =>
                e is FailureToCreateException || e is FailureToUploadException);
      });
    }

    return await toDoProvider.deleteToDo(toDo: toDo).catchError((e) {
      Flushbar? error;

      error = Flushbars.createError(
        message: e.cause,
        context: context,
        dismissCallback: () => error?.dismiss(),
      );

      error.show(context);
    }, test: (e) => e is FailureToDeleteException);
  }

  static Widget toDoMyDayTile({
    required BuildContext context,
    required int index,
    required ToDo toDo,
    bool smallScreen = false,
    Future<void> Function({required ToDo toDo, required int index})?
        checkboxAnimateBeforeUpdate,
    bool showHandle = false,
  }) {
    ToDoProvider toDoProvider = Provider.of(context, listen: false);
    return ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: Constants.padding),
        key: ValueKey(toDo.id ^ index),
        shape: const RoundedRectangleBorder(
            borderRadius:
                BorderRadius.all(Radius.circular(Constants.roundedCorners))),
        leading: LeadingWidgets.toDoCheckbox(
            outerPadding:
                const EdgeInsets.symmetric(horizontal: Constants.halfPadding),
            scale: 1.1,
            completed: toDo.completed,
            onChanged: (bool? value) async {
              toDo.completed = value!;

              if (null != checkboxAnimateBeforeUpdate) {
                await checkboxAnimateBeforeUpdate(toDo: toDo, index: index);
              }

              await toDoProvider.updateToDo(toDo: toDo);
            }),
        title: AutoSizeText(toDo.name,
            overflow: TextOverflow.ellipsis,
            minFontSize: Constants.large,
            softWrap: false,
            maxLines: 2),
        subtitle: Subtitles.toDoSubtitle(
            smallScreen: smallScreen,
            context: context,
            id: toDo.groupID,
            dueDate: toDo.dueDate,
            priority: toDo.priority,
            onError: () async {
              toDo.groupID = null;
              await toDoProvider.updateToDo(toDo: toDo);
            }),
        onTap: () async {
          await showDialog(
              barrierDismissible: false,
              useRootNavigator: false,
              context: context,
              builder: (BuildContext context) =>
                  UpdateToDoScreen(initialToDo: toDo));
        },
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          Row(mainAxisSize: MainAxisSize.min, children: [
            Constants.batteryIcons[(toDo.taskType == TaskType.small)
                ? toDo.weight
                : clamp(
                        x: remap(
                            x: toDo.weight,
                            inMin: 0,
                            inMax: Constants.maxWeight,
                            outMin: 0,
                            outMax: 5),
                        ll: 0,
                        ul: 5)
                    .toInt()]!,
            AutoSizeText(
              "${toDo.weight}",
              overflow: TextOverflow.visible,
              minFontSize: Constants.medium,
              softWrap: false,
              maxLines: 1,
            ),
          ]),
          Padding(
              padding: EdgeInsets.zero,
              child: IconButton(
                icon: const Icon(Icons.cloud_off_rounded),
                onPressed: () async {
                  toDo.myDay = false;
                  await toDoProvider.updateToDo(toDo: toDo);
                },
              )),
          (showHandle)
              ? ReorderableDragStartListener(
                  index: index, child: const Icon(Icons.drag_handle_rounded))
              : const SizedBox.shrink(),
        ]));
  }

  static Widget routineListTile(
      {required BuildContext context,
      required int index,
      required Routine routine,
      bool showHandle = false,
      bool checkDelete = false}) {
    RoutineProvider routineProvider =
        Provider.of<RoutineProvider>(context, listen: false);
    UserProvider userProvider =
        Provider.of<UserProvider>(context, listen: false);
    return ListTile(
        contentPadding: const EdgeInsets.only(right: Constants.padding),
        key: ValueKey(routine.id),
        shape: const RoundedRectangleBorder(
            borderRadius:
                BorderRadius.all(Radius.circular(Constants.roundedCorners))),
        leading: LeadingWidgets.routineIcon(
            currentContext: context,
            scale: 1,
            times: routineProvider.getRoutineTime(routine: routine),
            handleRoutineTimeChange: ({required int newRoutineTimes}) {
              routineProvider.setDailyRoutine(
                  timeOfDay: newRoutineTimes, routine: routine);
            }),
        title: AutoSizeText(routine.name,
            overflow: TextOverflow.ellipsis,
            minFontSize: Constants.large,
            softWrap: false,
            maxLines: 2),
        subtitle: Subtitles.subtaskSubtitle(
            subtaskCount: routineProvider.getSubtaskCount(id: routine.id)),
        onTap: () async {
          await showDialog(
              barrierDismissible: false,
              useRootNavigator: false,
              context: context,
              builder: (BuildContext context) =>
                  UpdateRoutineScreen(initialRoutine: routine));
        },
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          Row(mainAxisSize: MainAxisSize.min, children: [
            Constants.batteryIcons[remap(
                    x: routine.weight,
                    inMin: 0,
                    inMax: Constants.maxWeight,
                    outMin: 0,
                    outMax: 5)
                .toInt()]!,
            AutoSizeText(
              "${routine.weight}",
              overflow: TextOverflow.visible,
              minFontSize: Constants.large,
              softWrap: false,
              maxLines: 1,
            ),
          ]),
          Padding(
              padding: EdgeInsets.zero,
              child: IconButton(
                icon: const Icon(Icons.delete_forever_rounded),
                onPressed: () async {
                  if (!checkDelete) {
                    return await routineProvider
                        .deleteRoutine(routine: routine)
                        .catchError((e) {
                      Flushbar? error;

                      error = Flushbars.createError(
                        message: e.cause,
                        context: context,
                        dismissCallback: () => error?.dismiss(),
                      );

                      error.show(context);
                    }, test: (e) => e is FailureToDeleteException);
                  }
                  return await showDialog<List<bool>?>(
                      barrierDismissible: true,
                      context: context,
                      builder: (BuildContext context) {
                        return CheckDeleteDialog(
                            dontAsk: !checkDelete, type: "Routine");
                        // Dialog function.
                      }).then((results) async {
                    if (null == results) {
                      return;
                    }
                    userProvider.curUser?.checkDelete = results[1];
                    if (!results[0]) {
                      return;
                    }
                    await routineProvider
                        .deleteRoutine(routine: routine)
                        .catchError((e) {
                      Flushbar? error;

                      error = Flushbars.createError(
                        message: e.cause,
                        context: context,
                        dismissCallback: () => error?.dismiss(),
                      );

                      error.show(context);
                    }, test: (e) => e is FailureToDeleteException);
                  });
                },
              )),
          (showHandle)
              ? ReorderableDragStartListener(
                  index: index, child: const Icon(Icons.drag_handle_rounded))
              : const SizedBox.shrink(),
        ]));
  }

  static Widget deadlineListTile(
      {required BuildContext context,
      required int index,
      required Deadline deadline,
      bool smallScreen = false,
      bool showHandle = false,
      bool checkDelete = false}) {
    DeadlineProvider deadlineProvider =
        Provider.of<DeadlineProvider>(context, listen: false);
    UserProvider userProvider = Provider.of(context, listen: false);
    return ListTile(
        contentPadding:
            // Check the padding.
            const EdgeInsets.symmetric(horizontal: Constants.padding),
        key: ValueKey(deadline.id),
        shape: const RoundedRectangleBorder(
            borderRadius:
                BorderRadius.all(Radius.circular(Constants.roundedCorners))),
        leading: (deadline.warnMe)
            ? LeadingWidgets.deadlineWarnMeIcon(
                currentContext: context,
                outerPadding: const EdgeInsets.symmetric(
                    horizontal: Constants.halfPadding),
                iconPadding: const EdgeInsets.all(Constants.halfPadding))
            : LeadingWidgets.deadlineIcon(
                currentContext: context,
                outerPadding: const EdgeInsets.symmetric(
                    horizontal: Constants.halfPadding),
                iconPadding: const EdgeInsets.all(Constants.halfPadding)),
        title: AutoSizeText(deadline.name,
            overflow: TextOverflow.ellipsis,
            minFontSize: Constants.large,
            softWrap: false,
            maxLines: 2),
        subtitle: Subtitles.deadlineSubtitle(
          context: context,
          smallScreen: smallScreen,
          dueDate: deadline.dueDate,
          warnDate: (deadline.warnMe) ? deadline.warnDate : null,
          priority: deadline.priority,
        ),
        onTap: () async {
          await showDialog(
              barrierDismissible: false,
              useRootNavigator: false,
              context: context,
              builder: (BuildContext context) =>
                  UpdateDeadlineScreen(initialDeadline: deadline));
        },
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          Padding(
              padding: EdgeInsets.zero,
              child: IconButton(
                icon: const Icon(Icons.delete_forever_rounded),
                onPressed: () async {
                  if (!checkDelete) {
                    return await deleteDeadline(
                        deadline: deadline, context: context);
                  }
                  return await showDialog<List<bool>?>(
                      barrierDismissible: true,
                      context: context,
                      builder: (BuildContext context) {
                        return CheckDeleteDialog(
                            dontAsk: !checkDelete, type: "Deadline");
                        // Dialog function.
                      }).then((results) async {
                    if (null == results) {
                      return;
                    }
                    userProvider.curUser?.checkDelete = results[1];
                    if (!results[0]) {
                      return;
                    }
                    await deleteDeadline(
                        deadline: deadline,
                        context: context,
                        deadlineProvider: deadlineProvider);
                  });
                },
              )),
          (showHandle)
              ? ReorderableDragStartListener(
                  index: index, child: const Icon(Icons.drag_handle_rounded))
              : const SizedBox.shrink(),
        ]));
  }

  // Helper function to delete deadlines ->
  static Future<void> deleteDeadline({
    required Deadline deadline,
    required BuildContext context,
    DeadlineProvider? deadlineProvider,
  }) async {
    deadlineProvider = deadlineProvider ??
        Provider.of<DeadlineProvider>(context, listen: false);
    // For repeating deadlines.
    if (deadline.frequency != Frequency.once) {
      await showModalBottomSheet<bool?>(
          showDragHandle: true,
          context: context,
          builder: (BuildContext context) {
            return const HandleRepeatableModal(action: "Delete");
          }).then((deleteSingle) async {
        if (null == deleteSingle) {
          return;
        }

        // If delete all.
        if (!deleteSingle) {
          return await deadlineProvider!
              .deleteAndCancelFutures(deadline: deadline)
              .catchError((e) {
            Flushbar? error;

            error = Flushbars.createError(
              message: e.cause,
              context: context,
              dismissCallback: () => error?.dismiss(),
            );

            error.show(context);
          }, test: (e) => e is FailureToDeleteException);
        }

        // If delete one.
        await deadlineProvider!.nextRepeat(deadline: deadline).catchError((e) {
          Flushbar? error;

          error = Flushbars.createError(
            message: e.cause,
            context: context,
            dismissCallback: () => error?.dismiss(),
          );

          error.show(context);
        },
            test: (e) =>
                e is FailureToCreateException || e is FailureToUploadException);
      });
    }

    return await deadlineProvider.deleteDeadline(deadline: deadline).catchError(
        (e) {
      Flushbar? error;

      error = Flushbars.createError(
        message: e.cause,
        context: context,
        dismissCallback: () => error?.dismiss(),
      );

      error.show(context);
    }, test: (e) => e is FailureToDeleteException);
  }

  static Widget reminderListTile(
      {required BuildContext context,
      required int index,
      required Reminder reminder,
      bool smallScreen = false,
      bool showHandle = false,
      bool checkDelete = false}) {
    ReminderProvider reminderProvider =
        Provider.of<ReminderProvider>(context, listen: false);
    UserProvider userProvider = Provider.of(context, listen: false);
    return ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: Constants.padding),
        key: ValueKey(reminder.id),
        shape: const RoundedRectangleBorder(
            borderRadius:
                BorderRadius.all(Radius.circular(Constants.roundedCorners))),
        leading: (Frequency.once != reminder.frequency)
            ? LeadingWidgets.reminderRepeatingIcon(
                currentContext: context,
                outerPadding: const EdgeInsets.symmetric(
                    horizontal: Constants.halfPadding),
                iconPadding: const EdgeInsets.all(Constants.halfPadding))
            : LeadingWidgets.reminderIcon(
                currentContext: context,
                outerPadding: const EdgeInsets.symmetric(
                    horizontal: Constants.halfPadding),
                iconPadding: const EdgeInsets.all(Constants.halfPadding)),
        title: AutoSizeText(reminder.name,
            overflow: TextOverflow.ellipsis,
            minFontSize: Constants.large,
            softWrap: false,
            maxLines: 2),
        subtitle: Subtitles.reminderSubtitle(
          smallScreen: smallScreen,
          context: context,
          dueDate: reminder.dueDate,
        ),
        onTap: () async {
          await showDialog(
              barrierDismissible: false,
              useRootNavigator: false,
              context: context,
              builder: (BuildContext context) =>
                  UpdateReminderScreen(initialReminder: reminder));
        },
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          Padding(
              padding: EdgeInsets.zero,
              child: IconButton(
                icon: const Icon(Icons.delete_forever_rounded),
                onPressed: () async {
                  if (!checkDelete) {
                    return await deleteReminder(
                        reminder: reminder,
                        context: context,
                        reminderProvider: reminderProvider);
                  }
                  return await showDialog<List<bool>?>(
                      barrierDismissible: true,
                      context: context,
                      builder: (BuildContext context) {
                        return CheckDeleteDialog(
                            dontAsk: !checkDelete, type: "Reminder");
                        // Dialog function.
                      }).then((results) async {
                    if (null == results) {
                      return;
                    }
                    userProvider.curUser?.checkDelete = results[1];
                    if (!results[0]) {
                      return;
                    }
                    await deleteReminder(reminder: reminder, context: context);
                  });
                },
              )),
          (showHandle)
              ? ReorderableDragStartListener(
                  index: index, child: const Icon(Icons.drag_handle_rounded))
              : const SizedBox.shrink(),
        ]));
  }

  // Helper function to delete deadlines ->
  static Future<void> deleteReminder(
      {required Reminder reminder,
      required BuildContext context,
      ReminderProvider? reminderProvider}) async {
    reminderProvider = reminderProvider ??
        Provider.of<ReminderProvider>(context, listen: false);
    // For repeating deadlines.
    if (reminder.frequency != Frequency.once) {
      await showModalBottomSheet<bool?>(
          showDragHandle: true,
          context: context,
          builder: (BuildContext context) {
            return const HandleRepeatableModal(action: "Delete");
          }).then((deleteSingle) async {
        if (null == deleteSingle) {
          return;
        }

        // If delete all.
        if (!deleteSingle) {
          return await reminderProvider!
              .deleteAndCancelFutures(reminder: reminder)
              .catchError((e) {
            Flushbar? error;

            error = Flushbars.createError(
              message: e.cause,
              context: context,
              dismissCallback: () => error?.dismiss(),
            );

            error.show(context);
          }, test: (e) => e is FailureToDeleteException);
        }

        // If delete one.
        await reminderProvider!.nextRepeat(reminder: reminder).catchError((e) {
          Flushbar? error;

          error = Flushbars.createError(
            message: e.cause,
            context: context,
            dismissCallback: () => error?.dismiss(),
          );

          error.show(context);
        },
            test: (e) =>
                e is FailureToCreateException || e is FailureToUploadException);
      });
    }

    return await reminderProvider.deleteReminder(reminder: reminder).catchError(
        (e) {
      Flushbar? error;

      error = Flushbars.createError(
        message: e.cause,
        context: context,
        dismissCallback: () => error?.dismiss(),
      );

      error.show(context);
    }, test: (e) => e is FailureToDeleteException);
  }

  static Widget groupListTile(
      {required int index,
      required Group group,
      required BuildContext context,
      bool showHandle = false,
      bool checkDelete = false,
      ScrollPhysics physics = const NeverScrollableScrollPhysics()}) {
    GroupProvider groupProvider =
        Provider.of<GroupProvider>(context, listen: false);
    ToDoProvider toDoProvider =
        Provider.of<ToDoProvider>(context, listen: false);
    UserProvider userProvider =
        Provider.of<UserProvider>(context, listen: false);

    return ExpandedListTile(
        key: ValueKey(group.id),
        expanded: true,
        leading: LeadingWidgets.groupListViewIcon(onPressed: () async {
          await showDialog(
              barrierDismissible: false,
              useRootNavigator: false,
              context: context,
              builder: (BuildContext context) {
                return UpdateGroupScreen(initialGroup: group);
              });
        }),
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          Padding(
              padding: EdgeInsets.zero,
              child: IconButton(
                icon: const Icon(Icons.delete_forever_rounded),
                onPressed: () async {
                  if (!checkDelete) {
                    return await groupProvider.deleteGroup(group: group);
                  }
                  return await showDialog<List<bool>?>(
                      barrierDismissible: true,
                      context: context,
                      builder: (BuildContext context) {
                        return CheckDeleteDialog(
                            dontAsk: !checkDelete, type: "Group");
                        // Dialog function.
                      }).then((results) async {
                    if (null == results) {
                      return;
                    }
                    userProvider.curUser?.checkDelete = results[1];
                    if (!results[0]) {
                      return;
                    }
                    await groupProvider.deleteGroup(group: group);
                  });
                },
              )),
          (showHandle)
              ? ReorderableDragStartListener(
                  index: index, child: const Icon(Icons.drag_handle_rounded))
              : const SizedBox.shrink(),
        ]),
        title: AutoSizeText(
          group.name,
          maxLines: 1,
          overflow: TextOverflow.visible,
          softWrap: false,
          minFontSize: Constants.large,
        ),
        subtitle: Subtitles.groupSubtitle(
            toDoCount: groupProvider.getToDoCount(id: group.id)),
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Expanded(
                child: SearchRecentsBar<ToDo>(
                  border: BorderSide.none,
                  clearOnSelection: true,
                  hintText: "Search Tasks",
                  padding: const EdgeInsets.all(Constants.padding),
                  handleDataSelection: ({required int id}) async {
                    await groupToDoDataSelection(
                        toDoID: id,
                        groupID: group.id,
                        context: context,
                        toDoProvider: toDoProvider);
                  },
                  handleHistorySelection: ({required int id}) async {
                    await groupToDoDataSelection(
                        toDoID: id,
                        groupID: group.id,
                        context: context,
                        toDoProvider: toDoProvider);
                  },
                  searchController: SearchController(),
                  mostRecent: toDoProvider.mostRecent,
                  search: toDoProvider.searchToDos,
                ),
              ),
            ],
          ),
          PaginatingListview<ToDo>(
            items: group.toDos,
            query: (
                    {int limit = Constants.minLimitPerQuery,
                    int offset = 0}) async =>
                await groupProvider.getToDosByGroupID(
                    id: group.id, limit: limit, offset: offset),
            offset: group.toDos.length,
            paginateButton: true,
            pullToRefresh: false,
            rebuildNotifiers: [toDoProvider],
            rebuildCallback: ({required List<ToDo> items}) {
              groupProvider.setToDoCount(id: group.id);
            },
            listviewBuilder: (
                {required BuildContext context, required List<ToDo> items}) {
              return ListViews.reorderableGroupToDos(
                  context: context,
                  toDos: items,
                  physics: physics,
                  onChanged: ({required int index, bool value = false}) async {
                    items[index].completed = value;
                    await toDoProvider.updateToDo(toDo: items[index]);
                  },
                  onTap: ({required int index}) async {
                    await showDialog(
                        barrierDismissible: false,
                        useRootNavigator: false,
                        context: context,
                        builder: (BuildContext context) => UpdateToDoScreen(
                              initialToDo: items[index],
                              initialGroup:
                                  MapEntry<String, int>(group.name, group.id),
                            )).catchError((e) {
                      Flushbar? error;

                      error = Flushbars.createError(
                        message: e.cause,
                        context: context,
                        dismissCallback: () => error?.dismiss(),
                      );

                      error.show(context);
                    },
                        test: (e) =>
                            e is FailureToCreateException ||
                            e is FailureToUploadException);
                  },
                  handleRemove: ({required int index}) async {
                    items[index].groupID = null;
                    await toDoProvider.updateToDo(toDo: items[index]);
                  });
            },
          ),
          addTile(
              title: "Add Task",
              onTap: () async {
                await showDialog(
                    barrierDismissible: false,
                    useRootNavigator: false,
                    context: context,
                    builder: (BuildContext context) => CreateToDoScreen(
                          initialGroup:
                              MapEntry<String, int>(group.name, group.id),
                        )).catchError((e) {
                  Flushbar? error;

                  error = Flushbars.createError(
                    message: e.cause,
                    context: context,
                    dismissCallback: () => error?.dismiss(),
                  );

                  error.show(context);
                },
                    test: (e) =>
                        e is FailureToCreateException ||
                        e is FailureToUploadException);
              })
        ]);
  }

  // Helper method for groupListTile.
  static Future<void> groupToDoDataSelection(
      {required int toDoID,
      required int groupID,
      required BuildContext context,
      ToDoProvider? toDoProvider}) async {
    toDoProvider =
        toDoProvider ?? Provider.of<ToDoProvider>(context, listen: false);
    ToDo? toDo = await toDoProvider.getToDoByID(id: toDoID).catchError((_) {
      Flushbar? error;

      error = Flushbars.createError(
        message: "Error with Task Retrieval",
        context: context,
        dismissCallback: () => error?.dismiss(),
      );

      error.show(context);
      return null;
    });
    if (null != toDo) {
      toDo.groupID = groupID;
      await toDoProvider.updateToDo(toDo: toDo);
    }
  }

  // TODO: Refactor this -> should bring up a dialog instead, text is causing issues.
  // and the modal is gross.
  // Right now, using a focus node to check when focus is lost to update.
  static Widget subtaskCheckboxTile(
          {required BuildContext context,
          EdgeInsetsGeometry textFieldPadding = EdgeInsets.zero,
          required int index,
          required Subtask subtask,
          required Future<void> Function({required Subtask subtask})
              updateSubtask,
          required Future<void> Function({required Subtask subtask}) onRemoved,
          bool showHandle = false}) =>
      checkboxListTile(
          key: ValueKey(index),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: Constants.padding),
          onChanged: (bool? value) {
            subtask.completed = value!;
            updateSubtask(subtask: subtask);
          },
          title: Padding(
            padding: textFieldPadding,
            child: Focus(
              onFocusChange: (bool hasFocus) async {
                if (!hasFocus) {
                  await updateSubtask(subtask: subtask);
                }
              },
              child: AutoSizeTextField(
                  // TODO: get rid of this widget entirely. NEEDS to be its own statefulwidget.
                  controller: TextEditingController(text: subtask.name),
                  minLines: 1,
                  maxLines: 1,
                  minFontSize: Constants.large,
                  decoration: const InputDecoration.collapsed(
                    hintText: "Step name",
                  ),
                  onEditingComplete: () async {
                    await updateSubtask(subtask: subtask);
                  },
                  onChanged: (value) {
                    SemanticsService.announce(
                        value, Directionality.of(context));
                    subtask.name = value;
                  }),
            ),
          ),
          value: subtask.completed,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                visualDensity: VisualDensity.adaptivePlatformDensity,
                icon: Constants.batteryIcons[subtask.weight]!,
                selectedIcon: Constants.selectedBatteryIcons[subtask.weight]!,
                onPressed: () async {
                  await showModalBottomSheet<int?>(
                      useSafeArea: true,
                      showDragHandle: true,
                      context: context,
                      builder: (BuildContext context) {
                        return EnergyModal(initialWeight: subtask.weight);
                      }).then((newWeight) async {
                    subtask.weight = newWeight ?? subtask.weight;
                    await updateSubtask(subtask: subtask);
                  });
                },
              ),
              IconButton(
                  visualDensity: VisualDensity.adaptivePlatformDensity,
                  icon: const Icon(Icons.remove_circle_outline_rounded),
                  onPressed: () => onRemoved(subtask: subtask)),
              (showHandle)
                  ? ReorderableDragStartListener(
                      index: index,
                      child: const Icon(Icons.drag_handle_rounded))
                  : const SizedBox.shrink(),
            ],
          ));

  /// Checkboxes
  static Widget checkboxListTile({
    Key? key,
    EdgeInsetsGeometry contentPadding = EdgeInsets.zero,
    Widget? title,
    required void Function(bool? value) onChanged,
    bool value = false,
    Widget? trailing,
  }) =>
      ListTile(
          leading: LeadingWidgets.toDoCheckbox(
            completed: value,
            onChanged: onChanged,
          ),
          contentPadding: contentPadding,
          key: key,
          shape: const RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.all(Radius.circular(Constants.roundedCorners))),
          title: title,
          trailing: trailing);

  static Widget toDoCheckTile({
    required int index,
    required ToDo toDo,
    bool showHandle = false,
    required Future<void> Function({required int index, bool value}) onChanged,
    required Future<void> Function({required int index}) onTap,
    required void Function({required int index}) handleRemove,
  }) {
    return ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: Constants.innerPadding),
        key: ValueKey(toDo.id),
        shape: const RoundedRectangleBorder(
            borderRadius:
                BorderRadius.all(Radius.circular(Constants.roundedCorners))),
        leading: LeadingWidgets.toDoCheckbox(
            completed: toDo.completed,
            onChanged: (bool? value) => onChanged(index: index, value: value!)),
        title: AutoSizeText(toDo.name,
            overflow: TextOverflow.ellipsis,
            minFontSize: Constants.large,
            softWrap: false,
            maxLines: 2),
        onTap: () async => await onTap(index: index),
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          Row(mainAxisSize: MainAxisSize.min, children: [
            Constants.batteryIcons[(toDo.taskType == TaskType.small)
                ? toDo.weight
                : remap(
                        x: toDo.weight,
                        inMin: 0,
                        inMax: Constants.maxWeight,
                        outMin: 0,
                        outMax: 5)
                    .toInt()]!,
            AutoSizeText(
              "${toDo.weight}",
              overflow: TextOverflow.visible,
              minFontSize: Constants.large,
              softWrap: false,
              maxLines: 1,
            ),
          ]),
          Padding(
              padding: EdgeInsets.zero,
              child: IconButton(
                icon: const Icon(Icons.remove_circle_outline_rounded),
                onPressed: () => handleRemove(index: index),
              )),
          (showHandle)
              ? ReorderableDragStartListener(
                  index: index, child: const Icon(Icons.drag_handle_rounded))
              : const SizedBox.shrink(),
        ]));
  }

  // SUBTASK EXPANSION TILES
  // TODO: refactor subtasks into their own provider class.
  // issue with single-listener -> code should be shared
  static Widget subtasksTile({
    required BuildContext context,
    required int id,
    bool isDense = false,
    int limit = Constants.maxNumTasks,
    required List<Subtask> subtasks,
    required ValueNotifier<int> subtaskCount,
    ScrollPhysics physics = const NeverScrollableScrollPhysics(),
    EdgeInsetsGeometry outerPadding = EdgeInsets.zero,
  }) {
    SubtaskProvider subtaskProvider =
        Provider.of<SubtaskProvider>(context, listen: false);
    return ExpandedListTile(
        outerPadding: outerPadding,
        title: const AutoSizeText("Steps",
            maxLines: 1,
            overflow: TextOverflow.visible,
            softWrap: false,
            minFontSize: Constants.small),
        subtitle: Subtitles.subtaskSubtitle(subtaskCount: subtaskCount),
        children: [
          ListViews.reorderableSubtasks(
              showHandle: subtasks.length > 1,
              physics: physics,
              context: context,
              subtasks: subtasks,
              itemCount: subtasks.length,
              updateSubtask: ({required Subtask subtask}) async {
                await subtaskProvider
                    .updateSubtask(subtask: subtask)
                    .catchError((e) {
                  Flushbar? error;
                  error = Flushbars.createError(
                      message: e.cause,
                      context: context,
                      dismissCallback: () => error?.dismiss());
                },
                        test: (e) =>
                            e is FailureToUpdateException ||
                            e is FailureToUploadException);
              },
              onRemoved: ({required Subtask subtask}) async {
                await subtaskProvider
                    .deleteSubtask(subtask: subtask)
                    .catchError((e) {
                  Flushbar? error;
                  error = Flushbars.createError(
                      message: e.cause,
                      context: context,
                      dismissCallback: () => error?.dismiss());
                }, test: (e) => e is FailureToDeleteException);
              },
              onReorder: (int oldIndex, int newIndex) async {
                await subtaskProvider
                    .reorderSubtasks(
                        subtasks: subtasks,
                        oldIndex: oldIndex,
                        newIndex: newIndex)
                    .catchError((e) {
                  Flushbar? error;
                  error = Flushbars.createError(
                      message: e.cause,
                      context: context,
                      dismissCallback: () => error?.dismiss());
                  return List<Subtask>.empty(growable: false);
                },
                        test: (e) =>
                            e is FailureToUpdateException ||
                            e is FailureToUploadException);
              }),
          (subtasks.length < limit)
              ? SubtaskQuickEntry(
                  taskID: id,
                  taskIndex: subtasks.length,
                  outerPadding: const EdgeInsets.all(Constants.padding),
                  innerPadding: const EdgeInsets.symmetric(
                      horizontal: Constants.innerPadding),
                  hintText: "Add step",
                )

              // addTile(
              //         title: "Add a step",
              //         onTap: () async {
              //           await subtaskProvider
              //               .createSubtask(taskID: id, index: subtasks.length)
              //               .catchError((e) {
              //             Flushbar? error;
              //             error = Flushbars.createError(
              //                 message: e.cause,
              //                 context: context,
              //                 dismissCallback: () => error?.dismiss());
              //           },
              //                   test: (e) =>
              //                       e is FailureToCreateException ||
              //                       e is FailureToUploadException);
              //         })
              : const SizedBox.shrink()
        ]);
  }

  // MYDAY ROUTINE EXPANSION TILES

  static Widget emptyRoutineTile({
    required BuildContext context,
    int times = 0,
  }) {
    RoutineProvider routineProvider =
        Provider.of<RoutineProvider>(context, listen: false);

    String type = switch (times) {
      1 => "Morning",
      2 => "Afternoon",
      4 => "Evening",
      _ => "",
    };

    // TODO: onpressed should create a new routine.
    // OR -> Use a decorated box?
    // Also: add an add tile.
    return ExpandedListTile(
      leading: LeadingWidgets.myDayRoutineIcon(times: times, onPressed: () {}),
      title: Padding(
        padding: const EdgeInsets.symmetric(vertical: Constants.padding),
        child: AutoSizeText("$type Routine",
            maxLines: 1,
            overflow: TextOverflow.visible,
            softWrap: false,
            minFontSize: Constants.large),
      ),
      children: [
        SearchRecentsBar<Routine>(
          border: BorderSide.none,
          handleDataSelection: ({required int id}) async {
            Routine? routine = await routineProvider.getRoutineByID(id: id);
            if (null == routine) {
              return;
            }
            routineProvider.setDailyRoutine(timeOfDay: times, routine: routine);
          },
          handleHistorySelection: ({required int id}) async {
            Routine? routine = await routineProvider.getRoutineByID(id: id);
            if (null == routine) {
              return;
            }
            routineProvider.setDailyRoutine(timeOfDay: times, routine: routine);
          },
          mostRecent: routineProvider.mostRecent,
          search: routineProvider.searchRoutines,
          hintText: "Search Routines",
        ),
        // TODO: add tile -> Create routine with initial time set.
      ],
    );
  }

  // This doesn't really differ much from the subtasks tile.
  // TODO: try to make one widget
  static Widget filledRoutineTile({
    required BuildContext context,
    required Routine routine,
    ScrollPhysics physics = const NeverScrollableScrollPhysics(),
    int times = 0,
  }) {
    RoutineProvider routineProvider =
        Provider.of<RoutineProvider>(context, listen: false);
    SubtaskProvider subtaskProvider =
        Provider.of<SubtaskProvider>(context, listen: false);
    return ExpandedListTile(
        leading: LeadingWidgets.myDayRoutineIcon(
          times: times,
          routine: routine,
          onPressed: () async {
            await showDialog(
              barrierDismissible: false,
              useRootNavigator: false,
              context: context,
              builder: (BuildContext context) => UpdateRoutineScreen(
                initialRoutine: routine,
              ),
            );
          },
        ),
        title: AutoSizeText(routine.name,
            maxLines: 1,
            overflow: TextOverflow.visible,
            softWrap: false,
            minFontSize: Constants.large),
        subtitle: Subtitles.subtaskSubtitle(
            subtaskCount: routineProvider.getSubtaskCount(id: routine.id)),
        trailing: IconButton(
          icon: const Icon(Icons.remove_circle_outline),
          onPressed: () => routineProvider.unsetDailyRoutine(id: routine.id),
        ),
        children: [
          ListViews.reorderableSubtasks(
            context: context,
            physics: physics,
            itemCount: routine.subtasks.length,
            subtasks: routine.subtasks,
            updateSubtask: ({required Subtask subtask}) async {
              await subtaskProvider.updateSubtask(subtask: subtask).catchError(
                  (e) {
                Flushbar? error;
                error = Flushbars.createError(
                    message: e.cause,
                    context: context,
                    dismissCallback: () => error?.dismiss());
              },
                  test: (e) =>
                      e is FailureToUpdateException ||
                      e is FailureToUploadException);
            },
            onRemoved: ({required Subtask subtask}) async {
              await subtaskProvider.deleteSubtask(subtask: subtask).catchError(
                  (e) {
                Flushbar? error;
                error = Flushbars.createError(
                    message: e.cause,
                    context: context,
                    dismissCallback: () => error?.dismiss());
              }, test: (e) => e is FailureToDeleteException);
            },
            onReorder: (int oldIndex, int newIndex) async {
              await subtaskProvider
                  .reorderSubtasks(
                      subtasks: routine.subtasks,
                      oldIndex: oldIndex,
                      newIndex: newIndex)
                  .catchError((e) {
                Flushbar? error;
                error = Flushbars.createError(
                    message: e.cause,
                    context: context,
                    dismissCallback: () => error?.dismiss());
                return List<Subtask>.empty(growable: false);
              },
                      test: (e) =>
                          e is FailureToUpdateException ||
                          e is FailureToUploadException);
            },
            showHandle: routine.subtasks.length > 1,
          ),
          (routine.subtasks.length < Constants.maxNumTasks)
              ? addTile(
                  onTap: () async {
                    await subtaskProvider
                        .createSubtask(
                            taskID: routine.id, index: routine.subtasks.length)
                        .catchError((e) {
                      Flushbar? error;
                      error = Flushbars.createError(
                          message: e.cause,
                          context: context,
                          dismissCallback: () => error?.dismiss());
                    },
                            test: (e) =>
                                e is FailureToCreateException ||
                                e is FailureToUploadException);
                  },
                  title: "Add a step",
                )
              : const SizedBox.shrink(),
        ]);
  }

  /// Model Parameter Tiles
  // NAME
  static Widget nameTile({
    required BuildContext context,
    EdgeInsetsGeometry outerPadding = EdgeInsets.zero,
    EdgeInsetsGeometry textFieldPadding = EdgeInsets.zero,
    Widget? leading,
    String? hintText = "",
    String? errorText = "",
    TextEditingController? controller,
    required void Function() handleClear,
  }) =>
      Padding(
        padding: outerPadding,
        child: Row(
          children: [
            leading ?? const SizedBox.shrink(),
            Expanded(
              child: Padding(
                padding: textFieldPadding,
                child: AutoSizeTextField(
                  maxLines: 1,
                  minFontSize: Constants.huge,
                  decoration: InputDecoration(
                    suffixIcon: (controller?.text.isNotEmpty ?? false)
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded),
                            onPressed: handleClear)
                        : null,
                    contentPadding:
                        const EdgeInsets.all(Constants.innerPadding),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: const BorderRadius.all(
                            Radius.circular(Constants.roundedCorners)),
                        borderSide: BorderSide(
                          width: 2,
                          color: Theme.of(context).colorScheme.outlineVariant,
                          strokeAlign: BorderSide.strokeAlignOutside,
                        )),
                    border: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(
                            Radius.circular(Constants.roundedCorners)),
                        borderSide: BorderSide(
                          strokeAlign: BorderSide.strokeAlignOutside,
                        )),
                    hintText: hintText,
                    errorText: errorText,
                  ),
                  controller: controller,
                ),
              ),
            ),
          ],
        ),
      );

  // WEIGHT
  static Widget weightTile({
    EdgeInsetsGeometry outerPadding = EdgeInsets.zero,
    EdgeInsetsGeometry batteryPadding = EdgeInsets.zero,
    required double weight,
    required double max,
    Widget? slider,
    BoxConstraints constraints = const BoxConstraints(),
  }) =>
      Column(children: [
        Padding(
          padding: outerPadding,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Flexible(
                child: AutoSizeText("Energy Drain: ",
                    minFontSize: Constants.medium,
                    maxLines: 1,
                    softWrap: true,
                    style: Constants.hugeHeaderStyle),
              ),
              Flexible(
                child: Padding(
                  padding: batteryPadding,
                  child: DrainBar(
                    weight: weight,
                    max: max,
                    constraints: constraints,
                  ),
                ),
              ),
            ],
          ),
        ),
        slider ?? const SizedBox.shrink(),
      ]);

  // WEIGHT SLIDERS
  static Widget weightSlider(
          {required double weight,
          void Function(double? value)? handleWeightChange,
          void Function(double? value)? onChangeEnd}) =>
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          const Icon(Icons.battery_full),
          Expanded(
            child: Slider(
              value: weight,
              max: Constants.maxTaskWeight.toDouble(),
              label:
                  "$weight ${(weight > (Constants.maxTaskWeight / 2).floor()) ? Constants.lowBattery : Constants.fullBattery}",
              divisions: Constants.maxTaskWeight,
              onChanged: handleWeightChange,
              onChangeEnd: onChangeEnd,
            ),
          ),
          const Icon(Icons.battery_1_bar),
        ],
      );

  // TODO: on focus, number key might be a good shortcut?
  static Widget weightAnchor(
      {required double weight,
      void Function(double? value)? handleWeightChange}) {
    MenuController controller = MenuController();
    return MenuAnchor(
        style: const MenuStyle(
            alignment: AlignmentDirectional(-10, 1.1),
            shape: MaterialStatePropertyAll(RoundedRectangleBorder(
                borderRadius: BorderRadius.all(
                    Radius.circular(Constants.roundedCorners))))),
        anchorTapClosesMenu: true,
        controller: controller,
        menuChildren: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Constants.padding),
            child: weightSlider(
                weight: weight,
                handleWeightChange: handleWeightChange,
                onChangeEnd: (value) => controller.close()),
          )
        ],
        builder:
            (BuildContext context, MenuController controller, Widget? child) {
          return IconButton(
              icon: Constants.batteryIcons[weight.toInt()]!,
              onPressed: () {
                if (controller.isOpen) {
                  controller.close();
                } else {
                  controller.open();
                }
              });
        });
  }

  // DESCRIPTION
  static Widget descriptionTile(
          {TextEditingController? controller,
          EdgeInsetsGeometry outerPadding = EdgeInsets.zero,
          String hintText = "Description",
          int? maxLines = Constants.mobileMaxLinesBeforeScroll,
          int minLines = Constants.mobileMinLines,
          double? minFontSize,
          bool isDense = false,
          required BuildContext context}) =>
      Padding(
        padding: outerPadding,
        child: AutoSizeTextField(
            controller: controller,
            maxLines: maxLines,
            minLines: minLines,
            minFontSize: minFontSize ?? Constants.large,
            decoration: InputDecoration(
              isDense: isDense,
              contentPadding: const EdgeInsets.all(Constants.innerPadding),
              hintText: hintText,
              enabledBorder: OutlineInputBorder(
                  borderRadius: const BorderRadius.all(
                      Radius.circular(Constants.roundedCorners)),
                  borderSide: BorderSide(
                    width: 2,
                    color: Theme.of(context).colorScheme.outlineVariant,
                    strokeAlign: BorderSide.strokeAlignOutside,
                  )),
              border: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(
                      Radius.circular(Constants.roundedCorners)),
                  borderSide: BorderSide(
                    strokeAlign: BorderSide.strokeAlignOutside,
                  )),
            )),
      );

  // DURATION
  static Widget durationTile(
      {int expectedDuration = 0,
      int realDuration = 0,
      required BuildContext context,
      EdgeInsetsGeometry outerPadding = EdgeInsets.zero,
      required void Function() handleClear,
      required void Function(int? value) handleUpdate}) {
    return Padding(
      padding: outerPadding,
      child: ListTile(
        contentPadding: const EdgeInsets.only(left: Constants.innerPadding),
        leading: const Icon(Icons.timer_outlined),
        shape: const RoundedRectangleBorder(
            borderRadius:
                BorderRadius.all(Radius.circular(Constants.roundedCorners))),
        title: (expectedDuration > 0)
            ? Row(
                children: [
                  Flexible(
                    child: Tooltip(
                      message: "Expected",
                      child: AutoSizeText(
                          Duration(seconds: expectedDuration)
                              .toString()
                              .split(".")
                              .first,
                          overflow: TextOverflow.visible,
                          minFontSize: Constants.large,
                          maxLines: 1,
                          softWrap: false),
                    ),
                  ),
                  const Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: Constants.padding),
                    child: Icon(
                      Icons.timer_rounded,
                    ),
                  ),
                  Flexible(
                    child: Tooltip(
                      message: "Projected",
                      child: AutoSizeText(
                          Duration(seconds: realDuration)
                              .toString()
                              .split(".")
                              .first,
                          overflow: TextOverflow.visible,
                          minFontSize: Constants.large,
                          maxLines: 1,
                          softWrap: true),
                    ),
                  ),
                ],
              )
            : const AutoSizeText("Expected Duration: ",
                overflow: TextOverflow.visible,
                minFontSize: Constants.small,
                maxLines: 2,
                softWrap: true),
        trailing: (expectedDuration > 0)
            ? IconButton(
                icon: const Icon(Icons.clear_rounded), onPressed: handleClear)
            : const SizedBox.shrink(),
        onTap: () async => await showDialog<int>(
            context: context,
            builder: (BuildContext context) =>
                DurationDialog(duration: expectedDuration)).then(handleUpdate),
      ),
    );
  }

  // START-DUE DATES
  static Widget dateRangeTile({
    EdgeInsetsGeometry outerPadding = EdgeInsets.zero,
    required BuildContext context,
    DateTime? startDate,
    DateTime? dueDate,
    required void Function() handleClear,
    required void Function(
            {bool? checkClose, DateTime? newStart, DateTime? newDue})
        handleUpdate,
  }) =>
      Padding(
        padding: outerPadding,
        child: ListTile(
          contentPadding: const EdgeInsets.only(left: Constants.innerPadding),
          leading: const Icon(Icons.today_rounded),
          shape: const RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.all(Radius.circular(Constants.roundedCorners))),
          title: (null == startDate && null == dueDate)
              ? const AutoSizeText(
                  "Add Dates",
                  softWrap: true,
                  overflow: TextOverflow.visible,
                  maxLines: 2,
                  minFontSize: Constants.small,
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    (null == startDate)
                        ? const Flexible(
                            child: AutoSizeText(
                              "Start?",
                              softWrap: true,
                              overflow: TextOverflow.visible,
                              maxLines: 2,
                              minFontSize: Constants.small,
                            ),
                          )
                        : Flexible(
                            child: Tooltip(
                            message: "Start Date",
                            child: AutoSizeText(
                                Jiffy.parseFromDateTime(startDate)
                                    .toLocal()
                                    .format(
                                      pattern: "MMM d",
                                    ),
                                softWrap: false,
                                overflow: TextOverflow.visible,
                                maxLines: 1,
                                minFontSize: Constants.huge),
                          )),
                    (null == dueDate)
                        ? const Flexible(
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: Constants.padding),
                              child: Icon(Icons.today_rounded),
                            ),
                          )
                        : const Flexible(
                            child: Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: Constants.padding),
                            child: Icon(Icons.event_rounded),
                          )),
                    (null == dueDate)
                        ? const Flexible(
                            child: AutoSizeText(
                              "Due?",
                              softWrap: true,
                              overflow: TextOverflow.visible,
                              maxLines: 2,
                              minFontSize: Constants.small,
                            ),
                          )
                        : Flexible(
                            child: Tooltip(
                              message: "Due Date",
                              child: AutoSizeText(
                                  Jiffy.parseFromDateTime(dueDate)
                                      .toLocal()
                                      .format(pattern: "MMM d"),
                                  softWrap: false,
                                  overflow: TextOverflow.visible,
                                  maxLines: 1,
                                  minFontSize: Constants.huge),
                            ),
                          )
                  ],
                ),
          trailing: (startDate != null || dueDate != null)
              ? IconButton(
                  icon: const Icon(Icons.clear), onPressed: handleClear)
              : null,
          onTap: () async {
            await showDialog<List<DateTime?>?>(
                context: context,
                builder: (BuildContext context) {
                  return DateRangeDialog(
                      startDate: startDate, dueDate: dueDate);
                }).then((newDates) {
              if (null == newDates) {
                return handleUpdate(newStart: startDate, newDue: dueDate);
              }
              return handleUpdate(
                  newStart: newDates[0], newDue: newDates[1], checkClose: true);
            });
          },
        ),
      );

  // TIME
  static Widget timeTile({
    TimeOfDay? startTime,
    TimeOfDay? dueTime,
    EdgeInsetsGeometry outerPadding = EdgeInsets.zero,
    required BuildContext context,
    required void Function() handleClear,
    required void Function(
            {bool checkClose, TimeOfDay? newStart, TimeOfDay? newDue})
        handleUpdate,
  }) =>
      Padding(
        padding: outerPadding,
        child: ListTile(
            contentPadding: const EdgeInsets.only(left: Constants.innerPadding),
            leading: const Icon(Icons.schedule_rounded),
            shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(
                    Radius.circular(Constants.roundedCorners))),
            title: (null == startTime && null == dueTime)
                ? const AutoSizeText(
                    "Add Times",
                    overflow: TextOverflow.visible,
                    minFontSize: Constants.small,
                    maxLines: 2,
                    softWrap: true,
                  )
                : Row(children: [
                    (null == startTime)
                        ? const Flexible(
                            child: AutoSizeText(
                            "Start?",
                            softWrap: false,
                            overflow: TextOverflow.visible,
                            maxLines: 1,
                            minFontSize: Constants.large,
                          ))
                        : Flexible(
                            child: AutoSizeText(
                            startTime.format(context).toString(),
                            softWrap: false,
                            overflow: TextOverflow.visible,
                            maxLines: 1,
                            minFontSize: Constants.large,
                          )),
                    (null == dueTime)
                        ? const Flexible(
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: Constants.padding),
                              child: Icon(Icons.history_toggle_off_rounded),
                            ),
                          )
                        : const Flexible(
                            child: Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: Constants.padding),
                            child: Icon(Icons.schedule_rounded),
                          )),
                    (null == dueTime)
                        ? const Flexible(
                            child: AutoSizeText(
                              "Due?",
                              softWrap: false,
                              overflow: TextOverflow.visible,
                              maxLines: 1,
                              minFontSize: Constants.large,
                            ),
                          )
                        : Flexible(
                            child: AutoSizeText(
                              dueTime.format(context).toString(),
                              softWrap: false,
                              overflow: TextOverflow.visible,
                              maxLines: 1,
                              minFontSize: Constants.large,
                            ),
                          ),
                  ]),
            onTap: () async {
              await showDialog<List<TimeOfDay?>?>(
                  context: context,
                  builder: (BuildContext context) {
                    return TimeDialog(startTime: startTime, dueTime: dueTime);
                  }).then((newTimes) {
                if (null == newTimes) {
                  return handleUpdate(newStart: startTime, newDue: dueTime);
                }
                return handleUpdate(
                    newStart: newTimes[0],
                    newDue: newTimes[1],
                    checkClose: true);
              });
            },
            trailing: (startTime != null || dueTime != null)
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: handleClear,
                  )
                : null),
      );

  // SINGLE DATETIME TILE
  static Widget singleDateTimeTile({
    EdgeInsetsGeometry outerPadding = EdgeInsets.zero,
    required BuildContext context,
    Widget? leading,
    DateTime? date,
    TimeOfDay? time,
    bool useAlertIcon = false,
    bool showDate = false,
    String unsetDateText = "",
    String unsetTimeText = "",
    String dialogHeader = "",
    required void Function() handleClear,
    required void Function(
            {bool? checkClose, DateTime? newDate, TimeOfDay? newTime})
        handleUpdate,
  }) =>
      Padding(
        padding: outerPadding,
        child: ListTile(
            contentPadding: const EdgeInsets.only(left: Constants.innerPadding),
            shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(
                    Radius.circular(Constants.roundedCorners))),
            leading: (useAlertIcon)
                ? LeadingWidgets.alertIconButton(
                    warn: showDate,
                    onTap: () async {
                      await showDialog<Map<String, dynamic>?>(
                          context: context,
                          builder: (BuildContext context) {
                            return DateTimeDialog(
                              header: dialogHeader,
                              date: date,
                              time: time,
                            );
                          }).then((newDateTime) {
                        if (null == newDateTime) {
                          return handleUpdate(newDate: date, newTime: time);
                        }
                        return handleUpdate(
                            newDate: newDateTime["date"],
                            newTime: newDateTime["time"],
                            checkClose: true);
                      });
                    })
                : leading,
            title: (showDate && null != date)
                ? Row(children: [
                    Flexible(
                      child: AutoSizeText(
                        Jiffy.parseFromDateTime(date).format(pattern: "MMM d"),
                        softWrap: false,
                        overflow: TextOverflow.visible,
                        maxLines: 1,
                        minFontSize: Constants.huge,
                      ),
                    ),
                    (null != time)
                        ? const Flexible(
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: Constants.padding),
                              child: Icon(Icons.schedule_outlined),
                            ),
                          )
                        : const Flexible(
                            child: Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: Constants.padding),
                            child: Icon(Icons.history_toggle_off_outlined),
                          )),
                    (null != time)
                        ? Flexible(
                            child: AutoSizeText(
                              time.format(context).toString(),
                              softWrap: false,
                              overflow: TextOverflow.visible,
                              maxLines: 1,
                              minFontSize: Constants.huge,
                            ),
                          )
                        : Flexible(
                            child: AutoSizeText(
                              unsetTimeText,
                              overflow: TextOverflow.visible,
                              softWrap: false,
                              minFontSize: Constants.medium,
                              maxLines: 1,
                            ),
                          ),
                  ])
                : AutoSizeText(
                    unsetDateText,
                    overflow: TextOverflow.visible,
                    softWrap: true,
                    minFontSize: Constants.medium,
                    maxLines: 2,
                  ),
            onTap: () async {
              await showDialog<Map<String, dynamic>?>(
                  context: context,
                  builder: (BuildContext context) {
                    return DateTimeDialog(
                      header: dialogHeader,
                      date: date,
                      time: time,
                    );
                  }).then((newDateTime) {
                if (null == newDateTime) {
                  return handleUpdate(newDate: date, newTime: time);
                }
                return handleUpdate(
                    newDate: newDateTime["date"],
                    newTime: newDateTime["time"],
                    checkClose: true);
              });
            },
            trailing: (showDate && null != date)
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded),
                    onPressed: handleClear,
                  )
                : null),
      );

  // REPEATABLE
  static Widget repeatableTile({
    required BuildContext context,
    EdgeInsetsGeometry outerPadding = EdgeInsets.zero,
    required Frequency frequency,
    required Set<int> weekdays,
    DateTime? startDate,
    required int repeatSkip,
    required void Function(
            {bool? checkClose,
            required Frequency newFreq,
            required Set<int> newWeekdays,
            required int newSkip})
        handleUpdate,
    required void Function() handleClear,
  }) {
    return Padding(
      padding: outerPadding,
      child: ListTile(
          contentPadding: const EdgeInsets.only(left: Constants.innerPadding),
          leading: const Icon(Icons.event_repeat_rounded),
          shape: const RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.all(Radius.circular(Constants.roundedCorners))),
          title: (frequency == Frequency.once)
              ? const AutoSizeText("Set Recurring?",
                  overflow: TextOverflow.visible,
                  minFontSize: Constants.small,
                  maxLines: 2,
                  softWrap: true)
              : AutoSizeText(toBeginningOfSentenceCase(frequency.name)!,
                  overflow: TextOverflow.visible,
                  minFontSize: Constants.small,
                  maxLines: 1,
                  softWrap: false),
          onTap: () async {
            await showDialog<Map<String, dynamic>?>(
                context: context,
                builder: (BuildContext context) {
                  return FrequencyDialog(
                    frequency: frequency,
                    weekdays: weekdays,
                    repeatSkip: repeatSkip,
                    startDate: startDate,
                  );
                }).then((newFrequency) {
              if (null == newFrequency) {
                return handleUpdate(
                  newFreq: frequency,
                  newWeekdays: weekdays,
                  newSkip: repeatSkip,
                );
              }
              return handleUpdate(
                newFreq: newFrequency["frequency"],
                newWeekdays: newFrequency["weekdays"],
                newSkip: newFrequency["repeatSkip"],
                checkClose: true,
              );
            });
          },
          trailing: (frequency != Frequency.once)
              ? IconButton(
                  icon: const Icon(Icons.clear), onPressed: handleClear)
              : null),
    );
  }

  // PRIORITY
  static Widget priorityTile({
    required BuildContext context,
    EdgeInsetsGeometry outerPadding = EdgeInsets.zero,
    required Priority priority,
    required void Function(Set<Priority> newSelection) onSelectionChanged,
    bool mobile = false,
  }) =>
      Padding(
        padding: outerPadding,
        child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Row(children: [
                Expanded(
                    child: AutoSizeText("Priority",
                        style: Constants.headerStyle,
                        maxLines: 1,
                        softWrap: true,
                        textAlign: TextAlign.center,
                        minFontSize: Constants.medium))
              ]),
              SegmentedButton<Priority>(
                  selectedIcon: const Icon(Icons.flag_circle_rounded),
                  style: ButtonStyle(
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.adaptivePlatformDensity,
                    side: MaterialStatePropertyAll<BorderSide>(BorderSide(
                      width: 2,
                      color: Theme.of(context).colorScheme.outlineVariant,
                    )),
                  ),
                  segments: Priority.values
                      .map((Priority type) => ButtonSegment<Priority>(
                          tooltip: toBeginningOfSentenceCase(type.name),
                          icon: Constants.priorityIcon[type],
                          value: type,
                          label: (!mobile)
                              ? Text(
                                  "${toBeginningOfSentenceCase(type.name)}",
                                  softWrap: false,
                                  overflow: TextOverflow.ellipsis,
                                )
                              : null))
                      .toList(growable: false),
                  selected: <Priority>{priority},
                  onSelectionChanged: onSelectionChanged)
            ]),
      );

  // MY DAY
  static Widget myDayTile(
      {required bool myDay,
      required bool canAdd,
      required void Function() toggleMyDay}) {
    String title = "";
    Widget leading;

    if (myDay) {
      title = "Added to my Day";
      leading = IconButton.filledTonal(
        icon: const Icon(Icons.wb_sunny_rounded),
        onPressed: toggleMyDay,
      );
    } else if (canAdd) {
      title = "Add to my Day?";
      leading = IconButton.outlined(
          icon: const Icon(Icons.wb_sunny_outlined), onPressed: toggleMyDay);
    } else {
      title = "Don't overload yourself, you deserve a rest.";
      leading = const Icon(Icons.block_rounded);
    }
    return ListTile(
        leading: leading,
        shape: const RoundedRectangleBorder(
            borderRadius:
                BorderRadius.all(Radius.circular(Constants.roundedCorners))),
        title: AutoSizeText(
          title,
          overflow: TextOverflow.visible,
          softWrap: true,
          minFontSize: Constants.medium,
          maxLines: 2,
        ),
        onTap: (canAdd || myDay) ? toggleMyDay : null);
  }

  // EVENTS
  static Widget eventTile(
      {required CalendarEvent event,
      required BuildContext context,
      // Add padding later if needed
      bool smallScreen = false}) {
    return ListTile(
      leading: LeadingWidgets.eventIcon(
          type: event.repeatableType,
          currentContext: context,
          outerPadding:
              const EdgeInsets.symmetric(horizontal: Constants.halfPadding),
          iconPadding: const EdgeInsets.all(Constants.halfPadding)),
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.all(Radius.circular(Constants.roundedCorners))),
      title: AutoSizeText(
        event.model.name,
        minFontSize: Constants.large,
        maxLines: 1,
        overflow: TextOverflow.visible,
        softWrap: false,
      ),
      onTap: () async {
        late Widget dialog;
        switch (event.repeatableType) {
          case RepeatableType.task:
            dialog = UpdateToDoScreen(initialToDo: event.model as ToDo);
            break;
          case RepeatableType.deadline:
            dialog =
                UpdateDeadlineScreen(initialDeadline: event.model as Deadline);
            break;
          case RepeatableType.reminder:
            dialog =
                UpdateReminderScreen(initialReminder: event.model as Reminder);
            break;
        }

        await showDialog(
            barrierDismissible: false,
            useRootNavigator: false,
            context: context,
            builder: (BuildContext context) => dialog);
      },
      subtitle: Subtitles.eventSubtitle(
        context: context,
        model: event.model,
        type: event.repeatableType,
        smallScreen: smallScreen,
      ),
      trailing: (Frequency.once != event.model.frequency)
          ? const Icon(Icons.restart_alt_rounded)
          : const SizedBox.shrink(),
    );
  }

  /// SEARCH

  static Widget historyTile({
    Widget? trailing,
    String title = "",
    void Function()? onTap,
  }) =>
      ListTile(
          leading: const Icon(Icons.history_rounded),
          shape: const RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.all(Radius.circular(Constants.roundedCorners))),
          title: AutoSizeText(
            title,
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.visible,
          ),
          onTap: onTap,
          trailing: trailing);

  // I am unsure about a leading widget atm.
  static Widget searchTile({
    Widget? leading,
    Widget? trailing,
    String title = "",
    void Function()? onTap,
  }) =>
      ListTile(
        leading: leading,
        shape: const RoundedRectangleBorder(
            borderRadius:
                BorderRadius.all(Radius.circular(Constants.roundedCorners))),
        title: AutoSizeText(
          title,
          maxLines: 1,
          softWrap: false,
          overflow: TextOverflow.visible,
        ),
        onTap: onTap,
      );

  /// BOILERPLATE.

  // BASIC CREATE LISTTILE
  static Widget createNew({
    required void Function() onTap,
    required BuildContext context,
  }) =>
      ListTile(
        leading: CircleAvatar(
          child: Icon(Icons.add_rounded,
              color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
        title: const AutoSizeText(
          "Create New",
          overflow: TextOverflow.visible,
          softWrap: false,
          maxLines: 1,
          minFontSize: Constants.medium,
        ),
        contentPadding: const EdgeInsets.all(Constants.padding),
        shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.all(Radius.circular(Constants.roundedCorners)),
        ),
        onTap: onTap,
      );

  // BASIC ADD BUTTON
  static Widget addTile({
    required void Function() onTap,
    required String title,
  }) =>
      ListTile(
        shape: const RoundedRectangleBorder(
            borderRadius:
                BorderRadius.all(Radius.circular(Constants.roundedCorners))),
        leading: const Icon(Icons.add_rounded),
        title: AutoSizeText(title,
            maxLines: 1,
            overflow: TextOverflow.visible,
            softWrap: false,
            minFontSize: Constants.large),
        onTap: onTap,
      );

  // FETCH
  static Widget fetchTile({
    required void Function() onTap,
  }) =>
      ListTile(
          shape: const RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.all(Radius.circular(Constants.roundedCorners))),
          leading: const Icon(Icons.redo_rounded),
          title: const AutoSizeText(
            "Load more",
            maxLines: 1,
            overflow: TextOverflow.visible,
            softWrap: false,
            minFontSize: Constants.large,
          ),
          onTap: onTap);

  static Widget resetTile({
    required void Function() onTap,
  }) =>
      ListTile(
          shape: const RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.all(Radius.circular(Constants.roundedCorners))),
          leading: const Icon(Icons.refresh_rounded),
          title: const AutoSizeText(
            "Reset",
            maxLines: 1,
            overflow: TextOverflow.visible,
            softWrap: false,
            minFontSize: Constants.large,
          ),
          onTap: onTap);

  // CREATE/UPDATE
  static Widget createButton({
    String label = "Create",
    EdgeInsetsGeometry outerPadding = EdgeInsets.zero,
    required Future<void> Function() handleCreate,
  }) =>
      Align(
        alignment: Alignment.centerRight,
        child: Padding(
          padding: outerPadding,
          child: FilledButton.icon(
              label: Text(label, overflow: TextOverflow.ellipsis),
              icon: const Icon(Icons.add_rounded),
              onPressed: handleCreate),
        ),
      );

// DELETE
  static Widget deleteButton({
    EdgeInsetsGeometry outerPadding = EdgeInsets.zero,
    required Future<void> Function() handleDelete,
  }) =>
      Padding(
        padding: outerPadding,
        child: FilledButton.tonalIcon(
            label: const Text("Delete", overflow: TextOverflow.ellipsis),
            icon: const Icon(Icons.delete_forever_rounded),
            onPressed: handleDelete),
      );

// COMBINATION UPDATE & DELETE
  static Widget updateAndDeleteButtons({
    EdgeInsetsGeometry updateButtonPadding = EdgeInsets.zero,
    EdgeInsetsGeometry deleteButtonPadding = EdgeInsets.zero,
    required Future<void> Function() handleUpdate,
    required Future<void> Function() handleDelete,
  }) =>
      Align(
        alignment: Alignment.centerRight,
        child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              deleteButton(
                  outerPadding: deleteButtonPadding,
                  handleDelete: handleDelete),
              createButton(
                  label: "Update",
                  outerPadding: updateButtonPadding,
                  handleCreate: handleUpdate)
            ]),
      );
}
