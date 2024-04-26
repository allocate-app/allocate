import 'dart:async';
import 'dart:io';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:provider/provider.dart';

import '../../../model/task/todo.dart';
import '../../../providers/application/layout_provider.dart';
import '../../../providers/model/group_provider.dart';
import '../../../providers/model/todo_provider.dart';
import '../../../providers/viewmodels/group_viewmodel.dart';
import '../../../providers/viewmodels/todo_viewmodel.dart';
import '../../../util/constants.dart';
import '../../../util/enums.dart';
import '../../../util/exceptions.dart';
import '../../blurred_dialog.dart';
import '../../widgets/expanded_listtile.dart';
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
  late ValueNotifier<bool> _checkClose;
  late ValueNotifier<bool> _createLoading;
  late ValueNotifier<String?> _nameErrorText;

  // Providers
  late final GroupViewModel vm;
  late final GroupProvider groupProvider;

  late final ToDoViewModel tVM;
  late final ToDoProvider toDoProvider;
  late final LayoutProvider layoutProvider;

  // Scrolling
  late final ScrollController mobileScrollController;
  late final ScrollController desktopScrollController;
  late final ScrollPhysics scrollPhysics;

  // Controllers
  late final SearchController toDoSearchController;
  late final TextEditingController nameEditingController;
  late final TextEditingController descriptionEditingController;

  @override
  void initState() {
    super.initState();
    initializeProviders();
    initializeParameters();
    initializeControllers();
  }

  void initializeProviders() {
    vm = Provider.of<GroupViewModel>(context, listen: false);
    vm.clear();
    tVM = Provider.of<ToDoViewModel>(context, listen: false);
    tVM.clear();
    groupProvider = Provider.of<GroupProvider>(context, listen: false);
    toDoProvider = Provider.of<ToDoProvider>(context, listen: false);
    layoutProvider = Provider.of<LayoutProvider>(context, listen: false);
  }

  void initializeParameters() {
    _checkClose = ValueNotifier(false);
    _createLoading = ValueNotifier(false);
    _nameErrorText = ValueNotifier(null);
  }

  void initializeControllers() {
    desktopScrollController = ScrollController();
    mobileScrollController = ScrollController();

    ScrollPhysics parentPhysics = (Platform.isIOS || Platform.isMacOS)
        ? const BouncingScrollPhysics()
        : const ClampingScrollPhysics();
    scrollPhysics = AlwaysScrollableScrollPhysics(parent: parentPhysics);

    nameEditingController = TextEditingController();
    nameEditingController.addListener(watchName);

    descriptionEditingController = TextEditingController();
    descriptionEditingController.addListener(watchDescription);

    toDoSearchController = SearchController();
  }

  @override
  void dispose() {
    nameEditingController.removeListener(watchName);
    nameEditingController.dispose();
    descriptionEditingController.removeListener(watchDescription);
    descriptionEditingController.dispose();
    mobileScrollController.dispose();
    desktopScrollController.dispose();
    toDoSearchController.dispose();
    super.dispose();
  }

  void watchName() {
    _checkClose.value = groupProvider.userViewModel?.checkClose ?? true;
    String newText = nameEditingController.text;
    SemanticsService.announce(newText, Directionality.of(context));
    vm.name = newText;
    if (null != _nameErrorText.value) {
      _nameErrorText.value = null;
    }
  }

  void watchDescription() {
    _checkClose.value = groupProvider.userViewModel?.checkClose ?? true;
    String newText = descriptionEditingController.text;
    SemanticsService.announce(newText, Directionality.of(context));
    vm.description = newText;
  }

  bool validateData() {
    bool valid = true;

    if (nameEditingController.text.isEmpty) {
      valid = false;
      _nameErrorText.value = "Enter Group Name";
      if (desktopScrollController.hasClients) {
        desktopScrollController.jumpTo(0);
      }
      if (mobileScrollController.hasClients) {
        mobileScrollController.jumpTo(0);
      }
    }

    return valid;
  }

  // This should still run even if the online throws.
  // If local create fails, something is very wrong => pop context and escape
  Future<void> handleCreate() async {
    await groupProvider.createGroup(vm.toModel()).catchError((e) async {
      await Tiles.displayError(e: e);
    }).whenComplete(() {
      vm.clear();
      _popScreen();
    });
  }

  Future<void> handleSelection({
    required int id,
  }) async {
    ToDo? toDo = await toDoProvider.getToDoByID(id: id).catchError((_) {
      Tiles.displayError(e: TaskNotFoundException("Error with task Retrieval"));
      return null;
    });
    if (null == toDo) {
      return;
    }
    if (vm.id == toDo.groupID) {
      return;
    }

    toDo.groupID = vm.id;
    toDo.groupIndex = vm.toDos.length;
    await toDoProvider.updateToDo(toDo: toDo);
  }

  void _popScreen() {
    if (mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> handleClose({required bool willDiscard}) async {
    if (willDiscard) {
      for (ToDo toDo in vm.toDos) {
        toDo.groupID = null;
      }
      return await toDoProvider
          .updateBatch(toDos: vm.toDos)
          .catchError((e) async {
        await Tiles.displayError(e: e);
      }).whenComplete(() {
        vm.clear();
        _popScreen();
      });
    }
    _checkClose.value = false;
  }

  Future<void> createAndValidate() async {
    _createLoading.value = true;
    if (validateData()) {
      await handleCreate();
    }
    _createLoading.value = false;
  }

  void onFetch({List<ToDo>? items}) {
    if (null == items) {
      return;
    }
    DateTime threshold = DateTime.now();
    threshold = threshold.copyWith(
        millisecond: threshold.millisecond - Constants.newItemThreshold);
    for (ToDo toDo in items) {
      if (!toDo.lastUpdated.isBefore(threshold)) {
        toDo.fade = Fade.fadeIn;
      }
    }
  }

  Future<void> onRemove({ToDo? item}) async {
    if (null == item) {
      return;
    }
    if (mounted) {
      setState(() => item.fade = Fade.fadeOut);
      await Future.delayed(const Duration(milliseconds: Constants.fadeOutTime));
    }
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          if (layoutProvider.largeScreen) {
            return _buildDesktopDialog(
              context: context,
            );
          }
          return _buildMobileDialog(
              context: context, smallScreen: layoutProvider.smallScreen);
        },
      );

  Dialog _buildDesktopDialog({required BuildContext context}) {
    Widget innerList = ListView(
      padding: const EdgeInsets.only(
        top: Constants.halfPadding,
        left: Constants.padding,
        right: Constants.padding,
      ),
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
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                    // Name

                    _buildNameTile(),

                    _buildToDosTile(),
                  ])),
              Flexible(
                child: ListView(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(
                        vertical: Constants.padding,
                        horizontal: Constants.halfPadding),
                    children: [
                      _buildDescriptionTile(
                          minLines: Constants.desktopMinLines,
                          maxLines: Constants.desktopMaxLinesBeforeScroll)
                    ]),
              )
            ]),
      ],
    );

    return Dialog(
      insetPadding: const EdgeInsets.all(Constants.outerDialogPadding),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
            maxHeight: Constants.maxDesktopDialogHeight,
            maxWidth: Constants.maxDesktopDialogWidth),
        child: Padding(
          padding: const EdgeInsets.all(Constants.padding),
          child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Title && Close Button
                _buildTitleBar(),

                const PaddedDivider(padding: Constants.halfPadding),
                Flexible(
                  child: Material(
                    color: Colors.transparent,
                    child: (layoutProvider.isMobile)
                        ? Scrollbar(
                            controller: desktopScrollController,
                            child: innerList,
                          )
                        : innerList,
                  ),
                ),

                const PaddedDivider(padding: Constants.halfPadding),
                _buildCreateButton(),
              ]),
        ),
      ),
    );
  }

  Dialog _buildMobileDialog(
      {required BuildContext context, required bool smallScreen}) {
    Widget innerList = ListView(
        padding: const EdgeInsets.symmetric(horizontal: Constants.padding),
        shrinkWrap: true,
        controller: mobileScrollController,
        physics: scrollPhysics,
        children: [
          _buildNameTile(),
          _buildToDosTile(),
          const PaddedDivider(padding: Constants.padding),
          _buildDescriptionTile(mobile: smallScreen),
        ]);

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

              _buildTitleBar(),

              const PaddedDivider(padding: Constants.halfPadding),
              Flexible(
                child: (layoutProvider.isMobile)
                    ? Scrollbar(
                        controller: mobileScrollController,
                        child: innerList,
                      )
                    : innerList,
              ),

              const PaddedDivider(padding: Constants.halfPadding),
              _buildCreateButton(),
            ]),
      ),
    );
  }

  Widget _buildToDosTile(
      {ScrollPhysics physics = const NeverScrollableScrollPhysics()}) {
    return ExpandedListTile(
      initiallyExpanded: true,
      title: const AutoSizeText("Tasks",
          maxLines: 1,
          overflow: TextOverflow.visible,
          softWrap: false,
          minFontSize: Constants.large),
      subtitle: Subtitles.groupSubtitle(
          toDoCount: groupProvider.getToDoCount(id: vm.id)!),
      children: [
        PaginatingListview<ToDo>(
            items: vm.toDos,
            query: ({int limit = Constants.intMax, int offset = 0}) async =>
                await groupProvider.getToDosByGroupID(
                    id: vm.id, limit: limit, offset: offset),
            offset: vm.toDos.length,
            pullToRefresh: false,
            indicatorDisplacement: 0.0,
            rebuildNotifiers: [toDoProvider],
            rebuildCallback: ({required List<ToDo> items}) {
              vm.toDos = items;
              groupProvider.setToDoCount(id: vm.id);
            },
            onFetch: (groupProvider.userViewModel?.reduceMotion ?? false)
                ? null
                : onFetch,
            onRemove: (groupProvider.userViewModel?.reduceMotion ?? false)
                ? null
                : onRemove,
            listviewBuilder: (
                {Key? key,
                required BuildContext context,
                required List<ToDo> items,
                void Function({ToDo? item})? onRemove}) {
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
                  if (null != onRemove) {
                    onRemove(item: toDo);
                  }
                  await toDoProvider.updateToDo(toDo: toDo);
                },
                onTap: ({ToDo? toDo}) async {
                  if (null == toDo) {
                    return;
                  }

                  tVM.fromModel(model: toDo);
                  return await blurredNonDismissible(
                      context: context, dialog: const UpdateToDoScreen());
                  // await showDialog(
                  //   barrierDismissible: false,
                  //   useRootNavigator: false,
                  //   context: context,
                  //   builder: (BuildContext context) {
                  //     tVM.fromModel(model: toDo);
                  //     return const UpdateToDoScreen();
                  //   });
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
          onTap: () async => blurredNonDismissible(
              context: context,
              dialog: CreateToDoScreen(
                initialGroup: MapEntry<String, int>(
                    (vm.name.isNotEmpty) ? vm.name : "New Group", vm.id),
              )),
          // await showDialog(
          //     barrierDismissible: false,
          //     useRootNavigator: false,
          //     context: context,
          //     builder: (BuildContext context) => CreateToDoScreen(
          //           initialGroup: MapEntry<String, int>(
          //               (vm.name.isNotEmpty) ? vm.name : "New Group", vm.id),
          //         )).catchError((e) => Tiles.displayError(e: e)),
        )
      ],
    );
  }

  Widget _buildTitleBar() => ValueListenableBuilder<bool>(
        valueListenable: _checkClose,
        builder: (BuildContext context, bool check, Widget? child) => TitleBar(
          context: context,
          title: "New Group",
          handleClose: handleClose,
          checkClose: check,
          padding: const EdgeInsets.symmetric(horizontal: Constants.padding),
        ),
      );

  Widget _buildNameTile() => ValueListenableBuilder<String?>(
      valueListenable: _nameErrorText,
      builder: (BuildContext context, String? errorText, Widget? child) =>
          Selector<GroupViewModel, String>(
            selector: (BuildContext context, GroupViewModel vm) => vm.name,
            builder: (BuildContext context, String value, Widget? child) =>
                Tiles.nameTile(
                    context: context,
                    leading: ListTileWidgets.groupIcon(
                      currentContext: context,
                      iconPadding: const EdgeInsets.all(Constants.padding),
                      outerPadding: const EdgeInsets.symmetric(
                          horizontal: Constants.halfPadding),
                    ),
                    errorText: errorText,
                    hintText: "Group Name",
                    controller: nameEditingController,
                    outerPadding:
                        const EdgeInsets.symmetric(vertical: Constants.padding),
                    textFieldPadding:
                        const EdgeInsets.only(left: Constants.padding),
                    onEditingComplete: () {
                      _checkClose.value =
                          groupProvider.userViewModel?.checkClose ?? true;
                      vm.name = nameEditingController.text;
                    },
                    handleClear: () {
                      _checkClose.value =
                          groupProvider.userViewModel?.checkClose ?? true;
                      nameEditingController.clear();
                      vm.name = "";
                    }),
          ));

  Widget _buildDescriptionTile({
    int minLines = Constants.mobileMinLines,
    int maxLines = Constants.mobileMaxLinesBeforeScroll,
    bool mobile = false,
  }) =>
      Selector<GroupViewModel, String>(
        selector: (BuildContext context, GroupViewModel vm) => vm.description,
        builder: (BuildContext context, String value, Widget? child) =>
            Tiles.descriptionTile(
                context: context,
                isDense: mobile,
                hintText: "Notes",
                minLines: minLines,
                maxLines: maxLines,
                controller: descriptionEditingController,
                onEditingComplete: () {
                  _checkClose.value =
                      groupProvider.userViewModel?.checkClose ?? true;
                  vm.description = descriptionEditingController.text;
                }),
      );

  Widget _buildCreateButton() => ValueListenableBuilder(
        valueListenable: _createLoading,
        builder: (BuildContext context, bool createLoading, Widget? child) =>
            Tiles.createButton(
          loading: createLoading,
          outerPadding:
              const EdgeInsets.symmetric(horizontal: Constants.padding),
          handleCreate: createAndValidate,
        ),
      );
}
