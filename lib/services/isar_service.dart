import "dart:async";
import "dart:io";

import "package:flutter/foundation.dart";
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

  late bool _initialized = false;

  late Isar _isarClient;

  Isar get isarClient => _isarClient;

  // TODO: hook GUI thing in settings screen to look here.
  // Use the userProvider timer to periodically check this value.
  // Display a toast or something.
  ValueNotifier<int> dbSize = ValueNotifier(0);

  // TODO: get a size in MiB here -> Add listeners to repositories
  // Request Isar service update its own total.

  Future<void> init({bool? debug}) async {
    if (_initialized) {
      return;
    }
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
    _initialized = true;
    await updateDBSize();
  }

  Future<void> dispose() async {
    await _isarClient.close(deleteFromDisk: _debug);
  }

  Future<void> updateDBSize() async {
    dbSize.value = await _isarClient.getSize();
  }

  IsarService._internal();
}
