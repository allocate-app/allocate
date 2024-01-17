import "dart:ui";

import 'package:flutter/material.dart';
import "package:provider/provider.dart";
import "package:supabase_flutter/supabase_flutter.dart";

import 'providers/model/deadline_provider.dart';
import 'providers/model/group_provider.dart';
import 'providers/model/reminder_provider.dart';
import "providers/model/routine_provider.dart";
import 'providers/model/todo_provider.dart';
import 'providers/model/user_provider.dart';
import "services/isar_service.dart";
import "services/supabase_service.dart";
import "ui/app_router.dart";
import "util/constants.dart";

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  // Factor this MP out into a method pls.
  runApp(
    MultiProvider(providers: [
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
                    Provider.of<UserProvider>(context, listen: false).curUser,
              ),
          update: (BuildContext context, UserProvider up, RoutineProvider? rp) {
            rp?.setUser(newUser: up.curUser);
            return rp ?? RoutineProvider(userViewModel: up.curUser);
          }),
      ChangeNotifierProxyProvider<UserProvider, ReminderProvider>(
          create: (BuildContext context) => ReminderProvider(
              userViewModel:
                  Provider.of<UserProvider>(context, listen: false).curUser),
          update:
              (BuildContext context, UserProvider up, ReminderProvider? rp) {
            rp?.setUser(newUser: up.curUser);
            return rp ?? ReminderProvider(userViewModel: up.curUser);
          }),
      ChangeNotifierProxyProvider<UserProvider, DeadlineProvider>(
          create: (BuildContext context) => DeadlineProvider(
              userViewModel:
                  Provider.of<UserProvider>(context, listen: false).curUser),
          update:
              (BuildContext context, UserProvider up, DeadlineProvider? dp) {
            dp?.setUser(newUser: up.curUser);
            return dp ?? DeadlineProvider(userViewModel: up.curUser);
          }),
      ChangeNotifierProxyProvider<UserProvider, GroupProvider>(
          create: (BuildContext context) => GroupProvider(
              user: Provider.of<UserProvider>(context, listen: false).curUser),
          update: (BuildContext context, UserProvider up, GroupProvider? gp) {
            gp?.setUser(newUser: up.curUser);
            return gp ?? GroupProvider(user: up.curUser);
          })
    ], child: const MyApp()),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  // NOTE: Will need to set a watcher for the user's current theme prefs.
  // Bind accordingly and set the default to system.
  // Also, make themes.

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _appRouter = AppRouter();

  @override
  void initState() {
    IsarService.instance.init();
    SupabaseService.instance.init(
        supabaseUrl: Constants.supabaseURL,
        anonKey: Constants.supabaseAnnonKey);
    super.initState();

    // These are really not all that important.
    SupabaseService.instance.supabaseClient.auth.onAuthStateChange
        .listen((data) {
      final AuthChangeEvent event = data.event;
      if (event == AuthChangeEvent.signedIn) {
        _appRouter
          ..popUntilRoot()
          ..replace(HomeRoute());
      } else if (event == AuthChangeEvent.signedOut) {
        _appRouter
          ..popUntilRoot()
          ..replace(const LoginRoute());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      // Change this as necessary
      // Store themes in a static ui class - and a hashtable for theme values.
      theme: ThemeData(useMaterial3: true),
      routerConfig: _appRouter.config(
          // Deeplink interceptor -> Only if necessary.
          // deepLinkBuilder: (deeplink) {
          // return deeplink;
          // }
          ),
      routerDelegate: _appRouter.delegate(),
      routeInformationParser: _appRouter.defaultRouteParser(),
    );
  }
}
