import "dart:io";

import "package:flutter/material.dart";
import "package:flutter/semantics.dart";
import "package:provider/provider.dart";

import "../../../model/task/routine.dart";
import "../../../model/task/subtask.dart";
import "../../../providers/application/layout_provider.dart";
import '../../../providers/model/routine_provider.dart';
import '../../../providers/model/subtask_provider.dart';
import "../../../providers/viewmodels/routine_viewmodel.dart";
import "../../../services/application_service.dart";
import "../../../util/constants.dart";
import "../../../util/enums.dart";
import "../../widgets/listtile_widgets.dart";
import "../../widgets/padded_divider.dart";
import "../../widgets/tiles.dart";
import "../../widgets/title_bar.dart";

class CreateRoutineScreen extends StatefulWidget {
  const CreateRoutineScreen({super.key, this.times});

  final int? times;

  @override
  State<CreateRoutineScreen> createState() => _CreateRoutineScreen();
}

class _CreateRoutineScreen extends State<CreateRoutineScreen> {
  late ValueNotifier<bool> _checkClose;
  late ValueNotifier<bool> _createLoading;
  late ValueNotifier<String?> _nameErrorText;

  late final RoutineViewModel vm;
  late final RoutineProvider routineProvider;
  late final SubtaskProvider subtaskProvider;
  late final LayoutProvider layoutProvider;

  late ApplicationService applicationService;

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
  }

  void initializeParameters() {
    _checkClose = ValueNotifier(false);
    _createLoading = ValueNotifier(false);
    _nameErrorText = ValueNotifier(null);
  }

  void initializeControllers() {
    mobileScrollController = ScrollController();
    desktopScrollController = ScrollController();
    ScrollPhysics parentPhysics = (Platform.isIOS || Platform.isMacOS)
        ? const BouncingScrollPhysics()
        : const ClampingScrollPhysics();
    scrollPhysics = AlwaysScrollableScrollPhysics(parent: parentPhysics);
    nameEditingController = TextEditingController();
    nameEditingController.addListener(watchName);
    subtasksAnchorController = MenuController();
  }

  void initializeProviders() {
    routineProvider = Provider.of<RoutineProvider>(context, listen: false);

    vm = Provider.of<RoutineViewModel>(context, listen: false);
    vm.clear();
    vm.initRoutineTimes = widget.times ?? 0;

    subtaskProvider = Provider.of<SubtaskProvider>(context, listen: false);
    subtaskProvider.addListener(resetSubtasks);

    layoutProvider = Provider.of<LayoutProvider>(context, listen: false);

    applicationService = ApplicationService.instance;
    applicationService.addListener(scrollToTop);
  }

  @override
  void dispose() {
    applicationService.removeListener(scrollToTop);
    nameEditingController.removeListener(watchName);
    nameEditingController.dispose();
    mobileScrollController.dispose();
    desktopScrollController.dispose();
    subtaskProvider.removeListener(resetSubtasks);
    super.dispose();
  }

  void scrollToTop() {
    if (mobileScrollController.hasClients) {
      mobileScrollController.animateTo(
        0,
        duration: Constants.scrollDuration,
        curve: Constants.scrollCurve,
      );
    }
    if (desktopScrollController.hasClients) {
      desktopScrollController.animateTo(
        0,
        duration: Constants.scrollDuration,
        curve: Constants.scrollCurve,
      );
    }
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
      scrollToTop();
    }

    return valid;
  }

  // This should still run even if the online throws.
  // If local create fails, something is very wrong => pop context and escape
  Future<void> handleCreate() async {
    Routine newRoutine = vm.toModel();
    await routineProvider
        .createRoutine(newRoutine, vm.routineTimes)
        .catchError((e) async {
      await Tiles.displayError(e: e);
    }).whenComplete(() {
      vm.clear();
      _popScreen();
    });
  }

  void _popScreen() {
    if (mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> handleClose({required bool willDiscard}) async {
    if (willDiscard) {
      for (Subtask st in vm.subtasks) {
        st.toDelete = true;
      }
      await subtaskProvider
          .updateBatch(subtasks: vm.subtasks)
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

  void onFetch({List<Subtask>? items}) {
    if (null == items) {
      return;
    }

    DateTime threshold = DateTime.now();
    threshold = threshold.copyWith(
        millisecond: threshold.millisecond - Constants.newItemThreshold);
    for (Subtask subtask in items) {
      if (!subtask.lastUpdated.isBefore(threshold)) {
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
          MediaQuery.viewPaddingOf(context);
          if (layoutProvider.largeScreen) {
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
    double insets = View.of(context).viewInsets.bottom;
    Widget innerList = ListView(
        padding: const EdgeInsets.only(
          top: Constants.halfPadding,
          left: Constants.padding,
          right: Constants.padding,
        ),
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
                      const PaddedDivider(padding: Constants.padding),
                      _buildDurationTile(),
                    ])),
                Flexible(
                    child: ListView(
                        padding: const EdgeInsets.symmetric(
                            horizontal: Constants.halfPadding),
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: Constants.padding,
                            horizontal: Constants.halfPadding),
                        child: _buildSubtasksTile(),
                      ),
                    ]))
              ]),
          if (layoutProvider.isMobile)
            TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: Constants.keyboardSlideOut),
                curve: Curves.fastLinearToSlowEaseIn,
                tween: Tween<double>(
                  begin: insets > Constants.keyboardInsetOpenThreshold ? Constants.keyboardInset : 0,
                  end: insets > Constants.keyboardInsetOpenThreshold ? Constants.keyboardInset : 0,
                ),
                builder: (BuildContext context, double value, Widget? child){
                  return SizedBox(height: value);
                }
            ),
        ]);

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
      {required BuildContext context, bool smallScreen = false}) {
    double insets = View.of(context).viewInsets.bottom;
    Widget innerList = ListView(
      padding: const EdgeInsets.symmetric(horizontal: Constants.padding),
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

        _buildSubtasksTile(),
        if (layoutProvider.isMobile)
          TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: Constants.keyboardSlideOut),
              curve: Curves.fastLinearToSlowEaseIn,
              tween: Tween<double>(
                begin: insets > Constants.keyboardInsetOpenThreshold ? Constants.keyboardInset : 0,
                end: insets > Constants.keyboardInsetOpenThreshold ? Constants.keyboardInset : 0,
              ),
              builder: (BuildContext context, double value, Widget? child){
                return SizedBox(height: value);
              }
          ),
      ],
    );

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

  Widget _buildTitleBar() => ValueListenableBuilder<bool>(
        valueListenable: _checkClose,
        builder: (BuildContext context, bool check, Widget? child) =>
            Selector<RoutineViewModel, (int, int)>(
          selector: (BuildContext context, RoutineViewModel vm) =>
              (vm.expectedDuration, vm.realDuration),
          builder: (BuildContext context, (int, int) value, Widget? child) {
            return TitleBar(
              context: context,
              title: "New Routine",
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
                      iconPadding:
                          const EdgeInsets.all(Constants.quarterPadding),
                      outerPadding: const EdgeInsets.symmetric(
                          horizontal: Constants.halfPadding),
                      currentContext: context,
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
