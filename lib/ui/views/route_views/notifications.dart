import 'dart:io';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../model/task/deadline.dart';
import '../../../model/task/reminder.dart';
import '../../../model/task/todo.dart';
import '../../../providers/deadline_provider.dart';
import '../../../providers/reminder_provider.dart';
import '../../../providers/todo_provider.dart';
import '../../../providers/user_provider.dart';
import '../../../util/constants.dart';
import '../../../util/enums.dart';
import '../../../util/interfaces/i_model.dart';
import '../../../util/interfaces/i_repeatable.dart';
import '../../widgets/expanded_listtile.dart';
import '../../widgets/listview_header.dart';
import '../../widgets/listviews.dart';
import '../../widgets/paginating_listview.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreen();
}

class _NotificationsScreen extends State<NotificationsScreen> {
  late final ToDoProvider toDoProvider;
  late final ReminderProvider reminderProvider;
  late final DeadlineProvider deadlineProvider;
  late final UserProvider userProvider;

  late final ScrollController mainScrollController;

  late final ScrollPhysics parentScrollPhysics;

  @override
  void initState() {
    super.initState();
    initializeProviders();
    initializeControllers();
  }

  void initializeProviders() {
    toDoProvider = Provider.of<ToDoProvider>(context, listen: false);

    if (toDoProvider.rebuild) {
      toDoProvider.toDos = [];
      toDoProvider.secondaryToDos = [];
    }

    reminderProvider = Provider.of<ReminderProvider>(context, listen: false);

    if (reminderProvider.rebuild) {
      reminderProvider.reminders = [];
      reminderProvider.secondaryReminders = [];
    }

    deadlineProvider = Provider.of<DeadlineProvider>(context, listen: false);
    if (deadlineProvider.rebuild) {
      deadlineProvider.deadlines = [];
      deadlineProvider.secondaryDeadlines = [];
    }

    userProvider = Provider.of<UserProvider>(context, listen: false);
  }

  void initializeControllers() {
    mainScrollController = ScrollController();
    ScrollPhysics scrollPhysics = (Platform.isIOS || Platform.isMacOS)
        ? const BouncingScrollPhysics()
        : const ClampingScrollPhysics();
    parentScrollPhysics = AlwaysScrollableScrollPhysics(parent: scrollPhysics);
  }

  void onFetch({List<IModel>? items}) {
    if (null == items || items.isEmpty) {
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

    switch (item.modelType) {
      case ModelType.task:
        if (toDoProvider.toDos.length < 2) {
          return;
        }
      case ModelType.deadline:
        if (deadlineProvider.deadlines.length < 2) {
          return;
        }
      case ModelType.reminder:
        if (reminderProvider.reminders.length < 2) {
          return;
        }
      default:
        break;
    }

    if (mounted) {
      setState(() => item.fade = Fade.fadeOut);
      await Future.delayed(const Duration(milliseconds: Constants.fadeOutTime));
    }
  }

  @override
  void dispose() {
    mainScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    MediaQuery.sizeOf(context);
    return Padding(
        padding: const EdgeInsets.all(Constants.innerPadding),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const ListViewHeader<IRepeatable>(
            header: "Notifications",
            leadingIcon: Icon(Icons.notifications_on_rounded),
            sorter: null,
            showSorter: false,
          ),
          Flexible(
            child: Scrollbar(
              thumbVisibility: true,
              controller: mainScrollController,
              child: ListView(
                  shrinkWrap: true,
                  controller: mainScrollController,
                  physics: parentScrollPhysics,
                  children: [
                    ExpandedListTile(
                      initiallyExpanded: true,
                      leading: const Icon(Icons.upcoming_rounded),
                      title: const Padding(
                        padding:
                            EdgeInsets.symmetric(vertical: Constants.padding),
                        child: AutoSizeText(
                          "Upcoming",
                          maxLines: 1,
                          overflow: TextOverflow.visible,
                          softWrap: false,
                          minFontSize: Constants.large,
                        ),
                      ),
                      children: [
                        // Deadlines
                        ExpandedListTile(
                            initiallyExpanded: true,
                            leading: const Icon(Icons.announcement_rounded),
                            title: const AutoSizeText(
                              "Deadlines",
                              maxLines: 1,
                              overflow: TextOverflow.visible,
                              softWrap: false,
                              minFontSize: Constants.large,
                            ),
                            border: BorderSide.none,
                            children: [
                              PaginatingListview<Deadline>(
                                  items: deadlineProvider.deadlines,
                                  limit: 5,
                                  offset: (deadlineProvider.rebuild)
                                      ? 0
                                      : deadlineProvider.deadlines.length,
                                  listviewBuilder: (
                                          {Key? key,
                                          required BuildContext context,
                                          required List<Deadline> items,
                                          Future<void> Function(
                                                  {Deadline? item})?
                                              onRemove}) =>
                                      ListViews.immutableDeadlines(
                                        key: key,
                                        context: context,
                                        deadlines: items,
                                        checkDelete:
                                            userProvider.curUser?.checkDelete ??
                                                true,
                                        smallScreen: userProvider.smallScreen,
                                        onRemove: onRemove,
                                      ),
                                  query: deadlineProvider.getUpcoming,
                                  onFetch:
                                      (userProvider.curUser?.reduceMotion ??
                                              false)
                                          ? null
                                          : onFetch,
                                  onRemove:
                                      (userProvider.curUser?.reduceMotion ??
                                              false)
                                          ? null
                                          : onRemove,
                                  rebuildNotifiers: [deadlineProvider],
                                  rebuildCallback: (
                                      {required List<Deadline> items}) {
                                    deadlineProvider.deadlines = items;
                                    deadlineProvider.rebuild = false;
                                  }),
                            ]),
                        // Reminders
                        ExpandedListTile(
                            initiallyExpanded: true,
                            leading: const Icon(Icons.push_pin_rounded),
                            title: const AutoSizeText(
                              "Reminders",
                              maxLines: 1,
                              overflow: TextOverflow.visible,
                              softWrap: false,
                              minFontSize: Constants.large,
                            ),
                            border: BorderSide.none,
                            children: [
                              PaginatingListview<Reminder>(
                                  items: reminderProvider.reminders,
                                  limit: 5,
                                  offset: (reminderProvider.rebuild)
                                      ? 0
                                      : reminderProvider.reminders.length,
                                  onFetch:
                                      (userProvider.curUser?.reduceMotion ??
                                              false)
                                          ? null
                                          : onFetch,
                                  onRemove:
                                      (userProvider.curUser?.reduceMotion ??
                                              false)
                                          ? null
                                          : onRemove,
                                  listviewBuilder: (
                                          {Key? key,
                                          required BuildContext context,
                                          required List<Reminder> items,
                                          Future<void> Function(
                                                  {Reminder? item})?
                                              onRemove}) =>
                                      ListViews.immutableReminders(
                                        key: key,
                                        context: context,
                                        reminders: items,
                                        checkDelete:
                                            userProvider.curUser?.checkDelete ??
                                                true,
                                        smallScreen: userProvider.smallScreen,
                                        onRemove: onRemove,
                                      ),
                                  query: reminderProvider.getUpcoming,
                                  rebuildNotifiers: [reminderProvider],
                                  rebuildCallback: (
                                      {required List<Reminder> items}) {
                                    reminderProvider.reminders = items;
                                    reminderProvider.rebuild = false;
                                  }),
                            ]),
                        // TODOS
                        ExpandedListTile(
                            initiallyExpanded: true,
                            leading: const Icon(Icons.task_rounded),
                            title: const AutoSizeText(
                              "Tasks",
                              maxLines: 1,
                              overflow: TextOverflow.visible,
                              softWrap: false,
                              minFontSize: Constants.large,
                            ),
                            border: BorderSide.none,
                            children: [
                              PaginatingListview<ToDo>(
                                  items: toDoProvider.toDos,
                                  limit: 5,
                                  offset: (toDoProvider.rebuild)
                                      ? 0
                                      : toDoProvider.toDos.length,
                                  onFetch:
                                      (userProvider.curUser?.reduceMotion ??
                                              false)
                                          ? null
                                          : onFetch,
                                  onRemove:
                                      (userProvider.curUser?.reduceMotion ??
                                              false)
                                          ? null
                                          : onRemove,
                                  listviewBuilder: (
                                          {Key? key,
                                          required BuildContext context,
                                          required List<ToDo> items,
                                          Future<void> Function({ToDo? item})?
                                              onRemove}) =>
                                      ListViews.immutableToDos(
                                        key: key,
                                        context: context,
                                        toDos: items,
                                        checkDelete:
                                            userProvider.curUser?.checkDelete ??
                                                true,
                                        smallScreen: userProvider.smallScreen,
                                        onRemove: onRemove,
                                        checkboxAnimateBeforeUpdate: (
                                            {required int index,
                                            required ToDo toDo}) async {
                                          if (mounted) {
                                            setState(() {
                                              items[index] = toDo;
                                            });
                                          }
                                          await Future.delayed(const Duration(
                                              milliseconds:
                                                  Constants.animationDelay));
                                          if (null != onRemove) {
                                            await onRemove(item: toDo);
                                          }
                                        },
                                      ),
                                  query: toDoProvider.getUpcoming,
                                  rebuildNotifiers: [toDoProvider],
                                  rebuildCallback: (
                                      {required List<ToDo> items}) {
                                    toDoProvider.toDos = items;
                                    toDoProvider.rebuild = false;
                                  }),
                            ]),
                      ],
                    ),
                    ExpandedListTile(
                        initiallyExpanded: true,
                        leading:
                            const Icon(Icons.notification_important_rounded),
                        title: const Padding(
                          padding:
                              EdgeInsets.symmetric(vertical: Constants.padding),
                          child: AutoSizeText(
                            "Overdue",
                            maxLines: 1,
                            overflow: TextOverflow.visible,
                            softWrap: false,
                            minFontSize: Constants.large,
                          ),
                        ),
                        children: [
                          // Deadlines
                          ExpandedListTile(
                              initiallyExpanded: true,
                              leading: const Icon(Icons.announcement_rounded),
                              title: const AutoSizeText(
                                "Deadlines",
                                maxLines: 1,
                                overflow: TextOverflow.visible,
                                softWrap: false,
                                minFontSize: Constants.large,
                              ),
                              border: BorderSide.none,
                              children: [
                                PaginatingListview<Deadline>(
                                    items: deadlineProvider.secondaryDeadlines,
                                    limit: 5,
                                    offset: (deadlineProvider.rebuild)
                                        ? 0
                                        : deadlineProvider
                                            .secondaryDeadlines.length,
                                    onFetch:
                                        (userProvider.curUser?.reduceMotion ??
                                                false)
                                            ? null
                                            : onFetch,
                                    onRemove:
                                        (userProvider.curUser?.reduceMotion ??
                                                false)
                                            ? null
                                            : onRemove,
                                    listviewBuilder: (
                                            {Key? key,
                                            required BuildContext context,
                                            required List<Deadline> items,
                                            Future<void> Function(
                                                    {Deadline? item})?
                                                onRemove}) =>
                                        ListViews.immutableDeadlines(
                                          key: key,
                                          context: context,
                                          deadlines: items,
                                          checkDelete: userProvider
                                                  .curUser?.checkDelete ??
                                              true,
                                          smallScreen: userProvider.smallScreen,
                                          onRemove: onRemove,
                                        ),
                                    query: deadlineProvider.getOverdues,
                                    rebuildNotifiers: [deadlineProvider],
                                    rebuildCallback: (
                                        {required List<Deadline> items}) {
                                      deadlineProvider.secondaryDeadlines =
                                          items;
                                      deadlineProvider.rebuild = false;
                                    }),
                              ]),
                          // Reminders
                          ExpandedListTile(
                              initiallyExpanded: true,
                              leading: const Icon(Icons.push_pin_rounded),
                              title: const AutoSizeText(
                                "Reminders",
                                maxLines: 1,
                                overflow: TextOverflow.visible,
                                softWrap: false,
                                minFontSize: Constants.large,
                              ),
                              border: BorderSide.none,
                              children: [
                                PaginatingListview<Reminder>(
                                    items: reminderProvider.secondaryReminders,
                                    limit: 5,
                                    offset: (reminderProvider.rebuild)
                                        ? 0
                                        : reminderProvider
                                            .secondaryReminders.length,
                                    onFetch:
                                        (userProvider.curUser?.reduceMotion ??
                                                false)
                                            ? null
                                            : onFetch,
                                    onRemove:
                                        (userProvider.curUser?.reduceMotion ??
                                                false)
                                            ? null
                                            : onRemove,
                                    listviewBuilder: (
                                            {Key? key,
                                            required BuildContext context,
                                            required List<Reminder> items,
                                            Future<void> Function(
                                                    {Reminder? item})?
                                                onRemove}) =>
                                        ListViews.immutableReminders(
                                          key: key,
                                          context: context,
                                          reminders: items,
                                          checkDelete: userProvider
                                                  .curUser?.checkDelete ??
                                              true,
                                          smallScreen: userProvider.smallScreen,
                                          onRemove: onRemove,
                                        ),
                                    query: reminderProvider.getOverdues,
                                    rebuildNotifiers: [reminderProvider],
                                    rebuildCallback: (
                                        {required List<Reminder> items}) {
                                      reminderProvider.secondaryReminders =
                                          items;
                                      reminderProvider.rebuild = false;
                                    }),
                              ]),
                          // TODOS
                          ExpandedListTile(
                              initiallyExpanded: true,
                              leading: const Icon(Icons.task_rounded),
                              title: const AutoSizeText(
                                "Tasks",
                                maxLines: 1,
                                overflow: TextOverflow.visible,
                                softWrap: false,
                                minFontSize: Constants.large,
                              ),
                              border: BorderSide.none,
                              children: [
                                PaginatingListview<ToDo>(
                                    items: toDoProvider.secondaryToDos,
                                    limit: 5,
                                    offset: (toDoProvider.rebuild)
                                        ? 0
                                        : toDoProvider.secondaryToDos.length,
                                    onFetch:
                                        (userProvider.curUser?.reduceMotion ??
                                                false)
                                            ? null
                                            : onFetch,
                                    onRemove:
                                        (userProvider.curUser?.reduceMotion ??
                                                false)
                                            ? null
                                            : onRemove,
                                    listviewBuilder: (
                                            {Key? key,
                                            required BuildContext context,
                                            required List<ToDo> items,
                                            Future<void> Function({ToDo? item})?
                                                onRemove}) =>
                                        ListViews.immutableToDos(
                                          key: key,
                                          context: context,
                                          toDos: items,
                                          checkDelete: userProvider
                                                  .curUser?.checkDelete ??
                                              true,
                                          smallScreen: userProvider.smallScreen,
                                          onRemove: onRemove,
                                          checkboxAnimateBeforeUpdate: (
                                              {required int index,
                                              required ToDo toDo}) async {
                                            if (mounted) {
                                              setState(() {
                                                items[index] = toDo;
                                              });
                                            }
                                            await Future.delayed(const Duration(
                                                milliseconds:
                                                    Constants.animationDelay));
                                            if (null != onRemove) {
                                              await onRemove(item: toDo);
                                            }
                                          },
                                        ),
                                    query: toDoProvider.getOverdues,
                                    rebuildNotifiers: [toDoProvider],
                                    rebuildCallback: (
                                        {required List<ToDo> items}) {
                                      toDoProvider.secondaryToDos = items;
                                      toDoProvider.rebuild = false;
                                    }),
                              ]),
                        ]),
                  ]),
            ),
          )
        ]));
  }
}
