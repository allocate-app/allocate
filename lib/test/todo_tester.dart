import "dart:io" show Platform;
import "dart:ui";

import "package:flutter/material.dart";
import "package:isar/isar.dart";
import "package:jiffy/jiffy.dart";
import "package:path_provider_linux/path_provider_linux.dart";
import "package:path_provider_macos/path_provider_macos.dart";
import "package:path_provider_windows/path_provider_windows.dart";
import "package:supabase_flutter/supabase_flutter.dart";
import "package:test/test.dart";

import "../model/task/subtask.dart";
import "../model/task/todo.dart";
import "../providers/todo_provider.dart";
import "../services/isar_service.dart";
import "../services/supabase_service.dart";
import "../util/constants.dart";
import "../util/enums.dart";

/// Testing:
/// TODO: fix tests to have enough waiting time.
/// Initialize isar && clear db -> Setup func.
///
/// Tests:
///  - Local DB init & close.
///
///  - Create todo, put in database:
///  - Update todo:
///     -Test data updating
///     -Test subtask updating: add, modify, reorder.
///     -Test subtask reordering.
///     - Test ListLimit Error.
///
///  - Read todo:
///     - Test get by id / with null id
///     - With multiple todos, test sorted views
///     - Test customview reordering.
///
///   - Delete todo:
///     - Test deletion:
///       - Run the delete method
///       - Run the clock
///       - Check whether it was successfully deleted.
///
///
///     - Intentionally invoke -> Requires supabase fake session or throw intentional isar error.
///
///   - Test recurring todos.
///     - Test creation on day change.
///     - Test calendar creation.
///     - Test edit: For one.
///     - Test edit: For all.
///
///   - When Supabase, test pls.
///
///
/// Clear on end of testing -> end func.

final IsarService isarService = IsarService.instance;
final SupabaseService supabaseService = SupabaseService.instance;
SupabaseClient? supabaseClient;
Isar? isarClient;
ToDoProvider? provider;

void main() {
  // This is for pathprovider.
  if (Platform.isWindows) {
    PathProviderWindows.registerWith();
  } else if (Platform.isMacOS) {
    PathProviderMacOS.registerWith();
  } else {
    PathProviderLinux.registerWith();
  }

  DartPluginRegistrant.ensureInitialized();

  // RootIsolateToken rootIsolateToken = RootIsolateToken.instance!;
  // BackgroundIsolateBinaryMessenger.ensureInitialized(rootIsolateToken);

  // This is for async func calls.
  WidgetsFlutterBinding.ensureInitialized();

  setUp(initTesting);
  tearDown(closeTesting);

  group("IsarService tests", () {
    test("Initialization and closing", () async {
      expect(null != isarClient, true,
          reason: "Isar client failed to initialize");
      expect(null != provider, true, reason: "Provider failed to initialize");

      int? count = await isarClient?.toDos.count();

      expect(count != null, true, reason: "Collection is null");
      expect(count, 0, reason: "Database failed to clear");

      await closeTesting();

      expect(isarClient, null, reason: "Isar: Client failed to close");
      expect(provider, null, reason: "Provider: Client failed to close.");
    });
  });

  group("ToDo Create", () {
    test("ToDo creation: min requirements + defaults", () async {
      expect(null != provider, true, reason: "Provider is null");
      await provider!.createToDo(taskType: TaskType.small, name: 'TestSM');
      await Future.delayed(const Duration(seconds: 3));
      await provider!.setToDos();
      provider!.curToDo = provider!.toDos.firstOrNull ?? provider!.curToDo;
      int count = await isarClient!.toDos.count();
      expect(count, 1,
          reason: "toDo not placed in database \n"
              "Provider todos: ${provider!.toDos.toString()}\n"
              "CurToDo id: ${provider!.curToDo!.id}");
      // expect(provider!.failCache.isEmpty, true,
      //     reason: "Update/Upload thrown \n ${provider!.failCache.toString()}");
    });
  });

  group("ToDo Update", () {
    test("Update ToDo Data", () async {
      SubTask st1 = SubTask(name: "ST1", weight: 1);
      SubTask st2 = SubTask(name: "ST2", weight: 2);
      await provider!.createToDo(
          taskType: TaskType.large,
          name: "TestLG",
          subTasks: List.filled(5, SubTask()));
      await Future.delayed(const Duration(seconds: 3));
      // TODO: refactor this once getByID implemented.
      await provider!.setToDos();

      ToDo? tmp = provider!.toDos.firstOrNull;

      expect(tmp != null, true, reason: "Temp is null");

      provider!.curToDo = tmp ?? provider!.curToDo;
      tmp = provider!.curToDo!.copy();
      provider!.curToDo!.subTasks[0] = st1;
      provider!.curToDo!.subTasks[1] = st2;

      await provider!.updateToDo();

      provider!.curToDo = provider!.toDos.firstOrNull ?? provider!.curToDo;

      expect(tmp != provider!.curToDo, true,
          reason:
              "Data failed to update \n Current: ${provider!.curToDo}, Temp: $tmp");

      await Future.delayed(const Duration(seconds: 3));
      // TODO: refactor once getByID() implemented.
      await provider!.setToDosBy();

      tmp = provider!.toDos.firstOrNull;
      expect(null != tmp, true, reason: "null ToDo failed to grab from db");

      provider!.curToDo = tmp ?? provider!.curToDo;

      expect(provider!.curToDo!.weight, 3,
          reason: "Weight failed to recalculate\n"
              "Expected: 3, Actual ${provider!.curToDo!.weight}");

      // expect(provider!.failCache.isEmpty, true,
      //     reason: "Update/Upload thrown \n ${provider!.failCache.toString()}");
    });
  });

  group("ToDo Read", () {
    // Define two ToDos and use a list to compare.

    ToDo td1 = ToDo(
        taskType: TaskType.small,
        name: "a",
        startDate: DateTime.now(),
        dueDate: DateTime.now().add(const Duration(hours: 1)),
        weight: 2,
        expectedDuration: 3600,
        realDuration: 0,
        repeatDays: List.filled(7, false),
        subTasks: List.empty(growable: false),
        priority: Priority.low,
        lastUpdated: DateTime.now());
    ToDo td2 = ToDo(
        taskType: TaskType.small,
        name: "b",
        startDate: DateTime.now(),
        dueDate: DateTime.now().add(const Duration(hours: 2)),
        weight: 3,
        expectedDuration: 3600,
        realDuration: 0,
        repeatDays: List.filled(7, false),
        subTasks: List.empty(growable: false),
        priority: Priority.high,
        lastUpdated: DateTime.now());
    td1.id = 1;
    td1.customViewIndex = 1;
    td2.id = 2;
    td2.customViewIndex = 0;
    String td1First = [td1, td2].toString();
    String td2First = [td2, td1].toString();

    test("Insertion: 2 todos ", () async {
      provider!.curToDo = td1;
      await provider!.recalculateRealDuration();
      await Future.delayed(const Duration(seconds: 3));
      provider!.curToDo = td2;
      await provider!.recalculateRealDuration();
      await Future.delayed(const Duration(seconds: 3));

      await provider!.setToDos();
      expect(provider!.toDos.length == 2, true,
          reason: "Insertion failure\n"
              "Provider todos: ${provider!.toDos.toString()}");
    });

    // TODO: Wrong ID? Maybe.

    // My Day
    test("My Day", () async {
      provider!.curToDo = td1;
      await provider!.recalculateRealDuration();
      await Future.delayed(const Duration(seconds: 3));

      provider!.curToDo = td2;
      await provider!.recalculateRealDuration();
      await Future.delayed(const Duration(seconds: 3));

      await provider!.setToDos();
      expect(provider!.toDos.length == 2, true,
          reason: "Insertion failure\n"
              "Provider todos: ${provider!.toDos.toString()}");

      provider!.curToDo = provider!.toDos.firstOrNull ?? td1;
      provider!.curToDo!.myDay = true;

      await provider!.updateToDo();
      await Future.delayed(const Duration(seconds: 3));

      await provider!.setMyDay();

      expect(provider!.toDos.length, 1,
          reason: "Failed to set my day\n"
              "MyDay: ${provider!.toDos.toString()}");

      provider!.curToDo = provider!.toDos.firstOrNull ?? td1;
      provider!.curToDo!.myDay = false;

      await provider!.updateToDo();
      await Future.delayed(const Duration(seconds: 3));

      await provider!.setMyDay();

      expect(provider!.toDos.isEmpty, true,
          reason: "Failed to remove from myDay\n"
              "Provider todos: ${provider!.toDos.toString()}");
    });

    // Completed
    test("Completed", () async {
      provider!.curToDo = td1;
      await provider!.recalculateRealDuration();
      provider!.curToDo = td2;
      await provider!.recalculateRealDuration();

      await Future.delayed(const Duration(seconds: 3));

      await provider!.setToDos();
      expect(provider!.toDos.length == 2, true,
          reason: "Insertion failure\n"
              "Provider todos: ${provider!.toDos.toString()}");

      provider!.curToDo = provider!.toDos.firstOrNull ?? td1;

      provider!.curToDo!.completed = true;

      await provider!.updateToDo();
      await Future.delayed(const Duration(seconds: 3));

      await provider!.setToDosCompleted();
      expect(provider!.toDos.length, 1,
          reason: "Failed to set completion \n"
              "Provider todos: ${provider!.toDos.toString()}");

      provider!.curToDo = provider!.toDos.firstOrNull ?? td1;
      provider!.curToDo!.completed = false;

      await provider!.updateToDo();
      await Future.delayed(const Duration(seconds: 3));

      await provider!.setToDosCompleted();

      expect(provider!.toDos.isEmpty, true,
          reason: "Failed to remove completion\n"
              "Provider todos: ${provider!.toDos.toString()}");

      // expect(provider!.failCache.isEmpty, true,
      //     reason: "Update/Upload thrown \n ${provider!.failCache.toString()}");
    });

    // Sorting.
    test("ToDo sort by Name", () async {
      provider!.curToDo = td1;
      await provider!.recalculateRealDuration();
      provider!.curToDo = td2;
      await provider!.recalculateRealDuration();

      await Future.delayed(const Duration(seconds: 3));

      await provider!.setToDos();

      expect(provider!.toDos.length == 2, true,
          reason: "Insertion failure\n"
              "Provider todos: ${provider!.toDos.toString()}");

      expect(provider!.toDos.toString(), td2First,
          reason: "Custom VI failed \n"
              "Provider todos: ${provider!.toDos.toString()}\n"
              "Expected: $td2First");

      provider!.sorter.sortMethod = SortMethod.name;
      provider!.sorter.descending = false;

      await provider!.setToDosBy();

      expect(provider!.toDos.toString(), td1First,
          reason: "Sort by name failed\n"
              "SortMethod: ${provider!.sortMethod.name}, Descending: ${provider!.descending}\n"
              "Provider todos: ${provider!.toDos.toString()}\n"
              "Expected: $td1First");

      provider!.sorter.descending = true;
      await provider!.setToDosBy();

      expect(provider!.toDos.toString(), td2First,
          reason: "Descending sort by name failed\n"
              "SortMethod: ${provider!.sortMethod.name}, Descending: ${provider!.descending}\n"
              "Provider todos: ${provider!.toDos.toString()}\n"
              "Expected: $td2First");

      // expect(provider!.failCache.isEmpty, true,
      //     reason: "Update/Upload thrown \n ${provider!.failCache.toString()}");
    });

    test("ToDo sort by dueDate", () async {
      provider!.curToDo = td1;
      await provider!.recalculateRealDuration();
      provider!.curToDo = td2;
      await provider!.recalculateRealDuration();

      await Future.delayed(const Duration(seconds: 3));

      await provider!.setToDos();

      expect(provider!.toDos.length, 2, reason: "DB query failed");
      expect(provider!.toDos.toString(), td2First, reason: "Custom VI failed");

      provider!.sorter.sortMethod = SortMethod.due_date;
      provider!.sorter.descending = false;

      await provider!.setToDosBy();

      expect(provider!.toDos.toString(), td1First,
          reason: "Sort by dueDate failed\n"
              "SortMethod: ${provider!.sortMethod.name}, Descending: ${provider!.descending}\n"
              "Provider todos: ${provider!.toDos.toString()}\n"
              "Expected: $td1First");

      provider!.sorter.descending = true;
      await provider!.setToDosBy();

      expect(provider!.toDos.toString(), td2First,
          reason: "Descending sort by dueDate failed\n"
              "SortMethod: ${provider!.sortMethod.name}, Descending: ${provider!.descending}\n"
              "Provider todos: ${provider!.toDos.toString()}\n"
              "Expected: $td2First");

      // expect(provider!.failCache.isEmpty, true,
      //     reason: "Update/Upload thrown \n ${provider!.failCache.toString()}");
    });

    test("ToDo sort by weight", () async {
      provider!.curToDo = td1;
      await provider!.recalculateRealDuration();
      provider!.curToDo = td2;
      await provider!.recalculateRealDuration();

      await Future.delayed(const Duration(seconds: 3));

      await provider!.setToDos();

      expect(provider!.toDos.length, 2, reason: "DB query failed");
      expect(provider!.toDos.toString(), td2First, reason: "Custom VI failed");

      provider!.sorter.sortMethod = SortMethod.weight;
      provider!.sorter.descending = false;

      await provider!.setToDosBy();

      expect(provider!.toDos.toString(), td1First,
          reason: "Sort by weight failed\n"
              "SortMethod: ${provider!.sortMethod.name}, Descending: ${provider!.descending}\n"
              "Provider todos: ${provider!.toDos.toString()}\n"
              "Expected: $td1First");

      provider!.sorter.descending = true;
      await provider!.setToDosBy();

      expect(provider!.toDos.toString(), td2First,
          reason: "Descending sort by weight failed\n"
              "SortMethod: ${provider!.sortMethod.name}, Descending: ${provider!.descending}\n"
              "Provider todos: ${provider!.toDos.toString()}\n"
              "Expected: $td2First");

      // expect(provider!.failCache.isEmpty, true,
      //     reason: "Update/Upload thrown \n ${provider!.failCache.toString()}");
    });

    test("ToDo sort by RealDuration", () async {
      provider!.curToDo = td1;
      await provider!.recalculateRealDuration();
      provider!.curToDo = td2;
      await provider!.recalculateRealDuration();
      await Future.delayed(const Duration(seconds: 3));

      await provider!.setToDos();

      expect(provider!.toDos.length, 2, reason: "DB query failed");
      expect(provider!.toDos.toString(), td2First, reason: "Custom VI failed");

      provider!.sorter.sortMethod = SortMethod.duration;
      provider!.sorter.descending = false;

      await provider!.setToDosBy();

      expect(provider!.toDos.toString(), td1First,
          reason: "Sort by Duration failed\n"
              "SortMethod: ${provider!.sortMethod.name}, Descending: ${provider!.descending}\n"
              "Provider todos: ${provider!.toDos.toString()}\n"
              "Expected: $td1First");

      provider!.sorter.descending = true;
      await provider!.setToDosBy();

      expect(provider!.toDos.toString(), td2First,
          reason: "Descending sort by Duration failed\n"
              "SortMethod: ${provider!.sortMethod.name}, Descending: ${provider!.descending}\n"
              "Provider todos: ${provider!.toDos.toString()}\n"
              "Expected: $td2First");

      // expect(provider!.failCache.isEmpty, true,
      //     reason: "Update/Upload thrown \n ${provider!.failCache.toString()}");
    });

    test("ToDo sort by Priority", () async {
      provider!.curToDo = td1;
      await provider!.recalculateRealDuration();
      provider!.curToDo = td2;
      await provider!.recalculateRealDuration();
      await Future.delayed(const Duration(seconds: 3));

      await provider!.setToDos();

      expect(provider!.toDos.length, 2, reason: "DB query failed");
      expect(provider!.toDos.toString(), td2First, reason: "Custom VI failed");

      provider!.sorter.sortMethod = SortMethod.priority;
      provider!.sorter.descending = false;

      await provider!.setToDosBy();

      expect(provider!.toDos.toString(), td1First,
          reason: "Sorting by priority failed \n"
              "SortMethod: ${provider!.sortMethod.name}, Descending: ${provider!.descending}\n"
              "Provider todos: ${provider!.toDos.toString()}\n"
              "Expected: $td1First");

      provider!.sorter.descending = true;

      await provider!.setToDosBy();

      expect(provider!.toDos.toString(), td2First,
          reason: "Descending sort by priority failed\n"
              "SortMethod: ${provider!.sortMethod.name}, Descending: ${provider!.descending}\n"
              "Provider todos: ${provider!.toDos.toString()}\n"
              "Expected: $td2First");

      // expect(provider!.failCache.isEmpty, true,
      //     reason: "Update/Upload thrown \n ${provider!.failCache.toString()}");
    });

    // Reordering

    test("ToDo Reordering", () async {
      provider!.curToDo = td1;
      await provider!.recalculateRealDuration();
      provider!.curToDo = td2;
      await provider!.recalculateRealDuration();

      await Future.delayed(const Duration(seconds: 3));

      await provider!.setToDos();

      expect(provider!.toDos.length, 2, reason: "DB query failed");
      expect(provider!.toDos.toString(), td2First, reason: "Custom VI failed");

      await provider!.reorderToDos(oldIndex: 1, newIndex: 0);

      await Future.delayed(const Duration(seconds: 3));

      provider!.sorter.sortMethod = SortMethod.none;
      await provider!.setToDosBy();

      expect(provider!.toDos.first.name, td1.name, reason: "CVI failed");
      expect(provider!.toDos.first.customViewIndex, 0,
          reason: "CVI not set \n todos: ${provider!.toDos.toString()}");
      expect(provider!.toDos.last.customViewIndex, 1,
          reason: "CVI not set \n todos: ${provider!.toDos.toString()}");

      // expect(provider!.failCache.isEmpty, true,
      //     reason: "Update/Upload thrown \n ${provider!.failCache.toString()}");
    });
  });

  group("ToDo Delete", () {
    test("ToDo Delete Routine", () async {
      await provider!.createToDo(taskType: TaskType.small, name: "TD1");
      await provider!.createToDo(taskType: TaskType.small, name: "TD2");

      await Future.delayed(const Duration(seconds: 5));

      await provider!.setToDos();

      expect(provider!.toDos.length, 2, reason: "DB Query Failed");

      expect(provider!.syncTimer.isActive, true, reason: "Timer failed to set");

      await provider!.deleteToDo();
      await Future.delayed(const Duration(seconds: 3));

      await provider!.setToDos();

      expect(provider!.toDos.length, 1, reason: "Delete Routine failed");

      expect(provider!.toDos.firstOrNull?.name, "TD1",
          reason: "Wrong task deleted");

      provider!.createToDo(taskType: TaskType.small, name: "TD2");
      await provider!.deleteToDo();
      await Future.delayed(const Duration(seconds: 3));

      await provider!.setToDosBy();
      provider!.curToDo = provider!.toDos.firstOrNull ?? provider!.curToDo;

      await provider!.deleteToDo();
      await Future.delayed(const Duration(seconds: 3));
      provider!.createToDo(taskType: TaskType.small, name: "TD3");

      await Future.delayed(const Duration(seconds: 5));

      await provider!.setToDos();

      expect(provider!.toDos.length, 1,
          reason: "Delete Routine failed for multiple delete");

      provider!.curToDo = provider!.toDos.firstOrNull ?? provider!.curToDo;

      expect(provider!.curToDo!.name, "TD3", reason: "wrong todos deleted");
      await Future.delayed(const Duration(seconds: 30));

      // expect(provider!.failCache.isEmpty, true,
      //     reason: "Update/Upload thrown \n ${provider!.failCache.toString()}");
    });
  });

  // TODO: finish these once Supabase has been set up.
  // group("Supabase", () {

  // });
  //
  // // group("FailCache & Supabase", () {

  // });

  group("Recurring", () {
    test("Repeatable/Frequency.Once Failsafe", () async {
      provider!.createToDo(
          taskType: TaskType.small,
          name: "RepeatableTest",
          repeatable: true,
          frequency: Frequency.once,
          dueDate: DateTime.now());

      await Future.delayed(const Duration(seconds: 3));

      provider!
          .checkRepeating(now: DateTime.now().add(const Duration(days: 1)));

      await Future.delayed(const Duration(seconds: 3));

      await provider!.setToDosBy();

      expect(provider!.toDos.isNotEmpty, true,
          reason: "Db query failed \n ToDos: ${provider!.toDos.toString()}");
      expect(provider!.toDos.length, 1,
          reason: "More than one todo \n ToDos: ${provider!.toDos.toString()}");

      provider!.curToDo = provider!.toDos.firstOrNull ?? provider!.curToDo;

      expect(provider!.curToDo!.repeatable, false,
          reason: "ToDo repeatable not properly removed");

      // expect(provider!.failCache.isEmpty, true,
      //     reason: "Update/Upload thrown \n ${provider!.failCache.toString()}");
    });

    test("Daily Recurrence", () async {
      provider!.sorter.sortMethod = SortMethod.due_date;
      provider!.sorter.descending = true;

      provider!.createToDo(
          taskType: TaskType.small,
          name: "DailyTest",
          repeatable: true,
          frequency: Frequency.daily,
          startDate: DateTime.now(),
          dueDate: DateTime.now().add(const Duration(minutes: 1)));

      await Future.delayed(const Duration(seconds: 5));
      await provider!.setToDosBy();
      expect(provider!.toDos.length, 1, reason: "Db not updating");

      DateTime testDate = DateTime.now().add(const Duration(days: 1));
      for (int i = 1; i < 7; i++) {
        testDate = testDate.add(const Duration(days: 1));

        provider!.checkRepeating(now: testDate);
        await Future.delayed(const Duration(seconds: 3));

        await provider!.setToDosBy();

        expect(provider!.toDos.length, i + 1,
            reason:
                "Daily routine incorrect, ${provider!.toDos.length}/${i + 1} \n todos: ${provider!.toDos.toString()}");
      }

      await Future.delayed(const Duration(seconds: 5));
      await provider!.setToDosBy();

      expect(provider!.toDos.length, 7,
          reason:
              "Daily routine failed \n ToDos: ${provider!.toDos.toString()}");
      expect(
          provider!.toDos.firstOrNull?.dueDate
              .isAfter(provider!.curToDo!.dueDate),
          true,
          reason:
              "Repeat copy was unsuccessful \n todos: ${provider!.toDos.toString()}");
      // expect(provider!.failCache.isEmpty, true,
      //     reason: "Update/Upload thrown \n ${provider!.failCache.toString()}");
    });

    test("Weekly Recurrence", () async {
      provider!.sorter.sortMethod = SortMethod.due_date;
      provider!.sorter.descending = true;

      provider!.createToDo(
          taskType: TaskType.small,
          name: "WeeklyTest",
          repeatable: true,
          frequency: Frequency.weekly,
          startDate: DateTime.now(),
          dueDate: DateTime.now().add(const Duration(minutes: 1)));

      await Future.delayed(const Duration(seconds: 5));
      await provider!.setToDosBy();
      expect(provider!.toDos.length, 1, reason: "Db not updating");

      DateTime testDate = DateTime.now().add(const Duration(days: 1));

      for (int i = 1; i < 4; i++) {
        testDate =
            Jiffy.parseFromDateTime(testDate).add(weeks: 1, days: 1).dateTime;

        provider!.checkRepeating(now: testDate);
        await Future.delayed(const Duration(seconds: 5));

        await provider!.setToDosBy();

        expect(provider!.toDos.length, i + 1,
            reason:
                "Weekly routine incorrect, ${provider!.toDos.length}/${i + 1} \n todos: ${provider!.toDos.toString()}");
      }

      await Future.delayed(const Duration(seconds: 5));
      await provider!.setToDosBy();

      expect(provider!.toDos.length, 4,
          reason:
              "Weekly routine failed \n ToDos: ${provider!.toDos.toString()}");
      expect(
          provider!.toDos.firstOrNull?.dueDate
              .isAfter(provider!.curToDo!.dueDate),
          true,
          reason:
              "Repeat copy was unsuccessful\n CurToDo: ${provider!.curToDo!.dueDate}, Last: ${provider!.toDos.first.dueDate} \n todos: ${provider!.toDos.toString()}");

      // expect(provider!.failCache.isEmpty, true,
      //     reason: "Update/Upload thrown \n ${provider!.failCache.toString()}");
    });

    test("Biweekly recurrence", () async {
      provider!.sorter.sortMethod = SortMethod.due_date;
      provider!.sorter.descending = true;
      provider!.syncTimer.cancel();
      provider!.startTimer();

      provider!.createToDo(
          taskType: TaskType.small,
          startDate: DateTime.now(),
          dueDate: DateTime.now().add(const Duration(minutes: 1)),
          name: "BiweeklyTest",
          repeatable: true,
          frequency: Frequency.weekly,
          repeatSkip: 2);

      DateTime testDate = DateTime.now().add(const Duration(days: 1));

      for (int i = 1; i < 3; i++) {
        testDate = Jiffy.parseFromDateTime(testDate).add(weeks: 1).dateTime;
        provider!.checkRepeating(now: testDate);
        await Future.delayed(const Duration(seconds: 3));
      }
      // This is just to let the async function catch up.
      await Future.delayed(const Duration(seconds: 5));
      await provider!.setToDosBy();
      expect(provider!.toDos.length, 2,
          reason:
              "Biweekly Repeat broken\n ToDos: ${provider!.toDos.toString()}");
      expect(
          provider!.toDos.firstOrNull?.dueDate
              .isAfter(provider!.curToDo!.dueDate),
          true,
          reason:
              "Copy Routine didn't work or sorting busted \n ToDos: ${provider!.toDos.toString()}");
      // expect(provider!.failCache.isEmpty, true,
      //     reason: "Update/Upload thrown \n ${provider!.failCache.toString()}");
    });

    test("Monthly Recurrence", () async {
      provider!.sorter.sortMethod = SortMethod.due_date;
      provider!.sorter.descending = true;

      provider!.createToDo(
          taskType: TaskType.small,
          name: "MonthlyTest",
          repeatable: true,
          frequency: Frequency.monthly,
          startDate: DateTime.now(),
          dueDate: DateTime.now().add(const Duration(minutes: 1)));

      await Future.delayed(const Duration(seconds: 5));
      await provider!.setToDosBy();
      expect(provider!.toDos.length, 1, reason: "Db not updating");

      DateTime testDate = DateTime.now().add(const Duration(days: 1));
      for (int i = 1; i < 4; i++) {
        testDate = Jiffy.parseFromDateTime(testDate).add(months: 1).dateTime;
        provider!.checkRepeating(now: testDate);
        await Future.delayed(const Duration(seconds: 5));

        await provider!.setToDosBy();

        expect(provider!.toDos.length, i + 1,
            reason:
                "Monthly routine incorrect, ${provider!.toDos.length}/${i + 1} \n todos: ${provider!.toDos.toString()}");
      }

      await Future.delayed(const Duration(seconds: 5));
      await provider!.setToDosBy();

      expect(provider!.toDos.length, 4,
          reason:
              "Monthly routine failed \n ToDos: ${provider!.toDos.toString()}");
      expect(
          provider!.toDos.firstOrNull?.dueDate
              .isAfter(provider!.curToDo!.dueDate),
          true,
          reason:
              "Repeat copy was unsuccessful \n todos: ${provider!.toDos.toString()}");
      // expect(provider!.failCache.isEmpty, true,
      //     reason: "Update/Upload thrown \n ${provider!.failCache.toString()}");
    });

    test("Yearly Recurrence", () async {
      provider!.sorter.sortMethod = SortMethod.due_date;
      provider!.sorter.descending = true;

      provider!.createToDo(
          taskType: TaskType.small,
          name: "YearlyTest",
          repeatable: true,
          frequency: Frequency.yearly,
          startDate: DateTime.now(),
          dueDate: DateTime.now().add(const Duration(minutes: 1)));

      await Future.delayed(const Duration(seconds: 5));
      await provider!.setToDosBy();
      expect(provider!.toDos.length, 1, reason: "Db not updating");

      DateTime testDate = DateTime.now().add(const Duration(days: 1));
      for (int i = 1; i < 4; i++) {
        testDate = Jiffy.parseFromDateTime(testDate).add(years: 1).dateTime;
        provider!.checkRepeating(now: testDate);
        await Future.delayed(const Duration(seconds: 3));

        await provider!.setToDosBy();

        expect(provider!.toDos.length, i + 1,
            reason:
                "Yearly routine incorrect, ${provider!.toDos.length}/${i + 1} \n todos: ${provider!.toDos.toString()}");
      }

      await Future.delayed(const Duration(seconds: 3));
      await provider!.setToDosBy();

      expect(provider!.toDos.length, 4,
          reason:
              "Yearly routine failed \n ToDos: ${provider!.toDos.toString()}");
      expect(
          provider!.toDos.firstOrNull?.dueDate
              .isAfter(provider!.curToDo!.dueDate),
          true,
          reason:
              "Repeat copy was unsuccessful \n todos: ${provider!.toDos.toString()}");
      // expect(provider!.failCache.isEmpty, true,
      //     reason: "Update/Upload thrown \n ${provider!.failCache.toString()}");
    });

    test("Custom recurrence: Monday-Tuesday, biweekly", () async {
      provider!.sorter.sortMethod = SortMethod.due_date;
      provider!.sorter.descending = true;

      await provider!.createToDo(
          taskType: TaskType.small,
          name: "Mon-Tues Biweekly",
          // This is a Monday.
          startDate:
              Jiffy.parse("2023 Jul 24th", pattern: "yyyy MMM do").dateTime,
          dueDate:
              Jiffy.parse("2023 Jul 25th", pattern: "yyyy MMM do").dateTime,
          repeatable: true,
          frequency: Frequency.custom,
          customFreq: CustomFrequency.weekly,
          repeatSkip: 2,
          repeatDays: [true, true, false, false, false, false, false]);

      DateTime testDate = DateTime.now();

      for (int i = 1; i < 4; i++) {
        testDate = Jiffy.parseFromDateTime(testDate).add(weeks: 1).dateTime;
        provider!.checkRepeating(now: testDate);
        await Future.delayed(const Duration(seconds: 3));
      }

      provider!.checkRepeating(now: testDate);

      await Future.delayed(const Duration(seconds: 3));
      await provider!.setToDosBy();

      expect(provider!.toDos.length, 4,
          reason:
              "Mon-Tues biweekly (custom) routine failed \n todos: ${provider!.toDos.toString()}");
      expect(
          provider!.toDos.firstOrNull?.dueDate
              .isAfter(provider!.curToDo!.dueDate),
          true,
          reason:
              "Copy Routine didn't work or sorting busted \n todos: ${provider!.toDos.toString()}");
      // expect(provider!.failCache.isEmpty, true,
      //     reason: "Update/Upload thrown \n ${provider!.failCache.toString()}");
    });
    test("Custom recurrence: Mon-Wed-Fri, monthly", () async {
      provider!.sorter.sortMethod = SortMethod.due_date;
      provider!.sorter.descending = true;

      await provider!.createToDo(
          taskType: TaskType.small,
          name: "Mon-Tues Biweekly",
          // This is a Monday.
          startDate:
              Jiffy.parse("2023 Jul 24th", pattern: "yyyy MMM do").dateTime,
          dueDate:
              Jiffy.parse("2023 Jul 25th", pattern: "yyyy MMM do").dateTime,
          repeatable: true,
          frequency: Frequency.custom,
          customFreq: CustomFrequency.monthly,
          repeatSkip: 1,
          repeatDays: [true, false, true, false, true, false, false]);

      DateTime testDate = Jiffy.parseFromDateTime(provider!.curToDo!.startDate)
          .add(months: 1, days: 1)
          .dateTime;

      for (int i = 0; i < 4; i++) {
        provider!.checkRepeating(now: testDate);
        await Future.delayed(const Duration(seconds: 3));
      }

      await Future.delayed(const Duration(seconds: 15));
      await provider!.setToDosBy();

      expect(provider!.toDos.length, 4,
          reason:
              "Mon-Tues biweekly (custom) routine failed \n todos: ${provider!.toDos.toString()}");
      expect(
          provider!.toDos.firstOrNull?.dueDate
              .isAfter(provider!.curToDo!.dueDate),
          true,
          reason:
              "Copy Routine didn't work or sorting busted \n todos: ${provider!.toDos.toString()}");
      // expect(provider!.failCache.isEmpty, true,
      //     reason: "Update/Upload thrown \n ${provider!.failCache.toString()}");
    });
  });
}

Future<void> initTesting() async {
  await initDatabase();
  provider = ToDoProvider();
}

Future<void> initDatabase() async {
  await isarService.init(debug: true);
  await supabaseService.init(
      anonKey: Constants.supabaseAnnonKey,
      supabaseUrl: Constants.supabaseURL,
      client: FakeSupabase());
  isarClient = IsarService.instance.isarClient;
  supabaseClient = SupabaseService.instance.supabaseClient;
  await clearDatabase();
}

Future<void> clearDatabase() async => await isarClient?.writeTxn(() async {
      await isarClient!.clear();
      await Future.delayed(const Duration(seconds: 3));
    });

Future<void> closeDatabase() async {
  await isarService.dispose();
}

Future<void> closeTesting() async {
  await closeDatabase();
  isarClient = null;
  supabaseClient = null;
  provider?.syncTimer.cancel();
  provider = null;
}
