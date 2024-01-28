import "dart:async";
import "dart:io";

import "package:isar/isar.dart";
import "package:path_provider/path_provider.dart";

import "../model/task/deadline.dart";
import "../model/task/group.dart";
import "../model/task/reminder.dart";
import "../model/task/routine.dart";
import "../model/task/subtask.dart";
import "../model/task/todo.dart";
import "../model/user/allocate_user.dart";

/// Singleton helper class for interfacing with Isar.
/// Needs the schema to be generated.

class IsarService {
  static final IsarService _instance = IsarService._internal();

  static IsarService get instance => _instance;

  bool _debug = false;

  late Isar _isarClient;

  Isar get isarClient => _isarClient;

  Future<void> init({bool? debug}) async {
    _debug = debug ?? _debug;
    if (_debug) {
      await Isar.initializeIsarCore(download: true);
    }

    final Directory dbStorageDir = await getApplicationDocumentsDirectory();
    _isarClient = await Isar.open([
      ToDoSchema,
      RoutineSchema,
      ReminderSchema,
      GroupSchema,
      SubtaskSchema,
      AllocateUserSchema,
      DeadlineSchema
    ], directory: dbStorageDir.path);
  }

  Future<void> dispose() async {
    await _isarClient.close(deleteFromDisk: _debug);
  }

  IsarService._internal();
}
