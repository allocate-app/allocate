import "dart:io";

import "package:allocate/providers/application/layout_provider.dart";
import "package:flutter/material.dart";
import "package:flutter/semantics.dart";
import "package:provider/provider.dart";

import "../../../model/task/subtask.dart";
import '../../../providers/model/routine_provider.dart';
import '../../../providers/model/subtask_provider.dart';
import "../../../providers/viewmodels/routine_viewmodel.dart";
import "../../../util/constants.dart";
import "../../../util/enums.dart";
import "../../../util/exceptions.dart";
import "../../widgets/listtile_widgets.dart";
import "../../widgets/padded_divider.dart";
import "../../widgets/tiles.dart";
import "../../widgets/title_bar.dart";

class UpdateRoutineScreen extends StatefulWidget {
  const UpdateRoutineScreen({super.key});

  @override
  State<UpdateRoutineScreen> createState() => _UpdateRoutineScreen();
}

class _UpdateRoutineScreen extends State<UpdateRoutineScreen> {
  late ValueNotifier<bool> _checkClose;
  late ValueNotifier<String?> _nameErrorText;

  late final RoutineViewModel vm;
  late final RoutineProvider routineProvider;
  late final SubtaskProvider subtaskProvider;
  late final LayoutProvider layoutProvider;

  // Scrolling
  late final ScrollController mobileScrollController;
  late final ScrollController desktopScrollController;
  late final ScrollPhysics scrollPhysics;

  // Subtasks controller
  late final MenuController subtasksAnchorController;

  late final TextEditingController nameEditingController;

  @override
  void initState() {
    super.initState();
    initializeProviders();
    initializeParameters();
    initializeControllers();
    resetSubtasks();
  }

  void initializeProviders() {
    routineProvider = Provider.of<RoutineProvider>(context, listen: false);

    vm = Provider.of<RoutineViewModel>(context, listen: false);

    subtaskProvider = Provider.of<SubtaskProvider>(context, listen: false);

    subtaskProvider.addListener(resetSubtasks);
  }

  void initializeParameters() {
    _checkClose = ValueNotifier(false);
    _nameErrorText = ValueNotifier(null);
  }

  void initializeControllers() {
    mobileScrollController = ScrollController();
    desktopScrollController = ScrollController();
    ScrollPhysics parentPhysics = (Platform.isIOS || Platform.isMacOS)
        ? const BouncingScrollPhysics()
        : const ClampingScrollPhysics();
    scrollPhysics = AlwaysScrollableScrollPhysics(parent: parentPhysics);
    nameEditingController = TextEditingController(text: vm.name);
    nameEditingController.addListener(watchName);

    subtasksAnchorController = MenuController();
  }

  @override
  void dispose() {
    nameEditingController.removeListener(watchName);
    nameEditingController.dispose();
    mobileScrollController.dispose();
    desktopScrollController.dispose();
    subtaskProvider.removeListener(resetSubtasks);
    super.dispose();
  }

  void watchName() {
    _checkClose.value = routineProvider.userViewModel?.checkClose ?? true;
    String newText = nameEditingController.text;
    SemanticsService.announce(newText, Directionality.of(context));
    vm.name = newText;
    if (null != _nameErrorText.value) {
      _nameErrorText.value = null;
    }
  }

  Future<void> resetSubtasks() async {
    List<Subtask> newSubtasks = await routineProvider.getSubtasks(
        id: vm.id, limit: Constants.maxNumTasks);

    if (!(routineProvider.userViewModel?.reduceMotion ?? false)) {
      onFetch(items: newSubtasks);
    }

    vm.subtasks = newSubtasks;
    routineProvider.setSubtaskCount(id: vm.id, count: vm.subtasks.length);
    vm.weight = await routineProvider.getWeight(
        taskID: vm.id, limit: Constants.maxNumTasks);

    subtaskProvider.rebuild = false;
  }

  bool validateData() {
    bool valid = true;

    if (nameEditingController.text.isEmpty) {
      valid = false;
      _nameErrorText.value = "Enter Routine Name";
      if (desktopScrollController.hasClients) {
        desktopScrollController.jumpTo(0);
      }
      if (mobileScrollController.hasClients) {
        mobileScrollController.jumpTo(0);
      }
    }

    return valid;
  }

  Future<void> handleUpdate() async {
    await routineProvider
        .updateRoutine(routine: vm.toModel(), times: vm.routineTimes)
        .whenComplete(() {
      vm.clear();
      Navigator.pop(context);
    }).catchError((e) => Tiles.displayError(context: context, e: e),
            test: (e) =>
                e is FailureToCreateException || e is FailureToUploadException);
  }

  void handleClose({required bool willDiscard}) {
    if (willDiscard) {
      routineProvider.rebuild = true;
      vm.clear();
      Navigator.pop(context);
    }

    _checkClose.value = false;
  }

  Future<void> updateAndValidate() async {
    if (validateData()) {
      await handleUpdate();
    }
  }

  Future<void> handleDelete() async {
    return await routineProvider.deleteRoutine().whenComplete(() {
      vm.clear();
      Navigator.pop(context);
    }).catchError((e) => Tiles.displayError(context: context, e: e),
        test: (e) => e is FailureToDeleteException);
  }

  void onFetch({List<Subtask>? items}) {
    if (null == items) {
      return;
    }
    Set<Subtask> itemSet = vm.subtasks.toSet();

    for (Subtask subtask in items) {
      if (!itemSet.contains(subtask)) {
        subtask.fade = Fade.fadeIn;
      }
    }
  }

  Future<void> onRemove({Subtask? item}) async {
    if (null == item) {
      return;
    }
    if (mounted) {
      setState(() => item.fade = Fade.fadeOut);
      await Future.delayed(const Duration(milliseconds: Constants.fadeOutTime));
    }
  }

  void onAnchorOpen() {
    desktopScrollController.addListener(_closeMenuAnchor);
    mobileScrollController.addListener(_closeMenuAnchor);
  }

  void onAnchorClose() {
    desktopScrollController.removeListener(_closeMenuAnchor);
    mobileScrollController.removeListener(_closeMenuAnchor);
  }

  void _closeMenuAnchor() {
    subtasksAnchorController.close();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          if (constraints.maxWidth > Constants.largeScreen) {
            return _buildDesktopDialog(
              context: context,
            );
          }
          return _buildMobileDialog(
              context: context, smallScreen: layoutProvider.smallScreen);
        },
      );

  Dialog _buildDesktopDialog({
    required BuildContext context,
  }) {
    return Dialog(
      insetPadding: const EdgeInsets.all(Constants.outerDialogPadding),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
            maxHeight: Constants.maxDesktopDialogHeight,
            maxWidth: Constants.maxDesktopDialogWidth),
        child: Padding(
          padding: const EdgeInsets.all(Constants.padding),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            // Title && Close Button
            _buildTitleBar(),
            const PaddedDivider(padding: Constants.halfPadding),
            Flexible(
              child: Material(
                color: Colors.transparent,
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
                                  child: ListView(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: Constants.halfPadding),
                                      shrinkWrap: true,
                                      children: [
                                    // Title

                                    _buildNameTile(),
                                    _buildWeightTile(),
                                    const PaddedDivider(
                                        padding: Constants.padding),
                                    _buildDurationTile(),
                                  ])),
                              Flexible(
                                  child: ListView(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: Constants.halfPadding),
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      shrinkWrap: true,
                                      children: [
                                    _buildSubtasksTile(),
                                  ]))
                            ]),
                      ]),
                ),
              ),
            ),

            const PaddedDivider(padding: Constants.halfPadding),
            Tiles.updateAndDeleteButtons(
              handleDelete: handleDelete,
              updateButtonPadding:
                  const EdgeInsets.symmetric(horizontal: Constants.padding),
              deleteButtonPadding:
                  const EdgeInsets.symmetric(horizontal: Constants.padding),
              handleUpdate: updateAndValidate,
            ),
          ]),
        ),
      ),
    );
  }

  Dialog _buildMobileDialog(
      {required BuildContext context, bool smallScreen = false}) {
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
                child: ListView(
                  shrinkWrap: true,
                  controller: mobileScrollController,
                  physics: scrollPhysics,
                  children: [
                    _buildNameTile(),
                    _buildWeightTile(),
                    const PaddedDivider(padding: Constants.padding),
                    // Expected Duration / RealDuration -> Show status, on click, open a dialog.
                    _buildDurationTile(),
                    const PaddedDivider(padding: Constants.padding),

                    _buildSubtasksTile()
                  ],
                ),
              ),

              const PaddedDivider(padding: Constants.halfPadding),
              Tiles.updateAndDeleteButtons(
                handleDelete: handleDelete,
                updateButtonPadding:
                    const EdgeInsets.symmetric(horizontal: Constants.padding),
                deleteButtonPadding:
                    const EdgeInsets.symmetric(horizontal: Constants.padding),
                handleUpdate: updateAndValidate,
              ),
            ]),
      ),
    );
  }

  Widget _buildTitleBar() => ValueListenableBuilder<bool>(
        valueListenable: _checkClose,
        builder: (BuildContext context, bool check, Widget? child) =>
            Selector<RoutineViewModel, (int, int)>(
          selector: (BuildContext context, RoutineViewModel vm) =>
              (vm.expectedDuration, vm.realDuration),
          builder: (BuildContext context, (int, int) value, Widget? child) {
            return TitleBar(
              context: context,
              title: "Edit Routine",
              centerWidget: (value.$1 > 0)
                  ? TitleBar.durationCenterWidget(
                      expectedDuration: value.$1,
                      realDuration: value.$2,
                    )
                  : null,
              handleClose: handleClose,
              checkClose: check,
              padding:
                  const EdgeInsets.symmetric(horizontal: Constants.padding),
            );
          },
        ),
      );

  Widget _buildNameTile() => ValueListenableBuilder<String?>(
      valueListenable: _nameErrorText,
      builder: (BuildContext context, String? errorText, Widget? child) =>
          Selector<RoutineViewModel, (String, int)>(
            selector: (BuildContext context, RoutineViewModel vm) =>
                (vm.name, vm.routineTimes),
            builder: (BuildContext context, (String, int) value,
                    Widget? child) =>
                Tiles.nameTile(
                    context: context,
                    leading: ListTileWidgets.routineIcon(
                      currentContext: context,
                      scale: Constants.largeCheckboxMinScale,
                      times: value.$2,
                      handleRoutineTimeChange: (
                          {required int newRoutineTimes}) {
                        vm.routineTimes = newRoutineTimes;
                      },
                    ),
                    errorText: errorText,
                    hintText: "Routine Name",
                    controller: nameEditingController,
                    outerPadding:
                        const EdgeInsets.symmetric(vertical: Constants.padding),
                    textFieldPadding:
                        const EdgeInsets.only(left: Constants.padding),
                    onEditingComplete: () {
                      _checkClose.value =
                          routineProvider.userViewModel?.checkClose ?? true;
                      vm.name = nameEditingController.text;
                    },
                    handleClear: () {
                      _checkClose.value =
                          routineProvider.userViewModel?.checkClose ?? true;
                      nameEditingController.clear();
                      vm.name = "";
                    }),
          ));

  Widget _buildWeightTile() => Selector<RoutineViewModel, int>(
      selector: (BuildContext context, RoutineViewModel vm) => vm.weight,
      builder: (BuildContext context, int value, Widget? child) =>
          Tiles.weightTile(
            outerPadding: const EdgeInsets.all(Constants.doublePadding),
            batteryPadding: const EdgeInsets.all(Constants.padding),
            constraints: const BoxConstraints(
              maxWidth: 200,
            ),
            weight: value.toDouble(),
            max: Constants.maxWeight.toDouble(),
          ));

  Widget _buildDurationTile() => Selector<RoutineViewModel, (int, int)>(
        selector: (BuildContext context, RoutineViewModel vm) =>
            (vm.expectedDuration, vm.realDuration),
        builder: (BuildContext context, (int, int) value, Widget? child) =>
            Tiles.durationTile(
          context: context,
          expectedDuration: value.$1,
          realDuration: value.$2,
          handleClear: vm.clearDuration,
          handleUpdate: vm.updateDuration,
        ),
      );

  Widget _buildSubtasksTile() => Selector<RoutineViewModel, UniqueKey>(
      selector: (BuildContext context, RoutineViewModel vm) => vm.subtaskKey,
      builder: (BuildContext context, UniqueKey value, Widget? child) =>
          Tiles.subtasksTile(
              context: context,
              id: vm.id,
              subtasksAnchorController: subtasksAnchorController,
              onAnchorOpen: onAnchorOpen,
              onAnchorClose: onAnchorClose,
              onRemove: (routineProvider.userViewModel?.reduceMotion ?? false)
                  ? null
                  : onRemove,
              subtasks: vm.subtasks,
              subtaskCount: routineProvider.getSubtaskCount(id: vm.id)));
}
