import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart';
import 'package:isar/isar.dart';
//import 'package:macos_window_utils/macos_window_utils.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';

import '../model/task/todo.dart';
import '../providers/deadline_provider.dart';
import '../providers/group_provider.dart';
import '../providers/reminder_provider.dart';
import '../providers/routine_provider.dart';
import '../providers/subtask_provider.dart';
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

  // TODO: test flutter_acrylic for windows/mac.
  // on Linux, it's disrupting the keydown event.
  if (!Platform.isIOS && !Platform.isAndroid) {
    // Flutter acrylic doesn't allow keystrokes in linux.
    if (!Platform.isLinux) {
      // Transparency effects - Flutter acrylic
      await Window.initialize();

      // // see flutter_acrylic for effects. Only Transparent/disabled/solid for linux
      // // Windows - use Aero, acrylic is breaking in W10.
      // // Set colors according to user theme.
      // // MacOS - features for sidebar
      // await Window.setEffect(
      //   effect: WindowEffect.transparent,
      //   dark: true,
      // );

      await Window.setEffect(effect: WindowEffect.disabled, dark: true);

      // I think the idea is to make the window fully transparent/effected,
      // then add colours/opacities per widget.

      // Use for changing the transparency of the sidebar
      // await Window.setEffect(
      //   effect: WindowEffect.sidebar,
      //   dark: true,
      // );
    }
    // This is for default sizing.
    await windowManager.ensureInitialized();

    await windowManager.setResizable(true);
    await windowManager.setMinimumSize(Constants.testDesktopSize);

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
        ChangeNotifierProvider<SubtaskProvider>(
          create: (BuildContext context) => SubtaskProvider(),
        ),
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
      ServicesBinding.instance.keyboard.addHandler(_onKey);
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

  bool _onKey(KeyEvent event) {
    final key = event.logicalKey.keyLabel;
    if (event is KeyDownEvent) {
      print("Key down: $key");
    } else if (event is KeyUpEvent) {
      print("Key up: $key");
    } else if (event is KeyRepeatEvent) {
      print("Key repeat: $key");
    }
    return false;
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
    //TitlebarSafeArea is only for MacOS for window-tinting
    // return MaterialApp(
    //   home: const HomeScreen(),
    //   theme: ThemeData(useMaterial3: true),
    // );
    return TitlebarSafeArea(
      child: MaterialApp(
        theme: ThemeData(useMaterial3: true),
        home: const HomeScreen(),
      ),
    );
  }
}
