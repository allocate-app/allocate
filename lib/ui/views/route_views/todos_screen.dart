import 'dart:math';

import 'package:another_flushbar/flushbar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../model/task/todo.dart';
import '../../../providers/group_provider.dart';
import '../../../providers/todo_provider.dart';
import '../../../util/constants.dart';
import '../../../util/enums.dart';
import '../../../util/numbers.dart';
import '../../widgets/flushbars.dart';
import '../../widgets/listview_header.dart';
import '../../widgets/listviews.dart';
import '../../widgets/tiles.dart';
import '../sub_views/create_todo.dart';

class ToDosListScreen extends StatefulWidget {
  const ToDosListScreen({Key? key}) : super(key: key);

  @override
  State<ToDosListScreen> createState() => _ToDosListScreen();
}

class _ToDosListScreen extends State<ToDosListScreen> {
  late bool checkDelete;
  late bool allData;
  late bool showTopLoading;
  late bool loading;
  late int limit;
  late int offset;

  late final ToDoProvider toDoProvider;
  late final GroupProvider groupProvider;

  // For linked todos.
  late final ScrollController mainScrollController;
  late final ScrollPhysics scrollPhysics;

  // For Task search. -- Factor out.
  late final SearchController searchController;
  late List<MapEntry<String, int>> searchHistory;

  @override
  void initState() {
    super.initState();
    initializeProviders();
    initializeParameters();
    initializeControllers();

    if (toDoProvider.rebuild) {
      resetPagination();
      toDoProvider.rebuild = false;
    }
  }

  void initializeProviders() {
    toDoProvider = Provider.of<ToDoProvider>(context, listen: false);
    groupProvider = Provider.of<GroupProvider>(context, listen: false);

    toDoProvider.addListener(resetPagination);
  }

  void initializeParameters() {
    loading = toDoProvider.rebuild;
    showTopLoading = toDoProvider.rebuild;
    allData = false;
    checkDelete = true;
    offset = (toDoProvider.rebuild) ? 0 : toDoProvider.toDos.length;
    limit = Constants.minLimitPerQuery;
  }

  void initializeControllers() {
    mainScrollController = ScrollController();

    mainScrollController.addListener(() async {
      // Bottom: Run the query and append data.
      if (mainScrollController.offset >=
              mainScrollController.position.maxScrollExtent -
                  Constants.loadOffset &&
          !allData) {
        if (!loading && mounted) {
          return await appendData();
        }
      }

      // Top: Run the query and overwrite data.
      if (mainScrollController.offset <=
          mainScrollController.position.minScrollExtent) {
        if (!loading && mounted) {
          return await resetPagination();
        }
      }
    });

    scrollPhysics =
        const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics());
  }

  @override
  void dispose() {
    mainScrollController.dispose();
    toDoProvider.removeListener(resetPagination);
    super.dispose();
  }

  Future<void> resetPagination() async {
    offset = 0;
    limit = max(toDos.length, Constants.minLimitPerQuery);
    return await overwriteData();
  }

  Future<void> overwriteData() async {
    if (mounted) {
      setState(() {
        showTopLoading = true;
      });
    }
    List<ToDo> newToDos = await fetchData();
    if (mounted) {
      return setState(() {
        offset += newToDos.length;
        toDos = newToDos;
        loading = false;
        showTopLoading = false;
        allData = toDos.length <= limit;
        limit = Constants.minLimitPerQuery;
      });
    }
  }

  Future<void> appendData() async {
    List<ToDo> newToDos = await fetchData();
    if (mounted) {
      return setState(() {
        offset += newToDos.length;
        toDos.addAll(newToDos);
        loading = false;
        allData = newToDos.length < limit;
      });
    }
  }

  Future<List<ToDo>> fetchData() async {
    if (mounted) {
      setState(() => loading = true);
    }
    return await toDoProvider
        .getToDosBy(limit: limit, offset: offset)
        .catchError(
      (e) {
        Flushbar? error;

        error = Flushbars.createError(
          message: e.cause ?? "Query Error",
          context: context,
          dismissCallback: () => error?.dismiss(),
        );

        error.show(context);
        return List<ToDo>.empty(growable: true);
      },
    );
  }

  // Factor this out completely pls.
  Widget getArrowDirection({required SortMethod method}) {
    if (toDoProvider.sortMethod == SortMethod.none) {
      return const SizedBox.shrink();
    }

    if (toDoProvider.sortMethod == method && !toDoProvider.descending) {
      return const Icon(Icons.arrow_downward_rounded);
    }

    return const Icon(Icons.arrow_upward_rounded);
  }

  // Convenience accessors.
  List<ToDo> get toDos => toDoProvider.toDos;

  set toDos(List<ToDo> newToDos) => toDoProvider.toDos = newToDos;

  Icon getBatteryIcon({required ToDo toDo}) {
    // Icon is scaled for sum-weight.
    int weight = (toDo.taskType == TaskType.small)
        ? toDo.weight
        : remap(
                x: toDo.weight,
                inMin: 0,
                inMax: Constants.maxWeight,
                outMin: 0,
                outMax: 5)
            .toInt();

    return Constants.batteryIcons[weight]!;
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    bool largeScreen = (width >= Constants.largeScreen);
    bool smallScreen = (width <= Constants.smallScreen);

    return Padding(
      padding: const EdgeInsets.all(Constants.innerPadding),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        ListViewHeader(
            header: "Tasks",
            sorter: toDoProvider.sorter,
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
        Tiles.createNew(
          context: context,
          onTap: () async => await showDialog(
            barrierDismissible: false,
            context: context,
            builder: (BuildContext context) => const CreateToDoScreen(),
          ),
        ),
        Flexible(
          child: Scrollbar(
            thumbVisibility: true,
            controller: mainScrollController,
            child: ListView(
                shrinkWrap: true,
                controller: mainScrollController,
                physics: scrollPhysics,
                children: [
                  // DB is too fast & is causing jarring repaints.
                  // (showTopLoading)
                  //     ? const CircularProgressIndicator()
                  //     : const SizedBox.shrink(),
                  (toDoProvider.sortMethod == SortMethod.none)
                      ? ListViews.reorderableToDos(
                          context: context,
                          toDos: toDos,
                          checkDelete: checkDelete)
                      : ListViews.immutableToDos(
                          context: context,
                          toDos: toDos,
                          checkDelete: checkDelete)
                ]),
          ),
        )
      ]),
    );
  }
}
