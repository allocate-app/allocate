import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../model/task/routine.dart';
import '../../../providers/application/layout_provider.dart';
import '../../../providers/model/routine_provider.dart';
import '../../../util/constants.dart';
import '../../../util/enums.dart';
import '../../../util/sorting/routine_sorter.dart';
import '../../blurred_dialog.dart';
import '../../widgets/listview_header.dart';
import '../../widgets/listviews.dart';
import '../../widgets/paginating_listview.dart';
import '../../widgets/tiles.dart';
import '../sub_views/create_routine.dart';

class RoutinesListScreen extends StatefulWidget {
  const RoutinesListScreen({super.key});

  @override
  State<RoutinesListScreen> createState() => _RoutinesListScreen();
}

class _RoutinesListScreen extends State<RoutinesListScreen> {
  late final RoutineProvider routineProvider;
  late final LayoutProvider layoutProvider;

  @override
  void initState() {
    super.initState();
    initializeProviders();
  }

  void initializeProviders() {
    routineProvider = Provider.of<RoutineProvider>(context, listen: false);
    layoutProvider = Provider.of<LayoutProvider>(context, listen: false);
  }

  @override
  void dispose() {
    super.dispose();
  }

  void onFetch({List<Routine>? items}) {
    if (null == items) {
      return;
    }

    DateTime threshold = DateTime.now();
    threshold = threshold.copyWith(
        millisecond: threshold.millisecond - Constants.newItemThreshold);
    for (Routine routine in items) {
      if (!routine.lastUpdated.isBefore(threshold)) {
        routine.fade = Fade.fadeIn;
      }
    }
  }

  void onAppend({List<Routine>? items}) {
    if (null == items) {
      return;
    }
    for (Routine routine in items) {
      routine.fade = Fade.fadeIn;
    }
  }

  Future<void> onRemove({Routine? item}) async {
    if (null == item) {
      return;
    }

    if (routineProvider.routines.length < 2) {
      return;
    }

    if (mounted) {
      setState(() => item.fade = Fade.fadeOut);
      await Future.delayed(const Duration(milliseconds: Constants.fadeOutTime));
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
      return Padding(
        padding: const EdgeInsets.all(Constants.padding),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Selector<RoutineProvider, RoutineSorter>(
            selector: (BuildContext context, RoutineProvider rp) => rp.sorter,
            builder:
                (BuildContext context, RoutineSorter sorter, Widget? child) =>
                    ListViewHeader<Routine>(
                        outerPadding: const EdgeInsets.all(Constants.padding),
                        header: "Routines",
                        sorter: routineProvider.sorter,
                        leadingIcon: const Icon(Icons.repeat_rounded),
                        onChanged: ({SortMethod? sortMethod}) {
                          if (null == sortMethod) {
                            return;
                          }
                          if (mounted) {
                            setState(() {
                              routineProvider.sortMethod = sortMethod;
                            });
                          }
                        }),
          ),
          Tiles.createNew(
            outerPadding:
                const EdgeInsets.symmetric(vertical: Constants.halfPadding),
            context: context,
            onTap: () async => await blurredNonDismissible(
                context: context, dialog: const CreateRoutineScreen()),
            // await showDialog(
            //   useRootNavigator: false,
            //   barrierDismissible: false,
            //   context: context,
            //   builder: (BuildContext context) => const CreateRoutineScreen(),
            // ),
          ),
          Flexible(
            child: PaginatingListview<Routine>(
                items: routineProvider.routines,
                query: routineProvider.getRoutinesBy,
                offset: (routineProvider.rebuild)
                    ? 0
                    : routineProvider.routines.length,
                limit: Constants.minLimitPerQuery,
                rebuildNotifiers: [routineProvider],
                rebuildCallback: ({required List<Routine> items}) {
                  routineProvider.routines = items;
                  routineProvider.softRebuild = false;
                },
                getAnimationKey: (routineProvider.userViewModel?.reduceMotion ??
                        false)
                    ? null
                    : () => ValueKey(routineProvider.sorter.sortMethod.index *
                            (routineProvider.sorter.descending ? -1 : 1) +
                        (routineProvider.routines.isEmpty ? 0 : 1)),
                onFetch: (routineProvider.userViewModel?.reduceMotion ?? false)
                    ? null
                    : onFetch,
                onRemove: (routineProvider.userViewModel?.reduceMotion ?? false)
                    ? null
                    : onRemove,
                onAppend: (routineProvider.userViewModel?.reduceMotion ?? false)
                    ? null
                    : onAppend,
                listviewBuilder: ({
                  Key? key,
                  required BuildContext context,
                  required List<Routine> items,
                  Future<void> Function({Routine? item})? onRemove,
                }) {
                  if (routineProvider.sortMethod == SortMethod.none) {
                    return ListViews.reorderableRoutines(
                      key: key,
                      listPadding: Constants.fabPadding,
                      context: context,
                      routines: items,
                      checkDelete:
                          routineProvider.userViewModel?.checkDelete ?? true,
                      onRemove: onRemove,
                    );
                  }
                  return ListViews.immutableRoutines(
                    key: key,
                    listPadding: Constants.fabPadding,
                    routines: items,
                    checkDelete:
                        routineProvider.userViewModel?.checkDelete ?? true,
                    onRemove: onRemove,
                  );
                }),
          ),
        ]),
      );
    });
  }
}
