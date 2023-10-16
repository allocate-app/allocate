import "dart:math";

import "package:another_flushbar/flushbar.dart";
import "package:auto_size_text/auto_size_text.dart";
import "package:flutter/material.dart";
import "package:flutter/semantics.dart";
import "package:provider/provider.dart";

import "../../../model/task/subtask.dart";
import "../../../providers/routine_provider.dart";
import "../../../util/constants.dart";
import "../../../util/enums.dart";
import "../../../util/exceptions.dart";
import "../../widgets/expanded_listtile.dart";
import "../../widgets/flushbars.dart";
import "../../widgets/leading_widgets.dart";
import "../../widgets/listviews.dart";
import "../../widgets/padded_divider.dart";
import "../../widgets/tiles.dart";
import "../../widgets/title_bar.dart";

class CreateRoutineScreen extends StatefulWidget {
  const CreateRoutineScreen({Key? key, this.routineTime}) : super(key: key);
  final RoutineTime? routineTime;

  @override
  State<CreateRoutineScreen> createState() => _CreateRoutineScreen();
}

class _CreateRoutineScreen extends State<CreateRoutineScreen> {
  late bool checkClose;
  late bool expanded;

  // Provider (Needs user values) -> Refactor to DI for testing. One day.
  late final RoutineProvider routineProvider;

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

  late final List<TextEditingController> routineTaskEditingController;
  late final List<SubTask> routineTasks;
  late int shownTasks;

  // If setting the routine for the home screen.
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
    name = "";
    weight = 0;
    expectedDuration = 0;
    realDuration = 0;

    routineTasks = List.generate(Constants.maxNumTasks, (_) => SubTask());
    shownTasks = 0;
    routineTime = widget.routineTime ?? RoutineTime.none;
  }

  void initializeControllers() {
    mobileScrollController = ScrollController();
    desktopScrollController = ScrollController();
    scrollPhysics =
        const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics());
    nameEditingController = TextEditingController();
    nameEditingController.addListener(() {
      nameErrorText = null;
      checkClose = true;
      String newText = nameEditingController.text;
      SemanticsService.announce(newText, Directionality.of(context));
      if (mounted) {
        return setState(() => name = newText);
      }
    });

    routineTaskEditingController =
        List.generate(routineTasks.length, (_) => TextEditingController());
  }

  void initializeProviders() {
    routineProvider = Provider.of<RoutineProvider>(context, listen: false);
  }

  @override
  void dispose() {
    nameEditingController.dispose();
    mobileScrollController.dispose();
    desktopScrollController.dispose();
    for (TextEditingController controller in routineTaskEditingController) {
      controller.dispose();
    }
    super.dispose();
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
    await routineProvider
        .createRoutine(
      name: name,
      weight: weight,
      expectedDuration: expectedDuration,
      realDuration: realDuration,
      routineTasks: routineTasks,
    )
        .whenComplete(() async {
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
      Navigator.pop(context);
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
        name = "";
      });
    }
  }

  void changeRoutineTime({required RoutineTime? newRoutineTime}) {
    if (null == newRoutineTime) {
      return;
    }
    if (mounted) {
      return setState(() {
        checkClose = true;
        routineTime = newRoutineTime;
      });
    }
  }

  void handleWeightChange(double value) {
    if (mounted) {
      return setState(() {
        checkClose = true;
        weight = value.toInt();
        realDuration = routineProvider.calculateRealDuration(
            weight: weight, duration: expectedDuration);
      });
    }
  }

  void removeRoutineTask({required int index}) {
    if (mounted) {
      return setState(() {
        checkClose = true;
        SubTask st = routineTasks.removeAt(index);
        st = SubTask();
        routineTasks.add(st);
        TextEditingController ct = routineTaskEditingController.removeAt(index);
        ct.value = ct.value.copyWith(text: st.name);
        routineTaskEditingController.add(ct);

        shownTasks--;
        shownTasks = max(shownTasks, 0);
        weight = routineProvider.calculateWeight(routineTasks: routineTasks);
      });
    }
  }

  void reorderRoutineTasks(int oldIndex, int newIndex) {
    if (mounted) {
      return setState(() {
        checkClose = true;
        if (oldIndex < newIndex) {
          newIndex--;
        }
        SubTask st = routineTasks.removeAt(oldIndex);
        routineTasks.insert(newIndex, st);
        TextEditingController ct =
            routineTaskEditingController.removeAt(oldIndex);
        routineTaskEditingController.insert(newIndex, ct);
      });
    }
  }

  void onDataChange() {
    if (mounted) {
      return setState(() {
        checkClose = true;
      });
    }
  }

  void onRoutineTaskWeightChanged() {
    if (mounted) {
      return setState(() {
        checkClose = true;
        weight = routineProvider.calculateWeight(routineTasks: routineTasks);
        realDuration = routineProvider.calculateRealDuration(
            weight: weight, duration: expectedDuration);
      });
    }
  }

  void addRoutineTask() {
    if (mounted) {
      return setState(() {
        shownTasks++;
        shownTasks = min(shownTasks, Constants.maxNumTasks);
      });
    }
  }

  void updateDuration(int? value) {
    if (mounted) {
      return setState(() {
        checkClose = true;
        expectedDuration = value ?? expectedDuration;
        realDuration = routineProvider.calculateRealDuration(
            weight: weight, duration: expectedDuration);
      });
    }
  }

  void clearDuration() {
    if (mounted) {
      return setState(() {
        checkClose = true;
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
                                    leading: LeadingWidgets.routineIcon(
                                      currentContext: context,
                                      scale: Constants.largeCheckboxMinScale,
                                      routineTime: routineTime,
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
                                    handleClear: clearNameField),
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
                                buildRoutineTasksTile(
                                  outerPadding: const EdgeInsets.all(
                                    Constants.halfPadding,
                                  ),
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
                        leading: LeadingWidgets.routineIcon(
                          currentContext: context,
                          scale: Constants.largeCheckboxMinScale,
                          routineTime: routineTime,
                          handleRoutineTimeChange: changeRoutineTime,
                        ),
                        hintText: "Routine Name",
                        errorText: nameErrorText,
                        controller: nameEditingController,
                        outerPadding: const EdgeInsets.all(Constants.padding),
                        textFieldPadding:
                            const EdgeInsets.only(left: Constants.halfPadding),
                        handleClear: clearNameField),
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

                    buildRoutineTasksTile(),
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

  Widget buildRoutineTasksTile(
      {ScrollPhysics physics = const NeverScrollableScrollPhysics(),
      EdgeInsetsGeometry outerPadding = EdgeInsets.zero}) {
    return ExpandedListTile(
      outerPadding: outerPadding,
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
          subTasks: routineTasks,
          itemCount: min(Constants.maxNumTasks, shownTasks),
          controllers: routineTaskEditingController,
          onRemoved: removeRoutineTask,
          onReorder: reorderRoutineTasks,
          onChanged: onDataChange,
          onSubtaskWeightChanged: onRoutineTaskWeightChanged,
          showHandle: shownTasks > 1,
        ),
        (shownTasks < Constants.maxNumTasks)
            ? Tiles.addTile(
                title: "Add a step",
                onTap: addRoutineTask,
              )
            : const SizedBox.shrink(),
      ],
    );
  }
}
