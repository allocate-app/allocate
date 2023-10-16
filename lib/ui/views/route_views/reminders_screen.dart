import 'dart:math';

import 'package:another_flushbar/flushbar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../model/task/reminder.dart';
import '../../../providers/reminder_provider.dart';
import '../../../util/constants.dart';
import '../../../util/enums.dart';
import '../../widgets/flushbars.dart';
import '../../widgets/listview_header.dart';
import '../../widgets/listviews.dart';
import '../../widgets/tiles.dart';
import '../sub_views/create_reminder.dart';

class RemindersListScreen extends StatefulWidget {
  const RemindersListScreen({Key? key}) : super(key: key);

  @override
  State<RemindersListScreen> createState() => _RemindersListScreen();
}

class _RemindersListScreen extends State<RemindersListScreen> {
  late bool checkDelete;
  late bool allData;

  late bool loading;
  late int limit;
  late int offset;

  late final ReminderProvider reminderProvider;

  late final ScrollController mainScrollController;
  late final ScrollPhysics scrollPhysics;

  @override
  void initState() {
    super.initState();
    initializeProviders();
    initializeParameters();
    initializeControllers();

    if (reminderProvider.rebuild) {
      resetPagination();
      reminderProvider.rebuild = false;
    }
  }

  void initializeProviders() {
    reminderProvider = Provider.of<ReminderProvider>(context, listen: false);

    reminderProvider.addListener(resetPagination);
  }

  void initializeParameters() {
    loading = reminderProvider.rebuild;
    allData = false;
    checkDelete = true;
    offset = (reminderProvider.rebuild) ? 0 : reminderProvider.reminders.length;
    limit = Constants.minLimitPerQuery;
  }

  void initializeControllers() {
    mainScrollController = ScrollController();

    mainScrollController.addListener(() async {
      // Bottom: Run the query and append data.
      if (mainScrollController.offset >=
              mainScrollController.position.maxScrollExtent -
                  Constants.loadOffset &&
          !allData) {
        if (!loading && mounted) {
          return await appendData();
        }
      }

      // Top: Run the query and overwrite data.
      if (mainScrollController.offset <=
          mainScrollController.position.minScrollExtent) {
        if (!loading && mounted) {
          return await resetPagination();
        }
      }
    });

    scrollPhysics =
        const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics());
  }

  @override
  void dispose() {
    mainScrollController.dispose();
    reminderProvider.removeListener(resetPagination);
    super.dispose();
  }

  Future<void> resetPagination() async {
    offset = 0;
    limit = max(reminders.length, Constants.minLimitPerQuery);
    return await overwriteData();
  }

  Future<void> overwriteData() async {
    List<Reminder> newReminders = await fetchData();
    if (mounted) {
      return setState(() {
        offset += newReminders.length;
        reminders = newReminders;
        loading = false;
        // showTopLoading = false;
        allData = reminders.length < limit;
        limit = Constants.minLimitPerQuery;
      });
    }
  }

  Future<void> appendData() async {
    List<Reminder> newReminders = await fetchData();
    if (mounted) {
      return setState(() {
        offset += newReminders.length;
        reminders.addAll(newReminders);
        loading = false;
        allData = newReminders.length < limit;
      });
    }
  }

  Future<List<Reminder>> fetchData() async {
    if (mounted) {
      setState(() => loading = true);
    }
    return await reminderProvider
        .getRemindersBy(limit: limit, offset: offset)
        .catchError(
      (e) {
        Flushbar? error;

        error = Flushbars.createError(
          message: e.cause ?? "Query Error",
          context: context,
          dismissCallback: () => error?.dismiss(),
        );

        error.show(context);
        return List<Reminder>.empty(growable: true);
      },
    );
  }

  Future<void> checkboxAnimateBeforeUpdate(
      {required Reminder reminder, required int index}) async {
    if (mounted) {
      setState(() {
        reminders[index] = reminder;
      });
    }
    return await Future.delayed(
        const Duration(milliseconds: Constants.checkboxAnimationTime));
  }

  // Convenience accessors.
  List<Reminder> get reminders => reminderProvider.reminders;

  set reminders(List<Reminder> newReminders) =>
      reminderProvider.reminders = newReminders;

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    bool largeScreen = (width >= Constants.largeScreen);
    bool smallScreen = (width <= Constants.smallScreen);

    return Padding(
      padding: const EdgeInsets.all(Constants.innerPadding),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        ListViewHeader<Reminder>(
            header: "Reminders",
            sorter: reminderProvider.sorter,
            onChanged: (SortMethod? method) {
              if (null == method) {
                return;
              }
              if (mounted) {
                setState(() {
                  reminderProvider.sortMethod = method;
                });
              }
            }),
        Tiles.createNew(
          context: context,
          onTap: () async => await showDialog(
            barrierDismissible: false,
            context: context,
            builder: (BuildContext context) => const CreateReminderScreen(),
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
                  (reminderProvider.sortMethod == SortMethod.none)
                      ? ListViews.reorderableReminders(
                          smallScreen: smallScreen,
                          context: context,
                          reminders: reminders,
                          checkDelete: checkDelete)
                      : ListViews.immutableReminders(
                          smallScreen: smallScreen,
                          context: context,
                          reminders: reminders,
                          checkDelete: checkDelete)
                ]),
          ),
        )
      ]),
    );
  }
}
