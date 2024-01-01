import "package:another_flushbar/flushbar.dart";
import "package:flutter/material.dart";
import "package:flutter/semantics.dart";
import "package:provider/provider.dart";

import "../../../model/task/subtask.dart";
import "../../../providers/routine_provider.dart";
import "../../../providers/subtask_provider.dart";
import "../../../providers/user_provider.dart";
import "../../../util/constants.dart";
import "../../../util/enums.dart";
import "../../../util/exceptions.dart";
import "../../widgets/flushbars.dart";
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
  late bool checkClose;
  late bool expanded;

  // Provider (Needs user values) -> Refactor to DI for testing. One day.
  late final RoutineProvider routineProvider;
  late final UserProvider userProvider;
  late final SubtaskProvider subtaskProvider;

  // Scrolling
  late final ScrollController mobileScrollController;
  late final ScrollController desktopScrollController;
  late final ScrollPhysics scrollPhysics;

  late String name;
  late final TextEditingController nameEditingController;
  String? nameErrorText;

  // weight
  late int weight;

  // ExpectedDuration & Real Duration.
  late int expectedDuration;
  late int realDuration;

  late List<Subtask> subtasks;

  // If setting the routine for the home screen.
  int? times;

  @override
  void initState() {
    super.initState();
    initializeProviders();

    initializeParameters();

    initializeControllers();
  }

  void initializeParameters() {
    checkClose = false;
    expanded = true;
    name = "";
    weight = 0;
    expectedDuration = 0;
    realDuration = 0;
    times = widget.times;
    subtasks = List.empty();
  }

  void initializeControllers() {
    mobileScrollController = ScrollController();
    desktopScrollController = ScrollController();
    scrollPhysics =
        const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics());
    nameEditingController = TextEditingController();
    nameEditingController.addListener(() {
      if (null != nameErrorText && mounted) {
        setState(() {
          nameErrorText = null;
        });
      }
      SemanticsService.announce(
          nameEditingController.text, Directionality.of(context));
    });
  }

  void initializeProviders() {
    routineProvider = Provider.of<RoutineProvider>(context, listen: false);
    userProvider = Provider.of<UserProvider>(context, listen: false);
    subtaskProvider = Provider.of<SubtaskProvider>(context, listen: false);
    subtaskProvider.addListener(resetSubtasks);
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
      id: Constants.intMax,
    );
    if (!(userProvider.curUser?.reduceMotion ?? false)) {
      onFetch(items: newSubtasks);
    }

    subtasks = newSubtasks;

    routineProvider.setSubtaskCount(
        id: Constants.intMax, count: subtasks.length);
    weight = await routineProvider.getWeight(taskID: Constants.intMax);
    realDuration = routineProvider.calculateRealDuration(
        weight: weight, duration: expectedDuration);
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

  Future<void> handleCreate() async {
    // in case the usr doesn't submit to the textfields
    name = nameEditingController.text;
    await routineProvider
        .createRoutine(
            name: name,
            weight: weight,
            expectedDuration: expectedDuration,
            realDuration: realDuration,
            subtasks: subtasks,
            times: times)
        .whenComplete(() {
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

  Future<void> handleClose({required bool willDiscard}) async {
    if (willDiscard) {
      for (Subtask st in subtasks) {
        st.toDelete = true;
      }
      await subtaskProvider.updateBatch(subtasks: subtasks).whenComplete(() {
        Navigator.pop(context);
      });
    }

    if (mounted) {
      return setState(() => checkClose = false);
    }
  }

  void clearNameField() {
    if (mounted) {
      return setState(() {
        checkClose = userProvider.curUser?.checkClose ?? true;
        nameEditingController.clear();
        name = "";
      });
    }
  }

  void updateName() {
    if (mounted) {
      setState(() {
        checkClose = userProvider.curUser?.checkClose ?? true;
        name = nameEditingController.text;
      });
    }
  }

  void changeRoutineTime({required int newRoutineTimes}) {
    if (mounted) {
      return setState(() {
        checkClose = userProvider.curUser?.checkClose ?? true;
        times = newRoutineTimes;
      });
    }
  }

  void updateDuration(int? value) {
    if (mounted) {
      return setState(() {
        checkClose = userProvider.curUser?.checkClose ?? true;
        expectedDuration = value ?? expectedDuration;
        realDuration = routineProvider.calculateRealDuration(
            weight: weight, duration: expectedDuration);
      });
    }
  }

  void clearDuration() {
    if (mounted) {
      return setState(() {
        checkClose = userProvider.curUser?.checkClose ?? true;
        expectedDuration = 0;
        realDuration = 0;
      });
    }
  }

  Future<void> createAndValidate() async {
    if (validateData()) {
      await handleCreate();
    }
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
            currentContext: context,
            title: "New Routine",
            centerWidget: (expectedDuration > 0)
                ? TitleBar.durationCenterWidget(
                    expectedDuration: expectedDuration,
                    realDuration: realDuration)
                : null,
            checkClose: checkClose,
            padding: const EdgeInsets.symmetric(horizontal: Constants.padding),
            handleClose: handleClose,
          ),

          const PaddedDivider(padding: Constants.halfPadding),
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
                              child: ListView(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: Constants.halfPadding),
                                  shrinkWrap: true,
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
                                    outerPadding:
                                        const EdgeInsets.all(Constants.padding),
                                    textFieldPadding: const EdgeInsets.only(
                                        left: Constants.halfPadding),
                                    handleClear: clearNameField,
                                    onEditingComplete: updateName),
                                Tiles.weightTile(
                                  outerPadding: const EdgeInsets.all(
                                      Constants.innerPadding),
                                  batteryPadding: const EdgeInsets.symmetric(
                                      horizontal: Constants.padding),
                                  constraints:
                                      const BoxConstraints(maxWidth: 200),
                                  weight: weight.toDouble(),
                                  max: Constants.maxWeight.toDouble(),
                                ),
                                const PaddedDivider(padding: Constants.padding),
                                Tiles.durationTile(
                                  expectedDuration: expectedDuration,
                                  context: context,
                                  realDuration: realDuration,
                                  outerPadding: const EdgeInsets.symmetric(
                                      horizontal: Constants.padding),
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
                                  outerPadding: const EdgeInsets.all(
                                      Constants.halfPadding),
                                  id: Constants.intMax,
                                  onRemove:
                                      (userProvider.curUser?.reduceMotion ??
                                              false)
                                          ? null
                                          : onRemove,
                                  subtasks: subtasks,
                                  subtaskCount: routineProvider.getSubtaskCount(
                                      id: Constants.intMax),
                                )
                              ]))
                        ]),
                  ]),
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
                currentContext: context,
                title: "New Routine",
                centerWidget: (expectedDuration > 0)
                    ? TitleBar.durationCenterWidget(
                        expectedDuration: expectedDuration,
                        realDuration: realDuration)
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
                        outerPadding: const EdgeInsets.all(Constants.padding),
                        textFieldPadding:
                            const EdgeInsets.only(left: Constants.halfPadding),
                        handleClear: clearNameField,
                        onEditingComplete: updateName),
                    Tiles.weightTile(
                      outerPadding:
                          const EdgeInsets.all(Constants.innerPadding),
                      batteryPadding: const EdgeInsets.symmetric(
                          horizontal: Constants.padding),
                      constraints: const BoxConstraints(maxWidth: 200),
                      weight: weight.toDouble(),
                      max: Constants.maxWeight.toDouble(),
                    ),
                    const PaddedDivider(padding: Constants.padding),
                    // Expected Duration / RealDuration -> Show status, on click, open a dialog.
                    Tiles.durationTile(
                      expectedDuration: expectedDuration,
                      context: context,
                      realDuration: realDuration,
                      outerPadding: const EdgeInsets.symmetric(
                          horizontal: Constants.padding),
                      handleClear: clearDuration,
                      handleUpdate: updateDuration,
                    ),

                    const PaddedDivider(padding: Constants.padding),

                    Tiles.subtasksTile(
                        context: context,
                        id: Constants.intMax,
                        subtasks: subtasks,
                        subtaskCount: routineProvider.getSubtaskCount(
                            id: Constants.intMax)),
                  ],
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
    );
  }

// Widget buildRoutineTasksTile(
//     {ScrollPhysics physics = const NeverScrollableScrollPhysics(),
//     EdgeInsetsGeometry outerPadding = EdgeInsets.zero}) {
//   return ExpandedListTile(
//     outerPadding: outerPadding,
//     title: const AutoSizeText("Steps",
//         maxLines: 1,
//         overflow: TextOverflow.visible,
//         softWrap: false,
//         minFontSize: Constants.small),
//     subtitle: AutoSizeText(
//         "${min(shownTasks, Constants.maxNumTasks)}/${Constants.maxNumTasks} Steps",
//         maxLines: 1,
//         overflow: TextOverflow.visible,
//         softWrap: false,
//         minFontSize: Constants.small),
//     children: [
//       ListViews.reorderableSubtasks(
//         physics: physics,
//         context: context,
//         subtasks: subtasks,
//         itemCount: min(Constants.maxNumTasks, shownTasks),
//         onRemoved: removeRoutineTask,
//         onReorder: reorderRoutineTasks,
//         updateSubTask: onDataChange,
//         onSubtaskWeightChanged: onRoutineTaskWeightChanged,
//         showHandle: shownTasks > 1,
//       ),
//       (shownTasks < Constants.maxNumTasks)
//           ? Tiles.addTile(
//               title: "Add a step",
//               onTap: addRoutineTask,
//             )
//           : const SizedBox.shrink(),
//     ],
//   );
// }
}
