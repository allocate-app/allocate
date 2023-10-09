import 'package:another_flushbar/flushbar.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../model/task/group.dart';
import '../../../model/task/todo.dart';
import '../../../providers/group_provider.dart';
import '../../../providers/todo_provider.dart';
import '../../../util/constants.dart';
import '../../../util/enums.dart';
import '../../../util/exceptions.dart';
import '../../../util/numbers.dart';
import '../../../util/sorting/group_sorter.dart';
import '../../widgets/flushbars.dart';
import '../../widgets/padded_divider.dart';
import '../sub_views/create_group.dart';
import '../sub_views/create_todo.dart';
import '../sub_views/update_group.dart';
import '../sub_views/update_todo.dart';

class GroupsListScreen extends StatefulWidget {
  const GroupsListScreen({Key? key}) : super(key: key);

  @override
  State<GroupsListScreen> createState() => _GroupsListScreen();
}

class _GroupsListScreen extends State<GroupsListScreen> {
  late bool checkDelete;
  late bool allData;
  late bool loading;
  late int offset;

  late final GroupProvider groupProvider;
  late final ToDoProvider toDoProvider;

  // For linked todos.
  late final ScrollController mainScrollController;
  late final ScrollPhysics scrollPhysics;

  @override
  void initState() {
    super.initState();
    initializeProviders();
    initializeParameters();
    initializeControllers();

    if (groupProvider.rebuild) {
      resetPagination();
      groupProvider.rebuild = false;
    }
  }

  void initializeProviders() {
    groupProvider = Provider.of<GroupProvider>(context, listen: false);
    toDoProvider = Provider.of<ToDoProvider>(context, listen: false);

    groupProvider.addListener(resetPagination);
  }

  void initializeParameters() {
    loading = groupProvider.rebuild;
    allData = false;
    checkDelete = true;
    offset = (groupProvider.rebuild) ? 0 : groupProvider.groups.length;
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
    if (groupProvider.sortMethod == SortMethod.none) {
      return const SizedBox.shrink();
    }

    if (groupProvider.sortMethod == method && !groupProvider.descending) {
      return const Icon(Icons.arrow_downward_rounded);
    }

    return const Icon(Icons.arrow_upward_rounded);
  }

  Future<void> fetchData() async {
    setState(() => loading = true);
    return Future.delayed(
        const Duration(seconds: 1),
        () async => await groupProvider
                .getGroupsBy(
                    limit: Constants.minLimitPerQuery,
                    offset: offset,
                    grabToDos: true)
                .then((newGroups) {
              offset += newGroups.length;
              groupProvider.groups.addAll(newGroups);
              allData = newGroups.length < Constants.minLimitPerQuery;

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
      groupProvider.groups.clear();
    });
    return await fetchData();
  }

  @override
  void dispose() {
    mainScrollController.dispose();
    groupProvider.removeListener(resetPagination);
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

  Future<void> updateGroupToDo({required BuildContext context}) async {
    await toDoProvider.updateToDo().catchError((e) {
      Flushbar? error;

      error = Flushbars.createError(
        message: e.cause,
        context: context,
        dismissCallback: () => error?.dismiss(),
      );

      error.show(context);
    },
        test: (e) =>
            e is FailureToCreateException || e is FailureToUploadException);
  }

  @override
  Widget build(BuildContext context) {
    // TODO: Remove this @ first build if still unused.
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
                child: AutoSizeText("Groups",
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
                    value: groupProvider.sortMethod,
                    icon: (groupProvider.sortMethod != SortMethod.none)
                        ? (groupProvider.descending)
                            ? const Icon(Icons.arrow_downward_rounded)
                            : const Icon(Icons.arrow_upward_rounded)
                        : null,
                    borderRadius: const BorderRadius.all(
                        Radius.circular(Constants.roundedCorners)),
                    onChanged: (method) {
                      if (null != method) {
                        setState(() {
                          groupProvider.sortMethod = method;
                        });
                      }
                    },
                    items: GroupSorter.sortMethods
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
            builder: (BuildContext context) => const CreateGroupScreen(),
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
        Flexible(
          child: (loading)
              ? const CircularProgressIndicator()
              : buildGroupsList(
                  smallScreen: smallScreen,
                  physics: scrollPhysics,
                  largeScreen: largeScreen),
        ),
      ]),
    );
  }

  ListView buildGroupsList(
      {bool smallScreen = false,
      ScrollPhysics physics = const BouncingScrollPhysics(),
      largeScreen = false}) {
    return ListView(
        controller: mainScrollController,
        physics: physics,
        shrinkWrap: true,
        children: [
          Consumer<GroupProvider>(
            builder:
                (BuildContext context, GroupProvider value, Widget? child) {
              if (value.sortMethod == SortMethod.none) {
                return buildReorderable(
                    provider: value,
                    context: context,
                    largeScreen: largeScreen);
              }
              return buildImmutable(
                  provider: value, context: context, largeScreen: largeScreen);
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
      {required GroupProvider provider,
      required BuildContext context,
      bool largeScreen = false}) {
    return ReorderableListView.builder(
        buildDefaultDragHandles: false,
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: provider.groups.length,
        onReorder: (int oldIndex, int newIndex) async {
          provider.groups = await provider
              .reorderGroups(
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
            return List<Group>.empty(growable: true);
          },
                  test: (e) =>
                      e is FailureToCreateException ||
                      e is FailureToUploadException);
          if (provider.groups.isEmpty) {
            resetPagination();
          }
        },
        itemBuilder: (BuildContext context, int index) {
          return buildGroupExpansionTile(
              index: index,
              context: context,
              provider: provider,
              reorderable: true);
        });
  }

  ListView buildImmutable(
      {required GroupProvider provider,
      required BuildContext context,
      bool largeScreen = false}) {
    return ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: provider.groups.length,
        itemBuilder: (BuildContext context, int index) {
          return buildGroupExpansionTile(
              index: index,
              context: context,
              provider: provider,
              reorderable: false);
        });
  }

  Widget buildGroupExpansionTile(
      {required int index,
      required BuildContext context,
      required GroupProvider provider,
      bool reorderable = false}) {
    // This needs rebuilding.

    // Refactor into an expansion tile card.
    // Somehow... > May need to use a tile within the card.
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
      child: ExpansionTile(
        initiallyExpanded: true,
        tilePadding: const EdgeInsets.all(Constants.innerPadding),
        leading: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: Constants.innerPadding),
          child: IconButton.filledTonal(
              icon: const Icon(Icons.edit_rounded),
              onPressed: () async {
                provider.curGroup = provider.groups[index];
                await showDialog(
                    barrierDismissible: false,
                    useRootNavigator: false,
                    context: context,
                    builder: (BuildContext context) =>
                        const UpdateGroupScreen());
              }),
        ),
        collapsedShape: const RoundedRectangleBorder(
            borderRadius:
                BorderRadius.all(Radius.circular(Constants.roundedCorners))),
        shape: const RoundedRectangleBorder(
            borderRadius:
                BorderRadius.all(Radius.circular(Constants.roundedCorners))),
        title: AutoSizeText(provider.groups[index].name,
            overflow: TextOverflow.visible,
            style: Constants.headerStyle,
            minFontSize: Constants.medium,
            softWrap: true,
            maxLines: 1),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: Constants.innerPadding),
              child: IconButton(
                  icon: const Icon(Icons.delete_forever),
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
                                                    "Delete Group?",
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
                    } else {
                      await handleDelete(
                          provider: provider, index: index, context: context);
                    }
                  }),
            ),
            (reorderable)
                ? ReorderableDragStartListener(
                    index: index, child: const Icon(Icons.drag_handle_rounded))
                : const SizedBox.shrink(),
          ],
        ),
        children: [
          buildToDosList(
            index: index,
            physics: const NeverScrollableScrollPhysics(),
          ),
          const PaddedDivider(padding: Constants.padding),
          buildCreateToDoBar(
              context: context, id: provider.groups[index].localID!),
        ],
      ),
    );
  }

  Future<void> handleDelete(
      {required GroupProvider provider,
      required int index,
      required BuildContext context}) async {
    provider.curGroup = provider.groups[index];

    await provider.deleteGroup().catchError((e) {
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

  ListView buildToDosList(
      {required int index,
      ScrollPhysics physics = const BouncingScrollPhysics()}) {
    Group group = groupProvider.groups[index];
    return ListView(physics: physics, shrinkWrap: true, children: [
      Consumer<GroupProvider>(
        builder: (BuildContext context, GroupProvider value, Widget? child) {
          return ReorderableListView.builder(
              buildDefaultDragHandles: false,
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: group.toDos!.length,
              onReorder: (int oldIndex, int newIndex) async {
                group.toDos = await value
                    .reorderGroupToDos(
                        oldIndex: oldIndex,
                        newIndex: newIndex,
                        toDos: group.toDos)
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
              },
              itemBuilder: (BuildContext context, int index) {
                return buildToDoListTile(
                    group: group, index: index, context: context);
              });
        },
      ),
      // TODO: Stretch goal: decouple tasks from groups to use separate loading.
      (loading)
          ? const Padding(
              padding: EdgeInsets.all(Constants.padding),
              child: Center(child: CircularProgressIndicator()),
            )
          : const SizedBox.shrink()
    ]);
  }

  ListTile buildToDoListTile(
      {required Group group,
      required int index,
      required BuildContext context}) {
    return ListTile(
        key: ValueKey(index),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: Constants.innerPadding),
        shape: const RoundedRectangleBorder(
            borderRadius:
                BorderRadius.all(Radius.circular(Constants.roundedCorners))),
        leading: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: Constants.innerPadding),
          child: Checkbox(
              shape: const CircleBorder(),
              splashRadius: 15,
              value: group.toDos![index].completed,
              onChanged: (bool? completed) async {
                group.toDos![index].completed = completed!;
                toDoProvider.curToDo = group.toDos![index];
                await updateGroupToDo(context: context);
              }),
        ),
        title: AutoSizeText(group.toDos![index].name,
            overflow: TextOverflow.visible,
            style: Constants.headerStyle,
            minFontSize: Constants.medium,
            softWrap: true,
            maxLines: 1),
        onTap: () async {
          toDoProvider.curToDo = group.toDos![index];
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
                      e is FailureToUploadException).whenComplete(
                  () => setState(() {}));
        },
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                getBatteryIcon(toDo: group.toDos![index]),
                AutoSizeText(
                  "${group.toDos![index].weight}",
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
                    group.toDos![index].groupID = null;
                    toDoProvider.curToDo = group.toDos![index];
                    await updateGroupToDo(context: context)
                        .whenComplete(() => setState(() {
                              ToDo toDo = group.toDos![index];
                              group.toDos!.remove(toDo);
                            }));
                  }),
            ),
            ReorderableDragStartListener(
                index: index, child: const Icon(Icons.drag_handle_rounded)),
          ],
        ));
  }

  ListTile buildCreateToDoBar(
      {required BuildContext context, required int id}) {
    return ListTile(
        leading: const Icon(Icons.add_outlined),
        title: const AutoSizeText("Add New Task",
            maxLines: 1,
            overflow: TextOverflow.visible,
            softWrap: false,
            minFontSize: Constants.small),
        onTap: () async {
          await showDialog(
              barrierDismissible: false,
              useRootNavigator: false,
              context: context,
              builder: (BuildContext context) =>
                  CreateToDoScreen(groupID: id)).whenComplete(() async {
            allData = false;
            await resetPagination();
          }).catchError((e) {
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
        });
  }
}
