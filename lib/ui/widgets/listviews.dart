import 'package:allocate/providers/reminder_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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
import '../../providers/routine_provider.dart';
import '../../providers/todo_provider.dart';
import '../../util/constants.dart';
import 'custom_drag_start.dart';
import 'tiles.dart';

// TODO: Implement crossfading between lists?
class ListViews {
  // This is for dragging
  static Widget proxyDecorator(
          Widget child, int index, Animation<double> animation) =>
      AnimatedBuilder(
          animation: animation,
          child: child,
          builder: (BuildContext context, Widget? child) {
            final ColorScheme colorScheme = Theme.of(context).colorScheme;
            final Color draggableColor = colorScheme.primaryContainer;
            final Color shadowColor = colorScheme.shadow;
            return Material(
              borderRadius: const BorderRadius.all(
                  Radius.circular(Constants.semiCircular)),
              color: draggableColor,
              shadowColor: shadowColor,
              child: child,
            );
          });

  static Widget reorderableToDos({
    Key? key,
    required BuildContext context,
    required List<ToDo> toDos,
    bool checkDelete = false,
    bool smallScreen = false,
    Future<void> Function({required ToDo toDo, required int index})?
        checkboxAnimateBeforeUpdate,
    ScrollPhysics physics = const NeverScrollableScrollPhysics(),
  }) =>
      ReorderableListView.builder(
          key: key,
          proxyDecorator: proxyDecorator,
          buildDefaultDragHandles: false,
          physics: physics,
          shrinkWrap: true,
          onReorder: (int oldIndex, int newIndex) async =>
              await Provider.of<ToDoProvider>(context, listen: false)
                  .reorderToDos(
                      oldIndex: oldIndex, newIndex: newIndex, toDos: toDos),
          itemCount: toDos.length,
          itemBuilder: (BuildContext context, int index) {
            if (toDos.length > 1) {
              return CustomDragStartListener(
                delay: Constants.delayTime,
                index: index,
                key: ValueKey(toDos[index].id),
                child: Tiles.toDoListTile(
                  checkboxAnimateBeforeUpdate: checkboxAnimateBeforeUpdate,
                  smallScreen: smallScreen,
                  context: context,
                  index: index,
                  toDo: toDos[index],
                  showHandle: true,
                  checkDelete: checkDelete,
                ),
              );
            }
            return Tiles.toDoListTile(
              checkboxAnimateBeforeUpdate: checkboxAnimateBeforeUpdate,
              smallScreen: smallScreen,
              context: context,
              index: index,
              toDo: toDos[index],
              showHandle: false,
              checkDelete: checkDelete,
            );
          });

  static Widget immutableToDos({
    Key? key,
    required BuildContext context,
    required List<ToDo> toDos,
    bool checkDelete = false,
    bool smallScreen = false,
    Future<void> Function({required ToDo toDo, required int index})?
        checkboxAnimateBeforeUpdate,
    ScrollPhysics physics = const NeverScrollableScrollPhysics(),
  }) =>
      ListView.builder(
          key: key,
          physics: physics,
          shrinkWrap: true,
          itemCount: toDos.length,
          itemBuilder: (BuildContext context, int index) {
            return Tiles.toDoListTile(
              checkboxAnimateBeforeUpdate: checkboxAnimateBeforeUpdate,
              smallScreen: smallScreen,
              context: context,
              index: index,
              toDo: toDos[index],
              showHandle: false,
              checkDelete: checkDelete,
            );
          });

  static Widget reorderableMyDay({
    Key? key,
    required BuildContext context,
    required List<ToDo> toDos,
    bool checkDelete = false,
    bool smallScreen = false,
    Future<void> Function({required ToDo toDo, required int index})?
        checkboxAnimateBeforeUpdate,
    ScrollPhysics physics = const NeverScrollableScrollPhysics(),
  }) =>
      ReorderableListView.builder(
          key: key,
          proxyDecorator: proxyDecorator,
          buildDefaultDragHandles: false,
          physics: physics,
          shrinkWrap: true,
          onReorder: (int oldIndex, int newIndex) async =>
              await Provider.of<ToDoProvider>(context, listen: false)
                  .reorderToDos(
                      oldIndex: oldIndex, newIndex: newIndex, toDos: toDos),
          itemCount: toDos.length,
          itemBuilder: (BuildContext context, int index) {
            if (toDos.length > 1) {
              return CustomDragStartListener(
                delay: Constants.delayTime,
                index: index,
                key: ValueKey(toDos[index].id ^ index),
                child: Tiles.toDoMyDayTile(
                  checkboxAnimateBeforeUpdate: checkboxAnimateBeforeUpdate,
                  smallScreen: smallScreen,
                  context: context,
                  index: index,
                  toDo: toDos[index],
                  showHandle: true,
                ),
              );
            }
            return Tiles.toDoMyDayTile(
              checkboxAnimateBeforeUpdate: checkboxAnimateBeforeUpdate,
              smallScreen: smallScreen,
              context: context,
              index: index,
              toDo: toDos[index],
              showHandle: false,
            );
          });

  static Widget immutableMyDay({
    Key? key,
    required BuildContext context,
    required List<ToDo> toDos,
    bool smallScreen = false,
    Future<void> Function({required ToDo toDo, required int index})?
        checkboxAnimateBeforeUpdate,
    ScrollPhysics physics = const NeverScrollableScrollPhysics(),
  }) =>
      ListView.builder(
          key: key,
          physics: physics,
          shrinkWrap: true,
          itemCount: toDos.length,
          itemBuilder: (BuildContext context, int index) {
            return Tiles.toDoMyDayTile(
              checkboxAnimateBeforeUpdate: checkboxAnimateBeforeUpdate,
              smallScreen: smallScreen,
              context: context,
              index: index,
              toDo: toDos[index],
              showHandle: false,
            );
          });

  static Widget reorderableRoutines({
    Key? key,
    required BuildContext context,
    required List<Routine> routines,
    bool checkDelete = false,
    ScrollPhysics physics = const NeverScrollableScrollPhysics(),
  }) =>
      ReorderableListView.builder(
          key: key,
          proxyDecorator: proxyDecorator,
          buildDefaultDragHandles: false,
          physics: physics,
          shrinkWrap: true,
          onReorder: (int oldIndex, int newIndex) async =>
              await Provider.of<RoutineProvider>(context, listen: false)
                  .reorderRoutines(oldIndex: oldIndex, newIndex: newIndex),
          itemCount: routines.length,
          itemBuilder: (BuildContext context, int index) {
            if (routines.length > 1) {
              return CustomDragStartListener(
                delay: Constants.delayTime,
                index: index,
                key: ValueKey(routines[index].id),
                child: Tiles.routineListTile(
                  context: context,
                  index: index,
                  routine: routines[index],
                  showHandle: true,
                  checkDelete: checkDelete,
                ),
              );
            }
            return Tiles.routineListTile(
              context: context,
              index: index,
              routine: routines[index],
              showHandle: false,
              checkDelete: checkDelete,
            );
          });

  static Widget immutableRoutines({
    Key? key,
    required BuildContext context,
    required List<Routine> routines,
    bool checkDelete = false,
    ScrollPhysics physics = const NeverScrollableScrollPhysics(),
  }) =>
      ListView.builder(
          key: key,
          physics: physics,
          shrinkWrap: true,
          itemCount: routines.length,
          itemBuilder: (BuildContext context, int index) {
            return Tiles.routineListTile(
              context: context,
              index: index,
              routine: routines[index],
              showHandle: false,
              checkDelete: checkDelete,
            );
          });

  static Widget reorderableDeadlines({
    Key? key,
    required BuildContext context,
    required List<Deadline> deadlines,
    bool checkDelete = false,
    bool smallScreen = false,
    ScrollPhysics physics = const NeverScrollableScrollPhysics(),
  }) =>
      ReorderableListView.builder(
          key: key,
          proxyDecorator: proxyDecorator,
          buildDefaultDragHandles: false,
          physics: physics,
          shrinkWrap: true,
          onReorder: (int oldIndex, int newIndex) async =>
              await Provider.of<DeadlineProvider>(context, listen: false)
                  .reorderDeadlines(oldIndex: oldIndex, newIndex: newIndex),
          itemCount: deadlines.length,
          itemBuilder: (BuildContext context, int index) {
            if (deadlines.length > 1) {
              return CustomDragStartListener(
                delay: Constants.delayTime,
                index: index,
                key: ValueKey(deadlines[index].id),
                child: Tiles.deadlineListTile(
                  context: context,
                  index: index,
                  smallScreen: smallScreen,
                  deadline: deadlines[index],
                  showHandle: true,
                  checkDelete: checkDelete,
                ),
              );
            }
            return Tiles.deadlineListTile(
              context: context,
              index: index,
              smallScreen: smallScreen,
              deadline: deadlines[index],
              showHandle: false,
              checkDelete: checkDelete,
            );
          });

  static Widget immutableDeadlines({
    Key? key,
    required BuildContext context,
    required List<Deadline> deadlines,
    bool checkDelete = false,
    smallScreen = false,
    ScrollPhysics physics = const NeverScrollableScrollPhysics(),
  }) =>
      ListView.builder(
          key: key,
          physics: physics,
          shrinkWrap: true,
          itemCount: deadlines.length,
          itemBuilder: (BuildContext context, int index) {
            return Tiles.deadlineListTile(
              context: context,
              index: index,
              smallScreen: smallScreen,
              deadline: deadlines[index],
              showHandle: false,
              checkDelete: checkDelete,
            );
          });

  static Widget reorderableReminders({
    Key? key,
    required BuildContext context,
    required List<Reminder> reminders,
    bool checkDelete = false,
    bool smallScreen = false,
    ScrollPhysics physics = const NeverScrollableScrollPhysics(),
  }) =>
      ReorderableListView.builder(
          key: key,
          proxyDecorator: proxyDecorator,
          buildDefaultDragHandles: false,
          physics: physics,
          shrinkWrap: true,
          onReorder: (int oldIndex, int newIndex) async =>
              await Provider.of<ReminderProvider>(context, listen: false)
                  .reorderReminders(oldIndex: oldIndex, newIndex: newIndex),
          itemCount: reminders.length,
          itemBuilder: (BuildContext context, int index) {
            if (reminders.length > 1) {
              return CustomDragStartListener(
                delay: Constants.delayTime,
                index: index,
                key: ValueKey(reminders[index].id),
                child: Tiles.reminderListTile(
                  context: context,
                  index: index,
                  smallScreen: smallScreen,
                  reminder: reminders[index],
                  showHandle: true,
                  checkDelete: checkDelete,
                ),
              );
            }
            return Tiles.reminderListTile(
              context: context,
              index: index,
              smallScreen: smallScreen,
              reminder: reminders[index],
              showHandle: false,
              checkDelete: checkDelete,
            );
          });

  static Widget immutableReminders({
    Key? key,
    required BuildContext context,
    required List<Reminder> reminders,
    bool checkDelete = false,
    bool smallScreen = false,
    ScrollPhysics physics = const NeverScrollableScrollPhysics(),
  }) =>
      ListView.builder(
          key: key,
          physics: physics,
          shrinkWrap: true,
          itemCount: reminders.length,
          itemBuilder: (BuildContext context, int index) {
            return Tiles.reminderListTile(
              context: context,
              index: index,
              smallScreen: smallScreen,
              reminder: reminders[index],
              showHandle: false,
              checkDelete: checkDelete,
            );
          });

  static Widget reorderableGroups({
    Key? key,
    required BuildContext context,
    required List<Group> groups,
    bool checkDelete = false,
    ScrollPhysics physics = const NeverScrollableScrollPhysics(),
  }) =>
      ReorderableListView.builder(
          key: key,
          proxyDecorator: proxyDecorator,
          buildDefaultDragHandles: false,
          physics: physics,
          shrinkWrap: true,
          onReorder: (int oldIndex, int newIndex) async =>
              await Provider.of<GroupProvider>(context, listen: false)
                  .reorderGroups(oldIndex: oldIndex, newIndex: newIndex),
          itemCount: groups.length,
          itemBuilder: (BuildContext context, int index) {
            if (groups.length > 1) {
              return CustomDragStartListener(
                  delay: Constants.delayTime,
                  key: ValueKey(groups[index].id),
                  index: index,
                  child: Tiles.groupListTile(
                    context: context,
                    index: index,
                    group: groups[index],
                    showHandle: true,
                    checkDelete: checkDelete,
                  ));
            }
            return Tiles.groupListTile(
              context: context,
              index: index,
              group: groups[index],
              showHandle: false,
              checkDelete: checkDelete,
            );
          });

  static Widget immutableGroups({
    Key? key,
    required BuildContext context,
    required List<Group> groups,
    bool checkDelete = false,
    ScrollPhysics physics = const NeverScrollableScrollPhysics(),
  }) =>
      ListView.builder(
          key: key,
          shrinkWrap: true,
          physics: physics,
          itemCount: groups.length,
          itemBuilder: (BuildContext context, int index) {
            return Tiles.groupListTile(
              context: context,
              index: index,
              group: groups[index],
              checkDelete: checkDelete,
            );
          });

  static Widget reorderableGroupToDos({
    Key? key,
    required BuildContext context,
    required List<ToDo> toDos,
    ScrollPhysics physics = const NeverScrollableScrollPhysics(),
    required void Function({ToDo? toDo, bool? value}) onChanged,
    void Function({ToDo? toDo})? onTap,
    void Function({ToDo? toDo})? handleRemove,
  }) =>
      ReorderableListView.builder(
        key: key,
        proxyDecorator: proxyDecorator,
        buildDefaultDragHandles: false,
        physics: physics,
        shrinkWrap: true,
        onReorder: (int oldIndex, int newIndex) async =>
            await Provider.of<GroupProvider>(context, listen: false)
                .reorderGroupToDos(
                    oldIndex: oldIndex, newIndex: newIndex, toDos: toDos),
        onReorderStart: (_) {
          FocusScope.of(context).unfocus();
        },
        itemCount: toDos.length,
        itemBuilder: (BuildContext context, int index) {
          if (toDos.length > 1) {
            return CustomDragStartListener(
              delay: Constants.delayTime,
              index: index,
              key: ValueKey(toDos[index].id),
              child: Tiles.toDoCheckTile(
                index: index,
                toDo: toDos[index],
                showHandle: true,
                onChanged: (value) =>
                    onChanged(toDo: toDos[index], value: value),
                onTap: () => (null != onTap) ? onTap(toDo: toDos[index]) : null,
                handleRemove: () => (null != handleRemove)
                    ? handleRemove(toDo: toDos[index])
                    : null,
              ),
            );
          }
          return Tiles.toDoCheckTile(
            index: index,
            toDo: toDos[index],
            showHandle: false,
            onChanged: (value) => onChanged(toDo: toDos[index], value: value),
            onTap: () => (null != onTap) ? onTap(toDo: toDos[index]) : null,
            handleRemove: () => (null != handleRemove)
                ? handleRemove(toDo: toDos[index])
                : null,
          );
        },
      );

  static Widget reorderableSubtasks({
    Key? key,
    required BuildContext context,
    required List<Subtask> subtasks,
    int? itemCount,
    showHandle = false,
    ScrollPhysics physics = const NeverScrollableScrollPhysics(),
    required void Function(int oldIndex, int newIndex) onReorder,
    required void Function({bool? value, Subtask? subtask}) onChanged,
    required void Function({Subtask? subtask}) onTap,
    required void Function({Subtask? subtask}) onRemoved,
    EdgeInsetsGeometry contentPadding = EdgeInsets.zero,
  }) =>
      ReorderableListView.builder(
          key: key,
          proxyDecorator: proxyDecorator,
          buildDefaultDragHandles: false,
          physics: physics,
          shrinkWrap: true,
          itemCount: subtasks.length,
          onReorderStart: (_) {
            FocusScope.of(context).unfocus();
          },
          onReorder: onReorder,
          itemBuilder: (BuildContext context, int index) {
            return CustomDragStartListener(
                delay: Constants.delayTime,
                index: index,
                key: ValueKey(index),
                child: Tiles.subtaskCheckboxTile(
                    index: index,
                    subtask: subtasks[index],
                    onTap: () => onTap(subtask: subtasks[index]),
                    onChanged: (value) =>
                        onChanged(value: value, subtask: subtasks[index]),
                    onRemoved: () => onRemoved(subtask: subtasks[index]),
                    showHandle: (subtasks.length > 1)));
          });

  static Widget eventList(
          {required ValueListenable<List<CalendarEvent>> selectedEvents,
          bool smallScreen = false}) =>
      ValueListenableBuilder<List<CalendarEvent>>(
          valueListenable: selectedEvents,
          builder:
              (BuildContext context, List<CalendarEvent> value, Widget? child) {
            return ListView.builder(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: value.length,
                itemBuilder: (BuildContext context, int index) {
                  return Tiles.eventTile(
                    event: value[index],
                    context: context,
                    smallScreen: smallScreen,
                  );
                });
          });
}
