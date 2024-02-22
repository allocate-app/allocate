import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../model/task/todo.dart';
import '../../../providers/application/layout_provider.dart';
import '../../../providers/model/group_provider.dart';
import '../../../providers/model/todo_provider.dart';
import '../../../util/constants.dart';
import '../../../util/enums.dart';
import '../../widgets/listviews.dart';
import '../../widgets/paginating_listview.dart';

class MyDayToDos extends StatefulWidget {
  const MyDayToDos({super.key});

  @override
  State<MyDayToDos> createState() => _MyDayToDos();
}

class _MyDayToDos extends State<MyDayToDos> {
  late final ToDoProvider toDoProvider;
  late final LayoutProvider layoutProvider;
  late final GroupProvider groupProvider;

  @override
  void initState() {
    super.initState();
    initializeProviders();
  }

  void initializeProviders() {
    toDoProvider = Provider.of<ToDoProvider>(context, listen: false);

    layoutProvider = Provider.of<LayoutProvider>(context, listen: false);
    groupProvider = Provider.of<GroupProvider>(context, listen: false);
  }

  @override
  void dispose() {
    super.dispose();
  }

  void onFetch({List<ToDo>? items}) {
    if (null == items) {
      return;
    }
    DateTime threshold = DateTime.now();
    threshold = threshold.copyWith(
        millisecond: threshold.millisecond - Constants.newItemThreshold);
    for (ToDo toDo in items) {
      if (!toDo.lastUpdated.isBefore(threshold)) {
        toDo.fade = Fade.fadeIn;
      }
    }
  }

  void onAppend({List<ToDo>? items}) {
    if (null == items) {
      return;
    }
    for (ToDo toDo in items) {
      toDo.fade = Fade.fadeIn;
    }
  }

  Future<void> onRemove({ToDo? item}) async {
    if (null == item) {
      return;
    }

    if (toDoProvider.toDos.length < 2) {
      return;
    }

    if (mounted) {
      setState(() => item.fade = Fade.fadeOut);
      await Future.delayed(const Duration(milliseconds: Constants.fadeOutTime));
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: PaginatingListview<ToDo>(
                  items: toDoProvider.toDos,
                  query: toDoProvider.getMyDay,
                  offset:
                      (toDoProvider.rebuild) ? 0 : toDoProvider.toDos.length,
                  limit: Constants.minLimitPerQuery,
                  getAnimationKey: (toDoProvider.userViewModel?.reduceMotion ??
                          false)
                      ? null
                      : () => ValueKey(toDoProvider.sorter.sortMethod.index *
                              (toDoProvider.sorter.descending ? -1 : 1) +
                          (toDoProvider.toDos.isEmpty ? 0 : 1)),
                  rebuildNotifiers: [toDoProvider, groupProvider],
                  rebuildCallback: ({required List<ToDo> items}) {
                    toDoProvider.toDos = items;
                    toDoProvider.softRebuild = false;
                    groupProvider.softRebuild = false;
                  },
                  onFetch: (toDoProvider.userViewModel?.reduceMotion ?? false)
                      ? null
                      : onFetch,
                  onRemove: (toDoProvider.userViewModel?.reduceMotion ?? false)
                      ? null
                      : onRemove,
                  onAppend: (toDoProvider.userViewModel?.reduceMotion ?? false)
                      ? null
                      : onAppend,
                  listviewBuilder: (
                      {Key? key,
                      required BuildContext context,
                      required List<ToDo> items,
                      Future<void> Function({ToDo? item})? onRemove}) {
                    if (toDoProvider.sortMethod == SortMethod.none) {
                      return ListViews.reorderableMyDay(
                        key: key,
                        listPadding: Constants.fabPadding,
                        context: context,
                        toDos: items,
                        smallScreen: layoutProvider.smallScreen,
                        onRemove: onRemove,
                      );
                    }
                    return ListViews.immutableMyDay(
                      key: key,
                      listPadding: Constants.fabPadding,
                      toDos: items,
                      smallScreen: layoutProvider.smallScreen,
                      onRemove: onRemove,
                    );
                  }),
            ),
          ],
        );
      },
    );
  }
}
