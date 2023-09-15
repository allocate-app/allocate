import 'package:another_flushbar/flushbar.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../model/task/routine.dart';
import '../../../providers/routine_provider.dart';
import '../../../util/constants.dart';
import '../../../util/enums.dart';
import '../../../util/exceptions.dart';
import '../../../util/sorting/routine_sorter.dart';
import '../../widgets/flushbars.dart';
import '../sub_views/create_routine.dart';
import '../sub_views/update_routine.dart';

class RoutinesListScreen extends StatefulWidget {
  const RoutinesListScreen({Key? key}) : super(key: key);

  @override
  State<RoutinesListScreen> createState() => _RoutinesListScreen();
}

class _RoutinesListScreen extends State<RoutinesListScreen> {
  late bool checkDelete;
  late bool allData;
  late bool loading;
  late int offset;

  late final RoutineProvider routineProvider;

  // For linked todos.
  late final ScrollController mainScrollController;
  late final ScrollPhysics scrollPhysics;

  @override
  void initState() {
    super.initState();
    initializeProviders();
    initializeParameters();
    initializeControllers();

    if (routineProvider.rebuild) {
      resetPagination();
      routineProvider.rebuild = false;
    }
  }

  void initializeProviders() {
    routineProvider = Provider.of<RoutineProvider>(context, listen: false);

    routineProvider.addListener(resetPagination);
  }

  void initializeParameters() {
    loading = routineProvider.rebuild;
    allData = false;
    checkDelete = true;
    offset = (routineProvider.rebuild) ? 0 : routineProvider.routines.length;
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
    if (routineProvider.sortMethod == SortMethod.none) {
      return const SizedBox.shrink();
    }

    if (routineProvider.sortMethod == method && !routineProvider.descending) {
      return const Icon(Icons.arrow_downward_rounded);
    }

    return const Icon(Icons.arrow_upward_rounded);
  }

  Widget getTimeOfDayIcon(
      {required Routine routine,
      required BuildContext context,
      required RoutineProvider provider}) {
    RoutineTime routineTime = provider.getRoutineTime(routine: routine);

    Icon? icon = switch (routineTime) {
      RoutineTime.morning => const Icon(Icons.wb_twilight_rounded),
      RoutineTime.afternoon => const Icon(Icons.lunch_dining_rounded),
      RoutineTime.evening => const Icon(Icons.bed_rounded),
      _ => const Icon(null),
    };

    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.all(Constants.padding),
        shape: const CircleBorder(),
      ),
      onPressed: () async {
        await showDialog<RoutineTime>(
          context: context,
          builder: (BuildContext context) {
            return Dialog(
                child: ConstrainedBox(
              constraints: const BoxConstraints(
                  maxWidth: Constants.smallLandscapeDialogWidth),
              child: Padding(
                padding: const EdgeInsets.all(Constants.innerPadding),
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Expanded(
                              child: AutoSizeText(
                                "Set Routine Time",
                                style: Constants.headerStyle,
                                softWrap: true,
                                overflow: TextOverflow.visible,
                                maxLines: 2,
                                minFontSize: Constants.medium,
                              ),
                            )
                          ]),
                      const Flexible(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            Flexible(
                                child: AutoSizeText(
                              "Morning | Afternoon | Evening ",
                              style: Constants.largeHeaderStyle,
                              softWrap: true,
                              overflow: TextOverflow.visible,
                              maxLines: 1,
                              minFontSize: Constants.large,
                            )),
                            Flexible(
                              child: FittedBox(
                                  fit: BoxFit.fill,
                                  child: Icon(Icons.schedule_outlined,
                                      size: Constants.medIconSize)),
                            ),
                          ],
                        ),
                      ),
                      Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            Flexible(
                                child: Padding(
                              padding: const EdgeInsets.all(Constants.padding),
                              child: FittedBox(
                                fit: BoxFit.fill,
                                child: (routine == provider.curMorning)
                                    ? IconButton.filledTonal(
                                        iconSize: Constants.lgIconSize,
                                        icon: const Icon(
                                            Icons.wb_twilight_rounded),
                                        onPressed: () => Navigator.pop(
                                            context, RoutineTime.none))
                                    : IconButton.outlined(
                                        iconSize: Constants.lgIconSize,
                                        icon: const Icon(
                                            Icons.wb_twilight_rounded),
                                        onPressed: () => Navigator.pop(
                                            context, RoutineTime.morning)),
                              ),
                            )),
                            Flexible(
                              child: Padding(
                                padding:
                                    const EdgeInsets.all(Constants.padding),
                                child: FittedBox(
                                  fit: BoxFit.fill,
                                  child: (routine == provider.curAfternoon)
                                      ? IconButton.filledTonal(
                                          iconSize: Constants.lgIconSize,
                                          icon: const Icon(
                                              Icons.lunch_dining_rounded),
                                          onPressed: () => Navigator.pop(
                                              context, RoutineTime.none))
                                      : IconButton.outlined(
                                          iconSize: Constants.lgIconSize,
                                          icon: const Icon(
                                              Icons.lunch_dining_rounded),
                                          onPressed: () => Navigator.pop(
                                              context, RoutineTime.afternoon)),
                                ),
                              ),
                            ),
                            Flexible(
                              child: Padding(
                                padding:
                                    const EdgeInsets.all(Constants.padding),
                                child: FittedBox(
                                  fit: BoxFit.fill,
                                  child: (routine == provider.curEvening)
                                      ? IconButton.filledTonal(
                                          iconSize: Constants.lgIconSize,
                                          icon: const Icon(Icons.bed_rounded),
                                          onPressed: () => Navigator.pop(
                                              context, RoutineTime.none))
                                      : IconButton.outlined(
                                          iconSize: Constants.lgIconSize,
                                          icon: const Icon(Icons.bed_rounded),
                                          onPressed: () => Navigator.pop(
                                              context, RoutineTime.evening)),
                                ),
                              ),
                            )
                          ]),
                      Flexible(
                        child: Padding(
                            padding: const EdgeInsets.all(Constants.padding),
                            child: Tooltip(
                              message: "Remove.",
                              child: FittedBox(
                                fit: BoxFit.fill,
                                child: IconButton.outlined(
                                  iconSize: Constants.medIconSize,
                                  icon:
                                      const Icon(Icons.remove_circle_outlined),
                                  onPressed: () =>
                                      Navigator.pop(context, RoutineTime.none),
                                ),
                              ),
                            )),
                      )
                    ]),
              ),
            ));
          },
        ).then((RoutineTime? time) {
          if (time == null) {
            return;
          }
          provider.handleRoutineTime(time: time, routine: routine);
          if (mounted) {
            setState(() {});
          }
        });
      },
      child: icon,
    );
  }

  Future<void> fetchData() async {
    setState(() => loading = true);
    return Future.delayed(
        const Duration(seconds: 1),
        () async => await routineProvider
                .getRoutinesBy(limit: Constants.limitPerQuery, offset: offset)
                .then((newRoutines) {
              offset += newRoutines.length;
              routineProvider.routines.addAll(newRoutines);
              allData = newRoutines.length < Constants.limitPerQuery;

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
      routineProvider.routines.clear();
    });
    return await fetchData();
  }

  @override
  void dispose() {
    mainScrollController.dispose();
    routineProvider.removeListener(resetPagination);
    super.dispose();
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
                child: AutoSizeText("Routines",
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
                    value: routineProvider.sortMethod,
                    icon: (routineProvider.sortMethod != SortMethod.none)
                        ? (routineProvider.descending)
                            ? const Icon(Icons.arrow_downward_rounded)
                            : const Icon(Icons.arrow_upward_rounded)
                        : null,
                    borderRadius: const BorderRadius.all(
                        Radius.circular(Constants.roundedCorners)),
                    onChanged: (method) {
                      if (null != method) {
                        setState(() {
                          routineProvider.sortMethod = method;
                        });
                      }
                    },
                    items: RoutineSorter.sortMethods
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
            builder: (BuildContext context) => const CreateRoutineScreen(),
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
              : buildRoutinesList(
                  smallScreen: smallScreen,
                  physics: scrollPhysics,
                  largeScreen: largeScreen),
        ),
      ]),
    );
  }

  ListView buildRoutinesList(
      {bool smallScreen = false,
      ScrollPhysics physics = const BouncingScrollPhysics(),
      largeScreen = false}) {
    return ListView(
        controller: mainScrollController,
        physics: physics,
        shrinkWrap: true,
        children: [
          Consumer<RoutineProvider>(
            builder:
                (BuildContext context, RoutineProvider value, Widget? child) {
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
      {required RoutineProvider provider,
      required BuildContext context,
      bool largeScreen = false}) {
    return ReorderableListView.builder(
        buildDefaultDragHandles: false,
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: provider.routines.length,
        onReorder: (int oldIndex, int newIndex) async {
          provider.routines = await provider
              .reorderRoutines(
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
            return List<Routine>.empty(growable: true);
          },
                  test: (e) =>
                      e is FailureToCreateException ||
                      e is FailureToUploadException);
          if (provider.routines.isEmpty) {
            resetPagination();
          }
        },
        itemBuilder: (BuildContext context, int index) {
          // This needs to be a listtile
          return buildRoutineListTile(
              index: index,
              context: context,
              provider: provider,
              reorderable: true);
        });
  }

  ListView buildImmutable(
      {required RoutineProvider provider,
      required BuildContext context,
      bool largeScreen = false}) {
    return ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: provider.routines.length,
        itemBuilder: (BuildContext context, int index) {
          return buildRoutineListTile(
              index: index,
              context: context,
              provider: provider,
              reorderable: false);
        });
  }

  ListTile buildRoutineListTile(
      {required int index,
      required BuildContext context,
      required RoutineProvider provider,
      bool reorderable = false}) {
    return ListTile(
      key: ValueKey(index),
      leading: getTimeOfDayIcon(
        context: context,
        provider: provider,
        routine: provider.routines[index],
      ),
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.all(Radius.circular(Constants.roundedCorners))),
      title: AutoSizeText(provider.routines[index].name,
          overflow: TextOverflow.visible,
          style: Constants.headerStyle,
          minFontSize: Constants.medium,
          softWrap: true,
          maxLines: 1),
      onTap: () async {
        provider.curRoutine = provider.routines[index];
        await showDialog(
            barrierDismissible: false,
            useRootNavigator: false,
            context: context,
            builder: (BuildContext context) => const UpdateRoutineScreen());
      },
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: Constants.innerPadding),
            child: IconButton(
                icon: const Icon(Icons.delete_forever),
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
                                                  "Delete Routine?",
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
      {required RoutineProvider provider,
      required int index,
      required BuildContext context}) async {
    provider.curRoutine = provider.routines[index];

    await provider.deleteRoutine().catchError((e) {
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
}
