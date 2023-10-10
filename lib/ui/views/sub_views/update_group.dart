import 'dart:async';
import 'dart:math';

import 'package:allocate/providers/group_provider.dart';
import 'package:another_flushbar/flushbar.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:provider/provider.dart';

import '../../../model/task/group.dart';
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

class UpdateGroupScreen extends StatefulWidget {
  const UpdateGroupScreen({Key? key}) : super(key: key);

  @override
  State<UpdateGroupScreen> createState() => _UpdateGroupScreen();
}

class _UpdateGroupScreen extends State<UpdateGroupScreen> {
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

  // TODO: remove these once page has been refactored properly
  late final ScrollController subScrollControllerRight;
  late final ScrollController subScrollControllerLeft;
  late final ScrollPhysics scrollPhysics;

  // For Task search.
  late final SearchController toDoSearchController;

  // Name
  late final TextEditingController nameEditingController;
  String? nameErrorText;

  // Description
  late final TextEditingController descriptionEditingController;

  // Discarded todos
  late final List<ToDo> discards;

  Group get group => groupProvider.curGroup!;
  late Group prevGroup;

  // Convenience getter.
  List<ToDo> get toDos => groupProvider.curGroup!.toDos;

  set toDos(List<ToDo> newToDos) => groupProvider.curGroup!.toDos = newToDos;

  @override
  void initState() {
    super.initState();
    initializeProviders();
    initializeParameters();
    initializeControllers();
    resetPagination().whenComplete(() {
      prevGroup.toDos = List.from(group.toDos);
    });
    prevGroup = group.copy();
    prevGroup.id = group.id;
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
    offset = (toDoProvider.rebuild) ? 0 : toDoProvider.toDos.length;
    limit = Constants.minLimitPerQuery;
    discards = [];
    toDos = List.empty(growable: true);
  }

  void initializeControllers() {
    toDosScrollController = ScrollController();
    subScrollControllerLeft = ScrollController();
    subScrollControllerRight = ScrollController();

    // TODO: refactor this -> should be a button.
    toDosScrollController.addListener(() async {
      if (toDosScrollController.offset >=
              toDosScrollController.position.maxScrollExtent &&
          !allData) {
        if (!loading) {
          await appendData();
        }
      }
    });

    scrollPhysics =
        const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics());
    nameEditingController = TextEditingController(text: group.name);
    nameEditingController.addListener(() {
      nameErrorText = null;
      checkClose = true;
      String newText = nameEditingController.text;
      SemanticsService.announce(newText, Directionality.of(context));
      setState(() => group.name = newText);
    });
    descriptionEditingController =
        TextEditingController(text: group.description);
    descriptionEditingController.addListener(() {
      checkClose = true;
      String newText = descriptionEditingController.text;
      SemanticsService.announce(newText, Directionality.of(context));
      group.description = newText;
    });
    toDoSearchController = SearchController();
    toDoSearchController.addListener(() {
      String newText = toDoSearchController.text;
      SemanticsService.announce(newText, Directionality.of(context));
    });
  }

  @override
  void dispose() {
    nameEditingController.dispose();
    descriptionEditingController.dispose();
    toDosScrollController.dispose();
    subScrollControllerLeft.dispose();
    subScrollControllerRight.dispose();
    toDoSearchController.dispose();
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
        .getToDosByGroupID(id: group.id, limit: limit, offset: offset)
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

  void clearNameField() {
    setState(() {
      checkClose = true;
      nameEditingController.clear();
      group.name = "";
    });
  }

  Future<void> handleHistorySelection({
    required int id,
  }) async {
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
      toDoProvider.curToDo!.groupID = group.id;
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
      toDoProvider.curToDo!.groupID = group.id;
      await toDoProvider.updateToDo();
    }
  }

  Future<void> handleClose({required bool willDiscard}) async {
    if (willDiscard) {
      for (ToDo toDo in prevGroup.toDos) {
        toDos.remove(toDo);
        toDo.groupID = prevGroup.id;
      }

      for (ToDo toDo in toDos) {
        toDo.groupID = null;
        prevGroup.toDos.add(toDo);
      }

      groupProvider.curGroup = prevGroup;
      await toDoProvider.updateBatch(toDos: toDos).catchError((e) {
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
      return await groupProvider
          .updateGroup()
          .whenComplete(() => Navigator.pop(context));
    }

    if (mounted) {
      setState(() => checkClose = false);
    }
  }

  // This should just reset pagination
  Future<void> createToDo() async {
    checkClose = true;
    await showDialog(
        barrierDismissible: false,
        useRootNavigator: false,
        context: context,
        builder: (BuildContext context) => CreateToDoScreen(
              initialGroup: MapEntry<String, int>(
                  (group.name.isNotEmpty) ? group.name : "New Group", group.id),
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

  // Write at the end
  Future<void> completeToDo({required int index, bool value = false}) async {
    setState(() {
      toDos[index].completed = value;
    });

    // This feels pretty write-heavy.
    //return await toDoProvider.updateToDo();
  }

  // TODO: refactor once provider cleaned up
  Future<void> removeToDo({required int index}) async {
    checkClose = true;

    toDos[index].groupID = null;
    toDoProvider.curToDo = toDos[index];
    await toDoProvider.updateToDo();
  }

  Future<void> updateToDo({required int index}) async {
    toDoProvider.curToDo = toDos[index];
    showDialog(
        barrierDismissible: false,
        useRootNavigator: false,
        context: context,
        builder: (BuildContext context) => UpdateToDoScreen(
              initialGroup: MapEntry<String, int>(
                  (group.name.isNotEmpty) ? group.name : "New Group", group.id),
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

  Future<void> updateAndValidate() async {
    if (validateData()) {
      await handleUpdate();
    }
  }

  Future<void> handleUpdate() async {
    await groupProvider.updateGroup().whenComplete(() async {
      int? groupID = groupProvider.curGroup!.id;

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

  Future<void> handleDelete() async {
    return await groupProvider.deleteGroup().whenComplete(() {
      Navigator.pop(context);
    });
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
                  title: "Edit Group",
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
                Tiles.updateAndDeleteButtons(
                  handleDelete: handleDelete,
                  handleUpdate: handleUpdate,
                  updateButtonPadding:
                      const EdgeInsets.symmetric(horizontal: Constants.padding),
                  deleteButtonPadding:
                      const EdgeInsets.symmetric(horizontal: Constants.padding),
                )
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
                title: "Edit Group",
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
              Tiles.updateAndDeleteButtons(
                handleDelete: handleDelete,
                handleUpdate: handleUpdate,
                updateButtonPadding:
                    const EdgeInsets.symmetric(horizontal: Constants.padding),
                deleteButtonPadding:
                    const EdgeInsets.symmetric(horizontal: Constants.padding),
              )
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
        (loading) ? const CircularProgressIndicator() : const SizedBox.shrink(),
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
        SearchRecentsBar<ToDo>(
          clearOnSelection: true,
          hintText: "Search Tasks",
          padding: const EdgeInsets.all(Constants.padding),
          handleDataSelection: handleToDoSelection,
          handleHistorySelection: handleHistorySelection,
          searchController: toDoSearchController,
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
