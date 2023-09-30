import 'package:allocate/ui/widgets/tiles.dart';
import 'package:flutter/material.dart';

import '../../model/task/subtask.dart';

class ListViews {
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
