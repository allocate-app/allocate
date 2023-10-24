import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../model/task/todo.dart';
import '../../../providers/group_provider.dart';
import '../../../providers/todo_provider.dart';
import '../../../util/constants.dart';
import '../../../util/enums.dart';
import '../../../util/paginator.dart';
import '../../widgets/listview_header.dart';
import '../../widgets/listviews.dart';
import '../../widgets/paginating_listview.dart';

class CompletedListScreen extends StatefulWidget {
  const CompletedListScreen({Key? key}) : super(key: key);

  @override
  State<CompletedListScreen> createState() => _CompletedListScreen();
}

class _CompletedListScreen extends State<CompletedListScreen> {
  late bool checkDelete;

  late Paginator<ToDo> paginator;

  late final ToDoProvider toDoProvider;
  late final GroupProvider groupProvider;

  @override
  void initState() {
    super.initState();
    initializeProviders();
    initializeParameters();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void initializeProviders() {
    toDoProvider = Provider.of<ToDoProvider>(context, listen: false);
    groupProvider = Provider.of<GroupProvider>(context, listen: false);
  }

  void initializeParameters() {
    checkDelete = true;
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
            header: "Completed",
            sorter: toDoProvider.sorter,
            leadingIcon: const Icon(Icons.check_circle_outline_rounded),
            outerPadding: const EdgeInsets.only(bottom: Constants.padding),
            onChanged: (SortMethod? method) {
              if (null == method) {
                return;
              }
              if (mounted) {
                setState(() {
                  toDoProvider.sortMethod = method;
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
              },
              paginateButton: false,
              listviewBuilder: (
                  {required BuildContext context, required List<ToDo> items}) {
                if (toDoProvider.sortMethod == SortMethod.none) {
                  return ListViews.reorderableToDos(
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
