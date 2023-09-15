import 'package:another_flushbar/flushbar.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../model/task/deadline.dart';
import '../../../model/task/reminder.dart';
import '../../../model/task/todo.dart';
import '../../../providers/deadline_provider.dart';
import '../../../providers/reminder_provider.dart';
import '../../../providers/todo_provider.dart';
import '../../../util/constants.dart';
import '../../../util/enums.dart';
import '../../../util/exceptions.dart';
import '../../../util/numbers.dart';
import '../../widgets/flushbars.dart';
import '../sub_views/update_deadline.dart';
import '../sub_views/update_reminder.dart';
import '../sub_views/update_todo.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreen();
}

class _NotificationsScreen extends State<NotificationsScreen> {
  late bool upcomingToDoLoading;
  late bool upcomingDeadlineLoading;
  late bool upcomingReminderLoading;

  late bool overdueToDoLoading;
  late bool overdueDeadlineLoading;
  late bool overdueReminderLoading;

  late bool allToDos;
  late bool allReminders;
  late bool allDeadlines;

  late int toDoOffset;
  late int deadlineOffset;
  late int reminderOffset;

  late final ToDoProvider toDoProvider;
  late final ReminderProvider reminderProvider;
  late final DeadlineProvider deadlineProvider;

  late final ScrollController mainScrollController;
  late final ScrollController toDoScrollController;
  late final ScrollController reminderScrollController;
  late final ScrollController deadlineScrollController;
  late final ScrollPhysics scrollPhysics;

  @override
  void initState() {
    super.initState();
    initializeProviders();
    initializeParameters();
    initializeControllers();

    if (toDoProvider.rebuild) {
      resetToDoPagination();
      toDoProvider.rebuild = false;
    }
    if (reminderProvider.rebuild) {
      resetReminderPagination();
      reminderProvider.rebuild = false;
    }
    if (deadlineProvider.rebuild) {
      resetDeadlinePagination();
      deadlineProvider.rebuild = false;
    }
  }

  void initializeProviders() {
    toDoProvider = Provider.of<ToDoProvider>(context, listen: false);
    reminderProvider = Provider.of<ReminderProvider>(context, listen: false);
    deadlineProvider = Provider.of<DeadlineProvider>(context, listen: false);

    toDoProvider.addListener(resetToDoPagination);
    reminderProvider.addListener(resetReminderPagination);
    deadlineProvider.addListener(resetDeadlinePagination);
  }

  void initializeParameters() {
    upcomingToDoLoading = toDoProvider.rebuild;
    upcomingDeadlineLoading = deadlineProvider.rebuild;
    upcomingReminderLoading = reminderProvider.rebuild;

    overdueToDoLoading = toDoProvider.rebuild;
    overdueDeadlineLoading = deadlineProvider.rebuild;
    overdueReminderLoading = reminderProvider.rebuild;

    allToDos = false;
    allDeadlines = false;
    allReminders = false;
    toDoOffset = (toDoProvider.rebuild) ? 0 : toDoProvider.toDos.length;
    deadlineOffset =
        (deadlineProvider.rebuild) ? 0 : deadlineProvider.deadlines.length;
    reminderOffset =
        (reminderProvider.rebuild) ? 0 : reminderProvider.reminders.length;
  }

  void initializeControllers() {
    mainScrollController = ScrollController();
    toDoScrollController = ScrollController();
    deadlineScrollController = ScrollController();
    reminderScrollController = ScrollController();

    scrollPhysics =
        const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics());

    toDoScrollController.addListener(() async {
      if (toDoScrollController.offset >=
              toDoScrollController.position.maxScrollExtent &&
          !allToDos) {
        if (!overdueToDoLoading && mounted) {
          fetchOverdueToDos();
        }
      }
    });
    deadlineScrollController.addListener(() async {
      if (deadlineScrollController.offset >=
              deadlineScrollController.position.maxScrollExtent &&
          !allDeadlines) {
        if (!overdueDeadlineLoading && mounted) {
          fetchOverdueDeadlines();
        }
      }
    });

    reminderScrollController.addListener(() async {
      if (reminderScrollController.offset >=
              reminderScrollController.position.maxScrollExtent &&
          !allReminders) {
        if (!overdueReminderLoading && mounted) {
          fetchOverdueReminders();
        }
      }
    });
  }

  Future<void> resetToDoPagination() async {
    setState(() {
      toDoOffset = 0;
      toDoProvider.toDos.clear();
      toDoProvider.recentToDos.clear();
    });
    fetchUpcomingToDos();
    fetchOverdueToDos();
  }

  Future<void> resetReminderPagination() async {
    setState(() {
      reminderOffset = 0;
      reminderProvider.reminders.clear();
    });
    fetchUpcomingReminders();
    fetchOverdueReminders();
  }

  Future<void> resetDeadlinePagination() async {
    setState(() {
      deadlineOffset = 0;
      deadlineProvider.deadlines.clear();
    });
    fetchUpcomingDeadlines();
    fetchOverdueDeadlines();
  }

  Future<void> fetchUpcomingToDos() async {
    setState(() => upcomingToDoLoading = true);
    return Future.delayed(
        const Duration(seconds: 1),
        () async => await toDoProvider.getUpcoming().then((newToDos) {
              toDoProvider.recentToDos = newToDos;
              if (mounted) {
                setState(() => upcomingToDoLoading = false);
              }
            }));
  }

  Future<void> fetchOverdueToDos() async {
    setState(() {
      overdueToDoLoading = true;
    });
    return Future.delayed(
        const Duration(seconds: 1),
        () async => await toDoProvider
                .getOverdues(limit: Constants.limitPerQuery, offset: toDoOffset)
                .then((newToDos) {
              toDoOffset += newToDos.length;
              toDoProvider.toDos.addAll(newToDos);
              allToDos = newToDos.length < Constants.limitPerQuery;

              if (mounted) {
                setState(() => overdueToDoLoading = false);
              }
            }).catchError(
              (e) {
                Flushbar? error;

                error = Flushbars.createError(
                  message: e.cause ?? "Error with Task retrieval",
                  context: context,
                  dismissCallback: () => error?.dismiss(),
                );

                error.show(context);
              },
            ));
  }

  Future<void> fetchUpcomingReminders() async {
    setState(() => upcomingReminderLoading = true);
    return Future.delayed(
        const Duration(seconds: 1),
        () async => await reminderProvider.getUpcoming().then((newReminders) {
              reminderProvider.recentReminders = newReminders;
              if (mounted) {
                setState(() => upcomingReminderLoading = false);
              }
            }));
  }

  Future<void> fetchOverdueReminders() async {
    setState(() => overdueReminderLoading = true);
    return Future.delayed(
        const Duration(seconds: 1),
        () async => await reminderProvider
                .getOverdues(
                    limit: Constants.limitPerQuery, offset: reminderOffset)
                .then((newReminders) {
              reminderOffset += newReminders.length;
              reminderProvider.reminders.addAll(newReminders);
              allReminders = newReminders.length < Constants.limitPerQuery;

              if (mounted) {
                setState(() => overdueReminderLoading = false);
              }
            }).catchError(
              (e) {
                Flushbar? error;

                error = Flushbars.createError(
                  message: e.cause ?? "Error with Reminder retrieval",
                  context: context,
                  dismissCallback: () => error?.dismiss(),
                );

                error.show(context);
              },
            ));
  }

  Future<void> fetchUpcomingDeadlines() async {
    setState(() => upcomingDeadlineLoading = true);
    return Future.delayed(
        const Duration(seconds: 1),
        () async => await deadlineProvider.getUpcoming().then((newDeadlines) {
              deadlineProvider.recentDeadlines = newDeadlines;
              if (mounted) {
                setState(() => upcomingDeadlineLoading = false);
              }
            }));
  }

  Future<void> fetchOverdueDeadlines() async {
    setState(() => overdueDeadlineLoading = true);
    return Future.delayed(
        const Duration(seconds: 1),
        () async => await deadlineProvider
                .getOverdues(
                    limit: Constants.limitPerQuery, offset: deadlineOffset)
                .then((newDeadlines) {
              deadlineOffset += newDeadlines.length;
              deadlineProvider.deadlines.addAll(newDeadlines);
              allDeadlines = newDeadlines.length < Constants.limitPerQuery;

              if (mounted) {
                setState(() => overdueDeadlineLoading = false);
              }
            }).catchError(
              (e) {
                Flushbar? error;

                error = Flushbars.createError(
                  message: e.cause ?? "Error with Deadline retrieval",
                  context: context,
                  dismissCallback: () => error?.dismiss(),
                );

                error.show(context);
              },
            ));
  }

  @override
  void dispose() {
    mainScrollController.dispose();
    toDoScrollController.dispose();
    reminderScrollController.dispose();
    deadlineScrollController.dispose();

    toDoProvider.removeListener(resetToDoPagination);
    reminderProvider.removeListener(resetReminderPagination);
    deadlineProvider.removeListener(resetDeadlinePagination);
    super.dispose();
  }

  Icon getBatteryIcon({required ToDo toDo}) {
    int weight = (toDo.taskType == TaskType.small)
        ? toDo.weight
        : remap(
                x: toDo.weight,
                inMin: 0,
                inMax: Constants.maxWeight,
                outMin: 0,
                outMax: 5)
            .toInt();

    return Constants.batteryIcons[weight]!;
  }

  @override
  Widget build(BuildContext context) {
    bool largeScreen =
        (MediaQuery.of(context).size.width >= Constants.largeScreen);
    bool smallScreen =
        (MediaQuery.of(context).size.width <= Constants.smallScreen);

    return Padding(
        padding: const EdgeInsets.all(Constants.innerPadding),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              mainAxisSize: MainAxisSize.min,
              children: [
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(Constants.padding),
                    child: AutoSizeText("Notifications",
                        style: Constants.largeHeaderStyle,
                        softWrap: false,
                        maxLines: 1,
                        overflow: TextOverflow.visible,
                        minFontSize: Constants.large),
                  ),
                ),
              ]),
          Expanded(
            child: ListView(
                padding: const EdgeInsets.symmetric(
                    horizontal: Constants.innerPadding),
                shrinkWrap: true,
                controller: mainScrollController,
                physics: scrollPhysics,
                children: [
                  buildExpansionTile(
                      horizontalPadding: Constants.innerPadding,
                      verticalPadding: Constants.innerPadding,
                      title: "Upcoming",
                      children: buildUpcoming(),
                      leading: const Icon(Icons.upcoming_rounded)),
                  buildExpansionTile(
                      horizontalPadding: Constants.innerPadding,
                      verticalPadding: Constants.innerPadding,
                      title: "Overdue",
                      children: buildOverdue(),
                      leading: const Icon(Icons.notification_important_rounded))
                ]),
          )
        ]));
  }

  Widget buildExpansionTile(
      {required String title,
      required List<Widget> children,
      Widget? leading,
      double verticalPadding = 0,
      double horizontalPadding = 0}) {
    return Card(
        clipBehavior: Clip.antiAlias,
        elevation: 0,
        color: Colors.transparent,
        shape: RoundedRectangleBorder(
            side: BorderSide(
                color: Theme.of(context).colorScheme.outlineVariant,
                width: 1.5,
                strokeAlign: BorderSide.strokeAlignInside),
            borderRadius: const BorderRadius.all(
                Radius.circular(Constants.roundedCorners))),
        child: ExpansionTile(
          collapsedShape: const RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.all(Radius.circular(Constants.roundedCorners))),
          shape: const RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.all(Radius.circular(Constants.roundedCorners))),
          initiallyExpanded: true,
          tilePadding: EdgeInsets.symmetric(
              vertical: verticalPadding, horizontal: horizontalPadding),
          leading: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: Constants.innerPadding),
            child: leading,
          ),
          title: AutoSizeText(title,
              overflow: TextOverflow.visible,
              style: Constants.headerStyle,
              minFontSize: Constants.medium,
              softWrap: true,
              maxLines: 1),
          children: children,
        ));
  }

  List<Widget> buildUpcoming() {
    return [
      buildExpansionTile(
          horizontalPadding: Constants.innerPadding,
          title: "Tasks",
          leading: const Icon(Icons.task_rounded),
          children: [buildUpcomingToDos()]),
      buildExpansionTile(
          horizontalPadding: Constants.innerPadding,
          title: "Reminders",
          leading: const Icon(Icons.push_pin_rounded),
          children: [buildUpcomingReminders()]),
      buildExpansionTile(
          horizontalPadding: Constants.innerPadding,
          title: "Deadlines",
          leading: const Icon(Icons.announcement_rounded),
          children: [buildUpcomingDeadlines()])
    ];
  }

  List<Widget> buildOverdue() {
    return [
      buildExpansionTile(
          horizontalPadding: Constants.innerPadding,
          title: "Tasks",
          leading: const Icon(Icons.task_rounded),
          children: [buildOverdueToDos()]),
      buildExpansionTile(
          horizontalPadding: Constants.innerPadding,
          title: "Reminders",
          leading: const Icon(Icons.push_pin_rounded),
          children: [buildOverdueReminders()]),
      buildExpansionTile(
          horizontalPadding: Constants.innerPadding,
          title: "Deadlines",
          leading: const Icon(Icons.announcement_rounded),
          children: [buildOverdueDeadlines()])
    ];
  }

  ListView buildUpcomingToDos() {
    return ListView(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        children: [
          Consumer<ToDoProvider>(builder:
              (BuildContext context, ToDoProvider value, Widget? child) {
            return ListView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: value.recentToDos.length,
              itemBuilder: (BuildContext context, int index) {
                return buildToDoListTile(toDo: value.recentToDos[index]);
              },
            );
          }),
          (upcomingToDoLoading)
              ? const Padding(
                  padding: EdgeInsets.all(Constants.padding),
                  child: Center(child: CircularProgressIndicator()),
                )
              : const SizedBox.shrink(),
        ]);
  }

  Widget buildOverdueToDos() {
    return ConstrainedBox(
      constraints:
          const BoxConstraints(maxHeight: Constants.maxListHeightBeforeScroll),
      child: ListView(
          controller: toDoScrollController,
          physics: scrollPhysics,
          shrinkWrap: true,
          children: [
            Consumer<ToDoProvider>(builder:
                (BuildContext context, ToDoProvider value, Widget? child) {
              return ListView.builder(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: value.toDos.length,
                itemBuilder: (BuildContext context, int index) {
                  return buildToDoListTile(toDo: value.toDos[index]);
                },
              );
            }),
            (overdueToDoLoading)
                ? const Padding(
                    padding: EdgeInsets.all(Constants.padding),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : const SizedBox.shrink(),
          ]),
    );
  }

  ListTile buildToDoListTile({required ToDo toDo}) {
    return ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: Constants.innerPadding),
        shape: const RoundedRectangleBorder(
            borderRadius:
                BorderRadius.all(Radius.circular(Constants.roundedCorners))),
        leading: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: Constants.innerPadding),
          child: Checkbox(
              shape: const CircleBorder(),
              splashRadius: 15,
              value: toDo.completed,
              onChanged: (bool? completed) async {
                toDo.completed = completed!;
                toDoProvider.curToDo = toDo;
                await toDoProvider.updateToDo().catchError((e) {
                  Flushbar? error;

                  error = Flushbars.createError(
                    message: e.cause,
                    context: context,
                    dismissCallback: () => error?.dismiss(),
                  );

                  error.show(context);
                },
                    test: (e) =>
                        e is FailureToCreateException ||
                        e is FailureToUploadException);
              }),
        ),
        title: AutoSizeText(toDo.name,
            overflow: TextOverflow.visible,
            style: Constants.headerStyle,
            minFontSize: Constants.medium,
            softWrap: true,
            maxLines: 1),
        onTap: () async {
          toDoProvider.curToDo = toDo;
          await showDialog(
              barrierDismissible: false,
              useRootNavigator: false,
              context: context,
              builder: (BuildContext context) => const UpdateToDoScreen());
        },
        trailing: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: Constants.innerPadding),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              getBatteryIcon(toDo: toDo),
              AutoSizeText(
                "${toDo.weight}",
                overflow: TextOverflow.visible,
                minFontSize: Constants.large,
                softWrap: false,
                maxLines: 1,
              ),
            ],
          ),
        ));
  }

  ListView buildUpcomingReminders() {
    return ListView(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        children: [
          Consumer<ReminderProvider>(builder:
              (BuildContext context, ReminderProvider value, Widget? child) {
            return ListView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: value.recentReminders.length,
              itemBuilder: (BuildContext context, int index) {
                return buildReminderListTile(
                    reminder: value.recentReminders[index]);
              },
            );
          }),
          (upcomingReminderLoading)
              ? const Padding(
                  padding: EdgeInsets.all(Constants.padding),
                  child: Center(child: CircularProgressIndicator()),
                )
              : const SizedBox.shrink(),
        ]);
  }

  Widget buildOverdueReminders() {
    return ConstrainedBox(
      constraints:
          const BoxConstraints(maxHeight: Constants.maxListHeightBeforeScroll),
      child: ListView(
          controller: reminderScrollController,
          physics: scrollPhysics,
          shrinkWrap: true,
          children: [
            Consumer<ReminderProvider>(builder:
                (BuildContext context, ReminderProvider value, Widget? child) {
              return ListView.builder(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: value.reminders.length,
                itemBuilder: (BuildContext context, int index) {
                  return buildReminderListTile(
                      reminder: value.reminders[index]);
                },
              );
            }),
            (overdueReminderLoading)
                ? const Padding(
                    padding: EdgeInsets.all(Constants.padding),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : const SizedBox.shrink(),
          ]),
    );
  }

  buildReminderListTile({required Reminder reminder}) {
    return ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: Constants.innerPadding),
        shape: const RoundedRectangleBorder(
            borderRadius:
                BorderRadius.all(Radius.circular(Constants.roundedCorners))),
        title: AutoSizeText(reminder.name,
            overflow: TextOverflow.visible,
            style: Constants.headerStyle,
            minFontSize: Constants.medium,
            softWrap: true,
            maxLines: 1),
        onTap: () async {
          reminderProvider.curReminder = reminder;
          await showDialog(
              barrierDismissible: false,
              useRootNavigator: false,
              context: context,
              builder: (BuildContext context) => const UpdateReminderScreen());
        });
  }

  ListView buildUpcomingDeadlines() {
    return ListView(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        children: [
          Consumer<DeadlineProvider>(builder:
              (BuildContext context, DeadlineProvider value, Widget? child) {
            return ListView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: value.recentDeadlines.length,
              itemBuilder: (BuildContext context, int index) {
                return buildDeadlineListTile(
                    deadline: value.recentDeadlines[index]);
              },
            );
          }),
          (upcomingDeadlineLoading)
              ? const Padding(
                  padding: EdgeInsets.all(Constants.padding),
                  child: Center(child: CircularProgressIndicator()),
                )
              : const SizedBox.shrink(),
        ]);
  }

  Widget buildOverdueDeadlines() {
    return ConstrainedBox(
      constraints:
          const BoxConstraints(maxHeight: Constants.maxListHeightBeforeScroll),
      child: ListView(
          controller: deadlineScrollController,
          physics: scrollPhysics,
          shrinkWrap: true,
          children: [
            Consumer<DeadlineProvider>(builder:
                (BuildContext context, DeadlineProvider value, Widget? child) {
              return ListView.builder(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: value.deadlines.length,
                itemBuilder: (BuildContext context, int index) {
                  return buildDeadlineListTile(
                      deadline: value.deadlines[index]);
                },
              );
            }),
            (overdueDeadlineLoading)
                ? const Padding(
                    padding: EdgeInsets.all(Constants.padding),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : const SizedBox.shrink(),
          ]),
    );
  }

  buildDeadlineListTile({required Deadline deadline}) {
    return ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: Constants.innerPadding),
        shape: const RoundedRectangleBorder(
            borderRadius:
                BorderRadius.all(Radius.circular(Constants.roundedCorners))),
        leading: (deadline.warnMe)
            ? const Icon(Icons.notifications_rounded)
            : const Icon(null),
        title: AutoSizeText(
          deadline.name,
          overflow: TextOverflow.visible,
          style: Constants.headerStyle,
          minFontSize: Constants.medium,
          softWrap: true,
          maxLines: 1,
        ),
        onTap: () async {
          deadlineProvider.curDeadline = deadline;
          await showDialog(
              barrierDismissible: false,
              useRootNavigator: false,
              context: context,
              builder: (BuildContext context) => const UpdateDeadlineScreen());
        });
  }
}
