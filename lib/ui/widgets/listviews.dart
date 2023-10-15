import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../model/task/routine.dart';
import '../../model/task/subtask.dart';
import '../../model/task/todo.dart';
import '../../providers/group_provider.dart';
import '../../providers/routine_provider.dart';
import '../../providers/todo_provider.dart';
import 'tiles.dart';

// TODO: Implement crossfade
class ListViews {
  static reorderableToDos({
    required BuildContext context,
    required List<ToDo> toDos,
    bool checkDelete = false,
    Future<void> Function({required ToDo toDo, required int index})?
        checkboxAnimateBeforeUpdate,
    ScrollPhysics physics = const NeverScrollableScrollPhysics(),
  }) =>
      ReorderableListView.builder(
          buildDefaultDragHandles: false,
          physics: physics,
          shrinkWrap: true,
          onReorder: (int oldIndex, int newIndex) async =>
              await Provider.of<ToDoProvider>(context, listen: false)
                  .reorderToDos(oldIndex: oldIndex, newIndex: newIndex),
          itemCount: toDos.length,
          itemBuilder: (BuildContext context, int index) {
            return Tiles.toDoListTile(
              checkboxAnimateBeforeUpdate: checkboxAnimateBeforeUpdate,
              context: context,
              index: index,
              toDo: toDos[index],
              showHandle: toDos.length > 1,
              checkDelete: checkDelete,
            );
          });

  static immutableToDos({
    required BuildContext context,
    required List<ToDo> toDos,
    bool checkDelete = false,
    Future<void> Function({required ToDo toDo, required int index})?
        checkboxAnimateBeforeUpdate,
    ScrollPhysics physics = const NeverScrollableScrollPhysics(),
  }) =>
      ListView.builder(
          physics: physics,
          shrinkWrap: true,
          itemCount: toDos.length,
          itemBuilder: (BuildContext context, int index) {
            return Tiles.toDoListTile(
              checkboxAnimateBeforeUpdate: checkboxAnimateBeforeUpdate,
              context: context,
              index: index,
              toDo: toDos[index],
              showHandle: false,
              checkDelete: checkDelete,
            );
          });

  static reorderableRoutines({
    required BuildContext context,
    required List<Routine> routines,
    bool checkDelete = false,
    ScrollPhysics physics = const NeverScrollableScrollPhysics(),
  }) =>
      ReorderableListView.builder(
          buildDefaultDragHandles: false,
          physics: physics,
          shrinkWrap: true,
          onReorder: (int oldIndex, int newIndex) async =>
              await Provider.of<RoutineProvider>(context, listen: false)
                  .reorderRoutines(oldIndex: oldIndex, newIndex: newIndex),
          itemCount: routines.length,
          itemBuilder: (BuildContext context, int index) {
            return Tiles.routineListTile(
              context: context,
              index: index,
              routine: routines[index],
              showHandle: routines.length > 1,
              checkDelete: checkDelete,
            );
          });

  static immutableRoutines({
    required BuildContext context,
    required List<Routine> routines,
    bool checkDelete = false,
    ScrollPhysics physics = const NeverScrollableScrollPhysics(),
  }) =>
      ListView.builder(
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

  static reorderableGroupToDos({
    required BuildContext context,
    required List<ToDo> toDos,
    ScrollPhysics physics = const NeverScrollableScrollPhysics(),
    required Future<void> Function({required int index, bool value}) onChanged,
    required Future<void> Function({required int index}) onTap,
    required void Function({required int index}) handleRemove,
  }) =>
      ReorderableListView.builder(
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
        itemBuilder: (BuildContext context, int index) => Tiles.toDoCheckTile(
          index: index,
          toDo: toDos[index],
          showHandle: (toDos.length > 1),
          onChanged: onChanged,
          onTap: onTap,
          handleRemove: handleRemove,
        ),
      );

  static reorderableSubtasks({
    required BuildContext context,
    required List<SubTask> subTasks,
    required List<TextEditingController> controllers,
    int? itemCount,
    ScrollPhysics physics = const NeverScrollableScrollPhysics(),
    required void Function() onChanged,
    required void Function() onSubtaskWeightChanged,
    required void Function(int oldIndex, int newIndex) onReorder,
    required void Function({required int index}) onRemoved,
    EdgeInsetsGeometry contentPadding = EdgeInsets.zero,
    bool showHandle = false,
  }) =>
      ReorderableListView.builder(
          buildDefaultDragHandles: false,
          physics: physics,
          shrinkWrap: true,
          itemCount: itemCount ?? subTasks.length,
          onReorderStart: (_) {
            FocusScope.of(context).unfocus();
          },
          onReorder: onReorder,
          itemBuilder: (BuildContext context, int index) {
            return Tiles.subtaskCheckboxTile(
              context: context,
              index: index,
              subTask: subTasks[index],
              onChanged: onChanged,
              onSubtaskWeightChanged: onSubtaskWeightChanged,
              controller: controllers[index],
              onRemoved: onRemoved,
              showHandle: showHandle,
            );
          });
}
