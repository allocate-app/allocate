import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../model/task/deadline.dart';
import '../../../providers/deadline_provider.dart';
import '../../../util/constants.dart';
import '../../../util/enums.dart';
import '../../widgets/listview_header.dart';
import '../../widgets/listviews.dart';
import '../../widgets/paginating_listview.dart';
import '../../widgets/tiles.dart';
import '../sub_views/create_deadline.dart';

class DeadlinesListScreen extends StatefulWidget {
  const DeadlinesListScreen({super.key});

  @override
  State<DeadlinesListScreen> createState() => _DeadlinesListScreen();
}

class _DeadlinesListScreen extends State<DeadlinesListScreen> {
  late bool checkDelete;

  late final DeadlineProvider deadlineProvider;

  @override
  void initState() {
    super.initState();
    initializeProviders();
    initializeParameters();
  }

  void initializeProviders() {
    deadlineProvider = Provider.of<DeadlineProvider>(context, listen: false);
    if (deadlineProvider.rebuild) {
      deadlineProvider.deadlines = [];
    }
  }

  void initializeParameters() {
    checkDelete = true;
  }

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
        ListViewHeader<Deadline>(
            header: "Deadlines",
            sorter: deadlineProvider.sorter,
            leadingIcon: const Icon(Icons.announcement_outlined),
            onChanged: ({SortMethod? sortMethod}) {
              if (null == sortMethod) {
                return;
              }
              if (mounted) {
                setState(() {
                  deadlineProvider.sortMethod = sortMethod;
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
          child: PaginatingListview<Deadline>(
              items: deadlineProvider.deadlines,
              query: deadlineProvider.getDeadlinesBy,
              offset: (deadlineProvider.rebuild)
                  ? 0
                  : deadlineProvider.deadlines.length,
              limit: Constants.minLimitPerQuery,
              rebuildNotifiers: [deadlineProvider],
              getAnimationKey: () => ValueKey(
                  deadlineProvider.sorter.sortMethod.index *
                          (deadlineProvider.sorter.descending ? -1 : 1) +
                      (deadlineProvider.deadlines.isEmpty ? 0 : 1)),
              rebuildCallback: ({required List<Deadline> items}) {
                deadlineProvider.deadlines = items;
                deadlineProvider.rebuild = false;
              },

              // TODO: make condtnl
              onFetch: ({List<Deadline>? items}) {
                if (null == items) {
                  return;
                }
                for (Deadline deadline in items) {
                  deadline.fade = Fade.fadeIn;
                }
              },
              onRemove: ({Deadline? item}) async {
                if (null == item) {
                  return;
                }

                if (deadlineProvider.deadlines.length < 2) {
                  return;
                }

                if (mounted) {
                  setState(() => item.fade = Fade.fadeOut);
                  await Future.delayed(
                      const Duration(milliseconds: Constants.fadeOutTime));
                }
              },
              paginateButton: false,
              listviewBuilder: (
                  {Key? key,
                  required BuildContext context,
                  required List<Deadline> items,
                  Future<void> Function({Deadline? item})? onRemove}) {
                if (deadlineProvider.sortMethod == SortMethod.none) {
                  return ListViews.reorderableDeadlines(
                    key: key,
                    context: context,
                    deadlines: items,
                    checkDelete: checkDelete,
                    smallScreen: smallScreen,
                    onRemove: onRemove,
                  );
                }
                return ListViews.immutableDeadlines(
                  key: key,
                  context: context,
                  deadlines: items,
                  checkDelete: checkDelete,
                  smallScreen: smallScreen,
                  onRemove: onRemove,
                );
              }),
        ),
      ]),
    );
  }
}
