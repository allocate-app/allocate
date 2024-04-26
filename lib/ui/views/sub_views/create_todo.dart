import "dart:io";
import "dart:math";

import "package:auto_size_text/auto_size_text.dart";
import "package:flutter/material.dart";
import "package:flutter/semantics.dart";
import "package:intl/intl.dart";
import "package:provider/provider.dart";

import "../../../model/task/group.dart";
import "../../../model/task/subtask.dart";
import "../../../model/task/todo.dart";
import '../../../providers/application/event_provider.dart';
import "../../../providers/application/layout_provider.dart";
import '../../../providers/model/group_provider.dart';
import '../../../providers/model/subtask_provider.dart';
import '../../../providers/model/todo_provider.dart';
import '../../../providers/model/user_provider.dart';
import "../../../providers/viewmodels/todo_viewmodel.dart";
import "../../../util/constants.dart";
import "../../../util/enums.dart";
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
  late ValueNotifier<bool> _checkClose;
  late ValueNotifier<String?> _nameErrorText;

  late ValueNotifier<bool> _createLoading;

  late final UserProvider userProvider;
  late final ToDoProvider toDoProvider;
  late final ToDoViewModel vm;
  late final SubtaskProvider subtaskProvider;
  late final GroupProvider groupProvider;
  late final EventProvider eventProvider;
  late final LayoutProvider layoutProvider;

  // Scrolling
  late final ScrollController mobileScrollController;
  late final ScrollController desktopScrollController;
  late final ScrollPhysics scrollPhysics;

  // Subtasks controller
  late final MenuController subtasksAnchorController;

  //Text controller
  late final TextEditingController nameEditingController;
  late final TextEditingController descriptionEditingController;

  //Search controller
  late final SearchController groupEditingController;

  @override
  void initState() {
    super.initState();
    initializeProviders();

    initializeParameters();

    initializeControllers();
  }

  void initializeParameters() {
    _checkClose = ValueNotifier(false);
    _createLoading = ValueNotifier(false);
    _nameErrorText = ValueNotifier(null);
  }

  void initializeControllers() async {
    mobileScrollController = ScrollController();
    desktopScrollController = ScrollController();

    ScrollPhysics parentPhysics = (Platform.isIOS || Platform.isMacOS)
        ? const BouncingScrollPhysics()
        : const ClampingScrollPhysics();
    scrollPhysics = AlwaysScrollableScrollPhysics(parent: parentPhysics);
    nameEditingController = TextEditingController();
    nameEditingController.addListener(watchName);

    groupEditingController = SearchController();
    groupEditingController.value = groupEditingController.value
        .copyWith(text: widget.initialGroup?.key ?? "");

    descriptionEditingController = TextEditingController();
    descriptionEditingController.addListener(watchDescription);

    subtasksAnchorController = MenuController();
  }

  void initializeProviders() {
    vm = Provider.of<ToDoViewModel>(context, listen: false);
    vm.clear();

    vm.initGroupID = widget.initialGroup?.value;

    userProvider = Provider.of<UserProvider>(context, listen: false);
    toDoProvider = Provider.of<ToDoProvider>(context, listen: false);
    subtaskProvider = Provider.of<SubtaskProvider>(context, listen: false);
    groupProvider = Provider.of<GroupProvider>(context, listen: false);
    eventProvider = Provider.of<EventProvider>(context, listen: false);

    layoutProvider = Provider.of<LayoutProvider>(context, listen: false);
    subtaskProvider.addListener(resetSubtasks);
  }

  @override
  void dispose() {
    nameEditingController.removeListener(watchName);
    nameEditingController.dispose();
    descriptionEditingController.removeListener(watchDescription);
    descriptionEditingController.dispose();
    mobileScrollController.dispose();
    desktopScrollController.dispose();
    groupEditingController.dispose();
    subtaskProvider.removeListener(resetSubtasks);
    super.dispose();
  }

  Future<void> resetSubtasks() async {
    if (vm.taskType == TaskType.small) {
      return;
    }
    List<Subtask> newSubtasks = await toDoProvider.getSubtasks(
        id: vm.id, limit: Constants.numTasks[vm.taskType]!);

    if (!(toDoProvider.userViewModel?.reduceMotion ?? false)) {
      onFetch(items: newSubtasks);
    }

    vm.subtasks = newSubtasks;
    toDoProvider.setSubtaskCount(id: vm.id, count: vm.subtasks.length);
    vm.weight = await toDoProvider.getWeight(
        taskID: vm.id, limit: Constants.numTasks[vm.taskType]!);

    subtaskProvider.rebuild = false;
  }

  void watchName() {
    _checkClose.value = toDoProvider.userViewModel?.checkClose ?? true;
    String newText = nameEditingController.text;
    SemanticsService.announce(newText, Directionality.of(context));
    vm.name = newText;
    if (null != _nameErrorText.value) {
      _nameErrorText.value = null;
    }
  }

  void watchDescription() {
    _checkClose.value = toDoProvider.userViewModel?.checkClose ?? true;
    String newText = descriptionEditingController.text;
    SemanticsService.announce(newText, Directionality.of(context));
    vm.description = newText;
  }

  bool validateData() {
    bool valid = true;
    if (groupEditingController.text.isEmpty) {
      vm.groupID = null;
    }
    if (nameEditingController.text.isEmpty) {
      valid = false;
      _nameErrorText.value = "Enter Task Name";
      if (desktopScrollController.hasClients) {
        desktopScrollController.jumpTo(0);
      }
      if (mobileScrollController.hasClients) {
        mobileScrollController.jumpTo(0);
      }
    }

    if (null == vm.startDate || null == vm.dueDate) {
      vm.frequency = Frequency.once;
    }

    if (vm.frequency == Frequency.custom) {
      if (vm.weekdayList.isEmpty) {
        vm.weekdayList.add(
            min(((vm.startDate?.weekday ?? Constants.today.weekday) - 1), 0));
      }
    }

    return valid;
  }

  void _popScreen() {
    if (mounted) {
      Navigator.pop(context);
    }
  }

  // This should still run even if the online throws.
  // If local create fails, something is very wrong => pop context and escape
  Future<void> handleCreate() async {
    vm.repeatable = Frequency.once != vm.frequency;
    ToDo newToDo = vm.toModel();
    await toDoProvider.createToDo(newToDo).then((_) async {
      if (null != vm.groupID) {
        // This will catch if there is a valid ToDo in the database.
        groupProvider.setToDoCount(id: vm.groupID!);
      }

      // If the ToDo was put in the db, the calendar can be refreshed.
      // This is more or less a convenience method.
      await eventProvider.insertEventModel(model: newToDo, notify: true);
    }).catchError((e) async {
      await Tiles.displayError(e: e);
    }).whenComplete(() {
      vm.clear();
      _popScreen();
    });
  }

  Future<void> handleClose({required bool willDiscard}) async {
    if (willDiscard) {
      for (Subtask st in vm.subtasks) {
        st.toDelete = true;
      }
      await subtaskProvider
          .updateBatch(subtasks: vm.subtasks)
          .catchError((e) async {
        await Tiles.displayError(e: e);
      }).whenComplete(() {
        vm.clear();
        _popScreen();
      });
    }
    _checkClose.value = false;
  }

  Future<void> createAndValidate() async {
    _createLoading.value = true;
    if (validateData()) {
      await handleCreate();
    }
    _createLoading.value = false;
  }

  void onFetch({List<Subtask>? items}) {
    if (null == items) {
      return;
    }

    DateTime threshold = DateTime.now();
    threshold = threshold.copyWith(
        millisecond: threshold.millisecond - Constants.newItemThreshold);
    for (Subtask subtask in items) {
      if (!subtask.lastUpdated.isBefore(threshold)) {
        subtask.fade = Fade.fadeIn;
      }
    }
  }

  Future<void> onRemove({Subtask? item}) async {
    if (null == item) {
      return;
    }
    if (mounted) {
      setState(() => item.fade = Fade.fadeOut);
      await Future.delayed(const Duration(milliseconds: Constants.fadeOutTime));
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
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          if (layoutProvider.largeScreen) {
            return _buildDesktopDialog(
              context: context,
            );
          }
          return _buildMobileDialog(
              context: context, smallScreen: layoutProvider.smallScreen);
        },
      );

  Dialog _buildDesktopDialog({
    required BuildContext context,
  }) {
    Widget innerList = ListView(
        padding: const EdgeInsets.only(
          top: Constants.halfPadding,
          left: Constants.padding,
          right: Constants.padding,
        ),
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
                        _buildNameTile(),
                        _buildWeightTile(),

                        const PaddedDivider(padding: Constants.padding),
                        // My Day
                        _buildMyDay(),

                        const PaddedDivider(padding: Constants.padding),
                        // Priority
                        Padding(
                          padding:
                              const EdgeInsets.only(bottom: Constants.padding),
                          child: _buildPriorityTile(),
                        ),
                        const PaddedDivider(padding: Constants.padding),
                        // Expected Duration / RealDuration -> Show status, on click, open a dialog.
                        _buildDurationTile(),

                        const PaddedDivider(padding: Constants.padding),
                        // DateTime -> Show status, on click, open a dialog.
                        _buildDateRangeTile(),

                        _buildTimeTile(),
                        _buildRepeatableTile(),
                      ]),
                ),
                Flexible(
                  child: ListView(
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(
                          horizontal: Constants.halfPadding),
                      children: [
                        _buildSearchBar(
                            padding: const EdgeInsets.only(
                                top: Constants.halfPadding,
                                right: Constants.quarterPadding,
                                left: Constants.quarterPadding)),

                        const PaddedDivider(padding: Constants.padding),
                        // TaskType
                        _buildTaskTypeButton(),
                        _buildSubtasksTile(),

                        const Padding(
                          padding:
                              EdgeInsets.symmetric(vertical: Constants.padding),
                          child: PaddedDivider(padding: Constants.padding),
                        ),
                        // Description
                        _buildDescriptionTile(
                            minLines: Constants.desktopMinLines,
                            maxLines: Constants.desktopMaxLinesBeforeScroll),
                      ]),
                )
              ]),
        ]);

    return Dialog(
      insetPadding: const EdgeInsets.all(Constants.outerDialogPadding),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
            maxHeight: Constants.maxDesktopDialogHeight,
            maxWidth: Constants.maxDesktopDialogWidth),
        child: Padding(
          padding: const EdgeInsets.all(Constants.padding),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            // Title && Close Button
            _buildTitleBar(),
            const PaddedDivider(padding: Constants.halfPadding),
            Flexible(
              child: Material(
                color: Colors.transparent,
                child: (layoutProvider.isMobile)
                    ? Scrollbar(
                        controller: desktopScrollController,
                        child: innerList,
                      )
                    : innerList,
              ),
            ),

            const PaddedDivider(padding: Constants.halfPadding),
            _buildCreateButton(),
          ]),
        ),
      ),
    );
  }

  Dialog _buildMobileDialog({
    required BuildContext context,
    bool smallScreen = false,
  }) {
    // Inner list factored out bc of Flutter's Scrollbar change.

    Widget innerList = ListView(
      padding: const EdgeInsets.symmetric(horizontal: Constants.padding),
      shrinkWrap: true,
      controller: mobileScrollController,
      physics: scrollPhysics,
      children: [
        _buildNameTile(),
        _buildWeightTile(),
        const PaddedDivider(padding: Constants.padding),
        // TaskType -- This is only one-screen.
        _buildTaskTypeButton(),
        _buildSubtasksTile(),

        const PaddedDivider(padding: Constants.padding),
        // My Day
        _buildMyDay(),
        const PaddedDivider(padding: Constants.padding),
        // Priority
        _buildPriorityTile(mobile: smallScreen),

        const Padding(
          padding: EdgeInsets.symmetric(vertical: Constants.padding),
          child: PaddedDivider(padding: Constants.padding),
        ),

        SafeArea(
          child: _buildSearchBar(
              padding: const EdgeInsets.symmetric(
                  horizontal: Constants.quarterPadding)),
        ),

        const Padding(
          padding: EdgeInsets.symmetric(vertical: Constants.padding),
          child: PaddedDivider(padding: Constants.padding),
        ),

        // Description
        _buildDescriptionTile(mobile: smallScreen),

        const PaddedDivider(padding: Constants.padding),
        // Expected Duration / RealDuration -> Show status, on click, open a dialog.
        _buildDurationTile(),

        const PaddedDivider(padding: Constants.padding),
        // DateTime -> Show status, on click, open a dialog.
        _buildDateRangeTile(),

        _buildTimeTile(),
        _buildRepeatableTile(),
      ],
    );

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
              _buildTitleBar(),
              const PaddedDivider(padding: Constants.halfPadding),
              Flexible(
                child: (layoutProvider.isMobile)
                    ? Scrollbar(
                        controller: mobileScrollController,
                        child: innerList,
                      )
                    : innerList,
              ),

              const PaddedDivider(padding: Constants.halfPadding),
              _buildCreateButton(),
            ]),
      ),
    );
  }

  Widget _buildTitleBar() => ValueListenableBuilder<bool>(
        valueListenable: _checkClose,
        builder: (BuildContext context, bool check, Widget? child) =>
            Selector<ToDoViewModel, (int, int)>(
          selector: (BuildContext context, ToDoViewModel vm) =>
              (vm.expectedDuration, vm.realDuration),
          builder: (BuildContext context, (int, int) value, Widget? child) {
            return TitleBar(
              context: context,
              title: "New Task",
              centerWidget: (value.$1 > 0)
                  ? TitleBar.durationCenterWidget(
                      expectedDuration: value.$1,
                      realDuration: value.$2,
                    )
                  : null,
              handleClose: handleClose,
              checkClose: check,
              padding:
                  const EdgeInsets.symmetric(horizontal: Constants.padding),
            );
          },
        ),
      );

  Widget _buildNameTile() => ValueListenableBuilder<String?>(
      valueListenable: _nameErrorText,
      builder: (BuildContext context, String? errorText, Widget? child) =>
          Selector<ToDoViewModel, (String, bool)>(
            selector: (BuildContext context, ToDoViewModel vm) =>
                (vm.name, vm.completed),
            builder: (BuildContext context, (String, bool) value,
                    Widget? child) =>
                Tiles.nameTile(
                    context: context,
                    leading: ListTileWidgets.checkbox(
                      scale: Constants.largeCheckboxScale,
                      completed: value.$2,
                      onChanged: (bool? completed) {
                        _checkClose.value =
                            toDoProvider.userViewModel?.checkClose ?? true;
                        vm.completed = completed!;
                      },
                    ),
                    errorText: errorText,
                    hintText: "Task Name",
                    controller: nameEditingController,
                    outerPadding:
                        const EdgeInsets.symmetric(vertical: Constants.padding),
                    textFieldPadding:
                        const EdgeInsets.only(left: Constants.padding),
                    onEditingComplete: () {
                      _checkClose.value =
                          toDoProvider.userViewModel?.checkClose ?? true;
                      vm.name = nameEditingController.text;
                    },
                    handleClear: () {
                      _checkClose.value =
                          toDoProvider.userViewModel?.checkClose ?? true;
                      nameEditingController.clear();
                      vm.name = "";
                    }),
          ));

  Widget _buildWeightTile() => Selector<ToDoViewModel, (TaskType, int)>(
      selector: (BuildContext context, ToDoViewModel vm) =>
          (vm.taskType, vm.weight),
      builder: (BuildContext context, (TaskType, int) value, Widget? child) =>
          Tiles.weightTile(
            outerPadding: const EdgeInsets.all(Constants.doublePadding),
            batteryPadding: const EdgeInsets.all(Constants.padding),
            constraints: const BoxConstraints(
              maxWidth: 200,
            ),
            weight: value.$2.toDouble(),
            max: switch (value.$1) {
              TaskType.small => Constants.maxTaskWeightDouble,
              TaskType.large => Constants.medianWeight.toDouble(),
              TaskType.huge => Constants.maxWeight.toDouble()
            },
            slider: (TaskType.small == value.$1)
                ? Tiles.weightSlider(
                    weight: value.$2.toDouble(),
                    handleWeightChange: (double? newWeight) {
                      if (null == newWeight) {
                        return;
                      }
                      _checkClose.value =
                          toDoProvider.userViewModel?.checkClose ?? true;
                      vm.weight = newWeight.toInt();
                    })
                : null,
          ));

  Widget _buildMyDay() => Selector<ToDoViewModel, (bool, int)>(
        selector: (BuildContext context, ToDoViewModel vm) =>
            (vm.myDay, vm.weight),
        builder: (BuildContext context, (bool, int) value, Widget? child) =>
            Tiles.myDayTile(
          myDay: value.$1,
          canAdd: userProvider.myDayTotal.value + value.$2 <=
              (toDoProvider.userViewModel?.bandwidth ?? Constants.maxBandwidth),
          toggleMyDay: () {
            _checkClose.value = toDoProvider.userViewModel?.checkClose ?? true;
            vm.myDay = !vm.myDay;
          },
        ),
      );

  Widget _buildPriorityTile({bool mobile = false}) =>
      Selector<ToDoViewModel, Priority>(
        selector: (BuildContext context, ToDoViewModel vm) => vm.priority,
        builder: (BuildContext context, Priority value, Widget? child) =>
            Tiles.priorityTile(
                context: context,
                priority: value,
                mobile: mobile,
                onSelectionChanged: (Set<Priority> newPriority) {
                  _checkClose.value =
                      toDoProvider.userViewModel?.checkClose ?? true;
                  vm.priority = newPriority.first;
                }),
      );

  Widget _buildDurationTile() => Selector<ToDoViewModel, (int, int)>(
        selector: (BuildContext context, ToDoViewModel vm) =>
            (vm.expectedDuration, vm.realDuration),
        builder: (BuildContext context, (int, int) value, Widget? child) =>
            Tiles.durationTile(
          context: context,
          expectedDuration: value.$1,
          realDuration: value.$2,
          handleClear: vm.clearDuration,
          handleUpdate: vm.updateDuration,
        ),
      );

  Widget _buildDateRangeTile() =>
      Selector<ToDoViewModel, (DateTime?, DateTime?)>(
        selector: (BuildContext context, ToDoViewModel vm) =>
            (vm.startDate, vm.dueDate),
        builder: (BuildContext context, (DateTime?, DateTime?) value,
                Widget? child) =>
            Tiles.dateRangeTile(
                context: context,
                startDate: value.$1,
                dueDate: value.$2,
                handleClear: () {
                  _checkClose.value =
                      toDoProvider.userViewModel?.checkClose ?? true;
                  vm.clearDates();
                },
                handleUpdate: (
                    {bool? checkClose, DateTime? newDue, DateTime? newStart}) {
                  checkClose = checkClose ?? _checkClose.value;
                  _checkClose.value = (checkClose)
                      ? toDoProvider.userViewModel?.checkClose ?? checkClose
                      : false;
                  vm.updateDates(newStart: newStart, newDue: newDue);
                }),
      );

  Widget _buildTimeTile() =>
      Selector<ToDoViewModel, (bool, TimeOfDay?, TimeOfDay?)>(
        selector: (BuildContext context, ToDoViewModel vm) => (
          null != vm.startDate && null != vm.dueDate,
          vm.startTime,
          vm.dueTime
        ),
        builder: (BuildContext context, (bool, TimeOfDay?, TimeOfDay?) value,
                Widget? child) =>
            (value.$1)
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const PaddedDivider(padding: Constants.padding),
                      Tiles.timeTile(
                          context: context,
                          startTime: value.$2,
                          dueTime: value.$3,
                          handleClear: () {
                            _checkClose.value =
                                toDoProvider.userViewModel?.checkClose ?? true;
                            vm.clearTimes();
                          },
                          handleUpdate: (
                              {bool? checkClose,
                              TimeOfDay? newStart,
                              TimeOfDay? newDue}) {
                            checkClose = checkClose ?? _checkClose.value;
                            _checkClose.value = (checkClose)
                                ? toDoProvider.userViewModel?.checkClose ??
                                    checkClose
                                : false;
                            vm.updateTimes(newStart: newStart, newDue: newDue);
                          }),
                    ],
                  )
                : const SizedBox.shrink(),
      );

  Widget _buildRepeatableTile() => Selector<ToDoViewModel, (bool, UniqueKey)>(
        selector: (BuildContext context, ToDoViewModel vm) =>
            (null != vm.startDate && null != vm.dueDate, vm.repeatableKey),
        builder: (BuildContext context, (bool, UniqueKey) value,
                Widget? child) =>
            (value.$1)
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const PaddedDivider(padding: Constants.padding),
                      Tiles.repeatableTile(
                          context: context,
                          frequency: vm.frequency,
                          weekdays: vm.weekdayList,
                          repeatSkip: vm.repeatSkip,
                          startDate: vm.startDate,
                          handleUpdate: (
                              {bool? checkClose,
                              required Frequency newFreq,
                              required int newSkip,
                              required Set<int> newWeekdays}) {
                            checkClose = checkClose ?? _checkClose.value;
                            _checkClose.value = (checkClose)
                                ? toDoProvider.userViewModel?.checkClose ??
                                    checkClose
                                : false;
                            vm.updateRepeatable(
                                newFreq: newFreq,
                                newSkip: newSkip,
                                newWeekdays: newWeekdays);
                          },
                          handleClear: () {
                            _checkClose.value =
                                toDoProvider.userViewModel?.checkClose ?? true;
                            vm.clearRepeatable();
                          }),
                    ],
                  )
                : const SizedBox.shrink(),
      );

  Widget _buildTaskTypeButton() => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Expanded(
                child: AutoSizeText("Task Type",
                    maxLines: 1,
                    softWrap: true,
                    textAlign: TextAlign.center,
                    minFontSize: Constants.medium,
                    style: Constants.headerStyle),
              )
            ],
          ),
          Selector<ToDoViewModel, TaskType>(
            selector: (BuildContext context, ToDoViewModel vm) => vm.taskType,
            builder: (BuildContext context, TaskType value, Widget? child) =>
                SegmentedButton<TaskType>(
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
                              toBeginningOfSentenceCase(type.name),
                              softWrap: false,
                              overflow: TextOverflow.visible,
                            )))
                        .toList(growable: false),
                    selected: {value},
                    onSelectionChanged: (Set<TaskType> newSelection) {
                      _checkClose.value =
                          toDoProvider.userViewModel?.checkClose ?? true;
                      vm.taskType = newSelection.first;
                    }),
          )
        ],
      );

  Widget _buildDescriptionTile({
    int minLines = Constants.mobileMinLines,
    int maxLines = Constants.mobileMaxLinesBeforeScroll,
    bool mobile = false,
  }) =>
      Selector<ToDoViewModel, String>(
        selector: (BuildContext context, ToDoViewModel vm) => vm.description,
        builder: (BuildContext context, String value, Widget? child) =>
            Tiles.descriptionTile(
                context: context,
                isDense: mobile,
                hintText: "Notes",
                minLines: minLines,
                maxLines: maxLines,
                controller: descriptionEditingController,
                onEditingComplete: () {
                  _checkClose.value =
                      toDoProvider.userViewModel?.checkClose ?? true;
                  vm.description = descriptionEditingController.text;
                }),
      );

  Widget _buildSearchBar({EdgeInsetsGeometry padding = EdgeInsets.zero}) =>
      SearchRecentsBar<Group>(
        persistentEntry: widget.initialGroup,
        hintText: "Search Groups",
        padding: padding,
        handleDataSelection: ({required int id}) async {
          _checkClose.value = toDoProvider.userViewModel?.checkClose ?? true;
          vm.groupID = id;
        },
        searchController: groupEditingController,
        dispose: false,
        mostRecent: groupProvider.mostRecent,
        search: groupProvider.searchGroups,
      );

  Widget _buildSubtasksTile() => Selector<ToDoViewModel, (TaskType, UniqueKey)>(
        selector: (BuildContext context, ToDoViewModel vm) =>
            (vm.taskType, vm.subtaskKey),
        builder: (BuildContext context, (TaskType, UniqueKey) value,
                Widget? child) =>
            (TaskType.small != value.$1)
                ? Padding(
                    padding:
                        const EdgeInsets.only(top: Constants.doublePadding),
                    child: Tiles.subtasksTile(
                        context: context,
                        id: vm.id,
                        limit: Constants.numTasks[value.$1]!,
                        subtasksAnchorController: subtasksAnchorController,
                        onAnchorOpen: onAnchorOpen,
                        onAnchorClose: onAnchorClose,
                        onRemove:
                            (toDoProvider.userViewModel?.reduceMotion ?? false)
                                ? null
                                : onRemove,
                        subtasks: vm.subtasks,
                        subtaskCount: toDoProvider.getSubtaskCount(
                            id: vm.id, limit: Constants.numTasks[value.$1]!)),
                  )
                : const SizedBox.shrink(),
      );

  Widget _buildCreateButton() => ValueListenableBuilder(
        valueListenable: _createLoading,
        builder: (BuildContext context, bool createLoading, Widget? child) =>
            Tiles.createButton(
                outerPadding:
                    const EdgeInsets.symmetric(horizontal: Constants.padding),
                handleCreate: createAndValidate,
                loading: createLoading),
      );
}
