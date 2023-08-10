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

  late final List<SubTask> subTasks;

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
    //

    initializeControllers();

    // Refactor this into the user provider class.
    initializeParameters();
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
    expectedDuration = 0;
    realDuration = 0;

    frequency = Frequency.once;
    customFreq = CustomFrequency.weekly;

    repeatSkip = 1;

    subTasks = List.filled(Constants.maxNumTasks, SubTask());
    weekDaySet = <int>{};
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
    weight =
        remap(x: weight, inMin: 0, inMax: Constants.maxTaskWeight, outMin: 2, outMax: 4) as int;
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
          // These are just for shape.
          child: Row(
            mainAxisSize: (largeScreen) ? MainAxisSize.min : MainAxisSize.max,
            children: [
              Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    // Title && Close Button
                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [const Text("New Task"), buildCloseButton(context)]),
                    ListView(
                      controller: scrollController,
                      physics: scrollPhysics,
                      children: [
                        // Title + status
                        buildNameTile(),
                        // TaskType
                        buildTaskType(),
                        // Subtasks
                        (taskType != TaskType.small)
                            ? Padding(
                                padding: const EdgeInsets.symmetric(horizontal: Constants.padding),
                                child: buildSubTasksList(),
                              )
                            : const SizedBox.shrink(),

                        buildWeightTile(),

                        const Divider(),
                        // My Day
                        buildMyDayTile(),
                        const Divider(),
                        // Priority
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: Constants.padding),
                          child: buildPriorityTile(),
                        ),

                        const PaddedDivider(padding: Constants.padding),

                        // Group Picker
                        // TODO: figure out how to make this work with screen readers.
                        // I don't know if SemanticsService will actually work.
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: Constants.padding),
                          child: buildGroupBar(),
                        ),

                        const PaddedDivider(padding: Constants.padding),

                        // Description
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: Constants.padding),
                          child: buildDescriptionTile(
                              descriptionSize: (largeScreen)
                                  ? Constants.descripSizeDesktop
                                  : Constants.descripSizeMobile),
                        ),

                        const PaddedDivider(padding: Constants.padding),
                        // Expected Duration / RealDuration -> Show status, on click, open a dialog.
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: Constants.padding),
                          child: buildDurationTile(context),
                        ),

                        const PaddedDivider(padding: Constants.padding),
                        // DateTime -> Show status, on click, open a dialog.
                        //startDate
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: Constants.padding),
                          child: buildDateTile(context),
                        ),

                        const PaddedDivider(padding: Constants.padding),
                        // Time
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: Constants.padding),
                          child: buildTimeTile(),
                        ),

                        const PaddedDivider(padding: Constants.padding),
                        // Repeatable Stuff -> Show status, on click, open a dialog.
                        buildRepeatableTile(context),
                      ],
                    ),

                    // Create Button
                    Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                      IconButton.filled(
                          icon: const Icon(Icons.add_outlined),
                          selectedIcon: const Icon(Icons.add),
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
                                  content: Text(e.cause, style: TextStyle(color: errorColor)),
                                  action: SnackBarAction(label: "Dismiss", onPressed: () {}),
                                  duration: const Duration(milliseconds: 1500),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(Constants.circular),
                                  ),
                                  width: (MediaQuery.sizeOf(context).width) / 2,
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: Constants.padding),
                                ));
                              },
                                      test: (e) =>
                                          e is FailureToCreateException ||
                                          e is FailureToUploadException);
                            }
                            // Then save.
                          })
                    ])
                  ]),
            ],
          )),
    );
  }

  ListTile buildRepeatableTile(BuildContext context) {
    return ListTile(
        leading: const Icon(Icons.event_repeat_outlined),
        title: (frequency == Frequency.once)
            ? const Text("Set Recurring?")
            : Text(toBeginningOfSentenceCase(frequency.name)!),
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
          const Row(mainAxisAlignment: MainAxisAlignment.start, children: [Text("Set Recurring")]),
          // Segmented button
          SegmentedButton<Frequency>(
            segments: Frequency.values
                .map((Frequency frequency) => ButtonSegment<Frequency>(
                      value: frequency,
                      label: Text("${toBeginningOfSentenceCase(frequency.name)}"),
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
                    const Text("Repeat every: "),
                    // RETURN HERE
                    TextField(
                      controller: repeatSkipEditingController,
                      keyboardType: TextInputType.number,
                    ),
                    (frequency != Frequency.custom)
                        ? switch (frequency) {
                            Frequency.daily => const Text("days"),
                            Frequency.weekly => const Text("weeks"),
                            Frequency.monthly => const Text("months"),
                            Frequency.yearly => const Text("years"),
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
      const Text("How draining is this task?"),
      // Ternary widget pls.
      Row(
        children: [
          const Icon(Icons.battery_full),
          (taskType == TaskType.small)
              ? Slider(
                  value: weight as double,
                  max: Constants.maxTaskWeight as double,
                  label: (weight > (Constants.maxTaskWeight / 2).round())
                      ? Constants.fullBattery
                      : Constants.lowBattery,
                  divisions: Constants.maxTaskWeight,
                  onChanged: (value) => setState(() {
                    checkClose = true;
                    weight = value as int;
                  }),
                )
              : Slider(
                  value: sumWeight as double,
                  max: Constants.maxTaskWeight * Constants.numTasks[taskType]! as double,
                  divisions: Constants.numTasks[taskType],
                  onChanged: null),
          const Icon(Icons.battery_2_bar),
        ],
      ),
    ]);
  }

  ListView buildSubTasksList() {
    return ListView.separated(
      itemCount: subTasks.length,
      separatorBuilder: (context, index) => const Divider(),
      itemBuilder: (BuildContext context, int index) {
        return CheckboxListTile(
            controlAffinity: ListTileControlAffinity.leading,
            shape: const CircleBorder(),
            title: TextField(
                controller: TextEditingController(text: subTasks[index].name),
                decoration: const InputDecoration(labelText: "Add step"),
                onChanged: (value) => setState(() {
                      SemanticsService.announce(value, Directionality.of(context));
                      checkClose = true;
                      subTasks[index].name = value;
                    })),
            value: subTasks[index].completed,
            onChanged: (bool? value) => setState(() {
                  checkClose = true;
                  subTasks[index].completed = value!;
                }),
            // Subtask weight
            secondary: IconButton(
              icon: getBatteryIcon(weight: subTasks[index].weight, selected: false),
              selectedIcon: getBatteryIcon(weight: subTasks[index].weight, selected: true),
              onPressed: () {
                showModalBottomSheet(
                    context: context,
                    builder: (BuildContext context) {
                      return Center(
                          heightFactor: 1,
                          child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.drag_handle_rounded),
                                const Text("How draining is this task?"),
                                Row(
                                  children: [
                                    const Icon(Icons.battery_full),
                                    Slider(
                                      value: subTasks[index].weight as double,
                                      max: Constants.maxTaskWeight as double,
                                      label: (subTasks[index].weight >
                                              (Constants.maxTaskWeight / 2).round())
                                          ? Constants.fullBattery
                                          : Constants.lowBattery,
                                      divisions: Constants.maxTaskWeight,
                                      onChanged: (value) => setState(() {
                                        checkClose = true;
                                        subTasks[index].weight = value as int;
                                        sumWeight = subTasks.fold(0, (p, c) => p + c.weight);
                                      }),
                                    ),
                                    const Icon(Icons.battery_2_bar),
                                  ],
                                ),
                              ]));
                    });
              },
            ));
      },
    );
  }

  Row buildNameTile() {
    return Row(
      children: [
        Checkbox(
            value: completed,
            onChanged: (bool? value) => setState(() {
                  checkClose = true;
                  completed = value!;
                }),
            shape: const CircleBorder()),
        buildToDoName(),
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
              borderRadius: BorderRadius.all(Radius.circular(Constants.circular)),
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
                      TextField(
                          controller: TextEditingController(
                            text: "$hours",
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            hours = int.tryParse(value) ?? hours;
                            SemanticsService.announce("$hours hours", Directionality.of(context));
                          }),
                      const Padding(
                          padding: EdgeInsets.symmetric(horizontal: Constants.padding),
                          child: Text(":")),
                      TextField(
                          controller: TextEditingController(
                            text: "$minutes",
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            minutes = int.tryParse(value) ?? minutes;
                            SemanticsService.announce(
                                "$minutes minutes", Directionality.of(context));
                          }),
                      const Padding(
                          padding: EdgeInsets.symmetric(horizontal: Constants.padding),
                          child: Text(":")),
                      TextField(
                          controller: TextEditingController(
                            text: "$seconds",
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            hours = int.tryParse(value) ?? seconds;
                            SemanticsService.announce(
                                "$seconds seconds", Directionality.of(context));
                          }),
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

  SegmentedButton<TaskType> buildTaskType() {
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
                      trailing: IconButton(
                          icon: const Icon(Icons.close_outlined),
                          onPressed: () => setState(() => groupID = null))))
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
