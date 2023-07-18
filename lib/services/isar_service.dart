import "dart:io";

import "package:isar/isar.dart";
import "package:path_provider/path_provider.dart";

import "../model/task/deadline.dart";
import "../model/task/group.dart";
import "../model/task/reminder.dart";
import "../model/task/routine.dart";
import "../model/task/todo.dart";
import "../model/user/user.dart";

/// Singleton helper class for interfacing with Isar.
/// Needs the schema to be generated.
///

class IsarService {
  static final IsarService _instance = IsarService._internal();
  static IsarService get instance => _instance;

  static late final Isar _isarClient;
  static Isar get isarClient => _isarClient;

  // This needs directory to be set
  // Add tables to this as necessary.
  Future<void> init() async {
    final Directory dbStorageDir = await getApplicationSupportDirectory();
    _isarClient = await Isar.open([
      ToDoSchema,
      RoutineSchema,
      ReminderSchema,
      GroupSchema,
      UserSchema,
      DeadlineSchema
    ], directory: dbStorageDir.path);
  }

  IsarService._internal();
}
