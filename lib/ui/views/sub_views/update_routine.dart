import "dart:math";

import "package:another_flushbar/flushbar.dart";
import "package:auto_size_text/auto_size_text.dart";
import "package:flutter/material.dart";
import "package:flutter/semantics.dart";
import "package:provider/provider.dart";

import "../../../model/task/routine.dart";
import "../../../model/task/subtask.dart";
import "../../../providers/routine_provider.dart";
import "../../../util/constants.dart";
import "../../../util/enums.dart";
import "../../../util/exceptions.dart";
import "../../widgets/expanded_listtile.dart";
import "../../widgets/flushbars.dart";
import "../../widgets/listviews.dart";
import "../../widgets/padded_divider.dart";
import "../../widgets/tiles.dart";
import "../../widgets/title_bar.dart";

class UpdateRoutineScreen extends StatefulWidget {
  const UpdateRoutineScreen({Key? key}) : super(key: key);

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
  late final ScrollController mainScrollController;
  late final ScrollController subScrollControllerLeft;
  late final ScrollController subScrollControllerRight;
  late final ScrollPhysics scrollPhysics;

  late final TextEditingController nameEditingController;
  String? nameErrorText;

  late final List<TextEditingController> routineTaskEditingController;

  // RoutineTasks
  late final List<SubTask> cacheRoutineTasks;
  late int shownTasks;

  // Convenience method to avoid typing
  Routine get routine => routineProvider.curRoutine!;

  // For setting routine TOD for main screen
  late RoutineTime routineTime;

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

    cacheRoutineTasks = List.from(routine.routineTasks);
    shownTasks = routine.routineTasks.indexOf(SubTask());
    if (shownTasks < 0) {
      shownTasks = routine.routineTasks.length;
    }

    routineTime = routineProvider.getRoutineTime(routine: routine);
  }

  void initializeControllers() {
    mainScrollController = ScrollController();
    subScrollControllerLeft = ScrollController();
    subScrollControllerRight = ScrollController();
    scrollPhysics =
        const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics());
    nameEditingController = TextEditingController(text: routine.name);
    nameEditingController.addListener(() {
      nameErrorText = null;
      checkClose = true;
      String newText = nameEditingController.text;
      SemanticsService.announce(newText, Directionality.of(context));
      setState(() => routine.name = newText);
    });

    routineTaskEditingController = List.generate(cacheRoutineTasks.length,
        (i) => TextEditingController(text: routine.routineTasks[i].name));
    for (int i = 0; i < routineTaskEditingController.length; i++) {
      routineTaskEditingController[i].addListener(() {
        checkClose = true;
        String newText = routineTaskEditingController[i].text;
        SemanticsService.announce(newText, Directionality.of(context));
      });
    }
  }

  void initializeProviders() {
    routineProvider = Provider.of<RoutineProvider>(context, listen: false);
  }

  @override
  void dispose() {
    nameEditingController.dispose();
    for (TextEditingController controller in routineTaskEditingController) {
      controller.dispose();
    }
    super.dispose();
  }

  bool validateData() {
    bool valid = true;

    if (nameEditingController.text.isEmpty) {
      valid = false;
      setState(() => nameErrorText = "Enter Routine Name");
    }

    return valid;
  }

  Future<void> handleUpdate() async {
    await routineProvider.updateRoutine().whenComplete(() async {
      // Handle setting the routine.
      await routineProvider
          .handleRoutineTime(time: routineTime)
          .whenComplete(() {
        Navigator.pop(context);
      });
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
      setState(() => checkClose = false);
    }
  }

  void clearNameField() {
    setState(() {
      checkClose = true;
      nameEditingController.clear();
      routine.name = "";
    });
  }

  void handleWeightChange(double value) => setState(() {
        checkClose = true;
        routine.weight = value.toInt();
        routine.realDuration = routineProvider.calculateRealDuration(
            weight: routine.weight, duration: routine.expectedDuration);
      });

  void removeRoutineTask({required int index}) {
    setState(() {
      checkClose = true;
      SubTask st = routine.routineTasks.removeAt(index);
      st = SubTask();
      routine.routineTasks.add(st);
      TextEditingController ct = routineTaskEditingController.removeAt(index);
      ct.value = ct.value.copyWith(text: st.name);
      routineTaskEditingController.add(ct);

      shownTasks--;
      shownTasks = max(shownTasks, 0);
      routine.weight =
          routineProvider.calculateWeight(routineTasks: routine.routineTasks);
    });
  }

  void reorderRoutineTasks(int oldIndex, int newIndex) {
    setState(() {
      checkClose = true;
      if (oldIndex < newIndex) {
        newIndex--;
      }
      SubTask st = cacheRoutineTasks.removeAt(oldIndex);
      cacheRoutineTasks.insert(newIndex, st);
      TextEditingController ct =
          routineTaskEditingController.removeAt(oldIndex);
      routineTaskEditingController.insert(newIndex, ct);
    });
  }

  void onDataChange() {
    setState(() {
      checkClose = true;
    });
  }

  void onRoutineTaskWeightChanged() {
    setState(() {
      checkClose = true;
      routine.weight =
          routineProvider.calculateWeight(routineTasks: routine.routineTasks);
      routine.realDuration = routineProvider.calculateRealDuration(
          weight: routine.weight, duration: routine.expectedDuration);
    });
  }

  void addRoutineTask() {
    setState(() {
      shownTasks++;
      shownTasks = min(shownTasks, Constants.maxNumTasks);
    });
  }

  void updateDuration(int? value) {
    setState(() {
      checkClose = true;
      routine.expectedDuration = value ?? routine.expectedDuration;
      routine.realDuration = routineProvider.calculateRealDuration(
          weight: routine.weight, duration: routine.expectedDuration);
    });
  }

  void clearDuration() {
    setState(() {
      checkClose = true;
      routine.expectedDuration = 0;
      routine.realDuration = 0;
    });
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
        child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Title && Close Button
              TitleBar(
                currentContext: context,
                title: "Edit Routine",
                centerWidget: (routine.expectedDuration > 0)
                    ? TitleBar.toDoCenterWidget(
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
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Flexible(
                          child: ListView(
                              shrinkWrap: true,
                              controller: subScrollControllerLeft,
                              physics: scrollPhysics,
                              children: [
                            // Title

                            Tiles.nameTile(
                                context: context,
                                leading: buildTimeOfDayIcon(context: context),
                                hintText: "Routine Name",
                                errorText: nameErrorText,
                                controller: nameEditingController,
                                outerPadding: const EdgeInsets.symmetric(
                                    horizontal: Constants.padding),
                                textFieldPadding: const EdgeInsets.symmetric(
                                  horizontal: Constants.halfPadding,
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
                          child: Scrollbar(
                        controller: subScrollControllerRight,
                        thumbVisibility: true,
                        child: ListView(
                            physics: scrollPhysics,
                            controller: subScrollControllerRight,
                            shrinkWrap: true,
                            children: [buildRoutineTasksTile()]),
                      ))
                    ]),
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
                title: "New Routine",
                centerWidget: (routine.expectedDuration > 0)
                    ? TitleBar.toDoCenterWidget(
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
                  controller: mainScrollController,
                  physics: scrollPhysics,
                  children: [
                    Tiles.nameTile(
                        context: context,
                        leading: buildTimeOfDayIcon(context: context),
                        hintText: "Routine Name",
                        errorText: nameErrorText,
                        controller: nameEditingController,
                        outerPadding: const EdgeInsets.symmetric(
                            horizontal: Constants.padding),
                        textFieldPadding: const EdgeInsets.only(
                          left: Constants.halfPadding,
                        ),
                        handleClear: clearNameField),
                    Tiles.weightTile(
                      outerPadding:
                          const EdgeInsets.all(Constants.innerPadding),
                      batteryPadding: const EdgeInsets.symmetric(
                          horizontal: Constants.innerPadding),
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

                    buildRoutineTasksTile(
                        physics: const NeverScrollableScrollPhysics()),
                  ],
                ),
              ),

              const PaddedDivider(padding: Constants.halfPadding),
              Tiles.createButton(
                outerPadding:
                    const EdgeInsets.symmetric(horizontal: Constants.padding),
                handleCreate: updateAndValidate,
              ),
            ]),
      ),
    );
  }

  Widget buildRoutineTasksTile(
      {ScrollPhysics physics = const NeverScrollableScrollPhysics()}) {
    return ExpandedListTile(
      title: const AutoSizeText("Steps",
          maxLines: 1,
          overflow: TextOverflow.visible,
          softWrap: false,
          minFontSize: Constants.small),
      subtitle: AutoSizeText(
          "${min(shownTasks, Constants.maxNumTasks)}/${Constants.maxNumTasks} Steps",
          maxLines: 1,
          overflow: TextOverflow.visible,
          softWrap: false,
          minFontSize: Constants.small),
      children: [
        ListViews.reorderableSubtasks(
            physics: physics,
            context: context,
            subTasks: cacheRoutineTasks,
            itemCount: min(Constants.maxNumTasks, shownTasks),
            controllers: routineTaskEditingController,
            onRemoved: removeRoutineTask,
            onReorder: reorderRoutineTasks,
            onChanged: onDataChange,
            onSubtaskWeightChanged: onRoutineTaskWeightChanged,
            showHandle: (shownTasks > 1)),
        (shownTasks < Constants.maxNumTasks)
            ? Tiles.addTile(
                title: "Add a step",
                onTap: addRoutineTask,
              )
            : const SizedBox.shrink(),
      ],
    );
  }

  Widget buildTimeOfDayIcon({
    required BuildContext context,
  }) {
    Icon? icon = switch (routineTime) {
      RoutineTime.morning => const Icon(Icons.wb_twilight_rounded),
      RoutineTime.afternoon => const Icon(Icons.lunch_dining_rounded),
      RoutineTime.evening => const Icon(Icons.bed_rounded),
      _ => const Icon(Icons.alarm_rounded),
    };

    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.all(Constants.innerPadding),
        shape: const CircleBorder(),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      onPressed: () async {
        await showDialog<RoutineTime>(
          context: context,
          builder: (BuildContext context) {
            return Dialog(
                child: ConstrainedBox(
              constraints: const BoxConstraints(
                  maxWidth: Constants.smallLandscapeDialogWidth),
              child: Padding(
                padding: const EdgeInsets.all(Constants.innerPadding),
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Expanded(
                              child: AutoSizeText(
                                "Set Routine Time",
                                style: Constants.headerStyle,
                                softWrap: true,
                                overflow: TextOverflow.visible,
                                maxLines: 2,
                                minFontSize: Constants.medium,
                              ),
                            )
                          ]),
                      const Flexible(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            Flexible(
                                child: AutoSizeText(
                              "Morning | Afternoon | Evening ",
                              style: Constants.largeHeaderStyle,
                              softWrap: true,
                              overflow: TextOverflow.visible,
                              maxLines: 1,
                              minFontSize: Constants.large,
                            )),
                            Flexible(
                              child: FittedBox(
                                  fit: BoxFit.fill,
                                  child: Icon(Icons.schedule_rounded,
                                      size: Constants.medIconSize)),
                            ),
                          ],
                        ),
                      ),
                      Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            Flexible(
                                child: Padding(
                              padding: const EdgeInsets.all(Constants.padding),
                              child: FittedBox(
                                fit: BoxFit.fill,
                                child: (routineTime == RoutineTime.morning)
                                    ? IconButton.filledTonal(
                                        iconSize: Constants.lgIconSize,
                                        icon: const Icon(
                                            Icons.wb_twilight_rounded),
                                        onPressed: () => Navigator.pop(
                                            context, RoutineTime.none))
                                    : IconButton.outlined(
                                        iconSize: Constants.lgIconSize,
                                        icon: const Icon(
                                            Icons.wb_twilight_rounded),
                                        onPressed: () => Navigator.pop(
                                            context, RoutineTime.morning)),
                              ),
                            )),
                            Flexible(
                              child: Padding(
                                padding:
                                    const EdgeInsets.all(Constants.padding),
                                child: FittedBox(
                                  fit: BoxFit.fill,
                                  child: (routineTime == RoutineTime.afternoon)
                                      ? IconButton.filledTonal(
                                          iconSize: Constants.lgIconSize,
                                          icon: const Icon(
                                              Icons.lunch_dining_rounded),
                                          onPressed: () => Navigator.pop(
                                              context, RoutineTime.none))
                                      : IconButton.outlined(
                                          iconSize: Constants.lgIconSize,
                                          icon: const Icon(
                                              Icons.lunch_dining_rounded),
                                          onPressed: () => Navigator.pop(
                                              context, RoutineTime.afternoon)),
                                ),
                              ),
                            ),
                            Flexible(
                              child: Padding(
                                padding:
                                    const EdgeInsets.all(Constants.padding),
                                child: FittedBox(
                                  fit: BoxFit.fill,
                                  child: (routineTime == RoutineTime.evening)
                                      ? IconButton.filledTonal(
                                          iconSize: Constants.lgIconSize,
                                          icon: const Icon(Icons.bed_rounded),
                                          onPressed: () => Navigator.pop(
                                              context, RoutineTime.none))
                                      : IconButton.outlined(
                                          iconSize: Constants.lgIconSize,
                                          icon: const Icon(Icons.bed_rounded),
                                          onPressed: () => Navigator.pop(
                                              context, RoutineTime.evening)),
                                ),
                              ),
                            )
                          ]),
                      Flexible(
                        child: Padding(
                            padding: const EdgeInsets.all(Constants.padding),
                            child: Tooltip(
                              message: "Remove.",
                              child: FittedBox(
                                fit: BoxFit.fill,
                                child: IconButton.outlined(
                                  iconSize: Constants.medIconSize,
                                  icon: const Icon(
                                      Icons.remove_circle_outline_rounded),
                                  onPressed: () =>
                                      Navigator.pop(context, RoutineTime.none),
                                ),
                              ),
                            )),
                      )
                    ]),
              ),
            ));
          },
        ).then((RoutineTime? time) {
          if (time == null) {
            return;
          }
          setState(() {
            routineTime = time;
          });
        });
      },
      child: icon,
    );
  }
}
