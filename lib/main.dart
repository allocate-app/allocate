import "dart:io";
import "dart:ui";

import "package:allocate/util/enums.dart";
import "package:auto_route/auto_route.dart";
import 'package:flutter/material.dart';
import "package:flutter/services.dart";
import "package:flutter_acrylic/flutter_acrylic.dart";
import "package:provider/provider.dart";
import "package:window_manager/window_manager.dart";

import "providers/providers.dart";
import "services/application_service.dart";
import "services/daily_reset_service.dart";
import "ui/app_router.dart";
import "util/constants.dart";
import "util/interfaces/i_model.dart";

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();

  // GLOBAL APP SCHEDULER
  DailyResetService.instance.init();

  // iPadOS (and hopefully some android tablets) should ignore this.
  if (Platform.isIOS || Platform.isAndroid) {
    await SystemChrome.setPreferredOrientations(
        [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
  } else {
    await windowManager.ensureInitialized();
    await windowManager.setResizable(true);
    // TODO: implement windows transparent titlebar.
    WindowOptions windowOptions = const WindowOptions(
      minimumSize: Constants.minDesktopSize,
    );

    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
      // TODO: minimize to taskbar
      // await windowManager.setPreventClose(true);
    });
  }

  runApp(MultiProvider(providers: [
    // VIEWMODELS
    ChangeNotifierProvider<ToDoViewModel>(create: (_) => ToDoViewModel()),
    ChangeNotifierProvider<UserViewModel>(create: (_) => UserViewModel()),
    ChangeNotifierProvider<RoutineViewModel>(create: (_) => RoutineViewModel()),
    ChangeNotifierProvider<DeadlineViewModel>(
      create: (_) => DeadlineViewModel(),
    ),
    ChangeNotifierProvider<ReminderViewModel>(
        create: (_) => ReminderViewModel()),
    ChangeNotifierProvider<GroupViewModel>(create: (_) => GroupViewModel()),

    ChangeNotifierProvider<SubtaskViewModel>(create: (_) => SubtaskViewModel()),

    // GLOBAL LAYOUT STATE
    ChangeNotifierProvider<LayoutProvider>(create: (_) => LayoutProvider()),

    ChangeNotifierProxyProvider<UserViewModel, UserProvider>(
        create: (BuildContext context) => UserProvider(
            viewModel: Provider.of<UserViewModel>(context, listen: false)),
        update: (BuildContext context, UserViewModel vm, UserProvider? up) {
          if (null == up) {
            up = UserProvider(viewModel: vm);
            up.init();
          }
          up.shouldUpdate = true;
          return up;
        }),
    ChangeNotifierProxyProvider<UserProvider, ToDoProvider>(
        create: (BuildContext context) => ToDoProvider(
              userViewModel:
                  Provider.of<UserProvider>(context, listen: false).viewModel,
            ),
        update: (BuildContext context, UserProvider up, ToDoProvider? tp) {
          if (null == tp) {
            tp = ToDoProvider();
            tp.init();
          }
          tp.setUser(newUser: up.viewModel);
          return tp;
        }),
    ChangeNotifierProxyProvider<UserProvider, RoutineProvider>(
        create: (BuildContext context) => RoutineProvider(
              userViewModel:
                  Provider.of<UserProvider>(context, listen: false).viewModel,
            ),
        update: (BuildContext context, UserProvider up, RoutineProvider? rp) {
          if (null == rp) {
            rp = RoutineProvider();
            rp.init();
          }
          rp.setUser(newUser: up.viewModel);
          return rp;
        }),
    ChangeNotifierProxyProvider<UserProvider, SubtaskProvider>(
        create: (BuildContext context) => SubtaskProvider(
            userViewModel:
                Provider.of<UserProvider>(context, listen: false).viewModel),
        update: (BuildContext context, UserProvider up, SubtaskProvider? sp) {
          if (null == sp) {
            sp = SubtaskProvider();
            sp.init();
          }
          sp.setUser(newUser: up.viewModel);
          return sp;
        }),
    ChangeNotifierProxyProvider<UserProvider, ReminderProvider>(
        create: (BuildContext context) => ReminderProvider(
              userViewModel:
                  Provider.of<UserProvider>(context, listen: false).viewModel,
            ),
        update: (BuildContext context, UserProvider up, ReminderProvider? rp) {
          if (null == rp) {
            rp = ReminderProvider();
            rp.init();
          }
          rp.setUser(newUser: up.viewModel);
          return rp;
        }),
    ChangeNotifierProxyProvider<UserProvider, DeadlineProvider>(
        create: (BuildContext context) => DeadlineProvider(
            userViewModel:
                Provider.of<UserProvider>(context, listen: false).viewModel),
        update: (BuildContext context, UserProvider up, DeadlineProvider? dp) {
          if (null == dp) {
            dp = DeadlineProvider();
            dp.init();
          }
          dp.setUser(newUser: up.viewModel);
          return dp;
        }),
    ChangeNotifierProxyProvider<UserProvider, GroupProvider>(
        create: (BuildContext context) => GroupProvider(
            userViewModel:
                Provider.of<UserProvider>(context, listen: false).viewModel),
        update: (BuildContext context, UserProvider up, GroupProvider? gp) {
          if (null == gp) {
            gp = GroupProvider();
            gp.init();
          }
          gp.setUser(newUser: up.viewModel);
          return gp;
        }),
    ChangeNotifierProxyProvider<UserProvider, ThemeProvider>(
        create: (BuildContext context) => ThemeProvider(
            userViewModel:
                Provider.of<UserProvider>(context, listen: false).viewModel),
        update: (BuildContext context, UserProvider up, ThemeProvider? tp) {
          tp?.setUser(newUser: up.viewModel);
          return tp ?? ThemeProvider(userViewModel: up.viewModel);
        }),
    ChangeNotifierProxyProvider<UserProvider, SearchProvider>(
        create: (BuildContext context) => SearchProvider<IModel>(
              userModel:
                  Provider.of<UserProvider>(context, listen: false).viewModel,
            ),
        update: (BuildContext context, UserProvider up, SearchProvider? sp) {
          sp?.userModel = up.viewModel;
          return sp ?? SearchProvider(userModel: up.viewModel);
        }),
    ChangeNotifierProxyProvider<UserProvider, EventProvider>(
        create: (BuildContext context) => EventProvider(
              focusedDay: Constants.today,
              userModel:
                  Provider.of<UserProvider>(context, listen: false).viewModel,
            ),
        update: (BuildContext context, UserProvider up, EventProvider? ep) {
          ep?.userModel = up.viewModel;
          return ep ??
              EventProvider(
                  focusedDay: Constants.today, userModel: up.viewModel);
        }),
  ], child: const MyApp()));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final AppRouter _appRouter;

  @override
  void initState() {
    super.initState();
    _appRouter = ApplicationService.instance.appRouter;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
        builder: (BuildContext context, ThemeProvider value, Widget? child) {
      return TitlebarSafeArea(
        child: MaterialApp.router(
          theme: value.lightTheme,
          darkTheme: value.darkTheme,
          highContrastTheme: value.highContrastLight,
          highContrastDarkTheme: value.highContrastDark,
          themeMode: switch (value.themeType) {
            ThemeType.light => ThemeMode.light,
            ThemeType.dark => ThemeMode.dark,
            ThemeType.system => ThemeMode.system,
          },
          routerConfig: _appRouter.config(deepLinkBuilder: (deeplink) {
            if (deeplink.path.contains("login")) {
              return const DeepLink([LoginRoute()]);
            }
            if (deeplink.path.contains("validate-email")) {
              return const DeepLink([ValidateEmailChangeRoute()]);
            }

            // This is just "root".
            return DeepLink.defaultPath;
          }),
          routerDelegate: _appRouter.delegate(),
          routeInformationParser: _appRouter.defaultRouteParser(),
        ),
      );
    });
  }
}
