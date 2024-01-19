import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';

import '../providers/model/deadline_provider.dart';
import '../providers/model/group_provider.dart';
import '../providers/model/reminder_provider.dart';
import '../providers/model/routine_provider.dart';
import '../providers/model/todo_provider.dart';
import '../providers/model/user_provider.dart';
import '../services/isar_service.dart';
import '../services/notification_service.dart';
import '../services/supabase_service.dart';
import '../ui/views/sub_views.dart';
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
              userViewModel:
                  Provider.of<UserProvider>(context, listen: false).viewModel,
            ),
        update: (BuildContext context, UserProvider up, ToDoProvider? tp) {
          tp?.setUser(newUser: up.viewModel);
          return tp ?? ToDoProvider(userViewModel: up.viewModel);
        }),
    ChangeNotifierProxyProvider<UserProvider, RoutineProvider>(
        create: (BuildContext context) => RoutineProvider(
            userViewModel:
                Provider.of<UserProvider>(context, listen: false).viewModel),
        update: (BuildContext context, UserProvider up, RoutineProvider? rp) {
          rp?.setUser(newUser: up.viewModel);
          return rp ?? RoutineProvider(userViewModel: up.viewModel);
        }),
    ChangeNotifierProxyProvider<UserProvider, ReminderProvider>(
        create: (BuildContext context) => ReminderProvider(
            userViewModel:
                Provider.of<UserProvider>(context, listen: false).viewModel),
        update: (BuildContext context, UserProvider up, ReminderProvider? rp) {
          rp?.setUser(newUser: up.viewModel);
          return rp ?? ReminderProvider(userViewModel: up.viewModel);
        }),
    ChangeNotifierProxyProvider<UserProvider, DeadlineProvider>(
        create: (BuildContext context) => DeadlineProvider(
            userViewModel:
                Provider.of<UserProvider>(context, listen: false).viewModel),
        update: (BuildContext context, UserProvider up, DeadlineProvider? dp) {
          dp?.setUser(newUser: up.viewModel);
          return dp ?? DeadlineProvider(userViewModel: up.viewModel);
        }),
    ChangeNotifierProxyProvider<UserProvider, GroupProvider>(
        create: (BuildContext context) => GroupProvider(
            userViewModel:
                Provider.of<UserProvider>(context, listen: false).viewModel),
        update: (BuildContext context, UserProvider up, GroupProvider? gp) {
          gp?.setUser(newUser: up.viewModel);
          return gp ?? GroupProvider(userViewModel: up.viewModel);
        })
  ], child: UITester()));
}

class UITester extends StatelessWidget {
  UITester({super.key});

  final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

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

    NotificationService.instance.init();

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
      body: Center(
          child: Column(
        children: [
          const Text('Press the buttons below!'),
          Padding(
            padding: const EdgeInsets.all(Constants.padding),
            child: Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: [
                Column(children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: FloatingActionButton(
                        onPressed: () => inputDialog(context,
                            dialog: const CreateToDoScreen()),
                        backgroundColor: Colors.pink,
                        child: const Text("Create Task")),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: FloatingActionButton(
                      onPressed: () => inputDialog(context,
                          dialog: (null !=
                                  Provider.of<ToDoProvider>(context,
                                          listen: false)
                                      .curToDo)
                              ? const UpdateToDoScreen()
                              : const CreateToDoScreen()),
                      backgroundColor: Colors.green,
                      child: const Text("Update Task"),
                    ),
                  )
                ]),

                Column(children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: FloatingActionButton(
                        onPressed: () => inputDialog(context,
                            dialog: const CreateRoutineScreen()),
                        backgroundColor: Colors.pink,
                        child: const Text("Create Routine")),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: FloatingActionButton(
                      onPressed: () => inputDialog(context,
                          dialog: (null !=
                                  Provider.of<RoutineProvider>(context,
                                          listen: false)
                                      .curRoutine)
                              ? const UpdateRoutineScreen()
                              : const CreateRoutineScreen()),
                      backgroundColor: Colors.green,
                      child: const Text("Update Routine"),
                    ),
                  )
                ]),

                Column(children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: FloatingActionButton(
                        onPressed: () => inputDialog(context,
                            dialog: const CreateDeadlineScreen()),
                        backgroundColor: Colors.pink,
                        child: const Text("Create Deadline")),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: FloatingActionButton(
                      onPressed: () => inputDialog(context,
                          dialog: (null !=
                                  Provider.of<DeadlineProvider>(context,
                                          listen: false)
                                      .curDeadline)
                              ? const UpdateDeadlineScreen()
                              : const CreateDeadlineScreen()),
                      backgroundColor: Colors.green,
                      child: const Text("Update Deadline"),
                    ),
                  )
                ]),
                Column(children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: FloatingActionButton(
                        onPressed: () => inputDialog(context,
                            dialog: const CreateReminderScreen()),
                        backgroundColor: Colors.pink,
                        child: const Text("Create Reminder")),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: FloatingActionButton(
                      onPressed: () => inputDialog(context,
                          dialog: (null !=
                                  Provider.of<ReminderProvider>(context,
                                          listen: false)
                                      .curReminder)
                              ? const UpdateReminderScreen()
                              : const CreateReminderScreen()),
                      backgroundColor: Colors.green,
                      child: const Text("Update Reminder"),
                    ),
                  )
                ]),
                //
                Column(children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: FloatingActionButton(
                        onPressed: () => inputDialog(context,
                            dialog: const CreateGroupScreen()),
                        backgroundColor: Colors.pink,
                        child: const Text("Create Group")),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: FloatingActionButton(
                      onPressed: () => inputDialog(context,
                          dialog: (null !=
                                  Provider.of<GroupProvider>(context,
                                          listen: false)
                                      .curGroup)
                              ? const UpdateGroupScreen()
                              : const CreateGroupScreen()),
                      backgroundColor: Colors.green,
                      child: const Text("Update Group"),
                    ),
                  )
                ]),
              ],
            ),
          ),
        ],
      )),
    );
  }

  Future<void> inputDialog(BuildContext context,
          {required Widget dialog}) async =>
      await showDialog(
          barrierDismissible: false,
          useRootNavigator: false,
          context: context,
          builder: (BuildContext context) => dialog);
}
