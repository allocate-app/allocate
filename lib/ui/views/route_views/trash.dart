import "dart:io";

import "package:auto_size_text/auto_size_text.dart";
import "package:auto_size_text_field/auto_size_text_field.dart";
import "package:flutter/material.dart";
import "package:flutter/semantics.dart";
import "package:intl/intl.dart";
import "package:provider/provider.dart";

import "../../../model/task/deadline.dart";
import "../../../model/task/group.dart";
import "../../../model/task/reminder.dart";
import "../../../model/task/routine.dart";
import "../../../model/task/todo.dart";
import "../../../providers/deadline_provider.dart";
import "../../../providers/event_provider.dart";
import "../../../providers/group_provider.dart";
import "../../../providers/reminder_provider.dart";
import "../../../providers/routine_provider.dart";
import "../../../providers/search_provider.dart";
import "../../../providers/subtask_provider.dart";
import "../../../providers/todo_provider.dart";
import "../../../providers/user_provider.dart";
import "../../../util/constants.dart";
import "../../../util/enums.dart";
import "../../../util/exceptions.dart";
import "../../../util/interfaces/i_model.dart";
import "../../widgets/check_delete_dialog.dart";
import "../../widgets/expanded_listtile.dart";
import "../../widgets/listviews.dart";
import "../../widgets/paginating_listview.dart";
import "../../widgets/screen_header.dart";
import "../../widgets/tiles.dart";

class TrashScreen extends StatefulWidget {
  const TrashScreen({super.key});

  @override
  State<TrashScreen> createState() => _TrashScreen();
}

class _TrashScreen extends State<TrashScreen> {
  late final ToDoProvider toDoProvider;
  late final ReminderProvider reminderProvider;
  late final DeadlineProvider deadlineProvider;
  late final RoutineProvider routineProvider;
  late final GroupProvider groupProvider;
  late final UserProvider userProvider;
  late final SubtaskProvider subtaskProvider;
  late final EventProvider eventProvider;

  late final ScrollController mainScrollController;
  late final ScrollPhysics scrollPhysics;

  late final TextEditingController _searchController;

  late SearchProvider searchProvider;

  bool get noDeletes =>
      toDoProvider.toDos.isEmpty &&
      routineProvider.routines.isEmpty &&
      reminderProvider.reminders.isEmpty &&
      deadlineProvider.deadlines.isEmpty &&
      groupProvider.groups.isEmpty;

  @override
  void initState() {
    super.initState();
    initializeProviders();
    initializeControllers();
  }

  void initializeProviders() {
    toDoProvider = Provider.of<ToDoProvider>(context, listen: false);
    routineProvider = Provider.of<RoutineProvider>(context, listen: false);
    deadlineProvider = Provider.of<DeadlineProvider>(context, listen: false);
    reminderProvider = Provider.of<ReminderProvider>(context, listen: false);
    groupProvider = Provider.of<GroupProvider>(context, listen: false);
    subtaskProvider = Provider.of<SubtaskProvider>(context, listen: false);
    userProvider = Provider.of<UserProvider>(context, listen: false);

    searchProvider = Provider.of<SearchProvider>(context, listen: false);
    eventProvider = Provider.of<EventProvider>(context, listen: false);
  }

  void initializeControllers() {
    mainScrollController = ScrollController();

    ScrollPhysics parentScrollPhysics = (Platform.isIOS || Platform.isMacOS)
        ? const BouncingScrollPhysics()
        : const ClampingScrollPhysics();
    scrollPhysics = AlwaysScrollableScrollPhysics(parent: parentScrollPhysics);
    _searchController =
        TextEditingController(text: searchProvider.searchString);
    _searchController.addListener(searchDeleted);
  }

  @override
  void dispose() {
    mainScrollController.dispose();
    _searchController.removeListener(searchDeleted);
    _searchController.dispose();
    super.dispose();
  }

  void searchDeleted() {
    String searchText = _searchController.text;
    SemanticsService.announce(searchText, Directionality.of(context));
    if (searchText.isNotEmpty) {
      Future.wait([
        toDoProvider.searchToDos(searchString: searchText, toDelete: true),
        routineProvider.searchRoutines(
            searchString: searchText, toDelete: true),
        deadlineProvider.searchDeadlines(
            searchString: searchText, toDelete: true),
        reminderProvider.searchReminders(
            searchString: searchText, toDelete: true),
        groupProvider.searchGroups(searchString: searchText, toDelete: true),
      ]).then((model) {
        searchProvider.model = searchProvider.batchWithFade(
            models: model.cast(), searchString: searchText);
      });
    }
    searchProvider.searchString = searchText;
  }

  Future<void> handleRecover({required IModel model}) async {
    switch (model.modelType) {
      case ModelType.task:
        await toDoProvider.restoreToDo(toDo: model as ToDo);
        await eventProvider.insertEventModel(model: model);
        break;
      case ModelType.routine:
        await routineProvider.restoreRoutine(routine: model as Routine);
        break;
      case ModelType.reminder:
        await reminderProvider.restoreReminder(reminder: model as Reminder);
        await eventProvider.insertEventModel(model: model);
        break;
      case ModelType.deadline:
        await deadlineProvider.restoreDeadline(deadline: model as Deadline);
        await eventProvider.insertEventModel(model: model);
        break;
      case ModelType.group:
        await groupProvider.restoreGroup(group: model as Group);
        break;
      default:
        return;
    }
  }

  // Refactor delete dialog.
  Future<void> handleRemove({required IModel model}) async {
    if (userProvider.curUser?.checkDelete ?? true) {
      List<bool>? results = await showDialog(
          useRootNavigator: false,
          context: context,
          builder: (BuildContext context) {
            return CheckDeleteDialog(
              type: toBeginningOfSentenceCase(model.modelType.name)!,
              dontAsk: !(userProvider.curUser?.checkDelete ?? true),
            );
          });

      if (null == results) {
        // Need to repaint bc of fade animation
        if (mounted) {
          setState(() {});
        }
        return;
      }

      bool delete = results[0];
      userProvider.curUser?.checkDelete = results[1];
      if (!delete) {
        // Need to repaint bc of fade animation
        if (mounted) {
          setState(() {});
        }
        return;
      }
    }

    switch (model.modelType) {
      case ModelType.task:
        await toDoProvider.removeToDo(toDo: model as ToDo);
        break;
      case ModelType.routine:
        await routineProvider.removeRoutine(routine: model as Routine);
        break;
      case ModelType.reminder:
        await reminderProvider.removeReminder(reminder: model as Reminder);
        break;
      case ModelType.deadline:
        await deadlineProvider.removeDeadline(deadline: model as Deadline);
        break;
      case ModelType.group:
        await groupProvider.removeGroup(group: model as Group);
        break;
      default:
        return;
    }
  }

  // Refactor delete dialog.
  Future<void> emptyTrash() async {
    if (noDeletes) {
      return;
    }
    List<bool>? results = await showDialog(
      useRootNavigator: false,
      context: context,
      builder: (BuildContext context) {
        return const CheckDeleteDialog(
          headerOverride: "Empty Trash?",
          showCheckbox: false,
        );
      },
    );
    if (null == results) {
      return;
    }

    bool empty = results[0];
    if (!empty) {
      return;
    }
    await Future.wait(
      [
        toDoProvider.emptyTrash(),
        routineProvider.emptyTrash(),
        deadlineProvider.emptyTrash(),
        reminderProvider.emptyTrash(),
        groupProvider.emptyTrash(),
        subtaskProvider.emptyTrash(),
      ],
    ).catchError((e) => Tiles.displayError(context: context, e: e),
        test: (e) => e is FailureToDeleteException);
  }

  void onFetch({List<IModel>? items}) {
    if (null == items) {
      return;
    }
    for (IModel item in items) {
      item.fade = Fade.fadeIn;
    }
  }

  Future<void> onRemove({IModel? item}) async {
    if (null == item) {
      return;
    }

    if (mounted) {
      setState(() => item.fade = Fade.fadeOut);
      await Future.delayed(Duration(
          milliseconds: (userProvider.curUser?.reduceMotion ?? false)
              ? 0
              : Constants.fadeOutTime));
    }
  }

  @override
  Widget build(BuildContext context) {
    MediaQuery.sizeOf(context);
    return Padding(
      padding: const EdgeInsets.all(Constants.padding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ScreenHeader(
            outerPadding: const EdgeInsets.all(Constants.padding),
            leadingIcon: const Icon(Icons.delete_sweep_rounded),
            header: "Trash",
            trailing: FilledButton.icon(
              icon: const Icon(Icons.delete_forever_rounded),
              label: const Text(
                "Empty Trash",
                overflow: TextOverflow.ellipsis,
              ),
              onPressed: emptyTrash,
            ),
          ),
          Padding(
            padding:
                const EdgeInsets.symmetric(vertical: Constants.doublePadding),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Consumer<SearchProvider>(
                    builder: (BuildContext context,
                        SearchProvider<IModel> value, Widget? child) {
                      return AutoSizeTextField(
                        maxLines: 1,
                        minFontSize: Constants.huge,
                        controller: _searchController,
                        decoration: InputDecoration(
                          prefixIcon: const Padding(
                            padding: EdgeInsets.all(Constants.doublePadding),
                            child: Icon(Icons.search_rounded),
                          ),
                          suffixIcon: (searchProvider.searchString.isNotEmpty)
                              ? IconButton(
                                  icon: const Icon(Icons.close_rounded),
                                  onPressed: () {
                                    searchProvider.rebuild = true;
                                    _searchController.clear();
                                  })
                              : null,
                          hintText: "Search Deleted",
                          contentPadding:
                              const EdgeInsets.all(Constants.doublePadding),
                          enabledBorder: OutlineInputBorder(
                              borderRadius: const BorderRadius.all(
                                  Radius.circular(Constants.semiCircular)),
                              borderSide: BorderSide(
                                width: 2,
                                color: Theme.of(context)
                                    .colorScheme
                                    .outlineVariant,
                                strokeAlign: BorderSide.strokeAlignOutside,
                              )),
                          border: const OutlineInputBorder(
                              borderRadius: BorderRadius.all(
                                  Radius.circular(Constants.semiCircular)),
                              borderSide: BorderSide(
                                strokeAlign: BorderSide.strokeAlignOutside,
                              )),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          Flexible(
            child: Scrollbar(
              thumbVisibility: true,
              controller: mainScrollController,
              child: ListView(
                shrinkWrap: true,
                controller: mainScrollController,
                physics: scrollPhysics,
                children: [
                  Consumer<SearchProvider>(
                    builder: (BuildContext context,
                        SearchProvider<IModel> value, Widget? child) {
                      return AnimatedCrossFade(
                        crossFadeState: (searchProvider.searchString.isNotEmpty)
                            ? CrossFadeState.showFirst
                            : CrossFadeState.showSecond,
                        duration: const Duration(
                            milliseconds: Constants.animationDelay),
                        firstChild: ListViews.trashList(
                          models: value.model,
                          showCategory: true,
                          smallScreen: userProvider.smallScreen,
                          onRemove: onRemove,
                        ),
                        secondChild: ListView(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: EdgeInsets.zero,
                          children: [
                            // TODOS
                            ExpandedListTile(
                              leading: const Icon(
                                Icons.task_rounded,
                              ),
                              title: const AutoSizeText(
                                "Tasks",
                                maxLines: 1,
                                overflow: TextOverflow.visible,
                                softWrap: false,
                                minFontSize: Constants.large,
                              ),
                              children: [
                                PaginatingListview<IModel>(
                                  indicatorDisplacement: 0,
                                  query: toDoProvider.getDeleted,
                                  rebuildNotifiers: [
                                    toDoProvider,
                                  ],
                                  rebuildCallback: (
                                      {required List<IModel> items}) {
                                    toDoProvider.toDos = items.cast();
                                    toDoProvider.rebuild = false;
                                  },
                                  items: toDoProvider.toDos,
                                  offset: (toDoProvider.rebuild)
                                      ? 0
                                      : toDoProvider.toDos.length,
                                  onRemove:
                                      (userProvider.curUser?.reduceMotion ??
                                              false)
                                          ? null
                                          : onRemove,
                                  onFetch:
                                      (userProvider.curUser?.reduceMotion ??
                                              false)
                                          ? null
                                          : onFetch,
                                  listviewBuilder: ({
                                    Key? key,
                                    required BuildContext context,
                                    required List<IModel> items,
                                    Future<void> Function({IModel? item})?
                                        onRemove,
                                  }) =>
                                      ListViews.trashList(
                                    models: items,
                                    restoreModel: handleRecover,
                                    deleteModel: handleRemove,
                                    onRemove: onRemove,
                                  ),
                                ),
                              ],
                            ),
                            // DEADLINES
                            ExpandedListTile(
                              leading: const Icon(
                                Icons.announcement_rounded,
                              ),
                              title: const AutoSizeText(
                                "Deadlines",
                                maxLines: 1,
                                overflow: TextOverflow.visible,
                                softWrap: false,
                                minFontSize: Constants.large,
                              ),
                              children: [
                                PaginatingListview<IModel>(
                                  indicatorDisplacement: 0,
                                  query: deadlineProvider.getDeleted,
                                  rebuildNotifiers: [
                                    deadlineProvider,
                                  ],
                                  rebuildCallback: (
                                      {required List<IModel> items}) {
                                    deadlineProvider.deadlines = items.cast();
                                    deadlineProvider.rebuild = false;
                                  },
                                  items: deadlineProvider.deadlines,
                                  offset: (deadlineProvider.rebuild)
                                      ? 0
                                      : deadlineProvider.deadlines.length,
                                  onRemove:
                                      (userProvider.curUser?.reduceMotion ??
                                              false)
                                          ? null
                                          : onRemove,
                                  onFetch:
                                      (userProvider.curUser?.reduceMotion ??
                                              false)
                                          ? null
                                          : onFetch,
                                  listviewBuilder: ({
                                    Key? key,
                                    required BuildContext context,
                                    required List<IModel> items,
                                    Future<void> Function({IModel? item})?
                                        onRemove,
                                  }) =>
                                      ListViews.trashList(
                                    models: items,
                                    restoreModel: handleRecover,
                                    deleteModel: handleRemove,
                                    onRemove: onRemove,
                                  ),
                                ),
                              ],
                            ),
                            // REMINDERS
                            ExpandedListTile(
                              leading: const Icon(
                                Icons.push_pin_rounded,
                              ),
                              title: const AutoSizeText(
                                "Reminders",
                                maxLines: 1,
                                overflow: TextOverflow.visible,
                                softWrap: false,
                                minFontSize: Constants.large,
                              ),
                              children: [
                                PaginatingListview<IModel>(
                                  indicatorDisplacement: 0,
                                  query: reminderProvider.getDeleted,
                                  rebuildNotifiers: [
                                    reminderProvider,
                                  ],
                                  rebuildCallback: (
                                      {required List<IModel> items}) {
                                    reminderProvider.reminders = items.cast();
                                    reminderProvider.rebuild = false;
                                  },
                                  items: reminderProvider.reminders,
                                  offset: (reminderProvider.rebuild)
                                      ? 0
                                      : reminderProvider.reminders.length,
                                  onRemove:
                                      (userProvider.curUser?.reduceMotion ??
                                              false)
                                          ? null
                                          : onRemove,
                                  onFetch:
                                      (userProvider.curUser?.reduceMotion ??
                                              false)
                                          ? null
                                          : onFetch,
                                  listviewBuilder: ({
                                    Key? key,
                                    required BuildContext context,
                                    required List<IModel> items,
                                    Future<void> Function({IModel? item})?
                                        onRemove,
                                  }) =>
                                      ListViews.trashList(
                                    models: items,
                                    restoreModel: handleRecover,
                                    deleteModel: handleRemove,
                                    onRemove: onRemove,
                                  ),
                                ),
                              ],
                            ),
                            // ROUTINES
                            ExpandedListTile(
                              leading: const Icon(Icons.repeat_rounded),
                              title: const AutoSizeText(
                                "Routines",
                                maxLines: 1,
                                overflow: TextOverflow.visible,
                                softWrap: false,
                                minFontSize: Constants.large,
                              ),
                              children: [
                                PaginatingListview<IModel>(
                                  indicatorDisplacement: 0,
                                  query: routineProvider.getDeleted,
                                  rebuildNotifiers: [
                                    routineProvider,
                                  ],
                                  rebuildCallback: (
                                      {required List<IModel> items}) {
                                    routineProvider.routines = items.cast();
                                    routineProvider.rebuild = false;
                                  },
                                  items: routineProvider.routines,
                                  offset: (routineProvider.rebuild)
                                      ? 0
                                      : routineProvider.routines.length,
                                  onRemove:
                                      (userProvider.curUser?.reduceMotion ??
                                              false)
                                          ? null
                                          : onRemove,
                                  onFetch:
                                      (userProvider.curUser?.reduceMotion ??
                                              false)
                                          ? null
                                          : onFetch,
                                  listviewBuilder: ({
                                    Key? key,
                                    required BuildContext context,
                                    required List<IModel> items,
                                    Future<void> Function({IModel? item})?
                                        onRemove,
                                  }) =>
                                      ListViews.trashList(
                                    models: items,
                                    restoreModel: handleRecover,
                                    deleteModel: handleRemove,
                                    onRemove: onRemove,
                                  ),
                                ),
                              ],
                            ),
                            // GROUPS
                            ExpandedListTile(
                              leading: const Icon(Icons.table_view_rounded),
                              title: const AutoSizeText(
                                "Groups",
                                maxLines: 1,
                                overflow: TextOverflow.visible,
                                softWrap: false,
                                minFontSize: Constants.large,
                              ),
                              children: [
                                PaginatingListview<IModel>(
                                  indicatorDisplacement: 0,
                                  query: groupProvider.getDeleted,
                                  rebuildNotifiers: [
                                    groupProvider,
                                  ],
                                  rebuildCallback: (
                                      {required List<IModel> items}) {
                                    groupProvider.groups = items.cast();
                                    groupProvider.rebuild = false;
                                  },
                                  items: groupProvider.groups,
                                  offset: (groupProvider.rebuild)
                                      ? 0
                                      : groupProvider.groups.length,
                                  onRemove:
                                      (userProvider.curUser?.reduceMotion ??
                                              false)
                                          ? null
                                          : onRemove,
                                  onFetch:
                                      (userProvider.curUser?.reduceMotion ??
                                              false)
                                          ? null
                                          : onFetch,
                                  listviewBuilder: ({
                                    Key? key,
                                    required BuildContext context,
                                    required List<IModel> items,
                                    Future<void> Function({IModel? item})?
                                        onRemove,
                                  }) =>
                                      ListViews.trashList(
                                    models: items,
                                    restoreModel: handleRecover,
                                    deleteModel: handleRemove,
                                    onRemove: onRemove,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
