import "dart:async";
import "dart:developer";
import "dart:ui";

import "package:allocate/providers/reminder_provider.dart";
import "package:allocate/providers/routine_provider.dart";
import "package:allocate/providers/todo_provider.dart";
import "package:allocate/providers/user_provider.dart";
import "package:allocate/services/isar_service.dart";
import "package:allocate/services/supabase_service.dart";
import "package:allocate/util/constants.dart";
import "package:connectivity_plus/connectivity_plus.dart";
import 'package:flutter/material.dart';
import "package:internet_connection_checker/internet_connection_checker.dart";
import "package:provider/provider.dart";

import "providers/deadline_provider.dart";
import "providers/group_provider.dart";

ValueNotifier<bool> isDeviceConnected = ValueNotifier(false);
// TODO: Add proxy providers for the entire model. Refactor according to todoprovider
// TODO: remove internet_connection_checker.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  runApp(
    MultiProvider(providers: [
      ChangeNotifierProvider<UserProvider>(create: (_) => UserProvider()),
      ChangeNotifierProxyProvider<UserProvider, ToDoProvider>(
          create: (BuildContext context) => ToDoProvider(
              user: Provider.of<UserProvider>(context, listen: false).curUser,
              service: null),
          update: (BuildContext context, UserProvider up, ToDoProvider? tp) {
            tp?.setUser(user: up.curUser);
            return tp ?? ToDoProvider(user: up.curUser, service: null);
          }),
      ChangeNotifierProxyProvider<UserProvider, RoutineProvider>(
          create: (BuildContext context) => RoutineProvider(
              user: Provider.of<UserProvider>(context, listen: false).curUser,
              service: null),
          update: (BuildContext context, UserProvider up, RoutineProvider? rp) {
            rp?.setUser(user: up.curUser);
            return rp ?? RoutineProvider(user: up.curUser, service: null);
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
    ], child: const App()),
  );
}

class App extends StatefulWidget {
  const App({super.key});

  @override
  _AppState createState() => _AppState();
}

class _AppState extends State<App> {
  late StreamSubscription<ConnectivityResult> subscription;
  @override
  void initState() {
    IsarService.instance.init();
    SupabaseService.instance.init(
        supabaseUrl: Constants.supabaseURL,
        anonKey: Constants.supabaseAnnonKey);
    super.initState();
    subscription = Connectivity()
        .onConnectivityChanged
        .listen((ConnectivityResult result) async {
      isDeviceConnected.value = await InternetConnectionChecker().hasConnection;
      log("Internet Connected: $isDeviceConnected");
    });
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    throw UnimplementedError();
  }
}

// This widget is the root of your application.
@override
Widget build(BuildContext context) {
  return MaterialApp(
    title: 'Flutter Demo',
    theme: ThemeData(
      // This is the theme of your application.
      //
      // TRY THIS: Try running your application with "flutter run". You'll see
      // the application has a blue toolbar. Then, without quitting the app,
      // try changing the seedColor in the colorScheme below to Colors.green
      // and then invoke "hot reload" (save your changes or press the "hot
      // reload" button in a Flutter-supported IDE, or press "r" if you used
      // the command line to start the app).
      //
      // Notice that the counter didn't reset back to zero; the application
      // state is not lost during the reload. To reset the state, use hot
      // restart instead.
      //
      // This works for code too, not just values: Most code changes can be
      // tested with just a hot reload.
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      useMaterial3: true,
    ),
    home: const MyHomePage(title: 'Flutter Demo Home Page'),
  );
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          //
          // TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint"
          // action in the IDE, or press "p" in the console), to see the
          // wireframe for each widget.
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
