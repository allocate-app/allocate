import "dart:math";

import "package:allocate/util/constants.dart";
import "package:auto_size_text/auto_size_text.dart";
import "package:auto_size_text_field/auto_size_text_field.dart";
import "package:flutter/material.dart";
import "package:flutter/semantics.dart";
import "package:intl/intl.dart";
import "package:jiffy/jiffy.dart";
import "package:numberpicker/numberpicker.dart";
import "package:provider/provider.dart";

import "../../../model/task/group.dart";
import "../../../model/task/subtask.dart";
import "../../../providers/group_provider.dart";
import "../../../providers/todo_provider.dart";
import "../../../providers/user_provider.dart";
import "../../../util/enums.dart";
import "../../../util/exceptions.dart";
import "../../../util/numbers.dart";
import "../../widgets/paddedDivider.dart";

/// Basic UI list order (Mobile):
/// Title
/// Type
/// Begin dividers
/// Group - Dropdown search + stream.
/// Status (Complete + Myday)
/// Description
/// Duration (Expected + Real)
/// Dates (Start + End + Times)
/// Repeatable

class CreateToDoScreen extends StatefulWidget {
  const CreateToDoScreen({Key? key}) : super(key: key);

  @override
  State<CreateToDoScreen> createState() => _CreateToDoScreen();
}

class _CreateToDoScreen extends State<CreateToDoScreen> {
  late bool checkClose;
  late bool checkDelete;

  // Provider (Needs user values) -> Refactor to DI for testing.
  late final UserProvider userProvider;
  late final ToDoProvider toDoProvider;
  late final GroupProvider groupProvider;

  // Scrolling
  late final ScrollController scrollController;
  late final ScrollPhysics scrollPhysics;

  // Param fields.
  late TaskType taskType;

  late String name;
  late final TextEditingController nameEditingController;
  String? nameErrorText;

  // Group -> Tbh, not super sure what to do with this.
  late final TextEditingController groupEditingController;
  late List<MapEntry<String, int>> searchHistory;
  int? groupID;

  // Description
  late String description;
  late final TextEditingController descriptionEditingController;

  // Weight
  // Slider vs Non editable integer.
  // Use a list, accessed by TaskType.index;
  late int weight;
  // Only update this on subtask weight change
  late int sumWeight;

  // ExpectedDuration & Real Duration
  // May have to refactor Duration Constant out.

  late int expectedDuration;
  late int realDuration;
  late int hours;
  late int minutes;
  late int seconds;

  Priority priority = Priority.low;

  // Status
  late bool completed;
  final MaterialStateProperty<Icon?> completedIcon = MaterialStateProperty.resolveWith(
      (states) => (states.contains(MaterialState.selected) ? const Icon(Icons.task_alt) : null));
  late bool myDay;

  // DateTimes
  DateTime? startDate;
  DateTime? startTime;
  DateTime? dueDate;
  DateTime? dueTime;

  // Repeat
  late Frequency frequency;
  late CustomFrequency customFreq;

  late TextEditingController repeatSkipEditingController;
  late int repeatSkip;

  // Days of the week -> Need an enum, names map to indices.
  // ON creation -> Loop and map values
  late Set<int> weekDaySet;
  late List<bool> weekDays;

  late final List<TextEditingController> subTaskEditingController;
  late final List<SubTask> subTasks;
  late int shownTasks;

  // NOTE: On submit: run validation logic ->
  // Check fields, ensure valid:
  // If anything fails, set a boolean.
  // Check the boolean, if it's all passed, create & pop.
  // If not, run setState.
  // MORE: Validation: Check the group search bar -> if it doesn't have a name,
  // then set the groupID to null;

  @override
  void initState() {
    super.initState();
    initializeProviders();

    // Refactor this into the user provider class.
    initializeParameters();

    initializeControllers();
  }

  void initializeParameters() {
    // Refactor this into the user provider class.
    checkClose = false;
    taskType = TaskType.small;

    name = "";
    description = "";

    weight = 0;
    sumWeight = 0;

    completed = false;
    myDay = false;
    expectedDuration = 0;
    realDuration = 0;
    hours = 0;
    minutes = 0;
    seconds = 0;
    searchHistory = List.empty(growable: true);

    frequency = Frequency.once;
    customFreq = CustomFrequency.weekly;

    repeatSkip = 1;

    subTasks = List.generate(Constants.maxNumTasks, (_) => SubTask());
    shownTasks = 0;
    weekDaySet = <int>{};
    weekDays = List.generate(7, (_) => false);
  }

  void initializeControllers() {
    scrollController = ScrollController();
    scrollPhysics = const BouncingScrollPhysics();
    nameEditingController = TextEditingController();
    nameEditingController.addListener(() {
      checkClose = true;
      String newText = nameEditingController.text;
      SemanticsService.announce(newText, Directionality.of(context));
      name = newText;
    });

    groupEditingController = TextEditingController();
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

    subTaskEditingController = List.generate(subTasks.length, (_) => TextEditingController());
    for (int i = 0; i < subTaskEditingController.length; i++) {
      subTaskEditingController[i].addListener(() {
        checkClose = true;
        String newText = descriptionEditingController.text;
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

  void handleGroupSelection({required Group group, required SearchController controller}) {
    // Controller logic
    controller.closeView(group.name);
    setState(() {
      checkClose = true;
      groupID = group.id;
      if (searchHistory.length >= Constants.historyLength) {
        searchHistory.removeLast();
      }

      searchHistory.insert(0, MapEntry(group.name, group.id));
    });
  }

  void handleHistorySelection(
      {required MapEntry<String, int> groupData, required SearchController controller}) {
    controller.closeView(groupData.key);
    setState(() {
      checkClose = true;
      groupID = groupData.value;
    });
  }

  bool validateData() {
    bool valid = true;
    if (groupEditingController.text.isEmpty) {
      groupID = null;
    }
    if (nameEditingController.text.isEmpty) {
      valid = false;
      nameErrorText = "Enter Task Name";
    }
    if (frequency == Frequency.custom) {
      if (weekDaySet.isEmpty) {
        weekDaySet.add((startDate?.day ?? DateTime.now().day) - 1);
      }
    } else {
      customFreq = CustomFrequency.weekly;
    }

    return valid;
  }

  Icon getBatteryIcon({required int weight, required bool selected}) {
    // Icon is scaled for sum-weight.
    weight = (taskType == TaskType.small)
        ? weight
        : remap(
                x: weight,
                inMin: 0,
                inMax: (Constants.maxTaskWeight * Constants.numTasks[taskType]!),
                outMin: 0,
                outMax: 5)
            .toInt();

    if (selected) {
      return Constants.selectedBatteryIcons[weight]!;
    }
    return Constants.batteryIcons[weight]!;
  }

  @override
  Widget build(BuildContext context) {
    final Color errorColor = Theme.of(context).colorScheme.error;

    bool largeScreen = (MediaQuery.of(context).size.width >= Constants.largeScreen);
    bool smallScreen = (MediaQuery.of(context).size.width <= Constants.smallScreen);
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(Constants.padding),
        child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title && Close Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Constants.padding),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  const Flexible(
                    child: AutoSizeText(
                      "New Task",
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
                                  message: "Expected Task Duration",
                                  child: Padding(
                                    padding:
                                        const EdgeInsets.symmetric(horizontal: Constants.padding),
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
                                              Duration(seconds: expectedDuration)
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
                                  message: "Actual Task Duration",
                                  child: Padding(
                                    padding:
                                        const EdgeInsets.symmetric(horizontal: Constants.padding),
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
                                              Duration(seconds: realDuration)
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
                  buildCloseButton(context),
                ]),
              ),
              const PaddedDivider(padding: Constants.padding),
              Expanded(
                child: ListView(
                  shrinkWrap: true,
                  controller: scrollController,
                  physics: scrollPhysics,
                  children: [
                    // Title + status
                    Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: (smallScreen) ? Constants.padding : Constants.innerPadding),
                      child: buildNameTile(smallScreen: smallScreen),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: Constants.padding),
                      child: buildWeightTile(smallScreen: smallScreen),
                    ),
                    const PaddedDivider(padding: Constants.innerPadding),
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
                      padding: const EdgeInsets.all(Constants.innerPadding),
                      child: buildTaskTypeButton(smallScreen: smallScreen),
                    ),
                    // Subtasks
                    (taskType != TaskType.small)
                        ? Padding(
                            padding: const EdgeInsets.symmetric(horizontal: Constants.innerPadding),
                            child: Card(
                              clipBehavior: Clip.antiAlias,
                              elevation: 0,
                              color: Theme.of(context).colorScheme.surfaceVariant,
                              shape: RoundedRectangleBorder(
                                  side: BorderSide(
                                      color: Theme.of(context).colorScheme.outline,
                                      strokeAlign: BorderSide.strokeAlignInside),
                                  borderRadius: const BorderRadius.all(
                                      Radius.circular(Constants.roundedCorners))),
                              child: ExpansionTile(
                                title: const Text("Steps"),
                                collapsedShape: const RoundedRectangleBorder(
                                    side: BorderSide(strokeAlign: BorderSide.strokeAlignOutside),
                                    borderRadius: BorderRadius.all(
                                        Radius.circular(Constants.roundedCorners))),
                                shape: const RoundedRectangleBorder(
                                    side: BorderSide(strokeAlign: BorderSide.strokeAlignOutside),
                                    borderRadius: BorderRadius.all(
                                        Radius.circular(Constants.roundedCorners))),
                                children: [
                                  buildSubTasksList(),
                                  (shownTasks < Constants.numTasks[taskType]!)
                                      ? ListTile(
                                          leading: const Icon(Icons.add_outlined),
                                          title: const Text("Add a step"),
                                          onTap: () => setState(() {
                                                shownTasks++;
                                                shownTasks = min(shownTasks, Constants.maxNumTasks);
                                              }))
                                      : const SizedBox.shrink(),
                                ],
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),

                    const PaddedDivider(padding: Constants.padding),
                    // My Day
                    buildMyDayTile(),
                    const PaddedDivider(padding: Constants.padding),
                    // Priority
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: Constants.padding),
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
                      padding: const EdgeInsets.symmetric(horizontal: Constants.padding),
                      child: buildPriorityTile(smallScreen: smallScreen),
                    ),

                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: PaddedDivider(padding: Constants.innerPadding),
                    ),

                    // Group Picker
                    // TODO: figure out how to make this work with screen readers.
                    // I don't know if SemanticsService will actually work.
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: Constants.padding),
                      child: buildGroupBar(),
                    ),

                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: Constants.padding),
                      child: PaddedDivider(padding: Constants.innerPadding),
                    ),

                    // Description
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: Constants.padding),
                      child: buildDescriptionTile(smallScreen: smallScreen),
                    ),

                    const PaddedDivider(padding: Constants.innerPadding),
                    // Expected Duration / RealDuration -> Show status, on click, open a dialog.
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: Constants.padding),
                      child: buildDurationTile(context),
                    ),

                    const PaddedDivider(padding: Constants.innerPadding),
                    // DateTime -> Show status, on click, open a dialog.
                    //startDate
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: Constants.padding),
                      child: buildDateTile(context),
                    ),

                    const PaddedDivider(padding: Constants.innerPadding),
                    // Time
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: Constants.padding),
                      child: buildTimeTile(),
                    ),

                    const PaddedDivider(padding: Constants.innerPadding),
                    // Repeatable Stuff -> Show status, on click, open a dialog.
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: Constants.padding),
                      child: buildRepeatableTile(context),
                    ),
                  ],
                ),
              ),

              const PaddedDivider(padding: Constants.padding),
              // Create Button - could be a stack
              Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                FilledButton.icon(
                    label: const Text("Create Task"),
                    icon: const Icon(Icons.add),
                    onPressed: () async {
                      bool validData = validateData();
                      if (validData) {
                        weekDaySet.map((wd) => weekDays[wd] = true);
                        await toDoProvider
                            .createToDo(
                              groupID: groupID,
                              taskType: taskType,
                              name: name,
                              description: description,
                              weight: weight,
                              expectedDuration: expectedDuration,
                              realDuration: realDuration,
                              priority: priority,
                              startDate: startDate,
                              dueDate: dueDate,
                              myDay: myDay,
                              completed: completed,
                              repeatable: frequency != Frequency.once,
                              frequency: frequency,
                              customFreq: customFreq,
                              repeatDays: weekDays,
                              repeatSkip: repeatSkip,
                              subTasks: subTasks,
                            )
                            .then((value) => Navigator.pop(context))
                            .catchError((e) {
                          ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(
                            content: Text(e.cause,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: errorColor)),
                            action: SnackBarAction(label: "Dismiss", onPressed: () {}),
                            duration: const Duration(milliseconds: 1500),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(Constants.circular),
                            ),
                            width: (MediaQuery.sizeOf(context).width) / 2,
                            padding: const EdgeInsets.symmetric(horizontal: Constants.padding),
                          ));
                        },
                                test: (e) =>
                                    e is FailureToCreateException || e is FailureToUploadException);
                      }
                      // Then save.
                    })
              ])
            ]),
      ),
    );
  }

  ListTile buildRepeatableTile(BuildContext context) {
    return ListTile(
        leading: const Icon(Icons.event_repeat_outlined),
        title: (frequency == Frequency.once)
            ? const Text(
                "Set Recurring?",
                overflow: TextOverflow.ellipsis,
              )
            : Text(
                toBeginningOfSentenceCase(frequency.name)!,
                overflow: TextOverflow.ellipsis,
              ),
        onTap: () {
          // Caching bc of conditional rendering.
          Frequency cacheFreq = frequency;
          CustomFrequency cacheCustom = customFreq;
          Set<int> cacheWeekdays = Set.from(weekDaySet);
          int cacheSkip = repeatSkip;

          showDialog(
              context: context,
              builder: (BuildContext context) {
                return buildRepeatableDialog(
                    cacheFreq, cacheCustom, cacheSkip, cacheWeekdays, context);
              });
        },
        trailing: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => setState(() {
                  frequency = Frequency.once;
                  customFreq = CustomFrequency.weekly;
                })));
  }

  Dialog buildRepeatableDialog(Frequency cacheFreq, CustomFrequency cacheCustom, int cacheSkip,
      Set<int> cacheWeekdays, BuildContext context) {
    return Dialog(
        child: Padding(
      padding: const EdgeInsets.all(Constants.padding),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Row(mainAxisAlignment: MainAxisAlignment.start, children: [
            Text(
              "Set Recurring",
              overflow: TextOverflow.ellipsis,
            )
          ]),
          // Segmented button
          SegmentedButton<Frequency>(
            segments: Frequency.values
                .map((Frequency frequency) => ButtonSegment<Frequency>(
                      value: frequency,
                      label: Text(
                        "${toBeginningOfSentenceCase(frequency.name)}",
                        overflow: TextOverflow.ellipsis,
                      ),
                    ))
                .toList(growable: false),
            selected: <Frequency>{frequency},
            onSelectionChanged: (Set<Frequency> newSelection) => setState(() {
              checkClose = true;
              frequency = newSelection.first;
            }),
          ),
          // Conditional, custom rendering widget.
          (frequency == Frequency.once)
              ? const SizedBox.shrink()
              : Column(children: [
                  // Segmented CustomFreq button.
                  SegmentedButton<int>(
                      multiSelectionEnabled: true,
                      segments: const [
                        ButtonSegment<int>(
                          value: DateTime.sunday - 1,
                          label: Text("Sun"),
                        ),
                        ButtonSegment<int>(value: DateTime.monday - 1, label: Text("Mon")),
                        ButtonSegment<int>(value: DateTime.tuesday - 1, label: Text("Tues")),
                        ButtonSegment<int>(value: DateTime.wednesday - 1, label: Text("Wed")),
                        ButtonSegment<int>(value: DateTime.thursday - 1, label: Text("Thur")),
                        ButtonSegment<int>(value: DateTime.friday - 1, label: Text("Fri")),
                        ButtonSegment<int>(value: DateTime.saturday - 1, label: Text("Sat")),
                      ],
                      selected: weekDaySet,
                      onSelectionChanged: (Set<int> newSelection) => setState(() {
                            checkClose = true;
                            weekDaySet = newSelection;
                          }))
                ]),

          (frequency != Frequency.once)
              ? Row(
                  children: [
                    const Text(
                      "Repeat every: ",
                      overflow: TextOverflow.ellipsis,
                    ),
                    TextField(
                      controller: repeatSkipEditingController,
                      keyboardType: TextInputType.number,
                    ),
                    (frequency != Frequency.custom)
                        ? switch (frequency) {
                            Frequency.daily => const Text(
                                "days",
                                overflow: TextOverflow.ellipsis,
                              ),
                            Frequency.weekly => const Text(
                                "weeks",
                                overflow: TextOverflow.ellipsis,
                              ),
                            Frequency.monthly => const Text(
                                "months",
                                overflow: TextOverflow.ellipsis,
                              ),
                            Frequency.yearly => const Text(
                                "years",
                                overflow: TextOverflow.ellipsis,
                              ),
                            _ => const Text("")
                          }
                        : switch (customFreq) {
                            CustomFrequency.weekly => const Text("weeks"),
                            CustomFrequency.monthly => const Text("months"),
                            CustomFrequency.yearly => const Text("years"),
                          },
                  ],
                )
              : const SizedBox.shrink(),
          Padding(
              padding: const EdgeInsets.all(Constants.padding),
              child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                FilledButton.tonal(
                    onPressed: () {
                      setState(() {
                        frequency = cacheFreq;
                        customFreq = cacheCustom;
                        repeatSkip = cacheSkip;
                        weekDaySet = cacheWeekdays;
                      });
                      Navigator.pop(context);
                    },
                    child: const Text("Cancel")),
                FilledButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text("Save"),
                )
              ]))
        ],
      ),
    ));
  }

  ListTile buildTimeTile() {
    return ListTile(
        leading: const Icon(Icons.schedule_outlined),
        title: (null == startTime && null == dueTime)
            ? const Text("Add Times")
            : Row(children: [
                (null == startTime)
                    ? const Text("Start Time")
                    : Text(Jiffy.parseFromDateTime(startTime!).format(pattern: "hh:mm a")),
                const Text("-"),
                (null == dueTime)
                    ? const Icon(Icons.history_toggle_off_outlined)
                    : const Icon(Icons.schedule_outlined),
                (null == dueTime)
                    ? const Text("Due Time")
                    : Text(Jiffy.parseFromDateTime(dueTime!).format(pattern: "hh:mm a")),
              ]),
        trailing: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => setState(() {
            startTime = null;
            dueTime = null;
          }),
        ));
  }

  ListTile buildDateTile(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.today_outlined),
      // TODO: finish start and end + time.
      title: (null == startDate && null == dueDate)
          ? const Text("Add Dates")
          : Row(
              children: [
                (null == startDate)
                    ? const Text("Start Date")
                    : Text(Jiffy.parseFromDateTime(startDate!).format(pattern: "MMM d")),
                const Text("-"),
                (null == dueDate)
                    ? const Icon(Icons.today_outlined)
                    : const Icon(Icons.event_outlined),
                (null == dueDate)
                    ? const Text("Due Date")
                    : Text(
                        Jiffy.parseFromDateTime(dueDate!).format(pattern: "MMM d"),
                      )
              ],
            ),
      trailing: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => setState(() {
                if (null != startDate) {
                  weekDaySet.remove(startDate!.day);
                }

                startDate = null;
                dueDate = null;
              })),
      onTap: () async {
        DateTimeRange? initialRange = (null != startDate && null != dueDate)
            ? DateTimeRange(start: startDate!, end: dueDate!)
            : null;
        final DateTimeRange? picked = await showDateRangePicker(
          context: context,
          firstDate: DateTime(2015, 8),
          lastDate: DateTime(2101),
          initialDateRange: initialRange,
          fieldStartLabelText: "Start Date",
          fieldEndLabelText: "Due Date",
          fieldStartHintText: "Start Date",
          fieldEndHintText: "Due Date",
          saveText: "OK",
        );

        if (null != picked) {
          setState(() {
            startDate = picked.start;
            dueDate = picked.end;
            weekDaySet.add(startDate!.day);
          });
        }
      },
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
            const Expanded(
              child: AutoSizeText("Task Strain",
                  minFontSize: Constants.medium,
                  maxLines: 1,
                  softWrap: true,
                  style: Constants.headerStyle),
            ),
            Expanded(
              child: Tooltip(
                  message: "How draining is this task?",
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 100),
                    child: FittedBox(
                      fit: BoxFit.fitHeight,
                      child: Transform.rotate(
                          angle: -pi / 2,
                          child: getBatteryIcon(
                              weight: (taskType == TaskType.small) ? weight : sumWeight,
                              selected: false)),
                    ),
                  )),
            ),
            (smallScreen) ? const SizedBox.shrink() : const Spacer(),
          ],
        ),
      ),
      (taskType == TaskType.small)
          ? Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                const Icon(Icons.battery_full),
                Expanded(
                  child: Slider(
                    value: weight.toDouble(),
                    max: Constants.maxTaskWeight.toDouble(),
                    label: (weight > (Constants.maxTaskWeight / 2).floor())
                        ? " $weight ${Constants.lowBattery}"
                        : " $weight ${Constants.fullBattery}",
                    divisions: Constants.maxTaskWeight,
                    onChanged: (value) => setState(() {
                      checkClose = true;
                      weight = value.toInt();
                      realDuration = toDoProvider.calculateRealDuration(
                          weight: weight, duration: expectedDuration);
                    }),
                  ),
                ),
                const Icon(Icons.battery_1_bar),
              ],
            )
          : const SizedBox.shrink(),
    ]);
  }

  ListView buildSubTasksList() {
    return ListView.separated(
      // Possibly need scroll controller.
      shrinkWrap: true,
      itemCount: min(Constants.numTasks[taskType]!, shownTasks),
      separatorBuilder: (context, index) => const Divider(),
      itemBuilder: (BuildContext context, int index) {
        return CheckboxListTile(
            checkboxShape: const CircleBorder(),
            controlAffinity: ListTileControlAffinity.leading,
            shape: const CircleBorder(),
            title: Row(
              children: [
                IconButton(
                  icon: Constants.batteryIcons[subTasks[index].weight]!,
                  selectedIcon: Constants.selectedBatteryIcons[subTasks[index].weight]!,
                  onPressed: () {
                    showModalBottomSheet<void>(
                        context: context,
                        builder: (BuildContext context) {
                          return StatefulBuilder(
                            builder: (context, setState) => Center(
                                heightFactor: 1,
                                child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.drag_handle_rounded),
                                      const Text("Task Strain", style: Constants.headerStyle),
                                      Padding(
                                          padding: const EdgeInsets.all(Constants.padding),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                            children: [
                                              const Icon(Icons.battery_full),
                                              Expanded(
                                                child: Slider(
                                                  value: subTasks[index].weight.toDouble(),
                                                  max: Constants.maxTaskWeight.toDouble(),
                                                  label: (subTasks[index].weight >
                                                          (Constants.maxTaskWeight / 2).floor())
                                                      ? " ${subTasks[index].weight} ${Constants.lowBattery}"
                                                      : " ${subTasks[index].weight} ${Constants.fullBattery}",
                                                  divisions: Constants.maxTaskWeight,
                                                  onChanged: (value) => setState(() {
                                                    checkClose = true;
                                                    subTasks[index].weight = value.toInt();
                                                  }),
                                                ),
                                              ),
                                              const Icon(Icons.battery_1_bar),
                                            ],
                                          )),
                                    ])),
                          );
                        }).whenComplete(() => setState(() {
                          // TODO: refactor, there's no "Calculate Weight yet".
                          sumWeight = subTasks.fold(0, (p, c) => p + c.weight);
                          realDuration = toDoProvider.calculateRealDuration(
                              weight: sumWeight, duration: expectedDuration);
                        }));
                  },
                ),
                Expanded(
                  child: TextField(
                      controller: subTaskEditingController[index],
                      onChanged: (value) {
                        subTasks[index].name = value;
                        subTaskEditingController[index].value =
                            subTaskEditingController[index].value.copyWith(
                                  text: value,
                                  selection: TextSelection.collapsed(offset: value.length),
                                );
                      }),
                ),
              ],
            ),
            value: subTasks[index].completed,
            onChanged: (bool? value) => setState(() {
                  checkClose = true;
                  subTasks[index].completed = value!;
                }),

            // Delete Subtask
            secondary: IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () => setState(() {
                      SubTask st = subTasks.removeAt(index);
                      st = SubTask();
                      subTasks.add(st);
                      TextEditingController ct = subTaskEditingController.removeAt(index);
                      subTaskEditingController.add(ct);
                      ct.value = ct.value.copyWith(text: st.name);

                      shownTasks--;
                      shownTasks = max(shownTasks, 0);
                      // TODO: refactor, provider method.
                      sumWeight = subTasks.fold(0, (p, c) => p + c.weight);
                    })));
      },
    );
  }

  Row buildNameTile({bool smallScreen = false}) {
    return Row(
      children: [
        Transform.scale(
          scale: (smallScreen) ? Constants.largeCheckboxMinScale : Constants.largeCheckboxScale,
          child: Checkbox(
              splashRadius: 15,
              value: completed,
              onChanged: (bool? value) => setState(() {
                    checkClose = true;
                    completed = value!;
                  }),
              shape: const CircleBorder()),
        ),
        Expanded(
            child: Padding(
          padding: const EdgeInsets.all(Constants.padding),
          child: buildToDoName(smallScreen: smallScreen),
        )),
      ],
    );
  }

  ListTile buildMyDayTile() {
    return ListTile(
        title: AutoSizeText(
          (myDay)
              ? "Added to my Day"
              : (userProvider.myDayTotal + weight <=
                      (userProvider.curUser?.bandwidth ?? Constants.maxBandwidth))
                  ? "Add to My Day?"
                  : "Don't overload yourself, you deserve a rest",
          overflow: TextOverflow.visible,
          softWrap: true,
          minFontSize: Constants.medium,
          maxLines: 2,
        ),
        leading: (myDay)
            ? IconButton.filledTonal(
                icon: const Icon(Icons.wb_sunny),
                onPressed: () => setState(() {
                      checkClose = true;
                      myDay = !myDay;
                    }))
            : (userProvider.myDayTotal + weight <=
                    (userProvider.curUser?.bandwidth ?? Constants.maxBandwidth)
                ? IconButton.outlined(
                    icon: const Icon(Icons.wb_sunny_outlined),
                    onPressed: () => setState(() {
                          checkClose = true;
                          myDay = !myDay;
                        }))
                : const Icon(Icons.block_outlined)));
  }

  SegmentedButton<Priority> buildPriorityTile({bool smallScreen = false}) {
    return SegmentedButton<Priority>(
        selectedIcon: const Icon(Icons.flag_circle),
        style: ButtonStyle(
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        segments: Priority.values
            .map((Priority type) => ButtonSegment<Priority>(
                icon: Constants.priorityIcon[type],
                value: type,
                label: Text("${toBeginningOfSentenceCase(type.name)}",
                    softWrap: false,
                    overflow: TextOverflow.visible,
                    style: (smallScreen) ? Constants.minBodyText : null)))
            .toList(growable: false),
        selected: <Priority>{priority},
        onSelectionChanged: (Set<Priority> newSelection) => setState(() {
              checkClose = true;
              priority = newSelection.first;
            }));
  }

  AutoSizeTextField buildDescriptionTile({bool smallScreen = false}) {
    return AutoSizeTextField(
        controller: descriptionEditingController,
        maxLines: Constants.descripMaxLinesBeforeScroll,
        minLines:
            (smallScreen) ? Constants.descripMinLinesMobile : Constants.descripMinLinesDesktop,
        minFontSize: Constants.medium,
        decoration: InputDecoration(
          isDense: smallScreen,
          contentPadding: const EdgeInsets.all(Constants.innerPadding),
          hintText: "Description",
          border: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(Constants.roundedCorners)),
              borderSide: BorderSide(
                strokeAlign: BorderSide.strokeAlignOutside,
              )),
        ));
  }

  ListTile buildDurationTile(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.timer_outlined),
      title: (expectedDuration > 0)
          ? Row(
              children: [
                Flexible(
                  child: AutoSizeText(
                      "Expected: ${Duration(seconds: expectedDuration).toString().split(".").first}",
                      overflow: TextOverflow.visible,
                      minFontSize: Constants.small,
                      maxLines: 2,
                      softWrap: true),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: Constants.innerPadding),
                  child: Icon(
                    Icons.timer,
                  ),
                ),
                Flexible(
                  child: AutoSizeText(
                      "Actual: ${Duration(seconds: realDuration).toString().split(".").first}",
                      overflow: TextOverflow.visible,
                      minFontSize: Constants.small,
                      maxLines: 2,
                      softWrap: true),
                ),
              ],
            )
          : const AutoSizeText("Expected Duration Until Completion: ",
              overflow: TextOverflow.visible,
              minFontSize: Constants.small,
              maxLines: 2,
              softWrap: true),
      trailing: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => setState(() {
                expectedDuration = 0;
                realDuration = 0;
              })),
      onTap: () => showDialog<int>(
          context: context,
          builder: (BuildContext context) {
            return StatefulBuilder(
              builder: (context, setState) => buildDurationDialog(context, setState),
            );
          }).then((value) {
        setState(() {
          checkClose = true;
          expectedDuration = value ?? expectedDuration;
          realDuration = toDoProvider.calculateRealDuration(
              weight: (taskType == TaskType.small) ? weight : sumWeight,
              duration: expectedDuration);
          int tmp = expectedDuration;
          hours = tmp ~/ 3600;
          tmp %= 3600;
          minutes = tmp ~/ 60;
          tmp %= 60;
          seconds = tmp;
        });
      }),
    );
  }

// TODO: This needs rebuilding -> Size is bonkers.
  Dialog buildDurationDialog(BuildContext context, void Function(void Function()) setState) {
    // LOL.
    // int seconds = expectedDuration;
    // int hours = seconds ~/ 3600;
    // seconds %= 3600;
    // int minutes = seconds ~/ 60;
    // seconds %= 60;

    return Dialog(
        // shape: const RoundedRectangleBorder(
        //     borderRadius: BorderRadius.all(Radius.circular(Constants.roundedCorners))),
        child: Padding(
            padding: const EdgeInsets.all(Constants.innerPadding),
            child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                          minValue: 0,
                          maxValue: 100,
                          value: hours,
                          haptics: true,
                          onChanged: (value) {
                            SemanticsService.announce("$value, hours", Directionality.of(context));
                            setState(() => hours = value);
                          },
                        ),
                      ),
                      const Padding(
                          padding: EdgeInsets.symmetric(horizontal: Constants.padding),
                          child: Text(":", style: Constants.timeColon)),
                      Expanded(
                        child: NumberPicker(
                          minValue: 0,
                          maxValue: 59,
                          value: minutes,
                          haptics: true,
                          onChanged: (value) {
                            SemanticsService.announce(
                                "$value, minutes", Directionality.of(context));
                            setState(() => minutes = value);
                          },
                        ),
                      ),
                      const Padding(
                          padding: EdgeInsets.symmetric(horizontal: Constants.padding),
                          child: Text(":", style: Constants.timeColon)),
                      Expanded(
                        child: NumberPicker(
                          minValue: 0,
                          maxValue: 59,
                          value: seconds,
                          haptics: true,
                          onChanged: (value) {
                            SemanticsService.announce(
                                "$value, seconds", Directionality.of(context));
                            setState(() => seconds = value);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: Constants.padding),
                        child: FilledButton.tonalIcon(
                            icon: const Icon(Icons.close_outlined),
                            onPressed: () => Navigator.pop(context, 0),
                            label: const Text("Cancel")),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: Constants.padding),
                        child: FilledButton.icon(
                          icon: const Icon(Icons.done_outlined),
                          onPressed: () {
                            Navigator.pop(context, (hours * 3600) + (minutes * 60) + seconds);
                          },
                          label: const Text("Done"),
                        ),
                      ),
                    )
                  ])
                ])));
  }

  AutoSizeTextField buildToDoName({bool smallScreen = false}) {
    return AutoSizeTextField(
      maxLines: 1,
      minFontSize: Constants.medium,
      decoration: InputDecoration(
        isDense: smallScreen,
        suffixIcon: IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              nameEditingController.clear();
              setState(() => name = "");
            }),
        contentPadding: const EdgeInsets.all(Constants.innerPadding),
        border: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(Constants.roundedCorners)),
            borderSide: BorderSide(
              strokeAlign: BorderSide.strokeAlignOutside,
            )),
        hintText: "Task name",
        errorText: nameErrorText,
      ),
      controller: nameEditingController,
    );
  }

  IconButton buildCloseButton(BuildContext context) {
    return IconButton(
        onPressed: () {
          if (checkClose) {
            showModalBottomSheet<bool>(
                context: context,
                builder: (BuildContext context) {
                  return Center(
                      heightFactor: 1,
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.drag_handle_rounded),
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
                                padding: const EdgeInsets.all(Constants.padding),
                                child: FilledButton.tonalIcon(
                                  onPressed: () => Navigator.pop(context, false),
                                  label: const Text("Continue Editing"),
                                  icon: const Icon(
                                    Icons.edit_note_outlined,
                                  ),
                                ))
                          ]));
                }).then((willDiscard) {
              if (willDiscard ?? false) {
                // this should hopefully pop twice.
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

  SegmentedButton<TaskType> buildTaskTypeButton({bool smallScreen = false}) {
    return SegmentedButton<TaskType>(
        style: ButtonStyle(
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        segments: TaskType.values
            .map((TaskType type) => ButtonSegment<TaskType>(
                value: type,
                label: Text("${toBeginningOfSentenceCase(type.name)}",
                    softWrap: false,
                    overflow: TextOverflow.visible,
                    style: (smallScreen) ? Constants.minBodyText : null)))
            .toList(growable: false),
        selected: <TaskType>{taskType},
        onSelectionChanged: (Set<TaskType> newSelection) => setState(() {
              // -> TODO: Refactor this to be user-definable as a preference.
              checkClose = true;
              taskType = newSelection.first;
            }));
  }

  FutureBuilder<List<Group>> buildGroupList(
      Future<List<Group>> searchFuture, SearchController controller) {
    return FutureBuilder(
        future: searchFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            final List<Group>? groups = snapshot.data;
            if (null != groups) {
              return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: groups.length,
                  itemBuilder: (BuildContext context, int index) {
                    return ListTile(
                        title: Text(groups[index].name),
                        onTap: () =>
                            handleGroupSelection(group: groups[index], controller: controller));
                  });
            }
            // This is what to render if no data.
          }
          return const CircularProgressIndicator();
        });
  }

  SearchAnchor buildGroupBar() {
    return SearchAnchor.bar(
        viewConstraints: const BoxConstraints(maxHeight: Constants.maxHeightBeforeScroll),
        barHintText: (null == groupID) ? "Search Groups" : groupEditingController.text,
        suggestionsBuilder: (context, SearchController controller) {
          if (controller.text.isEmpty) {
            if (searchHistory.isNotEmpty) {
              return searchHistory
                  .map((MapEntry<String, int> groupData) => ListTile(
                        leading: const Icon(Icons.history),
                        title: Text(groupData.key),
                        onTap: () =>
                            handleHistorySelection(groupData: groupData, controller: controller),
                      ))
                  .toList();
            }
            final searchFuture = groupProvider.mostRecent(limit: 5);
            return [buildGroupList(searchFuture, controller)];
          }
          // Search query iterable.
          final searchFuture = groupProvider.searchGroups(searchString: controller.text);
          return [buildGroupList(searchFuture, controller)];
        });
  }
}
