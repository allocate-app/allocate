import "package:another_flushbar/flushbar.dart";
import "package:flutter/material.dart";
import "package:flutter/semantics.dart";
import "package:provider/provider.dart";

import "../../../model/task/group.dart";
import "../../../model/task/todo.dart";
import "../../../providers/group_provider.dart";
import "../../../providers/subtask_provider.dart";
import "../../../providers/todo_provider.dart";
import "../../../providers/user_provider.dart";
import "../../../util/constants.dart";
import "../../../util/enums.dart";
import "../../../util/exceptions.dart";
import "../../widgets/flushbars.dart";
import "../../widgets/handle_repeatable_modal.dart";
import "../../widgets/leading_widgets.dart";
import "../../widgets/padded_divider.dart";
import "../../widgets/search_recents_bar.dart";
import "../../widgets/tiles.dart";
import "../../widgets/title_bar.dart";

class UpdateToDoScreen extends StatefulWidget {
  final MapEntry<String, int>? initialGroup;
  final ToDo? initialToDo;

  const UpdateToDoScreen({super.key, this.initialGroup, this.initialToDo});

  @override
  State<UpdateToDoScreen> createState() => _UpdateToDoScreen();
}

class _UpdateToDoScreen extends State<UpdateToDoScreen> {
  late bool checkClose;
  late bool expanded;

  late final UserProvider userProvider;
  late final ToDoProvider toDoProvider;
  late final SubtaskProvider subtaskProvider;
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

  // This is just a convenience method to avoid extra typing
  ToDo get toDo => toDoProvider.curToDo!;

  bool get canAdd =>
      prevToDo.myDay ||
      (userProvider.myDayTotal + toDo.weight <=
          (userProvider.curUser?.bandwidth ?? Constants.maxBandwidth));

  @override
  void initState() {
    super.initState();
    initializeProviders();
    initializeParams();
    initializeControllers();
    resetSubtasks();
    expanded = false;
  }

  void initializeProviders() {
    userProvider = Provider.of<UserProvider>(context, listen: false);
    toDoProvider = Provider.of<ToDoProvider>(context, listen: false);
    subtaskProvider = Provider.of<SubtaskProvider>(context, listen: false);
    groupProvider = Provider.of<GroupProvider>(context, listen: false);

    if (null != widget.initialToDo) {
      toDoProvider.curToDo = widget.initialToDo;
    }

    subtaskProvider.addListener(resetSubtasks);
  }

  @override
  void dispose() {
    nameEditingController.dispose();
    descriptionEditingController.dispose();
    repeatSkipEditingController.dispose();
    mobileScrollController.dispose();
    desktopScrollController.dispose();
    groupEditingController.dispose();
    subtaskProvider.removeListener(resetSubtasks);
    super.dispose();
  }

  Future<void> resetSubtasks() async {
    if (toDo.taskType == TaskType.small) {
      return;
    }
    toDo.subtasks = await toDoProvider.getSubtasks(
        id: toDo.id, limit: Constants.numTasks[toDo.taskType]!);
    toDoProvider.setSubtaskCount(id: toDo.id, count: toDo.subtasks.length);
    toDo.weight = await toDoProvider.getWeight(
        taskID: toDo.id, limit: Constants.numTasks[toDo.taskType]!);
    toDo.realDuration = toDoProvider.calculateRealDuration(
        weight: toDo.weight, duration: toDo.expectedDuration);
    if (mounted) {
      setState(() {});
    }
  }

  void initializeParams() {
    checkClose = false;
    prevToDo = toDo.copy();
    prevToDo.id = toDo.id;

    // Midnight as a start/due time is ambiguous treating as "null".
    showStartTime = null != toDo.startDate;
    showDueTime = null != toDo.dueDate;
  }

  Future<void> initializeControllers() async {
    mobileScrollController = ScrollController();
    desktopScrollController = ScrollController();
    scrollPhysics =
        const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics());

    nameEditingController = TextEditingController(text: toDo.name);
    nameEditingController.addListener(() {
      if (null != nameErrorText && mounted) {
        setState(() {
          nameErrorText = null;
        });
      }
      SemanticsService.announce(
          nameEditingController.text, Directionality.of(context));
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

    descriptionEditingController =
        TextEditingController(text: toDo.description);
    descriptionEditingController.addListener(() {
      String newText = descriptionEditingController.text;
      SemanticsService.announce(newText, Directionality.of(context));
    });

    repeatSkipEditingController =
        TextEditingController(text: toDo.repeatSkip.toString());
    repeatSkipEditingController.addListener(() {
      String newText = descriptionEditingController.text;
      SemanticsService.announce(newText, Directionality.of(context));
    });
  }

  Future<void> handleGroupSelection({required int id}) async {
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

    if (null == toDo.startDate || null == toDo.dueDate) {
      toDo.frequency = Frequency.once;
    }

    if (toDo.frequency == Frequency.custom) {
      if (!toDo.repeatDays.contains(true)) {
        for (int i = 0; i < toDo.repeatDays.length; i++) {
          toDo.repeatDays[i] = prevToDo.repeatDays[i];
        }
      }
    }

    return valid;
  }

  Future<void> handleUpdate() async {
    // in case the usr doesn't submit to the textfields
    toDo.name = nameEditingController.text;
    toDo.description = descriptionEditingController.text;

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

    return await toDoProvider.updateToDo().whenComplete(() {
      if (null != toDo.groupID) {
        groupProvider.setToDoCount(id: toDo.groupID!);
      }
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

    await toDoProvider.deleteToDo(toDo: toDo).whenComplete(() {
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

  Future<void> handleClose({required bool willDiscard}) async {
    if (willDiscard) {
      return await toDoProvider
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

  void updateName() {
    if (mounted) {
      setState(() {
        checkClose = true;
        toDo.name = nameEditingController.text;
      });
    }
  }

  void updateDescription() {
    if (mounted) {
      setState(() {
        checkClose = true;
        toDo.description = descriptionEditingController.text;
      });
    }
  }

  void completeToDo(bool? value) {
    if (mounted) {
      setState(() {
        checkClose = true;
        toDo.completed = value!;
      });
    }
  }

  void handleWeightChange(double? value) {
    if (null == value) {
      return;
    }
    if (mounted) {
      setState(() {
        checkClose = true;
        toDo.weight = value.toInt();
        toDo.realDuration = toDoProvider.calculateRealDuration(
            weight: toDo.weight, duration: toDo.expectedDuration);
      });
    }
  }

  void toggleMyDay() {
    if (mounted) {
      setState(() {
        checkClose = true;
        toDo.myDay = !toDo.myDay;
      });
    }
  }

  void changePriority(Set<Priority> newSelection) {
    if (mounted) {
      setState(() {
        checkClose = true;
        toDo.priority = newSelection.first;
      });
    }
  }

  void updateDuration(int? value) {
    if (mounted) {
      setState(() {
        checkClose = true;
        toDo.expectedDuration = value ?? toDo.expectedDuration;
        toDo.realDuration = toDoProvider.calculateRealDuration(
            weight: toDo.weight, duration: toDo.expectedDuration);
      });
    }
  }

  void clearDuration() {
    if (mounted) {
      setState(() {
        checkClose = true;
        toDo.expectedDuration = 0;
        toDo.realDuration = 0;
      });
    }
  }

  void clearDates() {
    if (mounted) {
      setState(() {
        checkClose = true;
        toDo.startDate = null;
        toDo.dueDate = null;
      });
    }
  }

  void updateDates({bool? checkClose, DateTime? newStart, DateTime? newDue}) {
    if (mounted) {
      setState(() {
        this.checkClose = checkClose ?? this.checkClose;
        toDo.startDate = newStart;
        toDo.dueDate = newDue;
        if (null != toDo.startDate &&
            null != toDo.dueDate &&
            toDo.startDate!.isAfter(toDo.dueDate!)) {
          toDo.startDate = toDo.dueDate!;
        }
      });
    }
  }

  void clearTimes() {
    if (mounted) {
      setState(() {
        checkClose = true;
        showStartTime = false;
        showDueTime = false;
      });
    }
  }

  void updateTimes({bool? checkClose, TimeOfDay? newStart, TimeOfDay? newDue}) {
    if (mounted) {
      setState(() {
        this.checkClose = checkClose ?? this.checkClose;
        toDo.startDate = toDo.startDate
            ?.copyWith(hour: newStart?.hour, minute: newStart?.minute);

        toDo.dueDate =
            toDo.dueDate?.copyWith(hour: newDue?.hour, minute: newDue?.minute);
        showStartTime = null != newStart;
        showDueTime = null != newDue;
      });
    }
  }

  void clearRepeatable() {
    if (mounted) {
      setState(() {
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
      setState(() {
        this.checkClose = checkClose ?? this.checkClose;
        toDo.frequency = newFreq;
        toDo.repeatSkip = newSkip;

        if (newWeekdays.isEmpty) {
          newWeekdays
              .add((toDo.startDate?.weekday ?? DateTime.now().weekday) - 1);
        }
        for (int i = 0; i < toDo.repeatDays.length; i++) {
          toDo.repeatDays[i] = newWeekdays.contains(i);
        }
      });
    }
  }

  // void onDataChange() {
  //   if (mounted) {
  //     setState(() {
  //       checkClose = true;
  //     });
  //   }
  // }

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

    bool showTimeTile = (null != toDo.startDate || null != toDo.dueDate);

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
                                      leading: LeadingWidgets.checkbox(
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
                                      handleClear: clearNameField,
                                      onEditingComplete: updateName),
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
                                      canAdd: canAdd,
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
                                          startTime: (showStartTime)
                                              ? TimeOfDay.fromDateTime(
                                                  toDo.startDate!)
                                              : null,
                                          dueTime: (showDueTime)
                                              ? TimeOfDay.fromDateTime(
                                                  toDo.dueDate!)
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
                                  (null != toDo.dueDate &&
                                          null != toDo.startDate)
                                      ? Tiles.repeatableTile(
                                          context: context,
                                          outerPadding:
                                              const EdgeInsets.symmetric(
                                                  horizontal:
                                                      Constants.padding),
                                          frequency: toDo.frequency,
                                          weekdays: weekdayList,
                                          repeatSkip: toDo.repeatSkip,
                                          startDate: (Constants.nullDate !=
                                                  toDo.startDate)
                                              ? toDo.startDate
                                              : null,
                                          handleUpdate: updateRepeatable,
                                          handleClear: clearRepeatable,
                                        )
                                      : const SizedBox.shrink(),
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
                                    searchController: groupEditingController,
                                    dispose: false,
                                    mostRecent: groupProvider.mostRecent,
                                    search: groupProvider.searchGroups,
                                  ),

                                  (toDo.taskType != TaskType.small)
                                      ? const PaddedDivider(
                                          padding: Constants.padding)
                                      : const SizedBox.shrink(),
                                  // Subtasks
                                  (toDo.taskType != TaskType.small)
                                      ? Tiles.subtasksTile(
                                          context: context,
                                          id: toDo.id,
                                          limit: Constants
                                              .numTasks[toDo.taskType]!,
                                          subtasks: toDo.subtasks,
                                          subtaskCount:
                                              toDoProvider.getSubtaskCount(
                                                  id: toDo.id,
                                                  limit: Constants.numTasks[
                                                      toDo.taskType]!),
                                        )
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
                                    onEditingComplete: updateDescription,
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
                        leading: LeadingWidgets.checkbox(
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
                        handleClear: clearNameField,
                        onEditingComplete: updateName),

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
                        ? Tiles.subtasksTile(
                            context: context,
                            limit: Constants.numTasks[toDo.taskType]!,
                            subtasks: toDo.subtasks,
                            subtaskCount: toDoProvider.getSubtaskCount(
                                id: toDo.id,
                                limit: Constants.numTasks[toDo.taskType]!),
                            id: toDo.id)
                        : const SizedBox.shrink(),

                    const PaddedDivider(padding: Constants.padding),
                    // My Day
                    Tiles.myDayTile(
                        myDay: toDo.myDay,
                        canAdd: canAdd,
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
                      searchController: groupEditingController,
                      dispose: false,
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
                      onEditingComplete: updateDescription,
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
                            startTime: (showStartTime)
                                ? TimeOfDay.fromDateTime(toDo.startDate!)
                                : null,
                            dueTime: (showDueTime)
                                ? TimeOfDay.fromDateTime(toDo.dueDate!)
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
                    (null != toDo.dueDate && null != toDo.startDate)
                        ? Tiles.repeatableTile(
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
                          )
                        : const SizedBox.shrink(),
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
}
