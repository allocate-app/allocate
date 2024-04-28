import 'dart:io';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../model/task/deadline.dart';
import '../../../model/task/reminder.dart';
import '../../../model/task/todo.dart';
import '../../../providers/application/layout_provider.dart';
import '../../../providers/model/deadline_provider.dart';
import '../../../providers/model/reminder_provider.dart';
import '../../../providers/model/todo_provider.dart';
import '../../../util/constants.dart';
import '../../../util/enums.dart';
import '../../../util/interfaces/i_model.dart';
import '../../widgets/expanded_listtile.dart';
import '../../widgets/listviews.dart';
import '../../widgets/paginating_listview.dart';
import '../../widgets/screen_header.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreen();
}

class _NotificationsScreen extends State<NotificationsScreen> {
  late final ToDoProvider toDoProvider;
  late final ReminderProvider reminderProvider;
  late final DeadlineProvider deadlineProvider;
  late final LayoutProvider layoutProvider;

  late final ScrollController mainScrollController;

  late final ScrollPhysics scrollPhysics;

  @override
  void initState() {
    super.initState();
    initializeProviders();
    initializeControllers();
  }

  void initializeProviders() {
    toDoProvider = Provider.of<ToDoProvider>(context, listen: false);
    reminderProvider = Provider.of<ReminderProvider>(context, listen: false);
    deadlineProvider = Provider.of<DeadlineProvider>(context, listen: false);

    layoutProvider = Provider.of<LayoutProvider>(context, listen: false);
  }

  void initializeControllers() {
    mainScrollController = ScrollController();
    ScrollPhysics parentScrollPhysics = (Platform.isIOS || Platform.isMacOS)
        ? const BouncingScrollPhysics()
        : const ClampingScrollPhysics();
    scrollPhysics = AlwaysScrollableScrollPhysics(parent: parentScrollPhysics);
  }

  void onFetch({List<IModel>? items}) {
    if (null == items || items.isEmpty) {
      return;
    }

    DateTime threshold = DateTime.now();
    threshold = threshold.copyWith(
        millisecond: threshold.millisecond - Constants.newItemThreshold);
    for (IModel item in items) {
      if (!item.lastUpdated.isBefore(threshold)) {
        item.fade = Fade.fadeIn;
      }
    }
  }

  void onAppend({List<IModel>? items}) {
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
      await Future.delayed(const Duration(milliseconds: Constants.fadeOutTime));
    }
  }

  @override
  void dispose() {
    mainScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          return Padding(
              padding: const EdgeInsets.all(Constants.padding),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const ScreenHeader(
                    outerPadding: EdgeInsets.all(Constants.padding),
                    header: "Notifications",
                    leadingIcon: Icon(Icons.notifications_on_rounded)),
                Flexible(
                  child: ListView(
                      shrinkWrap: true,
                      controller: mainScrollController,
                      physics: scrollPhysics,
                      children: [
                        ExpandedListTile(
                          outerPadding:
                              const EdgeInsets.only(bottom: Constants.padding),
                          initiallyExpanded: layoutProvider.upcomingExpanded,
                          onExpansionChanged: ({bool expanded = false}) {
                            layoutProvider.upcomingExpanded = expanded;
                          },
                          leading: const Icon(Icons.upcoming_rounded),
                          title: const Padding(
                            padding: EdgeInsets.symmetric(
                                vertical: Constants.padding),
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
                                initiallyExpanded:
                                    layoutProvider.deadlineExpanded[0],
                                onExpansionChanged: ({bool expanded = false}) {
                                  layoutProvider.deadlineExpanded[0] = expanded;
                                },
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
                                      indicatorDisplacement: 0,
                                      items: deadlineProvider.deadlines,
                                      limit: 5,
                                      pullToRefresh: false,
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
                                            deadlines: items,
                                            checkDelete: deadlineProvider
                                                    .userViewModel
                                                    ?.checkDelete ??
                                                true,
                                            smallScreen:
                                                layoutProvider.smallScreen,
                                            onRemove: onRemove,
                                          ),
                                      query: deadlineProvider.getUpcoming,
                                      onFetch: (deadlineProvider.userViewModel?.reduceMotion ?? false)
                                          ? null
                                          : onFetch,
                                      onRemove: (deadlineProvider.userViewModel
                                                  ?.reduceMotion ??
                                              false)
                                          ? null
                                          : onRemove,
                                      onAppend: (deadlineProvider.userViewModel
                                                  ?.reduceMotion ??
                                              false)
                                          ? null
                                          : onAppend,
                                      rebuildNotifiers: [deadlineProvider],
                                      rebuildCallback: (
                                          {required List<Deadline> items}) {
                                        deadlineProvider.deadlines = items;
                                        deadlineProvider.softRebuild = false;
                                      }),
                                ]),
                            // Reminders
                            ExpandedListTile(
                                initiallyExpanded:
                                    layoutProvider.reminderExpanded[0],
                                onExpansionChanged: ({bool expanded = false}) {
                                  layoutProvider.reminderExpanded[0] = expanded;
                                },
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
                                      indicatorDisplacement: 0,
                                      items: reminderProvider.reminders,
                                      limit: 5,
                                      pullToRefresh: false,
                                      offset: (reminderProvider.rebuild)
                                          ? 0
                                          : reminderProvider.reminders.length,
                                      onFetch: (reminderProvider.userViewModel?.reduceMotion ?? false)
                                          ? null
                                          : onFetch,
                                      onRemove: (reminderProvider.userViewModel
                                                  ?.reduceMotion ??
                                              false)
                                          ? null
                                          : onRemove,
                                      onAppend: (reminderProvider.userViewModel
                                                  ?.reduceMotion ??
                                              false)
                                          ? null
                                          : onAppend,
                                      listviewBuilder: (
                                              {Key? key,
                                              required BuildContext context,
                                              required List<Reminder> items,
                                              Future<void> Function(
                                                      {Reminder? item})?
                                                  onRemove}) =>
                                          ListViews.immutableReminders(
                                            key: key,
                                            reminders: items,
                                            checkDelete: reminderProvider
                                                    .userViewModel
                                                    ?.checkDelete ??
                                                true,
                                            smallScreen:
                                                layoutProvider.smallScreen,
                                            onRemove: onRemove,
                                          ),
                                      query: reminderProvider.getUpcoming,
                                      rebuildNotifiers: [reminderProvider],
                                      rebuildCallback: (
                                          {required List<Reminder> items}) {
                                        reminderProvider.reminders = items;
                                        reminderProvider.softRebuild = false;
                                      }),
                                ]),
                            // TODOS
                            ExpandedListTile(
                                initiallyExpanded:
                                    layoutProvider.toDoExpanded[0],
                                onExpansionChanged: ({bool expanded = false}) {
                                  layoutProvider.toDoExpanded[0] = expanded;
                                },
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
                                      indicatorDisplacement: 0,
                                      items: toDoProvider.toDos,
                                      limit: 5,
                                      pullToRefresh: false,
                                      offset: (toDoProvider.rebuild)
                                          ? 0
                                          : toDoProvider.toDos.length,
                                      onFetch: (toDoProvider.userViewModel
                                                  ?.reduceMotion ??
                                              false)
                                          ? null
                                          : onFetch,
                                      onRemove: (toDoProvider.userViewModel
                                                  ?.reduceMotion ??
                                              false)
                                          ? null
                                          : onRemove,
                                      onAppend: (toDoProvider.userViewModel
                                                  ?.reduceMotion ??
                                              false)
                                          ? null
                                          : onAppend,
                                      listviewBuilder: (
                                              {Key? key,
                                              required BuildContext context,
                                              required List<ToDo> items,
                                              Future<void> Function({ToDo? item})?
                                                  onRemove}) =>
                                          ListViews.immutableToDos(
                                            key: key,
                                            toDos: items,
                                            checkDelete: toDoProvider
                                                    .userViewModel
                                                    ?.checkDelete ??
                                                true,
                                            smallScreen:
                                                layoutProvider.smallScreen,
                                            onRemove: onRemove,
                                            checkboxAnimateBeforeUpdate: (
                                                {required int index,
                                                required ToDo toDo}) async {
                                              if (mounted) {
                                                setState(() {
                                                  items[index] = toDo;
                                                });
                                              }
                                              await Future.delayed(
                                                  const Duration(
                                                      milliseconds: Constants
                                                          .animationDelay));
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
                                        toDoProvider.softRebuild = false;
                                      }),
                                ]),
                          ],
                        ),
                        ExpandedListTile(
                            initiallyExpanded: layoutProvider.overdueExpanded,
                            onExpansionChanged: ({bool expanded = false}) {
                              layoutProvider.overdueExpanded = expanded;
                            },
                            leading: const Icon(
                                Icons.notification_important_rounded),
                            title: const Padding(
                              padding: EdgeInsets.symmetric(
                                  vertical: Constants.padding),
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
                                  initiallyExpanded:
                                      layoutProvider.deadlineExpanded[1],
                                  onExpansionChanged: (
                                      {bool expanded = false}) {
                                    layoutProvider.deadlineExpanded[1] =
                                        expanded;
                                  },
                                  leading:
                                      const Icon(Icons.announcement_rounded),
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
                                        indicatorDisplacement: 0,
                                        items:
                                            deadlineProvider.secondaryDeadlines,
                                        limit: 5,
                                        pullToRefresh: false,
                                        offset: (deadlineProvider.rebuild)
                                            ? 0
                                            : deadlineProvider
                                                .secondaryDeadlines.length,
                                        onFetch: (deadlineProvider.userViewModel
                                                    ?.reduceMotion ??
                                                false)
                                            ? null
                                            : onFetch,
                                        onRemove:
                                            (deadlineProvider.userViewModel?.reduceMotion ?? false)
                                                ? null
                                                : onRemove,
                                        onAppend: (deadlineProvider
                                                    .userViewModel
                                                    ?.reduceMotion ??
                                                false)
                                            ? null
                                            : onAppend,
                                        listviewBuilder: (
                                                {Key? key,
                                                required BuildContext context,
                                                required List<Deadline> items,
                                                Future<void> Function(
                                                        {Deadline? item})?
                                                    onRemove}) =>
                                            ListViews.immutableDeadlines(
                                              key: key,
                                              deadlines: items,
                                              checkDelete: deadlineProvider
                                                      .userViewModel
                                                      ?.checkDelete ??
                                                  true,
                                              smallScreen:
                                                  layoutProvider.smallScreen,
                                              onRemove: onRemove,
                                            ),
                                        query: deadlineProvider.getOverdues,
                                        rebuildNotifiers: [deadlineProvider],
                                        rebuildCallback: ({required List<Deadline> items}) {
                                          deadlineProvider.secondaryDeadlines =
                                              items;
                                          deadlineProvider.softRebuild = false;
                                        }),
                                  ]),
                              // Reminders
                              ExpandedListTile(
                                  initiallyExpanded:
                                      layoutProvider.reminderExpanded[1],
                                  onExpansionChanged: (
                                      {bool expanded = false}) {
                                    layoutProvider.reminderExpanded[1] =
                                        expanded;
                                  },
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
                                        indicatorDisplacement: 0,
                                        items:
                                            reminderProvider.secondaryReminders,
                                        limit: 5,
                                        pullToRefresh: false,
                                        offset: (reminderProvider.rebuild)
                                            ? 0
                                            : reminderProvider
                                                .secondaryReminders.length,
                                        onFetch: (reminderProvider.userViewModel
                                                    ?.reduceMotion ??
                                                false)
                                            ? null
                                            : onFetch,
                                        onRemove:
                                            (reminderProvider.userViewModel?.reduceMotion ?? false)
                                                ? null
                                                : onRemove,
                                        onAppend: (reminderProvider
                                                    .userViewModel
                                                    ?.reduceMotion ??
                                                false)
                                            ? null
                                            : onAppend,
                                        listviewBuilder: (
                                                {Key? key,
                                                required BuildContext context,
                                                required List<Reminder> items,
                                                Future<void> Function(
                                                        {Reminder? item})?
                                                    onRemove}) =>
                                            ListViews.immutableReminders(
                                              key: key,
                                              reminders: items,
                                              checkDelete: reminderProvider
                                                      .userViewModel
                                                      ?.checkDelete ??
                                                  true,
                                              smallScreen:
                                                  layoutProvider.smallScreen,
                                              onRemove: onRemove,
                                            ),
                                        query: reminderProvider.getOverdues,
                                        rebuildNotifiers: [reminderProvider],
                                        rebuildCallback: ({required List<Reminder> items}) {
                                          reminderProvider.secondaryReminders =
                                              items;
                                          reminderProvider.softRebuild = false;
                                        }),
                                  ]),
                              // TODOS
                              ExpandedListTile(
                                  initiallyExpanded:
                                      layoutProvider.toDoExpanded[1],
                                  onExpansionChanged: (
                                      {bool expanded = false}) {
                                    layoutProvider.toDoExpanded[1] = expanded;
                                  },
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
                                        indicatorDisplacement: 0,
                                        items: toDoProvider.secondaryToDos,
                                        limit: 5,
                                        pullToRefresh: false,
                                        offset: (toDoProvider.rebuild)
                                            ? 0
                                            : toDoProvider
                                                .secondaryToDos.length,
                                        onFetch: (toDoProvider.userViewModel
                                                    ?.reduceMotion ??
                                                false)
                                            ? null
                                            : onFetch,
                                        onRemove: (toDoProvider.userViewModel
                                                    ?.reduceMotion ??
                                                false)
                                            ? null
                                            : onRemove,
                                        onAppend: (toDoProvider.userViewModel
                                                    ?.reduceMotion ??
                                                false)
                                            ? null
                                            : onAppend,
                                        listviewBuilder: (
                                                {Key? key,
                                                required BuildContext context,
                                                required List<ToDo> items,
                                                Future<void> Function(
                                                        {ToDo? item})?
                                                    onRemove}) =>
                                            ListViews.immutableToDos(
                                              key: key,
                                              toDos: items,
                                              checkDelete: toDoProvider
                                                      .userViewModel
                                                      ?.checkDelete ??
                                                  true,
                                              smallScreen:
                                                  layoutProvider.smallScreen,
                                              onRemove: onRemove,
                                              checkboxAnimateBeforeUpdate: (
                                                  {required int index,
                                                  required ToDo toDo}) async {
                                                if (mounted) {
                                                  setState(() {
                                                    items[index] = toDo;
                                                  });
                                                }
                                                await Future.delayed(
                                                    const Duration(
                                                        milliseconds: Constants
                                                            .animationDelay));
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
                                          toDoProvider.softRebuild = false;
                                        }),
                                  ]),
                            ]),
                      ]),
                )
              ]));
        },
      );
}
