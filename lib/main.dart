import "dart:async";
import "dart:io";
import "dart:ui";

import "package:auto_route/auto_route.dart";
import "package:flutter/foundation.dart";
import "package:flutter/gestures.dart";
import 'package:flutter/material.dart';
import "package:flutter/services.dart";
import "package:flutter_acrylic/flutter_acrylic.dart";
import "package:macos_window_utils/window_manipulator.dart";
import "package:provider/provider.dart";
import "package:tray_manager/tray_manager.dart";
import "package:win32_registry/win32_registry.dart";
import "package:window_manager/window_manager.dart";

import "providers/providers.dart";
import "services/application_service.dart";
import "services/daily_reset_service.dart";
import "ui/app_router.dart";
import "ui/widgets/macos_menu_bar.dart";
import "util/constants.dart";
import "util/enums.dart";
import "util/interfaces/i_model.dart";

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();

  // GLOBAL APP SCHEDULER
  DailyResetService.instance.init();

  FlutterView? view = PlatformDispatcher.instance.implicitView;

  Size? size = view?.physicalSize;
  double? pixelRatio = view?.devicePixelRatio;
  double logicalSize = (size?.shortestSide ?? 0) / (pixelRatio ?? 1);

  bool isTablet = logicalSize >= Constants.smallScreen;

  // iPad ignores this, Android tablets do not.
  if ((Platform.isIOS || Platform.isAndroid) && !isTablet) {
    await SystemChrome.setPreferredOrientations(
        [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
  }

  if (!(Platform.isIOS || Platform.isAndroid)) {
    await windowManager.ensureInitialized();
    await windowManager.setResizable(true);
    if (Platform.isWindows) {
      await windowManager.setAsFrameless();
      await register(Constants.scheme);
    }

    WindowOptions windowOptions = WindowOptions(
      title: "Allocate",
      size: (Platform.isMacOS)
          ? Constants.defaultMacOSSize
          : Constants.defaultSize,
      minimumSize:
          (kDebugMode) ? Constants.testDesktopSize : Constants.minDesktopSize,
      center: true,
    );

    // For flutter acrylic + MacOS.
    await Window.initialize();
    await Window.makeTitlebarTransparent();
    await Window.enableFullSizeContentView();
    await Window.hideTitle();

    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
      await windowManager.setPreventClose(true);
    });

    if (Platform.isWindows || Platform.isLinux) {
      await trayManager.setIcon(Platform.isWindows
          ? 'assets/allocatelogo128.ico'
          : 'assets/allocatelogo128.png');

      Menu menu = Menu(
        items: [
          MenuItem(
            key: Constants.showKey,
            label: "Show Window",
          ),
          MenuItem(
            key: Constants.hideKey,
            label: "Hide Window",
          ),
          MenuItem.separator(),
          MenuItem(key: Constants.notificationsKey, label: "Notifications"),
          MenuItem(key: Constants.prefsKey, label: "Preferences"),
          MenuItem.separator(),
          MenuItem(
            key: Constants.quitKey,
            label: "Quit Allocate",
          ),
        ],
      );

      await trayManager.setContextMenu(menu);
    }
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
            up.init(firstLaunch: false);
          }

          if (vm.pushUpdate) {
            up.updateUser();
          }

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

class _MyAppState extends State<MyApp> with WindowListener, TrayListener {
  late final AppRouter _appRouter;
  late final ApplicationService _applicationService;

  // Having difficulty getting applinks to work with approuter.
  // late AppLinks _appLinks;
  // StreamSubscription<Uri>? _subscription;

  @override
  void initState() {
    super.initState();
    _applicationService = ApplicationService.instance;
    _appRouter = _applicationService.appRouter;
    if (!(Platform.isAndroid || Platform.isIOS)) {
      windowManager.addListener(this);
    }
    if (Platform.isLinux || Platform.isWindows) {
      trayManager.addListener(this);
    }
    // _appLinks = AppLinks();
    // _initDeepLinking();
  }

  @override
  void dispose() {
    if (!(Platform.isAndroid || Platform.isIOS)) {
      windowManager.removeListener(this);
    }

    if (Platform.isLinux || Platform.isWindows) {
      trayManager.removeListener(this);
    }
    super.dispose();
  }

  @override
  void onWindowClose() async {
    _applicationService.hidden.value = true;
    FocusScope.of(context).unfocus();

    if (Platform.isMacOS) {
      // This should be initialized by flutter acrylic.
      await WindowManipulator.orderOut();
      return;
    }
    await windowManager.hide();
  }

  // TODO: test windows.
  @override
  void onTrayIconMouseDown() {
    if (Platform.isLinux) {
      trayManager.popUpContextMenu();
    }
  }

  // TODO: test windows.
  @override
  void onTrayIconRightMouseDown() {
    trayManager.popUpContextMenu();
  }

  @override
  void onWindowFocus() {
    _applicationService.hidden.value = false;
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) async {
    if (menuItem.key == Constants.showKey) {
      await windowManager.show();
      await windowManager.focus();
      return;
    }
    if (menuItem.key == Constants.notificationsKey) {
      if (Provider.of<UserProvider>(context, listen: false).initialized) {
        Provider.of<LayoutProvider>(context, listen: false).selectedPageIndex =
            1;
      } else {
        ApplicationService.instance.initialPageIndex = 1;
      }

      await windowManager.show();
      await windowManager.focus();
      return;
    }

    if (menuItem.key == Constants.prefsKey) {
      if (Provider.of<UserProvider>(context, listen: false).initialized) {
        Provider.of<LayoutProvider>(context, listen: false).selectedPageIndex =
            Constants.viewRoutes.indexOf(Constants.settingsScreen);
      } else {
        ApplicationService.instance.initialPageIndex =
            Constants.viewRoutes.indexOf(Constants.settingsScreen);
      }

      await windowManager.show();
      await windowManager.focus();
      return;
    }

    if (menuItem.key == Constants.hideKey) {
      await windowManager.close();
    }

    if (menuItem.key == Constants.quitKey) {
      SystemNavigator.pop();
      // Windows issue in flutter.
      if (Platform.isWindows) {
        exit(0);
      }
    }
  }

  // Future<void> _initDeepLinking() async{
  //   _appLinks = AppLinks();
  //
  //   final Uri? appLink = await _appLinks.getInitialAppLink();
  //   if(null != appLink){
  //     print("initial appLink: $appLink");
  //     handleAppLink(appLink);
  //   }
  //
  //   _subscription = _appLinks.uriLinkStream.listen((uri){
  //     print("appLink: $uri");
  //     handleAppLink(uri);
  //   });
  //   print("debug");
  // }
  //
  // void handleAppLink(Uri uri){
  //  String path = uri.toString();
  //  if(path.isEmpty){
  //    print("empty");
  //    return;
  //  }
  //
  //  if(path.contains("login")){
  //    print("login");
  //   _appRouter.navigate(const LoginRoute());
  //   return;
  //  }
  //  if(path.contains("validate-email")){
  //    print("validate-email");
  //    _appRouter.navigate(const ValidateEmailChangeRoute());
  //    return;
  //  }
  //
  //  if(path.contains("home")){
  //    print("home");
  //    if(!Provider.of<UserProvider>(context, listen: false).initialized){
  //      _appRouter.navigate(SplashRoute());
  //      return;
  //    }
  //    _appRouter.navigate(HomeRoute(index: 0));
  //    return;
  //  }
  // }

  @override
  Widget build(BuildContext context) {
    Widget app = Consumer<ThemeProvider>(
        builder: (BuildContext context, ThemeProvider value, Widget? child) {
      return MaterialApp.router(
        // Two-finger scroll fix.
        scrollBehavior: const MaterialScrollBehavior().copyWith(
            multitouchDragStrategy: MultitouchDragStrategy.latestPointer),
        // ScrollConfiguration.of(context).copyWith(
        //   multitouchDragStrategy: MultitouchDragStrategy.latestPointer,
        // ),
        theme: value.lightTheme,
        darkTheme: value.darkTheme,
        highContrastTheme: value.highContrastLight,
        highContrastDarkTheme: value.highContrastDark,
        themeMode: switch (value.themeType) {
          ThemeType.light => ThemeMode.light,
          ThemeType.dark => ThemeMode.dark,
          ThemeType.system => ThemeMode.system,
        },
        // routerConfig: _appRouter.config(),
        routerConfig: _appRouter.config(deepLinkBuilder: (deeplink) {
          // These seem to be busted - waiting on pkg maintainer
          if (deeplink.path.contains("home")) {
            if (_appRouter.isRouteActive("/home")) {
              return DeepLink([HomeRoute(index: 0)]);
            }
            return DeepLink([SplashRoute(initialIndex: 0)]);
          }

          if (deeplink.path.contains("login")) {
            if (_appRouter.isRouteActive("/home")) {
              return DeepLink([
                HomeRoute(
                    index:
                        Constants.viewRoutes.indexOf(Constants.settingsScreen))
              ]);
            }
            return DeepLink([
              SplashRoute(
                initialIndex:
                    Constants.viewRoutes.indexOf(Constants.settingsScreen),
              )
            ]);
          }

          if (deeplink.path.contains("validate-email")) {
            if (_appRouter.isRouteActive("/home")) {
              return DeepLink([
                HomeRoute(
                    index:
                        Constants.viewRoutes.indexOf(Constants.settingsScreen))
              ]);
            }
            return DeepLink([
              SplashRoute(
                initialIndex:
                    Constants.viewRoutes.indexOf(Constants.settingsScreen),
              )
            ]);
          }

          // This is just "root".
          return DeepLink([SplashRoute(initialIndex: 0)]);
        }),
      );
    });

    if (Platform.isIOS || Platform.isAndroid) {
      return app;
    }

    return ValueListenableBuilder(
        valueListenable: _applicationService.hidden,
        builder: (BuildContext context, bool value, Widget? child) {
          return (Platform.isMacOS)
              ? CallbackShortcuts(
                  bindings: <ShortcutActivator, VoidCallback>{
                    const SingleActivator(LogicalKeyboardKey.keyW,
                        meta: true, includeRepeats: false): () async {
                      if (value) {
                        return;
                      }
                      await windowManager.close();
                    }
                  },
                  child: PlatformMenuBar(
                    menus: finderBar(context: context),
                    child: app,
                  ),
                )
              : CallbackShortcuts(bindings: <ShortcutActivator, VoidCallback>{
                  const SingleActivator(LogicalKeyboardKey.keyW,
                      control: true, includeRepeats: false): () async {
                    if (value) {
                      return;
                    }
                    await windowManager.close();
                  }
                }, child: app);
        });
  }
}

// WINDOWS REGISTERRING DEEPLINKING
Future<void> register(String scheme) async {
  String appPath = Platform.resolvedExecutable;

  String protocolRegKey = 'Software\\Classes\\$scheme';
  RegistryValue protocolRegValue = const RegistryValue(
    'URL Protocol',
    RegistryValueType.string,
    '',
  );
  String protocolCmdRegKey = 'shell\\open\\command';
  RegistryValue protocolCmdRegValue = RegistryValue(
    '',
    RegistryValueType.string,
    '"$appPath" "%1"',
  );

  final regKey = Registry.currentUser.createKey(protocolRegKey);
  regKey.createValue(protocolRegValue);
  regKey.createKey(protocolCmdRegKey).createValue(protocolCmdRegValue);
}
