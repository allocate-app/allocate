import 'package:allocate/ui/blurred_dialog.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../model/task/deadline.dart';
import '../../../providers/application/layout_provider.dart';
import '../../../providers/model/deadline_provider.dart';
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
  late final DeadlineProvider deadlineProvider;
  late final LayoutProvider layoutProvider;

  @override
  void initState() {
    super.initState();
    initializeProviders();
  }

  void initializeProviders() {
    deadlineProvider = Provider.of<DeadlineProvider>(context, listen: false);

    layoutProvider = Provider.of<LayoutProvider>(context, listen: false);
  }

  @override
  void dispose() {
    super.dispose();
  }

  void onFetch({List<Deadline>? items}) {
    if (null == items) {
      return;
    }

    DateTime threshold = DateTime.now();
    threshold = threshold.copyWith(
        millisecond: threshold.millisecond - Constants.newItemThreshold);
    for (Deadline deadline in items) {
      if (!deadline.lastUpdated.isBefore(threshold)) {
        deadline.fade = Fade.fadeIn;
      }
    }
  }

  Future<void> onRemove({Deadline? item}) async {
    if (null == item) {
      return;
    }

    if (deadlineProvider.deadlines.length < 2) {
      return;
    }

    if (mounted) {
      setState(() => item.fade = Fade.fadeOut);
      await Future.delayed(const Duration(milliseconds: Constants.fadeOutTime));
    }
  }

  void onAppend({List<Deadline>? items}) {
    if (null == items) {
      return;
    }
    for (Deadline deadline in items) {
      deadline.fade = Fade.fadeIn;
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return Padding(
          padding: const EdgeInsets.all(Constants.padding),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            ListViewHeader<Deadline>(
                outerPadding: const EdgeInsets.all(Constants.padding),
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
              outerPadding:
                  const EdgeInsets.symmetric(vertical: Constants.halfPadding),
              context: context,
              onTap: () async => await blurredNonDismissible(
                  context: context, dialog: const CreateDeadlineScreen()),
              // await showDialog(
              //   useRootNavigator: false,
              //   barrierDismissible: false,
              //   context: context,
              //   builder: (BuildContext context) => const CreateDeadlineScreen(),
              // ),
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
                  getAnimationKey:
                      (deadlineProvider.userViewModel?.reduceMotion ?? false)
                          ? null
                          : () => ValueKey(
                              deadlineProvider.sorter.sortMethod.index *
                                      (deadlineProvider.sorter.descending
                                          ? -1
                                          : 1) +
                                  (deadlineProvider.deadlines.isEmpty ? 0 : 1)),
                  rebuildCallback: ({required List<Deadline> items}) {
                    deadlineProvider.deadlines = items;
                    deadlineProvider.softRebuild = false;
                  },
                  onFetch:
                      (deadlineProvider.userViewModel?.reduceMotion ?? false)
                          ? null
                          : onFetch,
                  onRemove:
                      (deadlineProvider.userViewModel?.reduceMotion ?? false)
                          ? null
                          : onRemove,
                  onAppend:
                      (deadlineProvider.userViewModel?.reduceMotion ?? false)
                          ? null
                          : onAppend,
                  listviewBuilder: (
                      {Key? key,
                      required BuildContext context,
                      required List<Deadline> items,
                      Future<void> Function({Deadline? item})? onRemove}) {
                    if (deadlineProvider.sortMethod == SortMethod.none) {
                      return ListViews.reorderableDeadlines(
                        key: key,
                        listPadding: Constants.fabPadding,
                        context: context,
                        deadlines: items,
                        checkDelete:
                            deadlineProvider.userViewModel?.checkDelete ?? true,
                        smallScreen: layoutProvider.smallScreen,
                        onRemove: onRemove,
                      );
                    }
                    return ListViews.immutableDeadlines(
                      key: key,
                      listPadding: Constants.fabPadding,
                      deadlines: items,
                      checkDelete:
                          deadlineProvider.userViewModel?.checkDelete ?? true,
                      smallScreen: layoutProvider.smallScreen,
                      onRemove: onRemove,
                    );
                  }),
            ),
          ]),
        );
      },
    );
  }
}
