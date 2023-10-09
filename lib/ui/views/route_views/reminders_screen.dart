import 'package:another_flushbar/flushbar.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:jiffy/jiffy.dart';
import 'package:provider/provider.dart';

import '../../../model/task/reminder.dart';
import '../../../providers/reminder_provider.dart';
import '../../../util/constants.dart';
import '../../../util/enums.dart';
import '../../../util/exceptions.dart';
import '../../../util/sorting/reminder_sorter.dart';
import '../../widgets/flushbars.dart';
import '../sub_views/create_reminder.dart';
import '../sub_views/update_reminder.dart';

class RemindersListScreen extends StatefulWidget {
  const RemindersListScreen({Key? key}) : super(key: key);

  @override
  State<RemindersListScreen> createState() => _RemindersListScreen();
}

class _RemindersListScreen extends State<RemindersListScreen> {
  late bool checkDelete;
  late bool allData;
  late bool loading;
  late int offset;

  late final ReminderProvider reminderProvider;

  // For linked todos.
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
  }

  void initializeControllers() {
    mainScrollController = ScrollController();

    mainScrollController.addListener(() async {
      // Bottom: Run the query.
      if (mainScrollController.offset >=
              mainScrollController.position.maxScrollExtent &&
          !allData) {
        if (!loading && mounted) {
          await fetchData();
        }
      }
    });

    scrollPhysics =
        const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics());
  }

  Widget getArrowDirection({required SortMethod method}) {
    if (reminderProvider.sortMethod == SortMethod.none) {
      return const SizedBox.shrink();
    }

    if (reminderProvider.sortMethod == method && !reminderProvider.descending) {
      return const Icon(Icons.arrow_downward_rounded);
    }

    return const Icon(Icons.arrow_upward_rounded);
  }

  Future<void> fetchData() async {
    setState(() => loading = true);
    return Future.delayed(
        const Duration(seconds: 1),
        () async => await reminderProvider
                .getRemindersBy(
                    limit: Constants.minLimitPerQuery, offset: offset)
                .then((newReminders) {
              offset += newReminders.length;
              reminderProvider.reminders.addAll(newReminders);
              allData = newReminders.length < Constants.minLimitPerQuery;

              if (mounted) {
                setState(() {
                  loading = false;
                });
              }
            }).catchError(
              (e) {
                Flushbar? error;

                error = Flushbars.createError(
                  message: e.cause ?? "Error with retrieval",
                  context: context,
                  dismissCallback: () => error?.dismiss(),
                );

                error.show(context);
              },
            ));
  }

  Future<void> resetPagination() async {
    setState(() {
      offset = 0;
      reminderProvider.reminders.clear();
    });
    return await fetchData();
  }

  @override
  void dispose() {
    mainScrollController.dispose();
    reminderProvider.removeListener(resetPagination);
    super.dispose();
  }

  Widget getReminderIcon({required Reminder reminder}) {
    Widget icon = (reminder.repeatable)
        ? const Tooltip(
            message: "Repeating", child: Icon(Icons.restart_alt_rounded))
        : const Icon(null);
    return DecoratedBox(
      decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant,
              strokeAlign: BorderSide.strokeAlignOutside)),
      child: Padding(
        padding: const EdgeInsets.all(Constants.padding),
        child: icon,
      ),
    );
  }

  Future<void> handleDelete(
      {required ReminderProvider provider,
      required int index,
      required BuildContext context}) async {
    provider.curReminder = provider.reminders[index];

    await provider.deleteReminder().catchError((e) {
      Flushbar? error;

      error = Flushbars.createError(
        message: e.cause,
        context: context,
        dismissCallback: () => error?.dismiss(),
      );

      error.show(context);
    },
        test: (e) =>
            e is FailureToDeleteException || e is FailureToUploadException);
  }

  @override
  Widget build(BuildContext context) {
    // TODO: Remove this @ first build if still unused.
    bool largeScreen =
        (MediaQuery.of(context).size.width >= Constants.largeScreen);
    bool smallScreen =
        (MediaQuery.of(context).size.width <= Constants.smallScreen);

    return Padding(
      padding: const EdgeInsets.all(Constants.innerPadding),
      child: Column(children: [
        Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Expanded(
                child: AutoSizeText("Reminders",
                    style: Constants.largeHeaderStyle,
                    softWrap: false,
                    maxLines: 1,
                    overflow: TextOverflow.visible,
                    minFontSize: Constants.large),
              ),
              const Icon(Icons.swap_vert_rounded, size: Constants.smIconSize),
              DropdownButtonHideUnderline(
                child: DropdownButton<SortMethod>(
                    padding: const EdgeInsets.symmetric(
                        horizontal: Constants.padding),
                    value: reminderProvider.sortMethod,
                    icon: (reminderProvider.sortMethod != SortMethod.none)
                        ? (reminderProvider.descending)
                            ? const Icon(Icons.arrow_downward_rounded)
                            : const Icon(Icons.arrow_upward_rounded)
                        : null,
                    borderRadius: const BorderRadius.all(
                        Radius.circular(Constants.roundedCorners)),
                    onChanged: (method) {
                      if (null != method) {
                        setState(() {
                          reminderProvider.sortMethod = method;
                        });
                      }
                    },
                    items: ReminderSorter.sortMethods
                        .map<DropdownMenuItem<SortMethod>>(
                            (method) => DropdownMenuItem<SortMethod>(
                                  value: method,
                                  child: Padding(
                                    padding:
                                        const EdgeInsets.all(Constants.padding),
                                    child: Text(
                                      toBeginningOfSentenceCase(
                                          method.name.replaceAll("_", " "))!,
                                    ),
                                  ),
                                ))
                        .toList(growable: false)),
              ),
            ]),
        ListTile(
          contentPadding: const EdgeInsets.symmetric(
              horizontal: Constants.innerPadding, vertical: Constants.padding),
          shape: const RoundedRectangleBorder(
            borderRadius:
                BorderRadius.all(Radius.circular(Constants.roundedCorners)),
          ),
          onTap: () async => await showDialog(
            barrierDismissible: false,
            context: context,
            builder: (BuildContext context) => const CreateReminderScreen(),
          ),
          leading: CircleAvatar(
            child: Icon(Icons.add_rounded,
                color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          title: const AutoSizeText(
            "Create New",
            overflow: TextOverflow.visible,
            softWrap: false,
            maxLines: 1,
            minFontSize: Constants.medium,
          ),
        ),
        Flexible(
          child: (loading)
              ? const CircularProgressIndicator()
              : buildRemindersList(
                  smallScreen: smallScreen,
                  physics: scrollPhysics,
                  largeScreen: largeScreen),
        ),
      ]),
    );
  }

  ListView buildRemindersList(
      {bool smallScreen = false,
      ScrollPhysics physics = const BouncingScrollPhysics(),
      largeScreen = false}) {
    return ListView(
        controller: mainScrollController,
        physics: physics,
        shrinkWrap: true,
        children: [
          Consumer<ReminderProvider>(
            builder:
                (BuildContext context, ReminderProvider value, Widget? child) {
              if (value.sortMethod == SortMethod.none) {
                return buildReorderable(
                    provider: value,
                    context: context,
                    largeScreen: largeScreen);
              }
              return buildImmutable(
                  provider: value, context: context, largeScreen: largeScreen);
            },
          ),
          (loading)
              ? const Padding(
                  padding: EdgeInsets.all(Constants.padding),
                  child: Center(child: CircularProgressIndicator()),
                )
              : const SizedBox.shrink()
        ]);
  }

  ReorderableListView buildReorderable(
      {required ReminderProvider provider,
      required BuildContext context,
      bool largeScreen = false}) {
    return ReorderableListView.builder(
        buildDefaultDragHandles: false,
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: provider.reminders.length,
        onReorder: (int oldIndex, int newIndex) async {
          provider.reminders = await provider
              .reorderReminders(
            oldIndex: oldIndex,
            newIndex: newIndex,
          )
              .catchError((e) {
            Flushbar? error;

            error = Flushbars.createError(
              message: e.cause,
              context: context,
              dismissCallback: () => error?.dismiss(),
            );

            error.show(context);
            return List<Reminder>.empty(growable: true);
          },
                  test: (e) =>
                      e is FailureToCreateException ||
                      e is FailureToUploadException);
          if (provider.reminders.isEmpty) {
            resetPagination();
          }
        },
        itemBuilder: (BuildContext context, int index) {
          // This needs to be a listtile
          return buildReminderListTile(
              index: index,
              context: context,
              provider: provider,
              reorderable: true);
        });
  }

  ListView buildImmutable(
      {required ReminderProvider provider,
      required BuildContext context,
      bool largeScreen = false}) {
    return ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: provider.reminders.length,
        itemBuilder: (BuildContext context, int index) {
          return buildReminderListTile(
              index: index,
              context: context,
              provider: provider,
              reorderable: false);
        });
  }

  ListTile buildReminderListTile(
      {required int index,
      required BuildContext context,
      required ReminderProvider provider,
      bool reorderable = false}) {
    return ListTile(
      key: ValueKey(index),
      // TODO: Come back to this after deciding whether to include
      // repeating reminders
      leading: getReminderIcon(reminder: provider.reminders[index]),
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.all(Radius.circular(Constants.roundedCorners))),
      title: AutoSizeText(provider.reminders[index].name,
          overflow: TextOverflow.visible,
          style: Constants.headerStyle,
          minFontSize: Constants.medium,
          softWrap: true,
          maxLines: 1),
      subtitle: buildSubtitle(reminder: provider.reminders[index]),
      onTap: () async {
        provider.curReminder = provider.reminders[index];
        Reminder? discarded = await showDialog(
            barrierDismissible: false,
            useRootNavigator: false,
            context: context,
            builder: (BuildContext context) => const UpdateReminderScreen());
        if (null != discarded) {
          provider.reminders[index] = discarded;
        }
      },
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: Constants.innerPadding),
            child: IconButton(
                icon: const Icon(Icons.delete_forever_rounded),
                onPressed: () async {
                  if (checkDelete) {
                    return await showDialog<bool?>(
                        barrierDismissible: true,
                        context: context,
                        builder: (BuildContext context) {
                          bool dontAsk = !checkDelete;
                          return StatefulBuilder(
                            builder: (context, setState) => Dialog(
                                insetPadding: const EdgeInsets.all(
                                    Constants.innerDialogPadding),
                                child: Padding(
                                  padding: const EdgeInsets.all(
                                      Constants.innerPadding),
                                  child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            children: [
                                              Expanded(
                                                child: AutoSizeText(
                                                  "Delete Reminder?",
                                                  style: Constants.headerStyle,
                                                  softWrap: true,
                                                  overflow:
                                                      TextOverflow.visible,
                                                  maxLines: 2,
                                                  minFontSize: Constants.medium,
                                                ),
                                              )
                                            ]),
                                        const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Expanded(
                                              child: AutoSizeText(
                                                "This cannot be undone.",
                                                style:
                                                    Constants.largeHeaderStyle,
                                                softWrap: true,
                                                overflow: TextOverflow.visible,
                                                maxLines: 2,
                                                minFontSize: Constants.medium,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: Constants.innerPadding),
                                          child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Expanded(
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            right: Constants
                                                                .padding),
                                                    child:
                                                        FilledButton.tonalIcon(
                                                            icon: const Icon(Icons
                                                                .close_outlined),
                                                            onPressed: () {
                                                              Navigator.pop(
                                                                  context,
                                                                  false);
                                                            },
                                                            label: const AutoSizeText(
                                                                "Cancel",
                                                                softWrap: false,
                                                                overflow:
                                                                    TextOverflow
                                                                        .visible,
                                                                maxLines: 1,
                                                                minFontSize:
                                                                    Constants
                                                                        .small)),
                                                  ),
                                                ),
                                                Expanded(
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            left: Constants
                                                                .padding),
                                                    child: FilledButton.icon(
                                                      icon: const Icon(Icons
                                                          .delete_forever_rounded),
                                                      onPressed: () {
                                                        Navigator.pop(
                                                            context, true);
                                                      },
                                                      label: const AutoSizeText(
                                                          "Delete",
                                                          softWrap: false,
                                                          overflow: TextOverflow
                                                              .visible,
                                                          maxLines: 1,
                                                          minFontSize:
                                                              Constants.small),
                                                    ),
                                                  ),
                                                )
                                              ]),
                                        ),
                                        CheckboxListTile(
                                            value: dontAsk,
                                            shape: const RoundedRectangleBorder(
                                                borderRadius: BorderRadius.all(
                                                    Radius.circular(Constants
                                                        .roundedCorners))),
                                            checkboxShape: const CircleBorder(),
                                            title: const AutoSizeText(
                                              "Don't ask me again",
                                              overflow: TextOverflow.visible,
                                              softWrap: false,
                                              maxLines: 1,
                                              minFontSize: Constants.medium,
                                            ),
                                            onChanged: (value) {
                                              // TODO: Factor this into user class pls.
                                              setState(() {
                                                dontAsk = value!;
                                                checkDelete = !value;
                                              });
                                            })
                                      ]),
                                )),
                          );
                        }).then((delete) async {
                      if (delete ?? false) {
                        await handleDelete(
                            provider: provider, index: index, context: context);
                      }
                    });
                  } else {
                    await handleDelete(
                        provider: provider, index: index, context: context);
                  }
                }),
          ),
          (reorderable)
              ? ReorderableDragStartListener(
                  index: index, child: const Icon(Icons.drag_handle_rounded))
              : const SizedBox.shrink()
        ],
      ),
    );
  }

  Widget buildSubtitle({required Reminder reminder}) {
    return Wrap(
        spacing: Constants.halfPadding,
        runSpacing: Constants.halfPadding,
        children: [
          buildDueDate(dueDate: reminder.dueDate),
          buildDueTime(dueDate: reminder.dueDate)
        ]);
  }

  Widget buildDueDate({required DateTime dueDate}) {
    return Wrap(spacing: Constants.halfPadding, children: [
      const Icon(Icons.event_rounded, size: Constants.minIconSize),
      AutoSizeText(
          Jiffy.parseFromDateTime(dueDate).toLocal().format(pattern: "MMM d"),
          softWrap: false,
          overflow: TextOverflow.visible,
          maxLines: 2,
          maxFontSize: Constants.large,
          minFontSize: Constants.small)
    ]);
  }

  Widget buildDueTime({required DateTime dueDate}) {
    return Wrap(spacing: Constants.halfPadding, children: [
      const Icon(Icons.schedule_rounded, size: Constants.minIconSize),
      AutoSizeText(
          Jiffy.parseFromDateTime(dueDate).toLocal().format(pattern: "hh:mm a"),
          softWrap: false,
          overflow: TextOverflow.visible,
          maxLines: 2,
          maxFontSize: Constants.large,
          minFontSize: Constants.small)
    ]);
  }
}
