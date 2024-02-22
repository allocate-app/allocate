import 'package:allocate/ui/blurred_dialog.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../model/task/reminder.dart';
import '../../../providers/application/layout_provider.dart';
import '../../../providers/model/reminder_provider.dart';
import '../../../util/constants.dart';
import '../../../util/enums.dart';
import '../../widgets/listview_header.dart';
import '../../widgets/listviews.dart';
import '../../widgets/paginating_listview.dart';
import '../../widgets/tiles.dart';
import '../sub_views/create_reminder.dart';

class RemindersListScreen extends StatefulWidget {
  const RemindersListScreen({super.key});

  @override
  State<RemindersListScreen> createState() => _RemindersListScreen();
}

class _RemindersListScreen extends State<RemindersListScreen> {
  late final ReminderProvider reminderProvider;
  late final LayoutProvider layoutProvider;

  @override
  void initState() {
    super.initState();
    initializeProviders();
  }

  void initializeProviders() {
    reminderProvider = Provider.of<ReminderProvider>(context, listen: false);
    layoutProvider = Provider.of<LayoutProvider>(context, listen: false);
  }

  @override
  void dispose() {
    super.dispose();
  }

  void onFetch({List<Reminder>? items}) {
    if (null == items) {
      return;
    }

    DateTime threshold = DateTime.now();
    threshold = threshold.copyWith(
        millisecond: threshold.millisecond - Constants.newItemThreshold);
    for (Reminder reminder in items) {
      if (!reminder.lastUpdated.isBefore(threshold)) {
        reminder.fade = Fade.fadeIn;
      }
    }
  }

  void onAppend({List<Reminder>? items}) {
    if (null == items) {
      return;
    }
    for (Reminder reminder in items) {
      reminder.fade = Fade.fadeIn;
    }
  }

  Future<void> onRemove({Reminder? item}) async {
    if (null == item) {
      return;
    }

    if (reminderProvider.reminders.length < 2) {
      return;
    }

    if (mounted) {
      setState(() => item.fade = Fade.fadeOut);
      await Future.delayed(const Duration(milliseconds: Constants.fadeOutTime));
    }
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) => Padding(
            padding: const EdgeInsets.all(Constants.padding),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              ListViewHeader<Reminder>(
                  outerPadding: const EdgeInsets.all(Constants.padding),
                  header: "Reminders",
                  leadingIcon: const Icon(Icons.push_pin_outlined),
                  sorter: reminderProvider.sorter,
                  onChanged: ({SortMethod? sortMethod}) {
                    if (null == sortMethod) {
                      return;
                    }
                    if (mounted) {
                      setState(() {
                        reminderProvider.sortMethod = sortMethod;
                      });
                    }
                  }),
              Tiles.createNew(
                outerPadding:
                    const EdgeInsets.symmetric(vertical: Constants.halfPadding),
                context: context,
                onTap: () async => await blurredNonDismissible(
                    context: context, dialog: const CreateReminderScreen()),
                // await showDialog(
                //   useRootNavigator: false,
                //   barrierDismissible: false,
                //   context: context,
                //   builder: (BuildContext context) =>
                //       const CreateReminderScreen(),
                // ),
              ),
              Flexible(
                child: PaginatingListview<Reminder>(
                    items: reminderProvider.reminders,
                    query: reminderProvider.getRemindersBy,
                    offset: (reminderProvider.rebuild)
                        ? 0
                        : reminderProvider.reminders.length,
                    limit: Constants.minLimitPerQuery,
                    rebuildNotifiers: [reminderProvider],
                    rebuildCallback: ({required List<Reminder> items}) {
                      reminderProvider.reminders = items;
                      reminderProvider.softRebuild = false;
                    },
                    onFetch:
                        (reminderProvider.userViewModel?.reduceMotion ?? false)
                            ? null
                            : onFetch,
                    onRemove:
                        (reminderProvider.userViewModel?.reduceMotion ?? false)
                            ? null
                            : onRemove,
                    onAppend:
                        (reminderProvider.userViewModel?.reduceMotion ?? false)
                            ? null
                            : onAppend,
                    getAnimationKey:
                        (reminderProvider.userViewModel?.reduceMotion ?? false)
                            ? null
                            : () => ValueKey(reminderProvider
                                        .sorter.sortMethod.index *
                                    (reminderProvider.sorter.descending
                                        ? -1
                                        : 1) +
                                (reminderProvider.reminders.isEmpty ? 0 : 1)),
                    listviewBuilder: ({
                      Key? key,
                      required BuildContext context,
                      required List<Reminder> items,
                      Future<void> Function({Reminder? item})? onRemove,
                    }) {
                      if (reminderProvider.sortMethod == SortMethod.none) {
                        return ListViews.reorderableReminders(
                          key: key,
                          listPadding: Constants.fabPadding,
                          context: context,
                          reminders: items,
                          checkDelete:
                              reminderProvider.userViewModel?.checkDelete ??
                                  true,
                          smallScreen: layoutProvider.smallScreen,
                          onRemove: onRemove,
                        );
                      }
                      return ListViews.immutableReminders(
                        key: key,
                        listPadding: Constants.fabPadding,
                        reminders: items,
                        checkDelete:
                            reminderProvider.userViewModel?.checkDelete ?? true,
                        smallScreen: layoutProvider.smallScreen,
                        onRemove: onRemove,
                      );
                    }),
              ),
            ]),
          ));
}
