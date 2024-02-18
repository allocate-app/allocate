import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../model/task/todo.dart';
import '../../../providers/application/layout_provider.dart';
import '../../../providers/model/group_provider.dart';
import '../../../providers/model/todo_provider.dart';
import '../../../util/constants.dart';
import '../../../util/enums.dart';
import '../../widgets/listview_header.dart';
import '../../widgets/listviews.dart';
import '../../widgets/paginating_listview.dart';

class CompletedListScreen extends StatefulWidget {
  const CompletedListScreen({super.key});

  @override
  State<CompletedListScreen> createState() => _CompletedListScreen();
}

class _CompletedListScreen extends State<CompletedListScreen> {
  late final ToDoProvider toDoProvider;
  late final GroupProvider groupProvider;
  late final LayoutProvider layoutProvider;

  @override
  void initState() {
    super.initState();
    initializeProviders();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void initializeProviders() {
    toDoProvider = Provider.of<ToDoProvider>(context, listen: false);
    groupProvider = Provider.of<GroupProvider>(context, listen: false);
    layoutProvider = Provider.of<LayoutProvider>(context, listen: false);
  }

  void onFetch({List<ToDo>? items}) {
    if (null == items) {
      return;
    }

    Set<ToDo> itemSet = toDoProvider.toDos.toSet();
    for (ToDo toDo in items) {
      if (!itemSet.contains(toDo)) {
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
                header: "Completed",
                sorter: toDoProvider.sorter,
                leadingIcon: const Icon(Icons.check_circle_outline_rounded),
                outerPadding: const EdgeInsets.all(Constants.padding),
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
            Flexible(
              child: PaginatingListview<ToDo>(
                  items: toDoProvider.toDos,
                  query: toDoProvider.getCompletedToDos,
                  offset:
                      (toDoProvider.rebuild) ? 0 : toDoProvider.toDos.length,
                  limit: Constants.minLimitPerQuery,
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
                  getAnimationKey: (toDoProvider.userViewModel?.reduceMotion ??
                          false)
                      ? null
                      : () => ValueKey(toDoProvider.sorter.sortMethod.index *
                              (toDoProvider.sorter.descending ? -1 : 1) +
                          (toDoProvider.toDos.isEmpty ? 0 : 1)),
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
                            setState(() {
                              items[index] = toDo;
                            });
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
                      listPadding: Constants.fabPadding,
                      key: key,
                      toDos: items,
                      checkDelete:
                          toDoProvider.userViewModel?.checkDelete ?? true,
                      onRemove: onRemove,
                      checkboxAnimateBeforeUpdate: (
                          {required ToDo toDo, required int index}) async {
                        if (mounted) {
                          setState(() {
                            items[index] = toDo;
                          });
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
