import 'dart:ui';

import 'package:flutter/services.dart';
import "package:flutter_test/flutter_test.dart";
import 'package:isar/isar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../model/task/todo.dart';
import '../providers/model/todo_provider.dart';
import '../providers/viewmodels/user_viewmodel.dart';
import '../repositories/todo_repo.dart';
import '../services/isar_service.dart';
import '../services/supabase_service.dart';
import '../util/constants.dart';
import '../util/enums.dart';
import '../util/interfaces/repository/model/todo_repository.dart';

final IsarService isarService = IsarService.instance;
Isar? client;
final SupabaseService supabaseService = SupabaseService.instance;
SupabaseClient? supabaseClient;
ToDoRepository? toDoRepo;
ToDoProvider? toDoProvider;

void main() async {
  DartPluginRegistrant.ensureInitialized();
  RootIsolateToken rootIsolateToken = RootIsolateToken.instance!;
  BackgroundIsolateBinaryMessenger.ensureInitialized(rootIsolateToken);
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(initIsar);
  setUp(clearIsar);
  tearDownAll(disposeIsar);
  group(
      "Delete sweep test, 3 ToDos in db, 1 year ago, 30 days ago, 15 days ago",
      () {
    // These have an offset of 1 day to accommodate for the "day reset"
    ToDo toDo1 = ToDo(
      id: Constants.generateID(),
      taskType: TaskType.small,
      name: 'toDo1',
      expectedDuration: 0,
      weight: 10,
      realDuration: 0,
      toDelete: true,
      repeatDays: List.generate(7, (i) => false),
      lastUpdated:
          Constants.today.copyWith(day: Constants.today.day - (15 + 1)),
    );

    ToDo toDo2 = ToDo(
      id: Constants.generateID(),
      taskType: TaskType.small,
      name: "toDo2",
      expectedDuration: 0,
      weight: 5,
      realDuration: 0,
      toDelete: true,
      repeatDays: List.generate(7, (i) => false),
      lastUpdated:
          Constants.today.copyWith(day: Constants.today.day - (30 + 1)),
    );
    ToDo toDo3 = ToDo(
      id: Constants.generateID(),
      taskType: TaskType.small,
      name: "toDo3",
      expectedDuration: 0,
      weight: 5,
      realDuration: 0,
      toDelete: true,
      repeatDays: List.generate(7, (i) => false),
      lastUpdated: Constants.today.copyWith(
          year: Constants.today.year - 1, day: Constants.today.day - 1),
    );
    test("forever, expect 3 left", () async {
      expect(null != toDoRepo, true, reason: "repo null");
      expect(null != toDoProvider, true, reason: "provider null");

      UserViewModel viewModel = UserViewModel();
      viewModel.deleteSchedule = DeleteSchedule.never;
      toDoProvider!.userViewModel = viewModel;

      ToDo t1 = toDo1.copyWith(
          toDelete: toDo1.toDelete, lastUpdated: toDo1.lastUpdated);
      ToDo t2 = toDo2.copyWith(
          toDelete: toDo2.toDelete, lastUpdated: toDo2.lastUpdated);
      ToDo t3 = toDo3.copyWith(
          toDelete: toDo3.toDelete, lastUpdated: toDo3.lastUpdated);
      await toDoRepo!.updateBatch([t1, t2, t3]);

      List<ToDo> toDos = await toDoRepo!.getDeleted();

      expect(toDos.length, 3, reason: "Deleted query failure: ${toDos.length}");

      await toDoProvider!.dayReset();
      toDos = await toDoRepo!.getDeleted();

      DateTime? deleteDate = toDoProvider!.userViewModel?.deleteDate;
      expect(null == deleteDate, true,
          reason:
              "Delete schedule error: -> ${toDoProvider!.userViewModel?.deleteSchedule}");

      expect(toDos.length, 3,
          reason:
              "Delete schedule not respected: todos -> ${toDos.length}, vm -> ${toDoProvider!.userViewModel?.deleteSchedule}");
    });
    test("1 year, expect 2 left", () async {
      expect(null != toDoRepo, true, reason: "repo null");
      expect(null != toDoProvider, true, reason: "provider null");

      UserViewModel viewModel = UserViewModel();
      viewModel.deleteSchedule = DeleteSchedule.oneYear;
      toDoProvider!.userViewModel = viewModel;

      ToDo t1 = toDo1.copyWith(
          toDelete: toDo1.toDelete, lastUpdated: toDo1.lastUpdated);
      ToDo t2 = toDo2.copyWith(
          toDelete: toDo2.toDelete, lastUpdated: toDo2.lastUpdated);
      ToDo t3 = toDo3.copyWith(
          toDelete: toDo3.toDelete, lastUpdated: toDo3.lastUpdated);
      await toDoRepo!.updateBatch([t1, t2, t3]);

      List<ToDo> toDos = await toDoRepo!.getDeleted();

      expect(toDos.length, 3, reason: "Deleted query failure: ${toDos.length}");

      await toDoProvider!.dayReset();
      toDos = await toDoRepo!.getDeleted();

      DateTime? deleteDate = toDoProvider!.userViewModel?.deleteDate;
      expect(
          Constants.today.copyWith(
                  year: Constants.today.year - 1, day: Constants.today.day) ==
              deleteDate,
          true,
          reason:
              "Delete schedule error: -> ${toDoProvider!.userViewModel?.deleteSchedule}\n"
              "DeleteDate: -> $deleteDate");

      expect(toDos.length, 2,
          reason:
              "Delete schedule not respected: todos -> ${toDos.length}, vm -> ${toDoProvider!.userViewModel?.deleteSchedule}");
    });
    test("30 days ago, expect 1 left", () async {
      expect(null != toDoRepo, true, reason: "repo null");
      expect(null != toDoProvider, true, reason: "provider null");

      UserViewModel viewModel = UserViewModel();
      viewModel.deleteSchedule = DeleteSchedule.thirtyDays;
      toDoProvider!.userViewModel = viewModel;

      ToDo t1 = toDo1.copyWith(
          toDelete: toDo1.toDelete, lastUpdated: toDo1.lastUpdated);
      ToDo t2 = toDo2.copyWith(
          toDelete: toDo2.toDelete, lastUpdated: toDo2.lastUpdated);
      ToDo t3 = toDo3.copyWith(
          toDelete: toDo3.toDelete, lastUpdated: toDo3.lastUpdated);
      await toDoRepo!.updateBatch([t1, t2, t3]);

      List<ToDo> toDos = await toDoRepo!.getDeleted();

      expect(toDos.length, 3, reason: "Deleted query failure: ${toDos.length}");

      await toDoProvider!.dayReset();
      toDos = await toDoRepo!.getDeleted();

      DateTime? deleteDate = toDoProvider!.userViewModel?.deleteDate;
      expect(
          Constants.today.copyWith(day: Constants.today.day - 30) == deleteDate,
          true,
          reason:
              "Delete schedule error: -> ${toDoProvider!.userViewModel?.deleteSchedule}\n"
              "DeleteDate: -> $deleteDate");

      expect(toDos.length, 1,
          reason:
              "Delete schedule not respected: todos -> ${toDos.length}, vm -> ${toDoProvider!.userViewModel?.deleteSchedule}");
    });
    test("15 days ago, expect 0 left", () async {
      expect(null != toDoRepo, true, reason: "repo null");
      expect(null != toDoProvider, true, reason: "provider null");

      UserViewModel viewModel = UserViewModel();
      viewModel.deleteSchedule = DeleteSchedule.fifteenDays;
      toDoProvider!.userViewModel = viewModel;

      ToDo t1 = toDo1.copyWith(
          toDelete: toDo1.toDelete, lastUpdated: toDo1.lastUpdated);
      ToDo t2 = toDo2.copyWith(
          toDelete: toDo2.toDelete, lastUpdated: toDo2.lastUpdated);
      ToDo t3 = toDo3.copyWith(
          toDelete: toDo3.toDelete, lastUpdated: toDo3.lastUpdated);
      await toDoRepo!.updateBatch([t1, t2, t3]);

      List<ToDo> toDos = await toDoRepo!.getDeleted();

      expect(toDos.length, 3, reason: "Deleted query failure: ${toDos.length}");

      await toDoProvider!.dayReset();
      toDos = await toDoRepo!.getDeleted();

      DateTime? deleteDate = toDoProvider!.userViewModel?.deleteDate;
      expect(
          Constants.today.copyWith(day: Constants.today.day - 15) == deleteDate,
          true,
          reason:
              "Delete schedule error: -> ${toDoProvider!.userViewModel?.deleteSchedule}\n"
              "DeleteDate: -> $deleteDate");

      expect(toDos.isEmpty, true,
          reason:
              "Delete schedule not respected: todos -> ${toDos.length}, vm -> ${toDoProvider!.userViewModel?.deleteSchedule}");
    });
  });
}

Future<void> initIsar() async {
  // THIS IS NECESSARY, DO NOT TOUCH.
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (MethodCall methodCall) async {
    return '.';
  });
  await isarService.init(debug: true);
  await supabaseService.init(
      anonKey: Constants.supabaseAnnonKey,
      supabaseUrl: Constants.supabaseURL,
      client: FakeSupabase());

  client = IsarService.instance.isarClient;
  supabaseClient = SupabaseService.instance.supabaseClient;
  toDoRepo = ToDoRepo.instance;
  toDoProvider = ToDoProvider();
  await clearIsar();
}

Future<void> clearIsar() async {
  await client!.writeTxn(() async {
    await client!.clear();
  });
}

Future<void> disposeIsar() async {
  await isarService.dispose();
  client = null;
  supabaseClient = null;
  toDoProvider = null;
}
