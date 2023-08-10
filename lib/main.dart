import "dart:ui";

import "package:allocate/providers/reminder_provider.dart";
import "package:allocate/providers/routine_provider.dart";
import "package:allocate/providers/todo_provider.dart";
import "package:allocate/providers/user_provider.dart";
import "package:allocate/services/isar_service.dart";
import "package:allocate/services/supabase_service.dart";
import "package:allocate/ui/app_router.dart";
import "package:allocate/util/constants.dart";
import 'package:flutter/material.dart';
import "package:provider/provider.dart";
import "package:supabase_flutter/supabase_flutter.dart" hide Provider;

import "providers/deadline_provider.dart";
import "providers/group_provider.dart";

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  runApp(
    MultiProvider(providers: [
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
    SupabaseService.instance
        .init(supabaseUrl: Constants.supabaseURL, anonKey: Constants.supabaseAnnonKey);
    super.initState();

    // These are really not all that important.
    SupabaseService.instance.supabaseClient.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      if (event == AuthChangeEvent.signedIn) {
        _appRouter
          ..popUntilRoot()
          ..replace(const HomeRoute());
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
