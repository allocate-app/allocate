import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../model/task/todo.dart';
import '../../../providers/application/layout_provider.dart';
import '../../../providers/model/group_provider.dart';
import '../../../providers/model/todo_provider.dart';
import '../../../util/constants.dart';
import '../../../util/enums.dart';
import '../../blurred_dialog.dart';
import '../../widgets/listview_header.dart';
import '../../widgets/listviews.dart';
import '../../widgets/paginating_listview.dart';
import '../../widgets/tiles.dart';
import '../sub_views/create_todo.dart';

class ToDosListScreen extends StatefulWidget {
  const ToDosListScreen({super.key});

  @override
  State<ToDosListScreen> createState() => _ToDosListScreen();
}

class _ToDosListScreen extends State<ToDosListScreen> {
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
        return Padding(
          padding: const EdgeInsets.all(Constants.padding),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            ListViewHeader<ToDo>(
                outerPadding: const EdgeInsets.all(Constants.padding),
                header: "Tasks",
                sorter: toDoProvider.sorter,
                leadingIcon: const Icon(Icons.task_outlined),
                onChanged: ({SortMethod? sortMethod}) {
                  if (null == sortMethod) {
                    return;
                  }
                  if (mounted) {
                    setState(() {
                      toDoProvider.sortMethod = sortMethod;
                    });
                  }
                }),
            Tiles.createNew(
              outerPadding:
                  const EdgeInsets.symmetric(vertical: Constants.halfPadding),
              context: context,
              onTap: () async => await blurredNonDismissible(
                  context: context, dialog: const CreateToDoScreen()),
              // await showDialog(
              //   useRootNavigator: false,
              //   barrierDismissible: false,
              //   context: context,
              //   builder: (BuildContext context) => const CreateToDoScreen(),
              // ),
            ),
            Flexible(
              child: PaginatingListview<ToDo>(
                  items: toDoProvider.toDos,
                  query: toDoProvider.getToDosBy,
                  offset:
                      (toDoProvider.rebuild) ? 0 : toDoProvider.toDos.length,
                  limit: Constants.minLimitPerQuery,
                  rebuildNotifiers: [toDoProvider, groupProvider],
                  rebuildCallback: ({required List<ToDo> items}) {
                    toDoProvider.toDos = items;
                    toDoProvider.softRebuild = false;
                  },
                  getAnimationKey: (toDoProvider.userViewModel?.reduceMotion ??
                          false)
                      ? null
                      : () => ValueKey(toDoProvider.sorter.sortMethod.index *
                              (toDoProvider.sorter.descending ? -1 : 1) +
                          (toDoProvider.toDos.isEmpty ? 0 : 1)),
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
                      return ListViews.reorderableToDos(
                        key: key,
                        listPadding: Constants.fabPadding,
                        context: context,
                        toDos: items,
                        checkDelete:
                            toDoProvider.userViewModel?.checkDelete ?? true,
                        onRemove: onRemove,
                        checkboxAnimateBeforeUpdate: (
                            {required ToDo toDo, required int index}) async {
                          if (mounted) {
                            setState(() {});
                          }
                          await Future.delayed(const Duration(
                              milliseconds: Constants.animationDelay));
                          if (null != onRemove) {
                            await onRemove(item: toDo);
                          }
                        },
                        smallScreen: layoutProvider.smallScreen,
                      );
                    }
                    return ListViews.immutableToDos(
                      key: key,
                      listPadding: Constants.fabPadding,
                      toDos: items,
                      checkDelete:
                          toDoProvider.userViewModel?.checkDelete ?? true,
                      onRemove: onRemove,
                      checkboxAnimateBeforeUpdate: (
                          {required ToDo toDo, required int index}) async {
                        if (mounted) {
                          setState(() {});
                        }
                        await Future.delayed(const Duration(
                            milliseconds: Constants.animationDelay));
                        if (null != onRemove) {
                          await onRemove(item: toDo);
                        }
                      },
                      smallScreen: layoutProvider.smallScreen,
                    );
                  }),
            ),
          ]),
        );
      },
    );
  }
}
