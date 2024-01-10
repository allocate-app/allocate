import "dart:io";
import "dart:math";

import "package:another_flushbar/flushbar.dart";
import "package:flutter/material.dart";
import "package:flutter/semantics.dart";
import "package:provider/provider.dart";

import "../../../model/task/group.dart";
import "../../../model/task/subtask.dart";
import "../../../model/task/todo.dart";
import "../../../providers/event_provider.dart";
import "../../../providers/group_provider.dart";
import "../../../providers/subtask_provider.dart";
import "../../../providers/todo_provider.dart";
import "../../../providers/user_provider.dart";
import "../../../util/constants.dart";
import "../../../util/enums.dart";
import "../../../util/exceptions.dart";
import "../../widgets/flushbars.dart";
import "../../widgets/handle_repeatable_modal.dart";
import "../../widgets/listtile_widgets.dart";
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
  late bool _checkRepeating;
  late bool expanded;
  late bool _projection;
  late ValueNotifier<int> _projectionSubtaskCount;

  late final UserProvider userProvider;
  late final ToDoProvider toDoProvider;
  late final SubtaskProvider subtaskProvider;
  late final GroupProvider groupProvider;
  late final EventProvider eventProvider;

  // Cache for repeating events & discard
  late final ToDo prevToDo;

  // For showing times.
  late bool showStartTime;
  late bool showDueTime;

  // Scrolling
  late final ScrollController mobileScrollController;
  late final ScrollController desktopScrollController;
  late final ScrollPhysics scrollPhysics;

  // Subtasks controller
  late final MenuController subtasksAnchorController;

  // Name
  late final TextEditingController nameEditingController;
  String? nameErrorText;

  // Group
  late final SearchController groupEditingController;

  // Description
  late final TextEditingController descriptionEditingController;

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
    initializeParameters();
    initializeControllers();
    resetSubtasks();
    expanded = false;
  }

  void initializeProviders() {
    userProvider = Provider.of<UserProvider>(context, listen: false);
    toDoProvider = Provider.of<ToDoProvider>(context, listen: false);
    subtaskProvider = Provider.of<SubtaskProvider>(context, listen: false);
    groupProvider = Provider.of<GroupProvider>(context, listen: false);

    eventProvider = Provider.of<EventProvider>(context, listen: false);

    if (null != widget.initialToDo) {
      toDoProvider.curToDo = widget.initialToDo;
    }

    _projection = toDo.repeatableState == RepeatableState.projected;
    if (_projection) {
      _projectionSubtaskCount = ValueNotifier(toDo.subtasks.length);
    }

    // Only add the listener when there are subtasks to grab.
    // Projected events have the subtasks in memory.
    if (!_projection) {
      subtaskProvider.addListener(resetSubtasks);
    }
  }

  @override
  void dispose() {
    nameEditingController.dispose();
    descriptionEditingController.dispose();
    mobileScrollController.dispose();
    desktopScrollController.dispose();
    groupEditingController.dispose();

    if (!_projection) {
      subtaskProvider.removeListener(resetSubtasks);
    }
    super.dispose();
  }

  Future<void> resetSubtasks() async {
    if (toDo.taskType == TaskType.small) {
      return;
    }
    List<Subtask> newSubtasks = await toDoProvider.getSubtasks(
        id: toDo.id, limit: Constants.numTasks[toDo.taskType]!);

    if (!(userProvider.curUser?.reduceMotion ?? false)) {
      onFetch(items: newSubtasks);
    }

    toDo.subtasks = newSubtasks;
    toDoProvider.setSubtaskCount(id: toDo.id, count: toDo.subtasks.length);
    toDo.weight = await toDoProvider.getWeight(
        taskID: toDo.id, limit: Constants.numTasks[toDo.taskType]!);
    toDo.realDuration = toDoProvider.calculateRealDuration(
        weight: toDo.weight, duration: toDo.expectedDuration);
    if (mounted) {
      setState(() {});
    }
  }

  void initializeParameters() {
    checkClose = false;
    _checkRepeating = false;
    prevToDo = toDo.copy();
    prevToDo.id = toDo.id;

    // Midnight as a start/due time is ambiguous treating as "null".
    showStartTime = null != toDo.startDate;
    showDueTime = null != toDo.dueDate;
  }

  Future<void> initializeControllers() async {
    mobileScrollController = ScrollController();
    desktopScrollController = ScrollController();
    ScrollPhysics parentPhysics = (Platform.isIOS || Platform.isMacOS)
        ? const BouncingScrollPhysics()
        : const ClampingScrollPhysics();
    scrollPhysics = AlwaysScrollableScrollPhysics(parent: parentPhysics);

    nameEditingController = TextEditingController(text: toDo.name);
    nameEditingController.addListener(() {
      _checkRepeating = true;
      String newText = nameEditingController.text;
      SemanticsService.announce(newText, Directionality.of(context));
      toDo.name = newText;
      if (null != nameErrorText && mounted) {
        setState(() {
          nameErrorText = null;
        });
      }
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
      _checkRepeating = true;
      String newText = descriptionEditingController.text;
      SemanticsService.announce(newText, Directionality.of(context));
      toDo.description = newText;
    });

    subtasksAnchorController = MenuController();
  }

  Future<void> handleGroupSelection({required int id}) async {
    setState(() {
      checkClose = userProvider.curUser?.checkClose ?? true;
      _checkRepeating = true;
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
    if (prevToDo.frequency != Frequency.once && _checkRepeating) {
      bool? updateSingle = await showModalBottomSheet<bool?>(
          showDragHandle: true,
          context: context,
          builder: (BuildContext context) {
            return const HandleRepeatableModal(action: "Update");
          });

      if (null == updateSingle) {
        return;
      }
      await toDoProvider
          .handleRepeating(toDo: prevToDo, single: updateSingle, delete: false)
          .catchError((e) => Tiles.displayError(context: context, e: e),
              test: (e) =>
                  e is FailureToUpdateException ||
                  e is FailureToUploadException ||
                  e is InvalidRepeatingException ||
                  e is FailureToDeleteException);

      if (RepeatableState.projected == toDo.repeatableState) {
        return await eventProvider
            .updateRepeating(model: toDo)
            .whenComplete(() => Navigator.pop(context));
      }
      return await eventProvider
          .updateEventModel(oldModel: prevToDo, newModel: toDo)
          .whenComplete(() => Navigator.pop(context));
    }
    await toDoProvider.updateToDo(toDo: toDo).catchError(
        (e) => Tiles.displayError(context: context, e: e),
        test: (e) =>
            e is FailureToUpdateException || e is FailureToUploadException);

    return await eventProvider
        .updateEventModel(oldModel: prevToDo, newModel: toDo)
        .whenComplete(() => Navigator.pop(context));
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
      await toDoProvider
          .handleRepeating(toDo: prevToDo, single: deleteSingle, delete: true)
          .catchError((e) => Tiles.displayError(context: context, e: e),
              test: (e) =>
                  e is InvalidRepeatingException ||
                  e is FailureToUpdateException ||
                  e is FailureToUploadException ||
                  e is FailureToDeleteException);

      if (RepeatableState.projected == toDo.repeatableState) {
        return await eventProvider
            .updateRepeating(model: toDo)
            .whenComplete(() => Navigator.pop(context));
      }

      // TODO: this is not working atm. Just clear the key.
      // Write a method to clear it.
      if (toDo.repeatable) {
        await eventProvider.updateRepeating(model: toDo);
      }
      return await eventProvider
          .updateEventModel(oldModel: prevToDo)
          .whenComplete(() => Navigator.pop(context));
    }

    await toDoProvider.deleteToDo(toDo: toDo).whenComplete(() {
      Navigator.pop(context);
    }).catchError((e) => Tiles.displayError(context: context, e: e),
        test: (e) => e is FailureToDeleteException);
  }

  Future<void> handleClose({required bool willDiscard}) async {
    if (willDiscard) {
      toDoProvider.rebuild = true;
      Navigator.pop(context);
    }

    if (mounted) {
      setState(() => checkClose = false);
    }
  }

  void clearNameField() {
    if (mounted) {
      setState(() {
        checkClose = userProvider.curUser?.checkClose ?? true;
        _checkRepeating = true;
        nameEditingController.clear();
        toDo.name = "";
      });
    }
  }

  void updateName() {
    if (mounted) {
      setState(() {
        checkClose = userProvider.curUser?.checkClose ?? true;
        _checkRepeating = true;
        toDo.name = nameEditingController.text;
      });
    }
  }

  void updateDescription() {
    if (mounted) {
      setState(() {
        checkClose = userProvider.curUser?.checkClose ?? true;
        _checkRepeating = true;
        toDo.description = descriptionEditingController.text;
      });
    }
  }

  void completeToDo(bool? value) {
    if (mounted) {
      setState(() {
        checkClose = userProvider.curUser?.checkClose ?? true;
        _checkRepeating = true;
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
        checkClose = userProvider.curUser?.checkClose ?? true;
        _checkRepeating = true;
        toDo.weight = value.toInt();
        toDo.realDuration = toDoProvider.calculateRealDuration(
            weight: toDo.weight, duration: toDo.expectedDuration);
      });
    }
  }

  void toggleMyDay() {
    if (mounted) {
      setState(() {
        checkClose = userProvider.curUser?.checkClose ?? true;
        _checkRepeating = true;
        toDo.myDay = !toDo.myDay;
      });
    }
  }

  void changePriority(Set<Priority> newSelection) {
    if (mounted) {
      setState(() {
        checkClose = userProvider.curUser?.checkClose ?? true;
        _checkRepeating = true;
        toDo.priority = newSelection.first;
      });
    }
  }

  void updateDuration(int? value) {
    if (mounted) {
      setState(() {
        checkClose = userProvider.curUser?.checkClose ?? true;
        _checkRepeating = true;
        toDo.expectedDuration = value ?? toDo.expectedDuration;
        toDo.realDuration = toDoProvider.calculateRealDuration(
            weight: toDo.weight, duration: toDo.expectedDuration);
      });
    }
  }

  void clearDuration() {
    if (mounted) {
      setState(() {
        checkClose = userProvider.curUser?.checkClose ?? true;
        _checkRepeating = true;
        toDo.expectedDuration = 0;
        toDo.realDuration = 0;
      });
    }
  }

  void clearDates() {
    if (mounted) {
      setState(() {
        checkClose = userProvider.curUser?.checkClose ?? true;
        _checkRepeating = true;
        toDo.startDate = null;
        toDo.dueDate = null;
      });
    }
  }

  void updateDates({bool? checkClose, DateTime? newStart, DateTime? newDue}) {
    if (mounted) {
      setState(() {
        checkClose = checkClose ?? this.checkClose;
        _checkRepeating = true;
        this.checkClose = (checkClose!)
            ? userProvider.curUser?.checkClose ?? checkClose!
            : checkClose!;
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
        checkClose = userProvider.curUser?.checkClose ?? true;
        _checkRepeating = true;
        showStartTime = false;
        showDueTime = false;
      });
    }
  }

  void updateTimes({bool? checkClose, TimeOfDay? newStart, TimeOfDay? newDue}) {
    if (mounted) {
      setState(() {
        checkClose = checkClose ?? this.checkClose;
        _checkRepeating = true;
        this.checkClose = (checkClose!)
            ? userProvider.curUser?.checkClose ?? checkClose!
            : checkClose!;
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
        checkClose = userProvider.curUser?.checkClose ?? true;
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
        checkClose = checkClose ?? this.checkClose;
        this.checkClose = (checkClose!)
            ? userProvider.curUser?.checkClose ?? checkClose!
            : checkClose!;
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
    // in case the usr doesn't submit to the textfields
    toDo.name = nameEditingController.text;
    toDo.description = descriptionEditingController.text;
    if (validateData()) {
      await handleUpdate();
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

  // Projected only
  // Internal "deal with repeating event deltas subtasks" methods.
  void onReorder(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex--;
    }
    Subtask subtask = toDo.subtasks.removeAt(oldIndex);
    toDo.subtasks.insert(newIndex, subtask);
    if (mounted) {
      setState(() {});
    }
  }

  void onSubtaskRemoved({Subtask? subtask}) {
    if (null == subtask) {
      return;
    }

    toDo.subtasks.remove(subtask);
    _projectionSubtaskCount.value = max(_projectionSubtaskCount.value - 1, 0);

    if (mounted) {
      setState(() {});
    }
  }

  void onSubtaskChanged({Subtask? subtask, bool? value}) {
    if (null == subtask || null == value) {
      return;
    }
    subtask.completed = value;
    if (mounted) {
      setState(() {});
    }
  }

  void onSubtaskSubmit({Subtask? subtask}) {
    if (null == subtask) {
      return;
    }
    toDo.subtasks.add(subtask);
    _projectionSubtaskCount.value += 1;
    if (mounted) {
      setState(() {});
    }
  }

  void handleSubtaskUpdate({Subtask? subtask}) {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    MediaQuery.sizeOf(context);

    bool showTimeTile = null != toDo.startDate || null != toDo.dueDate;
    bool showRepeatTile = null != toDo.startDate && null != toDo.dueDate;

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
                                      leading: ListTileWidgets.checkbox(
                                        scale: Constants.largeCheckboxScale,
                                        completed: toDo.completed,
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
                                    outerPadding: const EdgeInsets.all(
                                        Constants.doublePadding),
                                    batteryPadding: const EdgeInsets.symmetric(
                                        horizontal: Constants.doublePadding),
                                    constraints:
                                        const BoxConstraints(maxWidth: 200),
                                    weight: toDo.weight.toDouble(),
                                    max: switch (toDo.taskType) {
                                      TaskType.small =>
                                        Constants.maxTaskWeight.toDouble(),
                                      TaskType.large =>
                                        Constants.medianWeight.toDouble(),
                                      TaskType.huge =>
                                        Constants.maxWeight.toDouble(),
                                    },
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

                                  // Time
                                  if (showTimeTile) ...[
                                    const PaddedDivider(
                                        padding: Constants.padding),
                                    Tiles.timeTile(
                                      outerPadding: const EdgeInsets.symmetric(
                                          horizontal: Constants.padding),
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
                                    ),
                                  ],

                                  // Repeatable Stuff -> Show status, on click, open a dialog.
                                  if (showRepeatTile) ...[
                                    const PaddedDivider(
                                        padding: Constants.padding),
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
                                  ],
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

                                  // Subtasks
                                  if (toDo.taskType != TaskType.small) ...[
                                    const PaddedDivider(
                                        padding: Constants.padding),
                                    Tiles.subtasksTile(
                                      context: context,
                                      id: toDo.id,
                                      limit: Constants.numTasks[toDo.taskType]!,
                                      subtasksAnchorController:
                                          subtasksAnchorController,
                                      onAnchorOpen: onAnchorOpen,
                                      onAnchorClose: onAnchorClose,
                                      onReorder:
                                          (_projection) ? onReorder : null,
                                      onRemoved: (_projection)
                                          ? onSubtaskRemoved
                                          : null,
                                      onChanged: (_projection)
                                          ? onSubtaskChanged
                                          : null,
                                      onSubmit: (_projection)
                                          ? onSubtaskSubmit
                                          : null,
                                      onDelete: (_projection)
                                          ? onSubtaskRemoved
                                          : null,
                                      handleUpdate: (_projection)
                                          ? handleSubtaskUpdate
                                          : null,
                                      handleDelete: (_projection)
                                          ? onSubtaskRemoved
                                          : null,
                                      onRemove:
                                          (userProvider.curUser?.reduceMotion ??
                                                  false)
                                              ? null
                                              : onRemove,
                                      subtasks: toDo.subtasks,
                                      subtaskCount: (_projection)
                                          ? _projectionSubtaskCount
                                          : toDoProvider.getSubtaskCount(
                                              id: toDo.id,
                                              limit: Constants
                                                  .numTasks[toDo.taskType]!),
                                    ),
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

  Dialog buildMobileDialog({
    required BuildContext context,
    bool smallScreen = false,
    bool showTimeTile = false,
    bool showRepeatTile = false,
  }) {
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
                        leading: ListTileWidgets.checkbox(
                          scale: Constants.largeCheckboxScale,
                          completed: toDo.completed,
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
                      weight: toDo.weight.toDouble(),
                      max: switch (toDo.taskType) {
                        TaskType.small => Constants.maxTaskWeight.toDouble(),
                        TaskType.large => Constants.medianWeight.toDouble(),
                        TaskType.huge => Constants.maxWeight.toDouble(),
                      },
                      slider: (toDo.taskType == TaskType.small)
                          ? Tiles.weightSlider(
                              weight: toDo.weight.toDouble(),
                              handleWeightChange: handleWeightChange,
                            )
                          : null,
                    ),

                    const PaddedDivider(padding: Constants.padding),

                    // Subtasks
                    if (toDo.taskType != TaskType.small) ...[
                      Tiles.subtasksTile(
                          context: context,
                          limit: Constants.numTasks[toDo.taskType]!,
                          subtasksAnchorController: subtasksAnchorController,
                          onAnchorOpen: onAnchorOpen,
                          onAnchorClose: onAnchorClose,
                          onReorder: (_projection) ? onReorder : null,
                          onRemoved: (_projection) ? onSubtaskRemoved : null,
                          onChanged: (_projection) ? onSubtaskChanged : null,
                          onSubmit: (_projection) ? onSubtaskSubmit : null,
                          onDelete: (_projection) ? onSubtaskRemoved : null,
                          handleUpdate:
                              (_projection) ? handleSubtaskUpdate : null,
                          handleDelete: (_projection) ? onSubtaskRemoved : null,
                          subtaskCount: (_projection)
                              ? _projectionSubtaskCount
                              : toDoProvider.getSubtaskCount(
                                  id: toDo.id,
                                  limit: Constants.numTasks[toDo.taskType]!),
                          subtasks: toDo.subtasks,
                          id: toDo.id),
                      const PaddedDivider(padding: Constants.padding),
                    ],
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

                    const PaddedDivider(padding: Constants.padding),
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

                    const PaddedDivider(padding: Constants.padding),
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

                    if (showTimeTile) ...[
                      const PaddedDivider(padding: Constants.padding),
                      Tiles.timeTile(
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
                      ),
                    ],
                    if (showRepeatTile) ...[
                      const PaddedDivider(padding: Constants.padding),
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
