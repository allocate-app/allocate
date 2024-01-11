import "dart:io";
import "dart:math";

import "package:auto_size_text/auto_size_text.dart";
import "package:flutter/material.dart";
import "package:flutter/semantics.dart";
import "package:intl/intl.dart";
import "package:provider/provider.dart";

import "../../../model/task/group.dart";
import "../../../model/task/subtask.dart";
import "../../../providers/event_provider.dart";
import "../../../providers/group_provider.dart";
import "../../../providers/subtask_provider.dart";
import "../../../providers/todo_provider.dart";
import "../../../providers/user_provider.dart";
import "../../../util/constants.dart";
import "../../../util/enums.dart";
import "../../../util/exceptions.dart";
import "../../widgets/listtile_widgets.dart";
import "../../widgets/padded_divider.dart";
import "../../widgets/search_recents_bar.dart";
import "../../widgets/tiles.dart";
import "../../widgets/title_bar.dart";

class CreateToDoScreen extends StatefulWidget {
  final MapEntry<String, int>? initialGroup;

  const CreateToDoScreen({super.key, this.initialGroup});

  @override
  State<CreateToDoScreen> createState() => _CreateToDoScreen();
}

class _CreateToDoScreen extends State<CreateToDoScreen> {
  late bool checkClose;
  late bool expanded;

  // Provider (Needs user values) -> Refactor to DI for testing.
  late final UserProvider userProvider;
  late final ToDoProvider toDoProvider;
  late final SubtaskProvider subtaskProvider;
  late final GroupProvider groupProvider;
  late final EventProvider eventProvider;

  // Scrolling
  late final ScrollController mobileScrollController;
  late final ScrollController desktopScrollController;
  late final ScrollPhysics scrollPhysics;

  // Subtasks controller
  late final MenuController subtasksAnchorController;

  // Param fields.
  late TaskType taskType;

  late String name;
  late final TextEditingController nameEditingController;
  String? nameErrorText;

  late final SearchController groupEditingController;
  late List<MapEntry<String, int>> searchHistory;
  int? groupID;

  // Description
  late String description;
  late final TextEditingController descriptionEditingController;

  // Weight
  late int weight;

  // Only update this on subtask weight change
  late int sumWeight;

  // ExpectedDuration & Real Duration
  late int expectedDuration;
  late int realDuration;

  late int hours;
  late int minutes;
  late int seconds;

  late Priority priority;

  // Status
  late bool completed;
  late bool myDay;

  // DateTimes
  DateTime? startDate;
  TimeOfDay? startTime;
  DateTime? dueDate;
  TimeOfDay? dueTime;

  // Repeat
  late Frequency frequency;

  late int repeatSkip;

  late Set<int> weekdayList;
  late List<bool> weekdays;

  late List<Subtask> subtasks;
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
    expanded = false;
    taskType = TaskType.small;

    name = "";
    description = "";

    weight = 0;
    sumWeight = 0;

    priority = Priority.low;

    completed = false;
    myDay = false;
    expectedDuration = 0;
    realDuration = 0;

    searchHistory = List.empty(growable: true);

    frequency = Frequency.once;

    repeatSkip = 1;

    shownTasks = 0;
    weekdayList = {};
    weekdays = List.generate(7, (_) => false);
    groupID = widget.initialGroup?.value;
    subtasks = List.empty();
  }

  void initializeControllers() async {
    mobileScrollController = ScrollController();
    desktopScrollController = ScrollController();

    ScrollPhysics parentPhysics = (Platform.isIOS || Platform.isMacOS)
        ? const BouncingScrollPhysics()
        : const ClampingScrollPhysics();
    scrollPhysics = AlwaysScrollableScrollPhysics(parent: parentPhysics);
    nameEditingController = TextEditingController();
    nameEditingController.addListener(() {
      String newText = nameEditingController.text;
      if (null != nameErrorText && mounted) {
        setState(() {
          nameErrorText = null;
        });
      }
      SemanticsService.announce(newText, Directionality.of(context));

      name = newText;
    });

    groupEditingController = SearchController();
    groupEditingController.value = groupEditingController.value
        .copyWith(text: widget.initialGroup?.key ?? "");

    descriptionEditingController = TextEditingController();
    descriptionEditingController.addListener(() {
      String newText = descriptionEditingController.text;
      SemanticsService.announce(newText, Directionality.of(context));
      description = newText;
    });

    subtasksAnchorController = MenuController();
  }

  void initializeProviders() {
    userProvider = Provider.of<UserProvider>(context, listen: false);
    toDoProvider = Provider.of<ToDoProvider>(context, listen: false);
    subtaskProvider = Provider.of<SubtaskProvider>(context, listen: false);
    groupProvider = Provider.of<GroupProvider>(context, listen: false);
    eventProvider = Provider.of<EventProvider>(context, listen: false);

    subtaskProvider.addListener(resetSubtasks);
  }

  @override
  void dispose() {
    nameEditingController.dispose();
    descriptionEditingController.dispose();
    mobileScrollController.dispose();
    desktopScrollController.dispose();
    groupEditingController.dispose();
    subtaskProvider.removeListener(resetSubtasks);
    super.dispose();
  }

  Future<void> resetSubtasks() async {
    if (taskType == TaskType.small) {
      return;
    }
    List<Subtask> newSubtasks = await toDoProvider.getSubtasks(
        id: Constants.intMax, limit: Constants.numTasks[taskType]!);

    if (!(userProvider.curUser?.reduceMotion ?? false)) {
      onFetch(items: newSubtasks);
    }

    subtasks = newSubtasks;
    toDoProvider.setSubtaskCount(id: Constants.intMax, count: subtasks.length);
    sumWeight = await toDoProvider.getWeight(
        taskID: Constants.intMax, limit: Constants.numTasks[taskType]!);
    realDuration = toDoProvider.calculateRealDuration(
        weight: sumWeight, duration: expectedDuration);

    subtaskProvider.rebuild = false;

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> handleGroupSelection({required int id}) async {
    if (mounted) {
      setState(() {
        checkClose = userProvider.curUser?.checkClose ?? true;
        groupID = id;
      });
    }
  }

  bool validateData() {
    bool valid = true;
    if (groupEditingController.text.isEmpty) {
      groupID = null;
    }
    if (nameEditingController.text.isEmpty) {
      valid = false;
      if (mounted) {
        setState(() => nameErrorText = "Enter Task Name");
      }
    }

    if (null == startDate || null == dueDate) {
      frequency = Frequency.once;
    }

    if (frequency == Frequency.custom) {
      if (weekdayList.isEmpty) {
        weekdayList
            .add(min(((startDate?.weekday ?? DateTime.now().weekday) - 1), 0));
      }
    }

    return valid;
  }

  void mergeDateTimes() {
    startDate = startDate?.copyWith(
        hour: startTime?.hour ?? 0,
        minute: startTime?.minute ?? 0,
        second: 0,
        millisecond: 0,
        microsecond: 0);

    dueDate = dueDate?.copyWith(
        hour: dueTime?.hour ?? 0,
        minute: dueTime?.minute ?? 0,
        second: 0,
        millisecond: 0,
        microsecond: 0);
  }

  Future<void> handleCreate() async {
    for (int index in weekdayList) {
      weekdays[index] = true;
    }

    await toDoProvider
        .createToDo(
          groupID: groupID,
          groupIndex: groupProvider.getToDoCount(id: groupID)?.value,
          taskType: taskType,
          name: name,
          description: description,
          weight: (taskType == TaskType.small) ? weight : sumWeight,
          expectedDuration: expectedDuration,
          realDuration: realDuration,
          priority: priority,
          startDate: startDate,
          dueDate: dueDate,
          myDay: myDay,
          completed: completed,
          repeatable: frequency != Frequency.once,
          frequency: frequency,
          repeatDays: weekdays,
          repeatSkip: repeatSkip,
          subtasks: subtasks,
        )
        .catchError((e) => Tiles.displayError(context: context, e: e),
            test: (e) =>
                e is FailureToCreateException || e is FailureToUploadException);

    if (null != groupID) {
      groupProvider.setToDoCount(id: groupID!);
    }

    await eventProvider
        .insertEventModel(model: toDoProvider.curToDo!, notify: true)
        .whenComplete(
          () => Navigator.pop(context),
        );
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
      setState(() => checkClose = false);
    }
  }

  void clearNameField() {
    if (mounted) {
      setState(() {
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

  void updateDescription() {
    if (mounted) {
      setState(() {
        checkClose = userProvider.curUser?.checkClose ?? true;
        description = descriptionEditingController.text;
      });
    }
  }

  void completeToDo(bool? value) {
    if (mounted) {
      setState(() {
        checkClose = userProvider.curUser?.checkClose ?? true;
        completed = value!;
      });
    }
  }

  void handleWeightChange(double? value) {
    if (null == value) {
      return;
    }
    if (mounted) {
      setState(() {
        checkClose = userProvider.curUser?.checkClose ?? true;
        weight = value.toInt();
        realDuration = toDoProvider.calculateRealDuration(
            weight: weight, duration: expectedDuration);
      });
    }
  }

  void toggleMyDay() {
    if (mounted) {
      setState(() {
        checkClose = userProvider.curUser?.checkClose ?? true;
        myDay = !myDay;
      });
    }
  }

  void changePriority(Set<Priority> newSelection) {
    if (mounted) {
      setState(() {
        checkClose = userProvider.curUser?.checkClose ?? true;
        priority = newSelection.first;
      });
    }
  }

  void updateDuration(int? value) {
    if (mounted) {
      setState(() {
        checkClose = userProvider.curUser?.checkClose ?? true;
        expectedDuration = value ?? expectedDuration;
        realDuration = toDoProvider.calculateRealDuration(
            weight: (taskType == TaskType.small) ? weight : sumWeight,
            duration: expectedDuration);
      });
    }
  }

  void clearDuration() {
    if (mounted) {
      setState(() {
        checkClose = userProvider.curUser?.checkClose ?? true;
        expectedDuration = 0;
        realDuration = 0;
      });
    }
  }

  void clearDates() {
    if (mounted) {
      setState(() {
        checkClose = userProvider.curUser?.checkClose ?? true;
        startDate = null;
        dueDate = null;
      });
    }
  }

  void updateDates({bool? checkClose, DateTime? newStart, DateTime? newDue}) {
    if (mounted) {
      setState(() {
        checkClose = checkClose ?? this.checkClose;
        this.checkClose = (checkClose!)
            ? userProvider.curUser?.checkClose ?? checkClose!
            : checkClose!;
        startDate = newStart;
        dueDate = newDue;

        if (null != startDate &&
            null != dueDate &&
            startDate!.isAfter(dueDate!)) {
          startDate = dueDate;
        }
      });
    }
  }

  void clearTimes() {
    if (mounted) {
      setState(() {
        checkClose = userProvider.curUser?.checkClose ?? true;
        startTime = null;
        dueTime = null;
      });
    }
  }

  void updateTimes({bool? checkClose, TimeOfDay? newStart, TimeOfDay? newDue}) {
    if (mounted) {
      setState(() {
        checkClose = checkClose ?? this.checkClose;
        this.checkClose = (checkClose!)
            ? userProvider.curUser?.checkClose ?? checkClose!
            : checkClose!;
        startTime = newStart;
        dueTime = newDue;
      });
    }
  }

  void clearRepeatable() {
    if (mounted) {
      setState(() {
        checkClose = userProvider.curUser?.checkClose ?? true;
        frequency = Frequency.once;
        weekdayList.clear();
        repeatSkip = 1;
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
        checkClose = checkClose ?? this.checkClose;
        this.checkClose = (checkClose!)
            ? userProvider.curUser?.checkClose ?? checkClose!
            : checkClose!;
        frequency = newFreq;
        weekdayList = newWeekdays;
        repeatSkip = newSkip;
      });
    }
  }

  Future<void> createAndValidate() async {
    mergeDateTimes();
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
    // The query still needs to be performed to force a build.
    MediaQuery.sizeOf(context);

    bool showTimeTile = null != startDate || null != dueDate;
    bool showRepeatTile = null != dueDate && null != startDate;
    return (userProvider.largeScreen)
        ? buildDesktopDialog(
            context: context,
            showTimeTile: showTimeTile,
            showRepeatTile: showRepeatTile,
          )
        : buildMobileDialog(
            context: context,
            showTimeTile: showTimeTile,
            showRepeatTile: showRepeatTile,
            smallScreen: userProvider.smallScreen);
  }

  Dialog buildDesktopDialog({
    required BuildContext context,
    bool showTimeTile = false,
    bool showRepeatTile = false,
  }) {
    return Dialog(
      insetPadding: const EdgeInsets.all(Constants.outerDialogPadding),
      child: Padding(
        padding: const EdgeInsets.all(Constants.padding),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          // Title && Close Button
          TitleBar(
            currentContext: context,
            title: "New Task",
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
                                    Tiles.nameTile(
                                        context: context,
                                        leading: ListTileWidgets.checkbox(
                                          scale: Constants.largeCheckboxScale,
                                          completed: completed,
                                          onChanged: completeToDo,
                                        ),
                                        hintText: "Task Name",
                                        errorText: nameErrorText,
                                        controller: nameEditingController,
                                        outerPadding:
                                            const EdgeInsets.symmetric(
                                                vertical: Constants.padding),
                                        textFieldPadding: const EdgeInsets.only(
                                          left: Constants.padding,
                                        ),
                                        handleClear: clearNameField,
                                        onEditingComplete: updateName),
                                    Tiles.weightTile(
                                      outerPadding: const EdgeInsets.all(
                                          Constants.doublePadding),
                                      batteryPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal:
                                                  Constants.doublePadding),
                                      constraints: const BoxConstraints(
                                        maxWidth: 200,
                                      ),
                                      weight: (taskType == TaskType.small)
                                          ? weight.toDouble()
                                          : sumWeight.toDouble(),
                                      max: switch (taskType) {
                                        TaskType.small =>
                                          Constants.maxTaskWeight.toDouble(),
                                        TaskType.large =>
                                          Constants.medianWeight.toDouble(),
                                        TaskType.huge =>
                                          Constants.maxWeight.toDouble(),
                                      },
                                      slider: (taskType == TaskType.small)
                                          ? Tiles.weightSlider(
                                              weight: weight.toDouble(),
                                              handleWeightChange:
                                                  handleWeightChange,
                                            )
                                          : null,
                                    ),

                                    const PaddedDivider(
                                        padding: Constants.padding),
                                    // My Day
                                    Tiles.myDayTile(
                                        myDay: myDay,
                                        canAdd:
                                            (userProvider.myDayTotal + weight <=
                                                (toDoProvider.user?.bandwidth ??
                                                    Constants.maxBandwidth)),
                                        toggleMyDay: toggleMyDay),

                                    const PaddedDivider(
                                        padding: Constants.padding),
                                    // Priority
                                    Tiles.priorityTile(
                                      context: context,
                                      outerPadding: const EdgeInsets.symmetric(
                                          horizontal: Constants.padding),
                                      priority: priority,
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
                                      expectedDuration: expectedDuration,
                                      context: context,
                                      realDuration: realDuration,
                                      outerPadding: const EdgeInsets.symmetric(
                                          horizontal: Constants.padding),
                                      handleClear: clearDuration,
                                      handleUpdate: updateDuration,
                                    ),

                                    const PaddedDivider(
                                        padding: Constants.padding),
                                    // DateTime -> Show status, on click, open a dialog.
                                    //startDate
                                    Tiles.dateRangeTile(
                                      context: context,
                                      outerPadding: const EdgeInsets.symmetric(
                                          horizontal: Constants.padding),
                                      startDate: startDate,
                                      dueDate: dueDate,
                                      handleClear: clearDates,
                                      handleUpdate: updateDates,
                                    ),
                                    // Time
                                    if (showTimeTile) ...[
                                      const PaddedDivider(
                                          padding: Constants.padding),
                                      Tiles.timeTile(
                                        outerPadding:
                                            const EdgeInsets.symmetric(
                                                horizontal: Constants.padding),
                                        startTime: startTime,
                                        dueTime: dueTime,
                                        context: context,
                                        handleClear: clearTimes,
                                        handleUpdate: updateTimes,
                                      ),
                                    ],

                                    // Repeatable Stuff -> Show status, on click, open a dialog.
                                    if (showRepeatTile) ...[
                                      const PaddedDivider(
                                          padding: Constants.padding),
                                      Tiles.repeatableTile(
                                        context: context,
                                        outerPadding:
                                            const EdgeInsets.symmetric(
                                                horizontal: Constants.padding),
                                        frequency: frequency,
                                        weekdays: weekdayList,
                                        repeatSkip: repeatSkip,
                                        startDate: startDate,
                                        handleUpdate: updateRepeatable,
                                        handleClear: clearRepeatable,
                                      ),
                                    ],
                                  ]),
                            ),
                            Flexible(
                              child: ListView(
                                  physics: const NeverScrollableScrollPhysics(),
                                  shrinkWrap: true,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: Constants.halfPadding),
                                  children: [
                                    SearchRecentsBar<Group>(
                                      persistentEntry: widget.initialGroup,
                                      hintText: "Search Groups",
                                      padding: const EdgeInsets.all(
                                          Constants.padding),
                                      handleDataSelection: handleGroupSelection,
                                      searchController: groupEditingController,
                                      dispose: false,
                                      mostRecent: groupProvider.mostRecent,
                                      search: groupProvider.searchGroups,
                                    ),

                                    const PaddedDivider(
                                        padding: Constants.padding),
                                    // TaskType
                                    const Row(children: [
                                      Expanded(
                                        child: AutoSizeText("Task Type",
                                            maxLines: 1,
                                            softWrap: true,
                                            textAlign: TextAlign.center,
                                            minFontSize: Constants.medium,
                                            style: Constants.headerStyle),
                                      )
                                    ]),
                                    buildTaskTypeButton(),
                                    // Subtasks -- Factory Widget.
                                    if (taskType != TaskType.small) ...[
                                      const PaddedDivider(
                                          padding: Constants.padding),
                                      Tiles.subtasksTile(
                                          context: context,
                                          id: Constants.intMax,
                                          limit: Constants.numTasks[taskType]!,
                                          subtasksAnchorController:
                                              subtasksAnchorController,
                                          onAnchorOpen: onAnchorOpen,
                                          onAnchorClose: onAnchorClose,
                                          onRemove: (userProvider
                                                      .curUser?.reduceMotion ??
                                                  false)
                                              ? null
                                              : onRemove,
                                          subtasks: subtasks,
                                          subtaskCount:
                                              toDoProvider.getSubtaskCount(
                                                  id: Constants.intMax,
                                                  limit: Constants
                                                      .numTasks[taskType]!))
                                    ],

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
                          ]),
                    ]),
              ),
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
      {required BuildContext context,
      bool smallScreen = false,
      bool showTimeTile = false,
      bool showRepeatTile = false}) {
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
                title: "New Task",
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
                        leading: ListTileWidgets.checkbox(
                          scale: Constants.largeCheckboxScale,
                          completed: completed,
                          onChanged: completeToDo,
                        ),
                        hintText: "Task Name",
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
                      weight: (taskType == TaskType.small)
                          ? weight.toDouble()
                          : sumWeight.toDouble(),
                      max: switch (taskType) {
                        TaskType.small => Constants.maxTaskWeight.toDouble(),
                        TaskType.large => Constants.medianWeight.toDouble(),
                        TaskType.huge => Constants.maxWeight.toDouble(),
                      },
                      slider: (taskType == TaskType.small)
                          ? Tiles.weightSlider(
                              weight: weight.toDouble(),
                              handleWeightChange: handleWeightChange,
                            )
                          : null,
                    ),
                    const PaddedDivider(padding: Constants.padding),
                    // TaskType -- This is only one-screen.
                    const Row(children: [
                      Expanded(
                        child: AutoSizeText("Task Type",
                            maxLines: 1,
                            softWrap: true,
                            textAlign: TextAlign.center,
                            minFontSize: Constants.medium,
                            style: Constants.headerStyle),
                      )
                    ]),
                    buildTaskTypeButton(),

                    // Subtasks
                    if (taskType != TaskType.small) ...[
                      const PaddedDivider(padding: Constants.padding),
                      Tiles.subtasksTile(
                          context: context,
                          subtasksAnchorController: subtasksAnchorController,
                          onAnchorOpen: onAnchorOpen,
                          onAnchorClose: onAnchorClose,
                          onRemove:
                              (userProvider.curUser?.reduceMotion ?? false)
                                  ? null
                                  : onRemove,
                          limit: Constants.numTasks[taskType]!,
                          subtasks: subtasks,
                          subtaskCount: toDoProvider.getSubtaskCount(
                              id: Constants.intMax,
                              limit: Constants.numTasks[taskType]!),
                          id: Constants.intMax),
                    ],

                    const PaddedDivider(padding: Constants.padding),
                    // My Day
                    Tiles.myDayTile(
                        myDay: myDay,
                        canAdd: (userProvider.myDayTotal + weight <=
                            (toDoProvider.user?.bandwidth ??
                                Constants.maxBandwidth)),
                        toggleMyDay: toggleMyDay),

                    const PaddedDivider(padding: Constants.padding),
                    // Priority
                    Tiles.priorityTile(
                      mobile: smallScreen,
                      context: context,
                      outerPadding: const EdgeInsets.symmetric(
                          horizontal: Constants.padding),
                      priority: priority,
                      onSelectionChanged: changePriority,
                    ),

                    const Padding(
                      padding:
                          EdgeInsets.symmetric(vertical: Constants.padding),
                      child: PaddedDivider(padding: Constants.padding),
                    ),

                    // Group Picker
                    SearchRecentsBar<Group>(
                      hintText: "Search Groups",
                      padding: const EdgeInsets.symmetric(
                          horizontal: Constants.padding),
                      searchController: groupEditingController,
                      dispose: false,
                      mostRecent: groupProvider.mostRecent,
                      search: groupProvider.searchGroups,
                      handleDataSelection: handleGroupSelection,
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
                        isDense: true,
                        context: context,
                        onEditingComplete: updateDescription),

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
                    // DateTime -> Show status, on click, open a dialog.
                    //startDate
                    Tiles.dateRangeTile(
                      context: context,
                      outerPadding: const EdgeInsets.symmetric(
                          horizontal: Constants.padding),
                      startDate: startDate,
                      dueDate: dueDate,
                      handleClear: clearDates,
                      handleUpdate: updateDates,
                    ),

                    // Time
                    if (showTimeTile) ...[
                      const PaddedDivider(padding: Constants.padding),
                      Tiles.timeTile(
                        outerPadding: const EdgeInsets.symmetric(
                            horizontal: Constants.padding),
                        startTime: startTime,
                        dueTime: dueTime,
                        context: context,
                        handleClear: clearTimes,
                        handleUpdate: updateTimes,
                      ),
                    ],

                    // Repeatable Stuff -> Show status, on click, open a dialog.
                    if (showRepeatTile) ...[
                      const PaddedDivider(padding: Constants.padding),
                      Tiles.repeatableTile(
                        context: context,
                        outerPadding: const EdgeInsets.symmetric(
                            horizontal: Constants.padding),
                        frequency: frequency,
                        weekdays: weekdayList,
                        repeatSkip: repeatSkip,
                        startDate: startDate,
                        handleUpdate: updateRepeatable,
                        handleClear: clearRepeatable,
                      ),
                    ],
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

  Widget buildTaskTypeButton() {
    return Padding(
      padding: const EdgeInsets.all(Constants.padding),
      child: SegmentedButton<TaskType>(
          style: ButtonStyle(
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.adaptivePlatformDensity,
            side: MaterialStatePropertyAll<BorderSide>(BorderSide(
              width: 2,
              color: Theme.of(context).colorScheme.outlineVariant,
            )),
          ),
          segments: TaskType.values
              .map((TaskType type) => ButtonSegment<TaskType>(
                  value: type,
                  label: Text(
                    "${toBeginningOfSentenceCase(type.name)}",
                    softWrap: false,
                    overflow: TextOverflow.visible,
                  )))
              .toList(growable: false),
          selected: <TaskType>{taskType},
          onSelectionChanged: (Set<TaskType> newSelection) {
            TaskType newType = newSelection.first;
            if (taskType != newType) {
              if (mounted) {
                setState(() {
                  checkClose = userProvider.curUser?.checkClose ?? true;
                  taskType = newSelection.first;
                  realDuration = toDoProvider.calculateRealDuration(
                      weight: (taskType == TaskType.small) ? weight : sumWeight,
                      duration: expectedDuration);
                });
              }
            }
          }),
    );
  }
}
