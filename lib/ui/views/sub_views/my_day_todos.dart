import 'package:allocate/ui/views/sub_views/update_todo.dart';
import 'package:another_flushbar/flushbar.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:auto_size_text_field/auto_size_text_field.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:jiffy/jiffy.dart';
import 'package:provider/provider.dart';

import '../../../model/task/subtask.dart';
import '../../../model/task/todo.dart';
import '../../../providers/todo_provider.dart';
import '../../../providers/user_provider.dart';
import '../../../util/constants.dart';
import '../../../util/enums.dart';
import '../../../util/exceptions.dart';
import '../../../util/numbers.dart';
import '../../../util/sorting/todo_sorter.dart';
import '../../widgets/flushbars.dart';
import '../../widgets/padded_divider.dart';

class MyDayToDos extends StatefulWidget {
  const MyDayToDos({Key? key}) : super(key: key);

  @override
  State<MyDayToDos> createState() => _MyDayToDos();
}

class _MyDayToDos extends State<MyDayToDos> {
  late bool allData;
  late bool loading;
  late int offset;
  late bool updateScreen;

  late final ToDoProvider toDoProvider;
  late final UserProvider userProvider;

  late final ScrollController mainScrollController;
  late final ScrollPhysics scrollPhysics;

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
    userProvider = Provider.of<UserProvider>(context, listen: false);

    toDoProvider.addListener(resetPagination);
  }

  void initializeParameters() {
    updateScreen = true;
    loading = toDoProvider.rebuild;
    allData = false;
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

  // TODO: refactor query to grab with sorting.
  // TODO: Also, refactor my-day sum > Include completed.
  // TODO: write a method to -reset- myDay at midnight.
  Future<void> fetchData() async {
    setState(() => loading = true);
    return Future.delayed(
        const Duration(seconds: 1),
        () async => await toDoProvider
                .getMyDay(limit: Constants.limitPerQuery, offset: offset)
                .then((newToDos) {
              offset += newToDos.length;
              toDoProvider.toDos.addAll(newToDos);
              allData = newToDos.length < Constants.limitPerQuery ||
                  userProvider.myDayTotal >=
                      (userProvider.curUser?.bandwidth ??
                          Constants.maxBandwidth);

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
    if (!updateScreen) {
      return;
    }
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

  Future<void> updateSubtasksAsync(
      {required ToDo toDo, required List<SubTask> cacheSubTasks}) async {
    toDo.subTasks.setAll(0, cacheSubTasks);
    await updateToDoAsync(toDo: toDo);
  }

  Future<void> updateToDoAsync({required ToDo toDo}) async {
    updateScreen = false;
    toDoProvider.curToDo = toDo;
    await toDoProvider.updateToDo();
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    bool largeScreen = (width >= Constants.largeScreen);
    bool smallScreen = (width <= Constants.smallScreen);
    bool hugeScreen = (width >= Constants.hugeScreen);

    return Padding(
      padding: const EdgeInsets.all(Constants.halfPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              mainAxisSize: MainAxisSize.min,
              children: [
                Expanded(
                  child: AutoSizeText(
                      Jiffy.now().format(pattern: "EEEE, MMMM d, yyyy"),
                      style: Constants.headerStyle,
                      softWrap: false,
                      maxLines: 1,
                      overflow: TextOverflow.visible,
                      minFontSize: Constants.large),
                ),
                Flexible(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Flexible(
                        child: FittedBox(
                          fit: BoxFit.contain,
                          child: Icon(Icons.swap_vert_rounded,
                              size: Constants.smIconSize),
                        ),
                      ),
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.contain,
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<SortMethod>(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: Constants.padding),
                                value: toDoProvider.sortMethod,
                                icon: (toDoProvider.sortMethod !=
                                        SortMethod.none)
                                    ? (toDoProvider.descending)
                                        ? const Icon(
                                            Icons.arrow_downward_rounded)
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
                                        (method) =>
                                            DropdownMenuItem<SortMethod>(
                                              value: method,
                                              child: Padding(
                                                padding: const EdgeInsets.all(
                                                    Constants.padding),
                                                child: Text(
                                                  toBeginningOfSentenceCase(
                                                      method.name.replaceAll(
                                                          "_", " "))!,
                                                ),
                                              ),
                                            ))
                                    .toList(growable: false)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ]),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: Constants.padding),
            child: (loading)
                ? const Center(child: CircularProgressIndicator())
                : buildToDosList(
                    smallScreen: smallScreen, physics: scrollPhysics),
          ),
        ],
      ),
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
              context: context,
              provider: provider,
              smallScreen: smallScreen,
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
              provider: provider,
              context: context,
              smallScreen: smallScreen,
              reorderable: false);
        });
  }

  Widget buildToDoListTile(
      {required int index,
      bool smallScreen = false,
      required ToDoProvider provider,
      required BuildContext context,
      bool reorderable = false}) {
    ToDo toDo = provider.toDos[index];

    if (toDo.taskType == TaskType.small) {
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
                    value: toDo.completed,
                    onChanged: (bool? completed) async {
                      updateScreen = true;
                      toDo.completed = completed!;
                      provider.curToDo = toDo;

                      // TODO: Not sure how to handle yet: Possibly factor out a method:
                      // -- Refactor query so that my-day includes completed:
                      // -- On day reset, query myDay + completed -> REMOVE from my day.
                      // Could also just empty my-day, but I find that annoying.

                      // This can likely be removed.
                      // if (completed) {
                      //   provider.curToDo!.myDay = false;
                      //   userProvider.spentEnergy += provider.curToDo.weight, or something like that.
                      // }

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
          title: AutoSizeText(toDo.name,
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
                builder: (BuildContext context) {
                  updateScreen = true;
                  return const UpdateToDoScreen();
                });
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
                    icon: const Icon(Icons.remove_circle_outline_rounded),
                    onPressed: () async {
                      updateScreen = true;
                      provider.curToDo = provider.toDos[index];
                      provider.curToDo!.myDay = false;
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
                    }),
              ),
              (reorderable)
                  ? ReorderableDragStartListener(
                      index: index,
                      child: const Icon(Icons.drag_handle_rounded))
                  : const SizedBox.shrink()
            ],
          ));
    }

    int itemCount = toDo.subTasks.indexOf(SubTask());
    if (itemCount < 0) {
      itemCount = toDo.subTasks.length;
    }

    // For Multi-Tasks -> ExpansionTile.
    return Card(
      key: ValueKey(index),
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      color: Colors.transparent,
      shape: RoundedRectangleBorder(
          side: BorderSide(
              width: 1.5,
              color: Theme.of(context).colorScheme.outlineVariant,
              strokeAlign: BorderSide.strokeAlignInside),
          borderRadius: const BorderRadius.all(
              Radius.circular(Constants.roundedCorners))),
      // Decide Whether initially expanded. Doesn't seem wise.
      child: ExpansionTile(
        tilePadding: const EdgeInsets.all(Constants.innerPadding),
        leading: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: Constants.innerPadding),
          child: IconButton.filledTonal(
              icon: const Icon(Icons.edit_rounded),
              onPressed: () async {
                provider.curToDo = toDo;
                await showDialog(
                    barrierDismissible: false,
                    useRootNavigator: false,
                    context: context,
                    builder: (BuildContext context) =>
                        const UpdateToDoScreen());
              }),
        ),
        collapsedShape: const RoundedRectangleBorder(
            borderRadius:
                BorderRadius.all(Radius.circular(Constants.roundedCorners))),
        shape: const RoundedRectangleBorder(
            borderRadius:
                BorderRadius.all(Radius.circular(Constants.roundedCorners))),
        title: AutoSizeText(toDo.name,
            overflow: TextOverflow.visible,
            style: Constants.headerStyle,
            minFontSize: Constants.medium,
            softWrap: true,
            maxLines: 1),
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
                  icon: const Icon(Icons.remove_circle_outline_rounded),
                  onPressed: () async {
                    updateScreen = true;
                    provider.curToDo = provider.toDos[index];
                    provider.curToDo!.myDay = false;
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
                  }),
            ),
            (reorderable)
                ? ReorderableDragStartListener(
                    index: index, child: const Icon(Icons.drag_handle_rounded))
                : const SizedBox.shrink()
          ],
        ),
        children: [
          buildSubtasksList(
            toDo: toDo,
            itemCount: itemCount,
          ),
          const PaddedDivider(padding: Constants.padding),
          (itemCount < toDo.subTasks.length)
              ? ListTile(
                  leading: const Icon(Icons.add_rounded),
                  title: const AutoSizeText("Add a step",
                      maxLines: 1,
                      overflow: TextOverflow.visible,
                      softWrap: false,
                      minFontSize: Constants.small),
                  onTap: () => setState(() {
                        toDo.subTasks[itemCount] =
                            SubTask(name: "New Step", weight: 0);
                      }))
              : const SizedBox.shrink(),
        ],
      ),
    );
  }

  Widget buildSubtasksList({required ToDo toDo, required int itemCount}) {
    List<SubTask> cacheSubTasks = List.from(toDo.subTasks);

    return ReorderableListView.builder(
      buildDefaultDragHandles: false,
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: itemCount,
      itemBuilder: (BuildContext context, int index) {
        return CheckboxListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: Constants.innerPadding),
            key: ValueKey(index),
            checkboxShape: const CircleBorder(),
            controlAffinity: ListTileControlAffinity.leading,
            shape: const CircleBorder(),
            title: Row(
              children: [
                IconButton(
                  icon: Constants.batteryIcons[cacheSubTasks[index].weight]!,
                  selectedIcon: Constants
                      .selectedBatteryIcons[cacheSubTasks[index].weight]!,
                  onPressed: () {
                    showModalBottomSheet<void>(
                        showDragHandle: true,
                        context: context,
                        builder: (BuildContext context) {
                          return StatefulBuilder(
                            builder: (context, setState) => Center(
                                heightFactor: 1,
                                child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text("Step Drain",
                                          style: Constants.headerStyle),
                                      Padding(
                                          padding: const EdgeInsets.all(
                                              Constants.padding),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceEvenly,
                                            children: [
                                              const Icon(Icons.battery_full),
                                              Expanded(
                                                child: Slider(
                                                  value: cacheSubTasks[index]
                                                      .weight
                                                      .toDouble(),
                                                  max: Constants.maxTaskWeight
                                                      .toDouble(),
                                                  label: (cacheSubTasks[index]
                                                              .weight >
                                                          (Constants.maxTaskWeight /
                                                                  2)
                                                              .floor())
                                                      ? " ${cacheSubTasks[index].weight} ${Constants.lowBattery}"
                                                      : " ${cacheSubTasks[index].weight} ${Constants.fullBattery}",
                                                  divisions:
                                                      Constants.maxTaskWeight,
                                                  onChanged: (value) =>
                                                      setState(() {
                                                    cacheSubTasks[index]
                                                        .weight = value.toInt();
                                                  }),
                                                ),
                                              ),
                                              const Icon(Icons.battery_1_bar),
                                            ],
                                          )),
                                    ])),
                          );
                        }).whenComplete(() => setState(() {
                          toDo.weight = toDoProvider.calculateWeight(
                              subTasks: cacheSubTasks);
                          toDo.realDuration =
                              toDoProvider.calculateRealDuration(
                                  weight: toDo.weight,
                                  duration: toDo.expectedDuration);
                          updateToDoAsync(toDo: toDo);
                        }));
                  },
                ),
                Expanded(
                  child: AutoSizeTextField(
                      controller: TextEditingController(
                          text: cacheSubTasks[index].name),
                      maxLines: 1,
                      minFontSize: Constants.small,
                      decoration: const InputDecoration.collapsed(
                        hintText: "Step name",
                      ),
                      onChanged: (value) {
                        cacheSubTasks[index].name = value;
                        updateSubtasksAsync(
                            toDo: toDo, cacheSubTasks: cacheSubTasks);
                      }),
                ),
              ],
            ),
            value: cacheSubTasks[index].completed,
            onChanged: (bool? value) => setState(() {
                  cacheSubTasks[index].completed = value!;
                  updateSubtasksAsync(toDo: toDo, cacheSubTasks: cacheSubTasks);
                }),

            // Delete Subtask
            secondary: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: Constants.innerPadding),
                  child: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => setState(() {
                            SubTask st = cacheSubTasks.removeAt(index);
                            st = SubTask();
                            cacheSubTasks.add(st);
                            toDo.weight = toDoProvider.calculateWeight(
                                subTasks: cacheSubTasks);
                            updateSubtasksAsync(
                                toDo: toDo, cacheSubTasks: cacheSubTasks);
                          })),
                ),
                ReorderableDragStartListener(
                    index: index, child: const Icon(Icons.drag_handle_rounded))
              ],
            ));
      },
      onReorder: (int oldIndex, int newIndex) {
        setState(() {
          if (oldIndex < newIndex) {
            newIndex--;
          }

          SubTask st = cacheSubTasks.removeAt(oldIndex);
          cacheSubTasks.insert(newIndex, st);
          updateSubtasksAsync(toDo: toDo, cacheSubTasks: cacheSubTasks);
        });
      },
    );
  }
}
