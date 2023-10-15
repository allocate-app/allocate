import 'dart:math';

import 'package:another_flushbar/flushbar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../model/task/routine.dart';
import '../../../providers/routine_provider.dart';
import '../../../util/constants.dart';
import '../../../util/enums.dart';
import '../../widgets/flushbars.dart';
import '../../widgets/listview_header.dart';
import '../../widgets/listviews.dart';
import '../../widgets/tiles.dart';
import '../sub_views/create_routine.dart';

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
  late int limit;

  late final RoutineProvider routineProvider;

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
    routineProvider.removeListener(resetPagination);
    super.dispose();
  }

  Future<void> resetPagination() async {
    offset = 0;
    limit = max(routines.length, Constants.minLimitPerQuery);

    return await overwriteData();
  }

  Future<void> overwriteData() async {
    List<Routine> newRoutines = await fetchData();

    if (mounted) {
      return setState(() {
        offset += newRoutines.length;
        routines = newRoutines;
        loading = false;
        // showTopLoading = false;
        allData = routines.length <= limit;
        limit = Constants.minLimitPerQuery;
      });
    }
  }

  Future<void> appendData() async {
    List<Routine> newRoutines = await fetchData();
    if (mounted) {
      return setState(() {
        offset += newRoutines.length;
        routines.addAll(newRoutines);
        loading = false;
        allData = newRoutines.length < limit;
      });
    }
  }

  Future<List<Routine>> fetchData() async {
    if (mounted) {
      setState(() => loading = true);
    }
    return await routineProvider
        .getRoutinesBy(limit: limit, offset: offset)
        .catchError(
          (e) {
        Flushbar? error;

        error = Flushbars.createError(
          message: e.cause ?? "Query Error",
          context: context,
          dismissCallback: () => error?.dismiss(),
        );

        error.show(context);
        return List<Routine>.empty(growable: true);
      },
    );
  }

  // Convenience accessors.
  List<Routine> get routines => routineProvider.routines;

  set routines(List<Routine> newRoutines) =>
      routineProvider.routines = newRoutines;

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery
        .of(context)
        .size
        .width;
    bool largeScreen = (width >= Constants.largeScreen);
    bool smallScreen = (width <= Constants.smallScreen);

    return Padding(
      padding: const EdgeInsets.all(Constants.innerPadding),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        ListViewHeader(
            header: "Routines",
            sorter: routineProvider.sorter,
            onChanged: (SortMethod? method) {
              if (null == method) {
                return;
              }
              if (mounted) {
                setState(() {
                  routineProvider.sortMethod = method;
                });
              }
            }),
        Tiles.createNew(
          context: context,
          onTap: () async =>
          await showDialog(
            barrierDismissible: false,
            context: context,
            builder: (BuildContext context) => const CreateRoutineScreen(),
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
                  // DB is too fast & is causing jarring repaints.
                  // (showTopLoading)
                  //     ? const CircularProgressIndicator()
                  //     : const SizedBox.shrink(),
                  (routineProvider.sortMethod == SortMethod.none)
                      ? ListViews.reorderableRoutines(
                      context: context,
                      routines: routines,
                      checkDelete: checkDelete)
                      : ListViews.immutableRoutines(
                      context: context,
                      routines: routines,
                      checkDelete: checkDelete)
                ]),
          ),
        )
      ]),
    );
  }
}
