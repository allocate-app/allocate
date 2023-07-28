import "package:allocate/model/task/todo.dart";
import "package:allocate/util/exceptions.dart";
import "package:fake_async/fake_async.dart";
import "package:isar/isar.dart";
import "package:jiffy/jiffy.dart";
import "package:mocktail/mocktail.dart";
import "package:test/test.dart";

import "../model/task/subtask.dart";
import "../providers/todo_provider.dart";
import "../services/isar_service.dart";
import "../util/enums.dart";

/// Testing:
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
///   - Test failcache:
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
Isar? isarClient;
ToDoProvider? provider;

void main(){
  setUp(initTesting);
  tearDown(closeTesting);

  group("IsarService tests", () {

    test("Initialization and closing", () async {
      expect(null != isarClient, true, reason: "Isar client failed to initialize");
      expect(null != provider, true, reason: "Provider failed to initialize");

      int? count = await isarClient?.toDos.count();

      expect(count != null, true, reason: "Collection is null");
      expect(count, 0, reason: "Database failed to clear");

      closeTesting();

      expect(isarClient, null, reason: "Isar: Client failed to close");
      expect(provider, null, reason: "Provider: Client failed to close.");
    });
  });

  group("ToDo Create", () {
    test("ToDo creation: min requirements + defaults", () async {
      expect(null != provider, true, reason: "Provider is null");
      await provider!.createToDo(taskType: TaskType.small, name: 'TestSM');
      int count = await isarClient?.toDos.count() ?? 0;
      expect(count, 1, reason: "toDo not placed in database \n"
          "Provider todos: ${provider!.todos.toString()}");

      expect(provider!.failCache.isEmpty, true, reason: "Update/Upload thrown \n ${provider!.failCache.toString()}");
    });


  });

  group("ToDo Update", () {

    test("ListLimitExceeded thrown when subtask limit exceeded.", () async {
      await provider!.createToDo(taskType: TaskType.small, name: "TestSM");
      expect(null != provider?.curToDo, true, reason: "Create failed");

      // TODO: refactor this once getByID implemented.
      await provider!.getToDosBy();

      expect(provider?.addSubTask(name: "TestSubTask", weight: 1), throwsA(ListLimitExceededException), reason:"Failed to throw");
      expect(provider!.failCache.isEmpty, true, reason: "Update/Upload thrown \n ${provider!.failCache.toString()}");

    });

    test("Update ToDo Data", () async {
      await provider!.createToDo(taskType: TaskType.small, name: "TestSM");
      expect(null != provider?.curToDo, true, reason: "Create failed");

      // TODO: refactor this once getByID implemented.
      await provider!.getToDosBy();

      ToDo? tmp = provider?.curToDo;
      expect(tmp != null, true, reason: "Temp is null");

      await provider!.updateToDo(
        taskType: TaskType.large,
        priority: Priority.high,
        subTasks: [SubTask(name: "ST1", weight: 1), SubTask(name: "ST2", weight: 2)]
      );
      expect(tmp != provider!.curToDo, true, reason: "Data failed to update");

      // TODO: refactor once getByID() implemented.
      await provider!.getToDosBy();
      ToDo? test = provider!.todos.firstOrNull;
      expect(null != test, true, reason: "null ToDo failed to grab from db");
      provider!.curToDo = test ?? provider!.curToDo;
      expect(provider!.curToDo.weight, 3, reason: "Weight failed to recalculate\n"
          "Expected: 3, Actual ${provider!.curToDo.weight}");
      expect(provider!.failCache.isEmpty, true, reason: "Update/Upload thrown \n ${provider!.failCache.toString()}");

    });

    test("Update ToDo Subtasks", () async {
      await provider!.createToDo(taskType: TaskType.large, name: "TestSM", subTasks: [SubTask(name: "ST1", weight: 1), SubTask(name: "ST2", weight: 2)]);

      expect(null != provider?.curToDo, true, reason: "Create failed");

      // TODO: refactor this once getByID implemented.
      await provider!.getToDosBy();

      await provider!.addSubTask(name: "ST3", weight: 3);
      expect(0 != provider!.curToDo.weight, true, reason: "Weight is null");
      expect(provider!.curToDo.weight, 6, reason: "Weight failed to calculate"
          "Expected: 6, Actual: ${provider!.curToDo.weight}");

      await provider!.updateSubTask(subTask: SubTask(name: "ST3", weight: 3), name: "mST3", weight: 2);
      SubTask? newST =(provider!.curToDo.subTasks.isNotEmpty) ? provider!.curToDo.subTasks.last : null;
      expect(null != newST, true, reason: "newST is null");
      expect(newST?.name, "mST3", reason: "Failed to update subtask name \n"
          "newST: ${newST?.name}");
      expect(provider!.curToDo.weight, 5, reason: "Weight calculations failed\n"
          "Expected: 5, Actual: ${provider!.curToDo.weight}");

      expect(provider!.failCache.isEmpty, true, reason: "Update/Upload thrown \n ${provider!.failCache.toString()}");


    });
    test("Reorder ToDo Subtasks", () async {
      List<SubTask> wrongOrder = [SubTask(name: "ST1", weight: 1), SubTask(name: "ST2", weight: 2), SubTask(name: "ST3", weight: 3)];
      List<SubTask> expectedOrder = [SubTask(name: "ST3", weight: 3), SubTask(name: "ST1", weight:1), SubTask(name: "ST2", weight: 2)];

      await provider!.createToDo(taskType: TaskType.large, name: "TestSM", subTasks: wrongOrder);
      expect(null != provider?.curToDo, true, reason: "Create failed");

      //TODO: refactor when getByID implemented;
      await provider!.getToDosBy();

      ToDo? test = provider!.todos.firstOrNull;
      expect(null != test, true, reason: "null ToDo failed to grab from db");
      provider!.curToDo = test ?? provider!.curToDo;

      await provider!.reorderSubTasks(oldIndex: 2, newIndex: 0);
      await provider!.getToDosBy();
      test = provider!.todos.firstOrNull;

      expect(null != test, true, reason: "null ToDo, failed to grab from db again");
      expect(provider!.curToDo == test, true, reason: "Failed to update ToDo in db\n"
          "Todo: ${provider!.curToDo}\n"
          "Test: $test");

      provider!.curToDo = test ?? provider!.curToDo;

      List<SubTask> cmpList = provider!.curToDo.subTasks;


      expect(cmpList.toString().compareTo(expectedOrder.toString()), 0, reason: "Reordering failed\n"
          "CurToDo: ${cmpList.toString()}\n"
          "Expected: ${expectedOrder.toString()}");

      expect(provider!.failCache.isEmpty, true, reason: "Update/Upload thrown \n ${provider!.failCache.toString()}");
    });
  });

  group("ToDo Read", () {
    // Define two ToDos and use a list to compare.

    ToDo td1 = ToDo( taskType: TaskType.small,
      name: "a",
      startDate: DateTime.now(),
      dueDate: DateTime.now().add(const Duration(hours: 1)),
      weight: 2,
      expectedDuration: 3600,
      realDuration: 0, repeatDays: List.filled(7, false),
      subTasks: List.empty(growable: false),
      priority: Priority.low,


    );
    ToDo td2 = ToDo( taskType: TaskType.small,
      name: "b",
      startDate: DateTime.now(),
      dueDate: DateTime.now().add(const Duration(hours: 2)),
      weight: 3,
      expectedDuration: 3600,
      realDuration: 0,
      repeatDays: List.filled(7, false),
      subTasks: List.empty(growable: false),
      priority: Priority.high,
    );
    String td1First = [td1, td2].toString();
    String td2First = [td2, td1].toString();


    test("Insertion: 2 todos ", () async {
      provider!.curToDo = td1;
      provider!.curToDo.customViewIndex = 1;
      await provider!.recalculateRealDuration();
      provider!.curToDo = td2;
      provider!.curToDo.customViewIndex = 0;
      await provider!.recalculateRealDuration();
      await provider!.getToDos();
      expect(provider!.todos.length == 2, true, reason: "Insertion failure\n"
      "Provider todos: ${provider!.todos.toString()}");

      expect(provider!.failCache.isEmpty, true, reason: "Update/Upload thrown \n ${provider!.failCache.toString()}");

    });

    // TODO: implement get by id.
    // Wrong id ->

    // My Day
    test("My Day", () async {
      provider!.curToDo = td1;
      provider!.curToDo.customViewIndex = 1;
      await provider!.recalculateRealDuration();
      provider!.curToDo = td2;
      provider!.curToDo.customViewIndex = 0;
      await provider!.recalculateRealDuration();

      await provider!.getToDos();
      expect(provider!.todos.length == 2, true, reason: "Insertion failure\n"
          "Provider todos: ${provider!.todos.toString()}");

      provider!.curToDo = provider!.todos.firstOrNull ?? td1;

      await provider!.updateToDo(myDay: true);

      await provider!.getMyDay();

      expect(provider!.todos.length, 1, reason: "Failed to set my day\n"
          "MyDay: ${provider!.todos.toString()}");

      provider!.curToDo = provider!.todos.firstOrNull ?? td1;

      await provider!.updateToDo(myDay: false);

      await provider!.getMyDay();

      expect(provider!.todos.isEmpty, true, reason: "Failed to remove from myDay\n"
          "Provider todos: ${provider!.todos.toString()}");

      expect(provider!.failCache.isEmpty, true, reason: "Update/Upload thrown \n ${provider!.failCache.toString()}");

    });

    // Completed
    test("Completed", () async {
      provider!.curToDo = td1;
      provider!.curToDo.customViewIndex = 1;
      await provider!.recalculateRealDuration();
      provider!.curToDo = td2;
      provider!.curToDo.customViewIndex = 0;
      await provider!.recalculateRealDuration();

      await provider!.getToDos();
      expect(provider!.todos.length == 2, true, reason: "Insertion failure\n"
          "Provider todos: ${provider!.todos.toString()}");

      provider!.curToDo = provider!.todos.firstOrNull ?? td1;

      await provider!.updateToDo(completed: true);
      await provider!.getCompleted();
      expect(provider!.todos.length, 1, reason: "Failed to set completion \n"
          "Provider todos: ${provider!.todos.toString()}");

      provider!.curToDo = provider!.todos.firstOrNull ?? td1;

      await provider!.updateToDo(completed: false);
      await provider!.getCompleted();

      expect(provider!.todos.isEmpty, true, reason: "Failed to remove completion\n"
          "Provider todos: ${provider!.todos.toString()}");

      expect(provider!.failCache.isEmpty, true, reason: "Update/Upload thrown \n ${provider!.failCache.toString()}");

    });

    // Sorting.
    test("ToDo sort by Name", () async {
      provider!.curToDo = td1;
      provider!.curToDo.customViewIndex = 1;
      await provider!.recalculateRealDuration();
      provider!.curToDo = td2;
      provider!.curToDo.customViewIndex = 0;
      await provider!.recalculateRealDuration();

      await provider!.getToDos();

      expect(provider!.todos.length == 2, true, reason: "Insertion failure\n"
          "Provider todos: ${provider!.todos.toString()}");

      expect(provider!.todos.toString(), td2First, reason: "Custom VI failed \n"
          "Provider todos: ${provider!.todos.toString()}\n"
          "Expected: $td2First");

      provider!.sorter.sortMethod = SortMethod.name;
      provider!.sorter.descending = false;

      await provider!.getToDosBy();

      expect(provider!.todos.toString(), td2First, reason: "Sort by name failed\n"
          "SortMethod: ${provider!.sortMethod.name}, Descending: ${provider!.descending}\n"
          "Provider todos: ${provider!.todos.toString()}\n"
          "Expected: $td1First");

      provider!.sorter.descending = true;

      expect(provider!.todos.toString(), td2First, reason: "Descending sort by name failed\n"
          "SortMethod: ${provider!.sortMethod.name}, Descending: ${provider!.descending}\n"
          "Provider todos: ${provider!.todos.toString()}\n"
          "Expected: $td2First");

      expect(provider!.failCache.isEmpty, true, reason: "Update/Upload thrown \n ${provider!.failCache.toString()}");


    });

    test("ToDo sort by dueDate", () async {
      provider!.curToDo = td1;
      provider!.curToDo.customViewIndex = 1;
      await provider!.recalculateRealDuration();
      provider!.curToDo = td2;
      provider!.curToDo.customViewIndex = 0;
      await provider!.recalculateRealDuration();

      await provider!.getToDos();

      expect(provider!.todos.length, 2, reason: "DB query failed");
      expect(provider!.todos.toString(), td2First, reason: "Custom VI failed");

      provider!.sorter.sortMethod = SortMethod.dueDate;
      provider!.sorter.descending = false;

      await provider!.getToDosBy();

      expect(provider!.todos.toString(), td2First, reason: "Sort by dueDate failed\n"
          "SortMethod: ${provider!.sortMethod.name}, Descending: ${provider!.descending}\n"
          "Provider todos: ${provider!.todos.toString()}\n"
          "Expected: $td1First");

      provider!.sorter.descending = true;

      expect(provider!.todos.toString(), td2First, reason: "Descending sort by dueDate failed\n"
          "SortMethod: ${provider!.sortMethod.name}, Descending: ${provider!.descending}\n"
          "Provider todos: ${provider!.todos.toString()}\n"
          "Expected: $td2First");

      expect(provider!.failCache.isEmpty, true, reason: "Update/Upload thrown \n ${provider!.failCache.toString()}");


    });

    test("ToDo sort by weight", () async {
      provider!.curToDo = td1;
      provider!.curToDo.customViewIndex = 1;
      await provider!.recalculateRealDuration();
      provider!.curToDo = td2;
      provider!.curToDo.customViewIndex = 0;
      await provider!.recalculateRealDuration();

      await provider!.getToDos();

      expect(provider!.todos.length, 2, reason: "DB query failed");
      expect(provider!.todos.toString(), td2First, reason: "Custom VI failed");

      provider!.sorter.sortMethod = SortMethod.weight;
      provider!.sorter.descending = false;

      await provider!.getToDosBy();

      expect(provider!.todos.toString(), td2First, reason: "Sort by weight failed\n"
          "SortMethod: ${provider!.sortMethod.name}, Descending: ${provider!.descending}\n"
          "Provider todos: ${provider!.todos.toString()}\n"
          "Expected: $td1First");

      provider!.sorter.descending = true;

      expect(provider!.todos.toString(), td2First, reason: "Descending sort by weight failed\n"
          "SortMethod: ${provider!.sortMethod.name}, Descending: ${provider!.descending}\n"
          "Provider todos: ${provider!.todos.toString()}\n"
          "Expected: $td2First");

      expect(provider!.failCache.isEmpty, true, reason: "Update/Upload thrown \n ${provider!.failCache.toString()}");


    });

    test("ToDo sort by RealDuration", () async {
      provider!.curToDo = td1;
      provider!.curToDo.customViewIndex = 1;
      await provider!.recalculateRealDuration();
      provider!.curToDo = td2;
      provider!.curToDo.customViewIndex = 0;
      await provider!.recalculateRealDuration();

      await provider!.getToDos();

      expect(provider!.todos.length, 2, reason: "DB query failed");
      expect(provider!.todos.toString(), td2First, reason: "Custom VI failed");

      provider!.sorter.sortMethod = SortMethod.duration;
      provider!.sorter.descending = false;

      await provider!.getToDosBy();

      expect(provider!.todos.toString(), td2First, reason: "Sort by Duration failed\n"
          "SortMethod: ${provider!.sortMethod.name}, Descending: ${provider!.descending}\n"
          "Provider todos: ${provider!.todos.toString()}\n"
          "Expected: $td1First");

      provider!.sorter.descending = true;

      expect(provider!.todos.toString(), td2First, reason: "Descending sort by Duration failed\n"
          "SortMethod: ${provider!.sortMethod.name}, Descending: ${provider!.descending}\n"
          "Provider todos: ${provider!.todos.toString()}\n"
          "Expected: $td2First");

      expect(provider!.failCache.isEmpty, true, reason: "Update/Upload thrown \n ${provider!.failCache.toString()}");


    });

    test("ToDo sort by Priority", () async {
      provider!.curToDo = td1;
      provider!.curToDo.customViewIndex = 1;
      await provider!.recalculateRealDuration();
      provider!.curToDo = td2;
      provider!.curToDo.customViewIndex = 0;
      await provider!.recalculateRealDuration();

      await provider!.getToDos();

      expect(provider!.todos.length, 2, reason: "DB query failed");
      expect(provider!.todos.toString(), td2First, reason: "Custom VI failed");

      provider!.sorter.sortMethod = SortMethod.priority;
      provider!.sorter.descending = false;

      await provider!.getToDosBy();

      expect(provider!.todos.toString(), td1First, reason: "Sorting by priority failed \n"
          "SortMethod: ${provider!.sortMethod.name}, Descending: ${provider!.descending}\n"
          "Provider todos: ${provider!.todos.toString()}\n"
          "Expected: $td1First");

      provider!.sorter.descending = true;

      expect(provider!.todos.toString(), td2First, reason: "Descending sort by priority failed\n"
          "SortMethod: ${provider!.sortMethod.name}, Descending: ${provider!.descending}\n"
          "Provider todos: ${provider!.todos.toString()}\n"
          "Expected: $td2First");

      expect(provider!.failCache.isEmpty, true, reason: "Update/Upload thrown \n ${provider!.failCache.toString()}");

    });

    // Reordering

    test("ToDo Reordering", () async {
      provider!.curToDo = td1;
      provider!.curToDo.customViewIndex = 1;
      await provider!.recalculateRealDuration();
      provider!.curToDo = td2;
      provider!.curToDo.customViewIndex = 0;
      await provider!.recalculateRealDuration();

      await provider!.getToDos();

      expect(provider!.todos.length, 2, reason: "DB query failed");
      expect(provider!.todos.toString(), td2First, reason: "Custom VI failed");

      provider!.reorderToDos(oldIndex: 1, newIndex: 0);

      provider!.sorter.sortMethod = SortMethod.none;
      await provider!.getToDosBy();

      expect(provider!.todos.toString(), td1First, reason: "Custom VI failed \n todos: ${provider!.todos.toString()} \n expected: $td1First");
      expect(provider!.todos.first.customViewIndex, 0, reason: "CVI not set \n todos: ${provider!.todos.toString()}");
      expect(provider!.todos.last.customViewIndex, 1, reason: "CVI not set \n todos: ${provider!.todos.toString()}");

      expect(provider!.failCache.isEmpty, true, reason: "Update/Upload thrown \n ${provider!.failCache.toString()}");
    });
  });


  group("ToDo Delete", () {
    test("ToDo Delete Routine", () async {
      await provider!.createToDo(taskType: TaskType.small, name: "TD1");
      await provider!.createToDo(taskType: TaskType.small, name: "TD2");

      await provider!.getToDos();

      expect(provider!.todos.length, 2, reason: "DB Query Failed");
      expect(provider!.syncTimer.isActive, true, reason: "Timer failed to set");

      await provider!.deleteToDo();

      // This should run the delete routine in the provider.
      fakeAsync((async) {
        async.elapse(const Duration(minutes: 1));
      });

      await provider!.getToDos();
      expect(provider!.todos.length, 1, reason: "Delete Routine failed");
      expect(provider!.todos.firstOrNull?.name, "TD1", reason: "Wrong task deleted");

      provider!.createToDo(taskType: TaskType.small, name: "TD2");
      await provider!.deleteToDo();
      await provider!.deleteToDo();
      provider!.createToDo(taskType: TaskType.small, name: "TD3");

      fakeAsync((async) {async.elapse(const Duration(minutes: 2));});

      await provider!.getToDos();

      expect(provider!.todos.length, 1, reason: "Delete Routine failed for multiple delete");

      provider!.curToDo = provider!.todos.firstOrNull ?? provider!.curToDo;

      expect(provider!.curToDo.name, "TD3", reason: "wrong todos deleted");

      expect(provider!.failCache.isEmpty, true, reason: "Update/Upload thrown \n ${provider!.failCache.toString()}");

    });
  });

  // TODO: finish these once Supabase has been set up.
  // group("Supabase", () {

  // });
  //
  // group("FailCache & Supabase", () {

  // });

  group("Recurring", () {
    test("Repeatable/Frequency.Once Failsafe", () async {
      provider!.createToDo(taskType: TaskType.small,
        name: "RepeatableTest",
        repeatable: true,
        frequency: Frequency.once);

      provider!.testDate = DateTime.now().add(const Duration(days: 1));

      fakeAsync((async) {
        async.elapse(const Duration(days: 1, minutes: 1));
      });

      // This is just to let the async function catch up.
      await Future.delayed(const Duration(seconds: 3));
      await provider!.getToDosBy();
      expect(provider!.todos.isNotEmpty, true, reason: "Db query failed \n ToDos: ${provider!.todos.toString()}");
      expect(provider!.todos.length, 1, reason: "Repeat subroutine failed, more than one todo \n ToDos: ${provider!.todos.toString()}");

      provider!.curToDo = provider!.todos.firstOrNull ?? provider!.curToDo;

      expect(provider!.curToDo.repeatable, false, reason: "ToDo repeatable not properly removed");
      expect(provider!.failCache.isEmpty, true, reason: "Update/Upload thrown \n ${provider!.failCache.toString()}");



    });
    test("Daily Recurrence", () async {
      provider!.sorter.sortMethod = SortMethod.dueDate;
      provider!.sorter.descending = true;
      provider!.testTimer.cancel();
      provider!.syncTimer.cancel();
      provider!.testDate = DateTime.now();
      provider!.startTimer();

      provider!.createToDo(taskType: TaskType.small,
      name: "DailyTest",
      repeatable: true,
      frequency: Frequency.daily);

      for(int i = 1; i < 7; i++)
        {
          provider!.testDate.add(const Duration(days: 1));
          fakeAsync((async) {
            async.elapse(const Duration(days: 1));
          });
          // This is just to let the async function catch up.
          await Future.delayed(const Duration(seconds: 5));

          await provider!.getToDosBy();
          expect(provider!.todos.length, i + 1, reason: "Daily routine incorrect, ${provider!.todos.length}/${i + 1} \n todos: ${provider!.todos.toString()}");
        }
      await Future.delayed(const Duration(seconds: 3));
      await provider!.getToDosBy();
      expect(provider!.todos.length, 7, reason: "Daily routine failed \n ToDos: ${provider!.todos.toString()}");
      expect(provider!.todos.firstOrNull?.dueDate.isAfter(provider!.curToDo.dueDate), true, reason: "Repeat copy was unsuccessful \n todos: ${provider!.todos.toString()}");
      expect(provider!.failCache.isEmpty, true, reason: "Update/Upload thrown \n ${provider!.failCache.toString()}");

    });

    test("Weekly recurrence", () async {
      provider!.sorter.sortMethod = SortMethod.dueDate;
      provider!.sorter.descending = true;
      provider!.testTimer.cancel();
      provider!.syncTimer.cancel();
      provider!.testDate = DateTime.now();
      provider!.startTimer();

      provider!.createToDo(taskType: TaskType.small,
          name: "WeeklyTest",
          repeatable: true,
          frequency: Frequency.weekly);

      for(int i = 1; i < 4; i++)
        {
          provider!.testDate.add(const Duration(days: 7));
          fakeAsync((async) {
            async.elapse(const Duration(days: 7));
          });
          // This is just to let the async function catch up.
          await Future.delayed(const Duration(seconds: 5));
          await provider!.getToDosBy();
          expect(provider!.todos.length, i + 1, reason: "Weekly routine incorrect, ${provider!.todos.length}/${i + 1}");
        }
      await Future.delayed(const Duration(seconds: 3));
      await provider!.getToDosBy();
      expect(provider!.todos.length, 4, reason: "Weekly routine failed \n ToDos: ${provider!.todos.toString()}");
      expect(provider!.todos.firstOrNull?.dueDate.isAfter(provider!.curToDo.dueDate), true, reason: "Repeat copy was unsuccessful \n ToDos: ${provider!.todos.toString()}");
      expect(provider!.failCache.isEmpty, true, reason: "Update/Upload thrown \n ${provider!.failCache.toString()}");

    });
    test("Biweekly recurrence", () async {
      provider!.sorter.sortMethod = SortMethod.dueDate;
      provider!.sorter.descending = true;
      provider!.testTimer.cancel();
      provider!.syncTimer.cancel();
      provider!.testDate = DateTime.now();
      provider!.startTimer();

      provider!.createToDo(taskType: TaskType.small,
          name: "BiweeklyTest",
          repeatable: true,
          frequency: Frequency.weekly,
          repeatSkip: 2);

      for(int i = 1; i < 4; i++)
      {
        provider!.testDate.add(const Duration(days: 7));
        fakeAsync((async) {
          async.elapse(const Duration(days: 7));
        });
      }
      // This is just to let the async function catch up.
      await Future.delayed(const Duration(seconds: 5));
      await provider!.getToDosBy();
      expect(provider!.todos.length, 2, reason: "Biweekly Repeat broken\n ToDos: ${provider!.todos.toString()}");
      expect(provider!.todos.firstOrNull?.dueDate.isAfter(provider!.curToDo.dueDate), true, reason: "Copy Routine didn't work or sorting busted \n ToDos: ${provider!.todos.toString()}");
      expect(provider!.failCache.isEmpty, true, reason: "Update/Upload thrown \n ${provider!.failCache.toString()}");

    });

    test("Monthly recurrence", () async {
      provider!.sorter.sortMethod = SortMethod.dueDate;
      provider!.sorter.descending = true;
      provider!.testTimer.cancel();
      provider!.syncTimer.cancel();
      provider!.testDate = DateTime.now();
      provider!.startTimer();

      await provider!.createToDo(taskType: TaskType.small,
          name: "MonthlyTest",
          repeatable: true,
          frequency: Frequency.monthly);

      for(int i = 1; i < 4; i++)
      {
        DateTime oldDate = provider!.testDate;
        provider!.testDate = Jiffy.parseFromDateTime(provider!.testDate).add(months: 1).dateTime;
        int month = Jiffy.parseFromDateTime(provider!.testDate).diff(Jiffy.parseFromDateTime(oldDate)) as int;
        fakeAsync((async) {
          async.elapse(Duration(microseconds: month));
        });
        // This is just to let the async function catch up.
        await Future.delayed(const Duration(seconds: 3));

        await provider!.getToDosBy();

        expect(provider!.todos.length, i + 1, reason: "Monthly copy failed: ${provider!.todos.length} / ${i + 1}");

      }

      expect(provider!.todos.length, 4, reason: "Monthly routine failed \n ToDos: ${provider!.todos.toString()}");
      expect(provider!.todos.firstOrNull?.dueDate.isAfter(provider!.curToDo.dueDate), true, reason: "Copy Routine didn't work or sorting busted \n ToDos: ${provider!.todos.toString()}");
      expect(provider!.failCache.isEmpty, true, reason: "Update/Upload thrown \n ${provider!.failCache.toString()}");
    });

    test("Yearly recurrence", () async {
      provider!.sorter.sortMethod = SortMethod.dueDate;
      provider!.sorter.descending = true;
      provider!.testTimer.cancel();
      provider!.syncTimer.cancel();
      provider!.testDate = DateTime.now();
      provider!.startTimer();

      await provider!.createToDo(taskType: TaskType.small,
      name: "YearlyTest",
      repeatable: true,
      frequency: Frequency.yearly);

      for(int i = 1; i < 4; i++)
      {
      DateTime oldDate = provider!.testDate;
      provider!.testDate = Jiffy.parseFromDateTime(provider!.testDate).add(years: 1).dateTime;
      int year = Jiffy.parseFromDateTime(provider!.testDate).diff(Jiffy.parseFromDateTime(oldDate)) as int;
      fakeAsync((async) {
      async.elapse(Duration(microseconds: year));
      });

      // This is just to let the async function catch up. Might need to be longer.
      await Future.delayed(const Duration(seconds: 3));
      await provider!.getToDosBy();
      expect(provider!.todos.length, i + 1, reason: "Yearly copy failed: ${provider!.todos.length} / ${i + 1}");

      }
      expect(provider!.todos.length, 4, reason: "Yearly routine failed \n ToDos: ${provider!.todos.toString()}");
      expect(provider!.todos.firstOrNull?.dueDate.isAfter(provider!.curToDo.dueDate), true, reason: "Copy Routine didn't work or sorting busted \n ${provider!.todos.toString()}");
      expect(provider!.failCache.isEmpty, true, reason: "Update/Upload thrown \n ${provider!.failCache.toString()}");

    });

    test("Custom recurrence: Monday-Tuesday, biweekly", () async {
      provider!.sorter.sortMethod = SortMethod.dueDate;
      provider!.sorter.descending = true;
      provider!.testTimer.cancel();
      provider!.syncTimer.cancel();
      provider!.testDate = DateTime.now();
      provider!.startTimer();

      await provider!.createToDo(taskType: TaskType.small,
      name: "Mon-Tues Biweekly",
      // This is a Monday.
      startDate: Jiffy.parse("2023 Jul 24th", pattern: "yyyy MMM do").dateTime,
      repeatable: true,
      frequency: Frequency.custom,
      customFreq: CustomFrequency.weekly,
      repeatSkip: 2,
      repeatDays: [true, true, false, false, false, false, false]);

      for(int i = 1; i < 4; i++)
      {
      DateTime oldDate = provider!.testDate;
      provider!.testDate = Jiffy.parseFromDateTime(provider!.testDate).add(weeks: 1).dateTime;
      int weeks = Jiffy.parseFromDateTime(provider!.testDate).diff(Jiffy.parseFromDateTime(oldDate)) as int;
      fakeAsync((async) {
      async.elapse(Duration(microseconds: weeks));
      });

      }
      // This is just to let the async function catch up. Might need to be longer.
      await Future.delayed(const Duration(seconds: 3));
      await provider!.getToDosBy();

      expect(provider!.todos.length, 4, reason: "Mon-Tues biweekly (custom) routine failed \n todos: ${provider!.todos.toString()}");
      expect(provider!.todos.firstOrNull?.dueDate.isAfter(provider!.curToDo.dueDate), true, reason: "Copy Routine didn't work or sorting busted \n todos: ${provider!.todos.toString()}");
      expect(provider!.failCache.isEmpty, true, reason: "Update/Upload thrown \n ${provider!.failCache.toString()}");
    });

    test("Custom recurrence: Monday-Wednesday-Friday, monthly", () async {
      provider!.sorter.sortMethod = SortMethod.dueDate;
      provider!.sorter.descending = true;
      provider!.testTimer.cancel();
      provider!.syncTimer.cancel();
      provider!.testDate = DateTime.now();
      provider!.startTimer();

      await provider!.createToDo(taskType: TaskType.small,
      name: "Mon-Wed-Fri Monthly",
      // This is a Monday.
      startDate: Jiffy.parse("2023 Jul 24th", pattern: "yyyy MMM do").dateTime,
      repeatable: true,
      frequency: Frequency.custom,
      customFreq: CustomFrequency.monthly,
      repeatSkip: 1,
      repeatDays: [true, false, true, false, true, false, false]);

      for(int i = 1; i < 5; i++)
      {
      DateTime oldDate = provider!.testDate;
      provider!.testDate = Jiffy.parseFromDateTime(provider!.testDate).add(weeks: 1).dateTime;
      int weeks = Jiffy.parseFromDateTime(provider!.testDate).diff(Jiffy.parseFromDateTime(oldDate)) as int;
      fakeAsync((async) {
      async.elapse(Duration(microseconds: weeks));
      });

      }
      // This is just to let the async function catch up. Might need to be longer.
      await Future.delayed(const Duration(seconds: 3));
      await provider!.getToDosBy();

      expect(provider!.todos.length, 4, reason: "Mon-Wed-Fri Monthly (custom) routine failed \n todos: ${provider!.todos.toString()}");
      expect(provider!.todos.firstOrNull?.dueDate.isAfter(provider!.curToDo.dueDate), true, reason: "Copy Routine didn't work or sorting busted \n todos: ${provider!.todos.toString()}");
      expect(provider!.failCache.isEmpty, true, reason: "Update/Upload thrown \n ${provider!.failCache.toString()}");

    });

    test("Populate Calendar", () async {
      provider!.sorter.sortMethod = SortMethod.dueDate;
      provider!.sorter.descending = true;
      provider!.testTimer.cancel();
      provider!.syncTimer.cancel();
      provider!.createToDo(taskType: TaskType.small,
          name: "DailyTest",
          repeatable: true,
          frequency: Frequency.daily);

      await provider!.populateCalendar(now: DateTime.now().add(const Duration(days: 30)));
      await provider!.getToDosBy();
      expect(provider!.todos.length, 30, reason: "Populate Calendar Failed \n ToDos: ${provider!.todos.toString()}");
      expect(provider!.todos.firstOrNull?.dueDate.isAfter(provider!.curToDo.dueDate), true, reason: "Populate or Sorting failed \n ${provider!.todos.toString()}");

      await provider!.deleteFutures();
      await provider!.getToDosBy();
      expect(provider!.todos.length, 1, reason: "Delete Futures Failed \n ${provider!.todos.toString()}");
      expect(provider!.failCache.isEmpty, true, reason: "Update/Upload thrown \n ${provider!.failCache.toString()}");

    });

  });



}

Future<void> initTesting() async {
  initDatabase();
  provider = ToDoProvider();
}
Future<void> initDatabase() async {
  isarService.init();
  isarClient = IsarService.isarClient;
  clearDatabase();
}

Future<void> clearDatabase() async => await isarClient?.writeTxn(() async {
  await isarClient?.clear();
});
Future<void> closeDatabase() async {
  await isarClient?.close(deleteFromDisk: true);
}
Future<void> closeTesting() async {
  closeDatabase();
  isarClient = null;
  provider?.syncTimer.cancel();
  provider?.testTimer.cancel();
  provider = null;
}