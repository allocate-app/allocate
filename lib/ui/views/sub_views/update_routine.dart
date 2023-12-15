import "package:another_flushbar/flushbar.dart";
import "package:flutter/material.dart";
import "package:flutter/semantics.dart";
import "package:provider/provider.dart";

import "../../../model/task/routine.dart";
import "../../../model/task/subtask.dart";
import "../../../providers/routine_provider.dart";
import "../../../util/constants.dart";
import "../../../util/exceptions.dart";
import "../../widgets/flushbars.dart";
import "../../widgets/leading_widgets.dart";
import "../../widgets/padded_divider.dart";
import "../../widgets/tiles.dart";
import "../../widgets/title_bar.dart";

class UpdateRoutineScreen extends StatefulWidget {
  final Routine? initialRoutine;

  const UpdateRoutineScreen({Key? key, this.initialRoutine}) : super(key: key);

  @override
  State<UpdateRoutineScreen> createState() => _UpdateRoutineScreen();
}

class _UpdateRoutineScreen extends State<UpdateRoutineScreen> {
  late bool checkClose;
  late bool expanded;

  // Provider (Needs user values) -> Refactor to DI for testing. One day.
  late final RoutineProvider routineProvider;

  late final Routine prevRoutine;

  // Scrolling
  late final ScrollController mobileScrollController;
  late final ScrollController desktopScrollController;
  late final ScrollPhysics scrollPhysics;

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
  }

  void initializeParameters() {
    checkClose = false;
    expanded = true;
    prevRoutine = routine.copy();
  }

  void initializeControllers() {
    mobileScrollController = ScrollController();
    desktopScrollController = ScrollController();
    scrollPhysics =
        const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics());
    nameEditingController = TextEditingController(text: routine.name);
    nameEditingController.addListener(() {
      nameErrorText = null;
      checkClose = true;
      String newText = nameEditingController.text;
      SemanticsService.announce(newText, Directionality.of(context));
      if (mounted) {
        return setState(() => routine.name = newText);
      }
    });
  }

  void initializeProviders() {
    routineProvider = Provider.of<RoutineProvider>(context, listen: false);
    if (null != widget.initialRoutine) {
      routineProvider.curRoutine = widget.initialRoutine;
    }
  }

  @override
  void dispose() {
    nameEditingController.dispose();
    mobileScrollController.dispose();
    desktopScrollController.dispose();
    super.dispose();
  }

  Future<void> resetSubtasks() async {
    routine.subtasks = await routineProvider.getSubtasks(
      id: routine.id,
    );
    routineProvider.routineSubtaskCounts[routine.id]!.value =
        routine.subtasks.length;
    routine.weight = await routineProvider.getWeight(taskID: Constants.intMax);
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
      Navigator.pop(context, prevRoutine);
    }

    if (mounted) {
      return setState(() => checkClose = false);
    }
  }

  void clearNameField() {
    if (mounted) {
      return setState(() {
        checkClose = true;
        nameEditingController.clear();
        routine.name = "";
      });
    }
  }

  void changeRoutineTime({required int newRoutineTimes}) {
    if (mounted) {
      return setState(() {
        checkClose = true;
        times = newRoutineTimes;
      });
    }
  }

  // void handleWeightChange(double value) {
  //   if (mounted) {
  //     return setState(() {
  //       checkClose = true;
  //       routine.weight = value.toInt();
  //       routine.realDuration = routineProvider.calculateRealDuration(
  //           weight: routine.weight, duration: routine.expectedDuration);
  //     });
  //   }
  // }
  //
  // void removeRoutineTask({required int index}) {
  //   if (mounted) {
  //     return setState(() {
  //       checkClose = true;
  //       Subtask st = cacheRoutineTasks.removeAt(index);
  //       st = Subtask();
  //       cacheRoutineTasks.add(st);
  //       TextEditingController ct = routineTaskEditingController.removeAt(index);
  //       ct.value = ct.value.copyWith(text: st.name);
  //       routineTaskEditingController.add(ct);
  //
  //       shownTasks--;
  //       shownTasks = max(shownTasks, 0);
  //       routine.weight =
  //           routineProvider.calculateWeight(routineTasks: cacheRoutineTasks);
  //       routine.realDuration = routineProvider.calculateRealDuration(
  //           weight: routine.weight, duration: routine.expectedDuration);
  //     });
  //   }
  // }
  //
  // void reorderRoutineTasks(int oldIndex, int newIndex) {
  //   if (mounted) {
  //     return setState(() {
  //       checkClose = true;
  //       if (oldIndex < newIndex) {
  //         newIndex--;
  //       }
  //       Subtask st = cacheRoutineTasks.removeAt(oldIndex);
  //       cacheRoutineTasks.insert(newIndex, st);
  //       TextEditingController ct =
  //           routineTaskEditingController.removeAt(oldIndex);
  //       routineTaskEditingController.insert(newIndex, ct);
  //     });
  //   }
  // }

  // void onDataChange() {
  //   if (mounted) {
  //     return setState(() {
  //       checkClose = true;
  //     });
  //   }
  // }
  //
  // void onRoutineTaskWeightChanged() {
  //   if (mounted) {
  //     return setState(() {
  //       checkClose = true;
  //       routine.weight =
  //           routineProvider.calculateWeight(routineTasks: cacheRoutineTasks);
  //       routine.realDuration = routineProvider.calculateRealDuration(
  //           weight: routine.weight, duration: routine.expectedDuration);
  //     });
  //   }
  // }
  //
  // void addRoutineTask() {
  //   if (mounted) {
  //     return setState(() {
  //       shownTasks++;
  //       shownTasks = min(shownTasks, Constants.maxNumTasks);
  //     });
  //   }
  // }

  void updateDuration(int? value) {
    if (mounted) {
      return setState(() {
        checkClose = true;
        routine.expectedDuration = value ?? routine.expectedDuration;
        routine.realDuration = routineProvider.calculateRealDuration(
            weight: routine.weight, duration: routine.expectedDuration);
      });
    }
  }

  void clearDuration() {
    if (mounted) {
      return setState(() {
        checkClose = true;
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

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    bool largeScreen = (width >= Constants.largeScreen);
    bool smallScreen = (width <= Constants.smallScreen);
    bool hugeScreen = (width >= Constants.hugeScreen);
    return (largeScreen)
        ? buildDesktopDialog(
            context: context, smallScreen: smallScreen, hugeScreen: hugeScreen)
        : buildMobileDialog(context: context, smallScreen: smallScreen);
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
                                  leading: LeadingWidgets.routineIcon(
                                    currentContext: context,
                                    scale: Constants.largeCheckboxMinScale,
                                    times: times ?? 0,
                                    handleRoutineTimeChange: changeRoutineTime,
                                  ),
                                  hintText: "Routine Name",
                                  errorText: nameErrorText,
                                  controller: nameEditingController,
                                  outerPadding:
                                      const EdgeInsets.all(Constants.padding),
                                  textFieldPadding: const EdgeInsets.symmetric(
                                    horizontal: Constants.halfPadding,
                                  ),
                                  handleClear: clearNameField),
                              Tiles.weightTile(
                                outerPadding: const EdgeInsets.all(
                                    Constants.innerPadding),
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
                                outerPadding:
                                    const EdgeInsets.all(Constants.halfPadding),
                                id: routine.id,
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
                currentContext: context,
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
                        leading: LeadingWidgets.routineIcon(
                          currentContext: context,
                          scale: Constants.largeCheckboxMinScale,
                          times: times ?? 0,
                          handleRoutineTimeChange: changeRoutineTime,
                        ),
                        hintText: "Routine Name",
                        errorText: nameErrorText,
                        controller: nameEditingController,
                        outerPadding: const EdgeInsets.all(Constants.padding),
                        textFieldPadding: const EdgeInsets.only(
                          left: Constants.halfPadding,
                        ),
                        handleClear: clearNameField),
                    Tiles.weightTile(
                      outerPadding:
                          const EdgeInsets.all(Constants.innerPadding),
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
                      outerPadding: const EdgeInsets.symmetric(
                          horizontal: Constants.padding),
                      handleClear: clearDuration,
                      handleUpdate: updateDuration,
                    ),

                    const PaddedDivider(padding: Constants.padding),

                    Tiles.subtasksTile(
                        context: context,
                        id: routine.id,
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
//         subtasks: cacheRoutineTasks,
//         itemCount: min(Constants.maxNumTasks, shownTasks),
//         controllers: routineTaskEditingController,
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
