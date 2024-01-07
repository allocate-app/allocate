import "dart:ui";

import "package:flutter/services.dart";
import "package:flutter_test/flutter_test.dart";
import "package:isar/isar.dart";
import "package:supabase_flutter/supabase_flutter.dart";

import "../model/task/deadline.dart";
import "../model/task/reminder.dart";
import "../model/task/todo.dart";
import "../repositories/deadline_repo.dart";
import "../repositories/reminder_repo.dart";
import "../repositories/todo_repo.dart";
import "../services/isar_service.dart";
import "../services/repeatable_service.dart";
import "../services/supabase_service.dart";
import "../util/constants.dart";
import "../util/enums.dart";
import "../util/exceptions.dart";
import "../util/interfaces/repository/model/deadline_repository.dart";
import "../util/interfaces/repository/model/reminder_repository.dart";
import "../util/interfaces/repository/model/todo_repository.dart";
import "../util/sorting/deadline_sorter.dart";
import "../util/sorting/reminder_sorter.dart";
import "../util/sorting/todo_sorter.dart";

final IsarService isarService = IsarService.instance;
Isar? client;
final SupabaseService supabaseService = SupabaseService.instance;
SupabaseClient? supabaseClient;
RepeatableService? repeatableService;
ToDoRepository? toDoRepo;
DeadlineRepository? deadlineRepo;
ReminderRepository? reminderRepo;

// Starting from Jan 1st, 2024
DateTime startDate = DateTime(2024);
DateTime dueDate = DateTime(2024, 1, 2);

void main() async {
  DartPluginRegistrant.ensureInitialized();
  RootIsolateToken rootIsolateToken = RootIsolateToken.instance!;
  BackgroundIsolateBinaryMessenger.ensureInitialized(rootIsolateToken);
  TestWidgetsFlutterBinding.ensureInitialized();

  // Date arithmetic.
  group("Get repeat date", () {
    ToDo toDo = ToDo(
        taskType: TaskType.small,
        name: 'Tester',
        expectedDuration: 0,
        originalStart: startDate,
        startDate: startDate,
        originalDue: dueDate,
        dueDate: dueDate,
        realDuration: 0,
        repeatDays: List.generate(7, (i) => false),
        lastUpdated: DateTime.now());
    ToDo newToDo = toDo.copy();

    test("Ensure separate objects Task", () {
      expect(toDo == newToDo, false, reason: "IDs didn't generate.");
    });
    test("Ensure identical starting data Task", () {
      expect(toDo.startDate == newToDo.startDate, true,
          reason: "Copy Constructor failed");
      expect(toDo.dueDate == newToDo.dueDate, true,
          reason: "Copy Constructor Failed");
    });

    test("Date offset Task", () {
      expect(
          repeatableService!
              .getDateTimeDayOffset(start: startDate, end: dueDate),
          1,
          reason: "Offset calculation is incorrect");
    });
    // Task
    test("Daily Task, 1 mo", () {
      ToDo testToDo = toDo.copyWith(frequency: Frequency.daily, repeatSkip: 1);
      ToDo testNewToDo = testToDo.copy();

      expect(testToDo.startDate == testNewToDo.startDate, true,
          reason: "Copy Constructor failed");
      expect(testToDo.dueDate == testNewToDo.dueDate, true,
          reason: "Copy Constructor Failed");

      for (int i = 0; i < 30; i++) {
        DateTime? nextDate = repeatableService!.getRepeatDate(model: testToDo);
        int offset = repeatableService!.getDateTimeDayOffset(
            start: testToDo.startDate, end: testToDo.dueDate);

        // Make a new task
        testNewToDo = testToDo.copyWith(
            startDate: nextDate,
            dueDate: nextDate?.copyWith(day: nextDate.day + offset));
        expect(
            repeatableService!.getDateTimeDayOffset(
                start: newToDo.startDate, end: testNewToDo.startDate),
            1,
            reason: "Got wrong date");
        expect(
            repeatableService!.getDateTimeDayOffset(
                start: newToDo.dueDate, end: testNewToDo.dueDate),
            1,
            reason: "Got wrong date");

        // update the date for the next one
        testToDo = testNewToDo;
      }
    });
    test("Task Every two days, 1 mo", () {
      ToDo testToDo = toDo.copyWith(frequency: Frequency.daily, repeatSkip: 2);
      ToDo testNewToDo = testToDo.copy();

      expect(testToDo.startDate == testNewToDo.startDate, true,
          reason: "Copy Constructor failed");
      expect(testToDo.dueDate == testNewToDo.dueDate, true,
          reason: "Copy Constructor Failed");

      for (int i = 0; i < 30; i++) {
        DateTime? nextDate = repeatableService!.getRepeatDate(model: testToDo);
        int offset = repeatableService!.getDateTimeDayOffset(
            start: testToDo.startDate, end: testToDo.dueDate);

        // Make a new task
        testNewToDo = testToDo.copyWith(
            startDate: nextDate,
            dueDate: nextDate?.copyWith(day: nextDate.day + offset));
        expect(
            repeatableService!.getDateTimeDayOffset(
                start: newToDo.startDate, end: testNewToDo.startDate),
            2,
            reason: "Got wrong date");
        expect(
            repeatableService!.getDateTimeDayOffset(
                start: newToDo.dueDate, end: testNewToDo.dueDate),
            2,
            reason: "Got wrong date");

        // update the date for the next one
        testToDo = testNewToDo;
      }
    });
    test("Task Every 3 days 1 mo", () {
      ToDo testToDo = toDo.copyWith(frequency: Frequency.daily, repeatSkip: 3);
      ToDo testNewToDo = testToDo.copy();

      expect(testToDo.startDate == testNewToDo.startDate, true,
          reason: "Copy Constructor failed");
      expect(testToDo.dueDate == testNewToDo.dueDate, true,
          reason: "Copy Constructor Failed");

      for (int i = 0; i < 30; i++) {
        DateTime? nextDate = repeatableService!.getRepeatDate(model: testToDo);
        int offset = repeatableService!.getDateTimeDayOffset(
            start: testToDo.startDate, end: testToDo.dueDate);

        // Make a new task
        testNewToDo = testToDo.copyWith(
            startDate: nextDate,
            dueDate: nextDate?.copyWith(day: nextDate.day + offset));
        expect(
            repeatableService!.getDateTimeDayOffset(
                start: newToDo.startDate, end: testNewToDo.startDate),
            3,
            reason: "Got wrong date");
        expect(
            repeatableService!.getDateTimeDayOffset(
                start: newToDo.dueDate, end: testNewToDo.dueDate),
            3,
            reason: "Got wrong date");

        // update the date for the next one
        testToDo = testNewToDo;
      }
    });

    test("Weekly Task 1 mo", () {
      ToDo testToDo = toDo.copyWith(frequency: Frequency.weekly, repeatSkip: 1);
      ToDo testNewToDo = testToDo.copy();

      expect(testToDo.startDate == testNewToDo.startDate, true,
          reason: "Copy Constructor failed");
      expect(testToDo.dueDate == testNewToDo.dueDate, true,
          reason: "Copy Constructor Failed");

      DateTime? nextDate = repeatableService!.getRepeatDate(model: testToDo);
      int offset = repeatableService!.getDateTimeDayOffset(
          start: testToDo.startDate, end: testToDo.dueDate);

      DateTime? nextDue = nextDate!.copyWith(day: nextDate.day + offset);

      testNewToDo = testToDo.copyWith(
        startDate: nextDate,
        originalStart: nextDate,
        dueDate: nextDue,
        originalDue: nextDue,
      );

      expect(testNewToDo.startDate!, DateTime(2024, 1, 8),
          reason: "Date miscalculation");
      expect(testNewToDo.dueDate!, DateTime(2024, 1, 9),
          reason: "Date miscalculation");

      testToDo = testNewToDo;

      nextDate = repeatableService!.getRepeatDate(model: testToDo);
      offset = repeatableService!.getDateTimeDayOffset(
          start: testToDo.startDate, end: testToDo.dueDate);

      nextDue = nextDate!.copyWith(day: nextDate.day + offset);

      testNewToDo = testToDo.copyWith(
        startDate: nextDate,
        originalStart: nextDate,
        dueDate: nextDue,
        originalDue: nextDue,
      );

      expect(testNewToDo.startDate!, DateTime(2024, 1, 15),
          reason: "Date miscalculation");
      expect(testNewToDo.dueDate!, DateTime(2024, 1, 16),
          reason: "Date miscalculation");

      testToDo = testNewToDo;

      nextDate = repeatableService!.getRepeatDate(model: testToDo);
      offset = repeatableService!.getDateTimeDayOffset(
          start: testToDo.startDate, end: testToDo.dueDate);

      nextDue = nextDate!.copyWith(day: nextDate.day + offset);

      testNewToDo = testToDo.copyWith(
        startDate: nextDate,
        originalStart: nextDate,
        dueDate: nextDue,
        originalDue: nextDue,
      );

      expect(testNewToDo.startDate!, DateTime(2024, 1, 22),
          reason: "Date miscalculation");
      expect(testNewToDo.dueDate!, DateTime(2024, 1, 23),
          reason: "Date miscalculation");

      testToDo = testNewToDo;

      nextDate = repeatableService!.getRepeatDate(model: testToDo);
      offset = repeatableService!.getDateTimeDayOffset(
          start: testToDo.startDate, end: testToDo.dueDate);

      nextDue = nextDate!.copyWith(day: nextDate.day + offset);

      testNewToDo = testToDo.copyWith(
        startDate: nextDate,
        originalStart: nextDate,
        dueDate: nextDue,
        originalDue: nextDue,
      );

      expect(testNewToDo.startDate!, DateTime(2024, 1, 29),
          reason: "Date miscalculation");
      expect(testNewToDo.dueDate!, DateTime(2024, 1, 30),
          reason: "Date miscalculation");
    });

    test("Task Every two weeks 1 mo", () {
      ToDo testToDo = toDo.copyWith(frequency: Frequency.weekly, repeatSkip: 2);
      ToDo testNewToDo = testToDo.copy();

      expect(testToDo.startDate == testNewToDo.startDate, true,
          reason: "Copy Constructor failed");
      expect(testToDo.dueDate == testNewToDo.dueDate, true,
          reason: "Copy Constructor Failed");

      DateTime? nextDate = repeatableService!.getRepeatDate(model: testToDo);
      int offset = repeatableService!.getDateTimeDayOffset(
          start: testToDo.startDate, end: testToDo.dueDate);

      DateTime? nextDue = nextDate!.copyWith(day: nextDate.day + offset);

      testNewToDo = testToDo.copyWith(
        startDate: nextDate,
        originalStart: nextDate,
        dueDate: nextDue,
        originalDue: nextDue,
      );

      expect(testNewToDo.startDate!, DateTime(2024, 1, 15),
          reason: "Date miscalculation");
      expect(testNewToDo.dueDate!, DateTime(2024, 1, 16),
          reason: "Date miscalculation");

      testToDo = testNewToDo;

      nextDate = repeatableService!.getRepeatDate(model: testToDo);
      offset = repeatableService!.getDateTimeDayOffset(
          start: testToDo.startDate, end: testToDo.dueDate);

      nextDue = nextDate!.copyWith(day: nextDate.day + offset);

      testNewToDo = testToDo.copyWith(
        startDate: nextDate,
        originalStart: nextDate,
        dueDate: nextDue,
        originalDue: nextDue,
      );

      expect(testNewToDo.startDate!, DateTime(2024, 1, 29),
          reason: "Date miscalculation");
      expect(testNewToDo.dueDate!, DateTime(2024, 1, 30),
          reason: "Date miscalculation");
    });

    test("Task Every three weeks 2 mo", () {
      ToDo testToDo = toDo.copyWith(frequency: Frequency.weekly, repeatSkip: 3);
      ToDo testNewToDo = testToDo.copy();

      expect(testToDo.startDate == testNewToDo.startDate, true,
          reason: "Copy Constructor failed");
      expect(testToDo.dueDate == testNewToDo.dueDate, true,
          reason: "Copy Constructor Failed");

      DateTime? nextDate = repeatableService!.getRepeatDate(model: testToDo);
      int offset = repeatableService!.getDateTimeDayOffset(
          start: testToDo.startDate, end: testToDo.dueDate);

      DateTime? nextDue = nextDate!.copyWith(day: nextDate.day + offset);

      testNewToDo = testToDo.copyWith(
        startDate: nextDate,
        originalStart: nextDate,
        dueDate: nextDue,
        originalDue: nextDue,
      );

      expect(testNewToDo.startDate!, DateTime(2024, 1, 22),
          reason: "Date miscalculation");
      expect(testNewToDo.dueDate!, DateTime(2024, 1, 23),
          reason: "Date miscalculation");
      testToDo = testNewToDo;

      nextDate = repeatableService!.getRepeatDate(model: testToDo);
      offset = repeatableService!.getDateTimeDayOffset(
          start: testToDo.startDate, end: testToDo.dueDate);

      nextDue = nextDate!.copyWith(day: nextDate.day + offset);

      testNewToDo = testToDo.copyWith(
        startDate: nextDate,
        originalStart: nextDate,
        dueDate: nextDue,
        originalDue: nextDue,
      );

      expect(testNewToDo.startDate!, DateTime(2024, 2, 12),
          reason: "Date miscalculation");
      expect(testNewToDo.dueDate!, DateTime(2024, 2, 13),
          reason: "Date miscalculation");
    });

    test("Monthly Task 4 mo", () {
      ToDo testToDo =
          toDo.copyWith(frequency: Frequency.monthly, repeatSkip: 1);
      ToDo testNewToDo = testToDo.copy();

      expect(testToDo.startDate == testNewToDo.startDate, true,
          reason: "Copy Constructor failed");
      expect(testToDo.dueDate == testNewToDo.dueDate, true,
          reason: "Copy Constructor Failed");

      DateTime? nextDate = repeatableService!.getRepeatDate(model: testToDo);
      int offset = repeatableService!.getDateTimeDayOffset(
          start: testToDo.startDate, end: testToDo.dueDate);

      DateTime? nextDue = nextDate!.copyWith(day: nextDate.day + offset);

      testNewToDo = testToDo.copyWith(
        startDate: nextDate,
        originalStart: nextDate,
        dueDate: nextDue,
        originalDue: nextDue,
      );

      expect(testNewToDo.startDate!, DateTime(2024, 2, 1),
          reason: "Date miscalculation");
      expect(testNewToDo.dueDate!, DateTime(2024, 2, 2),
          reason: "Date miscalculation");

      testToDo = testNewToDo;

      nextDate = repeatableService!.getRepeatDate(model: testToDo);
      offset = repeatableService!.getDateTimeDayOffset(
          start: testToDo.startDate, end: testToDo.dueDate);

      nextDue = nextDate!.copyWith(day: nextDate.day + offset);

      testNewToDo = testToDo.copyWith(
        startDate: nextDate,
        originalStart: nextDate,
        dueDate: nextDue,
        originalDue: nextDue,
      );
      expect(testNewToDo.startDate!, DateTime(2024, 3, 1),
          reason: "Date miscalculation");
      expect(testNewToDo.dueDate!, DateTime(2024, 3, 2),
          reason: "Date miscalculation");

      testToDo = testNewToDo;

      nextDate = repeatableService!.getRepeatDate(model: testToDo);
      offset = repeatableService!.getDateTimeDayOffset(
          start: testToDo.startDate, end: testToDo.dueDate);

      nextDue = nextDate!.copyWith(day: nextDate.day + offset);

      testNewToDo = testToDo.copyWith(
        startDate: nextDate,
        originalStart: nextDate,
        dueDate: nextDue,
        originalDue: nextDue,
      );
      expect(testNewToDo.startDate!, DateTime(2024, 4, 1),
          reason: "Date miscalculation");
      expect(testNewToDo.dueDate!, DateTime(2024, 4, 2),
          reason: "Date miscalculation");
    });
    test("Task Every two months, 7 mo", () {
      ToDo testToDo =
          toDo.copyWith(frequency: Frequency.monthly, repeatSkip: 2);
      ToDo testNewToDo = testToDo.copy();

      expect(testToDo.startDate == testNewToDo.startDate, true,
          reason: "Copy Constructor failed");
      expect(testToDo.dueDate == testNewToDo.dueDate, true,
          reason: "Copy Constructor Failed");

      DateTime? nextDate = repeatableService!.getRepeatDate(model: testToDo);
      int offset = repeatableService!.getDateTimeDayOffset(
          start: testToDo.startDate, end: testToDo.dueDate);

      DateTime? nextDue = nextDate!.copyWith(day: nextDate.day + offset);

      testNewToDo = testToDo.copyWith(
        startDate: nextDate,
        originalStart: nextDate,
        dueDate: nextDue,
        originalDue: nextDue,
      );

      expect(testNewToDo.startDate!, DateTime(2024, 3, 1),
          reason: "Date miscalculation");
      expect(testNewToDo.dueDate!, DateTime(2024, 3, 2),
          reason: "Date miscalculation");

      testToDo = testNewToDo;

      nextDate = repeatableService!.getRepeatDate(model: testToDo);
      offset = repeatableService!.getDateTimeDayOffset(
          start: testToDo.startDate, end: testToDo.dueDate);

      nextDue = nextDate!.copyWith(day: nextDate.day + offset);

      testNewToDo = testToDo.copyWith(
        startDate: nextDate,
        originalStart: nextDate,
        dueDate: nextDue,
        originalDue: nextDue,
      );
      expect(testNewToDo.startDate!, DateTime(2024, 5, 1),
          reason: "Date miscalculation");
      expect(testNewToDo.dueDate!, DateTime(2024, 5, 2),
          reason: "Date miscalculation");

      testToDo = testNewToDo;

      nextDate = repeatableService!.getRepeatDate(model: testToDo);
      offset = repeatableService!.getDateTimeDayOffset(
          start: testToDo.startDate, end: testToDo.dueDate);

      nextDue = nextDate!.copyWith(day: nextDate.day + offset);

      testNewToDo = testToDo.copyWith(
        startDate: nextDate,
        originalStart: nextDate,
        dueDate: nextDue,
        originalDue: nextDue,
      );
      expect(testNewToDo.startDate!, DateTime(2024, 7, 1),
          reason: "Date miscalculation");
      expect(testNewToDo.dueDate!, DateTime(2024, 7, 2),
          reason: "Date miscalculation");
    });
    test("Task Every three months, 12 mo", () {
      ToDo testToDo =
          toDo.copyWith(frequency: Frequency.monthly, repeatSkip: 3);
      ToDo testNewToDo = testToDo.copy();

      expect(testToDo.startDate == testNewToDo.startDate, true,
          reason: "Copy Constructor failed");
      expect(testToDo.dueDate == testNewToDo.dueDate, true,
          reason: "Copy Constructor Failed");

      DateTime? nextDate = repeatableService!.getRepeatDate(model: testToDo);
      int offset = repeatableService!.getDateTimeDayOffset(
          start: testToDo.startDate, end: testToDo.dueDate);

      DateTime? nextDue = nextDate!.copyWith(day: nextDate.day + offset);

      testNewToDo = testToDo.copyWith(
        startDate: nextDate,
        originalStart: nextDate,
        dueDate: nextDue,
        originalDue: nextDue,
      );

      expect(testNewToDo.startDate!, DateTime(2024, 4, 1),
          reason: "Date miscalculation");
      expect(testNewToDo.dueDate!, DateTime(2024, 4, 2),
          reason: "Date miscalculation");

      testToDo = testNewToDo;

      nextDate = repeatableService!.getRepeatDate(model: testToDo);
      offset = repeatableService!.getDateTimeDayOffset(
          start: testToDo.startDate, end: testToDo.dueDate);

      nextDue = nextDate!.copyWith(day: nextDate.day + offset);

      testNewToDo = testToDo.copyWith(
        startDate: nextDate,
        originalStart: nextDate,
        dueDate: nextDue,
        originalDue: nextDue,
      );
      expect(testNewToDo.startDate!, DateTime(2024, 7, 1),
          reason: "Date miscalculation");
      expect(testNewToDo.dueDate!, DateTime(2024, 7, 2),
          reason: "Date miscalculation");

      testToDo = testNewToDo;

      nextDate = repeatableService!.getRepeatDate(model: testToDo);
      offset = repeatableService!.getDateTimeDayOffset(
          start: testToDo.startDate, end: testToDo.dueDate);

      nextDue = nextDate!.copyWith(day: nextDate.day + offset);

      testNewToDo = testToDo.copyWith(
        startDate: nextDate,
        originalStart: nextDate,
        dueDate: nextDue,
        originalDue: nextDue,
      );
      expect(testNewToDo.startDate!, DateTime(2024, 10, 1),
          reason: "Date miscalculation");
      expect(testNewToDo.dueDate!, DateTime(2024, 10, 2),
          reason: "Date miscalculation");
    });

    test("Yearly Task, 4 years", () {
      ToDo testToDo = toDo.copyWith(frequency: Frequency.yearly, repeatSkip: 1);
      ToDo testNewToDo = testToDo.copy();

      expect(testToDo.startDate == testNewToDo.startDate, true,
          reason: "Copy Constructor failed");
      expect(testToDo.dueDate == testNewToDo.dueDate, true,
          reason: "Copy Constructor Failed");

      DateTime? nextDate = repeatableService!.getRepeatDate(model: testToDo);
      int offset = repeatableService!.getDateTimeDayOffset(
          start: testToDo.startDate, end: testToDo.dueDate);

      DateTime? nextDue = nextDate!.copyWith(day: nextDate.day + offset);

      testNewToDo = testToDo.copyWith(
        startDate: nextDate,
        originalStart: nextDate,
        dueDate: nextDue,
        originalDue: nextDue,
      );

      expect(testNewToDo.startDate!, DateTime(2025, 1, 1),
          reason: "Date miscalculation");
      expect(testNewToDo.dueDate!, DateTime(2025, 1, 2),
          reason: "Date miscalculation");

      testToDo = testNewToDo;

      nextDate = repeatableService!.getRepeatDate(model: testToDo);
      offset = repeatableService!.getDateTimeDayOffset(
          start: testToDo.startDate, end: testToDo.dueDate);

      nextDue = nextDate!.copyWith(day: nextDate.day + offset);

      testNewToDo = testToDo.copyWith(
        startDate: nextDate,
        originalStart: nextDate,
        dueDate: nextDue,
        originalDue: nextDue,
      );

      expect(testNewToDo.startDate!, DateTime(2026, 1, 1),
          reason: "Date miscalculation");
      expect(testNewToDo.dueDate!, DateTime(2026, 1, 2),
          reason: "Date miscalculation");

      testToDo = testNewToDo;

      nextDate = repeatableService!.getRepeatDate(model: testToDo);
      offset = repeatableService!.getDateTimeDayOffset(
          start: testToDo.startDate, end: testToDo.dueDate);

      nextDue = nextDate!.copyWith(day: nextDate.day + offset);

      testNewToDo = testToDo.copyWith(
        startDate: nextDate,
        originalStart: nextDate,
        dueDate: nextDue,
        originalDue: nextDue,
      );

      expect(testNewToDo.startDate!, DateTime(2027, 1, 1),
          reason: "Date miscalculation");
      expect(testNewToDo.dueDate!, DateTime(2027, 1, 2),
          reason: "Date miscalculation");
      testToDo = testNewToDo;

      nextDate = repeatableService!.getRepeatDate(model: testToDo);
      offset = repeatableService!.getDateTimeDayOffset(
          start: testToDo.startDate, end: testToDo.dueDate);

      nextDue = nextDate!.copyWith(day: nextDate.day + offset);

      testNewToDo = testToDo.copyWith(
        startDate: nextDate,
        originalStart: nextDate,
        dueDate: nextDue,
        originalDue: nextDue,
      );

      expect(testNewToDo.startDate!, DateTime(2028, 1, 1),
          reason: "Date miscalculation");
      expect(testNewToDo.dueDate!, DateTime(2028, 1, 2),
          reason: "Date miscalculation");
      testToDo = testNewToDo;

      nextDate = repeatableService!.getRepeatDate(model: testToDo);
      offset = repeatableService!.getDateTimeDayOffset(
          start: testToDo.startDate, end: testToDo.dueDate);

      nextDue = nextDate!.copyWith(day: nextDate.day + offset);

      testNewToDo = testToDo.copyWith(
        startDate: nextDate,
        originalStart: nextDate,
        dueDate: nextDue,
        originalDue: nextDue,
      );
    });
    test("Task Every two years, 6 yrs", () {
      ToDo testToDo = toDo.copyWith(frequency: Frequency.yearly, repeatSkip: 2);
      ToDo testNewToDo = testToDo.copy();

      expect(testToDo.startDate == testNewToDo.startDate, true,
          reason: "Copy Constructor failed");
      expect(testToDo.dueDate == testNewToDo.dueDate, true,
          reason: "Copy Constructor Failed");

      DateTime? nextDate = repeatableService!.getRepeatDate(model: testToDo);
      int offset = repeatableService!.getDateTimeDayOffset(
          start: testToDo.startDate, end: testToDo.dueDate);

      DateTime? nextDue = nextDate!.copyWith(day: nextDate.day + offset);

      testNewToDo = testToDo.copyWith(
        startDate: nextDate,
        originalStart: nextDate,
        dueDate: nextDue,
        originalDue: nextDue,
      );

      expect(testNewToDo.startDate!, DateTime(2026, 1, 1),
          reason: "Date miscalculation");
      expect(testNewToDo.dueDate!, DateTime(2026, 1, 2),
          reason: "Date miscalculation");

      testToDo = testNewToDo;

      nextDate = repeatableService!.getRepeatDate(model: testToDo);
      offset = repeatableService!.getDateTimeDayOffset(
          start: testToDo.startDate, end: testToDo.dueDate);

      nextDue = nextDate!.copyWith(day: nextDate.day + offset);

      testNewToDo = testToDo.copyWith(
        startDate: nextDate,
        originalStart: nextDate,
        dueDate: nextDue,
        originalDue: nextDue,
      );

      expect(testNewToDo.startDate!, DateTime(2028, 1, 1),
          reason: "Date miscalculation");
      expect(testNewToDo.dueDate!, DateTime(2028, 1, 2),
          reason: "Date miscalculation");

      testToDo = testNewToDo;

      nextDate = repeatableService!.getRepeatDate(model: testToDo);
      offset = repeatableService!.getDateTimeDayOffset(
          start: testToDo.startDate, end: testToDo.dueDate);

      nextDue = nextDate!.copyWith(day: nextDate.day + offset);

      testNewToDo = testToDo.copyWith(
        startDate: nextDate,
        originalStart: nextDate,
        dueDate: nextDue,
        originalDue: nextDue,
      );

      expect(testNewToDo.startDate!, DateTime(2030, 1, 1),
          reason: "Date miscalculation");
      expect(testNewToDo.dueDate!, DateTime(2030, 1, 2),
          reason: "Date miscalculation");
    });
    test("Task Every three years, 9 yrs", () {
      ToDo testToDo = toDo.copyWith(frequency: Frequency.yearly, repeatSkip: 3);
      ToDo testNewToDo = testToDo.copy();

      expect(testToDo.startDate == testNewToDo.startDate, true,
          reason: "Copy Constructor failed");
      expect(testToDo.dueDate == testNewToDo.dueDate, true,
          reason: "Copy Constructor Failed");

      DateTime? nextDate = repeatableService!.getRepeatDate(model: testToDo);
      int offset = repeatableService!.getDateTimeDayOffset(
          start: testToDo.startDate, end: testToDo.dueDate);

      DateTime? nextDue = nextDate!.copyWith(day: nextDate.day + offset);

      testNewToDo = testToDo.copyWith(
        startDate: nextDate,
        originalStart: nextDate,
        dueDate: nextDue,
        originalDue: nextDue,
      );

      expect(testNewToDo.startDate!, DateTime(2027, 1, 1),
          reason: "Date miscalculation");
      expect(testNewToDo.dueDate!, DateTime(2027, 1, 2),
          reason: "Date miscalculation");

      testToDo = testNewToDo;

      nextDate = repeatableService!.getRepeatDate(model: testToDo);
      offset = repeatableService!.getDateTimeDayOffset(
          start: testToDo.startDate, end: testToDo.dueDate);

      nextDue = nextDate!.copyWith(day: nextDate.day + offset);

      testNewToDo = testToDo.copyWith(
        startDate: nextDate,
        originalStart: nextDate,
        dueDate: nextDue,
        originalDue: nextDue,
      );

      expect(testNewToDo.startDate!, DateTime(2030, 1, 1),
          reason: "Date miscalculation");
      expect(testNewToDo.dueDate!, DateTime(2030, 1, 2),
          reason: "Date miscalculation");

      testToDo = testNewToDo;

      nextDate = repeatableService!.getRepeatDate(model: testToDo);
      offset = repeatableService!.getDateTimeDayOffset(
          start: testToDo.startDate, end: testToDo.dueDate);

      nextDue = nextDate!.copyWith(day: nextDate.day + offset);

      testNewToDo = testToDo.copyWith(
        startDate: nextDate,
        originalStart: nextDate,
        dueDate: nextDue,
        originalDue: nextDue,
      );

      expect(testNewToDo.startDate!, DateTime(2033, 1, 1),
          reason: "Date miscalculation");
      expect(testNewToDo.dueDate!, DateTime(2033, 1, 2),
          reason: "Date miscalculation");
    });

    test("Invalid Dates Task", () {
      ToDo testToDo = toDo.copyWith(frequency: Frequency.daily, repeatSkip: 1);
      testToDo.startDate = null;
      testToDo.originalStart = null;
      testToDo.dueDate = null;
      testToDo.originalDue = null;
      ToDo testNewToDo = testToDo.copy();

      expect(testToDo.originalStart, null, reason: "Model not set");
      expect(testToDo.startDate, null, reason: "Model not set");
      expect(testNewToDo.originalStart, null,
          reason: "Copy constructor failed");
      expect(testNewToDo.startDate, null, reason: "Copy constructor failed");

      // This should be vaculously true
      expect(testToDo.startDate == testNewToDo.startDate, true,
          reason: "Copy Constructor failed");
      expect(testToDo.dueDate == testNewToDo.dueDate, true,
          reason: "Copy Constructor Failed");

      DateTime? nextDate = repeatableService!.getRepeatDate(model: testToDo);
      int offset = repeatableService!.getDateTimeDayOffset(
          start: testToDo.startDate, end: testToDo.dueDate);

      DateTime? nextDue = nextDate?.copyWith(day: nextDate.day + offset);
      expect(nextDate, null, reason: "getRepeatDate not returning null");
      expect(nextDue, null, reason: "getRepeatDate not returning null");
      expect(offset, 0, reason: "offset null not handled");

      testNewToDo = testToDo.copyWith(
        startDate: nextDate,
        originalStart: nextDate,
        dueDate: nextDue,
        originalDue: nextDue,
      );

      expect(testNewToDo.startDate, null, reason: "Null not handled");

      expect(testNewToDo.dueDate, null, reason: "Null not handled");

      testToDo = testNewToDo;

      nextDate = repeatableService!.getRepeatDate(model: testToDo);
      offset = repeatableService!.getDateTimeDayOffset(
          start: testToDo.startDate, end: testToDo.dueDate);

      nextDue = nextDate?.copyWith(day: nextDate.day + offset);

      testNewToDo = testToDo.copyWith(
        startDate: nextDate,
        originalStart: nextDate,
        dueDate: nextDue,
        originalDue: nextDue,
      );

      expect(testNewToDo.startDate, null, reason: "Null not handled");

      expect(testNewToDo.dueDate, null, reason: "Null not handled");
    });
  });

  // These are indexed 0-6 : Mon - Sun
  group("Get repeat date, custom date", () {
    ToDo toDo = ToDo(
        taskType: TaskType.small,
        name: 'Tester',
        expectedDuration: 0,
        originalStart: startDate,
        startDate: startDate,
        originalDue: dueDate,
        dueDate: dueDate,
        realDuration: 0,
        repeatSkip: 1,
        repeatDays: List.generate(7, (i) => false),
        lastUpdated: DateTime.now());

    test("Monday, Wednesday, Friday, every 1 week, 1yr", () {
      int numMonths = 12;
      int weeksPerMonth = 4;
      List<bool> repeatDays = [true, false, true, false, true, false, false];
      int oneWeek = 7;
      List<DateTime> originalValidTimes = [
        DateTime(2024, 1, 1),
        DateTime(2024, 1, 3),
        DateTime(2024, 1, 5)
      ];
      List<DateTime> validTimes = List.generate(
          originalValidTimes.length, (i) => originalValidTimes[i].copyWith());

      ToDo testToDo = toDo.copyWith(
        frequency: Frequency.custom,
        repeatDays: repeatDays,
      );

      ToDo newTestToDo = testToDo.copy();

      int numWeeksGenerated = weeksPerMonth ~/ testToDo.repeatSkip;
      int weekday = newTestToDo.startDate!.weekday - 1;

      expect(weekday & 1 == 0 && weekday < 6, true, reason: "offset error");
      // months * numDays * weeks. Start at 1, as Jan 1 is a monday.
      for (int i = 1;
          i < (numMonths * validTimes.length * numWeeksGenerated);
          i++) {
        DateTime? nextDate = repeatableService!.getRepeatDate(model: testToDo);
        int offset = repeatableService!.getDateTimeDayOffset(
            start: testToDo.originalStart, end: testToDo.originalDue);
        DateTime? nextDue = nextDate!.copyWith(day: nextDate.day + offset);
        newTestToDo = testToDo.copyWith(
            startDate: nextDate,
            originalStart: nextDate,
            dueDate: nextDue,
            originalDue: nextDue);
        weekday = newTestToDo.startDate!.weekday - 1;
        expect(weekday & 1 == 0 && weekday < 6, true,
            reason: "offset error, weekday: $weekday");
        expect(newTestToDo.startDate, validTimes[i % validTimes.length],
            reason: "offset error, index $i");

        testToDo = newTestToDo;

        if (i % validTimes.length == validTimes.length - 1) {
          for (int j = 0; j < validTimes.length; j++) {
            validTimes[j] =
                validTimes[j].copyWith(day: validTimes[j].day + oneWeek);
          }
        }
      }
    });
    test("Tuesday, Thursday, Saturday, every 1 week, 1yr", () {
      int numMonths = 12;
      int weeksPerMonth = 4;
      List<bool> repeatDays = [false, true, false, true, false, true, false];
      int oneWeek = 7;
      List<DateTime> originalValidTimes = [
        DateTime(2024, 1, 2),
        DateTime(2024, 1, 4),
        DateTime(2024, 1, 6),
      ];
      List<DateTime> validTimes = List.generate(
          originalValidTimes.length, (i) => originalValidTimes[i].copyWith());

      ToDo testToDo = toDo.copyWith(
        frequency: Frequency.custom,
        repeatDays: repeatDays,
      );

      ToDo newTestToDo = testToDo.copy();

      int numWeeksGenerated = weeksPerMonth ~/ testToDo.repeatSkip;
      int weekday = newTestToDo.startDate!.weekday - 1;

      // Total * num days * num weeks - 1, starting at 0;
      for (int i = 0;
          i < (numMonths * validTimes.length * numWeeksGenerated) - 1;
          i++) {
        DateTime? nextDate = repeatableService!.getRepeatDate(model: testToDo);
        int offset = repeatableService!.getDateTimeDayOffset(
            start: testToDo.originalStart, end: testToDo.originalDue);
        DateTime? nextDue = nextDate!.copyWith(day: nextDate.day + offset);
        newTestToDo = testToDo.copyWith(
            startDate: nextDate,
            originalStart: nextDate,
            dueDate: nextDue,
            originalDue: nextDue);
        weekday = newTestToDo.startDate!.weekday - 1;
        expect(weekday & 1 == 1 && weekday < 7, true,
            reason: "offset error, weekday: $weekday");
        expect(newTestToDo.startDate, validTimes[i % validTimes.length],
            reason: "offset error, index $i");

        testToDo = newTestToDo;

        if (i % validTimes.length == validTimes.length - 1) {
          for (int j = 0; j < validTimes.length; j++) {
            validTimes[j] =
                validTimes[j].copyWith(day: validTimes[j].day + oneWeek);
          }
        }
      }
    });
    test("Saturday, Sunday, every 1 week, 1 year", () {
      int numMonths = 12;
      int weeksPerMonth = 4;
      List<bool> repeatDays = [false, false, false, false, false, true, true];
      int oneWeek = 7;
      List<DateTime> originalValidTimes = [
        DateTime(2024, 1, 6),
        DateTime(2024, 1, 7),
      ];
      List<DateTime> validTimes = List.generate(
          originalValidTimes.length, (i) => originalValidTimes[i].copyWith());

      ToDo testToDo = toDo.copyWith(
        frequency: Frequency.custom,
        repeatDays: repeatDays,
      );

      ToDo newTestToDo = testToDo.copy();

      int numWeeksGenerated = weeksPerMonth ~/ testToDo.repeatSkip;
      int weekday = newTestToDo.startDate!.weekday - 1;

      // Num months * num days * num weeks - 1 as starting from zero
      for (int i = 0;
          i < (numMonths * validTimes.length * numWeeksGenerated) - 1;
          i++) {
        DateTime? nextDate = repeatableService!.getRepeatDate(model: testToDo);
        int offset = repeatableService!.getDateTimeDayOffset(
            start: testToDo.originalStart, end: testToDo.originalDue);
        DateTime? nextDue = nextDate!.copyWith(day: nextDate.day + offset);
        newTestToDo = testToDo.copyWith(
            startDate: nextDate,
            originalStart: nextDate,
            dueDate: nextDue,
            originalDue: nextDue);
        weekday = newTestToDo.startDate!.weekday - 1;
        expect(weekday == 5 || weekday == 6, true,
            reason: "offset error, weekday: $weekday");
        expect(newTestToDo.startDate, validTimes[i % validTimes.length],
            reason: "offset error, index $i");

        testToDo = newTestToDo;

        if (i % validTimes.length == validTimes.length - 1) {
          for (int j = 0; j < validTimes.length; j++) {
            validTimes[j] =
                validTimes[j].copyWith(day: validTimes[j].day + oneWeek);
          }
        }
      }
    });
    test("Sunday, Monday, every 1 week, 1 year", () {
      int numMonths = 12;
      int weeksPerMonth = 4;
      List<bool> repeatDays = [true, false, false, false, false, false, true];
      int oneWeek = 7;
      List<DateTime> originalValidTimes = [
        DateTime(2024, 1, 1),
        DateTime(2024, 1, 7),
      ];
      List<DateTime> validTimes = List.generate(
          originalValidTimes.length, (i) => originalValidTimes[i].copyWith());

      ToDo testToDo = toDo.copyWith(
        frequency: Frequency.custom,
        repeatDays: repeatDays,
      );

      ToDo newTestToDo = testToDo.copy();

      int numWeeksGenerated = weeksPerMonth ~/ testToDo.repeatSkip;
      int weekday = newTestToDo.startDate!.weekday - 1;

      // months * days per * weeks,
      for (int i = 1;
          i < numMonths * validTimes.length * numWeeksGenerated;
          i++) {
        DateTime? nextDate = repeatableService!.getRepeatDate(model: testToDo);
        int offset = repeatableService!.getDateTimeDayOffset(
            start: testToDo.originalStart, end: testToDo.originalDue);
        DateTime? nextDue = nextDate!.copyWith(day: nextDate.day + offset);
        newTestToDo = testToDo.copyWith(
            startDate: nextDate,
            originalStart: nextDate,
            dueDate: nextDue,
            originalDue: nextDue);
        weekday = newTestToDo.startDate!.weekday - 1;
        expect(weekday == 0 || weekday == 6, true,
            reason: "offset error, weekday: $weekday");
        expect(newTestToDo.startDate, validTimes[i % validTimes.length],
            reason: "offset error, index $i");

        testToDo = newTestToDo;

        if (i % validTimes.length == validTimes.length - 1) {
          for (int j = 0; j < validTimes.length; j++) {
            validTimes[j] =
                validTimes[j].copyWith(day: validTimes[j].day + oneWeek);
          }
        }
      }
    });

    test("Monday, Wednesday, Friday, every 2 weeks, 1 yr", () {
      int numMonths = 12;
      int weeksPerMonth = 4;
      List<bool> repeatDays = [true, false, true, false, true, false, false];
      int twoWeeks = 14;
      List<DateTime> originalValidTimes = [
        DateTime(2024, 1, 1),
        DateTime(2024, 1, 3),
        DateTime(2024, 1, 5)
      ];
      List<DateTime> validTimes = List.generate(
          originalValidTimes.length, (i) => originalValidTimes[i].copyWith());

      ToDo testToDo = toDo.copyWith(
        frequency: Frequency.custom,
        repeatDays: repeatDays,
        repeatSkip: 2,
      );

      ToDo newTestToDo = testToDo.copy();

      int numWeeksGenerated = weeksPerMonth ~/ testToDo.repeatSkip;
      int weekday = newTestToDo.startDate!.weekday - 1;

      expect(weekday & 1 == 0 && weekday < 6, true, reason: "offset error");
      // months * numDays * weeks. Start at 1, as Jan 1 is a monday.
      for (int i = 1;
          i < (numMonths * validTimes.length * numWeeksGenerated);
          i++) {
        DateTime? nextDate = repeatableService!.getRepeatDate(model: testToDo);
        int offset = repeatableService!.getDateTimeDayOffset(
            start: testToDo.originalStart, end: testToDo.originalDue);
        DateTime? nextDue = nextDate!.copyWith(day: nextDate.day + offset);
        newTestToDo = testToDo.copyWith(
            startDate: nextDate,
            originalStart: nextDate,
            dueDate: nextDue,
            originalDue: nextDue);
        weekday = newTestToDo.startDate!.weekday - 1;
        expect(weekday & 1 == 0 && weekday < 6, true,
            reason: "offset error, weekday: $weekday");
        expect(newTestToDo.startDate, validTimes[i % validTimes.length],
            reason: "offset error, index $i");

        testToDo = newTestToDo;

        if (i % validTimes.length == validTimes.length - 1) {
          for (int j = 0; j < validTimes.length; j++) {
            validTimes[j] =
                validTimes[j].copyWith(day: validTimes[j].day + twoWeeks);
          }
        }
      }
    });
    test("Tuesday, Thursday, Saturday, every 2 weeks", () {
      int numMonths = 12;
      int weeksPerMonth = 4;
      List<bool> repeatDays = [false, true, false, true, false, true, false];
      int twoWeeks = 14;
      List<DateTime> originalValidTimes = [
        DateTime(2024, 1, 2),
        DateTime(2024, 1, 4),
        DateTime(2024, 1, 6),
      ];
      List<DateTime> validTimes = List.generate(
          originalValidTimes.length, (i) => originalValidTimes[i].copyWith());

      ToDo testToDo = toDo.copyWith(
        frequency: Frequency.custom,
        repeatDays: repeatDays,
        repeatSkip: 2,
      );
      int numWeeksGenerated = weeksPerMonth ~/ testToDo.repeatSkip;
      ToDo newTestToDo = testToDo.copy();

      int weekday = newTestToDo.startDate!.weekday - 1;

      // Total * num days * num weeks - 1, starting at 0;
      for (int i = 0;
          i < (numMonths * validTimes.length * numWeeksGenerated) - 1;
          i++) {
        DateTime? nextDate = repeatableService!.getRepeatDate(model: testToDo);
        int offset = repeatableService!.getDateTimeDayOffset(
            start: testToDo.originalStart, end: testToDo.originalDue);
        DateTime? nextDue = nextDate!.copyWith(day: nextDate.day + offset);
        newTestToDo = testToDo.copyWith(
            startDate: nextDate,
            originalStart: nextDate,
            dueDate: nextDue,
            originalDue: nextDue);
        weekday = newTestToDo.startDate!.weekday - 1;
        expect(weekday & 1 == 1 && weekday < 7, true,
            reason: "offset error, weekday: $weekday");
        expect(newTestToDo.startDate, validTimes[i % validTimes.length],
            reason: "offset error, index $i");

        testToDo = newTestToDo;

        if (i % validTimes.length == validTimes.length - 1) {
          for (int j = 0; j < validTimes.length; j++) {
            validTimes[j] =
                validTimes[j].copyWith(day: validTimes[j].day + twoWeeks);
          }
        }
      }
    });
    test("Saturday, Sunday, every 2 weeks", () {
      int numMonths = 12;
      int weeksPerMonth = 4;
      List<bool> repeatDays = [false, false, false, false, false, true, true];
      int twoWeeks = 14;
      List<DateTime> originalValidTimes = [
        DateTime(2024, 1, 6),
        DateTime(2024, 1, 7),
      ];
      List<DateTime> validTimes = List.generate(
          originalValidTimes.length, (i) => originalValidTimes[i].copyWith());

      ToDo testToDo = toDo.copyWith(
        frequency: Frequency.custom,
        repeatDays: repeatDays,
        repeatSkip: 2,
      );

      ToDo newTestToDo = testToDo.copy();

      int numWeeksGenerated = weeksPerMonth ~/ testToDo.repeatSkip;
      int weekday = newTestToDo.startDate!.weekday - 1;

      // Num months * num days * num weeks - 1 as starting from zero
      for (int i = 0;
          i < (numMonths * validTimes.length * numWeeksGenerated) - 1;
          i++) {
        DateTime? nextDate = repeatableService!.getRepeatDate(model: testToDo);
        int offset = repeatableService!.getDateTimeDayOffset(
            start: testToDo.originalStart, end: testToDo.originalDue);
        DateTime? nextDue = nextDate!.copyWith(day: nextDate.day + offset);
        newTestToDo = testToDo.copyWith(
            startDate: nextDate,
            originalStart: nextDate,
            dueDate: nextDue,
            originalDue: nextDue);
        weekday = newTestToDo.startDate!.weekday - 1;
        expect(weekday == 5 || weekday == 6, true,
            reason: "offset error, weekday: $weekday");
        expect(newTestToDo.startDate, validTimes[i % validTimes.length],
            reason: "offset error, index $i");

        testToDo = newTestToDo;

        if (i % validTimes.length == validTimes.length - 1) {
          for (int j = 0; j < validTimes.length; j++) {
            validTimes[j] =
                validTimes[j].copyWith(day: validTimes[j].day + twoWeeks);
          }
        }
      }
    });
    test("Sunday, Monday, every 2 weeks", () {
      int numMonths = 12;
      int weeksPerMonth = 4;
      List<bool> repeatDays = [true, false, false, false, false, false, true];
      int twoWeeks = 14;
      List<DateTime> originalValidTimes = [
        DateTime(2024, 1, 1),
        DateTime(2024, 1, 7),
      ];
      List<DateTime> validTimes = List.generate(
          originalValidTimes.length, (i) => originalValidTimes[i].copyWith());

      ToDo testToDo = toDo.copyWith(
        frequency: Frequency.custom,
        repeatDays: repeatDays,
        repeatSkip: 2,
      );

      ToDo newTestToDo = testToDo.copy();

      int numWeeksGenerated = weeksPerMonth ~/ testToDo.repeatSkip;
      int weekday = newTestToDo.startDate!.weekday - 1;

      // months * days per * weeks,
      for (int i = 1;
          i < numMonths * validTimes.length * numWeeksGenerated;
          i++) {
        DateTime? nextDate = repeatableService!.getRepeatDate(model: testToDo);
        int offset = repeatableService!.getDateTimeDayOffset(
            start: testToDo.originalStart, end: testToDo.originalDue);
        DateTime? nextDue = nextDate!.copyWith(day: nextDate.day + offset);
        newTestToDo = testToDo.copyWith(
            startDate: nextDate,
            originalStart: nextDate,
            dueDate: nextDue,
            originalDue: nextDue);
        weekday = newTestToDo.startDate!.weekday - 1;
        expect(weekday == 0 || weekday == 6, true,
            reason: "offset error, weekday: $weekday");
        expect(newTestToDo.startDate, validTimes[i % validTimes.length],
            reason: "offset error, index $i");

        testToDo = newTestToDo;

        if (i % validTimes.length == validTimes.length - 1) {
          for (int j = 0; j < validTimes.length; j++) {
            validTimes[j] =
                validTimes[j].copyWith(day: validTimes[j].day + twoWeeks);
          }
        }
      }
    });

    test("Monday, Wednesday, Friday, every 3 weeks", () {
      int numMonths = 12;
      int weeksPerMonth = 4;
      List<bool> repeatDays = [true, false, true, false, true, false, false];
      int threeWeeks = 21;
      List<DateTime> originalValidTimes = [
        DateTime(2024, 1, 1),
        DateTime(2024, 1, 3),
        DateTime(2024, 1, 5)
      ];
      List<DateTime> validTimes = List.generate(
          originalValidTimes.length, (i) => originalValidTimes[i].copyWith());

      ToDo testToDo = toDo.copyWith(
        frequency: Frequency.custom,
        repeatDays: repeatDays,
        repeatSkip: 3,
      );

      ToDo newTestToDo = testToDo.copy();

      int numWeeksGenerated = weeksPerMonth ~/ testToDo.repeatSkip;
      int weekday = newTestToDo.startDate!.weekday - 1;

      expect(weekday & 1 == 0 && weekday < 6, true, reason: "offset error");
      // months * numDays * weeks. Start at 1, as Jan 1 is a monday.
      for (int i = 1;
          i < (numMonths * validTimes.length * numWeeksGenerated);
          i++) {
        DateTime? nextDate = repeatableService!.getRepeatDate(model: testToDo);
        int offset = repeatableService!.getDateTimeDayOffset(
            start: testToDo.originalStart, end: testToDo.originalDue);
        DateTime? nextDue = nextDate!.copyWith(day: nextDate.day + offset);
        newTestToDo = testToDo.copyWith(
            startDate: nextDate,
            originalStart: nextDate,
            dueDate: nextDue,
            originalDue: nextDue);
        weekday = newTestToDo.startDate!.weekday - 1;
        expect(weekday & 1 == 0 && weekday < 6, true,
            reason: "offset error, weekday: $weekday");
        expect(newTestToDo.startDate, validTimes[i % validTimes.length],
            reason: "offset error, index $i");

        testToDo = newTestToDo;

        if (i % validTimes.length == validTimes.length - 1) {
          for (int j = 0; j < validTimes.length; j++) {
            validTimes[j] =
                validTimes[j].copyWith(day: validTimes[j].day + threeWeeks);
          }
        }
      }
    });
    test("Tuesday, Thursday, Saturday, every 3 weeks", () {
      int numMonths = 12;
      int weeksPerMonth = 4;
      List<bool> repeatDays = [false, true, false, true, false, true, false];
      int threeWeeks = 21;
      List<DateTime> originalValidTimes = [
        DateTime(2024, 1, 2),
        DateTime(2024, 1, 4),
        DateTime(2024, 1, 6),
      ];
      List<DateTime> validTimes = List.generate(
          originalValidTimes.length, (i) => originalValidTimes[i].copyWith());

      ToDo testToDo = toDo.copyWith(
          frequency: Frequency.custom, repeatDays: repeatDays, repeatSkip: 3);
      int numWeeksGenerated = weeksPerMonth ~/ testToDo.repeatSkip;
      ToDo newTestToDo = testToDo.copy();

      int weekday = newTestToDo.startDate!.weekday - 1;

      // Total * num days * num weeks - 1, starting at 0;
      for (int i = 0;
          i < (numMonths * validTimes.length * numWeeksGenerated) - 1;
          i++) {
        DateTime? nextDate = repeatableService!.getRepeatDate(model: testToDo);
        int offset = repeatableService!.getDateTimeDayOffset(
            start: testToDo.originalStart, end: testToDo.originalDue);
        DateTime? nextDue = nextDate!.copyWith(day: nextDate.day + offset);
        newTestToDo = testToDo.copyWith(
            startDate: nextDate,
            originalStart: nextDate,
            dueDate: nextDue,
            originalDue: nextDue);
        weekday = newTestToDo.startDate!.weekday - 1;
        expect(weekday & 1 == 1 && weekday < 7, true,
            reason: "offset error, weekday: $weekday");
        expect(newTestToDo.startDate, validTimes[i % validTimes.length],
            reason: "offset error, index $i");

        testToDo = newTestToDo;

        if (i % validTimes.length == validTimes.length - 1) {
          for (int j = 0; j < validTimes.length; j++) {
            validTimes[j] =
                validTimes[j].copyWith(day: validTimes[j].day + threeWeeks);
          }
        }
      }
    });
    test("Saturday, Sunday, every 3 weeks", () {
      int numMonths = 12;
      int weeksPerMonth = 4;
      List<bool> repeatDays = [false, false, false, false, false, true, true];
      int threeWeeks = 21;
      List<DateTime> originalValidTimes = [
        DateTime(2024, 1, 6),
        DateTime(2024, 1, 7),
      ];
      List<DateTime> validTimes = List.generate(
          originalValidTimes.length, (i) => originalValidTimes[i].copyWith());

      ToDo testToDo = toDo.copyWith(
        frequency: Frequency.custom,
        repeatDays: repeatDays,
        repeatSkip: 3,
      );

      ToDo newTestToDo = testToDo.copy();

      int numWeeksGenerated = weeksPerMonth ~/ testToDo.repeatSkip;
      int weekday = newTestToDo.startDate!.weekday - 1;

      // Num months * num days * num weeks - 1 as starting from zero
      for (int i = 0;
          i < (numMonths * validTimes.length * numWeeksGenerated) - 1;
          i++) {
        DateTime? nextDate = repeatableService!.getRepeatDate(model: testToDo);
        int offset = repeatableService!.getDateTimeDayOffset(
            start: testToDo.originalStart, end: testToDo.originalDue);
        DateTime? nextDue = nextDate!.copyWith(day: nextDate.day + offset);
        newTestToDo = testToDo.copyWith(
            startDate: nextDate,
            originalStart: nextDate,
            dueDate: nextDue,
            originalDue: nextDue);
        weekday = newTestToDo.startDate!.weekday - 1;
        expect(weekday == 5 || weekday == 6, true,
            reason: "offset error, weekday: $weekday");
        expect(newTestToDo.startDate, validTimes[i % validTimes.length],
            reason: "offset error, index $i");

        testToDo = newTestToDo;

        if (i % validTimes.length == validTimes.length - 1) {
          for (int j = 0; j < validTimes.length; j++) {
            validTimes[j] =
                validTimes[j].copyWith(day: validTimes[j].day + threeWeeks);
          }
        }
      }
    });
    test("Sunday, Monday, every 3 weeks", () {
      int numMonths = 12;
      int weeksPerMonth = 4;
      List<bool> repeatDays = [true, false, false, false, false, false, true];
      int threeWeeks = 21;
      List<DateTime> originalValidTimes = [
        DateTime(2024, 1, 1),
        DateTime(2024, 1, 7),
      ];
      List<DateTime> validTimes = List.generate(
          originalValidTimes.length, (i) => originalValidTimes[i].copyWith());

      ToDo testToDo = toDo.copyWith(
        frequency: Frequency.custom,
        repeatDays: repeatDays,
        repeatSkip: 3,
      );

      ToDo newTestToDo = testToDo.copy();

      int numWeeksGenerated = weeksPerMonth ~/ testToDo.repeatSkip;
      int weekday = newTestToDo.startDate!.weekday - 1;

      // months * days per * weeks,
      for (int i = 1;
          i < numMonths * validTimes.length * numWeeksGenerated;
          i++) {
        DateTime? nextDate = repeatableService!.getRepeatDate(model: testToDo);
        int offset = repeatableService!.getDateTimeDayOffset(
            start: testToDo.originalStart, end: testToDo.originalDue);
        DateTime? nextDue = nextDate!.copyWith(day: nextDate.day + offset);
        newTestToDo = testToDo.copyWith(
            startDate: nextDate,
            originalStart: nextDate,
            dueDate: nextDue,
            originalDue: nextDue);
        weekday = newTestToDo.startDate!.weekday - 1;
        expect(weekday == 0 || weekday == 6, true,
            reason: "offset error, weekday: $weekday");
        expect(newTestToDo.startDate, validTimes[i % validTimes.length],
            reason: "offset error, index $i");

        testToDo = newTestToDo;

        if (i % validTimes.length == validTimes.length - 1) {
          for (int j = 0; j < validTimes.length; j++) {
            validTimes[j] =
                validTimes[j].copyWith(day: validTimes[j].day + threeWeeks);
          }
        }
      }
    });

    test("Monday, Wednesday, Friday, every 4 weeks", () {
      int numMonths = 12;
      int weeksPerMonth = 4;
      List<bool> repeatDays = [true, false, true, false, true, false, false];
      int fourWeeks = 28;
      List<DateTime> originalValidTimes = [
        DateTime(2024, 1, 1),
        DateTime(2024, 1, 3),
        DateTime(2024, 1, 5)
      ];
      List<DateTime> validTimes = List.generate(
          originalValidTimes.length, (i) => originalValidTimes[i].copyWith());

      ToDo testToDo = toDo.copyWith(
        frequency: Frequency.custom,
        repeatDays: repeatDays,
        repeatSkip: 4,
      );

      ToDo newTestToDo = testToDo.copy();

      int numWeeksGenerated = weeksPerMonth ~/ testToDo.repeatSkip;
      int weekday = newTestToDo.startDate!.weekday - 1;

      expect(weekday & 1 == 0 && weekday < 6, true, reason: "offset error");
      // months * numDays * weeks. Start at 1, as Jan 1 is a monday.
      for (int i = 1;
          i < (numMonths * validTimes.length * numWeeksGenerated);
          i++) {
        DateTime? nextDate = repeatableService!.getRepeatDate(model: testToDo);
        int offset = repeatableService!.getDateTimeDayOffset(
            start: testToDo.originalStart, end: testToDo.originalDue);
        DateTime? nextDue = nextDate!.copyWith(day: nextDate.day + offset);
        newTestToDo = testToDo.copyWith(
            startDate: nextDate,
            originalStart: nextDate,
            dueDate: nextDue,
            originalDue: nextDue);
        weekday = newTestToDo.startDate!.weekday - 1;
        expect(weekday & 1 == 0 && weekday < 6, true,
            reason: "offset error, weekday: $weekday");
        expect(newTestToDo.startDate, validTimes[i % validTimes.length],
            reason: "offset error, index $i");

        testToDo = newTestToDo;

        if (i % validTimes.length == validTimes.length - 1) {
          for (int j = 0; j < validTimes.length; j++) {
            validTimes[j] =
                validTimes[j].copyWith(day: validTimes[j].day + fourWeeks);
          }
        }
      }
    });
    test("Tuesday, Thursday, Saturday, every 4 weeks", () {
      int numMonths = 12;
      int weeksPerMonth = 4;
      List<bool> repeatDays = [false, true, false, true, false, true, false];
      int fourWeeks = 28;
      List<DateTime> originalValidTimes = [
        DateTime(2024, 1, 2),
        DateTime(2024, 1, 4),
        DateTime(2024, 1, 6),
      ];
      List<DateTime> validTimes = List.generate(
          originalValidTimes.length, (i) => originalValidTimes[i].copyWith());

      ToDo testToDo = toDo.copyWith(
        frequency: Frequency.custom,
        repeatDays: repeatDays,
        repeatSkip: 4,
      );
      int numWeeksGenerated = weeksPerMonth ~/ testToDo.repeatSkip;
      ToDo newTestToDo = testToDo.copy();

      int weekday = newTestToDo.startDate!.weekday - 1;

      // Total * num days * num weeks - 1, starting at 0;
      for (int i = 0;
          i < (numMonths * validTimes.length * numWeeksGenerated) - 1;
          i++) {
        DateTime? nextDate = repeatableService!.getRepeatDate(model: testToDo);
        int offset = repeatableService!.getDateTimeDayOffset(
            start: testToDo.originalStart, end: testToDo.originalDue);
        DateTime? nextDue = nextDate!.copyWith(day: nextDate.day + offset);
        newTestToDo = testToDo.copyWith(
            startDate: nextDate,
            originalStart: nextDate,
            dueDate: nextDue,
            originalDue: nextDue);
        weekday = newTestToDo.startDate!.weekday - 1;
        expect(weekday & 1 == 1 && weekday < 7, true,
            reason: "offset error, weekday: $weekday");
        expect(newTestToDo.startDate, validTimes[i % validTimes.length],
            reason: "offset error, index $i");

        testToDo = newTestToDo;

        if (i % validTimes.length == validTimes.length - 1) {
          for (int j = 0; j < validTimes.length; j++) {
            validTimes[j] =
                validTimes[j].copyWith(day: validTimes[j].day + fourWeeks);
          }
        }
      }
    });
    test("Saturday, Sunday, every 4 weeks", () {
      int numMonths = 12;
      int weeksPerMonth = 4;
      List<bool> repeatDays = [false, false, false, false, false, true, true];
      int fourWeeks = 28;
      List<DateTime> originalValidTimes = [
        DateTime(2024, 1, 6),
        DateTime(2024, 1, 7),
      ];
      List<DateTime> validTimes = List.generate(
          originalValidTimes.length, (i) => originalValidTimes[i].copyWith());

      ToDo testToDo = toDo.copyWith(
        frequency: Frequency.custom,
        repeatDays: repeatDays,
        repeatSkip: 4,
      );

      ToDo newTestToDo = testToDo.copy();

      int numWeeksGenerated = weeksPerMonth ~/ testToDo.repeatSkip;
      int weekday = newTestToDo.startDate!.weekday - 1;

      // Num months * num days * num weeks - 1 as starting from zero
      for (int i = 0;
          i < (numMonths * validTimes.length * numWeeksGenerated) - 1;
          i++) {
        DateTime? nextDate = repeatableService!.getRepeatDate(model: testToDo);
        int offset = repeatableService!.getDateTimeDayOffset(
            start: testToDo.originalStart, end: testToDo.originalDue);
        DateTime? nextDue = nextDate!.copyWith(day: nextDate.day + offset);
        newTestToDo = testToDo.copyWith(
            startDate: nextDate,
            originalStart: nextDate,
            dueDate: nextDue,
            originalDue: nextDue);
        weekday = newTestToDo.startDate!.weekday - 1;
        expect(weekday == 5 || weekday == 6, true,
            reason: "offset error, weekday: $weekday");
        expect(newTestToDo.startDate, validTimes[i % validTimes.length],
            reason: "offset error, index $i");

        testToDo = newTestToDo;

        if (i % validTimes.length == validTimes.length - 1) {
          for (int j = 0; j < validTimes.length; j++) {
            validTimes[j] =
                validTimes[j].copyWith(day: validTimes[j].day + fourWeeks);
          }
        }
      }
    });
    test("Sunday, Monday, every 4 weeks", () {
      int numMonths = 12;
      int weeksPerMonth = 4;
      List<bool> repeatDays = [true, false, false, false, false, false, true];
      int fourWeeks = 28;
      List<DateTime> originalValidTimes = [
        DateTime(2024, 1, 1),
        DateTime(2024, 1, 7),
      ];
      List<DateTime> validTimes = List.generate(
          originalValidTimes.length, (i) => originalValidTimes[i].copyWith());

      ToDo testToDo = toDo.copyWith(
        frequency: Frequency.custom,
        repeatDays: repeatDays,
        repeatSkip: 4,
      );

      ToDo newTestToDo = testToDo.copy();

      int numWeeksGenerated = weeksPerMonth ~/ testToDo.repeatSkip;
      int weekday = newTestToDo.startDate!.weekday - 1;

      // months * days per * weeks,
      for (int i = 1;
          i < numMonths * validTimes.length * numWeeksGenerated;
          i++) {
        DateTime? nextDate = repeatableService!.getRepeatDate(model: testToDo);
        int offset = repeatableService!.getDateTimeDayOffset(
            start: testToDo.originalStart, end: testToDo.originalDue);
        DateTime? nextDue = nextDate!.copyWith(day: nextDate.day + offset);
        newTestToDo = testToDo.copyWith(
            startDate: nextDate,
            originalStart: nextDate,
            dueDate: nextDue,
            originalDue: nextDue);
        weekday = newTestToDo.startDate!.weekday - 1;
        expect(weekday == 0 || weekday == 6, true,
            reason: "offset error, weekday: $weekday");
        expect(newTestToDo.startDate, validTimes[i % validTimes.length],
            reason: "offset error, index $i");

        testToDo = newTestToDo;

        if (i % validTimes.length == validTimes.length - 1) {
          for (int j = 0; j < validTimes.length; j++) {
            validTimes[j] =
                validTimes[j].copyWith(day: validTimes[j].day + fourWeeks);
          }
        }
      }
    });

    // Integer arithmetic will fail on weeks > 4
    // Need to divide at the end.
    test("Monday, Wednesday, Friday, every 5 weeks, 1 yr", () {
      int numMonths = 12;
      int weeksPerMonth = 4;
      List<bool> repeatDays = [true, false, true, false, true, false, false];
      int fiveWeeks = 35;
      List<DateTime> originalValidTimes = [
        DateTime(2024, 1, 1),
        DateTime(2024, 1, 3),
        DateTime(2024, 1, 5)
      ];
      List<DateTime> validTimes = List.generate(
          originalValidTimes.length, (i) => originalValidTimes[i].copyWith());

      ToDo testToDo = toDo.copyWith(
        frequency: Frequency.custom,
        repeatDays: repeatDays,
        repeatSkip: 5,
      );

      ToDo newTestToDo = testToDo.copy();

      int weekday = newTestToDo.startDate!.weekday - 1;

      expect(weekday & 1 == 0 && weekday < 6, true, reason: "offset error");
      // months * numDays * weeks. Start at 1, as Jan 1 is a monday.
      for (int i = 1;
          i <
              ((numMonths * weeksPerMonth * validTimes.length) ~/
                  newTestToDo.repeatSkip);
          i++) {
        DateTime? nextDate = repeatableService!.getRepeatDate(model: testToDo);
        int offset = repeatableService!.getDateTimeDayOffset(
            start: testToDo.originalStart, end: testToDo.originalDue);
        DateTime? nextDue = nextDate!.copyWith(day: nextDate.day + offset);
        newTestToDo = testToDo.copyWith(
            startDate: nextDate,
            originalStart: nextDate,
            dueDate: nextDue,
            originalDue: nextDue);
        weekday = newTestToDo.startDate!.weekday - 1;
        expect(weekday & 1 == 0 && weekday < 6, true,
            reason: "offset error, weekday: $weekday");
        expect(newTestToDo.startDate, validTimes[i % validTimes.length],
            reason: "offset error, index $i");

        testToDo = newTestToDo;

        if (i % validTimes.length == validTimes.length - 1) {
          for (int j = 0; j < validTimes.length; j++) {
            validTimes[j] =
                validTimes[j].copyWith(day: validTimes[j].day + fiveWeeks);
          }
        }
      }
    });
    test("Tuesday, Thursday, Saturday, every 5 weeks", () {
      int numMonths = 12;
      int weeksPerMonth = 4;
      List<bool> repeatDays = [false, true, false, true, false, true, false];
      int fiveWeeks = 35;
      List<DateTime> originalValidTimes = [
        DateTime(2024, 1, 2),
        DateTime(2024, 1, 4),
        DateTime(2024, 1, 6),
      ];
      List<DateTime> validTimes = List.generate(
          originalValidTimes.length, (i) => originalValidTimes[i].copyWith());

      ToDo testToDo = toDo.copyWith(
        frequency: Frequency.custom,
        repeatDays: repeatDays,
        repeatSkip: 5,
      );
      ToDo newTestToDo = testToDo.copy();

      int weekday = newTestToDo.startDate!.weekday - 1;

      // Total * num days * num weeks - 1, starting at 0;
      for (int i = 0;
          i <
              ((numMonths * validTimes.length * weeksPerMonth) ~/
                      newTestToDo.repeatSkip) -
                  1;
          i++) {
        DateTime? nextDate = repeatableService!.getRepeatDate(model: testToDo);
        int offset = repeatableService!.getDateTimeDayOffset(
            start: testToDo.originalStart, end: testToDo.originalDue);
        DateTime? nextDue = nextDate!.copyWith(day: nextDate.day + offset);
        newTestToDo = testToDo.copyWith(
            startDate: nextDate,
            originalStart: nextDate,
            dueDate: nextDue,
            originalDue: nextDue);
        weekday = newTestToDo.startDate!.weekday - 1;
        expect(weekday & 1 == 1 && weekday < 7, true,
            reason: "offset error, weekday: $weekday");
        expect(newTestToDo.startDate, validTimes[i % validTimes.length],
            reason: "offset error, index $i");

        testToDo = newTestToDo;

        if (i % validTimes.length == validTimes.length - 1) {
          for (int j = 0; j < validTimes.length; j++) {
            validTimes[j] =
                validTimes[j].copyWith(day: validTimes[j].day + fiveWeeks);
          }
        }
      }
    });
    test("Saturday, Sunday, every 5 weeks", () {
      int numMonths = 12;
      int weeksPerMonth = 4;
      List<bool> repeatDays = [false, false, false, false, false, true, true];
      int fiveWeeks = 35;
      List<DateTime> originalValidTimes = [
        DateTime(2024, 1, 6),
        DateTime(2024, 1, 7),
      ];
      List<DateTime> validTimes = List.generate(
          originalValidTimes.length, (i) => originalValidTimes[i].copyWith());

      ToDo testToDo = toDo.copyWith(
        frequency: Frequency.custom,
        repeatDays: repeatDays,
        repeatSkip: 5,
      );

      ToDo newTestToDo = testToDo.copy();

      int weekday = newTestToDo.startDate!.weekday - 1;

      // Num months * num days * num weeks - 1 as starting from zero
      for (int i = 0;
          i <
              ((numMonths * validTimes.length * weeksPerMonth) ~/
                      newTestToDo.repeatSkip) -
                  1;
          i++) {
        DateTime? nextDate = repeatableService!.getRepeatDate(model: testToDo);
        int offset = repeatableService!.getDateTimeDayOffset(
            start: testToDo.originalStart, end: testToDo.originalDue);
        DateTime? nextDue = nextDate!.copyWith(day: nextDate.day + offset);
        newTestToDo = testToDo.copyWith(
            startDate: nextDate,
            originalStart: nextDate,
            dueDate: nextDue,
            originalDue: nextDue);
        weekday = newTestToDo.startDate!.weekday - 1;
        expect(weekday == 5 || weekday == 6, true,
            reason: "offset error, weekday: $weekday");
        expect(newTestToDo.startDate, validTimes[i % validTimes.length],
            reason: "offset error, index $i");

        testToDo = newTestToDo;

        if (i % validTimes.length == validTimes.length - 1) {
          for (int j = 0; j < validTimes.length; j++) {
            validTimes[j] =
                validTimes[j].copyWith(day: validTimes[j].day + fiveWeeks);
          }
        }
      }
    });
    test("Sunday, Monday, every 5 weeks", () {
      int numMonths = 12;
      int weeksPerMonth = 4;
      List<bool> repeatDays = [true, false, false, false, false, false, true];
      int fiveWeeks = 35;
      List<DateTime> originalValidTimes = [
        DateTime(2024, 1, 1),
        DateTime(2024, 1, 7),
      ];
      List<DateTime> validTimes = List.generate(
          originalValidTimes.length, (i) => originalValidTimes[i].copyWith());

      ToDo testToDo = toDo.copyWith(
        frequency: Frequency.custom,
        repeatDays: repeatDays,
        repeatSkip: 5,
      );

      ToDo newTestToDo = testToDo.copy();

      int weekday = newTestToDo.startDate!.weekday - 1;

      // months * days per * weeks,
      for (int i = 1;
          i <
              (numMonths * validTimes.length * weeksPerMonth) ~/
                  newTestToDo.repeatSkip;
          i++) {
        DateTime? nextDate = repeatableService!.getRepeatDate(model: testToDo);
        int offset = repeatableService!.getDateTimeDayOffset(
            start: testToDo.originalStart, end: testToDo.originalDue);
        DateTime? nextDue = nextDate!.copyWith(day: nextDate.day + offset);
        newTestToDo = testToDo.copyWith(
            startDate: nextDate,
            originalStart: nextDate,
            dueDate: nextDue,
            originalDue: nextDue);
        weekday = newTestToDo.startDate!.weekday - 1;
        expect(weekday == 0 || weekday == 6, true,
            reason: "offset error, weekday: $weekday");
        expect(newTestToDo.startDate, validTimes[i % validTimes.length],
            reason: "offset error, index $i");

        testToDo = newTestToDo;

        if (i % validTimes.length == validTimes.length - 1) {
          for (int j = 0; j < validTimes.length; j++) {
            validTimes[j] =
                validTimes[j].copyWith(day: validTimes[j].day + fiveWeeks);
          }
        }
      }
    });
  });

  setUp(initIsar);
  tearDown(disposeIsar);
  // Isar tests
  group("Current Model, mutate single", () {
    // Tasks
    ToDo toDo = ToDo(
        taskType: TaskType.small,
        name: 'Tester',
        expectedDuration: 0,
        originalStart: startDate,
        startDate: startDate,
        originalDue: dueDate,
        dueDate: dueDate,
        frequency: Frequency.daily,
        realDuration: 0,
        repeatSkip: 1,
        repeatable: true,
        repeatDays: List.generate(7, (i) => false),
        lastUpdated: DateTime.now());

    Deadline deadline = Deadline(
        name: 'Tester',
        repeatable: true,
        startDate: startDate,
        originalStart: startDate,
        dueDate: dueDate,
        originalDue: dueDate,
        frequency: Frequency.daily,
        repeatSkip: 1,
        repeatDays: List.generate(7, (i) => false),
        lastUpdated: DateTime.now());

    Reminder reminder = Reminder(
        name: "Tester",
        repeatDays: List.generate(7, (i) => false),
        dueDate: startDate,
        originalDue: startDate,
        repeatable: true,
        frequency: Frequency.daily,
        repeatSkip: 1,
        lastUpdated: DateTime.now());

    test("ToDo test, daily occurrence, 4 days, mutate day 2", () async {
      ToDo testToDo = toDo.copyWith(repeatID: Constants.generateID());
      ToDo? template =
          testToDo.copyWith(repeatableState: RepeatableState.template);
      await toDoRepo!.updateBatch([testToDo, template]);

      template = await toDoRepo!.getTemplate(repeatID: testToDo.repeatID!);
      expect(null != template, true, reason: "Likely a race condition");

      // Due to back-generation (ie. after midnight, check all outdated repeats),
      // This needs to run for 5 days to generate 4 events.
      DateTime limit = DateTime(2024, 1, 5);
      DateTime startDate = DateTime(2024, 1, 1);

      ToDo? testMutate;
      List<ToDo> repeatables = [];
      while (startDate.isBefore(limit)) {
        repeatables = await toDoRepo!.getRepeatables(now: startDate);
        for (ToDo repeatable in repeatables) {
          if (repeatable.startDate == DateTime(2024, 1, 2)) {
            testMutate = repeatable;
          }
          await repeatableService!.nextRepeat(model: repeatable);
        }
        startDate = startDate.copyWith(day: startDate.day + 1);
      }

      List<ToDo> toDos = await toDoRepo!.getRepoList();

      expect(toDos.length, 4, reason: "Generated too many/few");

      expect(null != testMutate, true, reason: "repeatables set improperly");

      ToDo? testQuery = await toDoRepo!.getByID(id: testMutate!.id);
      expect(null != testQuery, true, reason: "ToDo not properly stored");

      // suppose some data has been changed, "update single."
      testQuery!.weight = 4;
      // These are just arbitrary numbers
      testQuery.expectedDuration = 1000;
      testQuery.realDuration = 1000;
      testQuery.startDate = testQuery.dueDate!;
      await repeatableService!
          .handleRepeating(model: testQuery, delete: false, single: true);

      await toDoRepo!.update(testQuery);

      // Generate another date. Get repo by dueDate desc. assert that the 1st element has startDate jan 5
      // loop through, check that date offset is 1 day long, exept one that has offset 0 -> assert that it is equal to tQ.
      // Repeat lists should only have length n for n number of repeating events.
      repeatables = await toDoRepo!.getRepeatables(now: startDate);
      expect(repeatables.length, 1, reason: "Repeats didn't generate properly");

      for (ToDo repeatable in repeatables) {
        await repeatableService!.nextRepeat(model: repeatable);
      }

      toDos = await toDoRepo!.getRepoListBy(
          sorter:
              ToDoSorter(descending: true, sortMethod: SortMethod.due_date));

      expect(toDos.isNotEmpty, true, reason: "Query failed");
      expect(toDos.length, 5,
          reason: "Generated too many/few todos, ${toDos.length}");

      expect(toDos[0].startDate, DateTime(2024, 1, 5),
          reason: "Incorrect date: ${toDos[0].startDate}");

      for (ToDo toDo in toDos) {
        int offset = repeatableService!
            .getDateTimeDayOffset(start: toDo.startDate, end: toDo.dueDate);
        expect(offset == 0 || offset == 1, true,
            reason: "Incorrect date offset $offset");
        if (offset == 0) {
          expect(toDo.startDate, testQuery.startDate,
              reason: "Wrong element mutated");
          expect(toDo.expectedDuration, 1000,
              reason: "model not mutated properly $toDo");
          expect(toDo.weight, 4, reason: "model not mutated properly $toDo");
        } else {
          expect(toDo.expectedDuration, 0, reason: "model mutated $toDo");
        }
      }
    });

    //Deadline
    test("Deadline test, daily occurrence, 4 days, mutate day 2", () async {
      Deadline testDeadline =
          deadline.copyWith(repeatID: Constants.generateID());
      Deadline? template =
          testDeadline.copyWith(repeatableState: RepeatableState.template);
      await deadlineRepo!.updateBatch([testDeadline, template]);

      template =
          await deadlineRepo!.getTemplate(repeatID: testDeadline.repeatID!);
      expect(null != template, true, reason: "Likely a race condition");

      DateTime limit = DateTime(2024, 1, 5);
      DateTime startDate = DateTime(2024, 1, 1);

      Deadline? testMutate;
      List<Deadline> repeatables = [];
      while (startDate.isBefore(limit)) {
        repeatables = await deadlineRepo!.getRepeatables(now: startDate);
        for (Deadline repeatable in repeatables) {
          if (repeatable.startDate == DateTime(2024, 1, 2)) {
            testMutate = repeatable;
          }
          await repeatableService!.nextRepeat(model: repeatable);
        }
        startDate = startDate.copyWith(day: startDate.day + 1);
      }

      List<Deadline> deadlines = await deadlineRepo!.getRepoList();

      expect(deadlines.length, 4, reason: "Generated too many/few");

      expect(null != testMutate, true, reason: "repeatables set improperly");

      Deadline? testQuery = await deadlineRepo!.getByID(id: testMutate!.id);
      expect(null != testQuery, true, reason: "Deadline not properly stored");

      // suppose some data has been changed, "update single."
      testQuery!.warnDate = limit;
      // These are just arbitrary numbers
      testQuery.warnMe = true;
      testQuery.startDate = testQuery.dueDate!;
      testQuery.dueDate = limit;
      await repeatableService!
          .handleRepeating(model: testQuery, delete: false, single: true);

      await deadlineRepo!.update(testQuery);

      repeatables = await deadlineRepo!.getRepeatables(now: startDate);
      expect(repeatables.length, 1, reason: "Repeats didn't generate properly");

      for (Deadline repeatable in repeatables) {
        await repeatableService!.nextRepeat(model: repeatable);
      }

      deadlines = await deadlineRepo!.getRepoListBy(
          sorter: DeadlineSorter(
              descending: true, sortMethod: SortMethod.due_date));

      expect(deadlines.isNotEmpty, true, reason: "Query failed");
      expect(deadlines.length, 5,
          reason: "Generated too many/few todos, ${deadlines.length}");

      expect(deadlines[0].startDate, DateTime(2024, 1, 5),
          reason: "Incorrect date: ${deadlines[0].startDate}");

      for (Deadline deadline in deadlines) {
        int offset = repeatableService!.getDateTimeDayOffset(
            start: deadline.startDate, end: deadline.dueDate);
        expect(offset == 2 || offset == 1, true,
            reason: "Incorrect date offset $offset");
        if (offset == 2) {
          expect(deadline.startDate, testQuery.startDate,
              reason: "Wrong element mutated");
          expect(deadline.warnMe, true,
              reason: "model not mutated properly $deadline");
          expect(deadline.warnDate, limit,
              reason: "model not mutated properly $deadline");
        } else {
          expect(deadline.warnMe, false, reason: "model mutated $deadline");
        }
      }
    });

    // Reminders
    test("Reminder test, daily occurrence, 4 days, mutate day 2", () async {
      Reminder testReminder =
          reminder.copyWith(repeatID: Constants.generateID());
      Reminder? template =
          testReminder.copyWith(repeatableState: RepeatableState.template);
      await reminderRepo!.updateBatch([testReminder, template]);

      template =
          await reminderRepo!.getTemplate(repeatID: testReminder.repeatID!);
      expect(null != template, true, reason: "Likely a race condition");

      // Due to back-generation (ie. after midnight, check all outdated repeats),
      // This needs to run for 5 days to generate 4 events.
      DateTime limit = DateTime(2024, 1, 5);
      DateTime startDate = DateTime(2024, 1, 1);

      Reminder? testMutate;
      List<Reminder> repeatables = [];
      while (startDate.isBefore(limit)) {
        repeatables = await reminderRepo!.getRepeatables(now: startDate);
        for (Reminder repeatable in repeatables) {
          if (repeatable.startDate == DateTime(2024, 1, 2)) {
            testMutate = repeatable;
          }
          await repeatableService!.nextRepeat(model: repeatable);
        }
        startDate = startDate.copyWith(day: startDate.day + 1);
      }

      List<Reminder> reminders = await reminderRepo!.getRepoList();

      expect(reminders.length, 4, reason: "Generated too many/few");

      expect(null != testMutate, true, reason: "repeatables set improperly");

      Reminder? testQuery = await reminderRepo!.getByID(id: testMutate!.id);
      expect(null != testQuery, true, reason: "Reminder not properly stored");

      // suppose some data has been changed, "update single."
      testQuery!.name = "NewTest";
      testQuery.dueDate = limit;
      await repeatableService!
          .handleRepeating(model: testQuery, delete: false, single: true);

      await reminderRepo!.update(testQuery);

      // Generate another date. Get repo by dueDate desc. assert that the 1st element has startDate jan 5
      // loop through, check that date offset is 1 day long, exept one that has offset 0 -> assert that it is equal to tQ.
      // Repeat lists should only have length n for n number of repeating events.
      repeatables = await reminderRepo!.getRepeatables(now: startDate);
      expect(repeatables.length, 1, reason: "Repeats didn't generate properly");

      for (Reminder repeatable in repeatables) {
        await repeatableService!.nextRepeat(model: repeatable);
      }

      reminders = await reminderRepo!.getRepoListBy(
          sorter: ReminderSorter(
              descending: true, sortMethod: SortMethod.due_date));

      expect(reminders.isNotEmpty, true, reason: "Query failed");
      expect(reminders.length, 5,
          reason: "Generated too many/few todos, ${reminders.length}");

      expect(reminders[0].startDate, DateTime(2024, 1, 5),
          reason: "Incorrect date: ${reminders[0].startDate}");

      for (Reminder reminder in reminders) {
        expect(reminder.name == "Tester" || reminder.name == "NewTest", true,
            reason: "Data not mutated, ${reminder.name}");
        if ("NewTest" == reminder.name) {
          expect(reminder.dueDate, limit, reason: "Data not mutated properly");
        }
      }
    });
  });

  // Test: Generate 4 models, delete middle.
  // Create a 5th and ensure it follows the rpt pattern.
  group("Current Model, delete single", () {
    ToDo toDo = ToDo(
        taskType: TaskType.small,
        name: 'Tester',
        expectedDuration: 0,
        originalStart: startDate,
        startDate: startDate,
        originalDue: dueDate,
        dueDate: dueDate,
        frequency: Frequency.daily,
        realDuration: 0,
        repeatSkip: 1,
        repeatable: true,
        repeatDays: List.generate(7, (i) => false),
        lastUpdated: DateTime.now());

    Deadline deadline = Deadline(
        name: 'Tester',
        repeatable: true,
        startDate: startDate,
        originalStart: startDate,
        dueDate: dueDate,
        originalDue: dueDate,
        frequency: Frequency.daily,
        repeatSkip: 1,
        repeatDays: List.generate(7, (i) => false),
        lastUpdated: DateTime.now());

    Reminder reminder = Reminder(
        name: "Tester",
        repeatDays: List.generate(7, (i) => false),
        dueDate: startDate,
        originalDue: startDate,
        repeatable: true,
        frequency: Frequency.daily,
        repeatSkip: 1,
        lastUpdated: DateTime.now());

    test("ToDo test, daily occurrence, 4 days, delete day 2", () async {
      ToDo testToDo = toDo.copyWith(repeatID: Constants.generateID());
      ToDo? template =
          testToDo.copyWith(repeatableState: RepeatableState.template);
      await toDoRepo!.updateBatch([testToDo, template]);

      template = await toDoRepo!.getTemplate(repeatID: testToDo.repeatID!);
      expect(null != template, true, reason: "Likely a race condition");

      // Due to back-generation (ie. after midnight, check all outdated repeats),
      // This needs to run for 5 days to generate 4 events.
      DateTime limit = DateTime(2024, 1, 5);
      DateTime startDate = DateTime(2024, 1, 1);

      ToDo? testMutate;
      List<ToDo> repeatables = [];
      while (startDate.isBefore(limit)) {
        repeatables = await toDoRepo!.getRepeatables(now: startDate);
        for (ToDo repeatable in repeatables) {
          if (repeatable.startDate == DateTime(2024, 1, 2)) {
            testMutate = repeatable;
          }
          await repeatableService!.nextRepeat(model: repeatable);
        }
        startDate = startDate.copyWith(day: startDate.day + 1);
      }

      List<ToDo> toDos = await toDoRepo!.getRepoList();

      expect(toDos.length, 4, reason: "Generated too many/few");

      expect(null != testMutate, true, reason: "repeatables set improperly");

      ToDo? testQuery = await toDoRepo!.getByID(id: testMutate!.id);
      expect(null != testQuery, true, reason: "ToDo not properly stored");

      // This is functionally equivalent to deleting.
      testQuery!.toDelete = true;
      await repeatableService!
          .handleRepeating(model: testQuery, delete: true, single: true);

      await toDoRepo!.update(testQuery);

      // Generate another date. Get repo by dueDate desc. assert that the 1st element has startDate jan 5
      // loop through, check that date offset is 1 day long, exept one that has offset 0 -> assert that it is equal to tQ.
      // Repeat lists should only have length n for n number of repeating events.
      repeatables = await toDoRepo!.getRepeatables(now: startDate);
      expect(repeatables.length, 1, reason: "Repeats didn't generate properly");

      for (ToDo repeatable in repeatables) {
        await repeatableService!.nextRepeat(model: repeatable);
      }

      toDos = await toDoRepo!.getRepoListBy(
          sorter:
              ToDoSorter(descending: true, sortMethod: SortMethod.due_date));

      expect(toDos.isNotEmpty, true, reason: "Query failed");
      expect(toDos.length, 4, reason: "Delete didnt' work, ${toDos.length}");

      expect(toDos[0].startDate, DateTime(2024, 1, 5),
          reason: "Incorrect date: ${toDos[0].startDate}");

      for (ToDo toDo in toDos) {
        int offset = repeatableService!
            .getDateTimeDayOffset(start: toDo.startDate, end: toDo.dueDate);
        expect(offset == 0 || offset == 1, true,
            reason: "Incorrect date offset $offset");
        if (offset == 0) {
          expect(toDo.startDate, testQuery.startDate,
              reason: "Wrong element mutated");
          expect(toDo.expectedDuration, 1000,
              reason: "model not mutated properly $toDo");
          expect(toDo.weight, 4, reason: "model not mutated properly $toDo");
        } else {
          expect(toDo.expectedDuration, 0, reason: "model mutated $toDo");
        }
      }
    });

    //Deadline
    test("Deadline test, daily occurrence, 4 days, delete day 2", () async {
      Deadline testDeadline =
          deadline.copyWith(repeatID: Constants.generateID());
      Deadline? template =
          testDeadline.copyWith(repeatableState: RepeatableState.template);
      await deadlineRepo!.updateBatch([testDeadline, template]);

      template =
          await deadlineRepo!.getTemplate(repeatID: testDeadline.repeatID!);
      expect(null != template, true, reason: "Likely a race condition");

      DateTime limit = DateTime(2024, 1, 5);
      DateTime startDate = DateTime(2024, 1, 1);

      Deadline? testMutate;
      List<Deadline> repeatables = [];
      while (startDate.isBefore(limit)) {
        repeatables = await deadlineRepo!.getRepeatables(now: startDate);
        for (Deadline repeatable in repeatables) {
          if (repeatable.startDate == DateTime(2024, 1, 2)) {
            testMutate = repeatable;
          }
          await repeatableService!.nextRepeat(model: repeatable);
        }
        startDate = startDate.copyWith(day: startDate.day + 1);
      }

      List<Deadline> deadlines = await deadlineRepo!.getRepoList();

      expect(deadlines.length, 4, reason: "Generated too many/few");

      expect(null != testMutate, true, reason: "repeatables set improperly");

      Deadline? testQuery = await deadlineRepo!.getByID(id: testMutate!.id);
      expect(null != testQuery, true, reason: "Deadline not properly stored");

      await repeatableService!
          .handleRepeating(model: testQuery, delete: true, single: true);

      repeatables = await deadlineRepo!.getRepeatables(now: startDate);
      expect(repeatables.length, 1, reason: "Repeats didn't generate properly");

      for (Deadline repeatable in repeatables) {
        await repeatableService!.nextRepeat(model: repeatable);
      }

      deadlines = await deadlineRepo!.getRepoListBy(
          sorter: DeadlineSorter(
              descending: true, sortMethod: SortMethod.due_date));

      expect(deadlines.isNotEmpty, true, reason: "Query failed");
      expect(deadlines.length, 4,
          reason: "Delete didn't work, ${deadlines.length}");

      expect(deadlines[0].startDate, DateTime(2024, 1, 5),
          reason: "Incorrect date: ${deadlines[0].startDate}");

      for (Deadline deadline in deadlines) {
        int offset = repeatableService!.getDateTimeDayOffset(
            start: deadline.startDate, end: deadline.dueDate);
        expect(offset == 2 || offset == 1, true,
            reason: "Incorrect date offset $offset");
        if (offset == 2) {
          expect(deadline.startDate, testQuery!.startDate,
              reason: "Wrong element mutated");
          expect(deadline.warnMe, true,
              reason: "model not mutated properly $deadline");
          expect(deadline.warnDate, limit,
              reason: "model not mutated properly $deadline");
        } else {
          expect(deadline.warnMe, false, reason: "model mutated $deadline");
        }
      }
    });

    // Reminders
    test("Reminder test, daily occurrence, 4 days, delete day 2", () async {
      Reminder testReminder =
          reminder.copyWith(repeatID: Constants.generateID());
      Reminder? template =
          testReminder.copyWith(repeatableState: RepeatableState.template);
      await reminderRepo!.updateBatch([testReminder, template]);

      template =
          await reminderRepo!.getTemplate(repeatID: testReminder.repeatID!);
      expect(null != template, true, reason: "Likely a race condition");

      // Due to back-generation (ie. after midnight, check all outdated repeats),
      // This needs to run for 5 days to generate 4 events.
      DateTime limit = DateTime(2024, 1, 5);
      DateTime startDate = DateTime(2024, 1, 1);

      Reminder? testMutate;
      List<Reminder> repeatables = [];
      while (startDate.isBefore(limit)) {
        repeatables = await reminderRepo!.getRepeatables(now: startDate);
        for (Reminder repeatable in repeatables) {
          if (repeatable.startDate == DateTime(2024, 1, 2)) {
            testMutate = repeatable;
          }
          await repeatableService!.nextRepeat(model: repeatable);
        }
        startDate = startDate.copyWith(day: startDate.day + 1);
      }

      List<Reminder> reminders = await reminderRepo!.getRepoList();

      expect(reminders.length, 4, reason: "Generated too many/few");

      expect(null != testMutate, true, reason: "repeatables set improperly");

      Reminder? testQuery = await reminderRepo!.getByID(id: testMutate!.id);
      expect(null != testQuery, true, reason: "Reminder not properly stored");

      await repeatableService!
          .handleRepeating(model: testQuery, delete: true, single: true);

      repeatables = await reminderRepo!.getRepeatables(now: startDate);
      expect(repeatables.length, 1, reason: "Repeats didn't generate properly");

      for (Reminder repeatable in repeatables) {
        await repeatableService!.nextRepeat(model: repeatable);
      }

      reminders = await reminderRepo!.getRepoListBy(
          sorter: ReminderSorter(
              descending: true, sortMethod: SortMethod.due_date));

      expect(reminders.isNotEmpty, true, reason: "Query failed");
      expect(reminders.length, 4,
          reason: "Delete didn't work, ${reminders.length}");

      expect(reminders[0].startDate, DateTime(2024, 1, 5),
          reason: "Incorrect date: ${reminders[0].startDate}");

      for (Reminder reminder in reminders) {
        expect(reminder.name == "Tester" || reminder.name == "NewTest", true,
            reason: "Data not mutated, ${reminder.name}");
        if ("NewTest" == reminder.name) {
          expect(reminder.dueDate, limit, reason: "Data not mutated properly");
        }
      }
    });
  });

  // Test: Generate 3 models, mutate middle.
  // Ensure template matches middle, generate a new one, ensure match
  group("Current Model, mutate all", () {
    ToDo toDo = ToDo(
        taskType: TaskType.small,
        name: 'Tester',
        expectedDuration: 0,
        originalStart: startDate,
        startDate: startDate,
        originalDue: dueDate,
        dueDate: dueDate,
        frequency: Frequency.daily,
        realDuration: 0,
        repeatSkip: 1,
        repeatable: true,
        repeatDays: List.generate(7, (i) => false),
        lastUpdated: DateTime.now());

    Deadline deadline = Deadline(
        name: 'Tester',
        repeatable: true,
        startDate: startDate,
        originalStart: startDate,
        dueDate: dueDate,
        originalDue: dueDate,
        frequency: Frequency.daily,
        repeatSkip: 1,
        repeatDays: List.generate(7, (i) => false),
        lastUpdated: DateTime.now());

    Reminder reminder = Reminder(
        name: "Tester",
        repeatDays: List.generate(7, (i) => false),
        dueDate: startDate,
        originalDue: startDate,
        repeatable: true,
        frequency: Frequency.daily,
        repeatSkip: 1,
        lastUpdated: DateTime.now());

    test("ToDo Update All", () async {
      ToDo testToDo = toDo.copyWith(repeatID: Constants.generateID());
      ToDo? template =
          testToDo.copyWith(repeatableState: RepeatableState.template);
      await toDoRepo!.updateBatch([testToDo, template]);

      template = await toDoRepo!.getTemplate(repeatID: testToDo.repeatID!);
      expect(null != template, true, reason: "Likely a race condition");

      DateTime limit = DateTime(2024, 1, 4);
      DateTime startDate = DateTime(2024, 1, 1);

      ToDo? testMutate;
      List<ToDo> repeatables = [];
      while (startDate.isBefore(limit)) {
        repeatables = await toDoRepo!.getRepeatables(now: startDate);
        for (ToDo repeatable in repeatables) {
          if (repeatable.startDate == DateTime(2024, 1, 2)) {
            testMutate = repeatable;
          }
          await repeatableService!.nextRepeat(model: repeatable);
        }
        startDate = startDate.copyWith(day: startDate.day + 1);
      }

      List<ToDo> toDos = await toDoRepo!.getRepoList();

      expect(toDos.length, 3, reason: "Generated too many/few");

      expect(null != testMutate, true, reason: "repeatables set improperly");

      ToDo? testQuery = await toDoRepo!.getByID(id: testMutate!.id);
      expect(null != testQuery, true, reason: "ToDo not properly stored");

      // Mutating data
      testQuery!.weight = 4;
      testQuery.name = "NewTester";
      testQuery.expectedDuration = 1000;
      // Offset of zero
      testQuery.startDate = limit;
      testQuery.dueDate = limit;
      // update all
      await repeatableService!
          .handleRepeating(model: testQuery, delete: false, single: false);

      // Generate two more.
      startDate = limit.copyWith(day: limit.day + 1);
      for (int i = 0; i < 2; i++) {
        repeatables = await toDoRepo!.getRepeatables(now: startDate);
        expect(repeatables.length, 1,
            reason: "Repeats didn't generate properly");
        for (ToDo repeatable in repeatables) {
          await repeatableService!.nextRepeat(model: repeatable);
        }
        startDate = startDate.copyWith(day: startDate.day + 1);
      }

      toDos = await toDoRepo!.getRepoListBy(
          sorter:
              ToDoSorter(descending: true, sortMethod: SortMethod.due_date));

      expect(toDos.isNotEmpty, true, reason: "Query failed");
      expect(toDos.length, 5, reason: "Generation failure, ${toDos.length}");

      int offset = repeatableService!.getDateTimeDayOffset(
          start: toDos[0].startDate, end: toDos[0].dueDate);
      expect(offset, 0,
          reason:
              "Incorrect date copied: ${toDos[0].startDate}, ${toDos[0].dueDate}");

      offset = repeatableService!.getDateTimeDayOffset(
          start: toDos[1].startDate, end: toDos[1].dueDate);
      expect(offset, 0,
          reason:
              "Incorrect date copied: ${toDos[1].startDate}, ${toDos[1].dueDate}");

      expect(toDos[0].weight, 4, reason: "Template not mutated");
      expect(toDos[1].weight, 4, reason: "Template not mutated");
      template = await toDoRepo!.getTemplate(repeatID: testToDo.repeatID!);

      expect(null != template, true, reason: "Template got severed");
      expect(template!.weight, 4, reason: "Template not mutated");
      expect(template.name, "NewTester", reason: "Template not mutated");
    });

    //Deadline
    test("Deadline update all", () async {
      Deadline testDeadline =
          deadline.copyWith(repeatID: Constants.generateID());
      Deadline? template =
          testDeadline.copyWith(repeatableState: RepeatableState.template);
      await deadlineRepo!.updateBatch([testDeadline, template]);

      template =
          await deadlineRepo!.getTemplate(repeatID: testDeadline.repeatID!);
      expect(null != template, true, reason: "Likely a race condition");

      DateTime limit = DateTime(2024, 1, 4);
      DateTime startDate = DateTime(2024, 1, 1);

      Deadline? testMutate;
      List<Deadline> repeatables = [];
      while (startDate.isBefore(limit)) {
        repeatables = await deadlineRepo!.getRepeatables(now: startDate);
        for (Deadline repeatable in repeatables) {
          if (repeatable.startDate == DateTime(2024, 1, 2)) {
            testMutate = repeatable;
          }
          await repeatableService!.nextRepeat(model: repeatable);
        }
        startDate = startDate.copyWith(day: startDate.day + 1);
      }

      List<Deadline> deadlines = await deadlineRepo!.getRepoList();

      expect(deadlines.length, 3, reason: "Generated too many/few");

      expect(null != testMutate, true, reason: "repeatables set improperly");

      Deadline? testQuery = await deadlineRepo!.getByID(id: testMutate!.id);
      expect(null != testQuery, true, reason: "Deadline not properly stored");

      // suppose some data has been changed, "update all."
      testQuery!.warnDate = limit;
      // These are just arbitrary numbers
      testQuery.warnMe = true;
      testQuery.name = "TestNew";
      testQuery.startDate = testQuery.dueDate!;
      testQuery.dueDate = limit;
      // this also updates
      await repeatableService!
          .handleRepeating(model: testQuery, delete: false, single: false);

      for (int i = 0; i < 2; i++) {
        repeatables = await deadlineRepo!.getRepeatables(now: startDate);
        expect(repeatables.length, 1,
            reason: "Repeats didn't generate properly");

        for (Deadline repeatable in repeatables) {
          await repeatableService!.nextRepeat(model: repeatable);
        }
        startDate = startDate.copyWith(day: startDate.day + 1);
      }

      deadlines = await deadlineRepo!.getRepoListBy(
          sorter: DeadlineSorter(
              descending: true, sortMethod: SortMethod.due_date));

      expect(deadlines.isNotEmpty, true, reason: "Query failed");
      expect(deadlines.length, 5,
          reason: "Generated too many/few todos, ${deadlines.length}");

      expect(deadlines[0].warnDate, deadlines[0].dueDate,
          reason:
              "Didn't properly mutate, ${deadlines[0].warnDate}, ${deadlines[0].dueDate}");

      expect(deadlines[1].warnDate, deadlines[1].dueDate,
          reason:
              "Didn't properly mutate, ${deadlines[1].warnDate}, ${deadlines[1].dueDate}");

      expect(deadlines[0].warnMe, deadlines[1].warnMe,
          reason:
              "Didn't properly mutate ${deadlines[0].warnMe}, ${deadlines[1].warnMe}");

      template =
          await deadlineRepo!.getTemplate(repeatID: deadlines[0].repeatID!);
      expect(null != template, true, reason: "Null template");
      expect(template!.warnMe, true,
          reason: "Didn't mutate ${template.warnMe}");
      expect(template.warnDate, template.dueDate,
          reason: "Didn't mutate ${template.warnDate}, ${template.dueDate}");
    });

    // Reminders
    test("Reminder update all", () async {
      Reminder testReminder =
          reminder.copyWith(repeatID: Constants.generateID());
      Reminder? template =
          testReminder.copyWith(repeatableState: RepeatableState.template);
      await reminderRepo!.updateBatch([testReminder, template]);

      template =
          await reminderRepo!.getTemplate(repeatID: testReminder.repeatID!);
      expect(null != template, true, reason: "Likely a race condition");

      DateTime limit = DateTime(2024, 1, 4);
      DateTime startDate = DateTime(2024, 1, 1);

      Reminder? testMutate;
      List<Reminder> repeatables = [];
      while (startDate.isBefore(limit)) {
        repeatables = await reminderRepo!.getRepeatables(now: startDate);
        for (Reminder repeatable in repeatables) {
          if (repeatable.startDate == DateTime(2024, 1, 2)) {
            testMutate = repeatable;
          }
          await repeatableService!.nextRepeat(model: repeatable);
        }
        startDate = startDate.copyWith(day: startDate.day + 1);
      }

      List<Reminder> reminders = await reminderRepo!.getRepoList();

      expect(reminders.length, 3, reason: "Generated too many/few");

      expect(null != testMutate, true, reason: "repeatables set improperly");

      Reminder? testQuery = await reminderRepo!.getByID(id: testMutate!.id);
      expect(null != testQuery, true, reason: "Reminder not properly stored");

      // suppose some data has been changed, "update single."
      testQuery!.name = "NewTest";
      testQuery.dueDate = limit;

      // This also updates
      await repeatableService!
          .handleRepeating(model: testQuery, delete: false, single: false);

      startDate = limit.copyWith(day: limit.day + 1);
      for (int i = 0; i < 2; i++) {
        repeatables = await reminderRepo!.getRepeatables(now: startDate);
        expect(repeatables.length, 1,
            reason: "Repeats didn't generate properly");

        for (Reminder repeatable in repeatables) {
          await repeatableService!.nextRepeat(model: repeatable);
        }
        startDate = startDate.copyWith(day: startDate.day + 1);
      }
      reminders = await reminderRepo!.getRepoListBy(
          sorter: ReminderSorter(
              descending: true, sortMethod: SortMethod.due_date));

      expect(reminders.isNotEmpty, true, reason: "Query failed");
      expect(reminders.length, 5,
          reason: "Generated too many/few todos, ${reminders.length}");

      expect(reminders[0].name, reminders[1].name,
          reason:
              "Data failed to mutate, ${reminders[0].name}, ${reminders[1].name}");

      expect(reminders[0].name, "NewTest", reason: "Data failed to mutate");

      expect(reminders[0].name != reminders[3].name, true,
          reason: "Template not properly mutated");

      template =
          await reminderRepo!.getTemplate(repeatID: reminders[0].repeatID!);

      expect(null != template, true, reason: "Null template");
      expect(template!.name, reminders[0].name,
          reason: "Data failed to mutate");
    });
  });

  // Test: Generate 2 models, project 1 model & modify it.
  // Generate the next model and ensure it matches the projection
  // Generate the following model and ensure it matches the template.
  // ie. generates from the delta.
  group("Projected Model, mutate single", () {
    ToDo toDo = ToDo(
        taskType: TaskType.small,
        name: 'Tester',
        expectedDuration: 0,
        originalStart: startDate,
        startDate: startDate,
        originalDue: dueDate,
        dueDate: dueDate,
        frequency: Frequency.daily,
        realDuration: 0,
        repeatSkip: 1,
        repeatable: true,
        repeatDays: List.generate(7, (i) => false),
        lastUpdated: DateTime.now());

    Deadline deadline = Deadline(
        name: 'Tester',
        repeatable: true,
        startDate: startDate,
        originalStart: startDate,
        dueDate: dueDate,
        originalDue: dueDate,
        frequency: Frequency.daily,
        repeatSkip: 1,
        repeatDays: List.generate(7, (i) => false),
        lastUpdated: DateTime.now());

    Reminder reminder = Reminder(
        name: "Tester",
        repeatDays: List.generate(7, (i) => false),
        dueDate: startDate,
        originalDue: startDate,
        repeatable: true,
        frequency: Frequency.daily,
        repeatSkip: 1,
        lastUpdated: DateTime.now());

    test("ToDo Projected update single.", () async {
      ToDo testToDo = toDo.copyWith(repeatID: Constants.generateID());
      ToDo? template =
          testToDo.copyWith(repeatableState: RepeatableState.template);
      await toDoRepo!.updateBatch([testToDo, template]);

      template = await toDoRepo!.getTemplate(repeatID: testToDo.repeatID!);
      expect(null != template, true, reason: "Likely a race condition");

      DateTime limit = DateTime(2024, 1, 4);
      DateTime startDate = DateTime(2024, 1, 1);
      DateTime testDate = DateTime(2024, 1, 20);

      List<ToDo> repeatables = [];
      while (startDate.isBefore(limit)) {
        repeatables = await toDoRepo!.getRepeatables(now: startDate);
        for (ToDo repeatable in repeatables) {
          await repeatableService!.nextRepeat(model: repeatable);
        }
        startDate = startDate.copyWith(day: startDate.day + 1);
      }

      List<ToDo> toDos = await toDoRepo!.getRepoList();

      expect(toDos.length, 3, reason: "Generated too many/few");

      // Create a projection.

      DateTime? nextDate = repeatableService!.getRepeatDate(
          model: template!.copyWith(
        originalStart: toDos[0].originalStart,
      ));

      expect(null != nextDate, true, reason: "Null start date");

      int offset = repeatableService!.getDateTimeDayOffset(
          start: template.startDate, end: template.dueDate);

      DateTime? nextDue = nextDate?.copyWith(day: nextDate.day + offset);

      ToDo projection = template.copyWith(
        startDate: nextDate,
        originalStart: nextDate,
        originalDue: nextDue,
        dueDate: testDate,
        completed: false,
        repeatable: true,
        name: "TestProjection",
        weight: 1,
        repeatableState: RepeatableState.projected,
        lastUpdated: DateTime.now(),
      );
      // update all
      await repeatableService!
          .handleRepeating(model: projection, delete: false, single: true);

      // Generate two more.
      for (int i = 0; i < 2; i++) {
        repeatables = await toDoRepo!.getRepeatables(now: startDate);
        expect(repeatables.length, 1,
            reason: "Repeats didn't generate properly");
        for (ToDo repeatable in repeatables) {
          await repeatableService!.nextRepeat(model: repeatable);
        }
        startDate = startDate.copyWith(day: startDate.day + 1);
      }

      toDos = await toDoRepo!.getRepoListBy(
          sorter:
              ToDoSorter(descending: true, sortMethod: SortMethod.due_date));
      // Due to the test date, the delta will be the top item.

      expect(toDos.isNotEmpty, true, reason: "Query failed");
      expect(toDos.length, 5, reason: "Generation failure, ${toDos.length}");
      expect(toDos[0].dueDate, testDate,
          reason: "Delta failed ${toDos[0].dueDate}");
      expect(toDos[0].name, "TestProjection",
          reason: "Delta failed: ${toDos[0].name}");
      expect(toDos[0].weight, 1, reason: "Delta failed ${toDos[0].weight}");
      expect(toDos[1].name, "Tester",
          reason: "template got modified ${toDos[1].name}");
      offset = repeatableService!.getDateTimeDayOffset(
          start: toDos[1].startDate, end: toDos[1].dueDate);
      expect(offset, 1, reason: "template got modified, offset:  $offset");

      expect(toDos[1].startDate, DateTime(2024, 1, 5),
          reason: "template got modified, ${toDos[1].startDate}");
      expect(toDos[1].dueDate, DateTime(2024, 1, 6),
          reason: "template got modified, ${toDos[1].dueDate}");
    });

    test("Deadline Projected update single.", () async {
      Deadline testDeadline =
          deadline.copyWith(repeatID: Constants.generateID());
      Deadline? template =
          testDeadline.copyWith(repeatableState: RepeatableState.template);
      await deadlineRepo!.updateBatch([testDeadline, template]);

      template =
          await deadlineRepo!.getTemplate(repeatID: testDeadline.repeatID!);
      expect(null != template, true, reason: "Likely a race condition");

      DateTime limit = DateTime(2024, 1, 4);
      DateTime startDate = DateTime(2024, 1, 1);
      DateTime testDate = DateTime(2024, 1, 20);

      List<Deadline> repeatables = [];
      while (startDate.isBefore(limit)) {
        repeatables = await deadlineRepo!.getRepeatables(now: startDate);
        for (Deadline repeatable in repeatables) {
          await repeatableService!.nextRepeat(model: repeatable);
        }
        startDate = startDate.copyWith(day: startDate.day + 1);
      }

      List<Deadline> deadlines = await deadlineRepo!.getRepoList();

      expect(deadlines.length, 3, reason: "Generated too many/few");

      // Create a projection.

      DateTime? nextDate = repeatableService!.getRepeatDate(
          model: template!.copyWith(
        originalStart: deadlines[0].originalStart,
      ));

      expect(null != nextDate, true, reason: "Null start date");

      int offset = repeatableService!.getDateTimeDayOffset(
          start: template.startDate, end: template.dueDate);

      DateTime? nextDue = nextDate?.copyWith(day: nextDate.day + offset);

      Deadline projection = template.copyWith(
        startDate: nextDate,
        originalStart: nextDate,
        originalDue: nextDue,
        dueDate: testDate,
        warnDate: testDate,
        warnMe: true,
        repeatable: true,
        name: "TestProjection",
        repeatableState: RepeatableState.projected,
        lastUpdated: DateTime.now(),
      );
      // update all
      await repeatableService!
          .handleRepeating(model: projection, delete: false, single: true);

      // Generate two more.
      for (int i = 0; i < 2; i++) {
        repeatables = await deadlineRepo!.getRepeatables(now: startDate);
        expect(repeatables.length, 1,
            reason: "Repeats didn't generate properly");
        for (Deadline repeatable in repeatables) {
          await repeatableService!.nextRepeat(model: repeatable);
        }
        startDate = startDate.copyWith(day: startDate.day + 1);
      }

      deadlines = await deadlineRepo!.getRepoListBy(
          sorter: DeadlineSorter(
              descending: true, sortMethod: SortMethod.due_date));
      // Due to the test date, the delta will be the top item.

      expect(deadlines.isNotEmpty, true, reason: "Query failed");
      expect(deadlines.length, 5,
          reason: "Generation failure, ${deadlines.length}");
      expect(deadlines[0].dueDate, testDate,
          reason: "Delta failed ${deadlines[0].dueDate}");
      expect(deadlines[0].name, "TestProjection",
          reason: "Delta failed: ${deadlines[0].name}");
      expect(deadlines[0].warnMe, true,
          reason: "Delta failed ${deadlines[0].warnMe}");
      expect(deadlines[0].warnDate, testDate, reason: "Delta failed");
      expect(deadlines[1].name, "Tester",
          reason: "template got modified ${deadlines[1].name}");
      offset = repeatableService!.getDateTimeDayOffset(
          start: deadlines[1].startDate, end: deadlines[1].dueDate);
      expect(offset, 1, reason: "template got modified, offset:  $offset");

      expect(deadlines[1].startDate, DateTime(2024, 1, 5),
          reason: "template got modified, ${deadlines[1].startDate}");
      expect(deadlines[1].dueDate, DateTime(2024, 1, 6),
          reason: "template got modified, ${deadlines[1].dueDate}");
    });

    test("Reminder Projected update single.", () async {
      Reminder testReminder =
          reminder.copyWith(repeatID: Constants.generateID());
      Reminder? template =
          testReminder.copyWith(repeatableState: RepeatableState.template);
      await reminderRepo!.updateBatch([testReminder, template]);

      template =
          await reminderRepo!.getTemplate(repeatID: testReminder.repeatID!);
      expect(null != template, true, reason: "Likely a race condition");

      DateTime limit = DateTime(2024, 1, 4);
      DateTime startDate = DateTime(2024, 1, 1);
      DateTime testDate = DateTime(2024, 1, 20);

      List<Reminder> repeatables = [];
      while (startDate.isBefore(limit)) {
        repeatables = await reminderRepo!.getRepeatables(now: startDate);
        for (Reminder repeatable in repeatables) {
          await repeatableService!.nextRepeat(model: repeatable);
        }
        startDate = startDate.copyWith(day: startDate.day + 1);
      }

      List<Reminder> reminders = await reminderRepo!.getRepoList();

      expect(reminders.length, 3, reason: "Generated too many/few");

      // Create a projection.

      DateTime? nextDate = repeatableService!.getRepeatDate(
          model: template!.copyWith(
        originalDue: reminders[0].originalDue,
      ));

      expect(null != nextDate, true, reason: "Null start date");

      int offset = repeatableService!.getDateTimeDayOffset(
          start: template.startDate, end: template.dueDate);

      DateTime? nextDue = nextDate?.copyWith(day: nextDate.day + offset);

      Reminder projection = template.copyWith(
        originalDue: nextDue,
        dueDate: testDate,
        repeatable: true,
        name: "TestProjection",
        repeatableState: RepeatableState.projected,
        lastUpdated: DateTime.now(),
      );
      // update all
      await repeatableService!
          .handleRepeating(model: projection, delete: false, single: true);

      // Generate two more.
      for (int i = 0; i < 2; i++) {
        repeatables = await reminderRepo!.getRepeatables(now: startDate);
        expect(repeatables.length, 1,
            reason: "Repeats didn't generate properly");
        for (Reminder repeatable in repeatables) {
          await repeatableService!.nextRepeat(model: repeatable);
        }
        startDate = startDate.copyWith(day: startDate.day + 1);
      }

      reminders = await reminderRepo!.getRepoListBy(
          sorter: ReminderSorter(
              descending: true, sortMethod: SortMethod.due_date));
      // Due to the test date, the delta will be the top item.

      expect(reminders.isNotEmpty, true, reason: "Query failed");
      expect(reminders.length, 5,
          reason: "Generation failure, ${reminders.length}");
      expect(reminders[0].dueDate, testDate,
          reason: "Delta failed ${reminders[0].dueDate}");
      expect(reminders[0].name, "TestProjection",
          reason: "Delta failed: ${reminders[0].name}");
      expect(reminders[1].name, "Tester",
          reason: "template got modified ${reminders[1].name}");

      expect(reminders[1].dueDate, DateTime(2024, 1, 5),
          reason: "template got modified, ${reminders[1].dueDate}");
    });
  });

  group("Projected Model, delete single", () {
    ToDo toDo = ToDo(
        taskType: TaskType.small,
        name: 'Tester',
        expectedDuration: 0,
        originalStart: startDate,
        startDate: startDate,
        originalDue: dueDate,
        dueDate: dueDate,
        frequency: Frequency.daily,
        realDuration: 0,
        repeatSkip: 1,
        repeatable: true,
        repeatDays: List.generate(7, (i) => false),
        lastUpdated: DateTime.now());

    Deadline deadline = Deadline(
        name: 'Tester',
        repeatable: true,
        startDate: startDate,
        originalStart: startDate,
        dueDate: dueDate,
        originalDue: dueDate,
        frequency: Frequency.daily,
        repeatSkip: 1,
        repeatDays: List.generate(7, (i) => false),
        lastUpdated: DateTime.now());

    Reminder reminder = Reminder(
        name: "Tester",
        repeatDays: List.generate(7, (i) => false),
        dueDate: startDate,
        originalDue: startDate,
        repeatable: true,
        frequency: Frequency.daily,
        repeatSkip: 1,
        lastUpdated: DateTime.now());

    test("ToDo Projected delete single.", () async {
      ToDo testToDo = toDo.copyWith(repeatID: Constants.generateID());
      ToDo? template =
          testToDo.copyWith(repeatableState: RepeatableState.template);
      await toDoRepo!.updateBatch([testToDo, template]);

      template = await toDoRepo!.getTemplate(repeatID: testToDo.repeatID!);
      expect(null != template, true, reason: "Likely a race condition");

      DateTime limit = DateTime(2024, 1, 4);
      DateTime startDate = DateTime(2024, 1, 1);
      DateTime testDate = DateTime(2024, 1, 20);

      List<ToDo> repeatables = [];
      while (startDate.isBefore(limit)) {
        repeatables = await toDoRepo!.getRepeatables(now: startDate);
        for (ToDo repeatable in repeatables) {
          await repeatableService!.nextRepeat(model: repeatable);
        }
        startDate = startDate.copyWith(day: startDate.day + 1);
      }

      List<ToDo> toDos = await toDoRepo!.getRepoList();

      expect(toDos.length, 3, reason: "Generated too many/few");

      // Create a projection.

      DateTime? nextDate = repeatableService!.getRepeatDate(
          model: template!.copyWith(
        originalStart: toDos[0].originalStart,
      ));

      expect(null != nextDate, true, reason: "Null start date");

      int offset = repeatableService!.getDateTimeDayOffset(
          start: template.startDate, end: template.dueDate);

      DateTime? nextDue = nextDate?.copyWith(day: nextDate.day + offset);

      ToDo projection = template.copyWith(
        startDate: nextDate,
        originalStart: nextDate,
        originalDue: nextDue,
        dueDate: testDate,
        completed: false,
        repeatable: true,
        name: "TestProjection",
        weight: 1,
        repeatableState: RepeatableState.projected,
        lastUpdated: DateTime.now(),
      );
      // update all
      await repeatableService!
          .handleRepeating(model: projection, delete: true, single: true);

      // Generate two more, one should be deleted.
      for (int i = 0; i < 2; i++) {
        repeatables = await toDoRepo!.getRepeatables(now: startDate);
        expect(repeatables.length, 1,
            reason: "Repeats didn't generate properly");
        for (ToDo repeatable in repeatables) {
          await repeatableService!.nextRepeat(model: repeatable);
        }
        startDate = startDate.copyWith(day: startDate.day + 1);
      }

      toDos = await toDoRepo!.getRepoListBy(
          sorter:
              ToDoSorter(descending: true, sortMethod: SortMethod.due_date));
      // Due to the test date, the delta will be the top item, if it's not properly deleted.

      expect(toDos.isNotEmpty, true, reason: "Query failed");
      expect(toDos.length, 4,
          reason: "Failure to apply delete delta, ${toDos.length}");
      offset = repeatableService!.getDateTimeDayOffset(
          start: toDos[0].startDate, end: toDos[0].dueDate);
      expect(offset, 1,
          reason: "Delete didn't work, todo start/due offset:  $offset");

      offset = repeatableService!
          .getDateTimeDayOffset(
              start: toDos[0].startDate, end: toDos[1].startDate)
          .abs();

      expect(offset, 2,
          reason: "Delete didn't work, todo/todo offset: $offset");

      expect(toDos[0].startDate, DateTime(2024, 1, 5),
          reason: "Delete didn't work, ${toDos[0].startDate}");
      expect(toDos[0].dueDate, DateTime(2024, 1, 6),
          reason: "Delete didn't work, ${toDos[0].dueDate}");
    });

    test("Deadline Projected delete single.", () async {
      Deadline testDeadline =
          deadline.copyWith(repeatID: Constants.generateID());
      Deadline? template =
          testDeadline.copyWith(repeatableState: RepeatableState.template);
      await deadlineRepo!.updateBatch([testDeadline, template]);

      template =
          await deadlineRepo!.getTemplate(repeatID: testDeadline.repeatID!);
      expect(null != template, true, reason: "Likely a race condition");

      DateTime limit = DateTime(2024, 1, 4);
      DateTime startDate = DateTime(2024, 1, 1);
      DateTime testDate = DateTime(2024, 1, 20);

      List<Deadline> repeatables = [];
      while (startDate.isBefore(limit)) {
        repeatables = await deadlineRepo!.getRepeatables(now: startDate);
        for (Deadline repeatable in repeatables) {
          await repeatableService!.nextRepeat(model: repeatable);
        }
        startDate = startDate.copyWith(day: startDate.day + 1);
      }

      List<Deadline> deadlines = await deadlineRepo!.getRepoList();

      expect(deadlines.length, 3, reason: "Generated too many/few");

      // Create a projection.

      DateTime? nextDate = repeatableService!.getRepeatDate(
          model: template!.copyWith(
        originalStart: deadlines[0].startDate,
      ));

      expect(null != nextDate, true, reason: "Null start date");

      int offset = repeatableService!.getDateTimeDayOffset(
          start: template.startDate, end: template.dueDate);

      DateTime? nextDue = nextDate?.copyWith(day: nextDate.day + offset);

      Deadline projection = template.copyWith(
        startDate: nextDate,
        originalStart: nextDate,
        originalDue: nextDue,
        dueDate: testDate,
        repeatable: true,
        name: "TestProjection",
        repeatableState: RepeatableState.projected,
        lastUpdated: DateTime.now(),
      );
      // update all
      await repeatableService!
          .handleRepeating(model: projection, delete: true, single: true);

      // Generate two more, one should be deleted.
      for (int i = 0; i < 2; i++) {
        repeatables = await deadlineRepo!.getRepeatables(now: startDate);
        expect(repeatables.length, 1,
            reason: "Repeats didn't generate properly");
        for (Deadline repeatable in repeatables) {
          await repeatableService!.nextRepeat(model: repeatable);
        }
        startDate = startDate.copyWith(day: startDate.day + 1);
      }

      deadlines = await deadlineRepo!.getRepoListBy(
          sorter: DeadlineSorter(
              descending: true, sortMethod: SortMethod.due_date));
      // Due to the test date, the delta will be the top item, if it's not properly deleted.

      expect(deadlines.isNotEmpty, true, reason: "Query failed");
      expect(deadlines.length, 4,
          reason: "Failure to apply delete delta, ${deadlines.length}");
      offset = repeatableService!.getDateTimeDayOffset(
          start: deadlines[0].startDate, end: deadlines[0].dueDate);
      expect(offset, 1,
          reason: "Delete didn't work, deadline start/due offset:  $offset");

      offset = repeatableService!
          .getDateTimeDayOffset(
              start: deadlines[0].startDate, end: deadlines[1].startDate)
          .abs();

      expect(offset, 2,
          reason: "Delete didn't work, deadline/deadline offset: $offset");

      expect(deadlines[0].startDate, DateTime(2024, 1, 5),
          reason: "Delete didn't work, ${deadlines[0].startDate}");
      expect(deadlines[0].dueDate, DateTime(2024, 1, 6),
          reason: "Delete didn't work, ${deadlines[0].dueDate}");
    });

    test("Reminder Projected delete single.", () async {
      Reminder testReminder =
          reminder.copyWith(repeatID: Constants.generateID());
      Reminder? template =
          testReminder.copyWith(repeatableState: RepeatableState.template);
      await reminderRepo!.updateBatch([testReminder, template]);

      template =
          await reminderRepo!.getTemplate(repeatID: testReminder.repeatID!);
      expect(null != template, true, reason: "Likely a race condition");

      DateTime limit = DateTime(2024, 1, 4);
      DateTime startDate = DateTime(2024, 1, 1);

      List<Reminder> repeatables = [];
      while (startDate.isBefore(limit)) {
        repeatables = await reminderRepo!.getRepeatables(now: startDate);
        for (Reminder repeatable in repeatables) {
          await repeatableService!.nextRepeat(model: repeatable);
        }
        startDate = startDate.copyWith(day: startDate.day + 1);
      }

      List<Reminder> reminders = await reminderRepo!.getRepoList();

      expect(reminders.length, 3, reason: "Generated too many/few");

      // Create a projection.

      DateTime? nextDate = repeatableService!.getRepeatDate(
          model: template!.copyWith(
        originalDue: reminders[0].originalDue,
      ));

      expect(null != nextDate, true, reason: "Null start date");

      Reminder projection = template.copyWith(
        dueDate: nextDate,
        originalDue: nextDate,
        repeatable: true,
        name: "TestProjection",
        repeatableState: RepeatableState.projected,
        lastUpdated: DateTime.now(),
      );
      // update all
      await repeatableService!
          .handleRepeating(model: projection, delete: true, single: true);

      // Generate two more, one should be deleted.
      for (int i = 0; i < 2; i++) {
        repeatables = await reminderRepo!.getRepeatables(now: startDate);
        expect(repeatables.length, 1,
            reason: "Repeats didn't generate properly");
        for (Reminder repeatable in repeatables) {
          await repeatableService!.nextRepeat(model: repeatable);
        }
        startDate = startDate.copyWith(day: startDate.day + 1);
      }

      reminders = await reminderRepo!.getRepoListBy(
          sorter: ReminderSorter(
              descending: true, sortMethod: SortMethod.due_date));
      // Due to the test date, the delta will be the top item, if it's not properly deleted.

      expect(reminders.isNotEmpty, true, reason: "Query failed");
      expect(reminders.length, 4,
          reason: "Failure to apply delete delta, ${reminders.length}");
      expect(reminders[0].name, "Tester",
          reason: "Delete didn't work, ${reminders[0].name}");

      int offset = repeatableService!
          .getDateTimeDayOffset(
              start: reminders[0].startDate, end: reminders[1].startDate)
          .abs();

      expect(offset, 2,
          reason: "Delete didn't work, reminder/reminder offset: $offset");

      expect(reminders[0].dueDate, DateTime(2024, 1, 5),
          reason: "Delete didn't work, ${reminders[0].dueDate}");
    });
  });

  // Test: Generate 2 models, project 1, update all.
  // Ensure that template matches projection, generate,
  // then ensure the generated model matches the projection
  group("Projected Model, mutate all", () {
    ToDo toDo = ToDo(
        taskType: TaskType.small,
        name: 'Tester',
        expectedDuration: 0,
        originalStart: startDate,
        startDate: startDate,
        originalDue: dueDate,
        dueDate: dueDate,
        frequency: Frequency.daily,
        realDuration: 0,
        repeatSkip: 1,
        repeatable: true,
        repeatDays: List.generate(7, (i) => false),
        lastUpdated: DateTime.now());

    Deadline deadline = Deadline(
        name: 'Tester',
        repeatable: true,
        startDate: startDate,
        originalStart: startDate,
        dueDate: dueDate,
        originalDue: dueDate,
        frequency: Frequency.daily,
        repeatSkip: 1,
        repeatDays: List.generate(7, (i) => false),
        lastUpdated: DateTime.now());

    Reminder reminder = Reminder(
        name: "Tester",
        repeatDays: List.generate(7, (i) => false),
        dueDate: startDate,
        originalDue: startDate,
        repeatable: true,
        frequency: Frequency.daily,
        repeatSkip: 1,
        lastUpdated: DateTime.now());

    test("ToDo Projected update all.", () async {
      ToDo testToDo = toDo.copyWith(repeatID: Constants.generateID());
      ToDo? template =
          testToDo.copyWith(repeatableState: RepeatableState.template);
      await toDoRepo!.updateBatch([testToDo, template]);

      template = await toDoRepo!.getTemplate(repeatID: testToDo.repeatID!);
      expect(null != template, true, reason: "Likely a race condition");

      DateTime limit = DateTime(2024, 1, 4);
      DateTime startDate = DateTime(2024, 1, 1);
      DateTime testDate = DateTime(2024, 1, 20);

      List<ToDo> repeatables = [];
      while (startDate.isBefore(limit)) {
        repeatables = await toDoRepo!.getRepeatables(now: startDate);
        for (ToDo repeatable in repeatables) {
          await repeatableService!.nextRepeat(model: repeatable);
        }
        startDate = startDate.copyWith(day: startDate.day + 1);
      }

      List<ToDo> toDos = await toDoRepo!.getRepoList();

      expect(toDos.length, 3, reason: "Generated too many/few");

      // Create a projection.

      DateTime? nextDate = repeatableService!.getRepeatDate(
          model: template!.copyWith(
        originalStart: toDos[0].originalStart,
      ));

      expect(null != nextDate, true, reason: "Null start date");

      int offset = repeatableService!.getDateTimeDayOffset(
          start: template.startDate, end: template.dueDate);

      DateTime? nextDue = nextDate?.copyWith(day: nextDate.day + offset);

      ToDo projection = template.copyWith(
        startDate: nextDate,
        originalStart: nextDate,
        originalDue: nextDue,
        dueDate: testDate,
        completed: false,
        repeatable: true,
        name: "TestProjection",
        weight: 1,
        repeatableState: RepeatableState.projected,
        lastUpdated: DateTime.now(),
      );

      // update all - creates the model
      await repeatableService!
          .handleRepeating(model: projection, delete: false, single: false);

      // Generate one more, from the newly updated date.
      for (int i = 0; i < 2; i++) {
        repeatables = await toDoRepo!.getRepeatables(now: startDate);
        expect(repeatables.length == 1 || repeatables.isEmpty, true,
            reason: "Repeats didn't generate properly");
        for (ToDo repeatable in repeatables) {
          await repeatableService!.nextRepeat(model: repeatable);
        }
        startDate = startDate.copyWith(day: startDate.day + 1);
      }

      toDos = await toDoRepo!.getRepoListBy(
          sorter:
              ToDoSorter(descending: true, sortMethod: SortMethod.due_date));
      // Due to the test date, the delta will be the top item.

      expect(toDos.isNotEmpty, true, reason: "Query failed");
      expect(toDos.length, 5, reason: "Generation failure, ${toDos.length}");
      expect(toDos[0].dueDate, testDate.copyWith(day: testDate.day + 1),
          reason: "Update failed ${toDos[0].dueDate}");
      expect(toDos[0].name, "TestProjection",
          reason: "Update failed: ${toDos[0].name}");
      expect(toDos[0].weight, 1, reason: "Update failed ${toDos[0].weight}");
      expect(toDos[1].name, "TestProjection",
          reason: "template failed to modify:  ${toDos[1].name}");
      offset = repeatableService!.getDateTimeDayOffset(
          start: toDos[0].startDate, end: toDos[0].dueDate);
      expect(offset, 16, reason: "template got modified, offset:  $offset");

      expect(toDos[1].startDate, DateTime(2024, 1, 4),
          reason: "template not properly modified, ${toDos[1].startDate}");
      expect(toDos[1].dueDate, testDate,
          reason: "template not properly modified, ${toDos[1].dueDate}");
    });

    test("Deadline Projected update all.", () async {
      Deadline testDeadline =
          deadline.copyWith(repeatID: Constants.generateID());
      Deadline? template =
          testDeadline.copyWith(repeatableState: RepeatableState.template);
      await deadlineRepo!.updateBatch([testDeadline, template]);

      template =
          await deadlineRepo!.getTemplate(repeatID: testDeadline.repeatID!);
      expect(null != template, true, reason: "Likely a race condition");

      DateTime limit = DateTime(2024, 1, 4);
      DateTime startDate = DateTime(2024, 1, 1);
      DateTime testDate = DateTime(2024, 1, 20);

      List<Deadline> repeatables = [];
      while (startDate.isBefore(limit)) {
        repeatables = await deadlineRepo!.getRepeatables(now: startDate);
        for (Deadline repeatable in repeatables) {
          await repeatableService!.nextRepeat(model: repeatable);
        }
        startDate = startDate.copyWith(day: startDate.day + 1);
      }

      List<Deadline> deadlines = await deadlineRepo!.getRepoList();

      expect(deadlines.length, 3, reason: "Generated too many/few");

      // Create a projection.

      DateTime? nextDate = repeatableService!.getRepeatDate(
          model: template!.copyWith(
        originalStart: deadlines[0].startDate,
      ));

      expect(null != nextDate, true, reason: "Null start date");

      int offset = repeatableService!.getDateTimeDayOffset(
          start: template.startDate, end: template.dueDate);

      DateTime? nextDue = nextDate?.copyWith(day: nextDate.day + offset);

      Deadline projection = template.copyWith(
        startDate: nextDate,
        originalStart: nextDate,
        originalDue: nextDue,
        dueDate: testDate,
        warnDate: testDate,
        warnMe: true,
        repeatable: true,
        name: "TestProjection",
        repeatableState: RepeatableState.projected,
        lastUpdated: DateTime.now(),
      );

      // update all - this creates a new model
      await repeatableService!
          .handleRepeating(model: projection, delete: false, single: false);

      // Generate one more.
      for (int i = 0; i < 2; i++) {
        repeatables = await deadlineRepo!.getRepeatables(now: startDate);
        expect(repeatables.isEmpty || repeatables.length == 1, true,
            reason: "Repeats didn't generate properly");
        for (Deadline repeatable in repeatables) {
          await repeatableService!.nextRepeat(model: repeatable);
        }
        startDate = startDate.copyWith(day: startDate.day + 1);
      }

      deadlines = await deadlineRepo!.getRepoListBy(
          sorter: DeadlineSorter(
              descending: true, sortMethod: SortMethod.due_date));
      // Due to the test date, the delta will be the top item.

      expect(deadlines.isNotEmpty, true, reason: "Query failed");
      expect(deadlines.length, 5,
          reason: "Generation failure, ${deadlines.length}");
      expect(deadlines[0].dueDate, testDate.copyWith(day: testDate.day + 1),
          reason: "Update failed ${deadlines[0].dueDate}");
      expect(deadlines[0].name, "TestProjection",
          reason: "Update failed: ${deadlines[0].name}");
      expect(deadlines[0].warnMe, true,
          reason: "Update failed ${deadlines[0].warnMe}");
      expect(deadlines[0].warnDate, testDate.copyWith(day: testDate.day + 1),
          reason: "Update failed ${deadlines[0].warnDate}");
      expect(deadlines[1].name, "TestProjection",
          reason: "template failed to modify ${deadlines[1].name}");
      offset = repeatableService!.getDateTimeDayOffset(
          start: deadlines[1].startDate, end: deadlines[1].dueDate);
      expect(offset, 16, reason: "template failed to modify, offset:  $offset");

      expect(deadlines[1].startDate, DateTime(2024, 1, 4),
          reason: "template failed to modify, ${deadlines[1].startDate}");
      expect(deadlines[1].dueDate, testDate,
          reason: "template failed to modify, ${deadlines[1].dueDate}");
    });

    test("Reminder Projected update all.", () async {
      Reminder testReminder =
          reminder.copyWith(repeatID: Constants.generateID());
      Reminder? template =
          testReminder.copyWith(repeatableState: RepeatableState.template);
      await reminderRepo!.updateBatch([testReminder, template]);

      template =
          await reminderRepo!.getTemplate(repeatID: testReminder.repeatID!);
      expect(null != template, true, reason: "Likely a race condition");

      DateTime limit = DateTime(2024, 1, 4);
      DateTime startDate = DateTime(2024, 1, 1);
      DateTime testDate = DateTime(2024, 1, 20);

      List<Reminder> repeatables = [];
      while (startDate.isBefore(limit)) {
        repeatables = await reminderRepo!.getRepeatables(now: startDate);
        for (Reminder repeatable in repeatables) {
          await repeatableService!.nextRepeat(model: repeatable);
        }
        startDate = startDate.copyWith(day: startDate.day + 1);
      }

      List<Reminder> reminders = await reminderRepo!.getRepoList();

      expect(reminders.length, 3, reason: "Generated too many/few");

      // Create a projection.

      DateTime? nextDate = repeatableService!.getRepeatDate(
          model: template!.copyWith(
        originalDue: reminders[0].dueDate,
      ));

      expect(null != nextDate, true, reason: "Null start date");

      int offset = repeatableService!.getDateTimeDayOffset(
          start: template.startDate, end: template.dueDate);

      DateTime? nextDue = nextDate?.copyWith(day: nextDate.day + offset);

      Reminder projection = template.copyWith(
        originalDue: nextDue,
        dueDate: testDate,
        repeatable: true,
        name: "TestProjection",
        repeatableState: RepeatableState.projected,
        lastUpdated: DateTime.now(),
      );
      // update all - creates a model
      await repeatableService!
          .handleRepeating(model: projection, delete: false, single: false);

      // Due date bumped to test date to keep repeating going.
      startDate = testDate;

      for (int i = 0; i < 2; i++) {
        // Generate one more, second was generated during the update.
        repeatables = await reminderRepo!.getRepeatables(now: startDate);
        expect(repeatables.isEmpty || repeatables.length == 1, true,
            reason: "Repeats didn't generate properly");
        for (Reminder repeatable in repeatables) {
          await repeatableService!.nextRepeat(model: repeatable);
        }
        startDate = startDate.copyWith(day: startDate.day + 1);
      }

      reminders = await reminderRepo!.getRepoListBy(
          sorter: ReminderSorter(
              descending: true, sortMethod: SortMethod.due_date));
      // Due to the test date, the deltas will be the top items .

      expect(reminders.isNotEmpty, true, reason: "Query failed");
      expect(reminders.length, 5,
          reason: "Generation failure, ${reminders.length}");
      expect(reminders[0].dueDate, testDate.copyWith(day: testDate.day + 1),
          reason: "Template failed to update ${reminders[0].dueDate}");
      expect(reminders[0].name, "TestProjection",
          reason: "Template failed to update: ${reminders[0].name}");
      expect(reminders[1].name, "TestProjection",
          reason: "Template failed to update ${reminders[1].name}");

      expect(reminders[1].dueDate, testDate,
          reason: "template failed to modify, ${reminders[1].dueDate}");
    });
  });

  // Test: Generate 2 models, project 1, delete all.
  // Delete the template, ensure getTemplate is null
  // Ensure that trying to generate next forces null -> Freq.once
  group("Projected model, delete all", () {
    ToDo toDo = ToDo(
        taskType: TaskType.small,
        name: 'Tester',
        expectedDuration: 0,
        originalStart: startDate,
        startDate: startDate,
        originalDue: dueDate,
        dueDate: dueDate,
        frequency: Frequency.daily,
        realDuration: 0,
        repeatSkip: 1,
        repeatable: true,
        repeatDays: List.generate(7, (i) => false),
        lastUpdated: DateTime.now());

    Deadline deadline = Deadline(
        name: 'Tester',
        repeatable: true,
        startDate: startDate,
        originalStart: startDate,
        dueDate: dueDate,
        originalDue: dueDate,
        frequency: Frequency.daily,
        repeatSkip: 1,
        repeatDays: List.generate(7, (i) => false),
        lastUpdated: DateTime.now());

    Reminder reminder = Reminder(
        name: "Tester",
        repeatDays: List.generate(7, (i) => false),
        dueDate: startDate,
        originalDue: startDate,
        repeatable: true,
        frequency: Frequency.daily,
        repeatSkip: 1,
        lastUpdated: DateTime.now());

    test("ToDo Projected delete all.", () async {
      ToDo testToDo = toDo.copyWith(repeatID: Constants.generateID());
      ToDo? template =
          testToDo.copyWith(repeatableState: RepeatableState.template);
      await toDoRepo!.updateBatch([testToDo, template]);

      template = await toDoRepo!.getTemplate(repeatID: testToDo.repeatID!);
      expect(null != template, true, reason: "Likely a race condition");

      DateTime limit = DateTime(2024, 1, 4);
      DateTime startDate = DateTime(2024, 1, 1);
      DateTime testDate = DateTime(2024, 1, 20);

      List<ToDo> repeatables = [];
      while (startDate.isBefore(limit)) {
        repeatables = await toDoRepo!.getRepeatables(now: startDate);
        for (ToDo repeatable in repeatables) {
          await repeatableService!.nextRepeat(model: repeatable);
        }
        startDate = startDate.copyWith(day: startDate.day + 1);
      }

      List<ToDo> toDos = await toDoRepo!.getRepoList();

      expect(toDos.length, 3, reason: "Generated too many/few");

      // Create a projection.

      DateTime? nextDate = repeatableService!.getRepeatDate(
          model: template!.copyWith(
        originalStart: toDos[0].originalStart,
      ));

      expect(null != nextDate, true, reason: "Null start date");

      int offset = repeatableService!.getDateTimeDayOffset(
          start: template.startDate, end: template.dueDate);

      DateTime? nextDue = nextDate?.copyWith(day: nextDate.day + offset);

      ToDo projection = template.copyWith(
        startDate: nextDate,
        originalStart: nextDate,
        originalDue: nextDue,
        dueDate: testDate,
        completed: false,
        repeatable: true,
        name: "TestProjection",
        weight: 1,
        repeatableState: RepeatableState.projected,
        lastUpdated: DateTime.now(),
      );

      // delete all - deletes the template, preventing new repeating.
      await repeatableService!
          .handleRepeating(model: projection, delete: true, single: false);

      // Try generating more data.
      for (int i = 0; i < 2; i++) {
        repeatables = await toDoRepo!.getRepeatables(now: startDate);
        for (ToDo repeatable in repeatables) {
          await repeatableService!.nextRepeat(model: repeatable);
        }
        startDate = startDate.copyWith(day: startDate.day + 1);
      }

      toDos = await toDoRepo!.getRepoListBy(
          sorter:
              ToDoSorter(descending: true, sortMethod: SortMethod.due_date));

      template = await toDoRepo!.getTemplate(repeatID: testToDo.repeatID!);

      expect(template, null, reason: "Template failed to delete");
      expect(toDos.isNotEmpty, true, reason: "Query failed");
      expect(toDos.length, 3, reason: "Delete failure, ${toDos.length}");
      expect(toDos[0].name, "Tester",
          reason: "Update failed: ${toDos[0].name}");

      expect(toDos[0].startDate, DateTime(2024, 1, 3),
          reason: "Failed to delete, ${toDos[0].startDate}");
    });

    test("Deadline Projected delete all.", () async {
      Deadline testDeadline =
          deadline.copyWith(repeatID: Constants.generateID());
      Deadline? template =
          testDeadline.copyWith(repeatableState: RepeatableState.template);
      await deadlineRepo!.updateBatch([testDeadline, template]);

      template =
          await deadlineRepo!.getTemplate(repeatID: testDeadline.repeatID!);
      expect(null != template, true, reason: "Likely a race condition");

      DateTime limit = DateTime(2024, 1, 4);
      DateTime startDate = DateTime(2024, 1, 1);
      DateTime testDate = DateTime(2024, 1, 20);

      List<Deadline> repeatables = [];
      while (startDate.isBefore(limit)) {
        repeatables = await deadlineRepo!.getRepeatables(now: startDate);
        for (Deadline repeatable in repeatables) {
          await repeatableService!.nextRepeat(model: repeatable);
        }
        startDate = startDate.copyWith(day: startDate.day + 1);
      }

      List<Deadline> deadlines = await deadlineRepo!.getRepoList();

      expect(deadlines.length, 3, reason: "Generated too many/few");

      // Create a projection.

      DateTime? nextDate = repeatableService!.getRepeatDate(
          model: template!.copyWith(
        originalStart: deadlines[0].startDate,
      ));

      expect(null != nextDate, true, reason: "Null start date");

      int offset = repeatableService!.getDateTimeDayOffset(
          start: template.startDate, end: template.dueDate);

      DateTime? nextDue = nextDate?.copyWith(day: nextDate.day + offset);

      Deadline projection = template.copyWith(
        startDate: nextDate,
        originalStart: nextDate,
        originalDue: nextDue,
        dueDate: testDate,
        warnDate: testDate,
        warnMe: true,
        repeatable: true,
        name: "TestProjection",
        repeatableState: RepeatableState.projected,
        lastUpdated: DateTime.now(),
      );

      // update all - this creates a new model
      await repeatableService!
          .handleRepeating(model: projection, delete: true, single: false);

      // Test generating.
      for (int i = 0; i < 2; i++) {
        repeatables = await deadlineRepo!.getRepeatables(now: startDate);
        for (Deadline repeatable in repeatables) {
          await repeatableService!.nextRepeat(model: repeatable);
        }
        startDate = startDate.copyWith(day: startDate.day + 1);
      }

      deadlines = await deadlineRepo!.getRepoListBy(
          sorter: DeadlineSorter(
              descending: true, sortMethod: SortMethod.due_date));

      template =
          await deadlineRepo!.getTemplate(repeatID: testDeadline.repeatID!);

      expect(template, null, reason: "Template failed to delete");
      expect(deadlines.isNotEmpty, true, reason: "Query failed");
      expect(deadlines.length, 3,
          reason: "Delete failure, ${deadlines.length}");
      expect(deadlines[0].dueDate, DateTime(2024, 1, 4),
          reason: "Delete failed ${deadlines[0].dueDate}");
      expect(deadlines[0].name, "Tester",
          reason: "Delete failed: ${deadlines[0].name}");
      expect(deadlines[0].warnMe, false,
          reason: "Delete failed ${deadlines[0].warnMe}");
    });

    test("Reminder Projected delete all.", () async {
      Reminder testReminder =
          reminder.copyWith(repeatID: Constants.generateID());
      Reminder? template =
          testReminder.copyWith(repeatableState: RepeatableState.template);
      await reminderRepo!.updateBatch([testReminder, template]);

      template =
          await reminderRepo!.getTemplate(repeatID: testReminder.repeatID!);
      expect(null != template, true, reason: "Likely a race condition");

      DateTime limit = DateTime(2024, 1, 4);
      DateTime startDate = DateTime(2024, 1, 1);
      DateTime testDate = DateTime(2024, 1, 20);

      List<Reminder> repeatables = [];
      while (startDate.isBefore(limit)) {
        repeatables = await reminderRepo!.getRepeatables(now: startDate);
        for (Reminder repeatable in repeatables) {
          await repeatableService!.nextRepeat(model: repeatable);
        }
        startDate = startDate.copyWith(day: startDate.day + 1);
      }

      List<Reminder> reminders = await reminderRepo!.getRepoList();

      expect(reminders.length, 3, reason: "Generated too many/few");

      // Create a projection.

      DateTime? nextDate = repeatableService!.getRepeatDate(
          model: template!.copyWith(
        originalDue: reminders[0].dueDate,
      ));

      expect(null != nextDate, true, reason: "Null start date");

      int offset = repeatableService!.getDateTimeDayOffset(
          start: template.startDate, end: template.dueDate);

      DateTime? nextDue = nextDate?.copyWith(day: nextDate.day + offset);

      Reminder projection = template.copyWith(
        originalDue: nextDue,
        dueDate: testDate,
        repeatable: true,
        name: "TestProjection",
        repeatableState: RepeatableState.projected,
        lastUpdated: DateTime.now(),
      );
      // update all - creates a model
      await repeatableService!
          .handleRepeating(model: projection, delete: true, single: false);

      // Due date bumped to test date to keep repeating going.
      startDate = testDate;

      // Test generating
      for (int i = 0; i < 2; i++) {
        repeatables = await reminderRepo!.getRepeatables(now: startDate);
        for (Reminder repeatable in repeatables) {
          await repeatableService!.nextRepeat(model: repeatable);
        }
        startDate = startDate.copyWith(day: startDate.day + 1);
      }

      reminders = await reminderRepo!.getRepoListBy(
          sorter: ReminderSorter(
              descending: true, sortMethod: SortMethod.due_date));

      template =
          await reminderRepo!.getTemplate(repeatID: testReminder.repeatID!);

      expect(template, null, reason: "Template failed to delete");

      expect(reminders.isNotEmpty, true, reason: "Query failed");
      expect(reminders.length, 3,
          reason: "Delete failure, ${reminders.length}");
      expect(reminders[0].dueDate, DateTime(2024, 1, 3),
          reason: "Template failed to delete ${reminders[0].dueDate}");
      expect(reminders[0].name, "Tester",
          reason: "Template failed to delete: ${reminders[0].name}");
    });
  });

  // Tests with null data pls.
  group("Invalid Repeating", () {
    ToDo toDo = ToDo(
        taskType: TaskType.small,
        name: 'Tester',
        expectedDuration: 0,
        originalStart: startDate,
        startDate: startDate,
        originalDue: dueDate,
        dueDate: dueDate,
        frequency: Frequency.daily,
        realDuration: 0,
        repeatSkip: 1,
        repeatable: true,
        repeatDays: List.generate(7, (i) => false),
        lastUpdated: DateTime.now());

    Deadline deadline = Deadline(
        name: 'Tester',
        repeatable: true,
        startDate: startDate,
        originalStart: startDate,
        dueDate: dueDate,
        originalDue: dueDate,
        frequency: Frequency.daily,
        repeatSkip: 1,
        repeatDays: List.generate(7, (i) => false),
        lastUpdated: DateTime.now());

    Reminder reminder = Reminder(
        name: "Tester",
        repeatDays: List.generate(7, (i) => false),
        dueDate: startDate,
        originalDue: startDate,
        repeatable: true,
        frequency: Frequency.daily,
        repeatSkip: 1,
        lastUpdated: DateTime.now());

    test("ToDo Update All: Invalid data", () async {
      ToDo testToDo = toDo.copyWith(repeatID: Constants.generateID());
      ToDo? template =
          testToDo.copyWith(repeatableState: RepeatableState.template);
      await toDoRepo!.updateBatch([testToDo, template]);

      template = await toDoRepo!.getTemplate(repeatID: testToDo.repeatID!);
      expect(null != template, true, reason: "Likely a race condition");

      DateTime limit = DateTime(2024, 1, 4);
      DateTime startDate = DateTime(2024, 1, 1);

      ToDo? testMutate;
      List<ToDo> repeatables = [];
      while (startDate.isBefore(limit)) {
        repeatables = await toDoRepo!.getRepeatables(now: startDate);
        for (ToDo repeatable in repeatables) {
          if (repeatable.startDate == DateTime(2024, 1, 2)) {
            testMutate = repeatable;
          }
          await repeatableService!.nextRepeat(model: repeatable);
        }
        startDate = startDate.copyWith(day: startDate.day + 1);
      }

      List<ToDo> toDos = await toDoRepo!.getRepoList();

      expect(toDos.length, 3, reason: "Generated too many/few");

      expect(null != testMutate, true, reason: "repeatables set improperly");

      ToDo? testQuery = await toDoRepo!.getByID(id: testMutate!.id);
      expect(null != testQuery, true, reason: "ToDo not properly stored");

      // Mutating data
      testQuery!.weight = 4;
      testQuery.name = "NewTester";
      testQuery.expectedDuration = 1000;
      // Offset of zero
      testQuery.startDate = null;
      testQuery.dueDate = null;

      // try to update all

      expect(
        () async => await repeatableService!
            .handleRepeating(model: testQuery, delete: false, single: false),
        throwsA(const TypeMatcher<InvalidRepeatingException>()),
        reason: "Exception did not throw",
      );
    });

    //Deadline
    test("Deadline update all: Invalid Data", () async {
      Deadline testDeadline =
          deadline.copyWith(repeatID: Constants.generateID());
      Deadline? template =
          testDeadline.copyWith(repeatableState: RepeatableState.template);
      await deadlineRepo!.updateBatch([testDeadline, template]);

      template =
          await deadlineRepo!.getTemplate(repeatID: testDeadline.repeatID!);
      expect(null != template, true, reason: "Likely a race condition");

      DateTime limit = DateTime(2024, 1, 4);
      DateTime startDate = DateTime(2024, 1, 1);

      Deadline? testMutate;
      List<Deadline> repeatables = [];
      while (startDate.isBefore(limit)) {
        repeatables = await deadlineRepo!.getRepeatables(now: startDate);
        for (Deadline repeatable in repeatables) {
          if (repeatable.startDate == DateTime(2024, 1, 2)) {
            testMutate = repeatable;
          }
          await repeatableService!.nextRepeat(model: repeatable);
        }
        startDate = startDate.copyWith(day: startDate.day + 1);
      }

      List<Deadline> deadlines = await deadlineRepo!.getRepoList();

      expect(deadlines.length, 3, reason: "Generated too many/few");

      expect(null != testMutate, true, reason: "repeatables set improperly");

      Deadline? testQuery = await deadlineRepo!.getByID(id: testMutate!.id);
      expect(null != testQuery, true, reason: "Deadline not properly stored");

      // suppose some data has been changed, "update all."
      testQuery!.warnDate = limit;
      // These are just arbitrary numbers
      testQuery.warnMe = true;
      testQuery.name = "TestNew";
      testQuery.startDate = null;
      testQuery.dueDate = null;

      expect(
        () async => await repeatableService!
            .handleRepeating(model: testQuery, delete: false, single: false),
        throwsA(const TypeMatcher<InvalidRepeatingException>()),
        reason: "Exception did not throw",
      );
    });

    // Reminders
    test("Reminder update all: Invalid Data", () async {
      Reminder testReminder =
          reminder.copyWith(repeatID: Constants.generateID());
      Reminder? template =
          testReminder.copyWith(repeatableState: RepeatableState.template);
      await reminderRepo!.updateBatch([testReminder, template]);

      template =
          await reminderRepo!.getTemplate(repeatID: testReminder.repeatID!);
      expect(null != template, true, reason: "Likely a race condition");

      DateTime limit = DateTime(2024, 1, 4);
      DateTime startDate = DateTime(2024, 1, 1);

      Reminder? testMutate;
      List<Reminder> repeatables = [];
      while (startDate.isBefore(limit)) {
        repeatables = await reminderRepo!.getRepeatables(now: startDate);
        for (Reminder repeatable in repeatables) {
          if (repeatable.startDate == DateTime(2024, 1, 2)) {
            testMutate = repeatable;
          }
          await repeatableService!.nextRepeat(model: repeatable);
        }
        startDate = startDate.copyWith(day: startDate.day + 1);
      }

      List<Reminder> reminders = await reminderRepo!.getRepoList();

      expect(reminders.length, 3, reason: "Generated too many/few");

      expect(null != testMutate, true, reason: "repeatables set improperly");

      Reminder? testQuery = await reminderRepo!.getByID(id: testMutate!.id);
      expect(null != testQuery, true, reason: "Reminder not properly stored");

      // suppose some data has been changed, "update single."
      testQuery!.name = "NewTest";
      testQuery.dueDate = null;

      // try updating with invalid data.
      expect(
        () async => await repeatableService!
            .handleRepeating(model: testQuery, delete: false, single: false),
        throwsA(const TypeMatcher<InvalidRepeatingException>()),
        reason: "Exception did not throw",
      );
    });

    test("ToDo Projected update all: Invalid Data.", () async {
      ToDo testToDo = toDo.copyWith(repeatID: Constants.generateID());
      ToDo? template =
          testToDo.copyWith(repeatableState: RepeatableState.template);
      await toDoRepo!.updateBatch([testToDo, template]);

      template = await toDoRepo!.getTemplate(repeatID: testToDo.repeatID!);
      expect(null != template, true, reason: "Likely a race condition");

      DateTime limit = DateTime(2024, 1, 4);
      DateTime startDate = DateTime(2024, 1, 1);

      List<ToDo> repeatables = [];
      while (startDate.isBefore(limit)) {
        repeatables = await toDoRepo!.getRepeatables(now: startDate);
        for (ToDo repeatable in repeatables) {
          await repeatableService!.nextRepeat(model: repeatable);
        }
        startDate = startDate.copyWith(day: startDate.day + 1);
      }

      List<ToDo> toDos = await toDoRepo!.getRepoList();

      expect(toDos.length, 3, reason: "Generated too many/few");

      // Create a projection.

      DateTime? nextDate = repeatableService!.getRepeatDate(
          model: template!.copyWith(
        originalStart: toDos[0].originalStart,
      ));

      expect(null != nextDate, true, reason: "Null start date");

      ToDo projection = template.copyWith(
        completed: false,
        repeatable: true,
        name: "TestProjection",
        weight: 1,
        repeatableState: RepeatableState.projected,
        lastUpdated: DateTime.now(),
      );

      projection.startDate = null;
      projection.dueDate = null;

      // try to update all
      expect(
        () async => await repeatableService!
            .handleRepeating(model: projection, delete: false, single: false),
        throwsA(const TypeMatcher<InvalidRepeatingException>()),
        reason: "Exception did not throw",
      );
    });

    test("Deadline Projected update all: Invalid Data", () async {
      Deadline testDeadline =
          deadline.copyWith(repeatID: Constants.generateID());
      Deadline? template =
          testDeadline.copyWith(repeatableState: RepeatableState.template);
      await deadlineRepo!.updateBatch([testDeadline, template]);

      template =
          await deadlineRepo!.getTemplate(repeatID: testDeadline.repeatID!);
      expect(null != template, true, reason: "Likely a race condition");

      DateTime limit = DateTime(2024, 1, 4);
      DateTime startDate = DateTime(2024, 1, 1);

      List<Deadline> repeatables = [];
      while (startDate.isBefore(limit)) {
        repeatables = await deadlineRepo!.getRepeatables(now: startDate);
        for (Deadline repeatable in repeatables) {
          await repeatableService!.nextRepeat(model: repeatable);
        }
        startDate = startDate.copyWith(day: startDate.day + 1);
      }

      List<Deadline> deadlines = await deadlineRepo!.getRepoList();

      expect(deadlines.length, 3, reason: "Generated too many/few");

      // Create a projection.

      DateTime? nextDate = repeatableService!.getRepeatDate(
          model: template!.copyWith(
        originalStart: deadlines[0].startDate,
      ));

      expect(null != nextDate, true, reason: "Null start date");

      Deadline projection = template.copyWith(
        warnMe: true,
        repeatable: true,
        name: "TestProjection",
        repeatableState: RepeatableState.projected,
        lastUpdated: DateTime.now(),
      );

      projection.startDate = null;
      projection.dueDate = null;
      projection.warnDate = null;

      // try to update all
      expect(
        () async => await repeatableService!
            .handleRepeating(model: projection, delete: false, single: false),
        throwsA(const TypeMatcher<InvalidRepeatingException>()),
        reason: "Exception did not throw",
      );
    });

    test("Reminder Projected update all: Invalid Data", () async {
      Reminder testReminder =
          reminder.copyWith(repeatID: Constants.generateID());
      Reminder? template =
          testReminder.copyWith(repeatableState: RepeatableState.template);
      await reminderRepo!.updateBatch([testReminder, template]);

      template =
          await reminderRepo!.getTemplate(repeatID: testReminder.repeatID!);
      expect(null != template, true, reason: "Likely a race condition");

      DateTime limit = DateTime(2024, 1, 4);
      DateTime startDate = DateTime(2024, 1, 1);

      List<Reminder> repeatables = [];
      while (startDate.isBefore(limit)) {
        repeatables = await reminderRepo!.getRepeatables(now: startDate);
        for (Reminder repeatable in repeatables) {
          await repeatableService!.nextRepeat(model: repeatable);
        }
        startDate = startDate.copyWith(day: startDate.day + 1);
      }

      List<Reminder> reminders = await reminderRepo!.getRepoList();

      expect(reminders.length, 3, reason: "Generated too many/few");

      // Create a projection.

      DateTime? nextDate = repeatableService!.getRepeatDate(
          model: template!.copyWith(
        originalDue: reminders[0].dueDate,
      ));

      expect(null != nextDate, true, reason: "Null start date");

      int offset = repeatableService!.getDateTimeDayOffset(
          start: template.startDate, end: template.dueDate);

      Reminder projection = template.copyWith(
        repeatable: true,
        name: "TestProjection",
        repeatableState: RepeatableState.projected,
        lastUpdated: DateTime.now(),
      );
      projection.dueDate = null;

      // try to update all
      expect(
        () async => await repeatableService!
            .handleRepeating(model: projection, delete: false, single: false),
        throwsA(const TypeMatcher<InvalidRepeatingException>()),
        reason: "Exception did not throw",
      );
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
  repeatableService = RepeatableService();
  toDoRepo = ToDoRepo();
  deadlineRepo = DeadlineRepo();
  reminderRepo = ReminderRepo();
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
  repeatableService = null;
}
