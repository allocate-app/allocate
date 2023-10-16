import 'dart:math';

import 'package:another_flushbar/flushbar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../model/task/deadline.dart';
import '../../../providers/deadline_provider.dart';
import '../../../util/constants.dart';
import '../../../util/enums.dart';
import '../../widgets/flushbars.dart';
import '../../widgets/listview_header.dart';
import '../../widgets/listviews.dart';
import '../../widgets/tiles.dart';
import '../sub_views/create_deadline.dart';

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
  late int limit;
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
    deadlineProvider.removeListener(resetPagination);
    super.dispose();
  }

  Future<void> resetPagination() async {
    offset = 0;
    limit = max(deadlines.length, Constants.minLimitPerQuery);
    return await overwriteData();
  }

  Future<void> overwriteData() async {
    List<Deadline> newDeadlines = await fetchData();
    if (mounted) {
      return setState(() {
        offset += newDeadlines.length;
        deadlines = newDeadlines;
        loading = false;
        // showTopLoading = false;
        allData = deadlines.length < limit;
        limit = Constants.minLimitPerQuery;
      });
    }
  }

  Future<void> appendData() async {
    List<Deadline> newDeadlines = await fetchData();
    if (mounted) {
      return setState(() {
        offset += newDeadlines.length;
        deadlines.addAll(newDeadlines);
        loading = false;
        allData = newDeadlines.length < limit;
      });
    }
  }

  Future<List<Deadline>> fetchData() async {
    if (mounted) {
      setState(() => loading = true);
    }
    return await deadlineProvider
        .getDeadlinesBy(limit: limit, offset: offset)
        .catchError(
      (e) {
        Flushbar? error;

        error = Flushbars.createError(
          message: e.cause ?? "Query Error",
          context: context,
          dismissCallback: () => error?.dismiss(),
        );

        error.show(context);
        return List<Deadline>.empty(growable: true);
      },
    );
  }

  // Convenience accessors.
  List<Deadline> get deadlines => deadlineProvider.deadlines;

  set deadlines(List<Deadline> newDeadlines) =>
      deadlineProvider.deadlines = newDeadlines;

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    bool largeScreen = (width >= Constants.largeScreen);
    bool smallScreen = (width <= Constants.smallScreen);

    return Padding(
      padding: const EdgeInsets.all(Constants.innerPadding),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        ListViewHeader<Deadline>(
            header: "Deadlines",
            sorter: deadlineProvider.sorter,
            onChanged: (SortMethod? method) {
              if (null == method) {
                return;
              }
              if (mounted) {
                setState(() {
                  deadlineProvider.sortMethod = method;
                });
              }
            }),
        Tiles.createNew(
          context: context,
          onTap: () async => await showDialog(
            barrierDismissible: false,
            context: context,
            builder: (BuildContext context) => const CreateDeadlineScreen(),
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
                  (deadlineProvider.sortMethod == SortMethod.none)
                      ? ListViews.reorderableDeadlines(
                          smallScreen: smallScreen,
                          context: context,
                          deadlines: deadlines,
                          checkDelete: checkDelete)
                      : ListViews.immutableDeadlines(
                          smallScreen: smallScreen,
                          context: context,
                          deadlines: deadlines,
                          checkDelete: checkDelete)
                ]),
          ),
        )
      ]),
    );
  }
}
