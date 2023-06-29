import "package:isar/isar.dart";

import "../model/task/routine.dart";
import "../model/task/todo.dart";

/// Singleton helper class for interfacing with Isar.
/// Needs the schema to be generated.

class IsarService {
  static final IsarService _instance = IsarService._internal();
  static IsarService get instance => _instance;

  static late final Isar _isarClient;
  static Isar get isarClient => _isarClient;

  // This needs directory to be set
  // Add tables to this as necessary.
  Future<void> init() async => _isarClient = await Isar.open(
      [ToDoSchema, RoutineSchema, ReminderSchema, UserSchema, DeadLineSchema]);


  IsarService._internal();
}
