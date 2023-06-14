import "package:test/test.dart";
import "dart:io" hide stdin;
import "package:mocktail/mocktail.dart";
import "dart:convert";
import "../model/task/task.dart";

class FakeStdin extends Mock implements Stdin{}

// void main()
// {
//   group("Task tests CLI", ()
//   {
//     // Small Tasks.
//     test("Task creation & Equals", ()
//     {
//       var testDate = DateTime.now();
//       var badDate = testDate.add(const Duration(hours: 2));
//       var testTask = Task(name: "TestTask", weight: 1, priority: Priority.low, startDate: testDate, endDate: testDate);
//       var equalsTask = Task(name: "TestTask", weight: 1, priority: Priority.low, startDate: testDate, endDate: testDate);
//       var nonEqualsTask = Task(name: "TestTask", weight: 1, priority: Priority.low, startDate: badDate, endDate: badDate);
//       expect(testTask.name, "TestTask");
//       expect(testTask.weight, 1);
//       expect(testTask.priority, Priority.low);
//       expect(testTask.startDate, testDate);
//       expect(testTask.endDate, testDate);
//       expect(testTask, equalsTask);
//       expect(testTask == nonEqualsTask, false);
//     });
//
//     // Large Tasks
//
//     test("Large Task creation ", ()
//     {
//       var testDate = DateTime.now();
//       var testLg = LargeTask(name: "LargeTaskTest", priority: Priority.medium, startDate: testDate, endDate: testDate);
//
//       expect(testLg.name, "LargeTaskTest");
//       expect(testLg.priority, Priority.medium);
//       expect(testLg.startDate, testDate);
//       expect(testLg.endDate, testDate);
//     });
//
//     test("Large Task Adding Subtasks", ()
//     {
//       var testDate = DateTime.now();
//       var badDate = testDate.add(const Duration(hours: 2));
//       var testTask = Task(name: "TestTask", weight: 1, priority: Priority.low, startDate: testDate, endDate: testDate);
//       var nonEqualsTask = Task(name: "TestTask", weight: 1, priority: Priority.low, startDate: badDate, endDate: badDate);
//       var testLg = LargeTask(name: "LargeTaskTest", priority: Priority.medium, startDate: testDate, endDate: testDate);
//
//       testLg.addSubTask(testTask);
//       testLg.addSubTask(testTask);
//       expect(testLg.todos.length, 1);
//       testLg.addSubTask(nonEqualsTask);
//       expect(testLg.todos.length, 2);
//     });
//
//     test("Large Task Reordering Subtasks", ()
//     {
//       var testDate = DateTime.now();
//       var testTask = Task(name: "TestTask", weight: 1, priority: Priority.low, startDate: testDate, endDate: testDate);
//       var nonEqualsTask = Task(name: "TestTask", weight: 1, priority: Priority.low);
//       var testLg = LargeTask(name: "LargeTaskTest", priority: Priority.medium);
//
//       testLg.addSubTask(testTask);
//       testLg.addSubTask(nonEqualsTask);
//
//       testLg.reOrderTask(testTask, 1);
//       expect(testLg.todos.first, nonEqualsTask);
//
//     });
//
//     test("Large Task Removal", ()
//     {
//       var testDate = DateTime.now();
//       var testTask = Task(name: "TestTask", weight: 1, priority: Priority.low, startDate: testDate, endDate: testDate);
//       var nonEqualsTask = Task(name: "TestTask", weight: 1, priority: Priority.low);
//       var testLg = LargeTask(name: "LargeTaskTest", priority: Priority.medium);
//
//       testLg.addSubTask(testTask);
//       testLg.addSubTask(nonEqualsTask);
//
//       expect(testLg.removeSubTask(nonEqualsTask), true);
//       expect(testLg.todos.length, 1);
//     });
//
//     test("Completion Event: TODOS check", ()
//     {
//       var testTask = Task(name: "TestTask", weight: 1, priority: Priority.low);
//       var testLg = LargeTask(name: "LargeTaskTest", priority: Priority.medium);
//
//       testLg.addSubTask(testTask);
//
//       testLg.todos.first.progress = Progress.completed;
//       expect(testLg.todos.length, 0);
//     });
//
//     test("Completion Event: Completed check", ()
//     {
//       var testTask = Task(name: "TestTask", weight: 1, priority: Priority.low);
//       var testLg = LargeTask(name: "LargeTaskTest", priority: Priority.medium);
//
//       testLg.addSubTask(testTask);
//
//       testLg.todos.first.progress = Progress.completed;
//       expect(testLg.completes.length, 1);
//     });
//
//     test("UnCompletion: TODOS check", ()
//     {
//       var testTask = Task(name: "TestTask", weight: 1, priority: Priority.low);
//       var testLg = LargeTask(name: "LargeTaskTest", priority: Priority.medium);
//
//       testLg.addSubTask(testTask);
//       testTask.progress = Progress.completed;
//       expect(testLg.todos.length, 0);
//
//       testLg.unCompleteTask(testTask);
//       expect(testLg.todos.length, 1);
//     });
//     test("UnCompletion: Completes check", ()
//     {
//       var testTask = Task(name: "TestTask", weight: 1, priority: Priority.low);
//       var testLg = LargeTask(name: "LargeTaskTest", priority: Priority.medium);
//
//       testLg.addSubTask(testTask);
//       testTask.progress = Progress.completed;
//       expect(testLg.completes.length, 1);
//
//       testLg.unCompleteTask(testTask);
//       expect(testLg.completes.length, 0);
//     });
//
//     test("Completion Event: LargeTask with TODOS -resolve", ()
//     {
//       var testDate = DateTime.now();
//       var testTask = Task(name: "TestTask", weight: 1, priority: Priority.low, startDate: testDate, endDate: testDate);
//       var nonEqualsTask = Task(name: "TestTask", weight: 1, priority: Priority.low);
//       var testLg = LargeTask(name: "LargeTaskTest", priority: Priority.medium);
//
//       testLg.addSubTask(testTask);
//       testLg.addSubTask(nonEqualsTask);
//       final stdin = FakeStdin();
//       when(() => stdin.readLineSync(encoding: utf8)).thenReturn("y");
//
//
//       IOOverrides.runZoned(()
//           {
//             testLg.progress = Progress.completed;
//             expect(testLg.todos.length, 0);
//             expect(testLg.completes.length, 2);
//           },
//           stdin: () =>stdin);
//
//     });
//
//     test("Completion Event: LargeTask with TODOS -noResolve", ()
//     {
//       var testDate = DateTime.now();
//       var testTask = Task(name: "TestTask", weight: 1, priority: Priority.low, startDate: testDate, endDate: testDate);
//       var nonEqualsTask = Task(name: "TestTask", weight: 1, priority: Priority.low);
//       var testLg = LargeTask(name: "LargeTaskTest", priority: Priority.medium);
//
//       testLg.addSubTask(testTask);
//       testLg.addSubTask(nonEqualsTask);
//       final stdin = FakeStdin();
//       when(() => stdin.readLineSync(encoding: utf8)).thenReturn("n");
//
//
//       IOOverrides.runZoned(()
//       {
//         testLg.progress = Progress.completed;
//         expect(testLg.todos.length, 2);
//         expect(testLg.completes.length, 0);
//       },
//           stdin: () =>stdin);
//
//     });
//
//     test("Test Name Sort", ()
//     {
//       var testLg = LargeTask(name: "LargeTaskTest", priority: Priority.medium);
//
//       testLg.addSubTask(Task(name:"a", weight:3, priority: Priority.high,startDate: DateTime(1991), endDate: DateTime(1991)));
//       testLg.addSubTask(Task(name:"b", weight:1, priority: Priority.medium, startDate: DateTime(1992), endDate: DateTime(1992)));
//       testLg.addSubTask(Task(name:"c", weight:2, priority: Priority.medium, startDate:DateTime(1990), endDate:DateTime(1990)));
//       testLg.addSubTask(Task(name:"d", weight:4, priority: Priority.low, startDate: DateTime(1993), endDate: DateTime(1993)));
//       var taskNames = List<String>.empty(growable:true);
//
//       testLg.sortByName();
//
//       for(final task in testLg.todos)
//         {
//           taskNames.add(task.name);
//         }
//       expect(taskNames, ["a", "b", "c", "d"]);
//
//     });
//     test("Test Weight Sort", ()
//     {
//       var testLg = LargeTask(name: "LargeTaskTest", priority: Priority.medium);
//
//       testLg.addSubTask(Task(name:"a", weight:3, priority: Priority.high,startDate: DateTime(1991), endDate: DateTime(1991)));
//       testLg.addSubTask(Task(name:"b", weight:1, priority: Priority.medium, startDate: DateTime(1992), endDate: DateTime(1992)));
//       testLg.addSubTask(Task(name:"c", weight:2, priority: Priority.medium, startDate:DateTime(1990), endDate:DateTime(1990)));
//       testLg.addSubTask(Task(name:"d", weight:4, priority: Priority.low, startDate: DateTime(1993), endDate: DateTime(1993)));
//       var taskNames = List<String>.empty(growable:true);
//
//       testLg.sortByWeight();
//       taskNames = List<String>.empty(growable:true);
//       for(final task in testLg.todos)
//       {
//         taskNames.add(task.name);
//       }
//       expect(taskNames, ["b", "c", "a", "d"]);
//     });
//
//     test("Test Priority Sort", ()
//     {
//       var testLg = LargeTask(name: "LargeTaskTest", priority: Priority.medium);
//
//       testLg.addSubTask(Task(name:"a", weight:3, priority: Priority.high,startDate: DateTime(1991), endDate: DateTime(1991)));
//       testLg.addSubTask(Task(name:"b", weight:1, priority: Priority.medium, startDate: DateTime(1992), endDate: DateTime(1992)));
//       testLg.addSubTask(Task(name:"c", weight:2, priority: Priority.medium, startDate:DateTime(1990), endDate:DateTime(1990)));
//       testLg.addSubTask(Task(name:"d", weight:4, priority: Priority.low, startDate: DateTime(1993), endDate: DateTime(1993)));
//       var taskNames = List<String>.empty(growable:true);
//
//       testLg.sortByPriority();
//       taskNames = List<String>.empty(growable:true);
//       for(final task in testLg.todos)
//         {
//           taskNames.add(task.name);
//         }
//       expect(taskNames, ["d", "b", "c", "a"]);
//     });
//     test("Test Date Sort", ()
//     {
//       var testLg = LargeTask(name: "LargeTaskTest", priority: Priority.medium);
//
//       testLg.addSubTask(Task(name:"a", weight:3, priority: Priority.high,startDate: DateTime(1991), endDate: DateTime(1991)));
//       testLg.addSubTask(Task(name:"b", weight:1, priority: Priority.medium, startDate: DateTime(1992), endDate: DateTime(1992)));
//       testLg.addSubTask(Task(name:"c", weight:2, priority: Priority.medium, startDate:DateTime(1990), endDate:DateTime(1990)));
//       testLg.addSubTask(Task(name:"d", weight:4, priority: Priority.low, startDate: DateTime(1993), endDate: DateTime(1993)));
//       var taskNames = List<String>.empty(growable:true);
//
//       testLg.sortByDate();
//       taskNames = List<String>.empty(growable:true);
//       for(final task in testLg.todos)
//         {
//           taskNames.add(task.name);
//         }
//
//       expect(taskNames, ["c", "a", "b", "d"]);
//     });
//   });
//
// }
