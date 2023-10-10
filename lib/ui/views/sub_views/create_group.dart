import 'dart:async';
import 'dart:math';

import 'package:allocate/providers/group_provider.dart';
import 'package:another_flushbar/flushbar.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:provider/provider.dart';

import '../../../model/task/todo.dart';
import '../../../providers/todo_provider.dart';
import '../../../util/constants.dart';
import '../../../util/exceptions.dart';
import '../../widgets/expanded_listtile.dart';
import '../../widgets/flushbars.dart';
import '../../widgets/listviews.dart';
import '../../widgets/padded_divider.dart';
import '../../widgets/search_recents_bar.dart';
import '../../widgets/tiles.dart';
import '../../widgets/title_bar.dart';
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

  // Limit >= Constants.minLimitPerQuery
  late int limit;

  // Providers
  late final GroupProvider groupProvider;
  late final ToDoProvider toDoProvider;

  // Scrolling
  late final ScrollController toDosScrollController;

  // For linked todos.
  // TODO: Remove this, it's ick.
  late final ScrollController subScrollControllerLeft;
  late final ScrollController subScrollControllerRight;
  late final ScrollPhysics scrollPhysics;

  // For Task search.
  late final SearchController searchController;

  // Name
  late String name;
  late final TextEditingController nameEditingController;
  String? nameErrorText;

  // Description
  late String description;
  late final TextEditingController descriptionEditingController;

  // ToDos.
  late List<ToDo> toDos;

  @override
  void initState() {
    super.initState();
    initializeProviders();
    initializeParameters();
    initializeControllers();
    resetPagination();
  }

  void initializeProviders() {
    groupProvider = Provider.of<GroupProvider>(context, listen: false);
    toDoProvider = Provider.of<ToDoProvider>(context, listen: false);

    toDoProvider.addListener(resetPagination);
  }

  void initializeParameters() {
    loading = true;
    allData = false;
    checkClose = false;
    expanded = true;
    name = "";
    description = "";
    offset = 0;
    limit = Constants.minLimitPerQuery;
    toDos = List.empty(growable: true);
  }

  void initializeControllers() {
    searchController = SearchController();
    toDosScrollController = ScrollController();
    subScrollControllerLeft = ScrollController();
    subScrollControllerRight = ScrollController();

    toDosScrollController.addListener(() async {
      // Bottom: Run the query.
      if (toDosScrollController.offset >=
              toDosScrollController.position.maxScrollExtent &&
          !allData) {
        if (!loading) {
          await appendData();
        }
      }
      // This should have one for when scroll at the top.
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

  @override
  void dispose() {
    nameEditingController.dispose();
    descriptionEditingController.dispose();
    toDosScrollController.dispose();
    subScrollControllerLeft.dispose();
    subScrollControllerRight.dispose();
    toDoProvider.removeListener(resetPagination);
    super.dispose();
  }

  Future<void> resetPagination() async {
    offset = 0;
    limit = max(toDos.length, Constants.minLimitPerQuery);
    await overwriteData();
  }

  Future<void> overwriteData() async {
    setState(() => loading = true);
    List<ToDo> newToDos = await fetchData();
    setState(() {
      offset += newToDos.length;
      toDos = newToDos;
      loading = false;
      allData = toDos.length <= limit;
      limit = Constants.minLimitPerQuery;
    });
  }

  Future<void> appendData() async {
    setState(() => loading = true);
    List<ToDo> newToDos = await fetchData();
    setState(() {
      offset += newToDos.length;
      toDos.addAll(newToDos);
      loading = false;
      allData = newToDos.length < limit;
    });
  }

  Future<List<ToDo>> fetchData() async {
    setState(() => loading = true);
    return await groupProvider
        .getToDosByGroupID(
            id: Constants.initialGroupID, limit: limit, offset: offset)
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

  bool validateData() {
    bool valid = true;

    if (nameEditingController.text.isEmpty) {
      valid = false;
      setState(() => nameErrorText = "Enter Group Name");
    }

    return valid;
  }

  Future<void> handleCreate() async {
    await groupProvider
        .createGroup(name: name, description: description)
        .whenComplete(() async {
      int? groupID = groupProvider.curGroup!.localID;

      print(groupID);

      for (int i = 0; i < toDos.length; i++) {
        toDos[i].groupID = groupID;
        toDos[i].groupIndex = i;
      }

      await toDoProvider
          .updateBatch(toDos: toDos)
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

  Future<void> handleHistorySelection({
    required MapEntry<String, int> data,
  }) async {
    toDoProvider.curToDo =
        await toDoProvider.getToDoByID(id: data.value).catchError((_) {
      Flushbar? error;

      error = Flushbars.createError(
        message: "Error with Task Retrieval",
        context: context,
        dismissCallback: () => error?.dismiss(),
      );

      error.show(context);
      return null;
    });
    // TODO: refactor this more cleanly in provider.
    if (null != toDoProvider.curToDo) {
      toDoProvider.curToDo!.groupID = Constants.initialGroupID;
      await toDoProvider.updateToDo();
    }
  }

  Future<void> handleToDoSelection({required int id}) async {
    toDoProvider.curToDo =
        await toDoProvider.getToDoByID(id: id).catchError((_) {
      Flushbar? error;

      error = Flushbars.createError(
        message: "Error with Task Retrieval",
        context: context,
        dismissCallback: () => error?.dismiss(),
      );

      error.show(context);
      return null;
    });

    // TODO: refactor this more cleanly in provider.
    if (null != toDoProvider.curToDo) {
      toDoProvider.curToDo!.groupID = Constants.initialGroupID;
      await toDoProvider.updateToDo();
    }
  }

  Future<void> handleClose({required bool willDiscard}) async {
    if (willDiscard) {
      for (ToDo toDo in toDos) {
        toDo.groupID = null;
      }
      return await toDoProvider
          .updateBatch()
          .whenComplete(() => Navigator.pop(context))
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
    }

    if (mounted) {
      setState(() => checkClose = false);
    }
  }

  void clearNameField() {
    setState(() {
      checkClose = true;
      nameEditingController.clear();
      name = "";
    });
  }

  Future<void> createAndValidate() async {
    if (validateData()) {
      await handleCreate();
    }
  }

  // This should just reset pagination
  Future<void> createToDo() async {
    await showDialog(
        barrierDismissible: false,
        useRootNavigator: false,
        context: context,
        builder: (BuildContext context) => CreateToDoScreen(
              initialGroup: MapEntry<String, int>(
                  (name.isNotEmpty) ? name : "New Group",
                  Constants.initialGroupID),
            )).catchError((e) {
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

  Future<void> reorderToDos(int oldIndex, int newIndex) async {
    await groupProvider.reorderGroupToDos(
        oldIndex: oldIndex, newIndex: newIndex, toDos: toDos);
  }

  // Write at the end.
  Future<void> completeToDo({required int index, bool value = false}) async {
    setState(() {
      toDos[index].completed = value;
    });

    // toDoProvider.curToDo = toDos[index];
    // This is pretty write heavy.
    // return await toDoProvider.updateToDoAsync();
  }

  Future<void> removeToDo({required int index}) async {
    toDos[index].groupID = null;
    toDoProvider.curToDo = toDos[index];
    await toDoProvider.updateToDo();
  }

  // TODO: refactor this once provider & db query refactored.
  // -RETURN THE OBJECT.
  // TODO: refactor - using the id works better.
  // THIS SHOULD TAKE THE GROUP ID MAPENTRY.
  Future<void> updateToDo({required int index}) async {
    toDoProvider.curToDo = toDos[index];
    showDialog(
        barrierDismissible: false,
        useRootNavigator: false,
        context: context,
        builder: (BuildContext context) => UpdateToDoScreen(
              initialGroup: MapEntry<String, int>(
                  (name.isNotEmpty) ? name : "New Group",
                  Constants.initialGroupID),
            )).catchError((e) {
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
    // TODO: this needs to be factored out once update ToDo refactored.
    resetPagination();
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    bool largeScreen = (width >= Constants.largeScreen);
    bool smallScreen = (width <= Constants.smallScreen);
    bool hugeScreen = (width >= Constants.hugeScreen);
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
                TitleBar(
                  currentContext: context,
                  title: "New Group",
                  checkClose: checkClose,
                  padding:
                      const EdgeInsets.symmetric(horizontal: Constants.padding),
                  handleClose: handleClose,
                ),
                const PaddedDivider(padding: Constants.padding),
                Flexible(
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Flexible(
                            // Name And Description.
                            child: ListView(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: Constants.padding),
                                shrinkWrap: true,
                                controller: subScrollControllerLeft,
                                physics: scrollPhysics,
                                children: [
                              // Title

                              Tiles.nameTile(
                                  context: context,
                                  // TODO: Leading widget?
                                  leading: null,
                                  hintText: "Group Name",
                                  errorText: nameErrorText,
                                  controller: nameEditingController,
                                  outerPadding: const EdgeInsets.only(
                                      left: Constants.padding,
                                      right: Constants.padding,
                                      bottom: Constants.padding),
                                  textFieldPadding: const EdgeInsets.only(
                                    left: Constants.halfPadding,
                                  ),
                                  handleClear: clearNameField),
                              buildToDosTile(physics: scrollPhysics),
                            ])),
                        Flexible(
                          child: Scrollbar(
                            thumbVisibility: true,
                            controller: subScrollControllerRight,
                            child: ListView(
                                controller: subScrollControllerRight,
                                physics: scrollPhysics,
                                shrinkWrap: true,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: Constants.padding),
                                children: [
                                  Tiles.descriptionTile(
                                    controller: descriptionEditingController,
                                    outerPadding: const EdgeInsets.symmetric(
                                        horizontal: Constants.padding),
                                    context: context,
                                  ),
                                ]),
                          ),
                        )
                      ]),
                ),

                const PaddedDivider(padding: Constants.padding),
                Tiles.createButton(
                  outerPadding:
                      const EdgeInsets.symmetric(horizontal: Constants.padding),
                  handleCreate: createAndValidate,
                ),
              ]),
        ),
      ),
    );
  }

  Dialog buildMobileDialog(
      {required BuildContext context, required bool smallScreen}) {
    return Dialog(
      insetPadding: EdgeInsets.all((smallScreen)
          ? Constants.mobileDialogPadding
          : Constants.outerDialogPadding),
      child: Padding(
        padding: const EdgeInsets.all(Constants.padding),
        child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title && Close Button
              TitleBar(
                currentContext: context,
                title: "New Group",
                checkClose: checkClose,
                padding:
                    const EdgeInsets.symmetric(horizontal: Constants.padding),
                handleClose: handleClose,
              ),
              const PaddedDivider(padding: Constants.padding),
              Flexible(
                child: ListView(
                    shrinkWrap: true,
                    controller: toDosScrollController,
                    physics: scrollPhysics,
                    children: [
                      Tiles.nameTile(
                          context: context,
                          // TODO: Leading widget?
                          leading: null,
                          hintText: "Group Name",
                          errorText: nameErrorText,
                          controller: nameEditingController,
                          outerPadding: const EdgeInsets.only(
                              left: Constants.padding,
                              right: Constants.padding,
                              bottom: Constants.padding),
                          textFieldPadding: const EdgeInsets.only(
                            left: Constants.halfPadding,
                          ),
                          handleClear: clearNameField),
                      buildToDosTile(physics: scrollPhysics),
                      const PaddedDivider(padding: Constants.padding),
                      Tiles.descriptionTile(
                        controller: descriptionEditingController,
                        outerPadding: const EdgeInsets.symmetric(
                            horizontal: Constants.padding),
                        context: context,
                      ),
                    ]),
              ),

              const PaddedDivider(padding: Constants.padding),
              Tiles.createButton(
                outerPadding:
                    const EdgeInsets.symmetric(horizontal: Constants.padding),
                handleCreate: createAndValidate,
              ),
            ]),
      ),
    );
  }

  Widget buildToDosTile(
      {ScrollPhysics physics = const NeverScrollableScrollPhysics()}) {
    return ExpandedListTile(
      padding: const EdgeInsets.symmetric(horizontal: Constants.padding),
      expanded: expanded,
      title: const AutoSizeText("Tasks",
          maxLines: 1,
          overflow: TextOverflow.visible,
          softWrap: false,
          minFontSize: Constants.small),
      subtitle: AutoSizeText("${toDos.length} Tasks",
          maxLines: 1,
          overflow: TextOverflow.visible,
          softWrap: false,
          minFontSize: Constants.small),
      children: [
        ListViews.reorderableToDos(
          context: context,
          toDos: toDos,
          physics: physics,
          onReorder: reorderToDos,
          onChanged: completeToDo,
          handleRemove: removeToDo,
          onTap: updateToDo,
        ),
        // TODO: refactor this to take a persistent history object.
        SearchRecents<ToDo>(
          clearOnSelection: true,
          hintText: "Search Tasks",
          padding: const EdgeInsets.all(Constants.padding),
          handleDataSelection: handleToDoSelection,
          handleHistorySelection: handleHistorySelection,
          searchController: searchController,
          mostRecent: toDoProvider.mostRecent,
          search: toDoProvider.searchToDos,
        ),
        Tiles.addTile(
          title: "Add Task",
          onTap: () async => await createToDo(),
        )
      ],
    );
  }
}
