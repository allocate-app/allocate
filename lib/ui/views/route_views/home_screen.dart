import "dart:developer";
import "dart:io";

import "package:auto_route/auto_route.dart";
import "package:flutter/material.dart";
import "package:provider/provider.dart";

import '../../../model/user/user.dart';
import '../../../providers/deadline_provider.dart';
import '../../../providers/reminder_provider.dart';
import '../../../providers/routine_provider.dart';
import '../../../providers/todo_provider.dart';
import '../../../providers/user_provider.dart';
import '../../../util/exceptions.dart';
import '../../../util/interfaces/crossbuild.dart';
import '../../app_router.dart';
import "../sub_views.dart";

// This will need AutotabsRouter of some sort.
// Also, Adaptive Layout.
@RoutePage()
class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreen();
}

class _HomeScreen extends State<HomeScreen> implements CrossBuild {
  // This is to prevent users from overloading with tasks.
  int dayWeight = 0;

  User? user;
  int selectedPageIndex = 0;

  static const List<NavigationDrawerDestination> destinations = [
    // HOME - My Day
    NavigationDrawerDestination(
        icon: Icon(Icons.house_outlined), label: Text("Home"), selectedIcon: Icon(Icons.house)),

    // Notifications (ie, overdue)
    NavigationDrawerDestination(
      icon: Icon(Icons.notification_add_outlined),
      label: Text("Notifications"),
      selectedIcon: Icon(Icons.notification_add),
    ),

    // ToDos
    NavigationDrawerDestination(
      icon: Icon(Icons.abc_outlined),
      label: Text("ToDos"),
      selectedIcon: Icon(Icons.abc),
    )

    // Completed

    // Groups

    // Uh, More if needed.
  ];
  @override
  void initState() {
    super.initState();

    // TODO: Clean up aggregate logic. Factor into method.
    // User verification can go -> Is handled in splash scrn.
    final UserProvider userProvider = Provider.of<UserProvider>(context, listen: false);

    final RoutineProvider routineProvider = Provider.of<RoutineProvider>(context, listen: false);
    final ToDoProvider toDoProvider = Provider.of<ToDoProvider>(context, listen: false);
    Future.wait([
      userProvider.loadedUser,
      toDoProvider.getMyDayWeight(),
      Future.delayed(const Duration(milliseconds: 2000))
    ]).then((responseList) {
      user = userProvider.curUser ?? responseList.first;
      dayWeight = responseList[1];

      if (null == user) {
        return context.router.replace(const InitUserRoute());
      }

      DateTime now = DateTime.now();
      // Check if day has changed -> If so, reset routines, generate repeating
      // tasks, then move to home screen.
      if (now.day != user!.lastOpened.day) {
        // These are for recurring tasks.
        toDoProvider.checkRepeating(now: now);

        routineProvider.resetRoutines();

        //Provider.of<ReminderProvider>(context, listen: false).checkRepeating(now: now);

        Provider.of<DeadlineProvider>(context, listen: false).checkRepeating(now: now);
      }

      user!.lastOpened = now;
      // This will update the user time on the next update sweep.
      userProvider.retry = true;
    }).catchError((e) {
      UserException userException = e as UserException;
      log(userException.cause);
      return context.router
          .replace((null == userProvider.curUser) ? const InitUserRoute() : const HomeRoute());
    }, test: (e) => e is UserException);
  }

  @override
  Widget build(BuildContext context) {
    if (Platform.isAndroid || Platform.isIOS) {
      return buildMobile(context: context);
    } else {
      return buildDesktop(context: context);
    }
  }

  // TBH, just write in the NavigationDrawer.
  @override
  Widget buildDesktop({required BuildContext context}) {
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Row(children: [
          // Children are the other thingies
          NavigationDrawer(
            selectedIndex: selectedPageIndex,
            onDestinationSelected: (int index) => setState(() => selectedPageIndex = index),
            children: [
              // Header -- Search Bar? User settings
              Container(),
              // Destination Nav
              ..._HomeScreen.destinations,

              // Bottom half - User settings.
              Container()
            ],
          ),
          // Destinations Here.
          [
            MyDayScreen(),
            // THESE NEED TO BE IN DESTINATION ORDER
          ][selectedPageIndex]
        ]),
      ),
    );
  }

  // TODO: Refactor this, but seems to work.
  @override
  Widget buildMobile({required BuildContext context}) {
    return Scaffold(
        appBar: AppBar(),
        body: SafeArea(child: [MyDayScreen()][selectedPageIndex]),
        drawer: NavigationDrawer(
          selectedIndex: selectedPageIndex,
          onDestinationSelected: (int index) => setState(() => selectedPageIndex = index),
          children: [],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => (dayWeight < user!.bandwidth)
              ? showDialog(
                  context: context, builder: (BuildContext context) => const CreateToDoScreen())
              : null,
        ));
  }
}
