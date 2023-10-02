import "dart:math";

import "package:another_flushbar/flushbar.dart";
import "package:auto_size_text/auto_size_text.dart";
import "package:flutter/material.dart";
import "package:flutter/semantics.dart";
import "package:intl/intl.dart";
import "package:provider/provider.dart";

import "../../../model/task/group.dart";
import "../../../model/task/subtask.dart";
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

class CreateToDoScreen extends StatefulWidget {
  final int? groupID;

  const CreateToDoScreen({Key? key, this.groupID}) : super(key: key);

  @override
  State<CreateToDoScreen> createState() => _CreateToDoScreen();
}

class _CreateToDoScreen extends State<CreateToDoScreen> {
  late bool checkClose;
  late bool expanded;

  // Provider (Needs user values) -> Refactor to DI for testing.
  late final UserProvider userProvider;
  late final ToDoProvider toDoProvider;
  late final GroupProvider groupProvider;

  // Scrolling
  late final ScrollController mainScrollController;
  late final ScrollController subScrollControllerLeft;
  late final ScrollController subScrollControllerRight;
  late final ScrollPhysics scrollPhysics;

  // Param fields.
  late TaskType taskType;

  late String name;
  late final TextEditingController nameEditingController;
  String? nameErrorText;

  // Group -> Tbh, not super sure what to do with this.
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

  late TextEditingController repeatSkipEditingController;
  late int repeatSkip;

  late Set<int> weekdayList;
  late List<bool> weekDays;

  late final List<TextEditingController> subTaskEditingController;
  late final List<SubTask> subTasks;
  late int shownTasks;

  @override
  void initState() {
    super.initState();
    initializeProviders();

    initializeParameters();

    initializeControllers().whenComplete(() {});
  }

  void initializeParameters() {
    // Refactor this into the user provider class.
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

    subTasks = List.generate(Constants.maxNumTasks, (_) => SubTask());
    shownTasks = 0;
    weekdayList = {};
    weekDays = List.generate(7, (_) => false);
    groupID = widget.groupID;
  }

  Future<void> initializeControllers() async {
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

    groupEditingController = SearchController();
    groupProvider
        .getGroupByID(id: groupID)
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

    descriptionEditingController = TextEditingController();
    descriptionEditingController.addListener(() {
      checkClose = true;
      String newText = descriptionEditingController.text;
      SemanticsService.announce(newText, Directionality.of(context));
      description = newText;
    });

    repeatSkipEditingController = TextEditingController();
    repeatSkipEditingController.addListener(() {
      checkClose = true;
      String newText = descriptionEditingController.text;
      SemanticsService.announce(newText, Directionality.of(context));
      repeatSkip = int.tryParse(newText) ?? repeatSkip;
      repeatSkip = max(repeatSkip, 1);
    });

    subTaskEditingController =
        List.generate(subTasks.length, (_) => TextEditingController());

    for (int i = 0; i < subTaskEditingController.length; i++) {
      subTaskEditingController[i].addListener(() {
        checkClose = true;
        String newText = subTaskEditingController[i].text;
        SemanticsService.announce(newText, Directionality.of(context));
      });
    }
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

  void handleGroupSelection({required int id}) {
    // Controller logic
    setState(() {
      checkClose = true;
      groupID = id;
    });
  }

  void handleHistorySelection({
    required MapEntry<String, int> data,
  }) {
    setState(() {
      checkClose = true;
      groupID = data.value;
    });
  }

  bool validateData() {
    bool valid = true;
    if (groupEditingController.text.isEmpty) {
      groupID = widget.groupID;
    }
    if (nameEditingController.text.isEmpty) {
      valid = false;
      setState(() => nameErrorText = "Enter Task Name");
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
    startDate = startDate ?? DateTime.now();
    startTime = startTime ?? Constants.midnight;

    startDate =
        startDate!.copyWith(hour: startTime!.hour, minute: startTime!.minute);

    dueDate = dueDate ?? DateTime.now();
    dueTime = dueTime ?? Constants.midnight;

    dueDate = dueDate!.copyWith(hour: dueTime!.hour, minute: dueTime!.minute);
  }

  Future<void> handleCreate() async {
    mergeDateTimes();

    for (int index in weekdayList) {
      weekDays[index] = true;
    }

    await toDoProvider
        .createToDo(
          groupID: groupID,
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
          repeatDays: weekDays,
          repeatSkip: repeatSkip,
          subTasks: subTasks,
        )
        .whenComplete(() => Navigator.pop(context))
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

  void handleClose({required bool willDiscard}) {
    if (willDiscard) {
      Navigator.pop(context);
    }

    if (mounted) {
      setState(() => checkClose = false);
    }
  }

  void clearNameField() {
    setState(() {
      checkClose = true;
      nameEditingController.clear();
      name = "";
    });
  }

  void handleWeightChange(double value) => setState(() {
        checkClose = true;
        weight = value.toInt();
        realDuration = toDoProvider.calculateRealDuration(
            weight: weight, duration: expectedDuration);
      });

  void removeSubtask({required int index}) {
    setState(() {
      checkClose = true;
      SubTask st = subTasks.removeAt(index);
      st = SubTask();
      subTasks.add(st);
      TextEditingController ct = subTaskEditingController.removeAt(index);
      ct.value = ct.value.copyWith(text: st.name);
      subTaskEditingController.add(ct);

      shownTasks--;
      shownTasks = max(shownTasks, 0);
      sumWeight = toDoProvider.calculateWeight(
          subTasks: List.generate(
              Constants.numTasks[taskType]!, (index) => subTasks[index]));
    });
  }

  void reorderSubtasks(int oldIndex, int newIndex) {
    setState(() {
      checkClose = true;
      if (oldIndex < newIndex) {
        newIndex--;
      }
      SubTask st = subTasks.removeAt(oldIndex);
      subTasks.insert(newIndex, st);
      TextEditingController ct = subTaskEditingController.removeAt(oldIndex);
      subTaskEditingController.insert(newIndex, ct);
    });
  }

  void onDataChange() {
    setState(() {
      checkClose = true;
    });
  }

  void onSubtaskWeightChanged() {
    setState(() {
      checkClose = true;
      sumWeight = toDoProvider.calculateWeight(
          subTasks: List.generate(
              Constants.numTasks[taskType]!, (index) => subTasks[index]));
      realDuration = toDoProvider.calculateRealDuration(
          weight: sumWeight, duration: expectedDuration);
    });
  }

  void addSubTask() {
    setState(() {
      shownTasks++;
      shownTasks = min(shownTasks, Constants.maxNumTasks);
    });
  }

  void toggleMyDay() {
    setState(() {
      checkClose = true;
      myDay = !myDay;
    });
  }

  void changePriority(Set<Priority> newSelection) {
    setState(() {
      checkClose = true;
      priority = newSelection.first;
    });
  }

  void updateDuration(int? value) {
    setState(() {
      checkClose = true;
      expectedDuration = value ?? expectedDuration;
      realDuration = toDoProvider.calculateRealDuration(
          weight: (taskType == TaskType.small) ? weight : sumWeight,
          duration: expectedDuration);
    });
  }

  void clearDuration() {
    setState(() {
      checkClose = true;
      expectedDuration = 0;
      realDuration = 0;
    });
  }

  void clearDates() {
    setState(() {
      checkClose = true;
      startDate = null;
      dueDate = null;
    });
  }

  void updateDates({bool? checkClose, DateTime? newStart, DateTime? newDue}) {
    setState(() {
      this.checkClose = checkClose ?? this.checkClose;
      startDate = newStart;
      dueDate = newDue;

      if (null != startDate &&
          null != dueDate &&
          startDate!.isAfter(dueDate!)) {
        startDate = dueDate;
      }
    });
  }

  void clearTimes() {
    setState(() {
      checkClose = true;
      startTime = null;
      dueTime = null;
    });
  }

  void updateTimes({bool? checkClose, TimeOfDay? newStart, TimeOfDay? newDue}) {
    setState(() {
      this.checkClose = checkClose ?? this.checkClose;
      startTime = newStart;
      dueTime = newDue;
    });
  }

  void clearRepeatable() {
    setState(() {
      checkClose = true;
      frequency = Frequency.once;
      weekdayList.clear();
      repeatSkip = 1;
    });
  }

  void updateRepeatable(
      {bool? checkClose,
      required Frequency newFreq,
      required Set<int> newWeekdays,
      required int newSkip}) {
    setState(() {
      this.checkClose = checkClose ?? this.checkClose;
      frequency = newFreq;
      weekdayList = newWeekdays;
      repeatSkip = newSkip;
    });
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

    bool showTimeTile = (null != startDate || null != dueDate);
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
                  title: "New Task",
                  centerWidget: (expectedDuration > 0)
                      ? TitleBar.toDoCenterWidget(
                          expectedDuration: expectedDuration,
                          realDuration: realDuration)
                      : null,
                  checkClose: checkClose,
                  padding:
                      const EdgeInsets.symmetric(horizontal: Constants.padding),
                  handleClose: handleClose,
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
                                  weight: (taskType == TaskType.small)
                                      ? weight.toDouble()
                                      : sumWeight.toDouble(),
                                  max: (taskType == TaskType.small)
                                      ? Constants.maxTaskWeight.toDouble()
                                      : Constants.maxWeight.toDouble(),
                                  slider: (taskType == TaskType.small)
                                      ? Tiles.weightSlider(
                                          weight: (taskType == TaskType.small)
                                              ? weight.toDouble()
                                              : sumWeight.toDouble(),
                                          handleWeightChange:
                                              handleWeightChange,
                                        )
                                      : null,
                                ),

                                const PaddedDivider(
                                    padding: Constants.innerPadding),
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
                                Padding(
                                  padding: const EdgeInsets.all(
                                      Constants.innerPadding),
                                  child: buildTaskTypeButton(),
                                ),
                                // Subtasks -- Factory Widget. == UH, why does this have padding?
                                (taskType != TaskType.small)
                                    ? buildSubTasksTile(physics: scrollPhysics)
                                    : const SizedBox.shrink(),

                                const PaddedDivider(padding: Constants.padding),
                                // My Day
                                Tiles.myDayTile(
                                    myDay: myDay,
                                    canAdd: (userProvider.myDayTotal + weight <=
                                        (userProvider.curUser?.bandwidth ??
                                            Constants.maxBandwidth)),
                                    toggleMyDay: toggleMyDay),

                                const PaddedDivider(padding: Constants.padding),
                                // Priority
                                Tiles.priorityTile(
                                  context: context,
                                  outerPadding: const EdgeInsets.symmetric(
                                      horizontal: Constants.padding),
                                  priority: priority,
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
                                  expectedDuration: expectedDuration,
                                  context: context,
                                  realDuration: realDuration,
                                  outerPadding: const EdgeInsets.symmetric(
                                      horizontal: Constants.padding),
                                  handleClear: clearDuration,
                                  handleUpdate: updateDuration,
                                ),

                                const PaddedDivider(
                                    padding: Constants.innerPadding),
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
                                const PaddedDivider(
                                    padding: Constants.innerPadding),
                                // Time

                                (showTimeTile)
                                    ? Tiles.timeTile(
                                        outerPadding:
                                            const EdgeInsets.symmetric(
                                                horizontal: Constants.padding),
                                        startTime: startTime,
                                        dueTime: dueTime,
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
                                  frequency: frequency,
                                  weekdayList: weekdayList,
                                  repeatSkip: repeatSkip,
                                  startDate: startDate,
                                  handleUpdate: updateRepeatable,
                                  handleClear: clearRepeatable,
                                ),
                              ]),
                        )
                      ]),
                ),

                const PaddedDivider(padding: Constants.padding),
                Tiles.createButton(
                  outerPadding:
                      const EdgeInsets.symmetric(horizontal: Constants.padding),
                  handleCreate: createAndValidate,
                ),
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
                title: "New Task",
                centerWidget: (expectedDuration > 0)
                    ? TitleBar.toDoCenterWidget(
                        expectedDuration: expectedDuration,
                        realDuration: realDuration)
                    : null,
                checkClose: checkClose,
                padding:
                    const EdgeInsets.symmetric(horizontal: Constants.padding),
                handleClose: handleClose,
              ),
              const PaddedDivider(padding: Constants.padding),
              Expanded(
                flex: 10,
                child: ListView(
                  shrinkWrap: true,
                  controller: mainScrollController,
                  physics: scrollPhysics,
                  children: [
                    Tiles.nameTile(
                        context: context,
                        leading:
                            buildCheckbox(scale: Constants.largeCheckboxScale),
                        hintText: "Task Name",
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
                      weight: (taskType == TaskType.small)
                          ? weight.toDouble()
                          : sumWeight.toDouble(),
                      max: (taskType == TaskType.small)
                          ? Constants.maxTaskWeight.toDouble()
                          : Constants.maxWeight.toDouble(),
                      slider: (taskType == TaskType.small)
                          ? Tiles.weightSlider(
                              weight: (taskType == TaskType.small)
                                  ? weight.toDouble()
                                  : sumWeight.toDouble(),
                              handleWeightChange: handleWeightChange,
                            )
                          : null,
                    ),
                    const PaddedDivider(padding: Constants.innerPadding),
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
                    Padding(
                      padding: const EdgeInsets.all(Constants.innerPadding),
                      child: buildTaskTypeButton(),
                    ),

                    // Subtasks
                    (taskType != TaskType.small)
                        ? buildSubTasksTile(
                            physics: const NeverScrollableScrollPhysics())
                        : const SizedBox.shrink(),

                    const PaddedDivider(padding: Constants.padding),
                    // My Day
                    Tiles.myDayTile(
                        myDay: myDay,
                        canAdd: (userProvider.myDayTotal + weight <=
                            (userProvider.curUser?.bandwidth ??
                                Constants.maxBandwidth)),
                        toggleMyDay: toggleMyDay),

                    const PaddedDivider(padding: Constants.padding),
                    // Priority
                    Tiles.priorityTile(
                      context: context,
                      outerPadding: const EdgeInsets.symmetric(
                          horizontal: Constants.padding),
                      priority: priority,
                      onSelectionChanged: changePriority,
                    ),

                    const Padding(
                      padding:
                          EdgeInsets.symmetric(vertical: Constants.padding),
                      child: PaddedDivider(padding: Constants.innerPadding),
                    ),

                    // Group Picker
                    SearchRecents<Group>(
                      padding: const EdgeInsets.symmetric(
                          horizontal: Constants.padding),
                      searchController: groupEditingController,
                      handleHistorySelection: handleHistorySelection,
                      mostRecent: groupProvider.mostRecent,
                      search: groupProvider.searchGroups,
                      handleDataSelection: handleGroupSelection,
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
                      isDense: true,
                      context: context,
                    ),

                    const PaddedDivider(padding: Constants.innerPadding),
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

                    const PaddedDivider(padding: Constants.innerPadding),
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

                    const PaddedDivider(padding: Constants.innerPadding),
                    // Time
                    (showTimeTile)
                        ? Tiles.timeTile(
                            outerPadding: const EdgeInsets.symmetric(
                                horizontal: Constants.padding),
                            startTime: startTime,
                            dueTime: dueTime,
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
                      frequency: frequency,
                      weekdayList: weekdayList,
                      repeatSkip: repeatSkip,
                      startDate: startDate,
                      handleUpdate: updateRepeatable,
                      handleClear: clearRepeatable,
                    ),
                  ],
                ),
              ),

              const PaddedDivider(padding: Constants.padding),
              Tiles.createButton(
                outerPadding:
                    const EdgeInsets.symmetric(horizontal: Constants.padding),
                handleCreate: createAndValidate,
              ),
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
          "${min(shownTasks, Constants.numTasks[taskType]!)}/${Constants.numTasks[taskType]!} Steps",
          maxLines: 1,
          overflow: TextOverflow.visible,
          softWrap: false,
          minFontSize: Constants.small),
      children: [
        ListViews.reorderableSubtasks(
            context: context,
            subTasks: subTasks,
            itemCount: min(Constants.numTasks[taskType]!, shownTasks),
            controllers: subTaskEditingController,
            onRemoved: removeSubtask,
            onReorder: reorderSubtasks,
            onChanged: onDataChange,
            onSubtaskWeightChanged: onSubtaskWeightChanged,
            showHandle: (shownTasks > 1)),
        (shownTasks < Constants.numTasks[taskType]!)
            ? Tiles.addTile(
                title: "Add a step",
                onTap: addSubTask,
              )
            : const SizedBox.shrink(),
      ],
    );
  }

  SegmentedButton<TaskType> buildTaskTypeButton() {
    return SegmentedButton<TaskType>(
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
                  overflow: TextOverflow.fade,
                )))
            .toList(growable: false),
        selected: <TaskType>{taskType},
        onSelectionChanged: (Set<TaskType> newSelection) {
          TaskType newType = newSelection.first;
          if (taskType != newType) {
            setState(() {
              checkClose = true;
              taskType = newSelection.first;
              realDuration = toDoProvider.calculateRealDuration(
                  weight: (taskType == TaskType.small) ? weight : sumWeight,
                  duration: expectedDuration);
            });
          }
        });
  }

  Widget buildCheckbox({double scale = 1}) {
    return Transform.scale(
        scale: scale,
        child: Checkbox(
            splashRadius: 15,
            value: completed,
            onChanged: (bool? value) => setState(() {
                  checkClose = true;
                  completed = value!;
                }),
            shape: const CircleBorder()));
  }
}
