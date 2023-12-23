import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../model/task/group.dart';
import '../../../providers/group_provider.dart';
import '../../../providers/todo_provider.dart';
import '../../../util/constants.dart';
import '../../../util/enums.dart';
import '../../widgets/listview_header.dart';
import '../../widgets/listviews.dart';
import '../../widgets/paginating_listview.dart';
import '../../widgets/tiles.dart';
import '../sub_views/create_group.dart';

class GroupsListScreen extends StatefulWidget {
  const GroupsListScreen({Key? key}) : super(key: key);

  @override
  State<GroupsListScreen> createState() => _GroupsListScreen();
}

class _GroupsListScreen extends State<GroupsListScreen> {
  late bool checkDelete;

  late final GroupProvider groupProvider;
  late final ToDoProvider toDoProvider;

  @override
  void initState() {
    super.initState();
    initializeProviders();
    initializeParameters();
  }

  void initializeProviders() {
    groupProvider = Provider.of<GroupProvider>(context, listen: false);
    toDoProvider = Provider.of<ToDoProvider>(context, listen: false);
  }

  void initializeParameters() {
    checkDelete = true;
  }

  void initializeControllers() {}

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
        ListViewHeader<Group>(
            header: "Groups",
            leadingIcon: const Icon(Icons.table_view_rounded),
            sorter: groupProvider.sorter,
            onChanged: ({SortMethod? sortMethod}) {
              if (null == sortMethod) {
                return;
              }
              if (mounted) {
                setState(() {
                  groupProvider.sortMethod = sortMethod;
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
          child: PaginatingListview<Group>(
              items: groupProvider.groups,
              query: groupProvider.getGroupsBy,
              offset: (groupProvider.rebuild) ? 0 : groupProvider.groups.length,
              limit: Constants.minLimitPerQuery,
              rebuildNotifiers: [groupProvider],
              rebuildCallback: ({required List<Group> items}) {
                groupProvider.groups = items;
                groupProvider.rebuild = false;
              },
              paginateButton: false,
              listviewBuilder: (
                  {Key? key,
                  required BuildContext context,
                  required List<Group> items}) {
                if (groupProvider.sortMethod == SortMethod.none) {
                  return ListViews.reorderableGroups(
                    key: key,
                    context: context,
                    groups: items,
                    checkDelete: checkDelete,
                  );
                }
                return ListViews.immutableGroups(
                  key: key,
                  context: context,
                  groups: items,
                  checkDelete: checkDelete,
                );
              }),
        ),
      ]),
    );
  }
}
