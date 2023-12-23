import 'package:another_flushbar/flushbar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../model/task/routine.dart';
import '../../../providers/routine_provider.dart';
import '../../../providers/subtask_provider.dart';
import '../../../providers/user_provider.dart';
import '../../../util/exceptions.dart';
import '../../widgets/flushbars.dart';
import '../../widgets/tiles.dart';

class MyDayRoutines extends StatefulWidget {
  const MyDayRoutines({Key? key}) : super(key: key);

  @override
  State<MyDayRoutines> createState() => _MyDayRoutines();
}

class _MyDayRoutines extends State<MyDayRoutines> {
  late RoutineProvider routineProvider;
  late UserProvider userProvider;
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
    userProvider = Provider.of<UserProvider>(context, listen: false);
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

    routine.subtasks = await routineProvider.getSubtasks(id: routine.id);
    routineProvider.setSubtaskCount(
        id: routine.id, count: routine.subtasks.length);
    routine.weight = await routineProvider.getWeight(taskID: routine.id);
    routine.realDuration = routineProvider.calculateRealDuration(
        weight: routine.weight, duration: routine.expectedDuration);
    return await routineProvider.updateRoutine(routine: routine).catchError(
        (e) {
      Flushbar? error;
      error = Flushbars.createError(
        context: context,
        message: e.cause,
        dismissCallback: () => error?.dismiss(),
      );
      error.show(context);
    },
        test: (e) =>
            e is FailureToUpdateException || e is FailureToUploadException);
  }

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
            Consumer<RoutineProvider>(
              builder:
                  (BuildContext context, RoutineProvider value, Widget? child) {
                if (null != value.curMorning) {
                  return Tiles.filledRoutineTile(
                      context: context, routine: value.curMorning!, times: 1);
                }
                return Tiles.emptyRoutineTile(context: context, times: 1);
              },
            ),
            Consumer<RoutineProvider>(
              builder:
                  (BuildContext context, RoutineProvider value, Widget? child) {
                if (null != value.curAfternoon) {
                  return Tiles.filledRoutineTile(
                      context: context, routine: value.curAfternoon!, times: 2);
                }
                return Tiles.emptyRoutineTile(context: context, times: 2);
              },
            ),
            Consumer<RoutineProvider>(
              builder:
                  (BuildContext context, RoutineProvider value, Widget? child) {
                if (null != value.curEvening) {
                  return Tiles.filledRoutineTile(
                      context: context, routine: value.curEvening!, times: 4);
                }
                return Tiles.emptyRoutineTile(context: context, times: 4);
              },
            ),
          ]),
    );
  }
}
