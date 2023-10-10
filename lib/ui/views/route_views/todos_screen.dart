import 'package:allocate/ui/views/sub_views.dart';
import 'package:another_flushbar/flushbar.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:jiffy/jiffy.dart';
import 'package:provider/provider.dart';

import '../../../model/task/group.dart';
import '../../../model/task/todo.dart';
import '../../../providers/group_provider.dart';
import '../../../providers/todo_provider.dart';
import '../../../util/constants.dart';
import '../../../util/enums.dart';
import '../../../util/exceptions.dart';
import '../../../util/numbers.dart';
import '../../../util/sorting/todo_sorter.dart';
import '../../widgets/flushbars.dart';

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
  late final GroupProvider groupProvider;

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
    groupProvider = Provider.of<GroupProvider>(context, listen: false);

    toDoProvider.addListener(resetPagination);
  }

  void initializeParameters() {
    loading = toDoProvider.rebuild;
    allData = false;
    checkDelete = true;
    offset = (toDoProvider.rebuild) ? 0 : toDoProvider.toDos.length;
  }

  void initializeControllers() {
    mainScrollController = ScrollController();

    mainScrollController.addListener(() async {
      // Bottom: Run the query.
      if (mainScrollController.offset >=
              mainScrollController.position.maxScrollExtent &&
          !allData) {
        if (!loading && mounted) {
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
                .getToDosBy(limit: Constants.minLimitPerQuery, offset: offset)
                .then((newToDos) {
              offset += newToDos.length;
              toDoProvider.toDos.addAll(newToDos);
              allData = newToDos.length < Constants.minLimitPerQuery;
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

  @override
  void dispose() {
    mainScrollController.dispose();
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
        ListTile(
          contentPadding: const EdgeInsets.symmetric(
              horizontal: Constants.innerPadding, vertical: Constants.padding),
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
            child: Icon(Icons.add_rounded,
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
        buildDefaultDragHandles: false,
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
              context: context,
              reorderable: true);
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
              context: context,
              reorderable: false);
        });
  }

// TODO: Refactor this into the tiles factory.
  ListTile buildToDoListTile(
      {required int index,
      bool smallScreen = false,
      required ToDoProvider provider,
      required BuildContext context,
      bool reorderable = false}) {
    return ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: Constants.innerPadding),
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
                    provider.toDos[index].completed = completed!;
                    await provider
                        .updateToDo(toDo: provider.toDos[index])
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
                  })),
        ),
        title: AutoSizeText(provider.toDos[index].name,
            overflow: TextOverflow.visible,
            style: Constants.headerStyle,
            minFontSize: Constants.medium,
            softWrap: true,
            maxLines: 1),
        subtitle: buildSubtitle(toDo: provider.toDos[index]),
        onTap: () async {
          provider.curToDo = provider.toDos[index];
          await showDialog(
              barrierDismissible: false,
              useRootNavigator: false,
              context: context,
              builder: (BuildContext context) => const UpdateToDoScreen());
        },
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
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
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: Constants.innerPadding),
              child: IconButton(
                  icon: const Icon(Icons.delete_forever_rounded),
                  onPressed: () async {
                    if (checkDelete) {
                      return await showDialog<bool?>(
                          barrierDismissible: true,
                          context: context,
                          builder: (BuildContext context) {
                            bool dontAsk = !checkDelete;
                            return StatefulBuilder(
                              builder: (context, setState) => Dialog(
                                  insetPadding: const EdgeInsets.all(
                                      Constants.innerDialogPadding),
                                  child: Padding(
                                    padding: const EdgeInsets.all(
                                        Constants.innerPadding),
                                    child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const Row(
                                              mainAxisSize: MainAxisSize.min,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.start,
                                              children: [
                                                Expanded(
                                                  child: AutoSizeText(
                                                    "Delete Task?",
                                                    style:
                                                        Constants.headerStyle,
                                                    softWrap: true,
                                                    overflow:
                                                        TextOverflow.visible,
                                                    maxLines: 2,
                                                    minFontSize:
                                                        Constants.medium,
                                                  ),
                                                )
                                              ]),
                                          const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Expanded(
                                                child: AutoSizeText(
                                                  "This cannot be undone.",
                                                  style: Constants
                                                      .largeHeaderStyle,
                                                  softWrap: true,
                                                  overflow:
                                                      TextOverflow.visible,
                                                  maxLines: 2,
                                                  minFontSize: Constants.medium,
                                                ),
                                              ),
                                            ],
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                                vertical:
                                                    Constants.innerPadding),
                                            child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Expanded(
                                                    child: Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                              right: Constants
                                                                  .padding),
                                                      child: FilledButton
                                                          .tonalIcon(
                                                              icon: const Icon(Icons
                                                                  .close_outlined),
                                                              onPressed: () {
                                                                Navigator.pop(
                                                                    context,
                                                                    false);
                                                              },
                                                              label: const AutoSizeText(
                                                                  "Cancel",
                                                                  softWrap:
                                                                      false,
                                                                  overflow:
                                                                      TextOverflow
                                                                          .visible,
                                                                  maxLines: 1,
                                                                  minFontSize:
                                                                      Constants
                                                                          .small)),
                                                    ),
                                                  ),
                                                  Expanded(
                                                    child: Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                              left: Constants
                                                                  .padding),
                                                      child: FilledButton.icon(
                                                        icon: const Icon(Icons
                                                            .delete_forever_rounded),
                                                        onPressed: () {
                                                          Navigator.pop(
                                                              context, true);
                                                        },
                                                        label:
                                                            const AutoSizeText(
                                                                "Delete",
                                                                softWrap: false,
                                                                overflow:
                                                                    TextOverflow
                                                                        .visible,
                                                                maxLines: 1,
                                                                minFontSize:
                                                                    Constants
                                                                        .small),
                                                      ),
                                                    ),
                                                  )
                                                ]),
                                          ),
                                          CheckboxListTile(
                                              value: dontAsk,
                                              shape: const RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.all(
                                                      Radius.circular(Constants
                                                          .roundedCorners))),
                                              checkboxShape:
                                                  const CircleBorder(),
                                              title: const AutoSizeText(
                                                "Don't ask me again",
                                                overflow: TextOverflow.visible,
                                                softWrap: false,
                                                maxLines: 1,
                                                minFontSize: Constants.medium,
                                              ),
                                              onChanged: (value) {
                                                // TODO: Factor this into user class pls.
                                                setState(() {
                                                  dontAsk = value!;
                                                  checkDelete = !value;
                                                });
                                              })
                                        ]),
                                  )),
                            );
                          }).then((delete) async {
                        if (delete ?? false) {
                          await handleDelete(
                              provider: provider,
                              index: index,
                              context: context);
                        }
                      });
                    }
                    return await handleDelete(
                        provider: provider, index: index, context: context);
                  }),
            ),
            (reorderable)
                ? ReorderableDragStartListener(
                    index: index, child: const Icon(Icons.drag_handle_rounded))
                : const SizedBox.shrink(),
          ],
        ));
  }

  Future<void> handleDelete(
      {required ToDoProvider provider,
      required int index,
      required BuildContext context}) async {
    await provider.deleteToDo(toDo: provider.toDos[index]).catchError((e) {
      Flushbar? error;

      error = Flushbars.createError(
        message: e.cause,
        context: context,
        dismissCallback: () => error?.dismiss(),
      );

      error.show(context);
    },
        test: (e) =>
            e is FailureToDeleteException || e is FailureToUploadException);
  }

  Widget buildSubtitle({required ToDo toDo}) {
    return Wrap(
        spacing: Constants.halfPadding,
        runSpacing: Constants.halfPadding,
        children: [
          buildGroupName(id: toDo.groupID),
          buildDueDate(dueDate: toDo.dueDate),
          buildPriorityIcon(priority: toDo.priority)
        ]);
  }

  Widget buildGroupName({int? id}) {
    if (null == id) {
      return const SizedBox.shrink();
    }
    return FutureBuilder(
      future: groupProvider.getGroupByID(id: id),
      builder: (BuildContext context, AsyncSnapshot<Group?> snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          Group? group = snapshot.data;
          if (null != group) {
            return DecoratedBox(
              decoration: BoxDecoration(
                  shape: BoxShape.rectangle,
                  borderRadius: const BorderRadius.all(
                      Radius.circular(Constants.roundedCorners)),
                  border: Border.all(
                      color: Theme.of(context).colorScheme.outlineVariant,
                      strokeAlign: BorderSide.strokeAlignOutside)),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: Constants.padding),
                child: AutoSizeText(
                  group.name,
                  minFontSize: Constants.medium,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                  maxLines: 1,
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return const SizedBox.shrink();
        }
        return ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 50),
          child: const LinearProgressIndicator(
            minHeight: Constants.minIconSize,
            borderRadius:
                BorderRadius.all(Radius.circular(Constants.roundedCorners)),
          ),
        );
      },
    );
  }

  Widget buildDueDate({required DateTime dueDate}) {
    return Wrap(spacing: Constants.halfPadding, children: [
      const Icon(Icons.event_rounded, size: Constants.minIconSize),
      AutoSizeText(
          Jiffy.parseFromDateTime(dueDate).toLocal().format(pattern: "MMM d"),
          softWrap: false,
          overflow: TextOverflow.visible,
          maxLines: 2,
          maxFontSize: Constants.large,
          minFontSize: Constants.small)
    ]);
  }

  Widget buildPriorityIcon({required Priority priority}) {
    return switch (priority) {
      Priority.low =>
        const Tooltip(message: "Low", child: Icon(Icons.low_priority_rounded)),
      Priority.medium => const Tooltip(
          message: "Medium", child: Icon(Icons.outlined_flag_rounded)),
      Priority.high => const Tooltip(
          message: "High", child: Icon(Icons.priority_high_rounded)),
    };
  }
}
