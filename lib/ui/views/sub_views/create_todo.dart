import "dart:math";

import "package:allocate/util/constants.dart";
import "package:flutter/material.dart";
import "package:flutter/semantics.dart";
import "package:intl/intl.dart";
import "package:jiffy/jiffy.dart";
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
    int numTasks = (taskType == TaskType.small) ? 1 : Constants.numTasks[taskType]!;

    // Getting zerodiv, lol.
    weight =
        remap(x: weight, inMin: 0, inMax: Constants.maxTaskWeight * numTasks, outMin: 0, outMax: 5)
            .toInt();
    if (selected) {
      return Constants.selectedBatteryIcons[weight]!;
    }
    return Constants.batteryIcons[weight]!;
  }

  @override
  Widget build(BuildContext context) {
    final Color errorColor = Theme.of(context).colorScheme.error;

    bool largeScreen = (MediaQuery.of(context).size.width >= Constants.landscapePx);
    return Dialog(
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(Constants.roundedCorners))),
      child: Padding(
        padding: const EdgeInsets.all(Constants.padding),
        child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            children: [
              // Title && Close Button
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: Constants.padding),
                  child: Text(
                    "New Task",
                    overflow: TextOverflow.ellipsis,
                    style: Constants.headerStyle,
                  ),
                ),
                buildCloseButton(context)
              ]),
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
                          horizontal: (largeScreen) ? Constants.innerPadding : Constants.padding),
                      child: buildNameTile(),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: Constants.padding),
                      child: buildWeightTile(),
                    ),
                    const PaddedDivider(padding: Constants.innerPadding),
                    // TaskType
                    const Center(child: Text("Task Type", style: Constants.headerStyle)),
                    Padding(
                      padding: const EdgeInsets.all(Constants.innerPadding),
                      child: buildTaskTypeButton(),
                    ),
                    // Subtasks
                    (taskType != TaskType.small)
                        ? Padding(
                            padding: const EdgeInsets.fromLTRB(Constants.padding,
                                Constants.padding / 2, Constants.padding, Constants.innerPadding),
                            child: Container(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: Constants.innerPadding),
                              decoration: BoxDecoration(
                                border: Border.all(strokeAlign: BorderSide.strokeAlignOutside),
                                borderRadius: BorderRadius.circular(Constants.roundedCorners),
                              ),
                              child: Column(children: [
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
                              ]),
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
                      child: Center(child: Text("Priority", style: Constants.headerStyle)),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: Constants.padding),
                      child: buildPriorityTile(),
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
                      child: buildDescriptionTile(
                          descriptionSize: (largeScreen)
                              ? Constants.descripSizeDesktop
                              : Constants.descripSizeMobile),
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
                    buildRepeatableTile(context),
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

  Column buildWeightTile() {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.all(Constants.padding),
        child: Stack(
          alignment: Alignment.centerLeft,
          children: [
            const Text("Task Strain", style: Constants.headerStyle),
            Align(
              alignment: Alignment.center,
              child: Transform.scale(
                scale: Constants.batteryScale,
                child: Transform.rotate(
                    angle: -pi / 2,
                    child: IconButton(
                      icon: getBatteryIcon(
                          weight: (taskType == TaskType.small) ? weight : sumWeight,
                          selected: false),
                      onPressed: null,
                    )),
              ),
            ),
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
                        }).whenComplete(() => setState(() {}));
                  },
                ),
                Expanded(
                  child: TextField(
                    controller: subTaskEditingController[index],
                  ),
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
                      for (int i = index; i < subTasks.length - 1; i++) {
                        subTasks[i] = subTasks[i + 1].copy();
                        subTaskEditingController[i].text = subTasks[i + 1].name;
                      }
                      subTasks[subTasks.length - 1] = SubTask();
                      subTaskEditingController[subTasks.length - 1].text =
                          subTasks[subTasks.length - 1].name;

                      shownTasks--;
                      shownTasks = max(shownTasks, 0);
                    })));
      },
    );
  }

  Row buildNameTile() {
    return Row(
      children: [
        Transform.scale(
          scale: Constants.checkboxScale,
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
          child: buildToDoName(),
        )),
      ],
    );
  }

  ListTile buildMyDayTile() {
    return ListTile(
        title: Text((myDay)
            ? "Added to my Day"
            : (userProvider.myDayTotal + weight <=
                    (userProvider.curUser?.bandwidth ?? Constants.maxBandwidth))
                ? "Add to My Day?"
                : "Don't overload yourself, you deserve a rest"),
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

  SegmentedButton<Priority> buildPriorityTile() {
    return SegmentedButton<Priority>(
        selectedIcon: const Icon(Icons.flag_circle),
        segments: Priority.values
            .map((Priority type) => ButtonSegment<Priority>(
                icon: Constants.priorityIcon[type],
                value: type,
                label: Text("${toBeginningOfSentenceCase(type.name)}")))
            .toList(growable: false),
        selected: <Priority>{priority},
        onSelectionChanged: (Set<Priority> newSelection) => setState(() {
              checkClose = true;
              priority = newSelection.first;
            }));
  }

  TextField buildDescriptionTile({required int descriptionSize}) {
    return TextField(
        controller: descriptionEditingController,
        maxLines: null,
        minLines: descriptionSize,
        decoration: const InputDecoration(
          labelText: "Description",
          border: OutlineInputBorder(
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
          ? Text(
              "Expected Duration: ${Duration(seconds: expectedDuration).toString().split(".").first} \t Actual Duration: ${Duration(seconds: realDuration).toString().split(".").first}")
          : const Text("Expected Duration Until Completion: "),
      onTap: () => showDialog(
          context: context,
          builder: (BuildContext context) {
            return buildDurationDialog(context);
          }),
    );
  }

  Dialog buildDurationDialog(BuildContext context) {
    int seconds = expectedDuration;
    int hours = seconds ~/ 3600;
    seconds %= 3600;
    int minutes = seconds ~/ 60;
    seconds %= 60;

    return Dialog(
        child: Padding(
            padding: const EdgeInsets.all(Constants.padding),
            child: Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      SizedBox(
                        child: TextField(
                            controller: TextEditingController(
                              text: "$hours",
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (value) {
                              hours = int.tryParse(value) ?? hours;
                              SemanticsService.announce("$hours hours", Directionality.of(context));
                            }),
                      ),
                      const Padding(
                          padding: EdgeInsets.symmetric(horizontal: Constants.padding),
                          child: Text(":")),
                      SizedBox(
                        child: TextField(
                            controller: TextEditingController(
                              text: "$minutes",
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (value) {
                              minutes = int.tryParse(value) ?? minutes;
                              SemanticsService.announce(
                                  "$minutes minutes", Directionality.of(context));
                            }),
                      ),
                      const Padding(
                          padding: EdgeInsets.symmetric(horizontal: Constants.padding),
                          child: Text(":")),
                      SizedBox(
                        child: TextField(
                            controller: TextEditingController(
                              text: "$seconds",
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (value) {
                              hours = int.tryParse(value) ?? seconds;
                              SemanticsService.announce(
                                  "$seconds seconds", Directionality.of(context));
                            }),
                      ),
                    ],
                  ),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                    OutlinedButton(
                        onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
                    FilledButton.tonal(
                      onPressed: () {
                        setState(() {
                          checkClose = true;
                          expectedDuration = seconds + (60 * minutes) + (3600 * hours);
                          realDuration = toDoProvider.calculateRealDuration(
                              weight: (taskType == TaskType.small) ? weight : sumWeight,
                              duration: expectedDuration);
                        });
                        Navigator.pop(context);
                      },
                      child: const Text("Done"),
                    )
                  ])
                ]),
              ],
            )));
  }

  TextField buildToDoName() {
    return TextField(
      decoration: InputDecoration(
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
          bool discard = true;
          if (checkClose) {
            discard = false;
            showModalBottomSheet<void>(
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
                                  discard = true;
                                  Navigator.pop(context);
                                },
                                label: const Text("Discard"),
                                icon: const Icon(Icons.delete_forever_outlined),
                              ),
                            ),
                            Padding(
                                padding: const EdgeInsets.all(Constants.padding),
                                child: FilledButton.tonalIcon(
                                  onPressed: () => Navigator.pop(context),
                                  label: const Text("Continue Editing"),
                                  icon: const Icon(
                                    Icons.edit_note_outlined,
                                  ),
                                ))
                          ]));
                });
          }
          if (discard) {
            Navigator.pop(context);
          }
          setState(() => checkClose = false);
        },
        icon: const Icon(Icons.close_outlined),
        selectedIcon: const Icon(Icons.close));
  }

  SegmentedButton<TaskType> buildTaskTypeButton() {
    return SegmentedButton<TaskType>(
        segments: TaskType.values
            .map((TaskType type) => ButtonSegment<TaskType>(
                value: type, label: Text("${toBeginningOfSentenceCase(type.name)}")))
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
