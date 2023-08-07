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
  late bool checkClose;
  late bool checkDelete;

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
    checkDelete = userProvider.curUser!.checkDelete;

    scrollController = ScrollController();
    scrollPhysics = const BouncingScrollPhysics();
    nameEditingController = TextEditingController();
    nameEditingController.addListener(() {
      String newText = nameEditingController.text;
      SemanticsService.announce(newText, Directionality.of(context));
      name = newText;
    });

    groupEditingController = TextEditingController();
    groupEditingController.addListener(() {
      String newText = nameEditingController.text;
      SemanticsService.announce(newText, Directionality.of(context));
    });

    taskType = TaskType.small;

    name = "";
    description = "";

    weight = 0;
    sumWeight = 0;

    completed = false;

    repeatSkip = 1;

    subTasks = List.filled(Constants.maxNumTasks, SubTask());
  }

  void handleGroupSelection(Group group, SearchController controller) {
    // Controller logic
    controller.closeView(group.name);
    setState(() {
      groupID = group.id;
      if (searchHistory.length >= historyLength) {
        searchHistory.removeLast();
      }

      searchHistory.insert(0, MapEntry(group.name, group.id));
    });
  }

  void handleHistorySelection(
      MapEntry<String, int> groupData, SearchController controller) {
    controller.closeView(groupData.key);
    setState(() {
      groupID = groupData.value;
    });
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
                    children: [
                      const Text("New ToDo"),
                      IconButton(
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
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(
                                                  Icons.drag_handle_rounded),
                                              Padding(
                                                padding: const EdgeInsets.all(
                                                    padding),
                                                child: FilledButton.icon(
                                                  onPressed: () {
                                                    discard = true;
                                                    Navigator.pop(context);
                                                  },
                                                  label: const Text("Discard"),
                                                  icon: const Icon(Icons
                                                      .delete_forever_outlined),
                                                ),
                                              ),
                                              Padding(
                                                  padding: const EdgeInsets.all(
                                                      padding),
                                                  child: FilledButton.tonalIcon(
                                                    onPressed: () =>
                                                        Navigator.pop(context),
                                                    label: const Text(
                                                        "Continue Editing"),
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
                          selectedIcon: const Icon(Icons.close))
                    ]),
                ListView(
                  controller: scrollController,
                  physics: scrollPhysics,
                  children: [
                    // Title
                    TextField(
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(50)),
                            borderSide: BorderSide(
                              strokeAlign: BorderSide.strokeAlignOutside,
                            )),
                        hintText: "Task name",
                        errorText: nameErrorText,
                      ),
                      controller: nameEditingController,
                    ),

                    // TaskType - > TODO: refactor into a reusable widget method.
                    SegmentedButton<TaskType>(
                        segments: TaskType.values
                            .map((TaskType type) => ButtonSegment<TaskType>(
                                value: type,
                                label: Text(
                                    "${toBeginningOfSentenceCase(type.name)}")))
                            .toList(growable: false),
                        selected: <TaskType>{taskType},
                        onSelectionChanged: (Set<TaskType> newSelection) =>
                            setState(() {
                              // -> TODO: Refactor this to be user-definable as a preference.
                              checkClose = true;
                              taskType = newSelection.first;
                            })),
                    const Divider(),
                    // Group Picker
                    // TODO: figure out how to make this work with screen readers.
                    // TODO: write a database search by name query.
                    // TODO: refactor this into a reusable widget method.
                    SearchAnchor.bar(
                        barHintText: "Search Groups",
                        suggestionsBuilder:
                            (context, SearchController controller) {
                          if (controller.text.isEmpty) {
                            if (searchHistory.isNotEmpty) {
                              return searchHistory.map(
                                  (MapEntry<String, int> groupData) => ListTile(
                                      leading: const Icon(Icons.history),
                                      title: Text(groupData.key),
                                      onTap: () => handleHistorySelection(
                                          groupData, controller)));
                            }
                            // Database query to grab uh? Most recent.
                            return [];
                          }
                          // Search query iterable.
                          return [];
                        }),

                    const Divider(),
                    // Status (Complete + MyDay):

                    const Divider(),
                    // Description

                    const Divider(),
                    // Expected Duration / RealDuration -> Show status, on click, open a dialog.

                    const Divider(),
                    // DateTime -> Show status, on click, open a dialog.
                    const Divider(),
                    // Repeatable Stuff -> Show status, on click, open a dialog.
                    // Segmented buttons
                    const Divider(),
                    // Priority
                    // This should be a modal bottom sheet.
                  ],
                ),

                // Create Button
              ])),
    );
  }
}
