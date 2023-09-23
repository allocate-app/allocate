//TODO: Finish -> Needs Three ExpansionTiles & possibly a numerical weight.
import 'package:another_flushbar/flushbar.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../model/task/routine.dart';
import '../../../model/task/subtask.dart';
import '../../../providers/routine_provider.dart';
import '../../../providers/user_provider.dart';
import '../../../util/constants.dart';
import '../../../util/enums.dart';
import '../../../util/exceptions.dart';
import '../../widgets/flushbars.dart';
import '../../widgets/padded_divider.dart';
import 'create_routine.dart';
import 'update_routine.dart';

class MyDayRoutines extends StatefulWidget {
  const MyDayRoutines({Key? key}) : super(key: key);

  @override
  State<MyDayRoutines> createState() => _MyDayRoutines();
}

class _MyDayRoutines extends State<MyDayRoutines> {
  late RoutineProvider routineProvider;
  late UserProvider userProvider;

  late ScrollController mainScrollController;
  late ScrollPhysics scrollPhysics;

  late final SearchController searchController;
  late List<MapEntry<String, int>> searchHistory;

  @override
  void initState() {
    initializeProviders();
    initializeParameters();
    initializeControllers();
    super.initState();
  }

  void initializeProviders() {
    userProvider = Provider.of<UserProvider>(context, listen: false);
    routineProvider = Provider.of<RoutineProvider>(context, listen: false);
  }

  void initializeParameters() {
    searchHistory = List.empty(growable: true);
  }

  void initializeControllers() {
    mainScrollController = ScrollController();
    searchController = SearchController();
    scrollPhysics = const ScrollPhysics();
  }

  @override
  void dispose() {
    mainScrollController.dispose();
    searchController.dispose();
    super.dispose();
  }

  // I don't love this idea.
  RoutineTime? getRoutineTime() {
    TimeOfDay now = TimeOfDay.now();
    // Add to user class.
    if ((now.hour < (userProvider.curUser?.aftHour ?? 24) &&
            now.hour >= (userProvider.curUser?.mornHour ?? 24)) &&
        null != userProvider.curUser?.curMornID) {
      return RoutineTime.morning;
    }
    if ((now.hour < (userProvider.curUser?.eveHour ?? 24) &&
            now.hour >= (userProvider.curUser?.aftHour ?? 24)) &&
        null != userProvider.curUser?.curAftID) {
      return RoutineTime.afternoon;
    }
    if (null != userProvider.curUser?.curEveID) {
      return RoutineTime.evening;
    }

    return null;
  }

  Future<void> handleHistorySelection(
      {required MapEntry<String, int> routineData,
      required SearchController controller,
      required BuildContext context,
      required RoutineTime timeOfDay}) async {
    controller.closeView("");
    await routineProvider
        .getRoutineByID(id: routineData.value)
        .then((routine) async {
      await setRoutine(routine: routine, timeOfDay: timeOfDay).whenComplete(() {
        setState(() {});
      });
    }).catchError((_) {
      Flushbar? error;
      error = Flushbars.createError(
        message: "Error with Routine Retrieval",
        context: context,
        dismissCallback: () => error?.dismiss(),
      );
      error.show(context);
    });
  }

  Future<void> handleRoutineSelection(
      {required Routine routine,
      required SearchController controller,
      required BuildContext context,
      required RoutineTime timeOfDay}) async {
    controller.closeView("");
    setState(() {
      if (searchHistory.length >= Constants.historyLength) {
        searchHistory.removeLast();
      }
    });
    await setRoutine(routine: routine, timeOfDay: timeOfDay).whenComplete(() {
      setState(() {
        searchHistory.insert(0, MapEntry(routine.name, routine.localID!));
      });
    });
  }

  Future<void> setRoutine(
      {Routine? routine, required RoutineTime timeOfDay}) async {
    if (null == routine) {
      return;
    }
    routineProvider.curRoutine = routine;
    await routineProvider.resetRoutine().whenComplete(() async {
      await routineProvider.handleRoutineTime(time: timeOfDay);
    }).catchError((e) {
      Flushbar? error;

      error = Flushbars.createError(
        message: e.cause,
        context: context,
        dismissCallback: () => error?.dismiss(),
      );
    },
        test: (e) =>
            e is FailureToCreateException || e is FailureToUpdateException);
  }

  Widget getTimeOfDayIcon({required RoutineTime timeOfDay}) {
    Icon? icon = switch (timeOfDay) {
      RoutineTime.morning => const Icon(Icons.wb_twilight_rounded),
      RoutineTime.afternoon => const Icon(Icons.lunch_dining_rounded),
      RoutineTime.evening => const Icon(Icons.bed_rounded),
      _ => const Icon(null),
    };
    return DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant,
              strokeAlign: BorderSide.strokeAlignOutside),
        ),
        child: Padding(
          padding: const EdgeInsets.all(Constants.padding),
          child: icon,
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.all(Constants.halfPadding),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(mainAxisSize: MainAxisSize.min, children: [
            Expanded(
                child: AutoSizeText(
                    "Focus Routine: ${toBeginningOfSentenceCase(getRoutineTime()?.name ?? "none")}",
                    style: Constants.headerStyle,
                    softWrap: false,
                    maxLines: 1,
                    overflow: TextOverflow.visible,
                    minFontSize: Constants.large)),
          ]),
          buildRoutineCards(),
        ]));
  }

  Widget buildRoutineCards() {
    return Consumer<RoutineProvider>(
        builder: (BuildContext context, RoutineProvider value, Widget? child) {
      return Expanded(
        child: ListView(
            controller: mainScrollController,
            physics: scrollPhysics,
            shrinkWrap: true,
            children: [
              (null != value.curMorning)
                  ? buildRoutineCard(
                      routine: value.curMorning!,
                      timeOfDay: RoutineTime.morning)
                  : buildEmptyCard(timeOfDay: RoutineTime.morning),
              (null != value.curAfternoon)
                  ? buildRoutineCard(
                      routine: value.curAfternoon!,
                      timeOfDay: RoutineTime.afternoon)
                  : buildEmptyCard(timeOfDay: RoutineTime.afternoon),
              (null != value.curEvening)
                  ? buildRoutineCard(
                      routine: value.curEvening!,
                      timeOfDay: RoutineTime.evening)
                  : buildEmptyCard(timeOfDay: RoutineTime.evening),
            ]),
      );
    });
  }

  Widget buildRoutineCard(
      {required Routine routine, required RoutineTime timeOfDay}) {
    int itemCount = routine.routineTasks.indexOf(SubTask());
    if (itemCount < 0) {
      itemCount = routine.routineTasks.length;
    }
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      color: Colors.transparent,
      shape: RoundedRectangleBorder(
          side: BorderSide(
              width: 2,
              color: Theme.of(context).colorScheme.outlineVariant,
              strokeAlign: BorderSide.strokeAlignInside),
          borderRadius: const BorderRadius.all(
              Radius.circular(Constants.roundedCorners))),
      child: ExpansionTile(
          initiallyExpanded: true,
          tilePadding: const EdgeInsets.all(Constants.innerPadding),
          leading: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: Constants.innerPadding),
            child: IconButton.filledTonal(
                icon: const Icon(Icons.edit_rounded),
                onPressed: () async {
                  routineProvider.curRoutine = routine;
                  await showDialog(
                      barrierDismissible: false,
                      useRootNavigator: false,
                      context: context,
                      builder: (BuildContext context) =>
                          const UpdateRoutineScreen());
                }),
          ),
          title: AutoSizeText(
            routine.name,
            maxLines: 1,
            overflow: TextOverflow.visible,
            softWrap: false,
            minFontSize: Constants.small,
          ),
          collapsedShape: const RoundedRectangleBorder(
              side: BorderSide(strokeAlign: BorderSide.strokeAlignOutside),
              borderRadius:
                  BorderRadius.all(Radius.circular(Constants.roundedCorners))),
          shape: const RoundedRectangleBorder(
              side: BorderSide(strokeAlign: BorderSide.strokeAlignOutside),
              borderRadius:
                  BorderRadius.all(Radius.circular(Constants.roundedCorners))),
          trailing: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: Constants.padding),
              child: IconButton(
                  icon: const Icon(Icons.remove_circle_outline_rounded),
                  onPressed: () async {
                    await routineProvider
                        .handleRoutineTime(routine: routine)
                        .whenComplete(() => setState(() {}));
                  })),
          children: [
            ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: itemCount,
                itemBuilder: (BuildContext context, int index) {
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: Constants.innerPadding),
                    shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(
                            Radius.circular(Constants.roundedCorners))),
                    leading: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: Constants.innerPadding),
                      child: Checkbox(
                          shape: const CircleBorder(),
                          splashRadius: 15,
                          value: routine.routineTasks[index].completed,
                          onChanged: (value) async {
                            setState(() {
                              routine.routineTasks[index].completed = value!;
                            });
                            routineProvider.curRoutine = routine;
                            await routineProvider
                                .updateRoutine()
                                .whenComplete(() {
                              setState(() {});
                            }).catchError((e) {
                              Flushbar? error;

                              error = Flushbars.createError(
                                message: e.cause,
                                context: context,
                                dismissCallback: () => error?.dismiss(),
                              );
                            },
                                    test: (e) =>
                                        e is FailureToCreateException ||
                                        e is FailureToUpdateException);
                          }),
                    ),
                    title: AutoSizeText(
                      routine.routineTasks[index].name,
                      overflow: TextOverflow.visible,
                      minFontSize: Constants.medium,
                      softWrap: false,
                      maxLines: 1,
                    ),
                  );
                }),
          ]),
    );
  }

  Widget buildEmptyCard({required RoutineTime timeOfDay}) {
    // Should have + add and Search.
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      color: Colors.transparent,
      shape: RoundedRectangleBorder(
          side: BorderSide(
              width: 2,
              color: Theme.of(context).colorScheme.outlineVariant,
              strokeAlign: BorderSide.strokeAlignInside),
          borderRadius: const BorderRadius.all(
              Radius.circular(Constants.roundedCorners))),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.all(Constants.innerPadding),
        initiallyExpanded: false,
        leading: getTimeOfDayIcon(timeOfDay: timeOfDay),
        title: AutoSizeText(
            "${toBeginningOfSentenceCase(timeOfDay.name)!} Routine",
            maxLines: 1,
            overflow: TextOverflow.visible,
            softWrap: false,
            minFontSize: Constants.small),
        collapsedShape: const RoundedRectangleBorder(
            side: BorderSide(strokeAlign: BorderSide.strokeAlignOutside),
            borderRadius:
                BorderRadius.all(Radius.circular(Constants.roundedCorners))),
        shape: const RoundedRectangleBorder(
            side: BorderSide(strokeAlign: BorderSide.strokeAlignOutside),
            borderRadius:
                BorderRadius.all(Radius.circular(Constants.roundedCorners))),
        children: [
          const PaddedDivider(padding: Constants.padding),
          buildRoutineSearchBar(timeOfDay: timeOfDay),
          const PaddedDivider(padding: Constants.innerPadding),
          buildCreateRoutineBar(context: context, timeOfDay: timeOfDay)
        ],
      ),
    );
  }

  SearchAnchor buildRoutineSearchBar({required RoutineTime timeOfDay}) {
    return SearchAnchor(
      viewHintText: "Search Routines",
      searchController: searchController,
      builder: (BuildContext context, SearchController controller) {
        return const ListTile(
            leading: Icon(Icons.search_rounded),
            title: AutoSizeText(
              "Search Routines",
              maxLines: 1,
              overflow: TextOverflow.visible,
              softWrap: false,
            ));
      },
      suggestionsBuilder: (BuildContext context, SearchController controller) {
        if (controller.text.isEmpty) {
          if (searchHistory.isNotEmpty) {
            return searchHistory
                .map((MapEntry<String, int> routineData) => ListTile(
                      leading: const Icon(Icons.history_rounded),
                      title: AutoSizeText(
                        routineData.key,
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.visible,
                      ),
                      onTap: () => handleHistorySelection(
                          context: context,
                          routineData: routineData,
                          controller: controller,
                          timeOfDay: timeOfDay),
                    ))
                .toList();
          }
          final searchFuture = routineProvider.mostRecent(limit: 5);
          return [
            buildRoutineSelectionList(
                searchFuture: searchFuture,
                controller: controller,
                timeOfDay: timeOfDay)
          ];
        }
        // Search query iterable.
        final searchFuture =
            routineProvider.searchRoutines(searchString: controller.text);
        return [
          buildRoutineSelectionList(
              searchFuture: searchFuture,
              controller: controller,
              timeOfDay: timeOfDay)
        ];
      },
    );
  }

  Widget buildCreateRoutineBar(
      {required BuildContext context, required RoutineTime timeOfDay}) {
    return ListTile(
        leading: const Icon(Icons.add_rounded),
        title: const AutoSizeText(
          "Add New Routine",
          maxLines: 1,
          overflow: TextOverflow.visible,
          softWrap: false,
          minFontSize: Constants.small,
        ),
        onTap: () async {
          await showDialog(
              barrierDismissible: false,
              useRootNavigator: false,
              context: context,
              builder: (BuildContext context) =>
                  CreateRoutineScreen(routineTime: timeOfDay));
        });
  }

  Widget buildRoutineSelectionList(
      {required Future<List<Routine>> searchFuture,
      required SearchController controller,
      required RoutineTime timeOfDay}) {
    return FutureBuilder(
        future: searchFuture,
        builder: (BuildContext context, AsyncSnapshot<List<Routine>> snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            final List<Routine>? routines = snapshot.data;
            if (null != routines) {
              return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: routines.length,
                  itemBuilder: (BuildContext context, int index) {
                    return ListTile(
                        title: AutoSizeText(routines[index].name),
                        onTap: () => handleRoutineSelection(
                              context: context,
                              routine: routines[index],
                              controller: controller,
                              timeOfDay: timeOfDay,
                            ));
                  });
            }
            return const SizedBox.shrink();
          }
          return const Padding(
            padding: EdgeInsets.all(Constants.padding),
            child: CircularProgressIndicator(),
          );
        });
  }
}
