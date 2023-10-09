import 'package:another_flushbar/flushbar.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:jiffy/jiffy.dart';
import 'package:provider/provider.dart';

import '../../../model/task/deadline.dart';
import '../../../providers/deadline_provider.dart';
import '../../../util/constants.dart';
import '../../../util/enums.dart';
import '../../../util/exceptions.dart';
import '../../../util/sorting/deadline_sorter.dart';
import '../../widgets/flushbars.dart';
import '../sub_views/create_deadline.dart';
import '../sub_views/update_deadline.dart';

class DeadlinesListScreen extends StatefulWidget {
  const DeadlinesListScreen({Key? key}) : super(key: key);

  @override
  State<DeadlinesListScreen> createState() => _DeadlinesListScreen();
}

class _DeadlinesListScreen extends State<DeadlinesListScreen> {
  late bool checkDelete;
  late bool allData;
  late bool loading;
  late int offset;

  late final DeadlineProvider deadlineProvider;

  // For linked todos.
  late final ScrollController mainScrollController;
  late final ScrollPhysics scrollPhysics;

  @override
  void initState() {
    super.initState();
    initializeProviders();
    initializeParameters();
    initializeControllers();

    if (deadlineProvider.rebuild) {
      resetPagination();
      deadlineProvider.rebuild = false;
    }
  }

  void initializeProviders() {
    deadlineProvider = Provider.of<DeadlineProvider>(context, listen: false);

    deadlineProvider.addListener(resetPagination);
  }

  void initializeParameters() {
    loading = deadlineProvider.rebuild;
    allData = false;
    checkDelete = true;
    offset = (deadlineProvider.rebuild) ? 0 : deadlineProvider.deadlines.length;
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
    if (deadlineProvider.sortMethod == SortMethod.none) {
      return const SizedBox.shrink();
    }

    if (deadlineProvider.sortMethod == method && !deadlineProvider.descending) {
      return const Icon(Icons.arrow_downward_rounded);
    }

    return const Icon(Icons.arrow_upward_rounded);
  }

  Future<void> fetchData() async {
    setState(() => loading = true);
    return Future.delayed(
        const Duration(seconds: 1),
        () async => await deadlineProvider
                .getDeadlinesBy(
                    limit: Constants.minLimitPerQuery, offset: offset)
                .then((newDeadlines) {
              offset += newDeadlines.length;
              deadlineProvider.deadlines.addAll(newDeadlines);
              allData = newDeadlines.length < Constants.minLimitPerQuery;

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
      deadlineProvider.deadlines.clear();
    });
    return await fetchData();
  }

  @override
  void dispose() {
    mainScrollController.dispose();
    deadlineProvider.removeListener(resetPagination);
    super.dispose();
  }

  Widget getDeadlineIcon({required Deadline deadline}) {
    Widget icon = (deadline.warnMe)
        ? const Icon(Icons.notifications_rounded)
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
                child: AutoSizeText("Deadlines",
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
                    value: deadlineProvider.sortMethod,
                    icon: (deadlineProvider.sortMethod != SortMethod.none)
                        ? (deadlineProvider.descending)
                            ? const Icon(Icons.arrow_downward_rounded)
                            : const Icon(Icons.arrow_upward_rounded)
                        : null,
                    borderRadius: const BorderRadius.all(
                        Radius.circular(Constants.roundedCorners)),
                    onChanged: (method) {
                      if (null != method) {
                        setState(() {
                          deadlineProvider.sortMethod = method;
                        });
                      }
                    },
                    items: DeadlineSorter.sortMethods
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
            builder: (BuildContext context) => const CreateDeadlineScreen(),
          ),
          leading: CircleAvatar(
            child: Icon(Icons.add_outlined,
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
              : buildDeadlinesList(
                  smallScreen: smallScreen,
                  physics: scrollPhysics,
                  largeScreen: largeScreen),
        ),
      ]),
    );
  }

  ListView buildDeadlinesList(
      {bool smallScreen = false,
      ScrollPhysics physics = const BouncingScrollPhysics(),
      largeScreen = false}) {
    return ListView(
        controller: mainScrollController,
        physics: physics,
        shrinkWrap: true,
        children: [
          Consumer<DeadlineProvider>(
            builder:
                (BuildContext context, DeadlineProvider value, Widget? child) {
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
      {required DeadlineProvider provider,
      required BuildContext context,
      bool largeScreen = false}) {
    return ReorderableListView.builder(
        buildDefaultDragHandles: false,
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: provider.deadlines.length,
        onReorder: (int oldIndex, int newIndex) async {
          provider.deadlines = await provider
              .reorderDeadlines(
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
            return List<Deadline>.empty(growable: true);
          },
                  test: (e) =>
                      e is FailureToCreateException ||
                      e is FailureToUploadException);
          if (provider.deadlines.isEmpty) {
            resetPagination();
          }
        },
        itemBuilder: (BuildContext context, int index) {
          // This needs to be a listtile
          return buildDeadlineListTile(
              index: index,
              context: context,
              provider: provider,
              reorderable: true);
        });
  }

  ListView buildImmutable(
      {required DeadlineProvider provider,
      required BuildContext context,
      bool largeScreen = false}) {
    return ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: provider.deadlines.length,
        itemBuilder: (BuildContext context, int index) {
          return buildDeadlineListTile(
              index: index,
              context: context,
              provider: provider,
              reorderable: false);
        });
  }

  ListTile buildDeadlineListTile(
      {required int index,
      required BuildContext context,
      required DeadlineProvider provider,
      bool reorderable = false}) {
    return ListTile(
      key: ValueKey(index),
      leading: getDeadlineIcon(deadline: provider.deadlines[index]),
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.all(Radius.circular(Constants.roundedCorners))),
      title: AutoSizeText(provider.deadlines[index].name,
          overflow: TextOverflow.visible,
          style: Constants.headerStyle,
          minFontSize: Constants.medium,
          softWrap: true,
          maxLines: 1),
      subtitle: buildSubtitle(deadline: provider.deadlines[index]),
      onTap: () async {
        provider.curDeadline = provider.deadlines[index];
        Deadline? discarded = await showDialog<Deadline>(
            barrierDismissible: false,
            useRootNavigator: false,
            context: context,
            builder: (BuildContext context) => const UpdateDeadlineScreen());
        if (null != discarded) {
          provider.deadlines[index] = discarded;
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
                                                  "Delete Deadline?",
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

  Future<void> handleDelete(
      {required DeadlineProvider provider,
      required int index,
      required BuildContext context}) async {
    provider.curDeadline = provider.deadlines[index];

    await provider.deleteDeadline().catchError((e) {
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

  Widget buildSubtitle({required Deadline deadline}) {
    return Wrap(
        spacing: Constants.halfPadding,
        runSpacing: Constants.halfPadding,
        children: [
          buildDueDate(dueDate: deadline.dueDate),
          (deadline.warnMe)
              ? buildWarnDate(warnDate: deadline.warnDate)
              : const SizedBox.shrink(),
          buildPriorityIcon(priority: deadline.priority)
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

  Widget buildWarnDate({required DateTime warnDate}) {
    return Wrap(spacing: Constants.halfPadding, children: [
      const Icon(Icons.notifications_on_rounded, size: Constants.minIconSize),
      AutoSizeText(
          Jiffy.parseFromDateTime(warnDate).toLocal().format(pattern: "MMM d"),
          softWrap: false,
          overflow: TextOverflow.visible,
          maxLines: 2,
          maxFontSize: Constants.large,
          minFontSize: Constants.small)
    ]);
  }

  Widget buildPriorityIcon({required Priority priority}) {
    return switch (priority) {
      Priority.low =>
        const Tooltip(message: "Low", child: Icon(Icons.low_priority_rounded)),
      Priority.medium => const Tooltip(
          message: "Medium", child: Icon(Icons.outlined_flag_rounded)),
      Priority.high => const Tooltip(
          message: "High", child: Icon(Icons.priority_high_rounded)),
    };
  }
}
