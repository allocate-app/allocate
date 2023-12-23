import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../model/task/todo.dart';
import '../../../providers/group_provider.dart';
import '../../../providers/todo_provider.dart';
import '../../../providers/user_provider.dart';
import '../../../util/constants.dart';
import '../../../util/enums.dart';
import '../../widgets/listviews.dart';
import '../../widgets/paginating_listview.dart';

class MyDayToDos extends StatefulWidget {
  const MyDayToDos({Key? key}) : super(key: key);

  @override
  State<MyDayToDos> createState() => _MyDayToDos();
}

class _MyDayToDos extends State<MyDayToDos> {
  late final ToDoProvider toDoProvider;
  late final UserProvider userProvider;
  late final GroupProvider groupProvider;

  @override
  void initState() {
    super.initState();
    initializeProviders();
    initializeParameters();
  }

  void initializeProviders() {
    toDoProvider = Provider.of<ToDoProvider>(context, listen: false);
    userProvider = Provider.of<UserProvider>(context, listen: false);
    groupProvider = Provider.of<GroupProvider>(context, listen: false);
  }

  void initializeParameters() {}

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    bool largeScreen = (width >= Constants.largeScreen);
    bool smallScreen = (width <= Constants.smallScreen);
    bool hugeScreen = (width >= Constants.hugeScreen);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: PaginatingListview<ToDo>(
              items: toDoProvider.toDos,
              query: toDoProvider.getMyDay,
              offset: (toDoProvider.rebuild) ? 0 : toDoProvider.toDos.length,
              limit: Constants.minLimitPerQuery,
              rebuildNotifiers: [toDoProvider, groupProvider],
              rebuildCallback: ({required List<ToDo> items}) {
                toDoProvider.toDos = items;
                toDoProvider.rebuild = false;
                groupProvider.rebuild = false;
              },
              paginateButton: false,
              listviewBuilder: (
                  {Key? key,
                  required BuildContext context,
                  required List<ToDo> items}) {
                if (toDoProvider.sortMethod == SortMethod.none) {
                  return ListViews.reorderableMyDay(
                    key: key,
                    context: context,
                    toDos: items,
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
                return ListViews.immutableMyDay(
                  key: key,
                  context: context,
                  toDos: items,
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
      ],
    );
  }
}
