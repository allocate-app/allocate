import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../model/task/routine.dart';
import '../../../model/task/subtask.dart';
import '../../../providers/model/routine_provider.dart';
import '../../../providers/model/subtask_provider.dart';
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

  late ScrollController mainScrollController;
  late ScrollPhysics scrollPhysics;

  @override
  void initState() {
    initializeProviders();
    initializeControllers();
    resetRoutines();
    super.initState();
  }

  void initializeProviders() {
    routineProvider = Provider.of<RoutineProvider>(context, listen: false);
    subtaskProvider = Provider.of<SubtaskProvider>(context, listen: false);
    routineProvider.addListener(resetRoutines);
    subtaskProvider.addListener(resetRoutines);
  }

  void initializeControllers() {
    mainScrollController = ScrollController();
    scrollPhysics = const ScrollPhysics();
  }

  @override
  void dispose() {
    mainScrollController.dispose();
    routineProvider.removeListener(resetRoutines);
    subtaskProvider.removeListener(resetRoutines);
    super.dispose();
  }

  Future<void> resetRoutines() async {
    await resetSubtasks(routine: routineProvider.curMorning);
    if (routineProvider.curMorning == routineProvider.curAfternoon) {
      routineProvider.curAfternoon?.subtasks =
          routineProvider.curMorning?.subtasks ?? [];
    } else {
      await resetSubtasks(routine: routineProvider.curAfternoon);
    }

    if (routineProvider.curMorning == routineProvider.curEvening) {
      routineProvider.curEvening?.subtasks =
          routineProvider.curMorning?.subtasks ?? [];
    } else if (routineProvider.curAfternoon == routineProvider.curEvening) {
      routineProvider.curEvening?.subtasks =
          routineProvider.curAfternoon?.subtasks ?? [];
    } else {
      await resetSubtasks(routine: routineProvider.curEvening);
    }
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> resetSubtasks({Routine? routine}) async {
    if (null == routine) {
      return;
    }

    List<Subtask> newSubtasks =
        await routineProvider.getSubtasks(id: routine.id);

    if (!(routineProvider.userViewModel?.reduceMotion ?? false)) {
      onFetch(items: newSubtasks, itemSet: routine.subtasks.toSet());
    }

    routine.subtasks = newSubtasks;

    routineProvider.setSubtaskCount(
        id: routine.id, count: routine.subtasks.length);
    routine.weight = await routineProvider.getWeight(taskID: routine.id);
    routine.realDuration = routineProvider.calculateRealDuration(
        weight: routine.weight, duration: routine.expectedDuration);
    return await routineProvider
        .updateRoutine(routine: routine)
        .catchError((e) => Tiles.displayError(e: e));
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

  // These don't need to be consumed.
  @override
  Widget build(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      buildRoutineCards(),
    ]);
  }

  Widget buildRoutineCards() {
    return Expanded(
      child: ListView(
          controller: mainScrollController,
          physics: scrollPhysics,
          shrinkWrap: true,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: Constants.padding),
              child: (null != routineProvider.curMorning)
                  ? Tiles.filledRoutineTile(
                      context: context,
                      onSubtaskRemove:
                          (routineProvider.userViewModel?.reduceMotion ?? false)
                              ? null
                              : onRemove,
                      routine: routineProvider.curMorning!,
                      times: 1)
                  : Tiles.emptyRoutineTile(context: context, times: 1),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: Constants.padding),
              child: (null != routineProvider.curAfternoon)
                  ? Tiles.filledRoutineTile(
                      context: context,
                      onSubtaskRemove:
                          (routineProvider.userViewModel?.reduceMotion ?? false)
                              ? null
                              : onRemove,
                      routine: routineProvider.curAfternoon!,
                      times: 2)
                  : Tiles.emptyRoutineTile(context: context, times: 2),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: Constants.padding),
              child: (null != routineProvider.curEvening)
                  ? Tiles.filledRoutineTile(
                      context: context,
                      onSubtaskRemove:
                          (routineProvider.userViewModel?.reduceMotion ?? false)
                              ? null
                              : onRemove,
                      routine: routineProvider.curEvening!,
                      times: 4)
                  : Tiles.emptyRoutineTile(context: context, times: 4),
            ),
          ]),
    );
  }
}
