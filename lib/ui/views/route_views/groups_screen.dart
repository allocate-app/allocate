import 'package:allocate/providers/model/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../model/task/group.dart';
import '../../../providers/model/group_provider.dart';
import '../../../providers/model/todo_provider.dart';
import '../../../util/constants.dart';
import '../../../util/enums.dart';
import '../../../util/interfaces/i_model.dart';
import '../../widgets/listview_header.dart';
import '../../widgets/listviews.dart';
import '../../widgets/paginating_listview.dart';
import '../../widgets/tiles.dart';
import '../sub_views/create_group.dart';

class GroupsListScreen extends StatefulWidget {
  const GroupsListScreen({super.key});

  @override
  State<GroupsListScreen> createState() => _GroupsListScreen();
}

class _GroupsListScreen extends State<GroupsListScreen> {
  late final GroupProvider groupProvider;
  late final ToDoProvider toDoProvider;
  late final UserProvider userProvider;

  @override
  void initState() {
    super.initState();
    initializeProviders();
  }

  void initializeProviders() {
    groupProvider = Provider.of<GroupProvider>(context, listen: false);
    toDoProvider = Provider.of<ToDoProvider>(context, listen: false);
    userProvider = Provider.of<UserProvider>(context, listen: false);
  }

  void initializeControllers() {}

  Future<void> onRemove({IModel? item}) async {
    if (null == item) {
      return;
    }

    switch (item.modelType) {
      case ModelType.task:
        if (toDoProvider.toDos.length < 2) {
          return;
        }
      case ModelType.group:
        if (groupProvider.groups.length < 2) {
          return;
        }
      default:
        break;
    }

    if (mounted) {
      setState(() => item.fade = Fade.fadeOut);
      await Future.delayed(const Duration(milliseconds: Constants.fadeOutTime));
    }
  }

  void onFetch({List<IModel>? items}) {
    if (null == items || items.isEmpty) {
      return;
    }

    for (IModel item in items) {
      item.fade = Fade.fadeIn;
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(Constants.padding),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        ListViewHeader<Group>(
            outerPadding: const EdgeInsets.all(Constants.padding),
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
          outerPadding:
              const EdgeInsets.symmetric(vertical: Constants.halfPadding),
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
              onFetch: (userProvider.curUser?.reduceMotion ?? false)
                  ? null
                  : onFetch,
              onRemove: (userProvider.curUser?.reduceMotion ?? false)
                  ? null
                  : onRemove,
              getAnimationKey: () => ValueKey(
                  groupProvider.sorter.sortMethod.index *
                          (groupProvider.sorter.descending ? -1 : 1) +
                      (groupProvider.groups.isEmpty ? 0 : 1)),
              listviewBuilder: (
                  {Key? key,
                  required BuildContext context,
                  required List<Group> items,
                  Future<void> Function({Group? item})? onRemove}) {
                if (groupProvider.sortMethod == SortMethod.none) {
                  return ListViews.reorderableGroups(
                    key: key,
                    context: context,
                    groups: items,
                    checkDelete: userProvider.curUser?.checkDelete ?? true,
                    onRemove: onRemove,
                    onToDoFetch: onFetch,
                    onToDoRemove: this.onRemove,
                  );
                }
                return ListViews.immutableGroups(
                    key: key,
                    groups: items,
                    checkDelete: userProvider.curUser?.checkDelete ?? true,
                    onRemove: onRemove,
                    onToDoFetch: onFetch,
                    onToDoRemove: this.onRemove);
              }),
        ),
      ]),
    );
  }
}
