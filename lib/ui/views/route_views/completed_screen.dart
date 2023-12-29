import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../model/task/todo.dart';
import '../../../providers/group_provider.dart';
import '../../../providers/todo_provider.dart';
import '../../../providers/user_provider.dart';
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
  late final UserProvider userProvider;

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
    if (toDoProvider.rebuild) {
      toDoProvider.toDos = [];
    }
    groupProvider = Provider.of<GroupProvider>(context, listen: false);
    userProvider = Provider.of<UserProvider>(context, listen: false);
  }

  void onFetch({List<ToDo>? items}) {
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
    return Padding(
      padding: const EdgeInsets.all(Constants.innerPadding),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        ListViewHeader<ToDo>(
            header: "Completed",
            sorter: toDoProvider.sorter,
            leadingIcon: const Icon(Icons.check_circle_outline_rounded),
            outerPadding: const EdgeInsets.only(bottom: Constants.padding),
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
              offset: (toDoProvider.rebuild) ? 0 : toDoProvider.toDos.length,
              limit: Constants.minLimitPerQuery,
              rebuildNotifiers: [toDoProvider, groupProvider],
              rebuildCallback: ({required List<ToDo> items}) {
                toDoProvider.toDos = items;
                toDoProvider.rebuild = false;
                groupProvider.rebuild = false;
              },
              onFetch: (userProvider.curUser?.reduceMotion ?? false)
                  ? null
                  : onFetch,
              onRemove: (userProvider.curUser?.reduceMotion ?? false)
                  ? null
                  : onRemove,
              getAnimationKey: () => ValueKey(
                  toDoProvider.sorter.sortMethod.index *
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
                    context: context,
                    toDos: items,
                    checkDelete: userProvider.curUser?.checkDelete ?? true,
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
                    smallScreen: userProvider.smallScreen,
                  );
                }
                return ListViews.immutableToDos(
                  key: key,
                  context: context,
                  toDos: items,
                  checkDelete: userProvider.curUser?.checkDelete ?? true,
                  onRemove: onRemove,
                  checkboxAnimateBeforeUpdate: (
                      {required ToDo toDo, required int index}) async {
                    if (mounted) {
                      setState(() {
                        items[index] = toDo;
                      });
                    }
                    await Future.delayed(
                        const Duration(milliseconds: Constants.animationDelay));
                    if (null != onRemove) {
                      await onRemove(item: toDo);
                    }
                  },
                  smallScreen: userProvider.smallScreen,
                );
              }),
        ),
      ]),
    );
  }
}
