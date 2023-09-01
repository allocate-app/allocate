import "dart:math";

import "package:another_flushbar/flushbar.dart";
import "package:auto_size_text/auto_size_text.dart";
import "package:auto_size_text_field/auto_size_text_field.dart";
import "package:flutter/material.dart";
import "package:flutter/semantics.dart";
import "package:numberpicker/numberpicker.dart";
import "package:provider/provider.dart";

import "../../../model/task/subtask.dart";
import "../../../providers/routine_provider.dart";
import "../../../util/constants.dart";
import "../../../util/exceptions.dart";
import "../../../util/numbers.dart";
import "../../widgets/flushbars.dart";
import "../../widgets/padded_divider.dart";

class CreateRoutineScreen extends StatefulWidget {
  const CreateRoutineScreen({Key? key}) : super(key: key);

  @override
  State<CreateRoutineScreen> createState() => _CreateRoutineScreen();
}

class _CreateRoutineScreen extends State<CreateRoutineScreen> {
  late bool checkClose;
  late bool expanded;

  // Provider (Needs user values) -> Refactor to DI for testing. One day.
  late final RoutineProvider routineProvider;

  // Scrolling
  late final ScrollController mainScrollController;
  late final ScrollController subScrollControllerLeft;
  late final ScrollController subScrollControllerRight;
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
  }

  void initializeControllers() {
    mainScrollController = ScrollController();
    subScrollControllerLeft = ScrollController();
    subScrollControllerRight = ScrollController();
    scrollPhysics =
        const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics());
    nameEditingController = TextEditingController();
    nameEditingController.addListener(() {
      nameErrorText = null;
      checkClose = true;
      String newText = nameEditingController.text;
      SemanticsService.announce(newText, Directionality.of(context));
      setState(() => name = newText);
    });

    routineTaskEditingController =
        List.generate(routineTasks.length, (_) => TextEditingController());
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

  Icon getBatteryIcon({required int weight, required bool selected}) {
    // Icon is scaled for sum-weight.
    weight = remap(
            x: weight,
            inMin: 0,
            inMax: Constants.maxWeight,
            outMin: 0,
            outMax: 5)
        .toInt();

    if (selected) {
      return Constants.selectedBatteryIcons[weight]!;
    }
    return Constants.batteryIcons[weight]!;
  }

  Future<void> handleCreate({required BuildContext context}) async {
    await routineProvider
        .createRoutine(
          name: name,
          weight: weight,
          expectedDuration: expectedDuration,
          realDuration: realDuration,
          routineTasks: routineTasks,
        )
        .then((value) => Navigator.pop(context))
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
                e is FailureToCreateException || e is FailureToUploadException);
  }

  @override
  Widget build(BuildContext context) {
    bool largeScreen =
        (MediaQuery.of(context).size.width >= Constants.largeScreen);
    bool smallScreen =
        (MediaQuery.of(context).size.width <= Constants.smallScreen);
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
            const BoxConstraints(maxHeight: Constants.maxLandscapeDialogHeight),
        child: Padding(
          padding: const EdgeInsets.all(Constants.padding),
          child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Title && Close Button
                Flexible(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: Constants.padding),
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Flexible(
                            child: AutoSizeText(
                              "New Routine",
                              overflow: TextOverflow.visible,
                              style: Constants.headerStyle,
                              minFontSize: Constants.medium,
                              softWrap: true,
                              maxLines: 1,
                            ),
                          ),
                          (expectedDuration > 0)
                              ? Flexible(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Flexible(
                                        child: Tooltip(
                                          message: "Expected Routine Duration",
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: Constants.padding),
                                            child: Row(
                                              children: [
                                                const Flexible(
                                                  child: FittedBox(
                                                    fit: BoxFit.fill,
                                                    child: Icon(
                                                      Icons.timer_outlined,
                                                    ),
                                                  ),
                                                ),
                                                Flexible(
                                                  child: AutoSizeText(
                                                      Duration(
                                                              seconds:
                                                                  expectedDuration)
                                                          .toString()
                                                          .split(".")
                                                          .first,
                                                      minFontSize:
                                                          Constants.medium,
                                                      overflow:
                                                          TextOverflow.visible,
                                                      softWrap: false,
                                                      maxLines: 2),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      Flexible(
                                        child: Tooltip(
                                          message: "Actual Routine Duration",
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: Constants.padding),
                                            child: Row(
                                              children: [
                                                const Flexible(
                                                  child: FittedBox(
                                                    fit: BoxFit.fill,
                                                    child: Icon(
                                                      Icons.timer,
                                                    ),
                                                  ),
                                                ),
                                                Flexible(
                                                  child: AutoSizeText(
                                                      Duration(
                                                              seconds:
                                                                  realDuration)
                                                          .toString()
                                                          .split(".")
                                                          .first,
                                                      minFontSize:
                                                          Constants.medium,
                                                      overflow:
                                                          TextOverflow.visible,
                                                      softWrap: false,
                                                      maxLines: 2),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : const SizedBox.shrink(),
                          buildCloseButton(context: context),
                        ]),
                  ),
                ),
                const PaddedDivider(padding: Constants.padding),
                Expanded(
                  // This is 100% a hacky workaround for trying to expand a listview.
                  flex: (shownTasks / 2).floor() + 1,
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                            child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                mainAxisSize: MainAxisSize.min,
                                // controller: subScrollControllerLeft,
                                children: [
                              // Title
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: Constants.padding),
                                child: buildNameTile(smallScreen: smallScreen),
                              ),
                              const PaddedDivider(
                                  padding: Constants.innerPadding),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: Constants.innerPadding),
                                  child: buildWeightTileDesktop(),
                                ),
                              ),

                              const PaddedDivider(
                                  padding: Constants.innerPadding),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: Constants.padding),
                                child: buildDurationTile(
                                    context: context, smallScreen: smallScreen),
                              ),
                            ])),
                        Expanded(
                          flex: 2,
                          child: Scrollbar(
                            thumbVisibility: true,
                            controller: subScrollControllerRight,
                            child: ListView(
                                controller: subScrollControllerRight,
                                physics: scrollPhysics,
                                shrinkWrap: true,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: Constants.padding),
                                children: [
                                  // RoutineTasks
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: Constants.innerPadding),
                                    child: Card(
                                      clipBehavior: Clip.antiAlias,
                                      elevation: 0,
                                      color: Colors.transparent,
                                      shape: RoundedRectangleBorder(
                                          side: BorderSide(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .outline,
                                              strokeAlign:
                                                  BorderSide.strokeAlignInside),
                                          borderRadius: const BorderRadius.all(
                                              Radius.circular(
                                                  Constants.roundedCorners))),
                                      child: ExpansionTile(
                                        initiallyExpanded: expanded,
                                        onExpansionChanged: (value) =>
                                            setState(() => expanded = value),
                                        title: const AutoSizeText(
                                            "Routine Steps",
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
                                        collapsedShape:
                                            const RoundedRectangleBorder(
                                                side: BorderSide(
                                                    strokeAlign: BorderSide
                                                        .strokeAlignOutside),
                                                borderRadius: BorderRadius.all(
                                                    Radius.circular(Constants
                                                        .roundedCorners))),
                                        shape: const RoundedRectangleBorder(
                                            side: BorderSide(
                                                strokeAlign: BorderSide
                                                    .strokeAlignOutside),
                                            borderRadius: BorderRadius.all(
                                                Radius.circular(
                                                    Constants.roundedCorners))),
                                        children: [
                                          buildReorderableSubTasks(
                                              smallScreen: smallScreen,
                                              physics: scrollPhysics),
                                          const PaddedDivider(
                                              padding: Constants.padding),
                                          (shownTasks < Constants.maxNumTasks)
                                              ? ListTile(
                                                  leading: const Icon(
                                                      Icons.add_outlined),
                                                  title: const AutoSizeText(
                                                      "Add a step",
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.visible,
                                                      softWrap: false,
                                                      minFontSize:
                                                          Constants.small),
                                                  onTap: () => setState(() {
                                                        shownTasks++;
                                                        shownTasks = min(
                                                            shownTasks,
                                                            Constants
                                                                .maxNumTasks);
                                                      }))
                                              : const SizedBox.shrink(),
                                        ],
                                      ),
                                    ),
                                  ),
                                ]),
                          ),
                        )
                      ]),
                ),

                const PaddedDivider(padding: Constants.padding),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: Constants.padding),
                  child: buildCreateButton(context: context),
                )
              ]),
        ),
      ),
    );
  }

  Dialog buildMobileDialog(
      {required BuildContext context, bool smallScreen = false}) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(
          horizontal: Constants.outerDialogPadding,
          vertical: Constants.smallOuterDialogPadding),
      child: Padding(
        padding: const EdgeInsets.all(Constants.padding),
        child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title && Close Button
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: Constants.padding),
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Flexible(
                        child: AutoSizeText(
                          "New Routine",
                          overflow: TextOverflow.visible,
                          style: Constants.headerStyle,
                          minFontSize: Constants.medium,
                          softWrap: true,
                          maxLines: 1,
                        ),
                      ),
                      (expectedDuration > 0)
                          ? Flexible(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Flexible(
                                    child: Tooltip(
                                      message: "Expected Routine Duration",
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: Constants.padding),
                                        child: Row(
                                          children: [
                                            const Flexible(
                                              child: FittedBox(
                                                fit: BoxFit.fill,
                                                child: Icon(
                                                  Icons.timer_outlined,
                                                ),
                                              ),
                                            ),
                                            Flexible(
                                              child: AutoSizeText(
                                                  Duration(
                                                          seconds:
                                                              expectedDuration)
                                                      .toString()
                                                      .split(".")
                                                      .first,
                                                  minFontSize: Constants.medium,
                                                  overflow:
                                                      TextOverflow.visible,
                                                  softWrap: false,
                                                  maxLines: 2),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  Flexible(
                                    child: Tooltip(
                                      message: "Actual Routine Duration",
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: Constants.padding),
                                        child: Row(
                                          children: [
                                            const Flexible(
                                              child: FittedBox(
                                                fit: BoxFit.fill,
                                                child: Icon(
                                                  Icons.timer,
                                                ),
                                              ),
                                            ),
                                            Flexible(
                                              child: AutoSizeText(
                                                  Duration(
                                                          seconds: realDuration)
                                                      .toString()
                                                      .split(".")
                                                      .first,
                                                  minFontSize: Constants.medium,
                                                  overflow:
                                                      TextOverflow.visible,
                                                  softWrap: false,
                                                  maxLines: 2),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : const SizedBox.shrink(),
                      buildCloseButton(context: context),
                    ]),
              ),
              const PaddedDivider(padding: Constants.padding),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  controller: mainScrollController,
                  physics: scrollPhysics,
                  children: [
                    // Title + status
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: Constants.padding),
                      child: buildNameTile(smallScreen: smallScreen),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: Constants.innerPadding),
                      child: buildWeightTileMobile(smallScreen: smallScreen),
                    ),

                    const PaddedDivider(padding: Constants.innerPadding),
                    // Expected Duration / RealDuration -> Show status, on click, open a dialog.
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: Constants.padding),
                      child: buildDurationTile(
                          context: context, smallScreen: smallScreen),
                    ),

                    const PaddedDivider(padding: Constants.innerPadding),

                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: Constants.innerPadding),
                      child: Card(
                        clipBehavior: Clip.antiAlias,
                        elevation: 0,
                        color: Colors.transparent,
                        shape: RoundedRectangleBorder(
                            side: BorderSide(
                                color: Theme.of(context).colorScheme.outline,
                                strokeAlign: BorderSide.strokeAlignInside),
                            borderRadius: const BorderRadius.all(
                                Radius.circular(Constants.roundedCorners))),
                        child: ExpansionTile(
                          initiallyExpanded: expanded,
                          onExpansionChanged: (value) =>
                              setState(() => expanded = value),
                          title: const AutoSizeText("Routine Steps",
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
                          collapsedShape: const RoundedRectangleBorder(
                              side: BorderSide(
                                  strokeAlign: BorderSide.strokeAlignOutside),
                              borderRadius: BorderRadius.all(
                                  Radius.circular(Constants.roundedCorners))),
                          shape: const RoundedRectangleBorder(
                              side: BorderSide(
                                  strokeAlign: BorderSide.strokeAlignOutside),
                              borderRadius: BorderRadius.all(
                                  Radius.circular(Constants.roundedCorners))),
                          children: [
                            buildReorderableSubTasks(
                                smallScreen: smallScreen,
                                physics: scrollPhysics),
                            (shownTasks < Constants.maxNumTasks)
                                ? ListTile(
                                    leading: const Icon(Icons.add_outlined),
                                    title: const AutoSizeText("Add a step",
                                        maxLines: 1,
                                        overflow: TextOverflow.visible,
                                        softWrap: false,
                                        minFontSize: Constants.small),
                                    onTap: () => setState(() {
                                          shownTasks++;
                                          shownTasks = min(shownTasks,
                                              Constants.maxNumTasks);
                                        }))
                                : const SizedBox.shrink(),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const PaddedDivider(padding: Constants.padding),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: Constants.padding),
                child: buildCreateButton(context: context),
              )
            ]),
      ),
    );
  }

  Row buildCreateButton({required BuildContext context}) {
    return Row(mainAxisAlignment: MainAxisAlignment.end, children: [
      FilledButton.icon(
          label: const Text("Create"),
          icon: const Icon(Icons.add),
          onPressed: () async {
            bool validData = validateData();
            if (validData) {
              await handleCreate(context: context);
            }
            // Then save.
          })
    ]);
  }

  Column buildWeightTileDesktop() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Flexible(
          child: AutoSizeText("Routine Strain",
              minFontSize: Constants.medium,
              maxLines: 1,
              softWrap: true,
              style: Constants.hugeHeaderStyle),
        ),
        Expanded(
          flex: 2,
          child: Tooltip(
              message: "How draining is this routine?",
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 200),
                child: FittedBox(
                  fit: BoxFit.fitHeight,
                  child: Transform.rotate(
                      angle: -pi / 2,
                      child: getBatteryIcon(weight: weight, selected: false)),
                ),
              )),
        ),
      ],
    );
  }

  Row buildWeightTileMobile({bool smallScreen = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Flexible(
          child: AutoSizeText("Routine Strain",
              minFontSize: Constants.large,
              maxLines: 1,
              softWrap: true,
              style: Constants.hugeHeaderStyle),
        ),
        Expanded(
          child: Tooltip(
              message: "How draining is this routine?",
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 100),
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: Transform.rotate(
                      angle: -pi / 2,
                      child: getBatteryIcon(weight: weight, selected: false)),
                ),
              )),
        ),
        (smallScreen) ? const SizedBox.shrink() : const Spacer(),
      ],
    );
  }

  ReorderableListView buildReorderableSubTasks(
      {bool smallScreen = false,
      ScrollPhysics physics = const BouncingScrollPhysics()}) {
    return ReorderableListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: min(Constants.maxNumTasks, shownTasks),
      onReorder: (int oldIndex, int newIndex) {
        setState(() {
          checkClose = true;
          if (oldIndex < newIndex) {
            newIndex--;
          }

          SubTask st = routineTasks.removeAt(oldIndex);
          routineTasks.insert(newIndex, st);
          TextEditingController ct =
              routineTaskEditingController.removeAt(oldIndex);
          //ct.value = ct.value.copyWith(text: st.name);
          routineTaskEditingController.insert(newIndex, ct);
        });
      },
      itemBuilder: (BuildContext context, int index) {
        return CheckboxListTile(
            key: ValueKey(index),
            checkboxShape: const CircleBorder(),
            controlAffinity: ListTileControlAffinity.leading,
            shape: const CircleBorder(),
            title: Row(
              children: [
                IconButton(
                  icon: Constants.batteryIcons[routineTasks[index].weight]!,
                  selectedIcon: Constants
                      .selectedBatteryIcons[routineTasks[index].weight]!,
                  onPressed: () {
                    showModalBottomSheet<void>(
                        showDragHandle: true,
                        context: context,
                        builder: (BuildContext context) {
                          return StatefulBuilder(
                            builder: (context, setState) => Center(
                                heightFactor: 1,
                                child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text("Step Strain",
                                          style: Constants.headerStyle),
                                      Padding(
                                          padding: const EdgeInsets.all(
                                              Constants.padding),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceEvenly,
                                            children: [
                                              const Icon(Icons.battery_full),
                                              Expanded(
                                                child: Slider(
                                                  value: routineTasks[index]
                                                      .weight
                                                      .toDouble(),
                                                  max: Constants.maxTaskWeight
                                                      .toDouble(),
                                                  label: (routineTasks[index]
                                                              .weight >
                                                          (Constants.maxTaskWeight /
                                                                  2)
                                                              .floor())
                                                      ? " ${routineTasks[index].weight} ${Constants.lowBattery}"
                                                      : " ${routineTasks[index].weight} ${Constants.fullBattery}",
                                                  divisions:
                                                      Constants.maxTaskWeight,
                                                  onChanged: (value) =>
                                                      setState(() {
                                                    checkClose = true;
                                                    routineTasks[index].weight =
                                                        value.toInt();
                                                  }),
                                                ),
                                              ),
                                              const Icon(Icons.battery_1_bar),
                                            ],
                                          )),
                                    ])),
                          );
                        }).whenComplete(() => setState(() {
                          weight = routineProvider.calculateWeight(
                              routineTasks: routineTasks);
                          realDuration = routineProvider.calculateRealDuration(
                              weight: weight, duration: expectedDuration);
                        }));
                  },
                ),
                Expanded(
                  child: AutoSizeTextField(
                      controller: routineTaskEditingController[index],
                      maxLines: 1,
                      minFontSize: Constants.small,
                      decoration: InputDecoration(
                        isDense: smallScreen,
                        hintText: "Step name",
                      ),
                      onChanged: (value) {
                        routineTasks[index].name = value;
                        routineTaskEditingController[index].value =
                            routineTaskEditingController[index].value.copyWith(
                                  text: value,
                                  selection: TextSelection.collapsed(
                                      offset: value.length),
                                );
                      }),
                ),
              ],
            ),
            value: routineTasks[index].completed,
            onChanged: (bool? value) => setState(() {
                  checkClose = true;
                  routineTasks[index].completed = value!;
                }),

            // Delete Subtask
            secondary: IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () => setState(() {
                      checkClose = true;
                      SubTask st = routineTasks.removeAt(index);
                      st = SubTask();
                      routineTasks.add(st);
                      TextEditingController ct =
                          routineTaskEditingController.removeAt(index);
                      ct.value = ct.value.copyWith(text: st.name);
                      routineTaskEditingController.add(ct);

                      shownTasks--;
                      shownTasks = max(shownTasks, 0);
                      weight = routineProvider.calculateWeight(
                          routineTasks: routineTasks);
                    })));
      },
    );
  }

  ListView buildSubTasksList(
      {bool smallScreen = false,
      ScrollPhysics physics = const BouncingScrollPhysics()}) {
    return ListView.separated(
      // Possibly need scroll controller.
      physics: physics,
      shrinkWrap: true,
      itemCount: min(Constants.maxNumTasks, shownTasks),
      separatorBuilder: (context, index) => const Divider(),
      itemBuilder: (BuildContext context, int index) {
        return CheckboxListTile(
            checkboxShape: const CircleBorder(),
            controlAffinity: ListTileControlAffinity.leading,
            shape: const CircleBorder(),
            title: Row(
              children: [
                IconButton(
                  icon: Constants.batteryIcons[routineTasks[index].weight]!,
                  selectedIcon: Constants
                      .selectedBatteryIcons[routineTasks[index].weight]!,
                  onPressed: () {
                    showModalBottomSheet<void>(
                        showDragHandle: true,
                        context: context,
                        builder: (BuildContext context) {
                          return StatefulBuilder(
                            builder: (context, setState) => Center(
                                heightFactor: 1,
                                child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text("Step Strain",
                                          style: Constants.headerStyle),
                                      Padding(
                                          padding: const EdgeInsets.all(
                                              Constants.padding),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceEvenly,
                                            children: [
                                              const Icon(Icons.battery_full),
                                              Expanded(
                                                child: Slider(
                                                  value: routineTasks[index]
                                                      .weight
                                                      .toDouble(),
                                                  max: Constants.maxTaskWeight
                                                      .toDouble(),
                                                  label: (routineTasks[index]
                                                              .weight >
                                                          (Constants.maxTaskWeight /
                                                                  2)
                                                              .floor())
                                                      ? " ${routineTasks[index].weight} ${Constants.lowBattery}"
                                                      : " ${routineTasks[index].weight} ${Constants.fullBattery}",
                                                  divisions:
                                                      Constants.maxTaskWeight,
                                                  onChanged: (value) =>
                                                      setState(() {
                                                    checkClose = true;
                                                    routineTasks[index].weight =
                                                        value.toInt();
                                                  }),
                                                ),
                                              ),
                                              const Icon(Icons.battery_1_bar),
                                            ],
                                          )),
                                    ])),
                          );
                        }).whenComplete(() => setState(() {
                          weight = routineProvider.calculateWeight(
                              routineTasks: routineTasks);
                          realDuration = routineProvider.calculateRealDuration(
                              weight: weight, duration: expectedDuration);
                        }));
                  },
                ),
                Expanded(
                  child: AutoSizeTextField(
                      controller: routineTaskEditingController[index],
                      maxLines: 1,
                      minFontSize: Constants.small,
                      decoration: InputDecoration(
                        isDense: smallScreen,
                        hintText: "Step name",
                      ),
                      onChanged: (value) {
                        routineTasks[index].name = value;
                        routineTaskEditingController[index].value =
                            routineTaskEditingController[index].value.copyWith(
                                  text: value,
                                  selection: TextSelection.collapsed(
                                      offset: value.length),
                                );
                      }),
                ),
              ],
            ),
            value: routineTasks[index].completed,
            onChanged: (bool? value) => setState(() {
                  checkClose = true;
                  routineTasks[index].completed = value!;
                }),

            // Delete Subtask
            secondary: IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () => setState(() {
                      SubTask st = routineTasks.removeAt(index);
                      st = SubTask();
                      routineTasks.add(st);
                      TextEditingController ct =
                          routineTaskEditingController.removeAt(index);
                      ct.value = ct.value.copyWith(text: st.name);
                      routineTaskEditingController.add(ct);

                      shownTasks--;
                      shownTasks = max(shownTasks, 0);
                      weight = routineProvider.calculateWeight(
                          routineTasks: routineTasks);
                    })));
      },
    );
  }

  Row buildNameTile({bool smallScreen = false}) {
    return Row(
      children: [
        Expanded(
            child: Padding(
          padding: const EdgeInsets.all(Constants.padding),
          child: buildRoutineName(smallScreen: smallScreen),
        )),
      ],
    );
  }

  ListTile buildDurationTile(
      {required BuildContext context, bool smallScreen = false}) {
    return ListTile(
      leading: const Icon(Icons.timer_outlined),
      title: (expectedDuration > 0)
          ? Row(
              children: [
                Flexible(
                  child: AutoSizeText(
                      (smallScreen)
                          ? Duration(seconds: expectedDuration)
                              .toString()
                              .split(".")
                              .first
                          : "Expected: ${Duration(seconds: expectedDuration).toString().split(".").first}",
                      overflow: TextOverflow.visible,
                      minFontSize: Constants.small,
                      maxLines: 2,
                      softWrap: true),
                ),
                const Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: Constants.innerPadding),
                  child: Icon(
                    Icons.timer,
                  ),
                ),
                Flexible(
                  child: AutoSizeText(
                      (smallScreen)
                          ? Duration(seconds: realDuration)
                              .toString()
                              .split(".")
                              .first
                          : "Actual: ${Duration(seconds: realDuration).toString().split(".").first}",
                      overflow: TextOverflow.visible,
                      minFontSize: Constants.small,
                      maxLines: 2,
                      softWrap: true),
                ),
              ],
            )
          : const AutoSizeText("Expected Routine Duration: ",
              overflow: TextOverflow.visible,
              minFontSize: Constants.small,
              maxLines: 2,
              softWrap: true),
      trailing: (expectedDuration > 0)
          ? IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () => setState(() {
                    checkClose = true;
                    expectedDuration = 0;
                    realDuration = 0;
                  }))
          : null,
      onTap: () => showDialog<int>(
          context: context,
          builder: (BuildContext context) {
            int time = expectedDuration;
            int hours = time ~/ 3600;
            time %= 3600;
            int minutes = time ~/ 60;
            time %= 60;
            int seconds = time;

            return StatefulBuilder(
              builder: (context, setState) => Dialog(
                  child: Padding(
                      padding: const EdgeInsets.all(Constants.innerPadding),
                      child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                      child: AutoSizeText(
                                    "Hours",
                                    maxLines: 1,
                                    minFontSize: Constants.small,
                                    softWrap: false,
                                    overflow: TextOverflow.visible,
                                    textAlign: TextAlign.center,
                                  )),
                                  Expanded(
                                      child: AutoSizeText(
                                    "Minutes",
                                    maxLines: 1,
                                    minFontSize: Constants.small,
                                    softWrap: false,
                                    overflow: TextOverflow.visible,
                                    textAlign: TextAlign.center,
                                  )),
                                  Expanded(
                                      child: AutoSizeText(
                                    "Seconds",
                                    maxLines: 1,
                                    minFontSize: Constants.small,
                                    softWrap: false,
                                    overflow: TextOverflow.visible,
                                    textAlign: TextAlign.center,
                                  ))
                                ]),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Expanded(
                                  child: NumberPicker(
                                    textStyle: Constants.numberPickerSecondary(
                                        context: context),
                                    selectedTextStyle:
                                        Constants.numberPickerPrimary(
                                            context: context),
                                    minValue: 0,
                                    maxValue: 100,
                                    value: hours,
                                    haptics: true,
                                    onChanged: (value) {
                                      SemanticsService.announce("$value, hours",
                                          Directionality.of(context));
                                      setState(() => hours = value);
                                    },
                                  ),
                                ),
                                const Padding(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: Constants.padding),
                                    child:
                                        Text(":", style: Constants.timeColon)),
                                Expanded(
                                  child: NumberPicker(
                                    textStyle: Constants.numberPickerSecondary(
                                        context: context),
                                    selectedTextStyle:
                                        Constants.numberPickerPrimary(
                                            context: context),
                                    minValue: 0,
                                    maxValue: 59,
                                    value: minutes,
                                    haptics: true,
                                    onChanged: (value) {
                                      SemanticsService.announce(
                                          "$value, minutes",
                                          Directionality.of(context));
                                      setState(() => minutes = value);
                                    },
                                  ),
                                ),
                                const Padding(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: Constants.padding),
                                    child:
                                        Text(":", style: Constants.timeColon)),
                                Expanded(
                                  child: NumberPicker(
                                    textStyle: Constants.numberPickerSecondary(
                                        context: context),
                                    selectedTextStyle:
                                        Constants.numberPickerPrimary(
                                            context: context),
                                    minValue: 0,
                                    maxValue: 59,
                                    value: seconds,
                                    haptics: true,
                                    onChanged: (value) {
                                      SemanticsService.announce(
                                          "$value, seconds",
                                          Directionality.of(context));
                                      setState(() => seconds = value);
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.only(
                                          right: Constants.padding),
                                      child: FilledButton.tonalIcon(
                                          icon:
                                              const Icon(Icons.close_outlined),
                                          onPressed: () =>
                                              Navigator.pop(context, 0),
                                          label: const AutoSizeText("Cancel",
                                              softWrap: false,
                                              overflow: TextOverflow.visible,
                                              maxLines: 1,
                                              minFontSize: Constants.small)),
                                    ),
                                  ),
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.only(
                                          left: Constants.padding),
                                      child: FilledButton.icon(
                                        icon: const Icon(Icons.done_outlined),
                                        onPressed: () {
                                          Navigator.pop(
                                              context,
                                              (hours * 3600) +
                                                  (minutes * 60) +
                                                  seconds);
                                        },
                                        label: const AutoSizeText("Done",
                                            softWrap: false,
                                            overflow: TextOverflow.visible,
                                            maxLines: 1,
                                            minFontSize: Constants.small),
                                      ),
                                    ),
                                  )
                                ])
                          ]))),
            );
          }).then((value) {
        setState(() {
          checkClose = true;
          expectedDuration = value ?? expectedDuration;
          realDuration = routineProvider.calculateRealDuration(
              weight: weight, duration: expectedDuration);
        });
      }),
    );
  }

  AutoSizeTextField buildRoutineName({bool smallScreen = false}) {
    return AutoSizeTextField(
      maxLines: 1,
      minFontSize: Constants.medium,
      decoration: InputDecoration(
        isDense: smallScreen,
        suffixIcon: (name != "")
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  checkClose = true;
                  nameEditingController.clear();
                  setState(() => name = "");
                })
            : null,
        contentPadding: const EdgeInsets.all(Constants.innerPadding),
        border: const OutlineInputBorder(
            borderRadius:
                BorderRadius.all(Radius.circular(Constants.roundedCorners)),
            borderSide: BorderSide(
              strokeAlign: BorderSide.strokeAlignOutside,
            )),
        hintText: "Routine name",
        errorText: nameErrorText,
      ),
      controller: nameEditingController,
    );
  }

  IconButton buildCloseButton({required BuildContext context}) {
    return IconButton(
        onPressed: () {
          if (checkClose) {
            showModalBottomSheet<bool>(
                showDragHandle: true,
                context: context,
                builder: (BuildContext context) {
                  return Center(
                      heightFactor: 1,
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // const Icon(Icons.drag_handle_rounded),
                            Padding(
                              padding: const EdgeInsets.all(Constants.padding),
                              child: FilledButton.icon(
                                onPressed: () {
                                  Navigator.pop(context, true);
                                },
                                label: const Text("Discard"),
                                icon: const Icon(Icons.delete_forever_outlined),
                              ),
                            ),
                            Padding(
                                padding:
                                    const EdgeInsets.all(Constants.padding),
                                child: FilledButton.tonalIcon(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  label: const Text("Continue Editing"),
                                  icon: const Icon(
                                    Icons.edit_note_outlined,
                                  ),
                                ))
                          ]));
                }).then((willDiscard) {
              if (willDiscard ?? false) {
                Navigator.pop(context);
              }
            });
            setState(() => checkClose = false);
          } else {
            Navigator.pop(context);
          }
        },
        icon: const Icon(Icons.close_outlined),
        selectedIcon: const Icon(Icons.close));
  }
}
