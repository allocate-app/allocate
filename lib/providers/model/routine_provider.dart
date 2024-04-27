import 'dart:async';
import 'dart:developer';

import 'package:flutter/foundation.dart';

import '../../model/task/routine.dart';
import '../../model/task/subtask.dart';
import '../../repositories/routine_repo.dart';
import '../../repositories/subtask_repo.dart';
import '../../util/constants.dart';
import '../../util/enums.dart';
import '../../util/exceptions.dart';
import '../../util/interfaces/repository/model/routine_repository.dart';
import '../../util/interfaces/repository/model/subtask_repository.dart';
import '../../util/numbers.dart';
import '../../util/sorting/routine_sorter.dart';
import '../viewmodels/user_viewmodel.dart';

class RoutineProvider extends ChangeNotifier {
  bool _rebuild = true;

  bool get rebuild => _rebuild;

  set rebuild(bool rebuild) {
    _rebuild = rebuild;
    if (_rebuild) {
      routines = [];
      notifyListeners();
    }
  }

  set softRebuild(bool rebuild) {
    _rebuild = rebuild;

    if (_rebuild) {
      routines = [];
    }
  }

  late final RoutineRepository _routineRepo;
  late final SubtaskRepository _subtaskRepo;

  UserViewModel? userViewModel;
  Routine? curRoutine;

  Routine? _curMorning;
  Routine? _curAfternoon;
  Routine? _curEvening;

  final Map<int, ValueNotifier<int>> routineSubtaskCounts = {};

  // CONSTRUCTOR
  RoutineProvider({
    this.userViewModel,
    RoutineRepository? routineRepository,
    SubtaskRepository? subtaskRepository,
  })  : sorter = userViewModel?.routineSorter ?? RoutineSorter(),
        _routineRepo = routineRepository ?? RoutineRepo.instance,
        _subtaskRepo = subtaskRepository ?? SubtaskRepo.instance {
    _routineRepo.addListener(notifyListeners);
  }

  Future<void> init() async {
    await _routineRepo.init();
    await setDailyRoutines();
    notifyListeners();
  }

  Routine? get curMorning => _curMorning;

  Routine? get curAfternoon => _curAfternoon;

  Routine? get curEvening => _curEvening;

  set curMorning(Routine? newRoutine) {
    if (newRoutine != _curMorning) {
      resetRoutineSubtasks(routine: _curMorning);
    }
    _curMorning = newRoutine;
    userViewModel?.curMornID = newRoutine?.id;
    // resetRoutineSubtasks(routine: _curMorning);
    notifyListeners();
  }

  set curAfternoon(Routine? newRoutine) {
    if (newRoutine != _curAfternoon) {
      resetRoutineSubtasks(routine: _curAfternoon);
    }
    _curAfternoon = newRoutine;
    userViewModel?.curAftID = newRoutine?.id;
    // resetRoutineSubtasks(routine: _curAfternoon);
    notifyListeners();
  }

  set curEvening(Routine? newRoutine) {
    if (newRoutine != _curEvening) {
      resetRoutineSubtasks(routine: _curEvening);
    }
    _curEvening = newRoutine;
    userViewModel?.curEveID = newRoutine?.id;
    // resetRoutineSubtasks(routine: _curEvening);
    notifyListeners();
  }

  void clearRoutines() {
    curMorning = null;
    curAfternoon = null;
    curEvening = null;
  }

  void setDailyRoutine({required int timeOfDay, Routine? routine}) {
    if (null == routine) {
      return;
    }
    if (timeOfDay & 1 == 1) {
      curMorning = routine;
    }
    if (timeOfDay & 2 == 2) {
      curAfternoon = routine;
    }
    if (timeOfDay & 4 == 4) {
      curEvening = routine;
    }
    if (timeOfDay == 0) {
      unsetDailyRoutine(id: routine.id);
    }
    notifyListeners();
  }

  void unsetDailyRoutine({required int id}) {
    if (id == curMorning?.id) {
      curMorning = null;
    }
    if (id == curAfternoon?.id) {
      curAfternoon = null;
    }
    if (id == curEvening?.id) {
      curEvening = null;
    }
  }

  // This is due to shared references.
  int get routineWeight {
    int totalWeight = 0;
    if (null != curMorning) {
      totalWeight += curMorning!.weight;
    }
    if (null != curAfternoon && curMorning != curAfternoon) {
      totalWeight += curAfternoon!.weight;
    }
    if (null != curEvening &&
        curMorning != curEvening &&
        curAfternoon != curEvening) {
      totalWeight += curEvening!.weight;
    }

    return totalWeight;
  }

  List<Routine> routines = [];

  late RoutineSorter sorter;

  void setUser({UserViewModel? newUser}) {
    userViewModel = newUser;
    if (userViewModel?.routineSorter == sorter &&
        sameRoutines(newUser: newUser)) {
      return;
    }
    sorter = userViewModel?.routineSorter ?? sorter;
    setDailyRoutines();
  }

  bool sameRoutines({UserViewModel? newUser}) {
    return newUser?.curMornID == curMorning?.id &&
        newUser?.curAftID == curAfternoon?.id &&
        newUser?.curEveID == curEvening?.id;
  }

  int getRoutineTime({Routine? routine}) {
    int times = 0;
    if (_curMorning == routine) {
      times |= 1;
    }
    if (_curAfternoon == routine) {
      times |= 2;
    }
    if (_curEvening == routine) {
      times |= 4;
    }
    return times;
  }

  Future<void> setDailyRoutines() async {
    _curMorning = (null != userViewModel?.curMornID)
        ? await _routineRepo.getByID(id: userViewModel!.curMornID!)
        : null;

    _curAfternoon = (null != userViewModel?.curAftID)
        ? await _routineRepo.getByID(id: userViewModel!.curAftID!)
        : null;

    _curEvening = (null != userViewModel?.curEveID)
        ? await _routineRepo.getByID(id: userViewModel!.curEveID!)
        : null;
    notifyListeners();
  }

  SortMethod get sortMethod => sorter.sortMethod;

  set sortMethod(SortMethod method) {
    if (method == sorter.sortMethod) {
      sorter.descending = !sorter.descending;
    } else {
      sorter.sortMethod = method;
      sorter.descending = false;
    }
    userViewModel?.routineSorter = sorter;
    notifyListeners();
  }

  bool get descending => sorter.descending;

  List<SortMethod> get sortMethods => sorter.sortMethods;

  int calculateRealDuration({int? weight, int? duration}) => (remap(
              x: weight ?? 0,
              inMin: 0,
              inMax: Constants.maxWeight,
              outMin: Constants.lowerBound,
              outMax: Constants.upperBound) *
          (duration ?? 0))
      .toInt();

  Future<int> getWeight(
          {required int taskID, int limit = Constants.maxNumTasks}) async =>
      await _subtaskRepo.getTaskSubtaskWeight(taskID: taskID, limit: limit);

  ValueNotifier<int> getSubtaskCount(
      {required int id, int limit = Constants.maxNumTasks}) {
    if (routineSubtaskCounts.containsKey(id)) {
      return routineSubtaskCounts[id]!;
    }

    routineSubtaskCounts[id] = ValueNotifier<int>(0);
    setSubtaskCount(id: id, limit: limit);
    return routineSubtaskCounts[id]!;
  }

  Future<void> setSubtaskCount(
      {required int id, int limit = Constants.maxNumTasks, int? count}) async {
    count = count ??
        await _subtaskRepo.getTaskSubtasksCount(taskID: id, limit: limit);
    if (routineSubtaskCounts.containsKey(id)) {
      routineSubtaskCounts[id]?.value = count;
    } else {
      routineSubtaskCounts[id] = ValueNotifier<int>(count);
    }
  }

  Future<void> refreshRepo() async {
    try {
      await _routineRepo.refreshRepo();
      notifyListeners();
    } on FailureToDeleteException catch (e, stacktrace) {
      log(e.cause, stackTrace: stacktrace);
      notifyListeners();
      return Future.error(e, stacktrace);
    } on FailureToUploadException catch (e, stacktrace) {
      log(e.cause, stackTrace: stacktrace);
      notifyListeners();
      return Future.error(e, stacktrace);
    } on Error catch (e, stacktrace) {
      log("Unknown error", stackTrace: stacktrace);
      notifyListeners();
      return Future.error(UnexpectedErrorException(), stacktrace);
    }
  }

  Future<void> syncRepo() async {
    try {
      await _routineRepo.syncRepo();
      notifyListeners();
    } on FailureToDeleteException catch (e, stacktrace) {
      log(e.cause, stackTrace: stacktrace);
      notifyListeners();
      return Future.error(e, stacktrace);
    } on FailureToUploadException catch (e, stacktrace) {
      log(e.cause, stackTrace: stacktrace);
      notifyListeners();
      return Future.error(e, stacktrace);
    } on Error catch (e, stacktrace) {
      log("Unknown error", stackTrace: stacktrace);
      notifyListeners();
      return Future.error(UnexpectedErrorException(), stacktrace);
    }
  }

  Future<void> createRoutine(Routine routine, int times) async {
    try {
      // Check for db collisions.
      bool inDB = await _routineRepo.containsID(id: routine.id);

      while (inDB) {
        routine.id = routine.id + 1;
        inDB = await _routineRepo.containsID(id: routine.id);
      }

      curRoutine = await _routineRepo.create(routine);
      setDailyRoutine(timeOfDay: times, routine: curRoutine);
      notifyListeners();
    } on FailureToCreateException catch (e, stacktrace) {
      log(e.cause, stackTrace: stacktrace);
      notifyListeners();
      return Future.error(e, stacktrace);
    } on FailureToUploadException catch (e, stacktrace) {
      log(e.cause, stackTrace: stacktrace);
      routine.isSynced = false;
      notifyListeners();
      return updateRoutine(routine: routine, times: times);
    } on Error catch (e, stacktrace) {
      log("Unknown error", stackTrace: stacktrace);
      notifyListeners();
      return Future.error(UnexpectedErrorException(), stacktrace);
    }
  }

  Future<void> updateRoutine({Routine? routine, int? times}) async {
    await updateRoutineAsync(routine: routine);
    if (null != times) {
      unsetDailyRoutine(id: routine!.id);
      setDailyRoutine(timeOfDay: times, routine: routine);
    }
    notifyListeners();
  }

  Future<void> updateRoutineAsync({Routine? routine}) async {
    routine = routine ?? curRoutine;

    if (null == routine) {
      throw FailureToUpdateException("Invalid model provided");
    }

    try {
      curRoutine = await _routineRepo.update(routine);
    } on FailureToUploadException catch (e, stacktrace) {
      log(e.cause, stackTrace: stacktrace);
      notifyListeners();
      return Future.error(e, stacktrace);
    } on FailureToUpdateException catch (e, stacktrace) {
      log(e.cause, stackTrace: stacktrace);
      notifyListeners();
      return Future.error(e, stacktrace);
    } on Error catch (e, stacktrace) {
      log("Unknown error", stackTrace: stacktrace);
      notifyListeners();
      return Future.error(UnexpectedErrorException(), stacktrace);
    }
  }

  Future<void> updateBatch({List<Routine>? routines}) async {
    routines = routines ?? this.routines;
    for (Routine routine in routines) {
      routine.lastUpdated = DateTime.now();
    }
    try {
      await _routineRepo.updateBatch(routines);
      notifyListeners();
    } on FailureToUploadException catch (e, stacktrace) {
      log(e.cause, stackTrace: stacktrace);
      notifyListeners();
      return Future.error(e, stacktrace);
    } on FailureToUpdateException catch (e, stacktrace) {
      log(e.cause, stackTrace: stacktrace);
      notifyListeners();
      return Future.error(e, stacktrace);
    } on Error catch (e, stacktrace) {
      log("Unknown error", stackTrace: stacktrace);
      notifyListeners();
      return Future.error(UnexpectedErrorException(), stacktrace);
    }
  }

  // Future<void> _updateSubtasks(
  //     {required List<Subtask> subtasks, required int taskID}) async {
  //   int i = 0;
  //
  //   // This eliminates empty subtasks.
  //   for (Subtask st in subtasks) {
  //     if (st.name != "") {
  //       st.taskID = taskID;
  //       st.customViewIndex = i++;
  //       st.lastUpdated = DateTime.now();
  //     } else {
  //       st.toDelete = true;
  //     }
  //   }
  //   try {
  //     await _subtaskRepo.updateBatch(subtasks);
  //   } on FailureToUploadException catch (e, stacktrace) {
  //     log(e.cause, stackTrace: stacktrace);
  //     return Future.error(e, stacktrace);
  //   } on FailureToUpdateException catch (e, stacktrace) {
  //     log(e.cause, stackTrace: stacktrace);
  //     return Future.error(e, stacktrace);
  //   } on Error catch (e, stacktrace) {
  //     log("Unknown error", stackTrace: stacktrace);
  //     return Future.error(UnexpectedErrorException(), stacktrace);
  //   }
  // }

  Future<void> deleteRoutine({Routine? routine}) async {
    if (null == routine) {
      return;
    }
    try {
      await _routineRepo.delete(routine);
      notifyListeners();
    } on FailureToDeleteException catch (e, stacktrace) {
      log(e.cause, stackTrace: stacktrace);
      notifyListeners();
      return Future.error(e, stacktrace);
    } on Error catch (e, stacktrace) {
      log("Unknown error", stackTrace: stacktrace);
      notifyListeners();
      return Future.error(UnexpectedErrorException(), stacktrace);
    }
  }

  Future<void> removeRoutine({Routine? routine}) async {
    if (null == routine) {
      return;
    }
    try {
      await _routineRepo.remove(routine);
      notifyListeners();
    } on FailureToDeleteException catch (e, stacktrace) {
      log(e.cause, stackTrace: stacktrace);
      notifyListeners();
      return Future.error(e, stacktrace);
    } on Error catch (e, stacktrace) {
      log("Unknown error", stackTrace: stacktrace);
      notifyListeners();
      return Future.error(UnexpectedErrorException(), stacktrace);
    }
  }

  Future<void> restoreRoutine({Routine? routine}) async {
    if (null == routine) {
      return;
    }
    routine.toDelete = false;
    try {
      curRoutine = await _routineRepo.update(routine);
      notifyListeners();
    } on FailureToUploadException catch (e, stacktrace) {
      log(e.cause, stackTrace: stacktrace);
      notifyListeners();
      return Future.error(e, stacktrace);
    } on FailureToUpdateException catch (e, stacktrace) {
      log(e.cause, stackTrace: stacktrace);
      notifyListeners();
      return Future.error(e, stacktrace);
    } on Error catch (e, stacktrace) {
      log("Unknown error", stackTrace: stacktrace);
      notifyListeners();
      return Future.error(UnexpectedErrorException(), stacktrace);
    }
  }

  Future<void> emptyTrash() async {
    try {
      List<int> ids = await _routineRepo.emptyTrash();
      for (int id in ids) {
        List<Subtask> subtasks = await _subtaskRepo.getRepoByTaskID(id: id);
        for (Subtask subtask in subtasks) {
          subtask.toDelete = true;
        }
        await _subtaskRepo.updateBatch(subtasks);
        routineSubtaskCounts.remove(id);
      }
      notifyListeners();
    } on FailureToDeleteException catch (e, stacktrace) {
      log(e.cause, stackTrace: stacktrace);
      notifyListeners();
      return Future.error(e, stacktrace);
    } on Error catch (e, stacktrace) {
      log("Unknown error", stackTrace: stacktrace);
      notifyListeners();
      return Future.error(UnexpectedErrorException(), stacktrace);
    }
  }

  Future<void> dayReset() async {
    DateTime? upTo = userViewModel?.deleteDate;
    if (null != upTo) {
      try {
        await _routineRepo.deleteSweep(upTo: upTo);
      } on FailureToDeleteException catch (e, stacktrace) {
        log(e.cause, stackTrace: stacktrace);
        return Future.error(e, stacktrace);
      } on Error catch (e, stacktrace) {
        log("Unknown error", stackTrace: stacktrace);
        return Future.error(UnexpectedErrorException(), stacktrace);
      }
    }
    await resetDailyRoutines();
  }

  Future<void> clearDatabase() async {
    curRoutine = null;
    routines = [];
    _rebuild = true;
    routineSubtaskCounts.clear();
    _curMorning = null;
    _curAfternoon = null;
    _curEvening = null;
    await _routineRepo.clearDB();
  }

  Future<List<Routine>> reorderRoutines(
      {List<Routine>? routines,
      required int oldIndex,
      required int newIndex}) async {
    routines = routines ?? this.routines;
    if (oldIndex < newIndex) {
      newIndex--;
    }
    Routine routine = routines.removeAt(oldIndex);
    routines.insert(newIndex, routine);
    for (int i = 0; i < routines.length; i++) {
      routines[i].customViewIndex = i;
    }
    try {
      await _routineRepo.updateBatch(routines);
      return routines;
    } on FailureToUpdateException catch (e, stacktrace) {
      log(e.cause, stackTrace: stacktrace);
      return Future.error(e, stacktrace);
    } on FailureToUploadException catch (e, stacktrace) {
      log(e.cause, stackTrace: stacktrace);
      return Future.error(e, stacktrace);
    } on Error catch (e, stacktrace) {
      log("Unknown error", stackTrace: stacktrace);
      return Future.error(UnexpectedErrorException(), stacktrace);
    }
  }

  Future<void> resetRoutineSubtasks({Routine? routine}) async {
    if (null == routine) {
      return;
    }
    List<Subtask> subtasks = (routine.subtasks.isNotEmpty)
        ? routine.subtasks
        : await _subtaskRepo.getRepoByTaskID(id: routine.id);
    for (Subtask subtask in subtasks) {
      subtask.completed = false;
    }
    try {
      await _subtaskRepo.updateBatch(subtasks);
    } on FailureToUpdateException catch (e, stacktrace) {
      log(e.cause, stackTrace: stacktrace);
      return Future.error(e, stacktrace);
    } on FailureToUploadException catch (e, stacktrace) {
      log(e.cause, stackTrace: stacktrace);
      return Future.error(e, stacktrace);
    } on Error catch (e, stacktrace) {
      log("Unknown error", stackTrace: stacktrace);
      return Future.error(UnexpectedErrorException(), stacktrace);
    }
  }

  // This is to be called once per day after midnight;
  Future<void> resetDailyRoutines() async {
    if (null != curMorning) {
      resetRoutineSubtasks(routine: curMorning);
    }
    if (null != curAfternoon && curMorning != curAfternoon) {
      resetRoutineSubtasks(routine: curAfternoon);
    }
    if (null != curEvening &&
        curMorning != curEvening &&
        curAfternoon != curEvening) {
      resetRoutineSubtasks(routine: curEvening);
    }
    notifyListeners();
  }

  Future<List<Routine>> getRoutines({int limit = 50, int offset = 0}) async =>
      await _routineRepo.getRepoList(limit: limit, offset: offset);

  Future<List<Subtask>> getSubtasks({
    required int id,
    int limit = Constants.maxNumTasks,
  }) async =>
      await _subtaskRepo.getRepoByTaskID(id: id, limit: limit);

  // Future<void> setRoutineList({int limit = 50, int offset = 0}) async =>
  //     await _routineRepo.getRepoList(limit: limit, offset: offset);

  Future<List<Routine>> getRoutinesBy({int limit = 50, int offset = 0}) async =>
      await _routineRepo.getRepoListBy(
          sorter: sorter, limit: limit, offset: offset);

  Future<List<Routine>> getDeleted(
          {int limit = Constants.minLimitPerQuery, int offset = 0}) async =>
      await _routineRepo.getDeleted(limit: limit, offset: offset);

  // Future<void> setRoutineListBy({int limit = 50, int offset = 0}) async =>
  //     await _routineRepo.getRepoListBy(
  //         sorter: sorter, limit: limit, offset: offset);

  Future<List<Routine>> searchRoutines(
          {required String searchString, bool toDelete = false}) async =>
      await _routineRepo.search(searchString: searchString, toDelete: toDelete);

  Future<List<Routine>> mostRecent({int limit = 5}) async =>
      await _routineRepo.mostRecent(limit: 5);

  Future<Routine?> getRoutineByID({int? id}) async {
    if (null == id) {
      return null;
    }
    return await _routineRepo.getByID(id: id);
  }

// Future<void> setRoutineByID({required int id}) async =>
//     curRoutine = await _routineRepo.getByID(id: id) ??
//         Routine(
//             name: '',
//             expectedDuration: 0,
//             realDuration: 0,
//             subtasks: List.filled(
//                 Constants.maxNumTasks, Subtask(lastUpdated: DateTime.now())),
//             lastUpdated: DateTime.now());
}
