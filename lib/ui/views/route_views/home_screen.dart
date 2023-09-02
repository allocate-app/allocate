import 'package:another_flushbar/flushbar.dart';
import "package:auto_route/auto_route.dart";
import 'package:auto_size_text/auto_size_text.dart';
import "package:flutter/material.dart";
import "package:provider/provider.dart";

import '../../../model/task/group.dart';
import '../../../providers/group_provider.dart';
import '../../../providers/routine_provider.dart';
import '../../../providers/todo_provider.dart';
import '../../../providers/user_provider.dart';
import '../../../services/supabase_service.dart';
import '../../../util/constants.dart';
import '../../widgets/flushbars.dart';
import '../../widgets/padded_divider.dart';
import '../routes.dart';
import '../sub_views.dart';

@RoutePage()
class HomeScreen extends StatefulWidget {
  final int? index;

  const HomeScreen({Key? key, this.index}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreen();
}

class _HomeScreen extends State<HomeScreen> {
  late int selectedPageIndex;
  late final ToDoProvider toDoProvider;
  late final RoutineProvider routineProvider;
  late final UserProvider userProvider;
  late final GroupProvider groupProvider;

  late bool mainLoading;
  late bool subLoading;

  late final ScrollController navScrollController;

  //late final ScrollController mainScrollController;
  late final ScrollPhysics scrollPhysics;

  // TODO: Factor this out to constants class once implementations built.
  static List<MapEntry<NavigationDrawerDestination, Widget>> viewRoutes = [
    MapEntry(
        const NavigationDrawerDestination(
          icon: Icon(Icons.home_outlined),
          label: Text("Home", overflow: TextOverflow.ellipsis),
          selectedIcon: Icon(Icons.home),
        ),
        MyDayScreen()),
    MapEntry(
      const NavigationDrawerDestination(
        icon: Icon(Icons.notifications_outlined),
        label: Text("Notifications"),
        selectedIcon: Icon(Icons.notifications),
      ),
      NotificationsScreen(),
    ),

    MapEntry(
        const NavigationDrawerDestination(
          icon: Icon(Icons.task_outlined),
          label: Text("ToDos"),
          selectedIcon: Icon(Icons.task),
        ),
        ToDosScreen()),

    // Completed


    // Routines

    // This is for group view.
    MapEntry(
        const NavigationDrawerDestination(
          icon: Icon(Icons.workspaces_outlined),
          label: Text("Everything", overflow: TextOverflow.ellipsis),
          selectedIcon: Icon(Icons.workspaces),
        ),
        GroupScreen())
  ];

  void updateDayWeight() async {
    await toDoProvider.getMyDayWeight().then((weight) {
      weight += routineProvider.routineWeight;
      userProvider.myDayTotal = weight;
    });
  }

  @override
  void initState() {
    super.initState();
    initializeProviders();
    initializeParams();
    initializeControllers();
    updateDayWeight();
  }

  void initializeProviders() {
    toDoProvider = Provider.of<ToDoProvider>(context, listen: false);
    routineProvider = Provider.of<RoutineProvider>(context, listen: false);
    userProvider = Provider.of<UserProvider>(context, listen: false);
    groupProvider = Provider.of<GroupProvider>(context, listen: false);

    toDoProvider.addListener(updateDayWeight);
    routineProvider.addListener(updateDayWeight);
  }

  void initializeParams() {
    selectedPageIndex = widget.index ?? 0;
    mainLoading = false;
    subLoading = false;
  }

  void initializeControllers() {
    navScrollController = ScrollController();
    scrollPhysics =
    const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics());
  }

  @override
  void dispose() {
    toDoProvider.removeListener(updateDayWeight);
    routineProvider.removeListener(updateDayWeight);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool largeScreen =
    (MediaQuery
        .of(context)
        .size
        .width >= Constants.largeScreen);
    bool smallScreen =
    (MediaQuery
        .of(context)
        .size
        .width <= Constants.smallScreen);

    return (largeScreen)
        ? buildDesktop(context: context)
        : buildMobile(context: context);
  }

  Widget buildDesktop({required BuildContext context}) {
    return Scaffold(
        body: Row(children: [
          // TODO: Build a wrapper for standard navdrawer.
          buildNavigationDrawer(context: context),

          Expanded(child: viewRoutes[selectedPageIndex].value)
        ]));
  }

  Widget buildMobile({required BuildContext context}) {
    return Scaffold(
      drawer: buildNavigationDrawer(context: context),
    );
  }

  NavigationDrawer buildNavigationDrawer({required BuildContext context}) {
    return NavigationDrawer(
        onDestinationSelected: (index) =>
            setState(() => selectedPageIndex = index),
        selectedIndex: selectedPageIndex,
        children: [
          // User name bar
          // Possible stretch Goal: add user images?
          ListTile(
            leading: CircleAvatar(
                child:
                Text("${userProvider.curUser?.userName[0].toUpperCase()}")),
            // Possible TODO: Refactor this to take a first/last name?
            title: Text("${userProvider.curUser?.userName}"),
            // Possible TODO: Refactor this to use an enum.
            subtitle: (null !=
                SupabaseService.instance.supabaseClient.auth.currentSession)
                ? const Text("Online: Sync resumed.")
                : const Text("Offline: Sync paused."),
            onTap: () {
              // TODO: Hook up auto-router -> Push to user settings.
              // TODO Twice: Consider making a blank user -> Only one screen, just update.
            },
            trailing: IconButton(
              icon: const Icon(Icons.search_outlined),
              selectedIcon: const Icon(Icons.search),
              onPressed: () {
                Flushbar? alert;
                alert = Flushbars.createAlert(
                  context: context,
                  message: "Feature not implemented yet, coming soon!",
                  dismissCallback: () => alert?.dismiss(),
                );
              },
            ),
          ),

          // ListView for remaining widgets
          ListView(
              controller: navScrollController,
              physics: scrollPhysics,
              children: [
                ...viewRoutes
                    .sublist(0, viewRoutes.length - 1)
                    .map((view) => view.key),
                const PaddedDivider(padding: Constants.innerPadding),
                // Drop down menu for Groups.
                ExpansionTile(
                  title: const AutoSizeText("Groups",
                      maxLines: 1,
                      overflow: TextOverflow.visible,
                      softWrap: false,
                      minFontSize: Constants.small),
                  children: [
                    // Tile for "See all groups"
                    viewRoutes.last.key,
                    buildNavGroupTile(),
                  ],
                )
              ])
        ]);
  }

  FutureBuilder<List<Group>> buildNavGroupTile() {
    return FutureBuilder(
      future: groupProvider.mostRecent(grabToDos: true),
      builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          final List<Group>? groups = snapshot.data;
          if (null != groups) {
            return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: groups.length,
                itemBuilder: (BuildContext context, int index) {
                  return ListTile(
                      leading:
                      const Icon(Icons.playlist_add_check_circle_outlined),
                      title: AutoSizeText(groups[index].name,
                          maxLines: 1,
                          overflow: TextOverflow.visible,
                          softWrap: false,
                          minFontSize: Constants.small),
                      onTap: () async =>
                      await showDialog(
                          barrierDismissible: false,
                          useRootNavigator: false,
                          context: context,
                          builder: (BuildContext context) =>
                          const UpdateGroupScreen())
                          .whenComplete(() => setState(() {})),
                      trailing: (groups[index].toDos.length > 1)
                          ? AutoSizeText("${groups[index].toDos.length}",
                          maxLines: 1,
                          overflow: TextOverflow.visible,
                          softWrap: false,
                          minFontSize: Constants.small)
                          : null);
                });
          }
          // This is what to render if no data.
          return const SizedBox.shrink();
        }
        return const Padding(
          padding: EdgeInsets.all(Constants.padding),
          child: CircularProgressIndicator(),
        );
      },
    );
  }
}
