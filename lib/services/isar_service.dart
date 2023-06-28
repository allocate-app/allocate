import "package:isar/isar.dart";

import "../model/task/routine.dart";
import "../model/task/todo.dart";

/// Singleton helper class for interfacing with Isar.
/// Needs the schema to be generated.

class IsarService {
  static final IsarService _instance = IsarService._internal();
  static IsarService get instance => _instance;

  late Isar isarInstance;

  // This needs directory to be set
  // Add tables to this as necessary.
  init() async => isarInstance = await Isar.open(
      [ToDoSchema, RoutineSchema, ReminderSchema, UserSchema, DeadLineSchema]);

  Future<int?> insertOneRoutine(Routine routine) async {
    late int? id;
    await isarInstance.writeTxn(() async {
      id = await isarInstance.routines.put(routine);
    });
    return id;
  }

  Future<List<int?>> insertFreshRoutines(List<Routine> routines) async {
    List<int?> ids = List.empty(growable: true);
    late int? id;
    await isarInstance.writeTxn(() async {
      for (Routine routine in routines) {
        id = await isarInstance.routines.put(routine);
        ids.add(id);
      }
    });
    return ids;
  }

  Future<List<Routine>> getRoutines() async {
    //TODO: implement.
    List<Routine> routines = List.empty(growable: true);
    return routines;
  }

  IsarService._internal();
}
