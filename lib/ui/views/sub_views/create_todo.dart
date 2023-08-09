import "dart:io";

import "package:allocate/util/constants.dart";
import "package:allocate/util/interfaces/crossbuild.dart";
import "package:flutter/material.dart";
import "package:flutter/semantics.dart";
import "package:intl/intl.dart";
import "package:provider/provider.dart";

import "../../../model/task/group.dart";
import "../../../model/task/subtask.dart";
import "../../../providers/group_provider.dart";
import "../../../providers/todo_provider.dart";
import "../../../providers/user_provider.dart";
import "../../../util/enums.dart";
import "../../../util/numbers.dart";

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

class _CreateToDoScreen extends State<CreateToDoScreen> implements CrossBuild {
  static const double padding = 8.0;
  static const int historyLength = 5;
  static const double smallRoundCorners = 50;
  static const double lgRoundCorners = 30;
  late bool checkClose;
  late bool checkDelete;

  static const String lowBattery = "🪫";
  static const String fullBattery = "🔋";

  static const Map<int, Icon> batteryIcons = {
    0: Icon(Icons.battery_full_outlined),
    1: Icon(Icons.battery_5_bar_outlined),
    2: Icon(Icons.battery_4_bar_outlined),
    3: Icon(Icons.battery_3_bar_outlined),
    4: Icon(Icons.battery_2_bar_outlined),
  };

  static const Map<int, Icon> selectedBatteryIcons = {
    0: Icon(Icons.battery_full),
    1: Icon(Icons.battery_5_bar),
    2: Icon(Icons.battery_4_bar),
    3: Icon(Icons.battery_3_bar),
    4: Icon(Icons.battery_2_bar),
  };
  static const Map<Priority, Icon> priorityIcon = {
    Priority.low: Icon(Icons.low_priority_outlined),
    Priority.medium: Icon(Icons.priority_high),
    Priority.high: Icon(Icons.local_fire_department_outlined),
  };

  // Provider (Needs user values).
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
  DateTime? dueDate;

  // Repeat
  late Frequency frequency;
  // Only show on frequency.custom;
  late CustomFrequency customFrequency;
  // Only expose this when weekly/daily/monthly,yearly;
  late int repeatSkip;

  // Days of the week -> Need an enum, names map to indices.
  // ON creation -> Loop and map values
  late Set set;

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
    userProvider = Provider.of<UserProvider>(context, listen: false);
    toDoProvider = Provider.of<ToDoProvider>(context, listen: false);
    groupProvider = Provider.of<GroupProvider>(context, listen: false);
    //
    checkClose = false;
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

    taskType = TaskType.small;

    name = "";
    description = "";

    weight = 0;
    sumWeight = 0;

    completed = false;
    expectedDuration = 0;
    realDuration = 0;

    repeatSkip = 1;

    subTasks = List.filled(Constants.maxNumTasks, SubTask());
  }

  @override
  void dispose() {
    nameEditingController.dispose();
    groupEditingController.dispose();
    descriptionEditingController.dispose();
    super.dispose();
  }

  void handleGroupSelection({required Group group, required SearchController controller}) {
    // Controller logic
    controller.closeView(group.name);
    setState(() {
      checkClose = true;
      groupID = group.id;
      if (searchHistory.length >= historyLength) {
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

  Icon getBatteryIcon({required int weight, required bool selected}) {
    weight =
        remap(x: weight, inMin: 0, inMax: Constants.maxTaskWeight, outMin: 2, outMax: 4) as int;
    if (selected) {
      return selectedBatteryIcons[weight]!;
    }
    return batteryIcons[weight]!;
  }

  @override
  Widget build(BuildContext context) {
    if (Platform.isAndroid || Platform.isIOS) {
      return buildMobile(context: context);
    }
    return buildDesktop(context: context);
  }

  @override
  Widget buildDesktop({required BuildContext context}) {
    // LOL lord help me.
    // At the very least, a lot of this logic can be copied over.
    return Dialog();
  }

  @override
  Widget buildMobile({required BuildContext context}) {
    return Dialog(
      child: Padding(
          padding: const EdgeInsets.all(padding),
          child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
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
                            padding: const EdgeInsets.symmetric(horizontal: padding),
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
                      padding: const EdgeInsets.symmetric(horizontal: padding),
                      child: buildPriorityTile(),
                    ),

                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: padding),
                      child: Divider(),
                    ),

                    // Group Picker
                    // TODO: figure out how to make this work with screen readers.
                    // I don't know if SemanticsService will actually work.
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: padding),
                      child: buildGroupBar(),
                    ),

                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: padding),
                      child: Divider(),
                    ),

                    // Description
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: padding),
                      child: buildDescriptionTile(),
                    ),

                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: padding),
                      child: Divider(),
                    ),
                    // Expected Duration / RealDuration -> Show status, on click, open a dialog.
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: padding),
                      child: buildDurationTile(context),
                    ),

                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: padding),
                      child: Divider(),
                    ),
                    // DateTime -> Show status, on click, open a dialog.

                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: padding),
                      child: Divider(),
                    ),
                    // Repeatable Stuff -> Show status, on click, open a dialog.

                    // Segmented buttons for days of week.
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: padding),
                      child: Divider(),
                    ),
                  ],
                ),

                // Create Button
              ])),
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
                  label:
                      (weight > (Constants.maxTaskWeight / 2).round()) ? fullBattery : lowBattery,
                  divisions: Constants.maxTaskWeight,
                  onChanged: (value) => setState(() {
                    checkClose = true;
                    weight = value as int;
                  }),
                )
              : Slider(
                  value: sumWeight as double,
                  max: Constants.maxNumTasks * Constants.numTasks[taskType]! as double,
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
                                          ? fullBattery
                                          : lowBattery,
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
                icon: priorityIcon[type],
                value: type,
                label: Text("${toBeginningOfSentenceCase(type.name)}")))
            .toList(growable: false),
        selected: <Priority>{priority},
        onSelectionChanged: (Set<Priority> newSelection) => setState(() {
              checkClose = true;
              priority = newSelection.first;
            }));
  }

  TextField buildDescriptionTile() {
    return TextField(
        controller: descriptionEditingController,
        maxLines: null,
        minLines: 5,
        decoration: const InputDecoration(
          labelText: "Description",
          border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(smallRoundCorners)),
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
            padding: const EdgeInsets.all(padding),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextField(
                      controller: TextEditingController(
                        text: "$hours",
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        hours = int.tryParse(value) ?? 0;
                        SemanticsService.announce("$hours hours", Directionality.of(context));
                      }),
                  const Padding(
                      padding: EdgeInsets.symmetric(horizontal: padding), child: Text(":")),
                  TextField(
                      controller: TextEditingController(
                        text: "$minutes",
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        minutes = int.tryParse(value) ?? 0;
                        SemanticsService.announce("$minutes minutes", Directionality.of(context));
                      }),
                  const Padding(
                      padding: EdgeInsets.symmetric(horizontal: padding), child: Text(":")),
                  TextField(
                      controller: TextEditingController(
                        text: "$seconds",
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        hours = int.tryParse(value) ?? 0;
                        SemanticsService.announce("$seconds seconds", Directionality.of(context));
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
            ])));
  }

  TextField buildToDoName() {
    return TextField(
      decoration: InputDecoration(
        border: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(lgRoundCorners)),
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
                              padding: const EdgeInsets.all(padding),
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
                                padding: const EdgeInsets.all(padding),
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
        barHintText: "Search Groups",
        suggestionsBuilder: (context, SearchController controller) {
          if (controller.text.isEmpty) {
            if (searchHistory.isNotEmpty) {
              return searchHistory.map((MapEntry<String, int> groupData) => ListTile(
                  leading: const Icon(Icons.history),
                  title: Text(groupData.key),
                  onTap: () =>
                      handleHistorySelection(groupData: groupData, controller: controller)));
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
