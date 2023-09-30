import "dart:math";

import "package:another_flushbar/flushbar.dart";
import "package:auto_size_text/auto_size_text.dart";
import "package:auto_size_text_field/auto_size_text_field.dart";
import "package:calendar_date_picker2/calendar_date_picker2.dart";
import "package:flutter/material.dart";
import "package:flutter/semantics.dart";
import "package:intl/intl.dart";
import "package:jiffy/jiffy.dart";
import "package:numberpicker/numberpicker.dart";
import "package:provider/provider.dart";

import "../../../model/task/group.dart";
import "../../../model/task/subtask.dart";
import "../../../model/task/todo.dart";
import "../../../providers/group_provider.dart";
import "../../../providers/todo_provider.dart";
import "../../../providers/user_provider.dart";
import "../../../util/constants.dart";
import "../../../util/enums.dart";
import "../../../util/exceptions.dart";
import "../../../util/numbers.dart";
import "../../widgets/flushbars.dart";
import "../../widgets/padded_divider.dart";

class UpdateToDoScreen extends StatefulWidget {
  final int? groupID;

  const UpdateToDoScreen({Key? key, this.groupID}) : super(key: key);

  @override
  State<UpdateToDoScreen> createState() => _UpdateToDoScreen();
}

class _UpdateToDoScreen extends State<UpdateToDoScreen> {
  late bool checkClose;
  late bool expanded;

  late final UserProvider userProvider;
  late final ToDoProvider toDoProvider;
  late final GroupProvider groupProvider;

  // Cache for repeating events & discard
  late final ToDo prevToDo;

  // For showing times.
  late bool showStartTime;
  late bool showDueTime;

  // Scrolling
  late final ScrollController mainScrollController;
  late final ScrollController subScrollControllerLeft;
  late final ScrollController subScrollControllerRight;
  late final ScrollPhysics scrollPhysics;

  // Name
  late final TextEditingController nameEditingController;
  String? nameErrorText;

  // Group
  late final SearchController groupEditingController;
  late List<MapEntry<String, int>> searchHistory;

  // Description
  late final TextEditingController descriptionEditingController;

  // Repeat
  late TextEditingController repeatSkipEditingController;

  late final List<TextEditingController> subTaskEditingController;
  late int shownTasks;

  // This is just a convenience method to avoid extra typing
  ToDo get toDo => toDoProvider.curToDo!;

  // Subtasks
  late List<SubTask> cacheSubTasks;

  @override
  void initState() {
    super.initState();
    initializeProviders();
    initializeParams();
    initializeControllers().whenComplete(() {});
    expanded = false;
  }

  void initializeProviders() {
    userProvider = Provider.of<UserProvider>(context, listen: false);
    toDoProvider = Provider.of<ToDoProvider>(context, listen: false);
    groupProvider = Provider.of<GroupProvider>(context, listen: false);
  }

  @override
  void dispose() {
    nameEditingController.dispose();
    groupEditingController.dispose();
    descriptionEditingController.dispose();
    repeatSkipEditingController.dispose();

    for (TextEditingController controller in subTaskEditingController) {
      controller.dispose();
    }

    super.dispose();
  }

  void initializeParams() {
    checkClose = false;
    prevToDo = toDo.copy();
    shownTasks = toDo.subTasks.indexOf(SubTask());
    if (shownTasks < 0) {
      shownTasks = toDo.subTasks.length;
    }

    cacheSubTasks = List.from(toDo.subTasks);

    // Midnight as a start/due time is ambiguous.
    showStartTime =
        Constants.midnight != TimeOfDay.fromDateTime(toDo.startDate);
    showDueTime = Constants.midnight != TimeOfDay.fromDateTime(toDo.dueDate);
    searchHistory = List.empty(growable: true);
  }

  Future<void> initializeControllers() async {
    mainScrollController = ScrollController();
    subScrollControllerLeft = ScrollController();
    subScrollControllerRight = ScrollController();
    scrollPhysics =
    const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics());

    nameEditingController = TextEditingController(text: toDo.name);
    nameEditingController.addListener(() {
      nameErrorText = null;
      checkClose = true;
      String newText = nameEditingController.text;
      SemanticsService.announce(newText, Directionality.of(context));
      setState(() => toDo.name = newText);
    });

    groupEditingController = SearchController();
    groupProvider
        .getGroupByID(id: toDo.groupID)
        .then((group) =>
        setState(() => groupEditingController.text = group?.name ?? ""))
        .catchError((_) {
      Flushbar? error;

      error = Flushbars.createError(
        message: "Error with Group Retrieval",
        context: context,
        dismissCallback: () => error?.dismiss(),
      );

      error.show(context);
    });
    groupEditingController.addListener(() {
      checkClose = true;
      String newText = nameEditingController.text;
      SemanticsService.announce(newText, Directionality.of(context));
    });

    descriptionEditingController =
        TextEditingController(text: toDo.description);
    descriptionEditingController.addListener(() {
      checkClose = true;
      String newText = descriptionEditingController.text;
      SemanticsService.announce(newText, Directionality.of(context));
      toDo.description = newText;
    });

    repeatSkipEditingController =
        TextEditingController(text: toDo.repeatSkip.toString());
    repeatSkipEditingController.addListener(() {
      checkClose = true;
      String newText = descriptionEditingController.text;
      SemanticsService.announce(newText, Directionality.of(context));
      toDo.repeatSkip = int.tryParse(newText) ?? toDo.repeatSkip;
      toDo.repeatSkip = max(toDo.repeatSkip, 1);
    });

    subTaskEditingController = List.generate(toDo.subTasks.length,
            (i) => TextEditingController(text: toDo.subTasks[i].name));
    for (int i = 0; i < subTaskEditingController.length; i++) {
      subTaskEditingController[i].addListener(() {
        checkClose = true;
        String newText = subTaskEditingController[i].text;
        SemanticsService.announce(newText, Directionality.of(context));
      });
    }
  }

  void handleGroupSelection(
      {required Group group, required SearchController controller}) {
    // Controller logic
    controller.closeView(group.name);
    setState(() {
      checkClose = true;
      toDo.groupID = group.localID;
      if (searchHistory.length >= Constants.historyLength) {
        searchHistory.removeLast();
      }

      searchHistory.insert(0, MapEntry(group.name, group.id));
    });
  }

  void handleHistorySelection({required MapEntry<String, int> groupData,
    required SearchController controller}) {
    controller.closeView(groupData.key);
    setState(() {
      checkClose = true;
      toDo.groupID = groupData.value;
    });
  }

  bool validateData() {
    bool valid = true;
    if (groupEditingController.text.isEmpty) {
      toDo.groupID = widget.groupID;
    }
    if (nameEditingController.text.isEmpty) {
      valid = false;
      setState(() => nameErrorText = "Enter Task Name");
    }
    if (toDo.frequency == Frequency.custom) {
      if (!toDo.repeatDays.contains(true)) {
        for (int i = 0; i < toDo.repeatDays.length; i++) {
          toDo.repeatDays[i] = prevToDo.repeatDays[i];
        }
      }
    } else {}

    return valid;
  }

  Icon getBatteryIcon({required int weight, required bool selected}) {
    // Icon is scaled for sum-weight.
    weight = (toDo.taskType == TaskType.small)
        ? weight
        : remap(
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

  Future<void> handleUpdate({required BuildContext context}) async {
    if (prevToDo.frequency != Frequency.once && checkClose) {
      bool? updateSingle = await showModalBottomSheet<bool?>(
          showDragHandle: true,
          context: context,
          builder: (BuildContext context) {
            return StatefulBuilder(
                builder: (BuildContext context,
                    void Function(void Function()) setState) =>
                    Center(
                        heightFactor: 1,
                        child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Padding(
                                padding:
                                const EdgeInsets.all(Constants.padding),
                                child: FilledButton.icon(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    label: const Text("This Event"),
                                    icon:
                                    const Icon(Icons.arrow_upward_rounded)),
                              ),
                              Padding(
                                  padding:
                                  const EdgeInsets.all(Constants.padding),
                                  child: FilledButton.tonalIcon(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    label: const Text("All Future Events"),
                                    icon: const Icon(Icons.repeat_rounded),
                                  ))
                            ])));
          });
      // If the modal is discarded.
      if (null == updateSingle) {
        return;
      }

      await toDoProvider.deleteFutures(toDo: prevToDo).catchError((e) {
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

      if (updateSingle) {
        prevToDo.repeatable = true;
        // Need to sever the connection to future repeating events.
        toDo.repeatID = toDo.hashCode;

        await toDoProvider.nextRepeat(toDo: prevToDo).catchError((e) {
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
        toDo.repeatable = false;
        toDo.frequency = Frequency.once;
      } else {
        toDo.repeatable = (toDo.frequency != Frequency.once);
      }
    } else {
      toDo.repeatable = (toDo.frequency != Frequency.once);
    }

    toDo.subTasks.setAll(0, cacheSubTasks);
    return await toDoProvider.updateToDo().whenComplete(() {
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

  Future<void> handleDelete({required BuildContext context}) async {
    if (prevToDo.frequency != Frequency.once) {
      bool? updateSingle = await showModalBottomSheet<bool?>(
          showDragHandle: true,
          context: context,
          builder: (BuildContext context) {
            return StatefulBuilder(
                builder: (BuildContext context,
                    void Function(void Function()) setState) =>
                    Center(
                        heightFactor: 1,
                        child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Padding(
                                padding:
                                const EdgeInsets.all(Constants.padding),
                                child: FilledButton.icon(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    label: const Text("Delete This Event"),
                                    icon:
                                    const Icon(Icons.arrow_upward_rounded)),
                              ),
                              Padding(
                                  padding:
                                  const EdgeInsets.all(Constants.padding),
                                  child: FilledButton.tonalIcon(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    label: const Text("Delete All"),
                                    icon: const Icon(Icons.repeat_rounded),
                                  ))
                            ])));
          });
      // If the modal is discarded.
      if (null == updateSingle) {
        return;
      }

      await toDoProvider.deleteFutures(toDo: prevToDo).catchError((e) {
        Flushbar? error;

        error = Flushbars.createError(
          message: e.cause,
          context: context,
          dismissCallback: () => error?.dismiss(),
        );

        error.show(context);
      }, test: (e) => e is FailureToDeleteException);

      if (updateSingle) {
        prevToDo.repeatable = true;
        // Need to sever the connection to future repeating events.
        toDo.repeatID = toDo.hashCode;

        await toDoProvider.nextRepeat(toDo: prevToDo).catchError((e) {
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
    }

    return await toDoProvider.deleteToDo().whenComplete(() {
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

  Widget buildDrainBar({required BuildContext context}) {
    double max = (toDo.taskType == TaskType.small)
        ? Constants.maxTaskWeight.toDouble()
        : Constants.maxWeight.toDouble();
    double offset = toDo.weight.toDouble() / max;
    return Stack(alignment: Alignment.center, children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: Constants.padding),
        child: Container(
          decoration: BoxDecoration(
              border: Border.all(
                  color: Theme
                      .of(context)
                      .colorScheme
                      .outline,
                  width: 3,
                  strokeAlign: BorderSide.strokeAlignCenter),
              shape: BoxShape.rectangle,
              borderRadius: const BorderRadius.all(Radius.circular(10))),
          child: Padding(
            padding: const EdgeInsets.all(Constants.halfPadding),
            child: LinearProgressIndicator(
                color: (offset < 0.8) ? null : Colors.redAccent,
                minHeight: 50,
                value: 1 - offset,
                // Possibly remove
                borderRadius: const BorderRadius.all(Radius.circular(10))),
          ),
        ),
      ),
      Align(
          alignment: Alignment.centerRight,
          child: Container(
              height: 40,
              width: 8,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.all(Radius.circular(2)),
                color: Theme
                    .of(context)
                    .colorScheme
                    .outline,
              ))),
      AutoSizeText("${toDo.weight}",
          minFontSize: Constants.large,
          softWrap: false,
          maxLines: 1,
          overflow: TextOverflow.visible,
          style: Constants.hugeHeaderStyle),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery
        .of(context)
        .size
        .width;
    bool largeScreen = (width >= Constants.largeScreen);
    bool smallScreen = (width <= Constants.smallScreen);
    bool hugeScreen = (width >= Constants.hugeScreen);
    bool showTimeTile = (Constants.nullDate != toDo.startDate ||
        Constants.nullDate != toDo.dueDate);

    return (largeScreen)
        ? buildDesktopDialog(
        context: context,
        showTimeTile: showTimeTile,
        smallScreen: smallScreen,
        hugeScreen: hugeScreen)
        : buildMobileDialog(
        context: context,
        showTimeTile: showTimeTile,
        smallScreen: smallScreen);
  }

  Dialog buildDesktopDialog({required BuildContext context,
    bool smallScreen = false,
    bool showTimeTile = false,
    bool hugeScreen = false}) {
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
              children: [
                // Title && Close Button
                Padding(
                  padding:
                  const EdgeInsets.symmetric(horizontal: Constants.padding),
                  child: buildTitleBar(context: context),
                ),
                const PaddedDivider(padding: Constants.padding),
                Expanded(
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: ListView(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: Constants.padding),
                              shrinkWrap: true,
                              controller: subScrollControllerLeft,
                              physics: scrollPhysics,
                              children: [
                                // Title + status
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: (smallScreen)
                                          ? Constants.padding
                                          : Constants.innerPadding),
                                  child:
                                  buildNameTile(smallScreen: smallScreen),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: Constants.padding),
                                  child:
                                  buildWeightTile(smallScreen: smallScreen),
                                ),
                                const PaddedDivider(
                                    padding: Constants.innerPadding),
                                // Subtasks
                                (toDo.taskType != TaskType.small)
                                    ? Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: Constants.innerPadding),
                                  child: buildSubTasksTile(
                                      context: context,
                                      smallScreen: smallScreen),
                                )
                                    : const SizedBox.shrink(),

                                const PaddedDivider(padding: Constants.padding),
                                // My Day
                                buildMyDayTile(),
                                const PaddedDivider(padding: Constants.padding),
                                // Priority
                                const Padding(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: Constants.padding),
                                  child: Row(children: [
                                    Expanded(
                                        child: AutoSizeText("Priority",
                                            style: Constants.headerStyle,
                                            maxLines: 1,
                                            softWrap: true,
                                            textAlign: TextAlign.center,
                                            minFontSize: Constants.medium))
                                  ]),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: Constants.padding),
                                  child: buildPriorityTile(
                                      smallScreen: smallScreen),
                                ),

                                // const Padding(
                                //   padding: EdgeInsets.symmetric(vertical: 8.0),
                                //   child: PaddedDivider(padding: Constants.innerPadding),
                                // )
                              ]),
                        ),
                        Expanded(
                          flex: (hugeScreen) ? 2 : 1,
                          child: ListView(
                              controller: subScrollControllerRight,
                              physics: scrollPhysics,
                              shrinkWrap: true,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: Constants.padding),
                              children: [
                                Padding(
                                  padding:
                                  const EdgeInsets.all(Constants.padding),
                                  child: buildGroupBar(),
                                ),

                                const Padding(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: Constants.padding),
                                  child: PaddedDivider(
                                      padding: Constants.innerPadding),
                                ),

                                // Description
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: Constants.padding),
                                  child: buildDescriptionTile(
                                      smallScreen: smallScreen),
                                ),

                                const PaddedDivider(
                                    padding: Constants.innerPadding),
                                // Expected Duration / RealDuration -> Show status, on click, open a dialog.
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: Constants.padding),
                                  child: buildDurationTile(
                                      context: context,
                                      smallScreen: smallScreen),
                                ),

                                const PaddedDivider(
                                    padding: Constants.innerPadding),
                                // DateTime -> Show status, on click, open a dialog.
                                //startDate
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: Constants.padding),
                                  child: buildDateTile(context: context),
                                ),

                                const PaddedDivider(
                                    padding: Constants.innerPadding),
                                // Time
                                (showTimeTile)
                                    ? Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: Constants.padding),
                                  child: buildTimeTile(),
                                )
                                    : const SizedBox.shrink(),

                                (showTimeTile)
                                    ? const PaddedDivider(
                                    padding: Constants.innerPadding)
                                    : const SizedBox.shrink(),
                                // Repeatable Stuff -> Show status, on click, open a dialog.
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: Constants.padding),
                                  child: buildRepeatableTile(
                                      context: context,
                                      smallScreen: smallScreen),
                                ),
                              ]),
                        )
                      ]),
                ),

                const PaddedDivider(padding: Constants.padding),
                Padding(
                  padding:
                  const EdgeInsets.symmetric(horizontal: Constants.padding),
                  child: buildUpdateDeleteRow(context: context),
                )
              ]),
        ),
      ),
    );
  }

  Dialog buildMobileDialog({required BuildContext context,
    bool smallScreen = false,
    showTimeTile = false}) {
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
              Padding(
                padding:
                const EdgeInsets.symmetric(horizontal: Constants.padding),
                child: buildTitleBar(context: context),
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
                      padding: EdgeInsets.symmetric(
                          horizontal: (smallScreen)
                              ? Constants.padding
                              : Constants.innerPadding),
                      child: buildNameTile(smallScreen: smallScreen),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: Constants.padding),
                      child: buildWeightTile(smallScreen: smallScreen),
                    ),
                    const PaddedDivider(padding: Constants.innerPadding),

                    // Subtasks
                    (toDo.taskType != TaskType.small)
                        ? Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: Constants.innerPadding),
                      child: buildSubTasksTile(
                          context: context, smallScreen: smallScreen),
                    )
                        : const SizedBox.shrink(),

                    const PaddedDivider(padding: Constants.padding),
                    // My Day
                    buildMyDayTile(),
                    const PaddedDivider(padding: Constants.padding),
                    // Priority
                    const Padding(
                      padding:
                      EdgeInsets.symmetric(horizontal: Constants.padding),
                      child: Row(children: [
                        Expanded(
                            child: AutoSizeText("Priority",
                                style: Constants.headerStyle,
                                maxLines: 1,
                                softWrap: true,
                                textAlign: TextAlign.center,
                                minFontSize: Constants.medium))
                      ]),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: Constants.padding),
                      child: buildPriorityTile(smallScreen: smallScreen),
                    ),

                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: PaddedDivider(padding: Constants.innerPadding),
                    ),

                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: Constants.padding),
                      child: buildGroupBar(),
                    ),

                    const Padding(
                      padding:
                      EdgeInsets.symmetric(horizontal: Constants.padding),
                      child: PaddedDivider(padding: Constants.innerPadding),
                    ),

                    // Description
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: Constants.padding),
                      child: buildDescriptionTile(smallScreen: smallScreen),
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
                    // DateTime -> Show status, on click, open a dialog.
                    //startDate
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: Constants.padding),
                      child: buildDateTile(context: context),
                    ),

                    const PaddedDivider(padding: Constants.innerPadding),
                    // Time
                    (showTimeTile)
                        ? Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: Constants.padding),
                      child: buildTimeTile(),
                    )
                        : const SizedBox.shrink(),

                    (showTimeTile)
                        ? const PaddedDivider(padding: Constants.innerPadding)
                        : const SizedBox.shrink(),
                    // Repeatable Stuff -> Show status, on click, open a dialog.
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: Constants.padding),
                      child: buildRepeatableTile(
                          context: context, smallScreen: smallScreen),
                    ),
                  ],
                ),
              ),

              const PaddedDivider(padding: Constants.padding),
              Padding(
                padding:
                const EdgeInsets.symmetric(horizontal: Constants.padding),
                child: buildUpdateDeleteRow(context: context),
              )
            ]),
      ),
    );
  }

  Widget buildTitleBar({required BuildContext context}) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      const Flexible(
        child: AutoSizeText(
          "Edit Task",
          overflow: TextOverflow.visible,
          style: Constants.headerStyle,
          minFontSize: Constants.medium,
          softWrap: true,
          maxLines: 1,
        ),
      ),
      (toDo.expectedDuration > 0)
          ? Flexible(
        flex: 2,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Tooltip(
                message: "Expected",
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: Constants.padding),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
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
                            Duration(seconds: toDo.expectedDuration)
                                .toString()
                                .split(".")
                                .first,
                            minFontSize: Constants.medium,
                            overflow: TextOverflow.visible,
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
                message: "Projected",
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: Constants.padding),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Flexible(
                        child: FittedBox(
                          fit: BoxFit.fill,
                          child: Icon(
                            Icons.timer_rounded,
                          ),
                        ),
                      ),
                      Flexible(
                        child: AutoSizeText(
                            Duration(seconds: toDo.realDuration)
                                .toString()
                                .split(".")
                                .first,
                            minFontSize: Constants.medium,
                            overflow: TextOverflow.visible,
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
    ]);
  }

  Card buildSubTasksTile(
      {required BuildContext context, bool smallScreen = false}) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      color: Colors.transparent,
      shape: RoundedRectangleBorder(
          side: BorderSide(
              width: 2,
              color: Theme
                  .of(context)
                  .colorScheme
                  .outlineVariant,
              strokeAlign: BorderSide.strokeAlignInside),
          borderRadius: const BorderRadius.all(
              Radius.circular(Constants.roundedCorners))),
      child: ExpansionTile(
        initiallyExpanded: expanded,
        onExpansionChanged: (value) => setState(() => expanded = value),
        title: const AutoSizeText("Steps",
            maxLines: 1,
            overflow: TextOverflow.visible,
            softWrap: false,
            minFontSize: Constants.small),
        subtitle: AutoSizeText(
            "${min(shownTasks, Constants.numTasks[toDo.taskType]!)}/${Constants
                .numTasks[toDo.taskType]!} Steps",
            maxLines: 1,
            overflow: TextOverflow.visible,
            softWrap: false,
            minFontSize: Constants.small),
        collapsedShape: const RoundedRectangleBorder(
            borderRadius:
            BorderRadius.all(Radius.circular(Constants.roundedCorners))),
        shape: const RoundedRectangleBorder(
            borderRadius:
            BorderRadius.all(Radius.circular(Constants.roundedCorners))),
        children: [
          buildReorderableSubTasks(
              smallScreen: smallScreen, physics: scrollPhysics),
          (shownTasks < Constants.numTasks[toDo.taskType]!)
              ? ListTile(
              leading: const Icon(Icons.add_rounded),
              title: const AutoSizeText("Add a step",
                  maxLines: 1,
                  overflow: TextOverflow.visible,
                  softWrap: false,
                  minFontSize: Constants.small),
              onTap: () =>
                  setState(() {
                    shownTasks++;
                    shownTasks = min(shownTasks, Constants.maxNumTasks);
                  }))
              : const SizedBox.shrink(),
        ],
      ),
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
                                    Icons.edit_note_rounded,
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
        icon: const Icon(Icons.close_rounded),
        selectedIcon: const Icon(Icons.close_rounded));
  }

  Row buildNameTile({bool smallScreen = false}) {
    return Row(
      children: [
        Transform.scale(
          scale: (smallScreen)
              ? Constants.largeCheckboxMinScale
              : Constants.largeCheckboxScale,
          child: Checkbox(
              splashRadius: 15,
              value: toDo.completed,
              onChanged: (bool? value) =>
                  setState(() {
                    checkClose = true;
                    toDo.completed = value!;
                  }),
              shape: const CircleBorder()),
        ),
        Expanded(
            child: Padding(
              padding: EdgeInsets.all(
                  (smallScreen) ? Constants.halfPadding : Constants.padding),
              child: buildTaskName(smallScreen: smallScreen),
            )),
      ],
    );
  }

  AutoSizeTextField buildTaskName({bool smallScreen = false}) {
    return AutoSizeTextField(
      maxLines: 1,
      minFontSize: Constants.huge,
      decoration: InputDecoration(
        isDense: smallScreen,
        suffixIcon: (toDo.name != "")
            ? IconButton(
            icon: const Icon(Icons.clear_rounded),
            onPressed: () {
              nameEditingController.clear();
              setState(() {
                checkClose = true;
                toDo.name = "";
              });
            })
            : null,
        contentPadding: const EdgeInsets.all(Constants.innerPadding),
        enabledBorder: OutlineInputBorder(
            borderRadius: const BorderRadius.all(
                Radius.circular(Constants.roundedCorners)),
            borderSide: BorderSide(
              width: 2,
              color: Theme
                  .of(context)
                  .colorScheme
                  .outlineVariant,
              strokeAlign: BorderSide.strokeAlignOutside,
            )),
        border: const OutlineInputBorder(
            borderRadius:
            BorderRadius.all(Radius.circular(Constants.roundedCorners)),
            borderSide: BorderSide(
              strokeAlign: BorderSide.strokeAlignOutside,
            )),
        hintText: "Task name",
        errorText: nameErrorText,
      ),
      controller: nameEditingController,
    );
  }

  Column buildWeightTile({bool smallScreen = false}) {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: Constants.padding),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Flexible(
              child: AutoSizeText("Energy Drain",
                  minFontSize: Constants.medium,
                  maxLines: 1,
                  softWrap: true,
                  style: Constants.hugeHeaderStyle),
            ),
            Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(Constants.innerPadding),
                  child: buildDrainBar(context: context),
                )),
          ],
        ),
      ),
      (toDo.taskType == TaskType.small)
          ? Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          const Icon(Icons.battery_full_rounded),
          Expanded(
            child: Slider(
              value: toDo.weight.toDouble(),
              max: Constants.maxTaskWeight.toDouble(),
              label: (toDo.weight > (Constants.maxTaskWeight / 2).floor())
                  ? " ${toDo.weight} ${Constants.lowBattery}"
                  : " ${toDo.weight} ${Constants.fullBattery}",
              divisions: Constants.maxTaskWeight,
              onChanged: (value) =>
                  setState(() {
                    checkClose = true;
                    toDo.weight = value.toInt();
                    toDo.realDuration = toDoProvider.calculateRealDuration(
                        weight: toDo.weight, duration: toDo.expectedDuration);
                  }),
            ),
          ),
          const Icon(Icons.battery_1_bar_rounded),
        ],
      )
          : const SizedBox.shrink(),
    ]);
  }

  ReorderableListView buildReorderableSubTasks({bool smallScreen = false,
    ScrollPhysics physics = const BouncingScrollPhysics()}) {
    return ReorderableListView.builder(
      buildDefaultDragHandles: false,
      physics: physics,
      shrinkWrap: true,
      itemCount: min(cacheSubTasks.length, shownTasks),
      onReorder: (int oldIndex, int newIndex) {
        setState(() {
          checkClose = true;
          if (oldIndex < newIndex) {
            newIndex--;
          }
          SubTask st = cacheSubTasks.removeAt(oldIndex);
          cacheSubTasks.insert(newIndex, st);
          TextEditingController ct =
          subTaskEditingController.removeAt(oldIndex);
          subTaskEditingController.insert(newIndex, ct);
        });
      },
      itemBuilder: (BuildContext context, int index) {
        return CheckboxListTile(
            contentPadding:
            const EdgeInsets.symmetric(horizontal: Constants.innerPadding),
            key: ValueKey(index),
            checkboxShape: const CircleBorder(),
            controlAffinity: ListTileControlAffinity.leading,
            shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(
                    Radius.circular(Constants.roundedCorners))),
            title: Row(
              children: [
                IconButton(
                  icon: Constants.batteryIcons[cacheSubTasks[index].weight]!,
                  selectedIcon: Constants
                      .selectedBatteryIcons[cacheSubTasks[index].weight]!,
                  onPressed: () {
                    showModalBottomSheet<void>(
                        showDragHandle: true,
                        context: context,
                        builder: (BuildContext context) {
                          return StatefulBuilder(
                            builder: (BuildContext context,
                                void Function(void Function()) setState) =>
                                Center(
                                    heightFactor: 1,
                                    child: Column(
                                        mainAxisAlignment:
                                        MainAxisAlignment.center,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Text("Step Drain",
                                              style: Constants.headerStyle),
                                          Padding(
                                              padding: const EdgeInsets.all(
                                                  Constants.padding),
                                              child: Row(
                                                mainAxisAlignment:
                                                MainAxisAlignment
                                                    .spaceEvenly,
                                                children: [
                                                  const Icon(Icons
                                                      .battery_full_rounded),
                                                  Expanded(
                                                    child: Slider(
                                                      value:
                                                      cacheSubTasks[index]
                                                          .weight
                                                          .toDouble(),
                                                      max: Constants
                                                          .maxTaskWeight
                                                          .toDouble(),
                                                      label: (cacheSubTasks[
                                                      index]
                                                          .weight >
                                                          (Constants
                                                              .maxTaskWeight /
                                                              2)
                                                              .floor())
                                                          ? " ${cacheSubTasks[index]
                                                          .weight} ${Constants
                                                          .lowBattery}"
                                                          : " ${cacheSubTasks[index]
                                                          .weight} ${Constants
                                                          .fullBattery}",
                                                      divisions: Constants
                                                          .maxTaskWeight,
                                                      onChanged: (value) =>
                                                          setState(() {
                                                            checkClose = true;
                                                            cacheSubTasks[index]
                                                                .weight =
                                                                value.toInt();
                                                          }),
                                                    ),
                                                  ),
                                                  const Icon(Icons
                                                      .battery_1_bar_rounded),
                                                ],
                                              )),
                                        ])),
                          );
                        }).whenComplete(() =>
                        setState(() {
                          checkClose = true;
                          toDo.weight = toDoProvider.calculateWeight(
                              subTasks: cacheSubTasks);
                          toDo.realDuration =
                              toDoProvider.calculateRealDuration(
                                  weight: toDo.weight,
                                  duration: toDo.expectedDuration);
                        }));
                  },
                ),
                Expanded(
                  child: AutoSizeTextField(
                      controller: subTaskEditingController[index],
                      maxLines: 1,
                      minFontSize: Constants.small,
                      decoration: const InputDecoration.collapsed(
                        hintText: "Step name",
                      ),
                      onChanged: (value) {
                        cacheSubTasks[index].name = value;
                        subTaskEditingController[index].value =
                            subTaskEditingController[index].value.copyWith(
                              text: value,
                              selection: TextSelection.collapsed(
                                  offset: value.length),
                            );
                      }),
                ),
              ],
            ),
            value: cacheSubTasks[index].completed,
            onChanged: (bool? value) =>
                setState(() {
                  checkClose = true;
                  cacheSubTasks[index].completed = value!;
                }),

            // Delete Subtask
            secondary: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: Constants.innerPadding),
                  child: IconButton(
                      icon: const Icon(Icons.delete_rounded),
                      onPressed: () =>
                          setState(() {
                            checkClose = true;
                            SubTask st = cacheSubTasks.removeAt(index);
                            st = SubTask();
                            cacheSubTasks.add(st);
                            TextEditingController ct =
                            subTaskEditingController.removeAt(index);
                            ct.value = ct.value.copyWith(text: st.name);
                            subTaskEditingController.add(ct);

                            shownTasks--;
                            shownTasks = max(shownTasks, 0);
                            toDo.weight = toDoProvider.calculateWeight(
                                subTasks: cacheSubTasks);
                          })),
                ),
                ReorderableDragStartListener(
                    index: index, child: const Icon(Icons.drag_handle_rounded))
              ],
            ));
      },
    );
  }

  ListTile buildMyDayTile() {
    return ListTile(
        title: AutoSizeText(
          (toDo.myDay)
              ? "Added to my Day"
              : (userProvider.myDayTotal + toDo.weight <=
              (userProvider.curUser?.bandwidth ??
                  Constants.maxBandwidth))
              ? "Add to My Day?"
              : "Don't overload yourself, you deserve a rest",
          overflow: TextOverflow.visible,
          softWrap: true,
          minFontSize: Constants.medium,
          maxLines: 2,
        ),
        leading: (toDo.myDay)
            ? IconButton.filledTonal(
            icon: const Icon(Icons.wb_sunny_rounded),
            onPressed: () =>
                setState(() {
                  checkClose = true;
                  toDo.myDay = !toDo.myDay;
                }))
            : (userProvider.myDayTotal + toDo.weight <=
            (userProvider.curUser?.bandwidth ?? Constants.maxBandwidth)
            ? IconButton.outlined(
            icon: const Icon(Icons.wb_sunny_outlined),
            onPressed: () =>
                setState(() {
                  checkClose = true;
                  toDo.myDay = !toDo.myDay;
                }))
            : const Icon(Icons.block_rounded)));
  }

  SegmentedButton<Priority> buildPriorityTile({bool smallScreen = false}) {
    return SegmentedButton<Priority>(
        selectedIcon: const Icon(Icons.flag_circle_rounded),
        style: ButtonStyle(
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.adaptivePlatformDensity,
          side: MaterialStatePropertyAll<BorderSide>(BorderSide(
            width: 2,
            color: Theme
                .of(context)
                .colorScheme
                .outlineVariant,
          )),
        ),
        segments: Priority.values
            .map((Priority type) =>
            ButtonSegment<Priority>(
                icon: Constants.priorityIcon[type],
                value: type,
                label: Text(
                  "${toBeginningOfSentenceCase(type.name)}",
                  softWrap: false,
                  overflow: TextOverflow.fade,
                )))
            .toList(growable: false),
        selected: <Priority>{toDo.priority},
        onSelectionChanged: (Set<Priority> newSelection) =>
            setState(() {
              checkClose = true;
              toDo.priority = newSelection.first;
            }));
  }

  SearchAnchor buildGroupBar() {
    return SearchAnchor.bar(
        isFullScreen: false,
        barSide: MaterialStatePropertyAll(BorderSide(
            width: 2,
            strokeAlign: BorderSide.strokeAlignOutside,
            color: Theme
                .of(context)
                .colorScheme
                .outlineVariant)),
        barBackgroundColor: const MaterialStatePropertyAll(Colors.transparent),
        barElevation: const MaterialStatePropertyAll(0),
        viewConstraints: const BoxConstraints(
            maxHeight: Constants.maxSearchHeightBeforeScroll),
        barHintText: "Search Groups",
        searchController: groupEditingController,
        suggestionsBuilder: (context, SearchController controller) {
          if (controller.text.isEmpty) {
            if (searchHistory.isNotEmpty) {
              return searchHistory
                  .map((MapEntry<String, int> groupData) =>
                  ListTile(
                    leading: const Icon(Icons.history_rounded),
                    title: AutoSizeText(
                      groupData.key,
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.visible,
                    ),
                    onTap: () =>
                        handleHistorySelection(
                            groupData: groupData, controller: controller),
                  ))
                  .toList();
            }
            final searchFuture = groupProvider.mostRecent(limit: 5);
            return [
              buildGroupList(searchFuture: searchFuture, controller: controller)
            ];
          }
          // Search query iterable.
          final searchFuture =
          groupProvider.searchGroups(searchString: controller.text);
          return [
            buildGroupList(searchFuture: searchFuture, controller: controller)
          ];
        });
  }

  FutureBuilder<List<Group>> buildGroupList(
      {required Future<List<Group>> searchFuture,
        required SearchController controller}) {
    return FutureBuilder(
        future: searchFuture,
        builder: (BuildContext context, AsyncSnapshot<List<Group>> snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            final List<Group>? groups = snapshot.data;
            if (null != groups) {
              return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: groups.length,
                  itemBuilder: (BuildContext context, int index) {
                    return ListTile(
                        title: AutoSizeText(groups[index].name),
                        onTap: () =>
                            handleGroupSelection(
                                group: groups[index], controller: controller));
                  });
            }
            // This is what to render if no data.
            return const SizedBox.shrink();
          }
          return const Padding(
            padding: EdgeInsets.all(Constants.padding),
            child: CircularProgressIndicator(),
          );
        });
  }

  AutoSizeTextField buildDescriptionTile({bool smallScreen = false}) {
    return AutoSizeTextField(
        controller: descriptionEditingController,
        maxLines: Constants.descripMaxLinesBeforeScroll,
        minLines:
        Constants.descripMinLines,
        minFontSize: Constants.medium,
        decoration: InputDecoration(
          isDense: smallScreen,
          contentPadding: const EdgeInsets.all(Constants.innerPadding),
          hintText: "Description",
          enabledBorder: OutlineInputBorder(
              borderRadius: const BorderRadius.all(
                  Radius.circular(Constants.roundedCorners)),
              borderSide: BorderSide(
                width: 2,
                color: Theme
                    .of(context)
                    .colorScheme
                    .outlineVariant,
                strokeAlign: BorderSide.strokeAlignOutside,
              )),
          border: const OutlineInputBorder(
              borderRadius:
              BorderRadius.all(Radius.circular(Constants.roundedCorners)),
              borderSide: BorderSide(
                strokeAlign: BorderSide.strokeAlignOutside,
              )),
        ));
  }

  ListTile buildDurationTile(
      {required BuildContext context, bool smallScreen = false}) {
    return ListTile(
      leading: const Icon(Icons.timer_outlined),
      shape: const RoundedRectangleBorder(
          borderRadius:
          BorderRadius.all(Radius.circular(Constants.roundedCorners))),
      title: (toDo.expectedDuration > 0)
          ? Row(
        children: [
          Flexible(
            child: Tooltip(
              message: "Expected",
              child: AutoSizeText(
                  Duration(seconds: toDo.expectedDuration)
                      .toString()
                      .split(".")
                      .first,
                  overflow: TextOverflow.visible,
                  minFontSize: Constants.large,
                  maxLines: 1,
                  softWrap: false),
            ),
          ),
          const Padding(
            padding:
            EdgeInsets.symmetric(horizontal: Constants.innerPadding),
            child: Icon(
              Icons.timer_rounded,
            ),
          ),
          Flexible(
            child: Tooltip(
              message: "Projected",
              child: AutoSizeText(
                  Duration(seconds: toDo.realDuration)
                      .toString()
                      .split(".")
                      .first,
                  overflow: TextOverflow.visible,
                  minFontSize: Constants.large,
                  maxLines: 1,
                  softWrap: false),
            ),
          ),
        ],
      )
          : const AutoSizeText("Expected Task Duration: ",
          overflow: TextOverflow.visible,
          minFontSize: Constants.small,
          maxLines: 2,
          softWrap: true),
      trailing: (toDo.expectedDuration > 0)
          ? IconButton(
          icon: const Icon(Icons.clear_rounded),
          onPressed: () =>
              setState(() {
                checkClose = true;
                toDo.expectedDuration = 0;
                toDo.realDuration = 0;
              }))
          : null,
      onTap: () =>
          showDialog<int>(
              context: context,
              builder: (BuildContext context) {
                int time = toDo.expectedDuration;
                int hours = time ~/ 3600;
                time %= 3600;
                int minutes = time ~/ 60;
                time %= 60;
                int seconds = time;
                return StatefulBuilder(
                  builder: (BuildContext context,
                      void Function(void Function()) setState) {
                    return Dialog(
                        child: Padding(
                            padding: const EdgeInsets.all(
                                Constants.innerPadding),
                            child: Column(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Row(
                                      mainAxisAlignment: MainAxisAlignment
                                          .start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Expanded(
                                          child: AutoSizeText(
                                            "Expected Duration",
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
                                      mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                      mainAxisSize: MainAxisSize.max,
                                      children: [
                                        Expanded(
                                            flex: 2,
                                            child: AutoSizeText(
                                              "Hours | Minutes | Seconds ",
                                              style: Constants.largeHeaderStyle,
                                              softWrap: true,
                                              overflow: TextOverflow.visible,
                                              maxLines: 1,
                                              minFontSize: Constants.large,
                                            )),
                                        Flexible(
                                          child: FittedBox(
                                              fit: BoxFit.fill,
                                              child: Icon(Icons.timer_outlined,
                                                  size: Constants.medIconSize)),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                    children: [
                                      Expanded(
                                        child: NumberPicker(
                                          textStyle:
                                          Constants.numberPickerSecondary(
                                              context: context),
                                          selectedTextStyle:
                                          Constants.numberPickerPrimary(
                                              context: context),
                                          minValue: 0,
                                          maxValue: 100,
                                          value: hours,
                                          haptics: true,
                                          onChanged: (value) {
                                            SemanticsService.announce(
                                                "$value, hours",
                                                Directionality.of(context));
                                            setState(() => hours = value);
                                          },
                                        ),
                                      ),
                                      const Padding(
                                          padding: EdgeInsets.symmetric(
                                              horizontal: Constants.padding),
                                          child: Text(":",
                                              style: Constants.timeColon)),
                                      Expanded(
                                        child: NumberPicker(
                                          textStyle:
                                          Constants.numberPickerSecondary(
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
                                          child: Text(":",
                                              style: Constants.timeColon)),
                                      Expanded(
                                        child: NumberPicker(
                                          textStyle:
                                          Constants.numberPickerSecondary(
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
                                                const Icon(Icons.close_rounded),
                                                onPressed: () =>
                                                    Navigator.pop(context, 0),
                                                label: const AutoSizeText(
                                                    "Cancel",
                                                    softWrap: false,
                                                    overflow: TextOverflow
                                                        .visible,
                                                    maxLines: 1,
                                                    minFontSize: Constants
                                                        .small)),
                                          ),
                                        ),
                                        Expanded(
                                          child: Padding(
                                            padding: const EdgeInsets.only(
                                                left: Constants.padding),
                                            child: FilledButton.icon(
                                              icon: const Icon(
                                                  Icons.done_rounded),
                                              onPressed: () {
                                                Navigator.pop(
                                                    context,
                                                    (hours * 3600) +
                                                        (minutes * 60) +
                                                        seconds);
                                              },
                                              label: const AutoSizeText("Done",
                                                  softWrap: false,
                                                  overflow: TextOverflow
                                                      .visible,
                                                  maxLines: 1,
                                                  minFontSize: Constants.small),
                                            ),
                                          ),
                                        )
                                      ])
                                ])));
                  },
                );
              }).then((value) {
            setState(() {
              checkClose = true;
              toDo.expectedDuration = value ?? toDo.expectedDuration;
              toDo.realDuration = toDoProvider.calculateRealDuration(
                  weight: toDo.weight, duration: toDo.expectedDuration);
            });
          }),
    );
  }

  ListTile buildDateTile({required BuildContext context}) {
    return ListTile(
      leading: const Icon(Icons.today_rounded),
      shape: const RoundedRectangleBorder(
          borderRadius:
          BorderRadius.all(Radius.circular(Constants.roundedCorners))),
      title: (Constants.nullDate == toDo.startDate &&
          Constants.nullDate == toDo.dueDate)
          ? const AutoSizeText(
        "Add Dates",
        softWrap: true,
        overflow: TextOverflow.visible,
        maxLines: 2,
        minFontSize: Constants.small,
      )
          : Row(
        children: [
          (Constants.nullDate == toDo.startDate)
              ? const Flexible(
            child: AutoSizeText(
              "Start",
              softWrap: true,
              overflow: TextOverflow.visible,
              maxLines: 2,
              minFontSize: Constants.small,
            ),
          )
              : Flexible(
              child: AutoSizeText(
                  Jiffy.parseFromDateTime(toDo.startDate)
                      .toLocal()
                      .format(
                    pattern: "MMM d",
                  ),
                  softWrap: true,
                  overflow: TextOverflow.visible,
                  maxLines: 2,
                  minFontSize: Constants.small)),
          const Padding(
            padding: EdgeInsets.all(Constants.padding),
            child: Text(
              "-",
              softWrap: false,
              overflow: TextOverflow.visible,
              maxLines: 1,
            ),
          ),
          (Constants.nullDate == toDo.dueDate)
              ? const Flexible(
            child: Padding(
              padding: EdgeInsets.only(right: Constants.padding),
              child: Icon(Icons.today_rounded),
            ),
          )
              : const Flexible(
              child: Padding(
                padding: EdgeInsets.only(right: Constants.padding),
                child: Icon(Icons.event_rounded),
              )),
          (Constants.nullDate == toDo.dueDate)
              ? const Flexible(
            child: AutoSizeText(
              "Due",
              softWrap: true,
              overflow: TextOverflow.visible,
              maxLines: 2,
              minFontSize: Constants.small,
            ),
          )
              : Flexible(
            child: AutoSizeText(
                Jiffy.parseFromDateTime(toDo.dueDate)
                    .toLocal()
                    .format(pattern: "MMM d"),
                softWrap: true,
                overflow: TextOverflow.visible,
                maxLines: 2,
                minFontSize: Constants.small),
          )
        ],
      ),
      trailing: (Constants.nullDate != toDo.startDate ||
          Constants.nullDate != toDo.dueDate)
          ? IconButton(
          icon: const Icon(Icons.clear_rounded),
          onPressed: () =>
              setState(() {
                checkClose = true;
                toDo.startDate = Constants.nullDate;
                toDo.dueDate = Constants.nullDate;
              }))
          : null,
      onTap: () {
        showDialog<void>(
            context: context,
            builder: (BuildContext context) {
              DateTime? tmpStart = (Constants.nullDate != toDo.startDate)
                  ? toDo.startDate
                  : null;
              DateTime? tmpDue =
              (Constants.nullDate != toDo.dueDate) ? toDo.dueDate : null;
              DateTime initDate = tmpStart ?? tmpDue ?? DateTime.now();
              bool setStart = false;
              final int numDays =
                  (tmpDue
                      ?.difference(initDate)
                      .inDays ?? 0) + 1;
              List<DateTime?> showDates = List.generate(
                  numDays, (i) => initDate.copyWith(day: initDate.day + i));

              // List ->
              return StatefulBuilder(
                  builder: (BuildContext context,
                      void Function(void Function()) setState) =>
                      Dialog(
                          insetPadding:
                          const EdgeInsets.all(Constants.innerPadding),
                          child: Padding(
                            padding:
                            const EdgeInsets.all(Constants.innerPadding),
                            child: Column(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Row(
                                      mainAxisAlignment:
                                      MainAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Expanded(
                                          child: AutoSizeText(
                                            "Select Dates",
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
                                      mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                      mainAxisSize: MainAxisSize.max,
                                      children: [
                                        Flexible(
                                            child: AutoSizeText(
                                              "Start | Due ",
                                              style: Constants.largeHeaderStyle,
                                              softWrap: true,
                                              overflow: TextOverflow.visible,
                                              maxLines: 1,
                                              minFontSize: Constants.large,
                                            )),
                                        Flexible(
                                          child: FittedBox(
                                              fit: BoxFit.fill,
                                              child: Icon(
                                                  Icons.date_range_rounded,
                                                  size: Constants.medIconSize)),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: Constants.innerPadding),
                                    child: Row(
                                        mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                        mainAxisSize: MainAxisSize.max,
                                        children: [
                                          Expanded(
                                            flex: 10,
                                            child: Container(
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                BorderRadius.circular(
                                                    Constants
                                                        .roundedCorners),
                                                border: Border.all(
                                                    width: 2,
                                                    color: Theme
                                                        .of(context)
                                                        .colorScheme
                                                        .outlineVariant,
                                                    strokeAlign: BorderSide
                                                        .strokeAlignOutside),
                                              ),
                                              child: Row(
                                                  mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                                  mainAxisSize:
                                                  MainAxisSize.max,
                                                  children: [
                                                    Expanded(
                                                      child: TextButton(
                                                          onPressed: () =>
                                                              setState(() {
                                                                checkClose =
                                                                true;
                                                                setStart = true;
                                                                tmpStart =
                                                                    tmpStart ??
                                                                        DateTime
                                                                            .now();
                                                              }),
                                                          child: (null !=
                                                              tmpStart)
                                                              ? AutoSizeText(
                                                            Jiffy
                                                                .parseFromDateTime(
                                                                tmpStart!)
                                                                .toLocal()
                                                                .format(
                                                                pattern:
                                                                "MMM d, yyyy"),
                                                            softWrap:
                                                            false,
                                                            overflow:
                                                            TextOverflow
                                                                .visible,
                                                            maxLines: 1,
                                                            minFontSize:
                                                            Constants
                                                                .small,
                                                          )
                                                              : const AutoSizeText(
                                                              "Start Date",
                                                              softWrap:
                                                              true,
                                                              overflow:
                                                              TextOverflow
                                                                  .visible,
                                                              maxLines: 1,
                                                              minFontSize:
                                                              Constants
                                                                  .small)),
                                                    ),
                                                    (tmpStart != null)
                                                        ? IconButton(
                                                      icon: const Icon(Icons
                                                          .clear_rounded),
                                                      selectedIcon:
                                                      const Icon(Icons
                                                          .clear),
                                                      onPressed: () =>
                                                          setState(() {
                                                            checkClose = true;
                                                            showDates.remove(
                                                                tmpStart);
                                                            tmpStart = null;
                                                          }),
                                                    )
                                                        : const SizedBox
                                                        .shrink(),
                                                  ]),
                                            ),
                                          ),
                                          const Flexible(
                                            flex: 1,
                                            child: Padding(
                                              padding: EdgeInsets.symmetric(
                                                  horizontal:
                                                  Constants.halfPadding),
                                              child: AutoSizeText("|",
                                                  style: Constants
                                                      .largeHeaderStyle,
                                                  softWrap: false,
                                                  overflow:
                                                  TextOverflow.visible,
                                                  maxLines: 1,
                                                  minFontSize: Constants.small),
                                            ),
                                          ),
                                          Expanded(
                                            flex: 10,
                                            child: Container(
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                BorderRadius.circular(
                                                    Constants
                                                        .roundedCorners),
                                                border: Border.all(
                                                    width: 2,
                                                    color: Theme
                                                        .of(context)
                                                        .colorScheme
                                                        .outlineVariant,
                                                    strokeAlign: BorderSide
                                                        .strokeAlignOutside),
                                              ),
                                              child: Row(
                                                  mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                                  mainAxisSize:
                                                  MainAxisSize.max,
                                                  children: [
                                                    Expanded(
                                                      child: TextButton(
                                                          onPressed: () =>
                                                              setState(() {
                                                                checkClose =
                                                                true;
                                                                setStart =
                                                                false;
                                                                tmpDue =
                                                                    tmpDue ??
                                                                        DateTime
                                                                            .now();
                                                              }),
                                                          child: (null !=
                                                              tmpDue)
                                                              ? AutoSizeText(
                                                            Jiffy
                                                                .parseFromDateTime(
                                                                tmpDue!)
                                                                .toLocal()
                                                                .format(
                                                                pattern:
                                                                "MMM d, yyyy"),
                                                            softWrap:
                                                            false,
                                                            overflow:
                                                            TextOverflow
                                                                .visible,
                                                            maxLines: 1,
                                                            minFontSize:
                                                            Constants
                                                                .small,
                                                          )
                                                              : const AutoSizeText(
                                                              "Due Date",
                                                              softWrap:
                                                              true,
                                                              overflow:
                                                              TextOverflow
                                                                  .visible,
                                                              maxLines: 1,
                                                              minFontSize:
                                                              Constants
                                                                  .small)),
                                                    ),
                                                    (null != tmpDue)
                                                        ? IconButton(
                                                      icon: const Icon(Icons
                                                          .clear_rounded),
                                                      selectedIcon:
                                                      const Icon(Icons
                                                          .clear),
                                                      onPressed: () =>
                                                          setState(() {
                                                            checkClose = true;
                                                            showDates.remove(
                                                                tmpDue);
                                                            tmpDue = null;
                                                          }),
                                                    )
                                                        : const SizedBox
                                                        .shrink()
                                                  ]),
                                            ),
                                          ),
                                        ]),
                                  ),

                                  // Calendar view.
                                  Column(
                                      mainAxisAlignment:
                                      MainAxisAlignment.center,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        CalendarDatePicker2(
                                            config: CalendarDatePicker2Config(
                                              calendarType:
                                              CalendarDatePicker2Type.range,
                                              firstDate: DateTime(1970),
                                              lastDate: DateTime(3000),
                                            ),
                                            value: showDates,
                                            onValueChanged: (dates) {
                                              setState(() {
                                                checkClose = true;
                                                if (dates.length > 1) {
                                                  tmpStart = dates.first;
                                                  tmpDue = dates.last;
                                                } else {
                                                  (setStart)
                                                      ? tmpStart = dates.first
                                                      : tmpDue = dates.first;
                                                }
                                                showDates = dates;
                                              });
                                            }),
                                      ]),

                                  Row(
                                      mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Expanded(
                                          child: Padding(
                                            padding: const EdgeInsets.only(
                                                right: Constants.padding),
                                            child: FilledButton.tonalIcon(
                                                icon: const Icon(
                                                    Icons.close_rounded),
                                                onPressed: () =>
                                                    Navigator.pop(context),
                                                label: const AutoSizeText(
                                                    "Cancel",
                                                    softWrap: false,
                                                    overflow:
                                                    TextOverflow.visible,
                                                    maxLines: 1,
                                                    minFontSize:
                                                    Constants.small)),
                                          ),
                                        ),
                                        Expanded(
                                          child: Padding(
                                            padding: const EdgeInsets.only(
                                                left: Constants.padding),
                                            child: FilledButton.icon(
                                              icon: const Icon(
                                                  Icons.done_rounded),
                                              onPressed: () {
                                                setState(() {
                                                  checkClose = true;
                                                  toDo.startDate = tmpStart ??
                                                      Constants.nullDate;
                                                  toDo.dueDate = tmpDue ??
                                                      Constants.nullDate;

                                                  if (Constants.nullDate !=
                                                      toDo.startDate &&
                                                      Constants.nullDate !=
                                                          toDo.dueDate &&
                                                      toDo.startDate.isAfter(
                                                          toDo.dueDate)) {
                                                    toDo.startDate =
                                                        toDo.dueDate;
                                                  }
                                                });
                                                Navigator.pop(context);
                                              },
                                              label: const AutoSizeText("Done",
                                                  softWrap: false,
                                                  overflow:
                                                  TextOverflow.visible,
                                                  maxLines: 1,
                                                  minFontSize: Constants.small),
                                            ),
                                          ),
                                        )
                                      ]),
                                ]),
                          )));
              // This is to update the main context after updating.
            }).then((_) => setState(() {}));
      },
    );
  }

  ListTile buildTimeTile() {
    TimeOfDay? startTime = TimeOfDay.fromDateTime(toDo.startDate);
    TimeOfDay? dueTime = TimeOfDay.fromDateTime(toDo.dueDate);
    return ListTile(
        leading: const Icon(Icons.schedule_rounded),
        shape: const RoundedRectangleBorder(
            borderRadius:
            BorderRadius.all(Radius.circular(Constants.roundedCorners))),
        title: (Constants.midnight == startTime &&
            Constants.midnight == dueTime)
            ? const AutoSizeText(
          "Add Times",
          overflow: TextOverflow.visible,
          minFontSize: Constants.small,
          maxLines: 2,
          softWrap: true,
        )
            : Row(children: [
          (Constants.midnight == startTime)
              ? const Flexible(
              child: AutoSizeText(
                "Start",
                softWrap: false,
                overflow: TextOverflow.visible,
                maxLines: 1,
                minFontSize: Constants.small,
              ))
              : Flexible(
              child: AutoSizeText(
                startTime.format(context).toString(),
                softWrap: false,
                overflow: TextOverflow.visible,
                maxLines: 1,
                minFontSize: Constants.large,
              )),
          (Constants.midnight == dueTime)
              ? const Flexible(
            child: Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: Constants.padding),
              child: FittedBox(
                  fit: BoxFit.fill,
                  child: Icon(Icons.history_toggle_off_rounded)),
            ),
          )
              : const Flexible(
              child: Padding(
                padding:
                EdgeInsets.symmetric(horizontal: Constants.padding),
                child: FittedBox(
                    fit: BoxFit.fill,
                    child: Icon(Icons.schedule_rounded)),
              )),
          (Constants.midnight == dueTime)
              ? const Flexible(
            child: AutoSizeText(
              "Due",
              softWrap: false,
              overflow: TextOverflow.visible,
              maxLines: 1,
              minFontSize: Constants.small,
            ),
          )
              : Flexible(
            child: AutoSizeText(
              dueTime.format(context).toString(),
              softWrap: false,
              overflow: TextOverflow.visible,
              maxLines: 1,
              minFontSize: Constants.small,
            ),
          ),
        ]),
        onTap: () {
          showDialog<void>(
              context: context,
              builder: (BuildContext context) {
                return StatefulBuilder(
                    builder: (BuildContext context,
                        void Function(void Function()) setState) =>
                        Dialog(
                            child: Padding(
                              padding: const EdgeInsets.all(
                                  Constants.innerPadding),
                              child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Row(
                                        mainAxisAlignment: MainAxisAlignment
                                            .start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Expanded(
                                            child: AutoSizeText(
                                              "Select Times",
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
                                        mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                        mainAxisSize: MainAxisSize.max,
                                        children: [
                                          Flexible(
                                              child: AutoSizeText(
                                                "Start | Due ",
                                                style: Constants
                                                    .largeHeaderStyle,
                                                softWrap: true,
                                                overflow: TextOverflow.visible,
                                                maxLines: 1,
                                                minFontSize: Constants.large,
                                              )),
                                          Flexible(
                                            child: FittedBox(
                                                fit: BoxFit.fill,
                                                child: Icon(
                                                    Icons.schedule_rounded,
                                                    size: Constants
                                                        .medIconSize)),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: Constants.innerPadding),
                                      child: Row(
                                          mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                          mainAxisSize: MainAxisSize.max,
                                          children: [
                                            Expanded(
                                              flex: 10,
                                              child: OutlinedButton(
                                                  style: OutlinedButton
                                                      .styleFrom(
                                                    side: BorderSide(
                                                      width: 2,
                                                      color: Theme
                                                          .of(context)
                                                          .colorScheme
                                                          .outlineVariant,
                                                    ),
                                                    shape: const RoundedRectangleBorder(
                                                        borderRadius: BorderRadius
                                                            .all(
                                                            Radius.circular(
                                                                Constants
                                                                    .roundedCorners))),
                                                  ),
                                                  onPressed: () async {
                                                    final TimeOfDay? picked =
                                                    await showTimePicker(
                                                        context: context,
                                                        initialTime:
                                                        startTime ??
                                                            Constants
                                                                .midnight);
                                                    if (null != picked) {
                                                      setState(
                                                              () =>
                                                          startTime = picked);
                                                    }
                                                  },
                                                  child: (Constants.midnight !=
                                                      startTime)
                                                      ? AutoSizeText(
                                                    startTime!
                                                        .format(context)
                                                        .toString(),
                                                    softWrap: false,
                                                    overflow:
                                                    TextOverflow.visible,
                                                    maxLines: 1,
                                                    minFontSize:
                                                    Constants.small,
                                                  )
                                                      : const AutoSizeText(
                                                      "Start Time",
                                                      softWrap: true,
                                                      overflow:
                                                      TextOverflow.visible,
                                                      maxLines: 1,
                                                      minFontSize:
                                                      Constants.small)),
                                            ),
                                            const Padding(
                                              padding: EdgeInsets.symmetric(
                                                  horizontal:
                                                  Constants.halfPadding),
                                              child: Text("|",
                                                  style: Constants.timeColon),
                                            ),
                                            Expanded(
                                              flex: 10,
                                              child: OutlinedButton(
                                                  style: OutlinedButton
                                                      .styleFrom(
                                                    side: BorderSide(
                                                      width: 2,
                                                      color: Theme
                                                          .of(context)
                                                          .colorScheme
                                                          .outlineVariant,
                                                    ),
                                                    shape: const RoundedRectangleBorder(
                                                        borderRadius: BorderRadius
                                                            .all(
                                                            Radius.circular(
                                                                Constants
                                                                    .roundedCorners))),
                                                  ),
                                                  onPressed: () async {
                                                    final TimeOfDay? picked =
                                                    await showTimePicker(
                                                        context: context,
                                                        initialTime: dueTime ??
                                                            Constants.midnight);
                                                    if (null != picked) {
                                                      setState(
                                                              () =>
                                                          dueTime = picked);
                                                    }
                                                  },
                                                  child: (Constants.midnight !=
                                                      dueTime)
                                                      ? AutoSizeText(
                                                    dueTime!
                                                        .format(context)
                                                        .toString(),
                                                    softWrap: false,
                                                    overflow:
                                                    TextOverflow.visible,
                                                    maxLines: 1,
                                                    minFontSize:
                                                    Constants.small,
                                                  )
                                                      : const AutoSizeText(
                                                      "Due Time",
                                                      softWrap: true,
                                                      overflow:
                                                      TextOverflow.visible,
                                                      maxLines: 1,
                                                      minFontSize:
                                                      Constants.small)),
                                            ),
                                          ]),
                                    ),
                                    Row(
                                        mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Expanded(
                                            child: Padding(
                                              padding: const EdgeInsets.only(
                                                  right: Constants.padding),
                                              child: FilledButton.tonalIcon(
                                                  icon: const Icon(
                                                      Icons.close_rounded),
                                                  onPressed: () =>
                                                      Navigator.pop(context),
                                                  label: const AutoSizeText(
                                                      "Cancel",
                                                      softWrap: false,
                                                      overflow:
                                                      TextOverflow.visible,
                                                      maxLines: 1,
                                                      minFontSize:
                                                      Constants.small)),
                                            ),
                                          ),
                                          Expanded(
                                            child: Padding(
                                              padding: const EdgeInsets.only(
                                                  left: Constants.padding),
                                              child: FilledButton.icon(
                                                icon:
                                                const Icon(Icons.done_rounded),
                                                onPressed: () {
                                                  setState(() {
                                                    startTime = startTime ??
                                                        Constants.midnight;
                                                    dueTime = dueTime ??
                                                        Constants.midnight;
                                                    toDo.startDate =
                                                        toDo.startDate
                                                            .copyWith(
                                                            hour: startTime!
                                                                .hour,
                                                            minute:
                                                            startTime!.minute);
                                                    toDo.dueDate = toDo.dueDate
                                                        .copyWith(
                                                        hour: dueTime!.hour,
                                                        minute:
                                                        dueTime!.minute);
                                                  });
                                                  Navigator.pop(context);
                                                },
                                                label: const AutoSizeText(
                                                    "Done",
                                                    softWrap: false,
                                                    overflow: TextOverflow
                                                        .visible,
                                                    maxLines: 1,
                                                    minFontSize: Constants
                                                        .small),
                                              ),
                                            ),
                                          )
                                        ]),
                                  ]),
                            )));
              }).then((_) => setState(() {}));
        },
        trailing:
        (Constants.midnight != startTime || Constants.midnight != dueTime)
            ? IconButton(
          icon: const Icon(Icons.clear_rounded),
          onPressed: () =>
              setState(() {
                checkClose = true;

                toDo.startDate = toDo.startDate.copyWith(
                    hour: Constants.midnight.hour,
                    minute: Constants.midnight.minute);
                toDo.dueDate = toDo.dueDate.copyWith(
                    hour: Constants.midnight.hour,
                    minute: Constants.midnight.minute);
              }),
        )
            : null);
  }

  ListTile buildRepeatableTile(
      {required BuildContext context, bool smallScreen = false}) {
    return ListTile(
        leading: const Icon(Icons.event_repeat_rounded),
        shape: const RoundedRectangleBorder(
            borderRadius:
            BorderRadius.all(Radius.circular(Constants.roundedCorners))),
        title: (toDo.frequency == Frequency.once)
            ? const AutoSizeText("Set Recurring?",
            overflow: TextOverflow.visible,
            minFontSize: Constants.small,
            maxLines: 2,
            softWrap: true)
            : AutoSizeText(toBeginningOfSentenceCase(toDo.frequency.name)!,
            overflow: TextOverflow.visible,
            minFontSize: Constants.small,
            maxLines: 1,
            softWrap: false),
        onTap: () {
          showDialog(
              context: context,
              builder: (BuildContext context) {
                Frequency cacheFreq = toDo.frequency;
                Set<int> cacheWeekdays = {};
                for (int i = 0; i < toDo.repeatDays.length; i++) {
                  if (toDo.repeatDays[i]) {
                    cacheWeekdays.add(i);
                  }
                }

                if (cacheWeekdays.isEmpty) {
                  int day = (Constants.nullDate != toDo.startDate)
                      ? max(toDo.startDate.weekday - 1, 0)
                      : max(DateTime
                      .now()
                      .weekday - 1, 0);
                  cacheWeekdays.add(day);
                }

                int cacheSkip = toDo.repeatSkip;

                return StatefulBuilder(builder: (BuildContext context,
                    void Function(void Function()) setState) {
                  return Dialog(
                      child: Padding(
                          padding: const EdgeInsets.all(Constants.innerPadding),
                          child: Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: AutoSizeText(
                                          "Set Recurring",
                                          softWrap: false,
                                          maxLines: 1,
                                          minFontSize: Constants.medium,
                                          overflow: TextOverflow.visible,
                                          style: Constants.headerStyle,
                                        ),
                                      )
                                    ]),
                                const Row(
                                  mainAxisSize: MainAxisSize.max,
                                  mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                                  children: [
                                    Flexible(
                                      child: AutoSizeText(
                                        "Repeat:",
                                        softWrap: false,
                                        maxLines: 1,
                                        minFontSize: Constants.medium,
                                        overflow: TextOverflow.visible,
                                        style: Constants.largeHeaderStyle,
                                      ),
                                    ),
                                    Flexible(
                                      child: FittedBox(
                                          fit: BoxFit.fill,
                                          child: Icon(Icons.repeat_rounded,
                                              size: Constants.medIconSize)),
                                    ),
                                  ],
                                ),
                                // This is a hacky override until m3 Has width-scaling for DropdownMenu
                                Padding(
                                  padding: (cacheFreq != Frequency.once &&
                                      cacheFreq != Frequency.daily)
                                      ? const EdgeInsets.fromLTRB(
                                      Constants.innerPadding,
                                      Constants.innerPadding,
                                      Constants.innerPadding,
                                      Constants.halfPadding)
                                      : const EdgeInsets.all(
                                      Constants.innerPadding),
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        width: 2,
                                        color: Theme
                                            .of(context)
                                            .colorScheme
                                            .outlineVariant,
                                        strokeAlign:
                                        BorderSide.strokeAlignOutside,
                                      ),
                                      borderRadius: const BorderRadius.all(
                                          Radius.circular(Constants.circular)),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(
                                          Constants.innerPadding),
                                      child: DropdownButtonHideUnderline(
                                        child: DropdownButton<Frequency>(
                                          focusColor: Colors.transparent,
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: Constants.padding),
                                          isDense: true,
                                          isExpanded: true,
                                          dropdownColor: Constants.dialogColor(
                                              context: context),
                                          borderRadius: const BorderRadius.all(
                                              Radius.circular(
                                                  Constants.roundedCorners)),
                                          value: cacheFreq,
                                          onChanged: (Frequency? value) =>
                                              setState(() {
                                                checkClose = true;
                                                cacheFreq = value ?? cacheFreq;
                                              }),
                                          items: Frequency.values
                                              .map((Frequency frequency) =>
                                              DropdownMenuItem<Frequency>(
                                                value: frequency,
                                                child: AutoSizeText(
                                                  "${toBeginningOfSentenceCase(
                                                      frequency.name)}",
                                                  softWrap: false,
                                                  maxLines: 1,
                                                  minFontSize:
                                                  Constants.small,
                                                ),
                                              ))
                                              .toList(),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                                (cacheFreq == Frequency.custom)
                                    ? Column(
                                  children: [
                                    // Days of the week - Wrap in padding and a container
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                          Constants.innerPadding,
                                          Constants.innerPadding,
                                          Constants.innerPadding,
                                          0),
                                      child: Wrap(
                                          spacing: 5,
                                          runSpacing: 5,
                                          alignment: WrapAlignment.center,
                                          runAlignment:
                                          WrapAlignment.center,
                                          children: Constants.weekDays
                                              .map((weekDay) =>
                                              InputChip(
                                                  backgroundColor:
                                                  Constants.dialogColor(
                                                      context:
                                                      context),
                                                  shape:
                                                  const RoundedRectangleBorder(
                                                    borderRadius:
                                                    BorderRadius.all(
                                                        Radius.circular(
                                                            Constants
                                                                .circular)),
                                                    side: BorderSide(
                                                      strokeAlign: BorderSide
                                                          .strokeAlignOutside,
                                                    ),
                                                  ),
                                                  label: AutoSizeText(
                                                      weekDay.key,
                                                      minFontSize:
                                                      Constants.small,
                                                      maxLines: 1,
                                                      softWrap: false,
                                                      overflow:
                                                      TextOverflow
                                                          .visible),
                                                  selected: cacheWeekdays
                                                      .contains(
                                                      weekDay.value),
                                                  onSelected:
                                                      (bool selected) =>
                                                      setState(() {
                                                        checkClose =
                                                        true;
                                                        if (selected) {
                                                          cacheWeekdays
                                                              .add(weekDay
                                                              .value);
                                                        } else {
                                                          cacheWeekdays
                                                              .remove(
                                                              weekDay.value);
                                                          if (cacheWeekdays
                                                              .isEmpty) {
                                                            int day = (Constants
                                                                .nullDate !=
                                                                toDo
                                                                    .startDate)
                                                                ? max(
                                                                toDo.startDate
                                                                    .weekday -
                                                                    1,
                                                                0)
                                                                : max(
                                                                DateTime
                                                                    .now()
                                                                    .weekday -
                                                                    1,
                                                                0);
                                                            cacheWeekdays
                                                                .add(
                                                                day);
                                                          }
                                                        }
                                                      })))
                                              .toList()),
                                    ),
                                  ],
                                )
                                    : const SizedBox.shrink(),

                                // Repeat Skip
                                (cacheFreq != Frequency.once &&
                                    cacheFreq != Frequency.daily)
                                    ? Padding(
                                  padding: const EdgeInsets.all(
                                      Constants.innerPadding),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment:
                                    MainAxisAlignment.center,
                                    children: [
                                      const Flexible(
                                          child: AutoSizeText(
                                            "Every",
                                            minFontSize: Constants.small,
                                            style: Constants.headerStyle,
                                            overflow: TextOverflow.visible,
                                            softWrap: false,
                                            maxLines: 1,
                                          )),
                                      Expanded(
                                          child: NumberPicker(
                                              itemCount: 1,
                                              textStyle: Constants
                                                  .numberPickerSecondary(
                                                  context: context),
                                              selectedTextStyle: Constants
                                                  .numberPickerPrimary(
                                                  context: context),
                                              minValue: 1,
                                              maxValue: 100,
                                              value: cacheSkip,
                                              haptics: true,
                                              onChanged: (value) {
                                                SemanticsService.announce(
                                                    "Skip value: $value",
                                                    Directionality.of(
                                                        context));
                                                setState(() {
                                                  checkClose = true;
                                                  cacheSkip = value;
                                                });
                                              })),
                                      Flexible(
                                        child: AutoSizeText(
                                          (cacheFreq == Frequency.custom)
                                              ? "Week${(cacheSkip > 1)
                                              ? "s"
                                              : "."}"
                                              : cacheFreq.name.replaceAll(
                                              "ly",
                                              (cacheSkip > 1)
                                                  ? "s."
                                                  : "."),
                                          minFontSize: Constants.small,
                                          style: Constants.headerStyle,
                                          overflow: TextOverflow.visible,
                                          softWrap: false,
                                          maxLines: 1,
                                          textAlign: TextAlign.end,
                                        ),
                                      )
                                    ],
                                  ),
                                )
                                    : const SizedBox.shrink(),

                                Row(
                                    mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.only(
                                              right: Constants.padding),
                                          child: FilledButton.tonalIcon(
                                              icon: const Icon(
                                                  Icons.close_rounded),
                                              onPressed: () =>
                                                  Navigator.pop(context),
                                              label: const AutoSizeText(
                                                  "Cancel",
                                                  softWrap: false,
                                                  overflow:
                                                  TextOverflow.visible,
                                                  maxLines: 1,
                                                  minFontSize:
                                                  Constants.small)),
                                        ),
                                      ),
                                      Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.only(
                                              left: Constants.padding),
                                          child: FilledButton.icon(
                                            icon:
                                            const Icon(Icons.done_rounded),
                                            onPressed: () {
                                              setState(() {
                                                checkClose = true;
                                                toDo.frequency = cacheFreq;
                                                toDo.repeatSkip = cacheSkip;

                                                if (cacheWeekdays.isEmpty) {
                                                  cacheWeekdays.add(
                                                      toDo.startDate.weekday -
                                                          1);
                                                }
                                                for (int i = 0;
                                                i < toDo.repeatDays.length;
                                                i++) {
                                                  toDo.repeatDays[i] =
                                                      cacheWeekdays.contains(i);
                                                }
                                              });
                                              Navigator.pop(context);
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
                              ])));
                });
              }).then((_) => setState(() {}));
        },
        trailing: (toDo.frequency != Frequency.once)
            ? IconButton(
            icon: const Icon(Icons.clear_rounded),
            onPressed: () =>
                setState(() {
                  checkClose = true;
                  toDo.frequency = Frequency.once;

                  toDo.repeatDays
                      .fillRange(0, toDo.repeatDays.length, false);

                  toDo.repeatSkip = 1;
                }))
            : null);
  }

  Row buildUpdateDeleteRow({required BuildContext context}) {
    return Row(mainAxisAlignment: MainAxisAlignment.end, children: [
      Flexible(
        child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: Constants.padding),
            child: buildDeleteButton(context: context)),
      ),
      Flexible(child: buildUpdateButton(context: context)),
    ]);
  }

  FilledButton buildDeleteButton({required BuildContext context}) {
    return FilledButton.tonalIcon(
      label: const Text("Delete"),
      icon: const Icon(Icons.delete_forever_rounded),
      onPressed: () async => await handleDelete(context: context),
    );
  }

  FilledButton buildUpdateButton({required BuildContext context}) {
    return FilledButton.icon(
        label: const Text("Update"),
        icon: const Icon(Icons.add_rounded),
        onPressed: () async {
          bool validData = validateData();
          if (validData) {
            await handleUpdate(context: context);
          }
          // Then save.
        });
  }
}
