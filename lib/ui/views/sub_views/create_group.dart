import 'dart:async';
import 'dart:math';

import 'package:allocate/providers/group_provider.dart';
import 'package:another_flushbar/flushbar.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:auto_size_text_field/auto_size_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:provider/provider.dart';

import '../../../model/task/todo.dart';
import '../../../providers/todo_provider.dart';
import '../../../util/constants.dart';
import '../../../util/enums.dart';
import '../../../util/exceptions.dart';
import '../../../util/numbers.dart';
import '../../widgets/flushbars.dart';
import '../../widgets/padded_divider.dart';
import '../sub_views.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({Key? key}) : super(key: key);

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreen();
}

class _CreateGroupScreen extends State<CreateGroupScreen> {
  late bool checkClose;
  late bool expanded;
  late bool allData;

  late bool loading;
  late int offset;

  // Providers
  late final GroupProvider groupProvider;
  late final ToDoProvider toDoProvider;

  // Scrolling
  late final ScrollController mainScrollController;

  // For linked todos.
  late final ScrollController subScrollController;
  late final ScrollPhysics scrollPhysics;

  // For Task search.
  late final SearchController searchController;
  late List<MapEntry<String, int>> searchHistory;

  // Name
  late String name;
  late final TextEditingController nameEditingController;
  String? nameErrorText;

  // Description
  late String description;
  late final TextEditingController descriptionEditingController;

  @override
  void initState() {
    super.initState();
    initializeProviders();
    initializeParameters();
    initializeControllers();
  }

  void initializeProviders() {
    groupProvider = Provider.of<GroupProvider>(context, listen: false);
    toDoProvider = Provider.of<ToDoProvider>(context, listen: false);

    toDoProvider.toDos = [];
  }

  void initializeParameters() {
    loading = false;
    allData = false;
    checkClose = false;
    expanded = true;
    name = "";
    description = "";
    offset = 0;
    searchHistory = List.empty(growable: true);
  }

  void initializeControllers() {
    searchController = SearchController();
    mainScrollController = ScrollController();
    subScrollController = ScrollController();

    mainScrollController.addListener(() async {
      // Bottom: Run the query.
      if (mainScrollController.offset >=
              mainScrollController.position.maxScrollExtent &&
          !allData) {
        if (!loading) {
          setState(() => loading = true);
          await fetchData();
        }
      }
    });

    scrollPhysics =
        const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics());
    nameEditingController = TextEditingController();
    nameEditingController.addListener(() {
      nameErrorText = null;
      checkClose = true;
      String newText = nameEditingController.text;
      SemanticsService.announce(newText, Directionality.of(context));
      setState(() => name = newText);
    });
    descriptionEditingController = TextEditingController();
    descriptionEditingController.addListener(() {
      checkClose = true;
      String newText = descriptionEditingController.text;
      SemanticsService.announce(newText, Directionality.of(context));
      description = newText;
    });
  }

  Future<void> fetchData() async {
    setState(() => loading = true);
    return Future.delayed(
        const Duration(seconds: 1),
        () async => await groupProvider
                .getToDosByGroupId(
                    id: Constants.initialGroupID,
                    limit: Constants.limitPerQuery,
                    offset: offset)
                .then((newToDos) {
              offset += newToDos.length;
              toDoProvider.toDos.addAll(newToDos);
              setState(() {
                loading = false;
                allData = newToDos.length < Constants.limitPerQuery;
              });
            }).catchError(
              (e) {
                Flushbar? error;

                error = Flushbars.createError(
                  message: e.cause ?? "Query Error",
                  context: context,
                  dismissCallback: () => error?.dismiss(),
                );

                error.show(context);
              },
            ));
  }

  @override
  void dispose() {
    nameEditingController.dispose();
    descriptionEditingController.dispose();
    super.dispose();
  }

  Future<void> resetPagination() async {
    setState(() {
      offset = 0;
      toDoProvider.toDos.clear();
    });
    return await fetchData();
  }

  bool validateData() {
    bool valid = true;

    if (nameEditingController.text.isEmpty) {
      valid = false;
      setState(() => nameErrorText = "Enter Group Name");
    }

    return valid;
  }

  Future<void> handleCreate({required BuildContext context}) async {
    await groupProvider
        .createGroup(name: name, description: description)
        .whenComplete(() async {
      for (ToDo toDo in toDoProvider.toDos) {
        toDo.groupID = groupProvider.curGroup!.localID;
      }

      await toDoProvider
          .updateBatch()
          .whenComplete(() => Navigator.pop(context))
          .catchError((e) {
        Flushbar? error;

        error = Flushbars.createError(
          message: e.cause,
          context: context,
          dismissCallback: () => error?.dismiss(),
        );
      },
              test: (e) =>
                  e is FailureToCreateException ||
                  e is FailureToUpdateException);
    }).catchError((e) {
      Flushbar? error;

      error = Flushbars.createError(
        message: e.cause,
        context: context,
        dismissCallback: () => error?.dismiss(),
      );
    },
            test: (e) =>
                e is FailureToCreateException || e is FailureToUpdateException);
  }

  Future<void> updateGroupToDo(
      {required ToDoProvider provider, required BuildContext context}) async {
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
            e is FailureToCreateException || e is FailureToUploadException);
  }

  Future<void> handleHistorySelection(
      {required MapEntry<String, int> toDoData,
      required SearchController controller,
      required BuildContext context}) async {
    controller.closeView("");
    setState(() {
      checkClose = true;
    });
    await toDoProvider.getToDoByID(id: toDoData.value).then((toDo) async {
      if (null == toDo) {
        return;
      }
      toDo.groupID = Constants.initialGroupID;
      toDoProvider.curToDo = toDo;
      await updateGroupToDo(provider: toDoProvider, context: context)
          .whenComplete(() async {
        allData = false;
        await resetPagination();
      });
    }).catchError((_) {
      Flushbar? error;

      error = Flushbars.createError(
        message: "Error with Task Retrieval",
        context: context,
        dismissCallback: () => error?.dismiss(),
      );

      error.show(context);
    });
  }

  Future<void> handleToDoSelection(
      {required ToDo toDo,
      required SearchController controller,
      required BuildContext context}) async {
    // Controller logic
    controller.closeView("");
    setState(() {
      checkClose = true;
      if (searchHistory.length >= Constants.historyLength) {
        searchHistory.removeLast();
      }
    });
    toDo.groupID = Constants.initialGroupID;
    toDoProvider.curToDo = toDo;
    await updateGroupToDo(provider: toDoProvider, context: context)
        .whenComplete(() async {
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
                e is FailureToCreateException || e is FailureToUploadException);

    searchHistory.insert(0, MapEntry(toDo.name, toDo.id));
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

  @override
  Widget build(BuildContext context) {
    bool largeScreen =
        (MediaQuery.of(context).size.width >= Constants.largeScreen);
    bool smallScreen =
        (MediaQuery.of(context).size.width <= Constants.smallScreen);
    return (largeScreen)
        ? buildDesktopDialog(context: context, smallScreen: smallScreen)
        : buildMobileDialog(context: context, smallScreen: smallScreen);
  }

  Dialog buildDesktopDialog(
      {required BuildContext context, bool smallScreen = false}) {
    return Dialog(
      insetPadding: const EdgeInsets.all(Constants.outerDialogPadding),
      child: ConstrainedBox(
        constraints:
            const BoxConstraints(maxHeight: Constants.maxLandscapeDialogHeight),
        child: Padding(
          padding: const EdgeInsets.all(Constants.padding),
          child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Title && Close Button
                Flexible(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: Constants.padding),
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Flexible(
                            child: AutoSizeText(
                              "New Group",
                              overflow: TextOverflow.visible,
                              style: Constants.headerStyle,
                              minFontSize: Constants.medium,
                              softWrap: true,
                              maxLines: 1,
                            ),
                          ),
                          buildCloseButton(context: context),
                        ]),
                  ),
                ),
                const PaddedDivider(padding: Constants.padding),
                Expanded(
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                            // Name And Description.
                            child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                              // Title
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: Constants.padding),
                                child: buildNameTile(smallScreen: smallScreen),
                              ),
                              const PaddedDivider(
                                  padding: Constants.innerPadding),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: Constants.innerPadding),
                                  child: buildDescriptionTile(
                                      smallScreen: smallScreen),
                                ),
                              ),
                            ])),
                        Expanded(
                          // I am unsure about this scroll controller.
                          flex: 2,
                          child: Scrollbar(
                            thumbVisibility: true,
                            controller: mainScrollController,
                            child: ListView(
                                controller: mainScrollController,
                                physics: scrollPhysics,
                                shrinkWrap: true,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: Constants.padding),
                                children: [
                                  // RoutineTasks
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: Constants.innerPadding),
                                    child: Card(
                                      clipBehavior: Clip.antiAlias,
                                      elevation: 0,
                                      color: Colors.transparent,
                                      shape: RoundedRectangleBorder(
                                          side: BorderSide(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .outline,
                                              strokeAlign:
                                                  BorderSide.strokeAlignInside),
                                          borderRadius: const BorderRadius.all(
                                              Radius.circular(
                                                  Constants.roundedCorners))),
                                      child: ExpansionTile(
                                        initiallyExpanded: expanded,
                                        onExpansionChanged: (value) =>
                                            setState(() => expanded = value),
                                        title: const AutoSizeText("Tasks",
                                            maxLines: 1,
                                            overflow: TextOverflow.visible,
                                            softWrap: false,
                                            minFontSize: Constants.small),
                                        collapsedShape:
                                            const RoundedRectangleBorder(
                                                side: BorderSide(
                                                    strokeAlign: BorderSide
                                                        .strokeAlignOutside),
                                                borderRadius: BorderRadius.all(
                                                    Radius.circular(Constants
                                                        .roundedCorners))),
                                        shape: const RoundedRectangleBorder(
                                            side: BorderSide(
                                                strokeAlign: BorderSide
                                                    .strokeAlignOutside),
                                            borderRadius: BorderRadius.all(
                                                Radius.circular(
                                                    Constants.roundedCorners))),
                                        children: [
                                          Scrollbar(
                                              thumbVisibility: true,
                                              controller: subScrollController,
                                              child: buildToDosList(
                                                  smallScreen: smallScreen,
                                                  physics: scrollPhysics)),
                                          const PaddedDivider(
                                              padding: Constants.padding),
                                          buildToDoSearchBar(),
                                          const PaddedDivider(
                                              padding: Constants.innerPadding),
                                          buildCreateToDoBar(context: context)
                                        ],
                                      ),
                                    ),
                                  ),
                                ]),
                          ),
                        )
                      ]),
                ),

                const PaddedDivider(padding: Constants.padding),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: Constants.padding),
                  child: buildCreateButton(context: context),
                )
              ]),
        ),
      ),
    );
  }

  Dialog buildMobileDialog(
      {required BuildContext context, required bool smallScreen}) {
    return Dialog(
      insetPadding: const EdgeInsets.all(Constants.outerDialogPadding),
      child: Padding(
        padding: const EdgeInsets.all(Constants.padding),
        child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title && Close Button
              Flexible(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: Constants.padding),
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Flexible(
                          child: AutoSizeText(
                            "New Group",
                            overflow: TextOverflow.visible,
                            style: Constants.headerStyle,
                            minFontSize: Constants.medium,
                            softWrap: true,
                            maxLines: 1,
                          ),
                        ),
                        buildCloseButton(context: context),
                      ]),
                ),
              ),
              const PaddedDivider(padding: Constants.padding),
              Expanded(
                flex: (expanded) ? min(toDoProvider.toDos.length + 2, 10) : 2,
                child: Scrollbar(
                  thumbVisibility: true,
                  controller: mainScrollController,
                  child: ListView(
                      shrinkWrap: true,
                      controller: mainScrollController,
                      physics: scrollPhysics,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: Constants.padding),
                          child: buildNameTile(smallScreen: smallScreen),
                        ),
                        const PaddedDivider(padding: Constants.innerPadding),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: Constants.innerPadding),
                          child: buildDescriptionTile(smallScreen: smallScreen),
                        ),
                        const PaddedDivider(padding: Constants.innerPadding),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: Constants.innerPadding),
                          child: Card(
                            clipBehavior: Clip.antiAlias,
                            elevation: 0,
                            color: Colors.transparent,
                            shape: RoundedRectangleBorder(
                                side: BorderSide(
                                    color:
                                        Theme.of(context).colorScheme.outline,
                                    strokeAlign: BorderSide.strokeAlignInside),
                                borderRadius: const BorderRadius.all(
                                    Radius.circular(Constants.roundedCorners))),
                            child: ExpansionTile(
                              initiallyExpanded: expanded,
                              onExpansionChanged: (value) =>
                                  setState(() => expanded = value),
                              title: const AutoSizeText("Tasks",
                                  maxLines: 1,
                                  overflow: TextOverflow.visible,
                                  softWrap: false,
                                  minFontSize: Constants.small),
                              collapsedShape: const RoundedRectangleBorder(
                                  side: BorderSide(
                                      strokeAlign:
                                          BorderSide.strokeAlignOutside),
                                  borderRadius: BorderRadius.all(
                                      Radius.circular(
                                          Constants.roundedCorners))),
                              shape: const RoundedRectangleBorder(
                                  side: BorderSide(
                                      strokeAlign:
                                          BorderSide.strokeAlignOutside),
                                  borderRadius: BorderRadius.all(
                                      Radius.circular(
                                          Constants.roundedCorners))),
                              children: [
                                Scrollbar(
                                    thumbVisibility: true,
                                    controller: subScrollController,
                                    child: buildToDosList(
                                        smallScreen: smallScreen,
                                        physics: scrollPhysics)),
                                const PaddedDivider(padding: Constants.padding),
                                buildToDoSearchBar(),
                                const PaddedDivider(
                                    padding: Constants.innerPadding),
                                buildCreateToDoBar(context: context)
                              ],
                            ),
                          ),
                        ),
                      ]),
                ),
              ),

              const PaddedDivider(padding: Constants.padding),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: Constants.padding),
                child: buildCreateButton(context: context),
              )
            ]),
      ),
    );
  }

  ListTile buildCreateToDoBar({required BuildContext context}) {
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
                      const CreateToDoScreen(groupID: Constants.initialGroupID))
              .whenComplete(() async {
            checkClose = true;
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

  IconButton buildCloseButton({required BuildContext context}) {
    return IconButton(
        onPressed: () {
          if (checkClose) {
            showModalBottomSheet<bool>(
                showDragHandle: true,
                context: context,
                builder: (BuildContext context) {
                  return Center(
                      heightFactor: 1,
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(Constants.padding),
                              child: FilledButton.icon(
                                onPressed: () {
                                  Navigator.pop(context, true);
                                },
                                label: const Text("Discard"),
                                icon: const Icon(Icons.delete_forever_outlined),
                              ),
                            ),
                            Padding(
                                padding:
                                    const EdgeInsets.all(Constants.padding),
                                child: FilledButton.tonalIcon(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  label: const Text("Continue Editing"),
                                  icon: const Icon(
                                    Icons.edit_note_outlined,
                                  ),
                                ))
                          ]));
                }).then((willDiscard) {
              if (willDiscard ?? false) {
                for (ToDo toDo in toDoProvider.toDos) {
                  toDo.groupID = null;
                }
                toDoProvider.updateBatch();

                Navigator.pop(context);
              }
            });
            setState(() => checkClose = false);
          } else {
            Navigator.pop(context);
          }
        },
        icon: const Icon(Icons.close_outlined),
        selectedIcon: const Icon(Icons.close));
  }

  Row buildCreateButton({required BuildContext context}) {
    return Row(mainAxisAlignment: MainAxisAlignment.end, children: [
      FilledButton.icon(
          label: const Text("Create"),
          icon: const Icon(Icons.add),
          onPressed: () async {
            bool validData = validateData();
            if (validData) {
              await handleCreate(context: context);
            }
            // Then save.
          })
    ]);
  }

  Row buildNameTile({bool smallScreen = false}) {
    return Row(
      children: [
        Expanded(
            child: Padding(
          padding: const EdgeInsets.all(Constants.padding),
          child: buildGroupName(smallScreen: smallScreen),
        )),
      ],
    );
  }

  AutoSizeTextField buildGroupName({bool smallScreen = false}) {
    return AutoSizeTextField(
      maxLines: 1,
      minFontSize: Constants.medium,
      decoration: InputDecoration(
        isDense: smallScreen,
        suffixIcon: (name != "")
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  checkClose = true;
                  nameEditingController.clear();
                  setState(() => name = "");
                })
            : null,
        contentPadding: const EdgeInsets.all(Constants.innerPadding),
        border: const OutlineInputBorder(
            borderRadius:
                BorderRadius.all(Radius.circular(Constants.roundedCorners)),
            borderSide: BorderSide(
              strokeAlign: BorderSide.strokeAlignOutside,
            )),
        hintText: "Group name",
        errorText: nameErrorText,
      ),
      controller: nameEditingController,
    );
  }

  AutoSizeTextField buildDescriptionTile({bool smallScreen = false}) {
    return AutoSizeTextField(
        controller: descriptionEditingController,
        maxLines: Constants.descripMaxLinesBeforeScroll,
        minLines: Constants.descripMinLines,
        minFontSize: Constants.medium,
        decoration: InputDecoration(
          isDense: smallScreen,
          contentPadding: const EdgeInsets.all(Constants.innerPadding),
          hintText: "Description",
          border: const OutlineInputBorder(
              borderRadius:
                  BorderRadius.all(Radius.circular(Constants.roundedCorners)),
              borderSide: BorderSide(
                strokeAlign: BorderSide.strokeAlignOutside,
              )),
        ));
  }

  // TODO: remove small screen.
  ListView buildToDosList(
      {bool smallScreen = false,
      ScrollPhysics physics = const BouncingScrollPhysics()}) {
    return ListView(
        controller: subScrollController,
        physics: physics,
        shrinkWrap: true,
        children: [
          Consumer<ToDoProvider>(
            builder: (BuildContext context, ToDoProvider value, Widget? child) {
              return ReorderableListView.builder(
                  buildDefaultDragHandles: false,
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: value.toDos.length,
                  onReorder: (int oldIndex, int newIndex) async {
                    value.toDos = await groupProvider
                        .reorderGroupToDos(
                            oldIndex: oldIndex,
                            newIndex: newIndex,
                            toDos: value.toDos)
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
                        index: index,
                        provider: value,
                        context: context,
                        smallScreen: smallScreen);
                  });
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

  ListTile buildToDoListTile(
      {required int index,
      bool smallScreen = false,
      required ToDoProvider provider,
      required BuildContext context}) {
    return ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: Constants.innerPadding),
        key: ValueKey(index),
        shape: const RoundedRectangleBorder(
            borderRadius:
                BorderRadius.all(Radius.circular(Constants.roundedCorners))),
        leading: Checkbox(
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
            }),
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
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: () async {
                    provider.curToDo = provider.toDos[index];
                    provider.toDos.remove(provider.toDos[index]);
                    provider.curToDo!.groupID = null;
                    await updateGroupToDo(provider: provider, context: context)
                        .whenComplete(() => setState(() {}));
                  }),
            ),
            ReorderableDragStartListener(
                index: index, child: const Icon(Icons.drag_handle_rounded))
          ],
        ));
  }

  SearchAnchor buildToDoSearchBar() {
    return SearchAnchor(
      viewHintText: "Search Tasks",
      searchController: searchController,
      builder: (BuildContext context, SearchController controller) {
        return ListTile(
            leading: const Icon(Icons.search_outlined),
            title: const AutoSizeText("Search Tasks",
                maxLines: 1,
                overflow: TextOverflow.visible,
                softWrap: false,
                minFontSize: Constants.small),
            onTap: () {
              controller.openView();
            });
      },
      suggestionsBuilder: (BuildContext context, SearchController controller) {
        if (controller.text.isEmpty) {
          if (searchHistory.isNotEmpty) {
            return searchHistory
                .map((MapEntry<String, int> toDoData) => ListTile(
                      leading: const Icon(Icons.history),
                      title: AutoSizeText(
                        toDoData.key,
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.visible,
                      ),
                      onTap: () => handleHistorySelection(
                          context: context,
                          toDoData: toDoData,
                          controller: controller),
                    ))
                .toList();
          }
          final searchFuture = toDoProvider.mostRecent(limit: 5);
          return [
            buildToDoSelectionList(
                searchFuture: searchFuture, controller: controller)
          ];
        }
        // Search query iterable.
        final searchFuture =
            toDoProvider.searchToDos(searchString: controller.text);
        return [
          buildToDoSelectionList(
              searchFuture: searchFuture, controller: controller)
        ];
      },
    );
  }

  FutureBuilder<List<ToDo>> buildToDoSelectionList(
      {required Future<List<ToDo>> searchFuture,
      required SearchController controller}) {
    return FutureBuilder(
        future: searchFuture,
        builder: (BuildContext context, AsyncSnapshot<List<ToDo>> snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            final List<ToDo>? toDos = snapshot.data;
            if (null != toDos) {
              return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: toDos.length,
                  itemBuilder: (BuildContext context, int index) {
                    return ListTile(
                        title: AutoSizeText(toDos[index].name),
                        onTap: () => handleToDoSelection(
                            context: context,
                            toDo: toDos[index],
                            controller: controller));
                  });
            }
            // This is what to render if no data.
            return const SizedBox.shrink();
          }
          return const Padding(
            padding: EdgeInsets.all(Constants.padding),
            child: CircularProgressIndicator(),
          );
        });
  }
}
