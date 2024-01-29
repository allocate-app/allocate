import 'dart:ui';

import 'package:flutter/services.dart';
import "package:flutter_test/flutter_test.dart";
import 'package:isar/isar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../model/task/todo.dart';
import '../providers/model/todo_provider.dart';
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

  group("MyDay, Day reset", () {
    ToDo toDo1 = ToDo(
      id: Constants.generateID(),
      taskType: TaskType.small,
      name: 'toDo1',
      expectedDuration: 0,
      weight: 10,
      realDuration: 0,
      repeatDays: List.generate(7, (i) => false),
      lastUpdated: Constants.today,
    );

    ToDo toDo2 = ToDo(
      id: Constants.generateID(),
      taskType: TaskType.small,
      name: "toDo2",
      expectedDuration: 0,
      weight: 5,
      realDuration: 0,
      repeatDays: List.generate(7, (i) => false),
      lastUpdated: Constants.today,
    );
    test("Two my day tasks, proper weights + list", () async {
      expect(null != toDoRepo, true, reason: "repo null");
      expect(null != toDoProvider, true, reason: "provider null");

      ToDo t1 = toDo1.copy();
      ToDo t2 = toDo2.copy();
      t1.myDay = true;
      t2.myDay = true;
      t1.completed = false;
      t2.completed = false;

      await toDoRepo!.updateBatch([t1, t2]);
      toDoProvider!.myDayWeight = await toDoProvider!.getMyDayWeight();
      List<ToDo> myDay = await toDoProvider!.getMyDay();
      expect(myDay.length, 2, reason: "My day query error: ${myDay.length}");
      expect(toDoProvider!.myDayWeight, 15,
          reason: "My Day weight query error: ${toDoProvider!.myDayWeight}");
    });
    test("Two my day tasks, one is completed, ensure weight remains", () async {
      expect(null != toDoRepo, true, reason: "repo null");
      expect(null != toDoProvider, true, reason: "provider null");

      ToDo t1 = toDo1.copy();
      ToDo t2 = toDo2.copy();
      t1.myDay = true;
      t2.myDay = true;
      t1.completed = true;
      t2.completed = false;

      await toDoRepo!.updateBatch([t1, t2]);
      toDoProvider!.myDayWeight = await toDoProvider!.getMyDayWeight();
      List<ToDo> myDay = await toDoProvider!.getMyDay();
      expect(myDay.length, 2,
          reason: "My day query error, completed ignored: ${myDay.length}");
      expect(toDoProvider!.myDayWeight, 15,
          reason:
              "My Day weight query error, completed ignored: ${toDoProvider!.myDayWeight}");
    });
    test(
        "Two my day tasks, one is completed, day reset, ensure removal and weight",
        () async {
      expect(null != toDoRepo, true, reason: "repo null");
      expect(null != toDoProvider, true, reason: "provider null");

      ToDo t1 = toDo1.copy();
      ToDo t2 = toDo2.copy();
      t1.myDay = true;
      t2.myDay = true;
      t1.completed = true;
      t2.completed = false;

      await toDoRepo!.updateBatch([t1, t2]);
      toDoProvider!.myDayWeight = await toDoProvider!.getMyDayWeight();
      List<ToDo> myDay = await toDoProvider!.getMyDay();
      expect(myDay.length, 2,
          reason:
              "My day query error, completed still ignored: ${myDay.length}");
      expect(toDoProvider!.myDayWeight, 15,
          reason:
              "My Day weight query error, completed still ignored: ${toDoProvider!.myDayWeight}");

      // Now run "day reset".

      await toDoProvider!.dayReset();
      toDoProvider!.myDayWeight = await toDoProvider!.getMyDayWeight();
      myDay = await toDoProvider!.getMyDay();
      expect(myDay.length, 1,
          reason:
              "Query error or day reset error: length ->${myDay.length}, t1 myDay-> ${t1.myDay}");
      expect(toDoProvider!.myDayWeight, 5,
          reason:
              "Query error or day reset error: tp weight -> ${toDoProvider!.myDayWeight}, t1 myDay -> ${t1.myDay}");
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
