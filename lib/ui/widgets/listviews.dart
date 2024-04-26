import 'dart:ui';

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
import '../../providers/model/deadline_provider.dart';
import '../../providers/model/group_provider.dart';
import '../../providers/model/reminder_provider.dart';
import '../../providers/model/routine_provider.dart';
import '../../providers/model/todo_provider.dart';
import '../../util/constants.dart';
import '../../util/enums.dart';
import '../../util/interfaces/i_model.dart';
import 'custom_drag_start.dart';
import 'custom_reorderable_separated.dart';
import 'tiles.dart';

abstract class ListViews {
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
            final animValue = Curves.easeInOut.transform(animation.value);
            return Material(
              elevation: lerpDouble(0, 10, animValue)!,
              borderRadius: const BorderRadius.all(
                  Radius.circular(Constants.semiCircular)),
              color: draggableColor,
              shadowColor: shadowColor,
              child: child,
            );
          });

  static Widget fade(
          {Key? key,
          Fade fade = Fade.fadeIn,
          Widget? child,
          void Function()? onEnd}) =>
      TweenAnimationBuilder(
          key: key,
          duration: switch (fade) {
            Fade.fadeIn => const Duration(milliseconds: Constants.fadeInTime),
            Fade.fadeOut => const Duration(milliseconds: Constants.fadeOutTime),
            Fade.none => const Duration(milliseconds: 0),
          },
          tween: switch (fade) {
            Fade.fadeIn => Tween<double>(begin: 0.0, end: 1.0),
            Fade.fadeOut => Tween<double>(begin: 1.0, end: 0.0),
            Fade.none => Tween<double>(begin: 1.0, end: 1.0),
          },
          curve: switch (fade) {
            Fade.fadeIn => Curves.fastLinearToSlowEaseIn,
            Fade.fadeOut => Curves.linear,
            Fade.none => Curves.linear,
          },
          onEnd: onEnd,
          child: child,
          builder: (BuildContext context, double opacity, Widget? child) {
            return Opacity(opacity: opacity, child: child);
          });

  static Widget reorderableToDos({
    Key? key,
    required BuildContext context,
    required List<ToDo> toDos,
    bool checkDelete = false,
    bool smallScreen = false,
    EdgeInsets listPadding = EdgeInsets.zero,
    Future<void> Function({required ToDo toDo, required int index})?
        checkboxAnimateBeforeUpdate,
    Future<void> Function({ToDo? item})? onRemove,
    ScrollPhysics physics = const NeverScrollableScrollPhysics(),
  }) =>
      ReorderableListView.builder(
          key: key,
          padding: listPadding,
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
            Widget child = fade(
              onEnd: () {
                toDos[index].fade = Fade.none;
              },
              key: ValueKey(toDos[index].id),
              fade: toDos[index].fade,
              child: Tiles.toDoListTile(
                checkboxAnimateBeforeUpdate: checkboxAnimateBeforeUpdate,
                smallScreen: smallScreen,
                context: context,
                index: index,
                toDo: toDos[index],
                showHandle: toDos.length > 1,
                checkDelete: checkDelete,
                onRemove: onRemove,
              ),
            );
            if (toDos.length > 1) {
              return CustomDragStartListener(
                delay: Constants.dragDelayTime,
                index: index,
                key: ValueKey(toDos[index].id),
                child: child,
              );
            }
            return child;
          });

  static Widget immutableToDos({
    Key? key,
    required List<ToDo> toDos,
    bool checkDelete = false,
    bool smallScreen = false,
    EdgeInsets listPadding = EdgeInsets.zero,
    Future<void> Function({required ToDo toDo, required int index})?
        checkboxAnimateBeforeUpdate,
    Future<void> Function({ToDo? item})? onRemove,
    ScrollPhysics physics = const NeverScrollableScrollPhysics(),
  }) =>
      ListView.builder(
          key: key,
          padding: listPadding,
          physics: physics,
          shrinkWrap: true,
          itemCount: toDos.length,
          itemBuilder: (BuildContext context, int index) {
            return fade(
              key: ValueKey(toDos[index].id),
              onEnd: () {
                toDos[index].fade = Fade.none;
              },
              fade: toDos[index].fade,
              child: Tiles.toDoListTile(
                checkboxAnimateBeforeUpdate: checkboxAnimateBeforeUpdate,
                smallScreen: smallScreen,
                context: context,
                index: index,
                toDo: toDos[index],
                onRemove: onRemove,
                showHandle: false,
                checkDelete: checkDelete,
              ),
            );
          });

  static Widget reorderableMyDay({
    Key? key,
    required BuildContext context,
    required List<ToDo> toDos,
    bool checkDelete = false,
    bool smallScreen = false,
    EdgeInsets listPadding = EdgeInsets.zero,
    Future<void> Function({required ToDo toDo, required int index})?
        checkboxAnimateBeforeUpdate,
    Future<void> Function({ToDo? item})? onRemove,
    ScrollPhysics physics = const NeverScrollableScrollPhysics(),
  }) =>
      ReorderableListView.builder(
          key: key,
          padding: listPadding,
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
            // Key is id ^ index. and I don't know why...
            Widget child = fade(
              key: ValueKey(toDos[index].id ^ index),
              onEnd: () {
                toDos[index].fade = Fade.none;
              },
              fade: toDos[index].fade,
              child: Tiles.toDoMyDayTile(
                checkboxAnimateBeforeUpdate: checkboxAnimateBeforeUpdate,
                smallScreen: smallScreen,
                context: context,
                index: index,
                toDo: toDos[index],
                showHandle: toDos.length > 1,
                onRemove: onRemove,
              ),
            );
            if (toDos.length > 1) {
              return CustomDragStartListener(
                delay: Constants.dragDelayTime,
                index: index,
                key: ValueKey(toDos[index].id ^ index),
                child: child,
              );
            }
            return child;
          });

  static Widget immutableMyDay({
    Key? key,
    required List<ToDo> toDos,
    bool smallScreen = false,
    EdgeInsets listPadding = EdgeInsets.zero,
    Future<void> Function({required ToDo toDo, required int index})?
        checkboxAnimateBeforeUpdate,
    Future<void> Function({ToDo? item})? onRemove,
    ScrollPhysics physics = const NeverScrollableScrollPhysics(),
  }) =>
      ListView.builder(
          key: key,
          padding: listPadding,
          physics: physics,
          shrinkWrap: true,
          itemCount: toDos.length,
          itemBuilder: (BuildContext context, int index) {
            return fade(
              key: ValueKey(toDos[index].id ^ index),
              onEnd: () {
                toDos[index].fade = Fade.none;
              },
              fade: toDos[index].fade,
              child: Tiles.toDoMyDayTile(
                checkboxAnimateBeforeUpdate: checkboxAnimateBeforeUpdate,
                smallScreen: smallScreen,
                context: context,
                index: index,
                toDo: toDos[index],
                showHandle: false,
                onRemove: onRemove,
              ),
            );
          });

  static Widget reorderableRoutines({
    Key? key,
    required BuildContext context,
    required List<Routine> routines,
    EdgeInsets listPadding = EdgeInsets.zero,
    bool checkDelete = false,
    Future<void> Function({Routine? item})? onRemove,
    ScrollPhysics physics = const NeverScrollableScrollPhysics(),
  }) =>
      ReorderableListView.builder(
          key: key,
          padding: listPadding,
          proxyDecorator: proxyDecorator,
          buildDefaultDragHandles: false,
          physics: physics,
          shrinkWrap: true,
          onReorder: (int oldIndex, int newIndex) async =>
              await Provider.of<RoutineProvider>(context, listen: false)
                  .reorderRoutines(oldIndex: oldIndex, newIndex: newIndex),
          itemCount: routines.length,
          itemBuilder: (BuildContext context, int index) {
            Widget child = fade(
              key: ValueKey(routines[index].id),
              onEnd: () {
                routines[index].fade = Fade.none;
              },
              fade: routines[index].fade,
              child: Tiles.routineListTile(
                context: context,
                index: index,
                routine: routines[index],
                showHandle: routines.length > 1,
                checkDelete: checkDelete,
                onRemove: onRemove,
              ),
            );
            if (routines.length > 1) {
              return CustomDragStartListener(
                  delay: Constants.dragDelayTime,
                  index: index,
                  key: ValueKey(routines[index].id),
                  child: child);
            }
            return child;
          });

  static Widget immutableRoutines({
    Key? key,
    required List<Routine> routines,
    bool checkDelete = false,
    EdgeInsets listPadding = EdgeInsets.zero,
    ScrollPhysics physics = const NeverScrollableScrollPhysics(),
    Future<void> Function({Routine? item})? onRemove,
  }) =>
      ListView.builder(
          key: key,
          padding: listPadding,
          physics: physics,
          shrinkWrap: true,
          itemCount: routines.length,
          itemBuilder: (BuildContext context, int index) {
            return fade(
              key: ValueKey(routines[index].id),
              onEnd: () {
                routines[index].fade = Fade.none;
              },
              fade: routines[index].fade,
              child: Tiles.routineListTile(
                context: context,
                index: index,
                routine: routines[index],
                showHandle: false,
                checkDelete: checkDelete,
              ),
            );
          });

  static Widget reorderableDeadlines({
    Key? key,
    required BuildContext context,
    required List<Deadline> deadlines,
    EdgeInsets listPadding = EdgeInsets.zero,
    bool checkDelete = false,
    bool smallScreen = false,
    ScrollPhysics physics = const NeverScrollableScrollPhysics(),
    Future<void> Function({Deadline? item})? onRemove,
  }) =>
      ReorderableListView.builder(
          key: key,
          proxyDecorator: proxyDecorator,
          padding: listPadding,
          buildDefaultDragHandles: false,
          physics: physics,
          shrinkWrap: true,
          onReorder: (int oldIndex, int newIndex) async =>
              await Provider.of<DeadlineProvider>(context, listen: false)
                  .reorderDeadlines(oldIndex: oldIndex, newIndex: newIndex),
          itemCount: deadlines.length,
          itemBuilder: (BuildContext context, int index) {
            Widget child = fade(
              key: ValueKey(deadlines[index].id),
              onEnd: () {
                deadlines[index].fade = Fade.none;
              },
              fade: deadlines[index].fade,
              child: Tiles.deadlineListTile(
                context: context,
                index: index,
                smallScreen: smallScreen,
                deadline: deadlines[index],
                showHandle: deadlines.length > 1,
                checkDelete: checkDelete,
                onRemove: onRemove,
              ),
            );
            if (deadlines.length > 1) {
              return CustomDragStartListener(
                delay: Constants.dragDelayTime,
                index: index,
                key: ValueKey(deadlines[index].id),
                child: child,
              );
            }
            return child;
          });

  static Widget immutableDeadlines({
    Key? key,
    required List<Deadline> deadlines,
    bool checkDelete = false,
    smallScreen = false,
    EdgeInsets listPadding = EdgeInsets.zero,
    ScrollPhysics physics = const NeverScrollableScrollPhysics(),
    Future<void> Function({Deadline? item})? onRemove,
  }) =>
      ListView.builder(
          key: key,
          physics: physics,
          padding: listPadding,
          shrinkWrap: true,
          itemCount: deadlines.length,
          itemBuilder: (BuildContext context, int index) {
            return fade(
              key: ValueKey(deadlines[index].id),
              onEnd: () {
                deadlines[index].fade = Fade.none;
              },
              fade: deadlines[index].fade,
              child: Tiles.deadlineListTile(
                context: context,
                index: index,
                smallScreen: smallScreen,
                deadline: deadlines[index],
                showHandle: false,
                checkDelete: checkDelete,
                onRemove: onRemove,
              ),
            );
          });

  static Widget reorderableReminders({
    Key? key,
    required BuildContext context,
    required List<Reminder> reminders,
    EdgeInsets listPadding = EdgeInsets.zero,
    bool checkDelete = false,
    bool smallScreen = false,
    ScrollPhysics physics = const NeverScrollableScrollPhysics(),
    Future<void> Function({Reminder? item})? onRemove,
  }) =>
      ReorderableListView.builder(
          key: key,
          padding: listPadding,
          proxyDecorator: proxyDecorator,
          buildDefaultDragHandles: false,
          physics: physics,
          shrinkWrap: true,
          onReorder: (int oldIndex, int newIndex) async =>
              await Provider.of<ReminderProvider>(context, listen: false)
                  .reorderReminders(oldIndex: oldIndex, newIndex: newIndex),
          itemCount: reminders.length,
          itemBuilder: (BuildContext context, int index) {
            Widget child = fade(
              key: ValueKey(reminders[index].id),
              onEnd: () {
                reminders[index].fade = Fade.none;
              },
              fade: reminders[index].fade,
              child: Tiles.reminderListTile(
                context: context,
                index: index,
                smallScreen: smallScreen,
                reminder: reminders[index],
                showHandle: reminders.length > 1,
                checkDelete: checkDelete,
                onRemove: onRemove,
              ),
            );
            if (reminders.length > 1) {
              return CustomDragStartListener(
                delay: Constants.dragDelayTime,
                index: index,
                key: ValueKey(reminders[index].id),
                child: child,
              );
            }
            return child;
          });

  static Widget immutableReminders({
    Key? key,
    required List<Reminder> reminders,
    bool checkDelete = false,
    bool smallScreen = false,
    EdgeInsets listPadding = EdgeInsets.zero,
    ScrollPhysics physics = const NeverScrollableScrollPhysics(),
    Future<void> Function({Reminder? item})? onRemove,
  }) =>
      ListView.builder(
          key: key,
          padding: listPadding,
          physics: physics,
          shrinkWrap: true,
          itemCount: reminders.length,
          itemBuilder: (BuildContext context, int index) {
            return fade(
              key: ValueKey(reminders[index].id),
              onEnd: () {
                reminders[index].fade = Fade.none;
              },
              fade: reminders[index].fade,
              child: Tiles.reminderListTile(
                context: context,
                index: index,
                smallScreen: smallScreen,
                reminder: reminders[index],
                showHandle: false,
                checkDelete: checkDelete,
                onRemove: onRemove,
              ),
            );
          });

  // NOTE: This is using a custom reorderable listview
  // to allow padding between items.
  // The index correction happens within the widget,
  // This has been accounted for in GroupProvider.
  static Widget reorderableGroups({
    Key? key,
    required BuildContext context,
    required List<Group> groups,
    bool checkDelete = false,
    Widget? divider,
    EdgeInsetsGeometry separatorPadding =
        const EdgeInsets.symmetric(vertical: Constants.padding),
    ScrollPhysics physics = const NeverScrollableScrollPhysics(),
    EdgeInsets listPadding = EdgeInsets.zero,
    Future<void> Function({Group? item})? onRemove,
    void Function({List<ToDo>? items})? onToDoFetch,
    Future<void> Function({ToDo? item})? onToDoRemove,
  }) =>
      CustomReorderableListView.separated(
          key: key,
          padding: listPadding,
          proxyDecorator: proxyDecorator,
          buildDefaultDragHandles: false,
          physics: physics,
          shrinkWrap: true,
          onReorder: (int oldIndex, int newIndex) async =>
              await Provider.of<GroupProvider>(context, listen: false)
                  .reorderGroups(oldIndex: oldIndex, newIndex: newIndex),
          itemCount: groups.length,
          itemBuilder: (BuildContext context, int index) {
            Widget child = fade(
              key: ValueKey(groups[index].id),
              onEnd: () {
                groups[index].fade = Fade.none;
              },
              fade: groups[index].fade,
              child: Tiles.groupListTile(
                context: context,
                index: index,
                group: groups[index],
                showHandle: groups.length > 1,
                checkDelete: checkDelete,
                onRemove: onRemove,
                onToDoFetch: (null != onToDoFetch) ? onToDoFetch : null,
                onToDoRemove: onToDoRemove,
              ),
            );

            // BECAUSE OF SEPARATORS, THIS NEEDS TO HAVE A DOUBLED INDEX
            if (groups.length > 1) {
              return CustomDragStartListener(
                delay: Constants.dragDelayTime,
                key: ValueKey(groups[index].id),
                index: index * 2,
                child: child,
              );
            }
            return child;
          },
          separatorBuilder: (BuildContext context, int index) =>
              divider ??
              Padding(
                  key: ValueKey("separatorKey: $index"),
                  padding: separatorPadding,
                  child: const SizedBox.shrink()));

  static Widget immutableGroups({
    Key? key,
    required List<Group> groups,
    bool checkDelete = false,
    Widget? divider,
    EdgeInsetsGeometry separatorPadding =
        const EdgeInsets.symmetric(vertical: Constants.padding),
    ScrollPhysics physics = const NeverScrollableScrollPhysics(),
    EdgeInsets listPadding = EdgeInsets.zero,
    Future<void> Function({Group? item})? onRemove,
    void Function({List<ToDo>? items})? onToDoFetch,
    Future<void> Function({ToDo? item})? onToDoRemove,
  }) =>
      ListView.separated(
        key: key,
        padding: listPadding,
        shrinkWrap: true,
        physics: physics,
        itemCount: groups.length,
        itemBuilder: (BuildContext context, int index) {
          return fade(
            key: ValueKey(groups[index].id),
            onEnd: () {
              groups[index].fade = Fade.none;
            },
            fade: groups[index].fade,
            child: Tiles.groupListTile(
              context: context,
              index: index,
              group: groups[index],
              checkDelete: checkDelete,
              onRemove: onRemove,
              onToDoFetch: (null != onToDoFetch) ? onToDoFetch : null,
              onToDoRemove: onToDoRemove,
            ),
          );
        },
        separatorBuilder: (BuildContext context, int index) =>
            divider ??
            Padding(padding: separatorPadding, child: const SizedBox.shrink()),
      );

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
          Widget child = fade(
            key: ValueKey(toDos[index].id),
            onEnd: () {
              toDos[index].fade = Fade.none;
            },
            fade: toDos[index].fade,
            child: Tiles.toDoCheckTile(
              index: index,
              toDo: toDos[index],
              showHandle: toDos.length > 1,
              onChanged: (value) => onChanged(toDo: toDos[index], value: value),
              onTap: () => (null != onTap) ? onTap(toDo: toDos[index]) : null,
              handleRemove: () => (null != handleRemove)
                  ? handleRemove(toDo: toDos[index])
                  : null,
            ),
          );

          if (toDos.length > 1) {
            return CustomDragStartListener(
                delay: Constants.dragDelayTime,
                index: index,
                key: ValueKey(toDos[index].id),
                child: child);
          }
          return child;
        },
      );

  static Widget navDrawerGroups({
    Key? key,
    required List<Group> groups,
    int? itemCount,
    EdgeInsetsGeometry tilePadding = EdgeInsets.zero,
    ScrollPhysics physics = const NeverScrollableScrollPhysics(),
  }) =>
      ListView.builder(
          padding: tilePadding,
          physics: physics,
          itemCount: itemCount ?? groups.length,
          shrinkWrap: true,
          itemBuilder: (BuildContext context, int index) {
            return fade(
                key: ValueKey(groups[index].id),
                fade: groups[index].fade,
                onEnd: () {
                  groups[index].fade = Fade.none;
                },
                child: Tiles.navDrawerGroupTile(
                    context: context, group: groups[index]));
          });

  static Widget reorderableSubtasks({
    Key? key,
    required BuildContext context,
    required List<Subtask> subtasks,
    int? itemCount,
    ScrollPhysics physics = const NeverScrollableScrollPhysics(),
    required void Function(int oldIndex, int newIndex) onReorder,
    required void Function({bool? value, Subtask? subtask}) onChanged,
    void Function({Subtask? subtask})? onTap,
    void Function({Subtask? subtask})? onRemoved,
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
                delay: Constants.dragDelayTime,
                index: index,
                key: ValueKey(subtasks[index].id),
                child: fade(
                  key: ValueKey(subtasks[index].id),
                  onEnd: () {
                    subtasks[index].fade = Fade.none;
                  },
                  fade: subtasks[index].fade,
                  child: Tiles.subtaskCheckboxTile(
                    index: index,
                    subtask: subtasks[index],
                    onTap: (null != onTap)
                        ? () => onTap(subtask: subtasks[index])
                        : null,
                    onChanged: (value) =>
                        onChanged(value: value, subtask: subtasks[index]),
                    onRemoved: (null != onRemoved)
                        ? () => onRemoved(subtask: subtasks[index])
                        : null,
                    showHandle: subtasks.length > 1,
                  ),
                ));
          });

  static Widget trashList({
    Key? key,
    required List<IModel> models,
    ScrollPhysics physics = const NeverScrollableScrollPhysics(),
    void Function({required IModel model})? restoreModel,
    void Function({required IModel model})? deleteModel,
    void Function({required IModel model})? onTap,
    Future<void> Function({IModel? item})? onRemove,
    EdgeInsets listPadding = EdgeInsets.zero,
    bool smallScreen = false,
    bool showCategory = false,
  }) =>
      ListView.builder(
          key: key,
          padding: listPadding,
          shrinkWrap: true,
          physics: physics,
          itemCount: models.length,
          itemBuilder: (BuildContext context, int index) {
            return fade(
              key: ValueKey(models[index].id),
              onEnd: () {
                models[index].fade = Fade.none;
              },
              fade: models[index].fade,
              child: Tiles.trashTile(
                context: context,
                model: models[index],
                showCategory: showCategory,
                smallScreen: smallScreen,
                onRemove: onRemove,
                onTap:
                    (null != onTap) ? () => onTap(model: models[index]) : null,
                restoreModel: (null != restoreModel)
                    ? () => restoreModel(model: models[index])
                    : null,
                deleteModel: (null != deleteModel)
                    ? () => deleteModel(model: models[index])
                    : null,
              ),
            );
          });

  static Widget eventList({
    required ValueListenable<List<CalendarEvent>> selectedEvents,
    bool smallScreen = false,
    EdgeInsets listPadding = EdgeInsets.zero,
  }) =>
      ValueListenableBuilder<List<CalendarEvent>>(
          valueListenable: selectedEvents,
          builder:
              (BuildContext context, List<CalendarEvent> value, Widget? child) {
            return ListView.builder(
                physics: const NeverScrollableScrollPhysics(),
                padding: listPadding,
                shrinkWrap: true,
                itemCount: value.length,
                itemBuilder: (BuildContext context, int index) {
                  return fade(
                    key: ValueKey(value[index].model.id),
                    fade: value[index].model.fade,
                    onEnd: () {
                      value[index].model.fade = Fade.none;
                    },
                    child: Tiles.eventTile(
                      event: value[index],
                      context: context,
                      smallScreen: smallScreen,
                    ),
                  );
                });
          });
}
