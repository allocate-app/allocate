import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../model/task/reminder.dart';
import '../../../providers/reminder_provider.dart';
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
  late bool checkDelete;

  late final ReminderProvider reminderProvider;

  @override
  void initState() {
    super.initState();
    initializeProviders();
    initializeParameters();
  }

  void initializeProviders() {
    reminderProvider = Provider.of<ReminderProvider>(context, listen: false);
    if (reminderProvider.rebuild) {
      reminderProvider.reminders = [];
    }
  }

  void initializeParameters() {
    checkDelete = true;
  }

  @override
  void dispose() {
    super.dispose();
  }

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
          context: context,
          onTap: () async => await showDialog(
            barrierDismissible: false,
            context: context,
            builder: (BuildContext context) => const CreateReminderScreen(),
          ),
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
                reminderProvider.rebuild = false;
              },
              paginateButton: false,
              onFetch: ({List<Reminder>? items}) {
                if (null == items) {
                  return;
                }

                for (Reminder reminder in items) {
                  reminder.fade = Fade.fadeIn;
                }
              },
              onRemove: ({Reminder? item}) async {
                if (null == item) {
                  return;
                }

                if (reminderProvider.reminders.length < 2) {
                  return;
                }

                if (mounted) {
                  setState(() => item.fade = Fade.fadeOut);
                  await Future.delayed(
                      const Duration(milliseconds: Constants.fadeOutTime));
                }
              },
              getAnimationKey: () => ValueKey(
                  reminderProvider.sorter.sortMethod.index *
                          (reminderProvider.sorter.descending ? -1 : 1) +
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
                    context: context,
                    reminders: items,
                    checkDelete: checkDelete,
                    smallScreen: smallScreen,
                    onRemove: onRemove,
                  );
                }
                return ListViews.immutableReminders(
                  key: key,
                  context: context,
                  reminders: items,
                  checkDelete: checkDelete,
                  smallScreen: smallScreen,
                  onRemove: onRemove,
                );
              }),
        ),
      ]),
    );
  }
}
