import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';

import '../model/task/todo.dart';
import '../providers/deadline_provider.dart';
import '../providers/group_provider.dart';
import '../providers/reminder_provider.dart';
import '../providers/routine_provider.dart';
import '../providers/todo_provider.dart';
import '../providers/user_provider.dart';
import '../services/isar_service.dart';
import '../services/notification_service.dart';
import '../services/supabase_service.dart';
import '../ui/views/route_views/home_screen.dart';
import '../util/constants.dart';
import '../util/enums.dart';

// Async for windowmanager & desktop apps.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();

  // THIS needs to be added to main in the app.
  if (!Platform.isIOS && !Platform.isAndroid) {
    // This is for default sizing.
    await windowManager.ensureInitialized();

    // NOTE: This is not currently working in Linux. Possibly macOS.
    // Linux size issue is not resolved.
    await WindowManager.instance.setResizable(true);
    await WindowManager.instance.setMinimumSize(Constants.testDesktopSize);

    WindowOptions windowOptions = const WindowOptions(
      minimumSize: Constants.testDesktopSize,
      title: "TESTING",
    );

    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
      await windowManager.setPreventClose(false);
    });
  }

  await Future.wait([
    IsarService.instance.init(debug: true),
    SupabaseService.instance.init(
        supabaseUrl: Constants.supabaseURL,
        anonKey: Constants.supabaseAnnonKey,
        client: FakeSupabase()),
    NotificationService.instance.init()
  ]).whenComplete(() => runApp(MultiProvider(providers: [
        ChangeNotifierProvider<UserProvider>(create: (_) => UserProvider()),
        ChangeNotifierProxyProvider<UserProvider, ToDoProvider>(
            create: (BuildContext context) => ToDoProvider(
                user: Provider.of<UserProvider>(context, listen: false).curUser,
                toDoService: null),
            update: (BuildContext context, UserProvider up, ToDoProvider? tp) {
              tp?.setUser(user: up.curUser);
              return tp ?? ToDoProvider(user: up.curUser, toDoService: null);
            }),
        ChangeNotifierProxyProvider<UserProvider, RoutineProvider>(
            create: (BuildContext context) => RoutineProvider(
                user: Provider.of<UserProvider>(context, listen: false).curUser,
                routineService: null),
            update:
                (BuildContext context, UserProvider up, RoutineProvider? rp) {
              rp?.setUser(user: up.curUser);
              return rp ??
                  RoutineProvider(user: up.curUser, routineService: null);
            }),
        ChangeNotifierProxyProvider<UserProvider, ReminderProvider>(
            create: (BuildContext context) => ReminderProvider(
                user: Provider.of<UserProvider>(context, listen: false).curUser,
                service: null),
            update:
                (BuildContext context, UserProvider up, ReminderProvider? rp) {
              rp?.setUser(user: up.curUser);
              return rp ?? ReminderProvider(user: up.curUser, service: null);
            }),
        ChangeNotifierProxyProvider<UserProvider, DeadlineProvider>(
            create: (BuildContext context) => DeadlineProvider(
                user: Provider.of<UserProvider>(context, listen: false).curUser,
                service: null),
            update:
                (BuildContext context, UserProvider up, DeadlineProvider? dp) {
              dp?.setUser(user: up.curUser);
              return dp ?? DeadlineProvider(user: up.curUser, service: null);
            }),
        ChangeNotifierProxyProvider<UserProvider, GroupProvider>(
            create: (BuildContext context) => GroupProvider(
                user: Provider.of<UserProvider>(context, listen: false).curUser,
                groupService: null,
                toDoService: null),
            update: (BuildContext context, UserProvider up, GroupProvider? gp) {
              gp?.setUser(user: up.curUser);
              return gp ??
                  GroupProvider(
                      user: up.curUser, groupService: null, toDoService: null);
            })
      ], child: const NavigationTester())));
}

class NavigationTester extends StatefulWidget {
  const NavigationTester({super.key});

  @override
  State<NavigationTester> createState() => _NavigationTester();
}

class _NavigationTester extends State<NavigationTester> with WindowListener {
  @override
  void initState() {
    if (!Platform.isAndroid && !Platform.isIOS) {
      windowManager.addListener(this);
    }
    // Test to inject 100 tasks.
    // testListView();

    super.initState();
  }

  @override
  Future<void> dispose() async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      windowManager.removeListener(this);
    }

    await Future.wait([
      IsarService.instance.dispose(),
    ]).whenComplete(() {
      super.dispose();
    });
  }

  @override
  void onWindowClose() async {
    await dispose();
    await windowManager.destroy();
  }

  void testListView() async {
    List<ToDo> testToDos = List.generate(
        100,
        (i) => ToDo(
              taskType: TaskType.small,
              name: 'Test: $i',
              expectedDuration: 0,
              realDuration: 0,
              startDate: DateTime.now().subtract(const Duration(days: 1)),
              dueDate: DateTime.now().subtract(const Duration(days: 1)),
              repeatDays: List.filled(7, false),
              lastUpdated: DateTime.now(),
            ));
    Isar isarClient = IsarService.instance.isarClient;
    await IsarService.instance.isarClient.writeTxn(() async {
      for (ToDo toDo in testToDos) {
        await isarClient.toDos.put(toDo);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

    print("MQ: $size");
    return MaterialApp(
      theme: ThemeData(useMaterial3: true),
      home: const HomeScreen(),
    );
  }
}
