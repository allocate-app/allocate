import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart';
import 'package:isar/isar.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';

import '../model/task/todo.dart';
import '../providers/application/event_provider.dart';
import '../providers/application/layout_provider.dart';
import '../providers/application/search_provider.dart';
import '../providers/application/theme_provider.dart';
import '../providers/model/deadline_provider.dart';
import '../providers/model/group_provider.dart';
import '../providers/model/reminder_provider.dart';
import '../providers/model/routine_provider.dart';
import '../providers/model/subtask_provider.dart';
import '../providers/model/todo_provider.dart';
import '../providers/model/user_provider.dart';
import '../providers/viewmodels/deadline_viewmodel.dart';
import '../providers/viewmodels/group_viewmodel.dart';
import '../providers/viewmodels/reminder_viewmodel.dart';
import '../providers/viewmodels/routine_viewmodel.dart';
import '../providers/viewmodels/subtask_viewmodel.dart';
import '../providers/viewmodels/todo_viewmodel.dart';
import '../providers/viewmodels/user_viewmodel.dart';
import '../services/application_service.dart';
import '../services/daily_reset_service.dart';
import '../services/isar_service.dart';
import '../services/notification_service.dart';
import '../services/supabase_service.dart';
import '../ui/views/route_views/home_screen.dart';
import '../util/constants.dart';
import '../util/enums.dart';
import '../util/interfaces/i_model.dart';

// Async for windowmanager & desktop apps.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  if (kReleaseMode) {
    print("RELEASEMODE");
  }

  // await SystemTheme.accentColor.load();
  // SystemTheme.fallbackColor = Constants.windowsDefaultDark;

  // TODO: test flutter_acrylic for windows/mac.
  // on Linux, it's disrupting the keydown event.
  if (!Platform.isIOS && !Platform.isAndroid) {
    // Flutter acrylic doesn't currently work in linux, but is required for window transparency.
    if (!Platform.isLinux) {
      // This needs testing
      // Transparency effects - Flutter acrylic
      // await Window.initialize();
      // await Window.setEffect(effect: WindowEffect.aero, dark: true);
      // // see flutter_acrylic for effects. Only Transparent/disabled/solid for linux
      // // Windows - use Aero, acrylic is breaking in W10.
      // // Set colors according to user theme.
      // // MacOS - features for sidebar
      // await Window.setEffect(
      //   effect: WindowEffect.transparent,
      //   dark: true,
      // );

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
    WindowOptions windowOptions = const WindowOptions(
      minimumSize: Constants.testDesktopSize,
    );

    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
      await windowManager.setPreventClose(false);
    });
  }

  // GLOBAL APP SCHEDULER
  DailyResetService.instance.init();

  // For all intents and purposes here, it's fine to keep as is.
  // in main, this will need to be refactored to use the splash screen.
  // Init needs to be called
  await Future.wait([
    IsarService.instance.init(debug: true),
    SupabaseService.instance.init(
        supabaseUrl: Constants.supabaseURL,
        anonKey: Constants.supabaseAnnonKey,
        client: FakeSupabase()),
    NotificationService.instance.init(),
  ]).whenComplete(() => runApp(MultiProvider(providers: [
        // VIEWMODELS
        ChangeNotifierProvider<ToDoViewModel>(create: (_) => ToDoViewModel()),
        ChangeNotifierProvider<UserViewModel>(create: (_) => UserViewModel()),
        ChangeNotifierProvider<RoutineViewModel>(
            create: (_) => RoutineViewModel()),
        ChangeNotifierProvider<DeadlineViewModel>(
          create: (_) => DeadlineViewModel(),
        ),
        ChangeNotifierProvider<ReminderViewModel>(
            create: (_) => ReminderViewModel()),
        ChangeNotifierProvider<GroupViewModel>(create: (_) => GroupViewModel()),

        ChangeNotifierProvider<SubtaskViewModel>(
            create: (_) => SubtaskViewModel()),

        // GLOBAL LAYOUT STATE
        ChangeNotifierProvider<LayoutProvider>(create: (_) => LayoutProvider()),

        ChangeNotifierProxyProvider<UserViewModel, UserProvider>(
            create: (BuildContext context) {
          UserProvider up = UserProvider(
              viewModel: Provider.of<UserViewModel>(context, listen: false));
          up.init();
          return up;
        }, update: (BuildContext context, UserViewModel vm, UserProvider? up) {
          if (null == up) {
            up = UserProvider(viewModel: vm);
            up.init();
          }
          up.shouldUpdate = true;
          return up;
        }),
        ChangeNotifierProxyProvider<UserProvider, ToDoProvider>(
            create: (BuildContext context) {
          ToDoProvider tp = ToDoProvider(
            userViewModel:
                Provider.of<UserProvider>(context, listen: false).viewModel,
          );
          tp.init();
          return tp;
        }, update: (BuildContext context, UserProvider up, ToDoProvider? tp) {
          if (null == tp) {
            tp = ToDoProvider();
            tp.init();
          }
          tp.setUser(newUser: up.viewModel);
          return tp;
        }),
        ChangeNotifierProxyProvider<UserProvider, RoutineProvider>(
            create: (BuildContext context) {
          RoutineProvider rp = RoutineProvider(
            userViewModel:
                Provider.of<UserProvider>(context, listen: false).viewModel,
          );
          rp.init();
          return rp;
        }, update:
                (BuildContext context, UserProvider up, RoutineProvider? rp) {
          if (null == rp) {
            rp = RoutineProvider();
            rp.init();
          }
          rp.setUser(newUser: up.viewModel);
          return rp;
        }),
        ChangeNotifierProxyProvider<UserProvider, SubtaskProvider>(
            create: (BuildContext context) {
          SubtaskProvider sp = SubtaskProvider(
              userViewModel:
                  Provider.of<UserProvider>(context, listen: false).viewModel);
          sp.init();
          return sp;
        }, update:
                (BuildContext context, UserProvider up, SubtaskProvider? sp) {
          if (null == sp) {
            sp = SubtaskProvider();
            sp.init();
          }
          sp.setUser(newUser: up.viewModel);
          return sp;
        }),
        ChangeNotifierProxyProvider<UserProvider, ReminderProvider>(
            create: (BuildContext context) {
          ReminderProvider rp = ReminderProvider(
            userViewModel:
                Provider.of<UserProvider>(context, listen: false).viewModel,
          );
          rp.init();
          return rp;
        }, update:
                (BuildContext context, UserProvider up, ReminderProvider? rp) {
          if (null == rp) {
            rp = ReminderProvider();
            rp.init();
          }
          rp.setUser(newUser: up.viewModel);
          return rp;
        }),
        ChangeNotifierProxyProvider<UserProvider, DeadlineProvider>(
            create: (BuildContext context) {
          DeadlineProvider dp = DeadlineProvider(
              userViewModel:
                  Provider.of<UserProvider>(context, listen: false).viewModel);
          dp.init();
          return dp;
        }, update:
                (BuildContext context, UserProvider up, DeadlineProvider? dp) {
          if (null == dp) {
            dp = DeadlineProvider();
            dp.init();
          }
          dp.setUser(newUser: up.viewModel);
          return dp;
        }),
        ChangeNotifierProxyProvider<UserProvider, GroupProvider>(
            create: (BuildContext context) {
          GroupProvider gp = GroupProvider(
              userViewModel:
                  Provider.of<UserProvider>(context, listen: false).viewModel);
          gp.init();
          return gp;
        }, update: (BuildContext context, UserProvider up, GroupProvider? gp) {
          if (null == gp) {
            gp = GroupProvider();
            gp.init();
          }
          gp.setUser(newUser: up.viewModel);
          return gp;
        }),
        ChangeNotifierProxyProvider<UserProvider, ThemeProvider>(
            create: (BuildContext context) => ThemeProvider(
                userViewModel: Provider.of<UserProvider>(context, listen: false)
                    .viewModel),
            update: (BuildContext context, UserProvider up, ThemeProvider? tp) {
              tp?.setUser(newUser: up.viewModel);
              return tp ?? ThemeProvider(userViewModel: up.viewModel);
            }),
        ChangeNotifierProxyProvider<UserProvider, SearchProvider>(
            create: (BuildContext context) => SearchProvider<IModel>(
                  userModel: Provider.of<UserProvider>(context, listen: false)
                      .viewModel,
                ),
            update:
                (BuildContext context, UserProvider up, SearchProvider? sp) {
              sp?.userModel = up.viewModel;
              return sp ?? SearchProvider(userModel: up.viewModel);
            }),
        ChangeNotifierProxyProvider<UserProvider, EventProvider>(
            create: (BuildContext context) => EventProvider(
                  focusedDay: Constants.today,
                  userModel: Provider.of<UserProvider>(context, listen: false)
                      .viewModel,
                ),
            update: (BuildContext context, UserProvider up, EventProvider? ep) {
              ep?.userModel = up.viewModel;
              return ep ??
                  EventProvider(
                      focusedDay: Constants.today, userModel: up.viewModel);
            }),
      ], child: const LocalTester())));
}

class LocalTester extends StatefulWidget {
  const LocalTester({super.key});

  @override
  State<LocalTester> createState() => _LocalTester();
}

class _LocalTester extends State<LocalTester> with WindowListener {
  late UserProvider userProvider;

  late GlobalKey<NavigatorState> navigatorKey;

  @override
  void initState() {
    if (!Platform.isAndroid && !Platform.isIOS) {
      windowManager.addListener(this);
      // ServicesBinding.instance.keyboard.addHandler(_onKey);
    }
    // Test to inject 100 tasks.
    // testListView();

    userProvider = Provider.of<UserProvider>(context, listen: false);
    navigatorKey = ApplicationService.instance.globalNavigatorKey;

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
  void onWindowFocus() {
    setState(() {});
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
              id: Constants.generateID(),
              taskType: TaskType.small,
              name: 'Test: $i',
              expectedDuration: 0,
              weight: 1,
              myDay: true,
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
    return Consumer<ThemeProvider>(
      builder: (BuildContext context, ThemeProvider value, Widget? child) {
        return TitlebarSafeArea(
          child: MaterialApp(
            navigatorKey: navigatorKey,
            theme: value.lightTheme,
            darkTheme: value.darkTheme,
            highContrastTheme: value.highContrastLight,
            highContrastDarkTheme: value.highContrastDark,
            themeMode: switch (value.themeType) {
              ThemeType.light => ThemeMode.light,
              ThemeType.dark => ThemeMode.dark,
              ThemeType.system => ThemeMode.system,
            },
            home: const HomeScreen(),
          ),
        );
      },
    );
  }
}
