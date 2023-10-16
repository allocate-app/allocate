import 'dart:async';
import 'dart:math';

import 'package:another_flushbar/flushbar.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:provider/provider.dart';

import '../../../../providers/group_provider.dart';
import '../../../model/task/group.dart';
import '../../../model/task/todo.dart';
import '../../../providers/todo_provider.dart';
import '../../../util/constants.dart';
import '../../../util/exceptions.dart';
import '../../widgets/expanded_listtile.dart';
import '../../widgets/flushbars.dart';
import '../../widgets/leading_widgets.dart';
import '../../widgets/listviews.dart';
import '../../widgets/padded_divider.dart';
import '../../widgets/search_recents_bar.dart';
import '../../widgets/subtitles.dart';
import '../../widgets/tiles.dart';
import '../../widgets/title_bar.dart';
import '../sub_views.dart';

class UpdateGroupScreen extends StatefulWidget {
  final Group? initialGroup;

  const UpdateGroupScreen({Key? key, this.initialGroup}) : super(key: key);

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
  late final ScrollController desktopScrollController;
  late final ScrollController mobileScrollController;
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

    if (null != widget.initialGroup) {
      groupProvider.curGroup = widget.initialGroup;
    }
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
    mobileScrollController = ScrollController();
    desktopScrollController = ScrollController();

    scrollPhysics =
        const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics());
    nameEditingController = TextEditingController(text: group.name);
    nameEditingController.addListener(() {
      nameErrorText = null;
      checkClose = true;
      String newText = nameEditingController.text;
      SemanticsService.announce(newText, Directionality.of(context));
      if (mounted) {
        return setState(() => group.name = newText);
      }
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
    desktopScrollController.dispose();
    mobileScrollController.dispose();
    toDoSearchController.dispose();
    toDoProvider.removeListener(resetPagination);
    super.dispose();
  }

  Future<void> resetPagination() async {
    offset = 0;
    limit = max(toDos.length, Constants.minLimitPerQuery);
    return await overwriteData();
  }

  Future<void> overwriteData() async {
    List<ToDo> newToDos = await fetchData();
    if (mounted) {
      return setState(() {
        offset += newToDos.length;
        toDos = newToDos;
        loading = false;
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
      if (mounted) {
        setState(() => nameErrorText = "Enter Group Name");
      }
    }

    return valid;
  }

  void clearNameField() {
    if (mounted) {
      return setState(() {
        checkClose = true;
        nameEditingController.clear();
        group.name = "";
      });
    }
  }

  // These are the same method, TODO: consolidate.
  Future<void> handleHistorySelection({
    required int id,
  }) async {
    ToDo? toDo = await toDoProvider.getToDoByID(id: id).catchError((_) {
      Flushbar? error;

      error = Flushbars.createError(
        message: "Error with Task Retrieval",
        context: context,
        dismissCallback: () => error?.dismiss(),
      );

      error.show(context);
      return null;
    });
    if (null != toDo) {
      toDo.groupID = group.id;
      await toDoProvider.updateToDo(toDo: toDo);
    }
  }

  Future<void> handleToDoSelection({required int id}) async {
    ToDo? toDo = await toDoProvider.getToDoByID(id: id).catchError((_) {
      Flushbar? error;

      error = Flushbars.createError(
        message: "Error with Task Retrieval",
        context: context,
        dismissCallback: () => error?.dismiss(),
      );

      error.show(context);
      return null;
    });

    if (null != toDo) {
      toDo.groupID = group.id;
      await toDoProvider.updateToDo(toDo: toDo);
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
          .updateGroup(group: prevGroup)
          .whenComplete(() => Navigator.pop(context));
    }

    if (mounted) {
      return setState(() => checkClose = false);
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

  // Future<void> reorderToDos(int oldIndex, int newIndex) async {
  //   await groupProvider.reorderGroupToDos(
  //       oldIndex: oldIndex, newIndex: newIndex, toDos: toDos);
  // }

  // Write at the end
  Future<void> completeToDo({required int index, bool value = false}) async {
    if (mounted) {
      return setState(() {
        toDos[index].completed = value;
      });
    }
  }

  Future<void> removeToDo({required int index}) async {
    checkClose = true;

    toDos[index].groupID = null;
    await toDoProvider.updateToDo(toDo: toDos[index]);
  }

  Future<void> updateToDo({required int index}) async {
    await showDialog(
        barrierDismissible: false,
        useRootNavigator: false,
        context: context,
        builder: (BuildContext context) => UpdateToDoScreen(
              initialToDo: toDos[index],
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
            const BoxConstraints(maxHeight: Constants.maxDesktopDialogSide),
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
                  child: Scrollbar(
                    thumbVisibility: true,
                    controller: desktopScrollController,
                    child: ListView(
                      shrinkWrap: true,
                      controller: desktopScrollController,
                      physics: scrollPhysics,
                      children: [
                        Row(
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
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      children: [
                                    // Title
                                    Tiles.nameTile(
                                        context: context,
                                        leading: LeadingWidgets.groupIcon(
                                            currentContext: context,
                                            iconPadding: const EdgeInsets.all(
                                                Constants.padding),
                                            outerPadding:
                                                const EdgeInsets.symmetric(
                                              horizontal: Constants.halfPadding,
                                            )),
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
                                    buildToDosTile(),
                                  ])),
                              Flexible(
                                child: ListView(
                                    shrinkWrap: true,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: Constants.padding),
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    children: [
                                      Tiles.descriptionTile(
                                        minLines: Constants.desktopMinLines,
                                        maxLines: Constants
                                            .desktopMaxLinesBeforeScroll,
                                        controller:
                                            descriptionEditingController,
                                        outerPadding:
                                            const EdgeInsets.symmetric(
                                                horizontal: Constants.padding),
                                        context: context,
                                      ),
                                    ]),
                              )
                            ]),
                      ],
                    ),
                  ),
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
                    controller: mobileScrollController,
                    physics: scrollPhysics,
                    children: [
                      Tiles.nameTile(
                          context: context,
                          leading: LeadingWidgets.groupIcon(
                              currentContext: context,
                              iconPadding:
                                  const EdgeInsets.all(Constants.padding),
                              outerPadding: const EdgeInsets.symmetric(
                                horizontal: Constants.halfPadding,
                              )),
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
                      buildToDosTile(),
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
      outerPadding: const EdgeInsets.symmetric(horizontal: Constants.padding),
      expanded: expanded,
      title: const AutoSizeText("Tasks",
          maxLines: 1,
          overflow: TextOverflow.visible,
          softWrap: false,
          minFontSize: Constants.large),
      subtitle: Subtitles.groupSubtitle(numTasks: toDos.length),
      children: [
        // This is too jarring. The database is too fast.
        // (loading) ? const CircularProgressIndicator() : const SizedBox.shrink(),
        ListViews.reorderableGroupToDos(
          context: context,
          toDos: toDos,
          physics: physics,
          onChanged: completeToDo,
          handleRemove: removeToDo,
          onTap: updateToDo,
        ),
        (!allData)
            ? Tiles.fetchTile(onTap: appendData)
            : const SizedBox.shrink(),
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
