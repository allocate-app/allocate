import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../model/task/deadline.dart';
import '../../model/task/group.dart';
import '../../model/task/reminder.dart';
import '../../model/task/routine.dart';
import '../../model/task/todo.dart';
import '../../providers/deadline_provider.dart';
import '../../providers/group_provider.dart';
import '../../providers/reminder_provider.dart';
import '../../providers/routine_provider.dart';
import '../../providers/todo_provider.dart';
import '../../util/constants.dart';
import '../../util/enums.dart';
import '../../util/interfaces/i_model.dart';
import '../views/sub_views/update_deadline.dart';
import '../views/sub_views/update_group.dart';
import '../views/sub_views/update_reminder.dart';
import '../views/sub_views/update_routine.dart';
import '../views/sub_views/update_todo.dart';
import 'tiles.dart';

class GlobalModelSearch extends StatefulWidget {
  const GlobalModelSearch({
    Key? key,
    required this.mostRecent,
    required this.search,
  }) : super(key: key);

  final Future<List<IModel>> Function() mostRecent;
  final Future<List<IModel>> Function({required String searchString}) search;

  @override
  State<GlobalModelSearch> createState() => _GlobalModelSearch();
}

class _GlobalModelSearch extends State<GlobalModelSearch> {
  late final ToDoProvider toDoProvider;
  late final RoutineProvider routineProvider;
  late final ReminderProvider reminderProvider;
  late final DeadlineProvider deadlineProvider;
  late final GroupProvider groupProvider;

  final SearchController searchController = SearchController();
  late List<MapEntry<String, MapEntry<int, ModelType>>> searchHistory =
      List.empty(growable: true);

  @override
  initState() {
    super.initState();
    searchController.addListener(() {
      String newText = searchController.text;
      SemanticsService.announce(newText, Directionality.of(context));
    });

    toDoProvider = Provider.of<ToDoProvider>(context, listen: false);
    routineProvider = Provider.of<RoutineProvider>(context, listen: false);
    deadlineProvider = Provider.of<DeadlineProvider>(context, listen: false);
    reminderProvider = Provider.of<ReminderProvider>(context, listen: false);
    groupProvider = Provider.of<GroupProvider>(context, listen: false);
  }

  @override
  dispose() {
    searchController.dispose();
    super.dispose();
  }

  void updateHistory(
      {required MapEntry<String, MapEntry<int, ModelType>> data}) {
    setState(() {
      if (searchHistory.length >= Constants.historyLength) {
        searchHistory.removeLast();
      }
      searchHistory.insert(0, data);
    });
  }

  Future<void> updateIModel({required MapEntry<int, ModelType> data}) async {
    switch (data.value) {
      case ModelType.task:
        await toDoProvider.getToDoByID(id: data.key).then((ToDo? toDo) async {
          if (null == toDo) {
            return;
          }
          return await openDialog(dialog: UpdateToDoScreen(initialToDo: toDo));
        });
        break;
      case ModelType.deadline:
        await deadlineProvider
            .getDeadlineByID(id: data.key)
            .then((Deadline? deadline) async {
          if (null == deadline) {
            return;
          }
          return await openDialog(
              dialog: UpdateDeadlineScreen(initialDeadline: deadline));
        });
        break;
      case ModelType.reminder:
        await reminderProvider
            .getReminderByID(id: data.key)
            .then((Reminder? reminder) async {
          if (null == reminder) {
            return;
          }
          return await openDialog(
              dialog: UpdateReminderScreen(initialReminder: reminder));
        });
        break;
      case ModelType.routine:
        await routineProvider
            .getRoutineByID(id: data.key)
            .then((Routine? routine) async {
          if (null == routine) {
            return;
          }
          return await openDialog(
              dialog: UpdateRoutineScreen(initialRoutine: routine));
        });
        break;
      case ModelType.group:
        await groupProvider
            .getGroupByID(id: data.key)
            .then((Group? group) async {
          if (null == group) {
            return;
          }
          return await openDialog(
              dialog: UpdateGroupScreen(initialGroup: group));
        });
        break;
      default:
        break;
    }
  }

  Future<void> openDialog({required Widget dialog}) async {
    await showDialog(
        barrierDismissible: false,
        useRootNavigator: false,
        context: context,
        builder: (BuildContext context) => dialog);
  }

  @override
  Widget build(context) {
    return SearchAnchor(
      isFullScreen: false,
      searchController: searchController,
      builder: (BuildContext context, SearchController controller) {
        return IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () => controller.openView());
      },
      suggestionsBuilder: (BuildContext context, SearchController controller) {
        if (controller.text.isEmpty) {
          if (searchHistory.isNotEmpty) {
            return searchHistory
                .map((MapEntry<String, MapEntry<int, ModelType>> data) =>
                    Tiles.historyTile(
                        title: data.key,
                        onTap: () async {
                          controller.closeView("");
                          await updateIModel(data: data.value);
                        },
                        trailing: modelType(modelType: data.value.value)))
                .toList();
          }
          final searchFuture = widget.mostRecent();
          return [
            buildFutureList(searchFuture: searchFuture, controller: controller)
          ];
        }
        final searchFuture = widget.search(searchString: controller.text);
        return [
          buildFutureList(searchFuture: searchFuture, controller: controller)
        ];
      },
    );
  }

  FutureBuilder<List<IModel>> buildFutureList(
      {required Future<List<IModel>> searchFuture,
      required SearchController controller}) {
    return FutureBuilder(
      future: searchFuture,
      builder: (BuildContext context, AsyncSnapshot<List<IModel>> snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          final List<IModel>? data = snapshot.data;
          if (null != data && data.isNotEmpty) {
            return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: data.length,
                itemBuilder: (BuildContext context, int index) {
                  return ListTile(
                      shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(
                              Radius.circular(Constants.semiCircular))),
                      title: AutoSizeText(data[index].name),
                      onTap: () async {
                        controller.closeView("");
                        updateHistory(
                            data: MapEntry(
                                data[index].name,
                                MapEntry(
                                    data[index].id, data[index].modelType)));
                        await updateIModel(
                            data: MapEntry(
                                data[index].id, data[index].modelType));
                      },
                      trailing: modelType(modelType: data[index].modelType));
                });
          }
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget modelType({required ModelType modelType}) => DecoratedBox(
      decoration: BoxDecoration(
          shape: BoxShape.rectangle,
          borderRadius:
              const BorderRadius.all(Radius.circular(Constants.semiCircular)),
          border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant,
              strokeAlign: BorderSide.strokeAlignOutside)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Constants.padding),
        child: AutoSizeText(
          toBeginningOfSentenceCase(modelType.name.toString())!,
          minFontSize: Constants.large,
          overflow: TextOverflow.visible,
          softWrap: false,
          maxLines: 1,
        ),
      ));
}
