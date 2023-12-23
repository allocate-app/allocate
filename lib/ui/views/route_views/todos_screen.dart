import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../model/task/todo.dart';
import '../../../providers/group_provider.dart';
import '../../../providers/todo_provider.dart';
import '../../../util/constants.dart';
import '../../../util/enums.dart';
import '../../widgets/listview_header.dart';
import '../../widgets/listviews.dart';
import '../../widgets/paginating_listview.dart';
import '../../widgets/tiles.dart';
import '../sub_views/create_todo.dart';

class ToDosListScreen extends StatefulWidget {
  const ToDosListScreen({Key? key}) : super(key: key);

  @override
  State<ToDosListScreen> createState() => _ToDosListScreen();
}

class _ToDosListScreen extends State<ToDosListScreen> {
  late bool checkDelete;

  late final ToDoProvider toDoProvider;
  late final GroupProvider groupProvider;

  // DB is too fast.

  @override
  void initState() {
    super.initState();
    initializeProviders();
    initializeParameters();
  }

  void initializeProviders() {
    toDoProvider = Provider.of<ToDoProvider>(context, listen: false);
    groupProvider = Provider.of<GroupProvider>(context, listen: false);
  }

  void initializeParameters() {
    checkDelete = true;
  }

  ValueKey<int> getAnimationKey() {
    return ValueKey(
        (toDoProvider.toDos.length + toDoProvider.sorter.sortMethod.index) *
            ((toDoProvider.sorter.descending) ? -1 : 1));
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    bool largeScreen = (width >= Constants.largeScreen);
    bool smallScreen = (width <= Constants.smallScreen);

    return Padding(
      padding: const EdgeInsets.all(Constants.innerPadding),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        ListViewHeader<ToDo>(
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
          context: context,
          onTap: () async => await showDialog(
            barrierDismissible: false,
            context: context,
            builder: (BuildContext context) => const CreateToDoScreen(),
          ),
        ),
        Flexible(
          child: PaginatingListview<ToDo>(
              getAnimationKey: getAnimationKey,
              items: toDoProvider.toDos,
              query: toDoProvider.getToDosBy,
              offset: (toDoProvider.rebuild) ? 0 : toDoProvider.toDos.length,
              limit: 3,
              rebuildNotifiers: [toDoProvider, groupProvider],
              rebuildCallback: ({required List<ToDo> items}) {
                toDoProvider.toDos = items;
                toDoProvider.rebuild = false;
              },
              paginateButton: false,
              listviewBuilder: (
                  {Key? key,
                  required BuildContext context,
                  required List<ToDo> items}) {
                if (toDoProvider.sortMethod == SortMethod.none) {
                  return ListViews.reorderableToDos(
                    key: key,
                    context: context,
                    toDos: items,
                    checkDelete: checkDelete,
                    checkboxAnimateBeforeUpdate: (
                        {required ToDo toDo, required int index}) async {
                      if (mounted) {
                        setState(() {
                          items[index] = toDo;
                        });
                      }
                      return await Future.delayed(const Duration(
                          milliseconds: Constants.checkboxAnimationTime));
                    },
                    smallScreen: smallScreen,
                  );
                }
                return ListViews.immutableToDos(
                  key: key,
                  context: context,
                  toDos: items,
                  checkDelete: checkDelete,
                  checkboxAnimateBeforeUpdate: (
                      {required ToDo toDo, required int index}) async {
                    if (mounted) {
                      setState(() {
                        items[index] = toDo;
                      });
                    }
                    return await Future.delayed(const Duration(
                        milliseconds: Constants.checkboxAnimationTime));
                  },
                  smallScreen: smallScreen,
                );
              }),
        ),
      ]),
    );
  }
}
