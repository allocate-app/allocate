import "dart:math";

import "package:another_flushbar/flushbar.dart";
import "package:auto_size_text/auto_size_text.dart";
import "package:flutter/material.dart";
import "package:flutter/semantics.dart";
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
import "../../widgets/expanded_listtile.dart";
import "../../widgets/flushbars.dart";
import "../../widgets/listviews.dart";
import "../../widgets/padded_divider.dart";
import "../../widgets/search_recents_bar.dart";
import "../../widgets/tiles.dart";
import "../../widgets/title_bar.dart";

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

  void handleGroupSelection({required int id}) {
    // Controller logic
    setState(() {
      checkClose = true;
      toDo.groupID = id;
    });
  }

  void handleHistorySelection({
    required MapEntry<String, int> data,
  }) {
    setState(() {
      checkClose = true;
      toDo.groupID = data.value;
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
                  color: Theme.of(context).colorScheme.outline,
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
                color: Theme.of(context).colorScheme.outline,
              ))),
      AutoSizeText("${toDo.weight}",
          minFontSize: Constants.large,
          softWrap: false,
          maxLines: 1,
          overflow: TextOverflow.visible,
          style: Constants.hugeHeaderStyle),
    ]);
  }

  void handleClose({required bool willDiscard}) {
    if (willDiscard) {
      Navigator.pop(context, prevToDo);
    }

    if (mounted) {
      setState(() => checkClose = false);
    }
  }

  void clearNameField() {
    setState(() {
      checkClose = true;
      nameEditingController.clear();
      toDo.name = "";
    });
  }

  void handleWeightChange(double value) => setState(() {
        checkClose = true;
        toDo.weight = value.toInt();
        toDo.realDuration = toDoProvider.calculateRealDuration(
            weight: toDo.weight, duration: toDo.expectedDuration);
      });

  void reorderSubtasks(int oldIndex, int newIndex) {
    setState(() {
      checkClose = true;
      if (oldIndex < newIndex) {
        newIndex--;
      }
      SubTask st = cacheSubTasks.removeAt(oldIndex);
      cacheSubTasks.insert(newIndex, st);
      TextEditingController ct = subTaskEditingController.removeAt(oldIndex);
      subTaskEditingController.insert(newIndex, ct);
    });
  }

  void onSubtaskWeightChanged() {
    return setState(() {
      checkClose = true;
      toDo.weight = toDoProvider.calculateWeight(
          subTasks: List.generate(Constants.numTasks[toDo.taskType]!,
              (index) => toDo.subTasks[index]));
      toDo.realDuration = toDoProvider.calculateRealDuration(
          weight: toDo.weight, duration: toDo.expectedDuration);
    });
  }

  void removeSubtask({required int index}) {
    setState(() {
      checkClose = true;
      SubTask st = cacheSubTasks.removeAt(index);
      st = SubTask();
      cacheSubTasks.add(st);
      TextEditingController ct = subTaskEditingController.removeAt(index);
      ct.value = ct.value.copyWith(text: st.name);
      subTaskEditingController.add(ct);

      shownTasks--;
      shownTasks = max(shownTasks, 0);
      toDo.weight = toDoProvider.calculateWeight(subTasks: cacheSubTasks);
    });
  }

  void addSubTask() {
    return setState(() {
      shownTasks++;
      shownTasks = min(shownTasks, Constants.maxNumTasks);
    });
  }

  void toggleMyDay() {
    return setState(() {
      checkClose = true;
      toDo.myDay = !toDo.myDay;
    });
  }

  void changePriority(Set<Priority> newSelection) {
    return setState(() {
      checkClose = true;
      toDo.priority = newSelection.first;
    });
  }

  void updateDuration(int? value) {
    setState(() {
      checkClose = true;
      toDo.expectedDuration = value ?? toDo.expectedDuration;
      toDo.realDuration = toDoProvider.calculateRealDuration(
          weight: toDo.weight, duration: toDo.expectedDuration);
    });
  }

  void clearDuration() {
    return setState(() {
      checkClose = true;
      toDo.expectedDuration = 0;
      toDo.realDuration = 0;
    });
  }

  void clearDates() {
    return setState(() {
      checkClose = true;
      toDo.startDate = Constants.nullDate;
      toDo.dueDate = Constants.nullDate;
    });
  }

  void updateDates({bool? checkClose, DateTime? newStart, DateTime? newDue}) {
    setState(() {
      this.checkClose = checkClose ?? this.checkClose;
      toDo.startDate = newStart ?? Constants.nullDate;
      toDo.dueDate = newDue ?? Constants.nullDate;

      if (Constants.nullDate != toDo.startDate &&
          Constants.nullDate != toDo.dueDate &&
          toDo.startDate.isAfter(toDo.dueDate)) {
        toDo.startDate = toDo.dueDate;
      }
    });
  }

  void clearTimes() {
    setState(() {
      checkClose = true;

      toDo.startDate = toDo.startDate.copyWith(
          hour: Constants.midnight.hour, minute: Constants.midnight.minute);
      toDo.dueDate = toDo.dueDate.copyWith(
          hour: Constants.midnight.hour, minute: Constants.midnight.minute);
    });
  }

  void updateTimes({bool? checkClose, TimeOfDay? newStart, TimeOfDay? newDue}) {
    setState(() {
      this.checkClose = checkClose ?? this.checkClose;
      newStart = newStart ?? Constants.midnight;
      newDue = newDue ?? Constants.midnight;
      toDo.startDate = toDo.startDate
          .copyWith(hour: newStart!.hour, minute: newStart!.minute);
      toDo.dueDate =
          toDo.dueDate.copyWith(hour: newDue!.hour, minute: newDue!.minute);
    });
  }

  void clearRepeatable() {
    setState(() {
      checkClose = true;
      toDo.frequency = Frequency.once;

      toDo.repeatDays.fillRange(0, toDo.repeatDays.length, false);

      toDo.repeatSkip = 1;
    });
  }

  void updateRepeatable(
      {bool? checkClose,
      required Frequency newFreq,
      required Set<int> newWeekdays,
      required int newSkip}) {
    setState(() {
      this.checkClose = checkClose ?? this.checkClose;
      toDo.frequency = newFreq;
      toDo.repeatSkip = newSkip;

      if (newWeekdays.isEmpty) {
        newWeekdays.add(toDo.startDate.weekday - 1);
      }
      for (int i = 0; i < toDo.repeatDays.length; i++) {
        toDo.repeatDays[i] = newWeekdays.contains(i);
      }
    });
  }

  void onDataChange() {
    return setState(() {
      checkClose = true;
    });
  }

  Set<int> get weekdayList {
    Set<int> weekdays = {};
    for (int i = 0; i < toDo.repeatDays.length; i++) {
      if (toDo.repeatDays[i]) {
        weekdays.add(i);
      }
    }
    return weekdays;
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    bool largeScreen = (width >= Constants.largeScreen);
    bool smallScreen = (width <= Constants.smallScreen);
    bool hugeScreen = (width >= Constants.hugeScreen);
    bool showTimeTile = (Constants.nullDate != toDo.startDate ||
        Constants.nullDate != toDo.dueDate);

    return (largeScreen)
        ? buildDesktopDialog(
            context: context,
            showTimeTile: showTimeTile,
          )
        : buildMobileDialog(
            context: context,
            showTimeTile: showTimeTile,
            smallScreen: smallScreen);
  }

  Dialog buildDesktopDialog({
    required BuildContext context,
    bool showTimeTile = false,
  }) {
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
                TitleBar(
                    currentContext: context,
                    title: "Edit Task",
                    centerWidget: (toDo.expectedDuration > 0)
                        ? TitleBar.toDoCenterWidget(
                            expectedDuration: toDo.expectedDuration,
                            realDuration: toDo.realDuration)
                        : null,
                    checkClose: checkClose,
                    padding: const EdgeInsets.symmetric(
                        horizontal: Constants.padding),
                    handleClose: handleClose),
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
                                Tiles.nameTile(
                                    context: context,
                                    leading: buildCheckbox(
                                        scale: Constants.largeCheckboxScale),
                                    hintText: "Task Name",
                                    errorText: nameErrorText,
                                    controller: nameEditingController,
                                    outerPadding: const EdgeInsets.symmetric(
                                        horizontal: Constants.innerPadding),
                                    textFieldPadding:
                                        const EdgeInsets.symmetric(
                                      horizontal: Constants.padding,
                                    ),
                                    handleClear: clearNameField),
                                Tiles.weightTile(
                                  outerPadding: const EdgeInsets.all(
                                      Constants.innerPadding),
                                  batteryPadding: const EdgeInsets.symmetric(
                                      horizontal: Constants.innerPadding),
                                  constraints:
                                      const BoxConstraints(maxWidth: 200),
                                  weight: toDo.weight.toDouble(),
                                  max: (toDo.taskType == TaskType.small)
                                      ? Constants.maxTaskWeight.toDouble()
                                      : Constants.maxWeight.toDouble(),
                                  slider: (toDo.taskType == TaskType.small)
                                      ? Tiles.weightSlider(
                                          weight: toDo.weight.toDouble(),
                                          handleWeightChange:
                                              handleWeightChange,
                                        )
                                      : null,
                                ),
                                const PaddedDivider(
                                    padding: Constants.innerPadding),
                                // Subtasks
                                (toDo.taskType != TaskType.small)
                                    ? buildSubTasksTile(
                                        physics: scrollPhysics,
                                      )
                                    : const SizedBox.shrink(),

                                const PaddedDivider(padding: Constants.padding),
                                // My Day
                                Tiles.myDayTile(
                                    myDay: toDo.myDay,
                                    canAdd: (userProvider.myDayTotal +
                                            toDo.weight <=
                                        (userProvider.curUser?.bandwidth ??
                                            Constants.maxBandwidth)),
                                    toggleMyDay: toggleMyDay),
                                const PaddedDivider(padding: Constants.padding),
                                // Priority
                                Tiles.priorityTile(
                                  context: context,
                                  outerPadding: const EdgeInsets.symmetric(
                                      horizontal: Constants.padding),
                                  priority: toDo.priority,
                                  onSelectionChanged: changePriority,
                                ),
                              ]),
                        ),
                        Expanded(
                          child: ListView(
                              controller: subScrollControllerRight,
                              physics: scrollPhysics,
                              shrinkWrap: true,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: Constants.padding),
                              children: [
                                SearchRecents<Group>(
                                  padding:
                                      const EdgeInsets.all(Constants.padding),
                                  handleDataSelection: handleGroupSelection,
                                  handleHistorySelection:
                                      handleHistorySelection,
                                  searchController: groupEditingController,
                                  mostRecent: groupProvider.mostRecent,
                                  search: groupProvider.searchGroups,
                                ),

                                const PaddedDivider(
                                    padding: Constants.innerPadding),

                                // Description
                                Tiles.descriptionTile(
                                  controller: descriptionEditingController,
                                  outerPadding: const EdgeInsets.symmetric(
                                      horizontal: Constants.padding),
                                  context: context,
                                ),

                                const PaddedDivider(
                                    padding: Constants.innerPadding),

                                // Expected Duration / RealDuration -> Show status, on click, open a dialog.
                                Tiles.durationTile(
                                  expectedDuration: toDo.expectedDuration,
                                  context: context,
                                  realDuration: toDo.realDuration,
                                  outerPadding: const EdgeInsets.symmetric(
                                      horizontal: Constants.padding),
                                  handleClear: clearDuration,
                                  handleUpdate: updateDuration,
                                ),

                                const PaddedDivider(
                                    padding: Constants.innerPadding),
                                // DateTime -> Show status, on click, open a dialog.
                                Tiles.dateRangeTile(
                                  context: context,
                                  outerPadding: const EdgeInsets.symmetric(
                                      horizontal: Constants.padding),
                                  startDate:
                                      (Constants.nullDate != toDo.startDate)
                                          ? toDo.startDate
                                          : null,
                                  dueDate: (Constants.nullDate != toDo.dueDate)
                                      ? toDo.dueDate
                                      : null,
                                  handleClear: clearDates,
                                  handleUpdate: updateDates,
                                ),

                                const PaddedDivider(
                                    padding: Constants.innerPadding),
                                // Time
                                (showTimeTile)
                                    ? Tiles.timeTile(
                                        outerPadding:
                                            const EdgeInsets.symmetric(
                                                horizontal: Constants.padding),
                                        startTime: (Constants.midnight !=
                                                TimeOfDay.fromDateTime(
                                                    toDo.startDate))
                                            ? TimeOfDay.fromDateTime(
                                                toDo.startDate)
                                            : null,
                                        dueTime: (Constants.midnight !=
                                                TimeOfDay.fromDateTime(
                                                    toDo.dueDate))
                                            ? TimeOfDay.fromDateTime(
                                                toDo.dueDate)
                                            : null,
                                        context: context,
                                        handleClear: clearTimes,
                                        handleUpdate: updateTimes,
                                      )
                                    : const SizedBox.shrink(),
                                (showTimeTile)
                                    ? const PaddedDivider(
                                        padding: Constants.innerPadding)
                                    : const SizedBox.shrink(),
                                // Repeatable Stuff -> Show status, on click, open a dialog.
                                Tiles.repeatableTile(
                                  context: context,
                                  outerPadding: const EdgeInsets.symmetric(
                                      horizontal: Constants.padding),
                                  frequency: toDo.frequency,
                                  weekdayList: weekdayList,
                                  repeatSkip: toDo.repeatSkip,
                                  startDate:
                                      (Constants.nullDate != toDo.startDate)
                                          ? toDo.startDate
                                          : null,
                                  handleUpdate: updateRepeatable,
                                  handleClear: clearRepeatable,
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

  Dialog buildMobileDialog(
      {required BuildContext context,
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
              TitleBar(
                  currentContext: context,
                  title: "Edit Task",
                  centerWidget: (toDo.expectedDuration > 0)
                      ? TitleBar.toDoCenterWidget(
                          expectedDuration: toDo.expectedDuration,
                          realDuration: toDo.realDuration)
                      : null,
                  checkClose: checkClose,
                  padding:
                      const EdgeInsets.symmetric(horizontal: Constants.padding),
                  handleClose: handleClose),
              const PaddedDivider(padding: Constants.padding),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  controller: mainScrollController,
                  physics: scrollPhysics,
                  children: [
                    // Title + status
                    Tiles.nameTile(
                        context: context,
                        leading:
                            buildCheckbox(scale: Constants.largeCheckboxScale),
                        hintText: "Task Name",
                        errorText: nameErrorText,
                        controller: nameEditingController,
                        outerPadding: const EdgeInsets.symmetric(
                            horizontal: Constants.innerPadding),
                        textFieldPadding: const EdgeInsets.symmetric(
                          horizontal: Constants.padding,
                        ),
                        handleClear: clearNameField),

                    Tiles.weightTile(
                      outerPadding:
                          const EdgeInsets.all(Constants.innerPadding),
                      batteryPadding: const EdgeInsets.symmetric(
                          horizontal: Constants.innerPadding),
                      constraints: const BoxConstraints(maxWidth: 200),
                      weight: toDo.weight.toDouble(),
                      max: (toDo.taskType == TaskType.small)
                          ? Constants.maxTaskWeight.toDouble()
                          : Constants.maxWeight.toDouble(),
                      slider: (toDo.taskType == TaskType.small)
                          ? Tiles.weightSlider(
                              weight: toDo.weight.toDouble(),
                              handleWeightChange: handleWeightChange,
                            )
                          : null,
                    ),

                    const PaddedDivider(padding: Constants.innerPadding),

                    // Subtasks
                    (toDo.taskType != TaskType.small)
                        ? buildSubTasksTile()
                        : const SizedBox.shrink(),

                    const PaddedDivider(padding: Constants.padding),
                    // My Day
                    Tiles.myDayTile(
                        myDay: toDo.myDay,
                        canAdd: (userProvider.myDayTotal + toDo.weight <=
                            (userProvider.curUser?.bandwidth ??
                                Constants.maxBandwidth)),
                        toggleMyDay: toggleMyDay),
                    const PaddedDivider(padding: Constants.padding),
                    // Priority
                    Tiles.priorityTile(
                      context: context,
                      outerPadding: const EdgeInsets.symmetric(
                          horizontal: Constants.padding),
                      priority: toDo.priority,
                      onSelectionChanged: changePriority,
                    ),

                    const PaddedDivider(padding: Constants.innerPadding),

                    SearchRecents<Group>(
                      padding: const EdgeInsets.all(Constants.padding),
                      handleDataSelection: handleGroupSelection,
                      handleHistorySelection: handleHistorySelection,
                      searchController: groupEditingController,
                      mostRecent: groupProvider.mostRecent,
                      search: groupProvider.searchGroups,
                    ),

                    const Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: Constants.padding),
                      child: PaddedDivider(padding: Constants.innerPadding),
                    ),

                    // Description
                    Tiles.descriptionTile(
                      controller: descriptionEditingController,
                      outerPadding: const EdgeInsets.symmetric(
                          horizontal: Constants.padding),
                      context: context,
                    ),

                    const PaddedDivider(padding: Constants.innerPadding),
                    // Expected Duration / RealDuration -> Show status, on click, open a dialog.
                    Tiles.durationTile(
                      expectedDuration: toDo.expectedDuration,
                      context: context,
                      realDuration: toDo.realDuration,
                      outerPadding: const EdgeInsets.symmetric(
                          horizontal: Constants.padding),
                      handleClear: clearDuration,
                      handleUpdate: updateDuration,
                    ),

                    const PaddedDivider(padding: Constants.innerPadding),
                    // DateTime -> Show status, on click, open a dialog.
                    Tiles.dateRangeTile(
                      context: context,
                      outerPadding: const EdgeInsets.symmetric(
                          horizontal: Constants.padding),
                      startDate: (Constants.nullDate != toDo.startDate)
                          ? toDo.startDate
                          : null,
                      dueDate: (Constants.nullDate != toDo.dueDate)
                          ? toDo.dueDate
                          : null,
                      handleClear: clearDates,
                      handleUpdate: updateDates,
                    ),

                    const PaddedDivider(padding: Constants.innerPadding),
                    // Time
                    (showTimeTile)
                        ? Tiles.timeTile(
                            outerPadding: const EdgeInsets.symmetric(
                                horizontal: Constants.padding),
                            startTime: (Constants.midnight !=
                                    TimeOfDay.fromDateTime(toDo.startDate))
                                ? TimeOfDay.fromDateTime(toDo.startDate)
                                : null,
                            dueTime: (Constants.midnight !=
                                    TimeOfDay.fromDateTime(toDo.dueDate))
                                ? TimeOfDay.fromDateTime(toDo.dueDate)
                                : null,
                            context: context,
                            handleClear: clearTimes,
                            handleUpdate: updateTimes,
                          )
                        : const SizedBox.shrink(),

                    (showTimeTile)
                        ? const PaddedDivider(padding: Constants.innerPadding)
                        : const SizedBox.shrink(),
                    // Repeatable Stuff -> Show status, on click, open a dialog.
                    Tiles.repeatableTile(
                      context: context,
                      outerPadding: const EdgeInsets.symmetric(
                          horizontal: Constants.padding),
                      frequency: toDo.frequency,
                      weekdayList: weekdayList,
                      repeatSkip: toDo.repeatSkip,
                      startDate: (Constants.nullDate != toDo.startDate)
                          ? toDo.startDate
                          : null,
                      handleUpdate: updateRepeatable,
                      handleClear: clearRepeatable,
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

  Widget buildSubTasksTile({physics = const NeverScrollableScrollPhysics()}) {
    return ExpandedListTile(
      title: const AutoSizeText("Steps",
          maxLines: 1,
          overflow: TextOverflow.visible,
          softWrap: false,
          minFontSize: Constants.small),
      subtitle: AutoSizeText(
          "${min(shownTasks, Constants.numTasks[toDo.taskType]!)}/${Constants.numTasks[toDo.taskType]!} Steps",
          maxLines: 1,
          overflow: TextOverflow.visible,
          softWrap: false,
          minFontSize: Constants.small),
      children: [
        ListViews.reorderableSubtasks(
            context: context,
            subTasks: cacheSubTasks,
            itemCount: min(Constants.numTasks[toDo.taskType]!, shownTasks),
            controllers: subTaskEditingController,
            onRemoved: removeSubtask,
            onReorder: reorderSubtasks,
            onChanged: onDataChange,
            onSubtaskWeightChanged: onSubtaskWeightChanged,
            showHandle: (shownTasks > 1)),
        (shownTasks < Constants.numTasks[toDo.taskType]!)
            ? Tiles.addTile(
                title: "Add a step",
                onTap: addSubTask,
              )
            : const SizedBox.shrink(),
      ],
    );
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
          if (validateData()) {
            await handleUpdate(context: context);
          }
          // Then save.
        });
  }

  Widget buildCheckbox({double scale = 1}) {
    return Transform.scale(
        scale: scale,
        child: Checkbox(
            splashRadius: 15,
            value: toDo.completed,
            onChanged: (bool? value) => setState(() {
                  checkClose = true;
                  toDo.completed = value!;
                }),
            shape: const CircleBorder()));
  }
}
