import "dart:io";

import "package:another_flushbar/flushbar.dart";
import "package:flutter/material.dart";
import "package:flutter/semantics.dart";
import "package:provider/provider.dart";

import "../../../model/task/routine.dart";
import "../../../model/task/subtask.dart";
import '../../../providers/model/routine_provider.dart';
import '../../../providers/model/subtask_provider.dart';
import '../../../providers/model/user_provider.dart';
import "../../../util/constants.dart";
import "../../../util/enums.dart";
import "../../../util/exceptions.dart";
import "../../widgets/flushbars.dart";
import "../../widgets/listtile_widgets.dart";
import "../../widgets/padded_divider.dart";
import "../../widgets/tiles.dart";
import "../../widgets/title_bar.dart";

class UpdateRoutineScreen extends StatefulWidget {
  final Routine? initialRoutine;

  const UpdateRoutineScreen({super.key, this.initialRoutine});

  @override
  State<UpdateRoutineScreen> createState() => _UpdateRoutineScreen();
}

class _UpdateRoutineScreen extends State<UpdateRoutineScreen> {
  late bool checkClose;
  late bool expanded;

  late final RoutineProvider routineProvider;
  late final SubtaskProvider subtaskProvider;
  late final UserProvider userProvider;

  // Scrolling
  late final ScrollController mobileScrollController;
  late final ScrollController desktopScrollController;
  late final ScrollPhysics scrollPhysics;

  // Subtasks controller
  late final MenuController subtasksAnchorController;

  late final TextEditingController nameEditingController;
  String? nameErrorText;

  // RoutineTasks
  late final List<Subtask> cacheRoutineTasks;
  late int shownTasks;

  // Convenience method to avoid typing
  Routine get routine => routineProvider.curRoutine!;

  // For setting routine TOD for main screen
  int? times;

  @override
  void initState() {
    super.initState();
    initializeProviders();

    initializeParameters();

    initializeControllers();
    resetSubtasks();
  }

  void initializeParameters() {
    checkClose = false;
    expanded = true;
    times = routineProvider.getRoutineTime(routine: routine);
  }

  void initializeControllers() {
    mobileScrollController = ScrollController();
    desktopScrollController = ScrollController();
    ScrollPhysics parentPhysics = (Platform.isIOS || Platform.isMacOS)
        ? const BouncingScrollPhysics()
        : const ClampingScrollPhysics();
    scrollPhysics = AlwaysScrollableScrollPhysics(parent: parentPhysics);
    nameEditingController = TextEditingController(text: routine.name);
    nameEditingController.addListener(() {
      if (null != nameErrorText && mounted) {
        setState(() {
          nameErrorText = null;
        });
      }
      checkClose = userProvider.curUser?.checkClose ?? true;
      String newText = nameEditingController.text;
      SemanticsService.announce(newText, Directionality.of(context));
    });

    subtasksAnchorController = MenuController();
  }

  void initializeProviders() {
    routineProvider = Provider.of<RoutineProvider>(context, listen: false);
    if (null != widget.initialRoutine) {
      routineProvider.curRoutine = widget.initialRoutine;
    }
    subtaskProvider = Provider.of<SubtaskProvider>(context, listen: false);

    subtaskProvider.addListener(resetSubtasks);
    userProvider = Provider.of<UserProvider>(context, listen: false);
  }

  @override
  void dispose() {
    nameEditingController.dispose();
    mobileScrollController.dispose();
    desktopScrollController.dispose();
    subtaskProvider.removeListener(resetSubtasks);
    super.dispose();
  }

  Future<void> resetSubtasks() async {
    List<Subtask> newSubtasks = await routineProvider.getSubtasks(
      id: routine.id,
    );

    if (!(userProvider.curUser?.reduceMotion ?? false)) {
      onFetch(items: newSubtasks);
    }

    routine.subtasks = newSubtasks;
    routineProvider.setSubtaskCount(
        id: routine.id, count: routine.subtasks.length);
    routine.weight = await routineProvider.getWeight(taskID: routine.id);
    routine.realDuration = routineProvider.calculateRealDuration(
        weight: routine.weight, duration: routine.expectedDuration);
    if (mounted) {
      setState(() {});
    }
  }

  bool validateData() {
    bool valid = true;

    if (nameEditingController.text.isEmpty) {
      valid = false;
      if (mounted) {
        setState(() => nameErrorText = "Enter Routine Name");
      }
    }

    return valid;
  }

  Future<void> handleUpdate() async {
    // in case the usr doesn't submit to the textfields
    routine.name = nameEditingController.text;

    await routineProvider.updateRoutine(times: times).whenComplete(() {
      Navigator.pop(context);
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
  }

  void handleClose({required bool willDiscard}) {
    if (willDiscard) {
      routineProvider.rebuild = true;
      return Navigator.pop(context);
    }

    if (mounted) {
      setState(() => checkClose = false);
    }
  }

  void clearNameField() {
    if (mounted) {
      setState(() {
        checkClose = userProvider.curUser?.checkClose ?? true;
        nameEditingController.clear();
        routine.name = "";
      });
    }
  }

  void updateName() {
    if (mounted) {
      setState(() {
        routine.name = nameEditingController.text;
      });
    }
  }

  void changeRoutineTime({required int newRoutineTimes}) {
    if (mounted) {
      setState(() {
        checkClose = userProvider.curUser?.checkClose ?? true;
        times = newRoutineTimes;
      });
    }
  }

  void updateDuration(int? value) {
    if (mounted) {
      setState(() {
        checkClose = userProvider.curUser?.checkClose ?? true;
        routine.expectedDuration = value ?? routine.expectedDuration;
        routine.realDuration = routineProvider.calculateRealDuration(
            weight: routine.weight, duration: routine.expectedDuration);
      });
    }
  }

  void clearDuration() {
    if (mounted) {
      setState(() {
        checkClose = userProvider.curUser?.checkClose ?? true;
        routine.expectedDuration = 0;
        routine.realDuration = 0;
      });
    }
  }

  Future<void> updateAndValidate() async {
    if (validateData()) {
      await handleUpdate();
    }
  }

  Future<void> handleDelete() async {
    return await routineProvider.deleteRoutine().whenComplete(() {
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

  void onFetch({List<Subtask>? items}) {
    if (null == items) {
      return;
    }
    for (Subtask subtask in items) {
      subtask.fade = Fade.fadeIn;
    }
  }

  Future<void> onRemove({Subtask? item}) async {
    if (null == item) {
      return;
    }
    if (mounted) {
      setState(() => item.fade = Fade.fadeOut);
      await Future.delayed(const Duration(milliseconds: Constants.fadeInTime));
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
  Widget build(BuildContext context) {
    MediaQuery.sizeOf(context);
    return (userProvider.largeScreen)
        ? buildDesktopDialog(
            context: context,
            smallScreen: userProvider.smallScreen,
            hugeScreen: userProvider.hugeScreen)
        : buildMobileDialog(
            context: context, smallScreen: userProvider.smallScreen);
  }

  Dialog buildDesktopDialog(
      {required BuildContext context,
      bool smallScreen = false,
      bool hugeScreen = false}) {
    return Dialog(
      insetPadding: const EdgeInsets.all(Constants.outerDialogPadding),
      child: Padding(
        padding: const EdgeInsets.all(Constants.padding),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          // Title && Close Button
          TitleBar(
            context: context,
            title: "Edit Routine",
            centerWidget: (routine.expectedDuration > 0)
                ? TitleBar.durationCenterWidget(
                    expectedDuration: routine.expectedDuration,
                    realDuration: routine.realDuration)
                : null,
            checkClose: checkClose,
            padding: const EdgeInsets.symmetric(horizontal: Constants.padding),
            handleClose: handleClose,
          ),

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
                                  physics: const NeverScrollableScrollPhysics(),
                                  children: [
                                // Title

                                Tiles.nameTile(
                                    context: context,
                                    leading: ListTileWidgets.routineIcon(
                                      currentContext: context,
                                      scale: Constants.largeCheckboxMinScale,
                                      times: times ?? 0,
                                      handleRoutineTimeChange:
                                          changeRoutineTime,
                                    ),
                                    hintText: "Routine Name",
                                    errorText: nameErrorText,
                                    controller: nameEditingController,
                                    outerPadding: const EdgeInsets.symmetric(
                                        vertical: Constants.padding),
                                    textFieldPadding: const EdgeInsets.only(
                                      left: Constants.padding,
                                    ),
                                    handleClear: clearNameField,
                                    onEditingComplete: updateName),
                                Tiles.weightTile(
                                  outerPadding: const EdgeInsets.all(
                                      Constants.doublePadding),
                                  batteryPadding: const EdgeInsets.symmetric(
                                      horizontal: Constants.padding),
                                  constraints:
                                      const BoxConstraints(maxWidth: 200),
                                  weight: routine.weight.toDouble(),
                                  max: Constants.maxWeight.toDouble(),
                                ),
                                const PaddedDivider(padding: Constants.padding),
                                Tiles.durationTile(
                                  expectedDuration: routine.expectedDuration,
                                  context: context,
                                  realDuration: routine.realDuration,
                                  handleClear: clearDuration,
                                  handleUpdate: updateDuration,
                                ),
                              ])),
                          Flexible(
                              child: ListView(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: Constants.halfPadding),
                                  physics: const NeverScrollableScrollPhysics(),
                                  shrinkWrap: true,
                                  children: [
                                Tiles.subtasksTile(
                                  context: context,
                                  id: routine.id,
                                  subtasksAnchorController:
                                      subtasksAnchorController,
                                  onAnchorOpen: onAnchorOpen,
                                  onAnchorClose: onAnchorClose,
                                  onRemove:
                                      (userProvider.curUser?.reduceMotion ??
                                              false)
                                          ? null
                                          : onRemove,
                                  subtasks: routine.subtasks,
                                  subtaskCount: routineProvider.getSubtaskCount(
                                      id: routine.id),
                                )
                              ]))
                        ]),
                  ],
                ),
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
    );
  }

  Dialog buildMobileDialog(
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
              TitleBar(
                context: context,
                title: "Edit Routine",
                centerWidget: (routine.expectedDuration > 0)
                    ? TitleBar.durationCenterWidget(
                        expectedDuration: routine.expectedDuration,
                        realDuration: routine.realDuration)
                    : null,
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
                        leading: ListTileWidgets.routineIcon(
                          currentContext: context,
                          scale: Constants.largeCheckboxMinScale,
                          times: times ?? 0,
                          handleRoutineTimeChange: changeRoutineTime,
                        ),
                        hintText: "Routine Name",
                        errorText: nameErrorText,
                        controller: nameEditingController,
                        outerPadding: const EdgeInsets.symmetric(
                            vertical: Constants.padding),
                        textFieldPadding: const EdgeInsets.only(
                          left: Constants.padding,
                        ),
                        handleClear: clearNameField,
                        onEditingComplete: updateName),
                    Tiles.weightTile(
                      outerPadding:
                          const EdgeInsets.all(Constants.doublePadding),
                      batteryPadding: const EdgeInsets.symmetric(
                          horizontal: Constants.padding),
                      constraints: const BoxConstraints(maxWidth: 200),
                      weight: routine.weight.toDouble(),
                      max: Constants.maxWeight.toDouble(),
                    ),
                    const PaddedDivider(padding: Constants.padding),
                    // Expected Duration / RealDuration -> Show status, on click, open a dialog.
                    Tiles.durationTile(
                      expectedDuration: routine.expectedDuration,
                      context: context,
                      realDuration: routine.realDuration,
                      handleClear: clearDuration,
                      handleUpdate: updateDuration,
                    ),

                    const PaddedDivider(padding: Constants.padding),

                    Tiles.subtasksTile(
                        context: context,
                        id: routine.id,
                        subtasksAnchorController: subtasksAnchorController,
                        onAnchorOpen: onAnchorOpen,
                        onAnchorClose: onAnchorClose,
                        subtasks: routine.subtasks,
                        subtaskCount:
                            routineProvider.getSubtaskCount(id: routine.id)),
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
}
