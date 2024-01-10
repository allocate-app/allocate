import 'dart:async';
import 'dart:io';

import 'package:another_flushbar/flushbar.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:provider/provider.dart';

import '../../../model/task/todo.dart';
import '../../../providers/group_provider.dart';
import '../../../providers/todo_provider.dart';
import '../../../providers/user_provider.dart';
import '../../../util/constants.dart';
import '../../../util/enums.dart';
import '../../../util/exceptions.dart';
import '../../widgets/expanded_listtile.dart';
import '../../widgets/flushbars.dart';
import '../../widgets/listtile_widgets.dart';
import '../../widgets/listviews.dart';
import '../../widgets/padded_divider.dart';
import '../../widgets/paginating_listview.dart';
import '../../widgets/search_recents_bar.dart';
import '../../widgets/subtitles.dart';
import '../../widgets/tiles.dart';
import '../../widgets/title_bar.dart';
import '../sub_views.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

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
  late final UserProvider userProvider;

  // Scrolling
  late final ScrollController mobileScrollController;
  late final ScrollController desktopScrollController;
  late final ScrollPhysics scrollPhysics;

  // For Task search.
  late final SearchController toDoSearchController;

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
  }

  void initializeProviders() {
    groupProvider = Provider.of<GroupProvider>(context, listen: false);
    toDoProvider = Provider.of<ToDoProvider>(context, listen: false);
    userProvider = Provider.of<UserProvider>(context, listen: false);
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
    desktopScrollController = ScrollController();
    mobileScrollController = ScrollController();

    ScrollPhysics parentPhysics = (Platform.isIOS || Platform.isMacOS)
        ? const BouncingScrollPhysics()
        : const ClampingScrollPhysics();
    scrollPhysics = AlwaysScrollableScrollPhysics(parent: parentPhysics);
    nameEditingController = TextEditingController();
    nameEditingController.addListener(() {
      String newText = nameEditingController.text;
      if (null != nameErrorText && mounted) {
        setState(() {
          nameErrorText = null;
        });
      }

      SemanticsService.announce(newText, Directionality.of(context));
      name = newText;
    });
    descriptionEditingController = TextEditingController();
    descriptionEditingController.addListener(() {
      String newText = descriptionEditingController.text;
      SemanticsService.announce(newText, Directionality.of(context));
      description = newText;
    });

    toDoSearchController = SearchController();
  }

  @override
  void dispose() {
    nameEditingController.dispose();
    descriptionEditingController.dispose();
    mobileScrollController.dispose();
    desktopScrollController.dispose();
    toDoSearchController.dispose();
    super.dispose();
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
    // in case the usr doesn't submit to the textfields
    name = nameEditingController.text;
    description = descriptionEditingController.text;

    await groupProvider
        .createGroup(name: name, description: description)
        .whenComplete(() async {
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

  Future<void> handleSelection({
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
    if (null == toDo) {
      return;
    }
    if (Constants.intMax == toDo.groupID) {
      return;
    }

    toDo.groupID = Constants.intMax;
    toDo.groupIndex = toDos.length;
    await toDoProvider.updateToDo(toDo: toDo);
  }

  Future<void> handleClose({required bool willDiscard}) async {
    if (willDiscard) {
      for (ToDo toDo in toDos) {
        toDo.groupID = null;
      }
      return await toDoProvider
          .updateBatch(toDos: toDos)
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
      checkClose = (groupProvider.user?.checkClose ?? true);
      nameEditingController.clear();
      name = "";
    });
  }

  void updateName() {
    if (mounted) {
      setState(() {
        checkClose = (groupProvider.user?.checkClose ?? true);
        name = nameEditingController.text;
      });
    }
  }

  void updateDescription() {
    if (mounted) {
      setState(() {
        checkClose = (groupProvider.user?.checkClose ?? true);
        description = descriptionEditingController.text;
      });
    }
  }

  Future<void> createAndValidate() async {
    if (validateData()) {
      await handleCreate();
    }
  }

  void onFetch({List<ToDo>? items}) {
    if (null == items) {
      return;
    }
    for (ToDo toDo in items) {
      toDo.fade = Fade.fadeIn;
    }
  }

  Future<void> onRemove({ToDo? item}) async {
    if (null == item) {
      return;
    }
    if (mounted) {
      setState(() => item.fade = Fade.fadeOut);
      await Future.delayed(const Duration(milliseconds: Constants.fadeInTime));
    }
  }

  @override
  Widget build(BuildContext context) {
    MediaQuery.sizeOf(context);
    return (userProvider.largeScreen)
        ? buildDesktopDialog(
            context: context, smallScreen: userProvider.smallScreen)
        : buildMobileDialog(
            context: context, smallScreen: userProvider.smallScreen);
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
                  title: "New Group",
                  checkClose: checkClose,
                  padding: const EdgeInsets.symmetric(
                      horizontal: Constants.halfPadding),
                  handleClose: handleClose,
                ),
                const PaddedDivider(padding: Constants.halfPadding),
                Flexible(
                  child: Scrollbar(
                    thumbVisibility: true,
                    controller: desktopScrollController,
                    child: ListView(
                      shrinkWrap: true,
                      physics: scrollPhysics,
                      controller: desktopScrollController,
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
                                      leading: ListTileWidgets.groupIcon(
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
                                      outerPadding: const EdgeInsets.symmetric(
                                          vertical: Constants.padding),
                                      textFieldPadding: const EdgeInsets.only(
                                        left: Constants.padding,
                                      ),
                                      handleClear: clearNameField,
                                      onEditingComplete: updateName,
                                    ),
                                    buildToDosTile(),
                                  ])),
                              Flexible(
                                child: ListView(
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    shrinkWrap: true,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: Constants.padding),
                                    children: [
                                      Tiles.descriptionTile(
                                        minLines: Constants.desktopMinLines,
                                        maxLines: Constants
                                            .desktopMaxLinesBeforeScroll,
                                        controller:
                                            descriptionEditingController,
                                        outerPadding: const EdgeInsets.all(
                                            Constants.padding),
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

                const PaddedDivider(padding: Constants.halfPadding),
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
              const PaddedDivider(padding: Constants.halfPadding),
              Flexible(
                child: ListView(
                    shrinkWrap: true,
                    controller: mobileScrollController,
                    physics: scrollPhysics,
                    children: [
                      Tiles.nameTile(
                          context: context,
                          leading: ListTileWidgets.groupIcon(
                              currentContext: context,
                              iconPadding:
                                  const EdgeInsets.all(Constants.padding),
                              outerPadding: const EdgeInsets.symmetric(
                                horizontal: Constants.halfPadding,
                              )),
                          hintText: "Group Name",
                          errorText: nameErrorText,
                          controller: nameEditingController,
                          outerPadding: const EdgeInsets.symmetric(
                              vertical: Constants.padding),
                          textFieldPadding: const EdgeInsets.only(
                            left: Constants.padding,
                          ),
                          handleClear: clearNameField,
                          onEditingComplete: updateName),
                      buildToDosTile(),
                      const PaddedDivider(padding: Constants.padding),
                      Tiles.descriptionTile(
                        controller: descriptionEditingController,
                        onEditingComplete: updateDescription,
                        outerPadding: const EdgeInsets.symmetric(
                            horizontal: Constants.padding),
                        context: context,
                      ),
                    ]),
              ),

              const PaddedDivider(padding: Constants.halfPadding),
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
      initiallyExpanded: expanded,
      title: const AutoSizeText("Tasks",
          maxLines: 1,
          overflow: TextOverflow.visible,
          softWrap: false,
          minFontSize: Constants.large),
      subtitle: Subtitles.groupSubtitle(
          toDoCount: groupProvider.getToDoCount(id: Constants.intMax)!),
      children: [
        PaginatingListview<ToDo>(
            items: toDos,
            query: (
                    {int limit = Constants.minLimitPerQuery,
                    int offset = 0}) async =>
                await groupProvider.getToDosByGroupID(
                    id: Constants.intMax, limit: limit, offset: offset),
            offset: toDos.length,
            indicatorDisplacement: 0.0,
            rebuildNotifiers: [toDoProvider],
            rebuildCallback: ({required List<ToDo> items}) {
              toDos = items;
              groupProvider.setToDoCount(id: Constants.intMax);
            },
            onFetch:
                (userProvider.curUser?.reduceMotion ?? false) ? null : onFetch,
            onRemove:
                (userProvider.curUser?.reduceMotion ?? false) ? null : onRemove,
            listviewBuilder: (
                {Key? key,
                required BuildContext context,
                required List<ToDo> items,
                void Function({ToDo? item})? onRemove}) {
              return ListViews.reorderableGroupToDos(
                key: key,
                context: context,
                toDos: toDos,
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
                  if (null != onRemove) {
                    onRemove(item: toDo);
                  }
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
                                (name.isNotEmpty) ? name : "New Group",
                                Constants.intMax),
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
                        (name.isNotEmpty) ? name : "New Group",
                        Constants.intMax),
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
