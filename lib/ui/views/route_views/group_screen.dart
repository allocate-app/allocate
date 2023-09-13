import 'package:another_flushbar/flushbar.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../model/task/group.dart';
import '../../../providers/group_provider.dart';
import '../../../util/constants.dart';
import '../../../util/enums.dart';
import '../../../util/exceptions.dart';
import '../../../util/sorting/group_sorter.dart';
import '../../widgets/flushbars.dart';
import '../sub_views/create_group.dart';
import '../sub_views/update_group.dart';

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

  late final GroupProvider groupProvider;

  // For linked todos.
  late final ScrollController mainScrollController;
  late final ScrollPhysics scrollPhysics;

  // For Task search.
  late final SearchController searchController;
  late List<MapEntry<String, int>> searchHistory;

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

    groupProvider.addListener(resetPagination);
  }

  void initializeParameters() {
    loading = groupProvider.rebuild;
    allData = false;
    checkDelete = true;
    offset = (groupProvider.rebuild) ? 0 : groupProvider.groups.length;
    searchHistory = List.empty(growable: true);
  }

  void initializeControllers() {
    searchController = SearchController();
    mainScrollController = ScrollController();

    mainScrollController.addListener(() async {
      // Bottom: Run the query.
      if (mainScrollController.offset >=
              mainScrollController.position.maxScrollExtent &&
          !allData) {
        if (!loading && mounted) {
          setState(() => loading = true);
          await fetchData();
        }
      }
    });

    scrollPhysics =
        const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics());
  }

  Widget getArrowDirection({required SortMethod method}) {
    if (groupProvider.sortMethod == SortMethod.none) {
      return const SizedBox.shrink();
    }

    if (groupProvider.sortMethod == method && !groupProvider.descending) {
      return const Icon(Icons.arrow_downward_rounded);
    }

    return const Icon(Icons.arrow_upward_rounded);
  }

  Future<void> fetchData() async {
    setState(() => loading = true);
    return Future.delayed(
        const Duration(seconds: 1),
        () async => await groupProvider
                .getGroupsBy(limit: Constants.limitPerQuery, offset: offset)
                .then((newGroups) {
              offset += newGroups.length;
              groupProvider.groups.addAll(newGroups);
              allData = newGroups.length < Constants.limitPerQuery;

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
      groupProvider.groups.clear();
    });
    return await fetchData();
  }

  // Grab search from todos scrn.

  @override
  void dispose() {
    groupProvider.removeListener(resetPagination);
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
                child: AutoSizeText("Groups",
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
                    value: groupProvider.sortMethod,
                    icon: (groupProvider.sortMethod != SortMethod.none)
                        ? (groupProvider.descending)
                            ? const Icon(Icons.arrow_downward_rounded)
                            : const Icon(Icons.arrow_upward_rounded)
                        : null,
                    borderRadius: const BorderRadius.all(
                        Radius.circular(Constants.roundedCorners)),
                    onChanged: (method) {
                      if (null != method) {
                        setState(() {
                          groupProvider.sortMethod = method;
                        });
                      }
                    },
                    items: GroupSorter.sortMethods
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
        Padding(
          padding: const EdgeInsets.symmetric(vertical: Constants.padding),
          child: ListTile(
            shape: const RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.all(Radius.circular(Constants.roundedCorners)),
            ),
            onTap: () async => await showDialog(
              barrierDismissible: false,
              context: context,
              builder: (BuildContext context) => const CreateGroupScreen(),
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
        ),
        Flexible(
          child: (loading)
              ? const CircularProgressIndicator()
              : buildGroupsList(
                  smallScreen: smallScreen,
                  physics: scrollPhysics,
                  largeScreen: largeScreen),
        ),
      ]),
    );
  }

  ListView buildGroupsList(
      {bool smallScreen = false,
      ScrollPhysics physics = const BouncingScrollPhysics(),
      largeScreen = false}) {
    return ListView(
        controller: mainScrollController,
        physics: physics,
        shrinkWrap: true,
        children: [
          Consumer<GroupProvider>(
            builder:
                (BuildContext context, GroupProvider value, Widget? child) {
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
      {required GroupProvider provider,
      required BuildContext context,
      bool largeScreen = false}) {
    return ReorderableListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: provider.groups.length,
        onReorder: (int oldIndex, int newIndex) async {
          provider.groups = await provider
              .reorderGroups(
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
            return List<Group>.empty(growable: true);
          },
                  test: (e) =>
                      e is FailureToCreateException ||
                      e is FailureToUploadException);
          if (provider.groups.isEmpty) {
            resetPagination();
          }
        },
        itemBuilder: (BuildContext context, int index) {
          // This needs to be a listtile
          return buildGroupExpansionTile(
              index: index, context: context, provider: provider);
        });
  }

  ListView buildImmutable(
      {required GroupProvider provider,
      required BuildContext context,
      bool largeScreen = false}) {
    return ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: provider.groups.length,
        itemBuilder: (BuildContext context, int index) {
          return buildGroupExpansionTile(
              index: index, context: context, provider: provider);
        });
  }

  Widget buildGroupExpansionTile(
      {required int index,
      required BuildContext context,
      required GroupProvider provider}) {
    // This needs rebuilding.

    // Refactor into an expansion tile card.
    // Somehow... > May need to use a tile within the card.
    return Card(
      key: ValueKey(index),
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      color: Colors.transparent,
      shape: RoundedRectangleBorder(
          side: BorderSide(
              color: Theme.of(context).colorScheme.outline,
              strokeAlign: BorderSide.strokeAlignOutside),
          borderRadius: const BorderRadius.all(
              Radius.circular(Constants.roundedCorners))),
      child: ExpansionTile(
        onExpansionChanged: (value) {
          if (value) {
            // TODO: Change this to query.
            groupProvider.groups[index].toDos = [];
          }
        },
        leading: IconButton.filledTonal(
            icon: const Icon(Icons.edit_rounded),
            onPressed: () async {
              provider.curGroup = provider.groups[index];
              await showDialog(
                  barrierDismissible: false,
                  useRootNavigator: false,
                  context: context,
                  builder: (BuildContext context) =>
                      const UpdateGroupScreen()).catchError((e) {
                Flushbar? error;

                error = Flushbars.createError(
                  message: e.cause,
                  context: context,
                  dismissCallback: () => error?.dismiss(),
                );

                error.show(context);
              },
                  test: (e) =>
                      e is FailureToCreateException ||
                      e is FailureToUploadException);
            }),
        collapsedShape: const RoundedRectangleBorder(
            borderRadius:
                BorderRadius.all(Radius.circular(Constants.roundedCorners))),
        shape: const RoundedRectangleBorder(
            borderRadius:
                BorderRadius.all(Radius.circular(Constants.roundedCorners))),
        title: AutoSizeText(provider.groups[index].name,
            overflow: TextOverflow.visible,
            style: Constants.headerStyle,
            minFontSize: Constants.medium,
            softWrap: true,
            maxLines: 1),
        trailing: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: Constants.innerPadding),
          child: IconButton(
              icon: const Icon(Icons.delete_forever),
              onPressed: () async {
                // TODO: Modal for delete with checkDelete;
                // Factor out into a method.
                provider.curGroup = provider.groups[index];

                await provider.deleteGroup().catchError((e) {
                  Flushbar? error;

                  error = Flushbars.createError(
                    message: e.cause,
                    context: context,
                    dismissCallback: () => error?.dismiss(),
                  );

                  error.show(context);
                },
                    test: (e) =>
                        e is FailureToDeleteException ||
                        e is FailureToUploadException);
              }),
        ),
        // TODO: Listview builder from group tasks.
        // Needs to be a future builder -> snag from create group.
        // OR -> wait. Hold on. Use a consumer/ref.context. && the Group's own list object.
        children: [
          // Scrollbar(
          //   thumbVisibility: true,
          //   child: null,
          //   controller: null,
          //   child: buildToDosList(
          //     smallScreen: smallScreen,
          //     physics: scrollPhysics,
          //   ),
          //   const PaddedDivider(padding: Constants.padding),
          //   buildToDoSearchBar(),
          //   const PaddedDivider(
          //     padding: Constants.innerPadding)
          //   ),
          //   buildCreateToDoBar(context: context)
          // ),
        ],
      ),
    );
  }
}
