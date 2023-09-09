import 'package:allocate/ui/views/sub_views.dart';
import 'package:another_flushbar/flushbar.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../model/task/todo.dart';
import '../../../providers/todo_provider.dart';
import '../../../util/constants.dart';
import '../../../util/enums.dart';
import '../../../util/exceptions.dart';
import '../../../util/numbers.dart';
import '../../../util/sorting/todo_sorter.dart';
import '../../widgets/flushbars.dart';

// TODO: Refactor checkbox listtile and build from scratch

// TODO: Migrate checkbox listtile to updateGroup, createGroup && Completed.
// Must needs be clean.

class ToDosListScreen extends StatefulWidget {
  const ToDosListScreen({Key? key}) : super(key: key);

  @override
  State<ToDosListScreen> createState() => _ToDosListScreen();
}

class _ToDosListScreen extends State<ToDosListScreen> {
  late bool checkDelete;
  late bool allData;
  late bool loading;
  late int offset;

  late final ToDoProvider toDoProvider;

  // For linked todos.
  late final ScrollController mainScrollController;
  late final ScrollPhysics scrollPhysics;

  // For Task search.
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

    toDoProvider.addListener(resetPagination);
  }

  void initializeParameters() {
    loading = toDoProvider.rebuild;
    allData = false;
    checkDelete = true;
    offset = (toDoProvider.rebuild) ? 0 : toDoProvider.toDos.length;
    searchHistory = List.empty(growable: true);
  }

  void initializeControllers() {
    searchController = SearchController();
    mainScrollController = ScrollController();

    mainScrollController.addListener(() async {
      // Bottom: Run the query.
      if (mainScrollController.offset >=
              mainScrollController.position.maxScrollExtent &&
          !allData) {
        if (!loading && mounted) {
          setState(() => loading = true);
          await fetchData();
        }
      }
    });

    scrollPhysics =
        const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics());
  }

  Widget getArrowDirection({required SortMethod method}) {
    if (toDoProvider.sortMethod == SortMethod.none) {
      return const SizedBox.shrink();
    }

    if (toDoProvider.sortMethod == method && !toDoProvider.descending) {
      return const Icon(Icons.arrow_downward_rounded);
    }

    return const Icon(Icons.arrow_upward_rounded);
  }

  Future<void> fetchData() async {
    setState(() => loading = true);
    return Future.delayed(
        const Duration(seconds: 1),
        () async => await toDoProvider
                .getToDosBy(limit: Constants.limitPerQuery, offset: offset)
                .then((newToDos) {
              offset += newToDos.length;
              toDoProvider.toDos.addAll(newToDos);
              allData = newToDos.length < Constants.limitPerQuery;
              if (mounted) {
                setState(() {
                  loading = false;
                });
              }
            }).catchError(
              (e) {
                Flushbar? error;

                error = Flushbars.createError(
                  message: e.cause ?? "Error with retrieval",
                  context: context,
                  dismissCallback: () => error?.dismiss(),
                );

                error.show(context);
              },
            ));
  }

  Future<void> resetPagination() async {
    setState(() {
      offset = 0;
      toDoProvider.toDos.clear();
    });
    return await fetchData();
  }

  // Grab search from todos scrn.

  @override
  void dispose() {
    toDoProvider.removeListener(resetPagination);
    super.dispose();
  }

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
    bool largeScreen =
        (MediaQuery.of(context).size.width >= Constants.largeScreen);
    bool smallScreen =
        (MediaQuery.of(context).size.width <= Constants.smallScreen);

    return Padding(
      padding: const EdgeInsets.all(Constants.innerPadding),
      child: Column(children: [
        Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Expanded(
                child: AutoSizeText("Tasks",
                    style: Constants.largeHeaderStyle,
                    softWrap: false,
                    maxLines: 1,
                    overflow: TextOverflow.visible,
                    minFontSize: Constants.large),
              ),
              const Icon(Icons.swap_vert_rounded, size: Constants.smIconSize),
              DropdownButtonHideUnderline(
                child: DropdownButton<SortMethod>(
                    padding: const EdgeInsets.symmetric(
                        horizontal: Constants.padding),
                    value: toDoProvider.sortMethod,
                    icon: (toDoProvider.sortMethod != SortMethod.none)
                        ? (toDoProvider.descending)
                            ? const Icon(Icons.arrow_downward_rounded)
                            : const Icon(Icons.arrow_upward_rounded)
                        : null,
                    borderRadius: const BorderRadius.all(
                        Radius.circular(Constants.roundedCorners)),
                    onChanged: (method) {
                      if (null != method) {
                        // TODO: When user, add in.
                        // ALSO: CHANGE PROXY PROVIDER.
                        // SHOULD JUST BE AT START && SAVE ACCORDINGLY.
                        setState(() {
                          toDoProvider.sortMethod = method;
                        });
                      }
                    },
                    items: ToDoSorter.sortMethods
                        .map<DropdownMenuItem<SortMethod>>(
                            (method) => DropdownMenuItem<SortMethod>(
                                  value: method,
                                  child: Padding(
                                    padding:
                                        const EdgeInsets.all(Constants.padding),
                                    child: Text(
                                      toBeginningOfSentenceCase(
                                          method.name.replaceAll("_", " "))!,
                                    ),
                                  ),
                                ))
                        .toList(growable: false)),
              ),
            ]),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: Constants.padding),
          child: ListTile(
            shape: const RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.all(Radius.circular(Constants.roundedCorners)),
            ),
            onTap: () async => await showDialog(
              barrierDismissible: false,
              context: context,
              builder: (BuildContext context) => const CreateToDoScreen(),
            ),
            leading: CircleAvatar(
              child: Icon(Icons.add_outlined,
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            title: const AutoSizeText(
              "Create New",
              overflow: TextOverflow.visible,
              softWrap: false,
              maxLines: 1,
              minFontSize: Constants.medium,
            ),
          ),
        ),
        Flexible(
          child: (loading)
              ? const CircularProgressIndicator()
              : buildToDosList(
                  smallScreen: smallScreen, physics: scrollPhysics),
        ),
      ]),
    );
  }

  ListView buildToDosList(
      {bool smallScreen = false,
      ScrollPhysics physics = const BouncingScrollPhysics()}) {
    return ListView(
        controller: mainScrollController,
        physics: physics,
        shrinkWrap: true,
        children: [
          Consumer<ToDoProvider>(
            builder: (BuildContext context, ToDoProvider value, Widget? child) {
              if (value.sortMethod == SortMethod.none) {
                return buildReorderable(
                    provider: value,
                    context: context,
                    smallScreen: smallScreen);
              }
              return buildImmutable(
                  provider: value, context: context, smallScreen: smallScreen);
            },
          ),
          (loading)
              ? const Padding(
                  padding: EdgeInsets.all(Constants.padding),
                  child: Center(child: CircularProgressIndicator()),
                )
              : const SizedBox.shrink()
        ]);
  }

  ReorderableListView buildReorderable(
      {required ToDoProvider provider,
      required BuildContext context,
      bool smallScreen = false}) {
    return ReorderableListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: provider.toDos.length,
        onReorder: (int oldIndex, int newIndex) async {
          provider.toDos = await provider
              .reorderToDos(
            oldIndex: oldIndex,
            newIndex: newIndex,
          )
              .catchError((e) {
            Flushbar? error;

            error = Flushbars.createError(
              message: e.cause,
              context: context,
              dismissCallback: () => error?.dismiss(),
            );

            error.show(context);
            return List<ToDo>.empty(growable: true);
          },
                  test: (e) =>
                      e is FailureToCreateException ||
                      e is FailureToUploadException);
          if (provider.toDos.isEmpty) {
            resetPagination();
          }
        },
        itemBuilder: (BuildContext context, int index) {
          return buildToDoListTile(
              index: index,
              smallScreen: smallScreen,
              provider: provider,
              context: context);
        });
  }

  ListView buildImmutable(
      {required ToDoProvider provider,
      required BuildContext context,
      bool smallScreen = false}) {
    return ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: provider.toDos.length,
        itemBuilder: (BuildContext context, int index) {
          return buildToDoListTile(
              index: index,
              smallScreen: smallScreen,
              provider: provider,
              context: context);
        });
  }

  ListTile buildToDoListTile(
      {required int index,
      bool smallScreen = false,
      required ToDoProvider provider,
      required BuildContext context}) {
    return ListTile(
        key: ValueKey(index),
        shape: const RoundedRectangleBorder(
            borderRadius:
                BorderRadius.all(Radius.circular(Constants.roundedCorners))),
        leading: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: Constants.innerPadding),
          child: Transform.scale(
              scale: (smallScreen)
                  ? Constants.largeCheckboxMinScale
                  : Constants.largeCheckboxScale,
              child: Checkbox(
                  shape: const CircleBorder(),
                  splashRadius: 15,
                  value: provider.toDos[index].completed,
                  onChanged: (bool? completed) async {
                    provider.curToDo = provider.toDos[index];
                    provider.curToDo!.completed = completed!;
                    await provider.updateToDo().catchError((e) {
                      Flushbar? error;

                      error = Flushbars.createError(
                        message: e.cause,
                        context: context,
                        dismissCallback: () => error?.dismiss(),
                      );

                      error.show(context);
                    },
                        test: (e) =>
                            e is FailureToCreateException ||
                            e is FailureToUploadException);
                  })),
        ),
        title: AutoSizeText(provider.toDos[index].name,
            overflow: TextOverflow.visible,
            style: Constants.headerStyle,
            minFontSize: Constants.medium,
            softWrap: true,
            maxLines: 1),
        onTap: () async {
          provider.curToDo = provider.toDos[index];
          await showDialog(
                  barrierDismissible: false,
                  useRootNavigator: false,
                  context: context,
                  builder: (BuildContext context) => const UpdateToDoScreen())
              .catchError((e) {
            Flushbar? error;

            error = Flushbars.createError(
              message: e.cause,
              context: context,
              dismissCallback: () => error?.dismiss(),
            );

            error.show(context);
          },
                  test: (e) =>
                      e is FailureToCreateException ||
                      e is FailureToUploadException);
        },
        trailing: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: Constants.innerPadding),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: Constants.padding),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      getBatteryIcon(toDo: provider.toDos[index]),
                      AutoSizeText(
                        "${provider.toDos[index].weight}",
                        overflow: TextOverflow.visible,
                        minFontSize: Constants.large,
                        softWrap: false,
                        maxLines: 1,
                      ),
                    ],
                  )),
              IconButton(
                  icon: const Icon(Icons.delete_forever),
                  onPressed: () async {
                    // TODO: Modal for delete with checkDelete;
                    // Factor out into a method.
                    provider.curToDo = provider.toDos[index];

                    await provider.deleteToDo().catchError((e) {
                      Flushbar? error;

                      error = Flushbars.createError(
                        message: e.cause,
                        context: context,
                        dismissCallback: () => error?.dismiss(),
                      );

                      error.show(context);
                    },
                        test: (e) =>
                            e is FailureToDeleteException ||
                            e is FailureToUploadException);
                  }),
            ],
          ),
        ));
  }
}
