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
import "../../widgets/handle_repeatable_modal.dart";
import "../../widgets/leading_widgets.dart";
import "../../widgets/listviews.dart";
import "../../widgets/padded_divider.dart";
import "../../widgets/search_recents_bar.dart";
import "../../widgets/tiles.dart";
import "../../widgets/title_bar.dart";

class UpdateToDoScreen extends StatefulWidget {
  final MapEntry<String, int>? initialGroup;
  final ToDo? initialToDo;

  const UpdateToDoScreen({Key? key, this.initialGroup, this.initialToDo})
      : super(key: key);

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
  late final ScrollController mobileScrollController;
  late final ScrollController desktopScrollController;
  late final ScrollPhysics scrollPhysics;

  // Name
  late final TextEditingController nameEditingController;
  String? nameErrorText;

  // Group
  late final SearchController groupEditingController;

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

    if (null != widget.initialToDo) {
      toDoProvider.curToDo = widget.initialToDo;
    }
  }

  @override
  void dispose() {
    nameEditingController.dispose();
    groupEditingController.dispose();
    descriptionEditingController.dispose();
    repeatSkipEditingController.dispose();
    mobileScrollController.dispose();
    desktopScrollController.dispose();

    for (TextEditingController controller in subTaskEditingController) {
      controller.dispose();
    }

    super.dispose();
  }

  void initializeParams() {
    checkClose = false;
    prevToDo = toDo.copy();
    prevToDo.id = toDo.id;
    shownTasks = toDo.subTasks.indexOf(SubTask());
    if (shownTasks < 0) {
      shownTasks = toDo.subTasks.length;
    }

    cacheSubTasks = List.from(toDo.subTasks);

    // Midnight as a start/due time is ambiguous treating as "null".
    showStartTime =
        Constants.midnight != TimeOfDay.fromDateTime(toDo.startDate);
    showDueTime = Constants.midnight != TimeOfDay.fromDateTime(toDo.dueDate);
  }

  Future<void> initializeControllers() async {
    mobileScrollController = ScrollController();
    desktopScrollController = ScrollController();
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
    if (null != widget.initialGroup) {
      groupEditingController.value = groupEditingController.value
          .copyWith(text: widget.initialGroup?.key ?? "");
    } else {
      groupProvider
          .getGroupByID(id: toDo.groupID)
          .then((group) => setState(() => groupEditingController.value =
              groupEditingController.value.copyWith(text: group?.name ?? "")))
          .catchError((_) {
        Flushbar? error;

        error = Flushbars.createError(
          message: "Error with Group Retrieval",
          context: context,
          dismissCallback: () => error?.dismiss(),
        );

        error.show(context);
      });
    }
    groupEditingController.addListener(() {
      String newText = groupEditingController.text;
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
    setState(() {
      checkClose = true;
      toDo.groupID = id;
    });
  }

  void handleHistorySelection({
    required int id,
  }) {
    setState(() {
      checkClose = true;
      toDo.groupID = id;
    });
  }

  bool validateData() {
    bool valid = true;
    if (groupEditingController.text.isEmpty) {
      toDo.groupID = null;
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

  Future<void> handleUpdate() async {
    if (prevToDo.frequency != Frequency.once && checkClose) {
      bool? updateSingle = await showModalBottomSheet<bool?>(
          showDragHandle: true,
          context: context,
          builder: (BuildContext context) {
            return const HandleRepeatableModal(action: "Update");
          });
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
        // To prevent getting deleted by editing another repeating event.
        toDo.repeatID = Constants.generateID();

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

  Future<void> handleDelete() async {
    if (prevToDo.frequency != Frequency.once) {
      bool? deleteSingle = await showModalBottomSheet<bool?>(
          showDragHandle: true,
          context: context,
          builder: (BuildContext context) {
            return const HandleRepeatableModal(
              action: "Delete",
            );
          });
      if (null == deleteSingle) {
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

      if (deleteSingle) {
        prevToDo.repeatable = true;

        // To prevent getting deleted by editing another repeating event.
        toDo.repeatID = Constants.generateID();

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

    await toDoProvider
        .deleteToDo(toDo: toDo)
        .whenComplete(() => Navigator.pop(context));
  }

  Future<void> handleClose({required bool willDiscard}) async {
    if (willDiscard) {
      await toDoProvider
          .updateToDo(toDo: prevToDo)
          .whenComplete(() => Navigator.pop(context));
    }

    if (mounted) {
      setState(() => checkClose = false);
    }
  }

  void clearNameField() {
    if (mounted) {
      setState(() {
        checkClose = true;
        nameEditingController.clear();
        toDo.name = "";
      });
    }
  }

  void completeToDo(bool? value) {
    if (mounted) {
      return setState(() {
        checkClose = true;
        toDo.completed = value!;
      });
    }
  }

  void handleWeightChange(double value) {
    if (mounted) {
      return setState(() {
        checkClose = true;
        toDo.weight = value.toInt();
        toDo.realDuration = toDoProvider.calculateRealDuration(
            weight: toDo.weight, duration: toDo.expectedDuration);
      });
    }
  }

  void reorderSubtasks(int oldIndex, int newIndex) {
    if (mounted) {
      return setState(() {
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
  }

  void onSubtaskWeightChanged() {
    if (mounted) {
      return setState(() {
        checkClose = true;
        toDo.weight = toDoProvider.calculateWeight(
            subTasks: List.generate(Constants.numTasks[toDo.taskType]!,
                (index) => toDo.subTasks[index]));
        toDo.realDuration = toDoProvider.calculateRealDuration(
            weight: toDo.weight, duration: toDo.expectedDuration);
      });
    }
  }

  void removeSubtask({required int index}) {
    if (mounted) {
      return setState(() {
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
        toDo.realDuration = toDoProvider.calculateRealDuration(
            weight: toDo.weight, duration: toDo.expectedDuration);
      });
    }
  }

  void addSubTask() {
    if (mounted) {
      return setState(() {
        shownTasks++;
        shownTasks = min(shownTasks, Constants.maxNumTasks);
      });
    }
  }

  void toggleMyDay() {
    if (mounted) {
      return setState(() {
        checkClose = true;
        toDo.myDay = !toDo.myDay;
      });
    }
  }

  void changePriority(Set<Priority> newSelection) {
    if (mounted) {
      return setState(() {
        checkClose = true;
        toDo.priority = newSelection.first;
      });
    }
  }

  void updateDuration(int? value) {
    if (mounted) {
      return setState(() {
        checkClose = true;
        toDo.expectedDuration = value ?? toDo.expectedDuration;
        toDo.realDuration = toDoProvider.calculateRealDuration(
            weight: toDo.weight, duration: toDo.expectedDuration);
      });
    }
  }

  void clearDuration() {
    if (mounted) {
      return setState(() {
        checkClose = true;
        toDo.expectedDuration = 0;
        toDo.realDuration = 0;
      });
    }
  }

  void clearDates() {
    if (mounted) {
      return setState(() {
        checkClose = true;
        toDo.startDate = Constants.nullDate;
        toDo.dueDate = Constants.nullDate;
      });
    }
  }

  void updateDates({bool? checkClose, DateTime? newStart, DateTime? newDue}) {
    if (mounted) {
      setState(() {
        this.checkClose = checkClose ?? this.checkClose;
        newStart = newStart ?? Constants.nullDate;
        newDue = newDue ?? Constants.nullDate;
        toDo.startDate = newStart!;
        toDo.dueDate = newDue!;

        if (Constants.nullDate != toDo.startDate &&
            Constants.nullDate != toDo.dueDate &&
            toDo.startDate.isAfter(toDo.dueDate)) {
          toDo.startDate = toDo.dueDate;
        }
        (Constants.nullDate != toDo.startDate) ? toDo.startDate : null;
      });
    }
  }

  void clearTimes() {
    if (mounted) {
      setState(() {
        checkClose = true;

        toDo.startDate = toDo.startDate.copyWith(
            hour: Constants.midnight.hour, minute: Constants.midnight.minute);
        toDo.dueDate = toDo.dueDate.copyWith(
            hour: Constants.midnight.hour, minute: Constants.midnight.minute);
      });
    }
  }

  void updateTimes({bool? checkClose, TimeOfDay? newStart, TimeOfDay? newDue}) {
    if (mounted) {
      return setState(() {
        this.checkClose = checkClose ?? this.checkClose;
        newStart = newStart ?? Constants.midnight;
        newDue = newDue ?? Constants.midnight;
        toDo.startDate = toDo.startDate
            .copyWith(hour: newStart!.hour, minute: newStart!.minute);
        toDo.dueDate =
            toDo.dueDate.copyWith(hour: newDue!.hour, minute: newDue!.minute);
      });
    }
  }

  void clearRepeatable() {
    if (mounted) {
      return setState(() {
        checkClose = true;
        toDo.frequency = Frequency.once;

        toDo.repeatDays.fillRange(0, toDo.repeatDays.length, false);

        toDo.repeatSkip = 1;
      });
    }
  }

  void updateRepeatable(
      {bool? checkClose,
      required Frequency newFreq,
      required Set<int> newWeekdays,
      required int newSkip}) {
    if (mounted) {
      return setState(() {
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
  }

  void onDataChange() {
    if (mounted) {
      return setState(() {
        checkClose = true;
      });
    }
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

  Future<void> updateAndValidate() async {
    if (validateData()) {
      await handleUpdate();
    }
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
      child: Padding(
        padding: const EdgeInsets.all(Constants.padding),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          // Title && Close Button
          TitleBar(
              currentContext: context,
              title: "Edit Task",
              centerWidget: (toDo.expectedDuration > 0)
                  ? TitleBar.durationCenterWidget(
                      expectedDuration: toDo.expectedDuration,
                      realDuration: toDo.realDuration)
                  : null,
              checkClose: checkClose,
              padding:
                  const EdgeInsets.symmetric(horizontal: Constants.padding),
              handleClose: handleClose),
          const PaddedDivider(padding: Constants.halfPadding),
          Flexible(
            child: Scrollbar(
              thumbVisibility: true,
              controller: desktopScrollController,
              child: ListView(
                  shrinkWrap: true,
                  controller: desktopScrollController,
                  children: [
                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Flexible(
                            child: ListView(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: Constants.padding),
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                children: [
                                  Tiles.nameTile(
                                      context: context,
                                      leading: LeadingWidgets.toDoCheckbox(
                                        scale: Constants.largeCheckboxScale,
                                        completed: toDo.completed,
                                        onChanged: completeToDo,
                                      ),
                                      hintText: "Task Name",
                                      errorText: nameErrorText,
                                      controller: nameEditingController,
                                      outerPadding: const EdgeInsets.all(
                                          Constants.padding),
                                      textFieldPadding: const EdgeInsets.only(
                                        left: Constants.halfPadding,
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
                                      padding: Constants.padding),
                                  // My Day
                                  Tiles.myDayTile(
                                      myDay: toDo.myDay,
                                      canAdd: (userProvider.myDayTotal +
                                              toDo.weight <=
                                          (userProvider.curUser?.bandwidth ??
                                              Constants.maxBandwidth)),
                                      toggleMyDay: toggleMyDay),
                                  const PaddedDivider(
                                      padding: Constants.padding),
                                  // Priority
                                  Tiles.priorityTile(
                                    context: context,
                                    outerPadding: const EdgeInsets.symmetric(
                                        horizontal: Constants.padding),
                                    priority: toDo.priority,
                                    onSelectionChanged: changePriority,
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(
                                        vertical: Constants.padding),
                                    child: PaddedDivider(
                                        padding: Constants.padding),
                                  ),
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
                                      padding: Constants.padding),
                                  // DateTime -> Show status, on click, open a dialog.
                                  Tiles.dateRangeTile(
                                    context: context,
                                    outerPadding: const EdgeInsets.symmetric(
                                        horizontal: Constants.padding),
                                    startDate:
                                        (Constants.nullDate != toDo.startDate)
                                            ? toDo.startDate
                                            : null,
                                    dueDate:
                                        (Constants.nullDate != toDo.dueDate)
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
                                                  horizontal:
                                                      Constants.padding),
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
                                          padding: Constants.padding)
                                      : const SizedBox.shrink(),
                                  // Repeatable Stuff -> Show status, on click, open a dialog.
                                  Tiles.repeatableTile(
                                    context: context,
                                    outerPadding: const EdgeInsets.symmetric(
                                        horizontal: Constants.padding),
                                    frequency: toDo.frequency,
                                    weekdays: weekdayList,
                                    repeatSkip: toDo.repeatSkip,
                                    startDate:
                                        (Constants.nullDate != toDo.startDate)
                                            ? toDo.startDate
                                            : null,
                                    handleUpdate: updateRepeatable,
                                    handleClear: clearRepeatable,
                                  ),
                                ]),
                          ),
                          Flexible(
                            child: ListView(
                                physics: const NeverScrollableScrollPhysics(),
                                shrinkWrap: true,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: Constants.padding),
                                children: [
                                  SearchRecentsBar<Group>(
                                    persistentEntry: widget.initialGroup,
                                    hintText: "Search Groups",
                                    padding:
                                        const EdgeInsets.all(Constants.padding),
                                    handleDataSelection: handleGroupSelection,
                                    handleHistorySelection:
                                        handleHistorySelection,
                                    searchController: groupEditingController,
                                    mostRecent: groupProvider.mostRecent,
                                    search: groupProvider.searchGroups,
                                  ),

                                  (toDo.taskType != TaskType.small)
                                      ? const PaddedDivider(
                                          padding: Constants.padding)
                                      : const SizedBox.shrink(),
                                  // Subtasks
                                  (toDo.taskType != TaskType.small)
                                      ? buildSubTasksTile()
                                      : const SizedBox.shrink(),

                                  const PaddedDivider(
                                      padding: Constants.padding),

                                  // Description
                                  Tiles.descriptionTile(
                                    hintText: "Notes",
                                    minLines: Constants.desktopMinLines,
                                    maxLines:
                                        Constants.desktopMaxLinesBeforeScroll,
                                    controller: descriptionEditingController,
                                    outerPadding: const EdgeInsets.symmetric(
                                        horizontal: Constants.padding),
                                    context: context,
                                  ),
                                ]),
                          )
                        ])
                  ]),
            ),
          ),

          const PaddedDivider(padding: Constants.halfPadding),
          Tiles.updateAndDeleteButtons(
            handleDelete: handleDelete,
            handleUpdate: updateAndValidate,
            updateButtonPadding:
                const EdgeInsets.symmetric(horizontal: Constants.padding),
            deleteButtonPadding:
                const EdgeInsets.symmetric(horizontal: Constants.padding),
          )
        ]),
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
                      ? TitleBar.durationCenterWidget(
                          expectedDuration: toDo.expectedDuration,
                          realDuration: toDo.realDuration)
                      : null,
                  checkClose: checkClose,
                  padding:
                      const EdgeInsets.symmetric(horizontal: Constants.padding),
                  handleClose: handleClose),
              const PaddedDivider(padding: Constants.halfPadding),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  controller: mobileScrollController,
                  physics: scrollPhysics,
                  children: [
                    // Title + status
                    Tiles.nameTile(
                        context: context,
                        leading: LeadingWidgets.toDoCheckbox(
                          scale: Constants.largeCheckboxScale,
                          completed: toDo.completed,
                          onChanged: completeToDo,
                        ),
                        hintText: "Task Name",
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

                    const PaddedDivider(padding: Constants.padding),

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
                      mobile: smallScreen,
                      context: context,
                      outerPadding: const EdgeInsets.symmetric(
                          horizontal: Constants.padding),
                      priority: toDo.priority,
                      onSelectionChanged: changePriority,
                    ),

                    const Padding(
                      padding:
                          EdgeInsets.symmetric(vertical: Constants.padding),
                      child: PaddedDivider(padding: Constants.padding),
                    ),

                    SearchRecentsBar<Group>(
                      hintText: "Search Groups",
                      padding: const EdgeInsets.all(Constants.padding),
                      handleDataSelection: handleGroupSelection,
                      handleHistorySelection: handleHistorySelection,
                      searchController: groupEditingController,
                      mostRecent: groupProvider.mostRecent,
                      search: groupProvider.searchGroups,
                    ),

                    const Padding(
                      padding:
                          EdgeInsets.symmetric(vertical: Constants.padding),
                      child: PaddedDivider(padding: Constants.padding),
                    ),

                    // Description
                    Tiles.descriptionTile(
                      hintText: "Notes",
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
                        ? const PaddedDivider(padding: Constants.padding)
                        : const SizedBox.shrink(),
                    // Repeatable Stuff -> Show status, on click, open a dialog.
                    Tiles.repeatableTile(
                      context: context,
                      outerPadding: const EdgeInsets.symmetric(
                          horizontal: Constants.padding),
                      frequency: toDo.frequency,
                      weekdays: weekdayList,
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

              const PaddedDivider(padding: Constants.halfPadding),
              Tiles.updateAndDeleteButtons(
                handleDelete: handleDelete,
                handleUpdate: updateAndValidate,
                updateButtonPadding:
                    const EdgeInsets.symmetric(horizontal: Constants.padding),
                deleteButtonPadding:
                    const EdgeInsets.symmetric(horizontal: Constants.padding),
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
            physics: physics,
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
}
