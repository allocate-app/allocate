import 'dart:async';

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
import '../../widgets/paginating_listview.dart';
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

  Group get group => groupProvider.curGroup!;
  late Group prevGroup;

  @override
  void initState() {
    super.initState();
    initializeProviders();
    initializeParameters();
    initializeControllers();
    prevGroup = group.copy();
    prevGroup.id = group.id;
  }

  void initializeProviders() {
    groupProvider = Provider.of<GroupProvider>(context, listen: false);
    toDoProvider = Provider.of<ToDoProvider>(context, listen: false);

    if (null != widget.initialGroup) {
      groupProvider.curGroup = widget.initialGroup;
    }
    // toDoProvider.addListener(resetPagination);
  }

  void initializeParameters() {
    loading = true;
    allData = false;
    checkClose = false;
    expanded = true;
    offset = (toDoProvider.rebuild) ? 0 : toDoProvider.toDos.length;
    limit = Constants.minLimitPerQuery;
  }

  void initializeControllers() {
    mobileScrollController = ScrollController();
    desktopScrollController = ScrollController();

    scrollPhysics =
        const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics());
    nameEditingController = TextEditingController(text: group.name);
    nameEditingController.addListener(() {
      if (null != nameErrorText && mounted) {
        setState(() {
          nameErrorText = null;
        });
      }
      SemanticsService.announce(
          nameEditingController.text, Directionality.of(context));
    });
    descriptionEditingController =
        TextEditingController(text: group.description);
    descriptionEditingController.addListener(() {
      String newText = descriptionEditingController.text;
      SemanticsService.announce(newText, Directionality.of(context));
    });
    toDoSearchController = SearchController();
  }

  @override
  void dispose() {
    nameEditingController.dispose();
    descriptionEditingController.dispose();
    desktopScrollController.dispose();
    mobileScrollController.dispose();
    toDoSearchController.dispose();
    super.dispose();
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
      setState(() {
        checkClose = true;
        nameEditingController.clear();
        group.name = "";
      });
    }
  }

  void updateName() {
    if (mounted) {
      setState(() {
        checkClose = true;
        group.name = nameEditingController.text;
      });
    }
  }

  void updateDescription() {
    if (mounted) {
      setState(() {
        checkClose = true;
        group.description = descriptionEditingController.text;
      });
    }
  }

  Future<void> handleSelection({required int id}) async {
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

    if (null == toDo) {
      return;
    }
    if (group.id == toDo.groupID) {
      return;
    }

    toDo.groupID = group.id;
    toDo.groupIndex = group.toDos.length;
    await toDoProvider.updateToDo(toDo: toDo);
  }

  void handleClose({required bool willDiscard}) {
    if (willDiscard) {
      return Navigator.pop(context);
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

  Future<void> updateAndValidate() async {
    if (validateData()) {
      await handleUpdate();
    }
  }

  Future<void> handleUpdate() async {
    // in case the usr doesn't submit to the textfields
    group.name = nameEditingController.text;
    group.description = descriptionEditingController.text;

    await groupProvider.updateGroup().whenComplete(() {
      Navigator.pop(context);
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
    await groupProvider.deleteGroup().whenComplete(() {
      Navigator.pop(context);
    }).catchError((e) {
      Flushbar? error;

      error = Flushbars.createError(
        message: e.cause,
        context: context,
        dismissCallback: () => error?.dismiss(),
      );

      error.show(context);
    }, test: (e) => e is FailureToDeleteException);
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
                                        handleClear: clearNameField,
                                        onEditingComplete: updateName),
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
                                        onEditingComplete: updateDescription,
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
                          handleClear: clearNameField,
                          onEditingComplete: updateName),
                      buildToDosTile(),
                      const PaddedDivider(padding: Constants.padding),
                      Tiles.descriptionTile(
                        controller: descriptionEditingController,
                        outerPadding: const EdgeInsets.symmetric(
                            horizontal: Constants.padding),
                        context: context,
                        onEditingComplete: updateDescription,
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

  // This could be factored into the tiles class.
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
      subtitle: Subtitles.groupSubtitle(
          toDoCount: groupProvider.getToDoCount(id: group.id)!),
      children: [
        // This is too jarring. The database is too fast.
        // (loading) ? const CircularProgressIndicator() : const SizedBox.shrink(),
        PaginatingListview<ToDo>(
            items: group.toDos,
            query: (
                    {int limit = Constants.minLimitPerQuery,
                    int offset = 0}) async =>
                await groupProvider.getToDosByGroupID(
                    id: group.id, limit: limit, offset: offset),
            offset: group.toDos.length,
            paginateButton: true,
            rebuildNotifiers: [toDoProvider],
            rebuildCallback: ({required List<ToDo> items}) {
              group.toDos = items;
              groupProvider.setToDoCount(id: group.id, count: items.length);
            },
            listviewBuilder: (
                {Key? key,
                required BuildContext context,
                required List<ToDo> items}) {
              return ListViews.reorderableGroupToDos(
                key: key,
                context: context,
                toDos: items,
                physics: physics,
                onChanged: ({ToDo? toDo, bool? value}) async {
                  if (null == toDo) {
                    return;
                  }
                  toDo.completed = value!;
                  await toDoProvider.updateToDo(toDo: toDo);
                },
                handleRemove: ({ToDo? toDo}) async {
                  if (null == toDo) {
                    return;
                  }
                  toDo.groupIndex = -1;
                  toDo.groupID = null;
                  await toDoProvider.updateToDo(toDo: toDo);
                },
                onTap: ({ToDo? toDo}) async {
                  if (null == toDo) {
                    return;
                  }
                  return await showDialog(
                      barrierDismissible: false,
                      useRootNavigator: false,
                      context: context,
                      builder: (BuildContext context) => UpdateToDoScreen(
                            initialToDo: toDo,
                            initialGroup: MapEntry<String, int>(
                                (group.name.isNotEmpty)
                                    ? group.name
                                    : "New Group",
                                group.id),
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
                          e is FailureToCreateException ||
                          e is FailureToUploadException);
                },
              );
            }),
        SearchRecentsBar<ToDo>(
          border: BorderSide.none,
          clearOnSelection: true,
          hintText: "Search Tasks",
          padding: const EdgeInsets.all(Constants.padding),
          handleDataSelection: handleSelection,
          searchController: toDoSearchController,
          dispose: false,
          mostRecent: toDoProvider.mostRecent,
          search: toDoProvider.searchToDos,
        ),
        Tiles.addTile(
          title: "Add Task",
          onTap: () async => await showDialog(
              barrierDismissible: false,
              useRootNavigator: false,
              context: context,
              builder: (BuildContext context) => CreateToDoScreen(
                    initialGroup: MapEntry<String, int>(
                        (group.name.isNotEmpty) ? group.name : "New Group",
                        group.id),
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
                  e is FailureToCreateException ||
                  e is FailureToUploadException),
        )
      ],
    );
  }
}
