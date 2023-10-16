import 'dart:math';

import 'package:another_flushbar/flushbar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../model/task/group.dart';
import '../../../providers/group_provider.dart';
import '../../../providers/todo_provider.dart';
import '../../../util/constants.dart';
import '../../../util/enums.dart';
import '../../widgets/flushbars.dart';
import '../../widgets/listview_header.dart';
import '../../widgets/listviews.dart';
import '../../widgets/tiles.dart';
import '../sub_views/create_group.dart';

class GroupsListScreen extends StatefulWidget {
  const GroupsListScreen({Key? key}) : super(key: key);

  @override
  State<GroupsListScreen> createState() => _GroupsListScreen();
}

class _GroupsListScreen extends State<GroupsListScreen> {
  late bool checkDelete;
  late bool allData;

  late bool loading;
  late int offset;
  late int limit;

  late final GroupProvider groupProvider;
  late final ToDoProvider toDoProvider;

  // For linked todos.
  late final ScrollController mainScrollController;
  late final ScrollPhysics scrollPhysics;

  @override
  void initState() {
    super.initState();
    initializeProviders();
    initializeParameters();
    initializeControllers();

    if (groupProvider.rebuild) {
      resetPagination();
      groupProvider.rebuild = false;
    }
  }

  void initializeProviders() {
    groupProvider = Provider.of<GroupProvider>(context, listen: false);
    toDoProvider = Provider.of<ToDoProvider>(context, listen: false);

    groupProvider.addListener(resetPagination);
    toDoProvider.addListener(resetPagination);
  }

  void initializeParameters() {
    loading = groupProvider.rebuild;
    allData = false;
    checkDelete = true;
    offset = (groupProvider.rebuild) ? 0 : groupProvider.groups.length;
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
    groupProvider.removeListener(resetPagination);
    toDoProvider.removeListener(resetPagination);
    super.dispose();
  }

  Future<void> resetPagination() async {
    offset = 0;
    limit = max(groups.length, Constants.minLimitPerQuery);
    return await overwriteData();
  }

  Future<void> overwriteData() async {
    List<Group> newGroups = await fetchData();
    if (mounted) {
      return setState(() {
        offset += newGroups.length;
        groups = newGroups;
        loading = false;
        // showTopLoading = false;
        allData = newGroups.length < limit;
        limit = Constants.minLimitPerQuery;
      });
    }
  }

  Future<void> appendData() async {
    List<Group> newGroups = await fetchData();
    if (mounted) {
      return setState(() {
        offset += newGroups.length;
        groups.addAll(newGroups);
        loading = false;
        allData = newGroups.length < limit;
      });
    }
  }

  Future<List<Group>> fetchData() async {
    if (mounted) {
      setState(() => loading = true);
    }
    // Future TODO: refactor this to paginate.
    return await groupProvider
        .getGroupsBy(limit: limit, offset: offset, grabToDos: true)
        .catchError(
      (e) {
        Flushbar? error;

        error = Flushbars.createError(
          message: e.cause ?? "Query Error",
          context: context,
          dismissCallback: () => error?.dismiss(),
        );

        error.show(context);
        return List<Group>.empty(growable: true);
      },
    );
  }

  // Convenience accessors.
  List<Group> get groups => groupProvider.groups;

  set groups(List<Group> newGroups) => groupProvider.groups = newGroups;

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    bool largeScreen = (width >= Constants.largeScreen);
    bool smallScreen = (width <= Constants.smallScreen);

    return Padding(
      padding: const EdgeInsets.all(Constants.innerPadding),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        ListViewHeader<Group>(
            header: "Groups",
            sorter: groupProvider.sorter,
            onChanged: (SortMethod? method) {
              if (null == method) {
                return;
              }
              if (mounted) {
                setState(() {
                  groupProvider.sortMethod = method;
                });
              }
            }),
        Tiles.createNew(
          context: context,
          onTap: () async => await showDialog(
            barrierDismissible: false,
            context: context,
            builder: (BuildContext context) => const CreateGroupScreen(),
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
                  (groupProvider.sortMethod == SortMethod.none)
                      ? ListViews.reorderableGroups(
                          context: context,
                          groups: groups,
                          checkDelete: checkDelete)
                      : ListViews.immutableGroups(
                          context: context,
                          groups: groups,
                          checkDelete: checkDelete)
                ]),
          ),
        )
      ]),
    );
  }
}
