import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../model/task/routine.dart';
import '../../../model/task/subtask.dart';
import '../../../providers/application/layout_provider.dart';
import '../../../providers/model/routine_provider.dart';
import '../../../providers/model/subtask_provider.dart';
import '../../../services/application_service.dart';
import '../../../util/constants.dart';
import '../../../util/enums.dart';
import '../../widgets/tiles.dart';

// MIGRATE TO SELECTORS -> WATCH EACH ROUTINE
class MyDayRoutines extends StatefulWidget {
  const MyDayRoutines({super.key});

  @override
  State<MyDayRoutines> createState() => _MyDayRoutines();
}

class _MyDayRoutines extends State<MyDayRoutines> {
  late RoutineProvider routineProvider;
  late SubtaskProvider subtaskProvider;
  late LayoutProvider layoutProvider;

  late ApplicationService applicationService;

  late ScrollController mainScrollController;
  late ScrollPhysics scrollPhysics;

  @override
  void initState() {
    super.initState();

    initializeProviders();
    initializeControllers();
    updateSubtasks();
  }

  void initializeProviders() {
    routineProvider = Provider.of<RoutineProvider>(context, listen: false);
    subtaskProvider = Provider.of<SubtaskProvider>(context, listen: false);
    subtaskProvider.addListener(updateSubtasks);

    layoutProvider = Provider.of<LayoutProvider>(context, listen: false);

    applicationService = ApplicationService.instance;
    applicationService.addListener(scrollToTop);
  }

  void initializeControllers() {
    mainScrollController = ScrollController();
    ScrollPhysics parentPhysics = (Platform.isIOS || Platform.isMacOS)
        ? const BouncingScrollPhysics()
        : const ClampingScrollPhysics();
    scrollPhysics = AlwaysScrollableScrollPhysics(parent: parentPhysics);
  }

  @override
  void dispose() {
    applicationService.removeListener(scrollToTop);
    mainScrollController.dispose();
    subtaskProvider.removeListener(updateSubtasks);
    super.dispose();
  }

  void scrollToTop() {
    if (mainScrollController.hasClients) {
      mainScrollController.animateTo(
        0,
        duration: Constants.scrollDuration,
        curve: Constants.scrollCurve,
      );
    }
  }

  Future<void> updateSubtasks() async {
    await updateWeights();
    await getSubtasks();
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> getSubtasks() async {
    if (null != routineProvider.curMorning) {
      routineProvider.curMorning!.subtasks =
          await routineProvider.getSubtasks(id: routineProvider.curMorning!.id);
      routineProvider.setSubtaskCount(
          id: routineProvider.curMorning!.id,
          count: routineProvider.curMorning!.subtasks.length);
    }

    if (null != routineProvider.curAfternoon) {
      routineProvider.curAfternoon!.subtasks = await routineProvider
          .getSubtasks(id: routineProvider.curAfternoon!.id);
      routineProvider.setSubtaskCount(
          id: routineProvider.curAfternoon!.id,
          count: routineProvider.curAfternoon!.subtasks.length);
    }

    if (null != routineProvider.curEvening) {
      routineProvider.curEvening!.subtasks =
          await routineProvider.getSubtasks(id: routineProvider.curEvening!.id);
      routineProvider.setSubtaskCount(
          id: routineProvider.curEvening!.id,
          count: routineProvider.curEvening!.subtasks.length);
    }
  }

  Future<void> updateWeights() async {
    List<Routine> toUpdate = [];
    if (null != routineProvider.curMorning) {
      int weight = await routineProvider.getWeight(
          taskID: routineProvider.curMorning!.id);
      if (weight != routineProvider.curMorning!.weight) {
        routineProvider.curMorning!.weight = weight;
        toUpdate.add(routineProvider.curMorning!);
      }
    }

    if (null != routineProvider.curAfternoon) {
      int weight = await routineProvider.getWeight(
          taskID: routineProvider.curAfternoon!.id);
      if (weight != routineProvider.curAfternoon!.weight) {
        routineProvider.curAfternoon!.weight = weight;
        toUpdate.add(routineProvider.curAfternoon!);
      }
    }

    if (null != routineProvider.curEvening) {
      int weight = await routineProvider.getWeight(
          taskID: routineProvider.curEvening!.id);
      if (weight != routineProvider.curEvening!.weight) {
        routineProvider.curEvening!.weight = weight;
        toUpdate.add(routineProvider.curEvening!);
      }
    }
    await routineProvider.updateBatch(routines: toUpdate);
  }

  void onFetch({List<Subtask>? items, Set<Subtask>? itemSet}) {
    if (null == items || null == itemSet) {
      return;
    }
    for (Subtask subtask in items) {
      if (!itemSet.contains(subtask)) {
        subtask.fade = Fade.fadeIn;
      }
    }
  }

  Future<void> onRemove({Subtask? item}) async {
    if (null == item) {
      return;
    }

    if (mounted) {
      setState(() => item.fade = Fade.fadeOut);
      await Future.delayed(const Duration(milliseconds: Constants.fadeOutTime));
    }
  }

  void setExpanded({bool? expanded, int? index}) {
    if (null == expanded || null == index || index < 0 || index > 2) {
      return;
    }
    layoutProvider.routineExpanded[index] = expanded;
  }

  @override
  Widget build(BuildContext context) {
    Widget body = SingleChildScrollView(
      // padding: const EdgeInsets.only(bottom: 200),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      controller: mainScrollController,
      physics: scrollPhysics,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: buildRoutineCards(),
      ),
    );

    return (layoutProvider.isMobile)
        ? Scrollbar(
            controller: mainScrollController,
            child: body,
          )
        : body;
  }

  // FilledRoutine needs selector.
  Widget buildRoutineCards() {
    return Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Selector<RoutineProvider, Routine?>(
              selector: (BuildContext context, RoutineProvider rp) =>
                  rp.curMorning,
              builder: (BuildContext context, Routine? value, Widget? child) {
                return Padding(
                  padding: const EdgeInsets.only(
                      top: Constants.padding, bottom: Constants.doublePadding),
                  child: (null != value)
                      ? Tiles.filledRoutineTile(
                          vmIndex: 0,
                          initiallyExpanded: layoutProvider.routineExpanded[0],
                          onExpansionChanged: ({bool expanded = false}) =>
                              setExpanded(expanded: expanded, index: 0),
                          context: context,
                          onSubtaskRemove:
                              (routineProvider.userViewModel?.reduceMotion ??
                                      false)
                                  ? null
                                  : onRemove,
                          routine: value,
                          times: 1)
                      : Tiles.emptyRoutineTile(
                          context: context,
                          times: 1,
                          initiallyExpanded: layoutProvider.routineExpanded[0],
                          onExpansionChanged: ({bool expanded = false}) =>
                              setExpanded(expanded: expanded, index: 0),
                        ),
                );
              }),
          Selector<RoutineProvider, Routine?>(
              selector: (BuildContext context, RoutineProvider rp) =>
                  rp.curAfternoon,
              builder: (BuildContext context, Routine? value, Widget? child) {
                return Padding(
                  padding:
                      const EdgeInsets.only(bottom: Constants.doublePadding),
                  child: (null != value)
                      ? Tiles.filledRoutineTile(
                          vmIndex: 1,
                          initiallyExpanded: layoutProvider.routineExpanded[1],
                          onExpansionChanged: ({bool expanded = false}) =>
                              setExpanded(expanded: expanded, index: 1),
                          context: context,
                          onSubtaskRemove:
                              (routineProvider.userViewModel?.reduceMotion ??
                                      false)
                                  ? null
                                  : onRemove,
                          routine: value,
                          times: 2)
                      : Tiles.emptyRoutineTile(
                          context: context,
                          times: 2,
                          initiallyExpanded: layoutProvider.routineExpanded[1],
                          onExpansionChanged: ({bool expanded = false}) =>
                              setExpanded(expanded: expanded, index: 1),
                        ),
                );
              }),
          Selector<RoutineProvider, Routine?>(
              selector: (BuildContext context, RoutineProvider rp) =>
                  rp.curEvening,
              builder: (BuildContext context, Routine? value, Widget? child) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: Constants.padding),
                  child: (null != value)
                      ? Tiles.filledRoutineTile(
                          vmIndex: 2,
                          initiallyExpanded: layoutProvider.routineExpanded[2],
                          onExpansionChanged: ({bool expanded = false}) =>
                              setExpanded(expanded: expanded, index: 2),
                          context: context,
                          onSubtaskRemove:
                              (routineProvider.userViewModel?.reduceMotion ??
                                      false)
                                  ? null
                                  : onRemove,
                          routine: value,
                          times: 4)
                      : Tiles.emptyRoutineTile(
                          context: context,
                          times: 4,
                          initiallyExpanded: layoutProvider.routineExpanded[2],
                          onExpansionChanged: ({bool expanded = false}) =>
                              setExpanded(expanded: expanded, index: 2),
                        ),
                );
              }),
          // Padding(
          //   padding: const EdgeInsets.only(bottom: Constants.padding),
          //   child: (null != routineProvider.curAfternoon)
          //       ? Tiles.filledRoutineTile(
          //           context: context,
          //           onSubtaskRemove:
          //               (routineProvider.userViewModel?.reduceMotion ?? false)
          //                   ? null
          //                   : onRemove,
          //           routine: routineProvider.curAfternoon!,
          //           times: 2)
          //       : Tiles.emptyRoutineTile(context: context, times: 2),
          // ),
          // Padding(
          //   padding: const EdgeInsets.only(bottom: Constants.padding),
          //   child: (null != routineProvider.curEvening)
          //       ? Tiles.filledRoutineTile(
          //           context: context,
          //           onSubtaskRemove:
          //               (routineProvider.userViewModel?.reduceMotion ?? false)
          //                   ? null
          //                   : onRemove,
          //           routine: routineProvider.curEvening!,
          //           times: 4)
          //       : Tiles.emptyRoutineTile(context: context, times: 4),
          // ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 200),
            child: SizedBox.shrink(),
          ),
        ]);
  }
}
