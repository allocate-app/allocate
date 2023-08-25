// This will need to be a basic scaffold with floating action button
// Return here once DI refactor, and test pages/functions accoringly.

import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';

import '../providers/deadline_provider.dart';
import '../providers/group_provider.dart';
import '../providers/reminder_provider.dart';
import '../providers/routine_provider.dart';
import '../providers/todo_provider.dart';
import '../providers/user_provider.dart';
import '../services/isar_service.dart';
import '../services/supabase_service.dart';
import '../ui/views/sub_views/create_routine.dart';
import '../ui/views/sub_views/create_todo.dart';
import '../ui/views/sub_views/update_todo.dart';
import '../util/constants.dart';

// Async for windowmanager & desktop apps.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();

  // THIS needs to be added to main in the app.
  if (!Platform.isIOS && !Platform.isAndroid) {
    // This is for default sizing.
    await windowManager.ensureInitialized();

    WindowManager.instance.setMinimumSize(Constants.minDesktopSize);

    WindowOptions windowOptions = const WindowOptions(
      minimumSize: Constants.minDesktopSize,
      title: "TESTING",
    );

    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
      await windowManager.setPreventClose(true);
    });
  }

  runApp(MultiProvider(providers: [
    ChangeNotifierProvider<UserProvider>(create: (_) => UserProvider()),
    ChangeNotifierProxyProvider<UserProvider, ToDoProvider>(
        create: (BuildContext context) => ToDoProvider(
            user: Provider.of<UserProvider>(context, listen: false).curUser, service: null),
        update: (BuildContext context, UserProvider up, ToDoProvider? tp) {
          tp?.setUser(user: up.curUser);
          return tp ?? ToDoProvider(user: up.curUser, service: null);
        }),
    ChangeNotifierProxyProvider<UserProvider, RoutineProvider>(
        create: (BuildContext context) => RoutineProvider(
            user: Provider.of<UserProvider>(context, listen: false).curUser, service: null),
        update: (BuildContext context, UserProvider up, RoutineProvider? rp) {
          rp?.setUser(user: up.curUser);
          return rp ?? RoutineProvider(user: up.curUser, service: null);
        }),
    ChangeNotifierProxyProvider<UserProvider, ReminderProvider>(
        create: (BuildContext context) => ReminderProvider(
            user: Provider.of<UserProvider>(context, listen: false).curUser, service: null),
        update: (BuildContext context, UserProvider up, ReminderProvider? rp) {
          rp?.setUser(user: up.curUser);
          return rp ?? ReminderProvider(user: up.curUser, service: null);
        }),
    ChangeNotifierProxyProvider<UserProvider, DeadlineProvider>(
        create: (BuildContext context) => DeadlineProvider(
            user: Provider.of<UserProvider>(context, listen: false).curUser, service: null),
        update: (BuildContext context, UserProvider up, DeadlineProvider? dp) {
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
          return gp ?? GroupProvider(user: up.curUser, groupService: null, toDoService: null);
        })
  ], child: const UITester()));

  // REMEMBER: Add this to main - might have to be a desktop-only.
  // doWhenWindowReady(() {
  //   final win = appWindow;
  //   win.minSize = Constants.minDesktopSize;
  //   win.show();
  // });
}

class UITester extends StatelessWidget {
  const UITester({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(useMaterial3: true),
      // Switch this out as needed.
      home: const FormTester(),
    );
  }
}

class FormTester extends StatefulWidget {
  const FormTester({super.key});

  @override
  State<FormTester> createState() => _FormTester();
}

class _FormTester extends State<FormTester> with WindowListener {
  WindowListener? listener;

  @override
  void initState() {
    IsarService.instance.init(debug: true);
    SupabaseService.instance.init(
        supabaseUrl: Constants.supabaseURL,
        anonKey: Constants.supabaseAnnonKey,
        client: FakeSupabase());

    if (!Platform.isAndroid && !Platform.isIOS) {
      windowManager.addListener(this);
    }

    super.initState();
  }

  @override
  Future<void> dispose() async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      windowManager.removeListener(this);
    }
    await IsarService.instance.dispose();
    super.dispose();
  }

  @override
  void onWindowClose() async {
    await dispose();
    await windowManager.destroy();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FormTester'),
      ),
      body: const Center(child: Text('Press the button below!')),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Padding(
        padding: const EdgeInsets.all(Constants.padding),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            FloatingActionButton(
              onPressed: () => showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    // return const CreateToDoScreen();
                    return const CreateRoutineScreen();
                    // return const CreateDeadlineScreen();
                    // return const CreateReminderScreen();
                  }),
              backgroundColor: Colors.pink,
              child: const Text("Create New"),
            ),
            FloatingActionButton(
              onPressed: () => showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    if (null != Provider.of<ToDoProvider>(context, listen: false).curToDo) {
                      return const UpdateToDoScreen();
                    } else {
                      return const CreateToDoScreen();
                    }
                    // return const UpdateRoutineScreen();
                    // return const UpdateDeadlineScreen();
                    // return const UpdateReminderScreen();
                  }),
              backgroundColor: Colors.green,
              child: const Text("Update"),
            ),
          ],
        ),
      ),
    );
  }
}
