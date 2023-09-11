import 'package:allocate/ui/views/route_views/user_settings.dart';
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
import '../../widgets/desktop_drawer_wrapper.dart';
import '../../widgets/flushbars.dart';
import '../../widgets/padded_divider.dart';
import '../routes.dart';
import '../sub_views.dart';
import 'deadlines_screen.dart';
import 'reminders_screen.dart';

@RoutePage()
class HomeScreen extends StatefulWidget {
  final int? index;

  const HomeScreen({Key? key, this.index}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreen();
}

class _HomeScreen extends State<HomeScreen> {
  late int selectedPageIndex;
  late final PageStorageBucket bucket;

  late final ToDoProvider toDoProvider;
  late final RoutineProvider routineProvider;
  late final UserProvider userProvider;
  late final GroupProvider groupProvider;

  late Future<List<Group>> groupFuture;

  late bool mainLoading;
  late bool subLoading;

  late final ScrollController navScrollController;

  //late final ScrollController mainScrollController;
  late final ScrollPhysics scrollPhysics;

  // TODO: Potentially move to constants class.
  // Separate Screens.
  static ViewRoute groupScreen =
      const ViewRoute(view: GroupScreen(), name: "Groups");
  static ViewRoute settingsScreen = const ViewRoute(
    view: UserSettingsScreen(),
    name: "Settings",
  );

  static List<ViewRoute> viewRoutes = [
    const ViewRoute(
      destination: NavigationDrawerDestination(
        icon: Icon(Icons.home_outlined),
        label: Text("Home", overflow: TextOverflow.ellipsis),
        selectedIcon: Icon(Icons.home_rounded),
      ),
      view: MyDayScreen(),
      name: "My Day",
    ),

    const ViewRoute(
      destination: NavigationDrawerDestination(
        icon: Icon(Icons.notifications_outlined),
        label: Text("Notifications"),
        selectedIcon: Icon(Icons.notifications_rounded),
      ),
      view: NotificationsScreen(),
      name: "Notifications",
    ),

    const ViewRoute(
      destination: NavigationDrawerDestination(
          icon: Icon(Icons.push_pin_outlined),
          selectedIcon: Icon(Icons.push_pin_rounded),
          label: Text("Reminders")),
      view: RemindersListScreen(),
      name: "Reminders",
    ),

    const ViewRoute(
        destination: NavigationDrawerDestination(
          icon: Icon(Icons.announcement_outlined),
          label: Text("Deadlines"),
          selectedIcon: Icon(Icons.announcement_rounded),
        ),
        view: DeadlinesListScreen(),
        name: "Deadlines"),

    const ViewRoute(
        destination: NavigationDrawerDestination(
          icon: Icon(Icons.task_outlined),
          label: Text("Tasks"),
          selectedIcon: Icon(Icons.task_rounded),
        ),
        view: ToDosListScreen(key: PageStorageKey<String>("ToDoListPage")),
        name: "Tasks"),

    // Completed
    const ViewRoute(
        destination: NavigationDrawerDestination(
          icon: Icon(Icons.task_alt_outlined),
          label: Text("Completed"),
          selectedIcon: Icon(Icons.task_alt_rounded),
        ),
        view: CompletedListScreen(),
        name: "Completed"),
    // Routines
    const ViewRoute(
        destination: NavigationDrawerDestination(
          icon: Icon(Icons.repeat_rounded),
          label: Text("Routines"),
          selectedIcon: Icon(Icons.repeat_rounded),
        ),
        view: RoutinesListScreen(),
        name: "Routines"),
    groupScreen,
    settingsScreen,
  ];

  List<Widget> views = viewRoutes.map((view) => view.view).toList();

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

  void resetProviders() {
    toDoProvider.rebuild = true;
    routineProvider.rebuild = true;
    // userProvider.rebuild = true
    groupProvider.rebuild = true;
  }

  void initializeParams() {
    selectedPageIndex = widget.index ?? 0;
    mainLoading = false;
    subLoading = false;
    bucket = PageStorageBucket();
    groupFuture = groupProvider.mostRecent(grabToDos: true);
  }

  void initializeControllers() {
    navScrollController = ScrollController();
    scrollPhysics =
        const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics());
  }

  Future<void> resetNavGroups() async {
    setState(() {
      subLoading = true;
    });

    return Future.delayed(
        const Duration(seconds: 1),
        () async => await groupProvider
            .setMostRecent()
            .whenComplete(() => setState(() => subLoading = false)));
  }

  @override
  void dispose() {
    toDoProvider.removeListener(updateDayWeight);
    routineProvider.removeListener(updateDayWeight);
    super.dispose();
  }

  // TODO: Figure out some way to factor this into the app bar.
  Widget buildDrainBar({required BuildContext context}) {
    int maxBandwidth =
        userProvider.curUser?.bandwidth ?? Constants.maxBandwidth;
    double offset =
        userProvider.myDayTotal.toDouble() / maxBandwidth.toDouble();
    return Transform.scale(
      scale: 0.75,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 100, maxHeight: 50),
        child: Stack(alignment: Alignment.center, children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Constants.padding),
            child: Container(
              decoration: BoxDecoration(
                  border: Border.all(
                      color: Theme.of(context).colorScheme.outline,
                      width: 3,
                      strokeAlign: BorderSide.strokeAlignCenter),
                  shape: BoxShape.rectangle,
                  borderRadius: const BorderRadius.all(Radius.circular(10))),
              child: Padding(
                padding: const EdgeInsets.all(Constants.halfPadding),
                child: LinearProgressIndicator(
                    color: (offset < 0.8) ? null : Colors.redAccent,
                    minHeight: 50,
                    value: 1 - offset,
                    // Possibly remove
                    borderRadius: const BorderRadius.all(Radius.circular(10))),
              ),
            ),
          ),
          Align(
              alignment: Alignment.centerRight,
              child: Container(
                  height: 40,
                  width: 8,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.all(Radius.circular(2)),
                    color: Theme.of(context).colorScheme.outline,
                  ))),
          AutoSizeText("${maxBandwidth - userProvider.myDayTotal}",
              minFontSize: Constants.large,
              softWrap: false,
              maxLines: 1,
              overflow: TextOverflow.visible,
              style: Constants.hugeHeaderStyle),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool largeScreen =
        (MediaQuery.of(context).size.width >= Constants.largeScreen);
    bool smallScreen =
        (MediaQuery.of(context).size.width <= Constants.smallScreen);

    return (largeScreen)
        ? buildDesktop(context: context, largeScreen: largeScreen)
        : buildMobile(context: context, largeScreen: largeScreen);
  }

  Widget buildDesktop(
      {required BuildContext context, bool largeScreen = true}) {
    return Row(children: [
      // This is a workaround for a standard navigation drawer
      // until m3 spec is fully implemented in flutter.
      DesktopDrawerWrapper(
          drawer: buildNavigationDrawer(
              context: context, largeScreen: largeScreen)),

      Expanded(
          child: Scaffold(
              appBar: buildAppBar(context: context),
              body: SafeArea(
                  child: PageStorage(
                      bucket: bucket,
                      child: viewRoutes[selectedPageIndex].view))))
    ]);
  }

  Widget buildMobile(
      {required BuildContext context, bool largeScreen = false}) {
    return Scaffold(
        appBar: buildAppBar(context: context),
        drawer:
            buildNavigationDrawer(context: context, largeScreen: largeScreen),
        body: SafeArea(
            child: PageStorage(
                bucket: bucket, child: viewRoutes[selectedPageIndex].view)));
  }

  AppBar buildAppBar({required BuildContext context}) {
    return AppBar(
      title: buildDrainBar(context: context),
      centerTitle: true,
    );
  }

  NavigationDrawer buildNavigationDrawer(
      {required BuildContext context, bool largeScreen = false}) {
    return NavigationDrawer(
        onDestinationSelected: (index) {
          setState(() {
            selectedPageIndex = index;
            resetProviders();
          });
          if (!largeScreen) {
            Navigator.pop(context);
          }
        },
        selectedIndex: selectedPageIndex,
        children: [
          // User name bar
          // Possible stretch Goal: add user images?
          SizedBox(
            height: 100,
            child: DrawerHeader(
              child: ListTile(
                shape: const RoundedRectangleBorder(
                    side: BorderSide(
                        style: BorderStyle.none,
                        strokeAlign: BorderSide.strokeAlignCenter),
                    borderRadius: BorderRadius.all(
                        Radius.circular(Constants.roundedCorners))),
                leading: CircleAvatar(
                    child: Text(
                        "${userProvider.curUser?.userName[0].toUpperCase()}")),
                // Possible TODO: Refactor this to take a first/last name?
                title: Text("${userProvider.curUser?.userName}"),
                // Possible TODO: Refactor this to use an enum.
                subtitle: (null !=
                        SupabaseService
                            .instance.supabaseClient.auth.currentSession)
                    ? const Text("Online")
                    : const Text("Offline"),
                onTap: () => setState(() =>
                    selectedPageIndex = viewRoutes.indexOf(settingsScreen)),
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
                    alert.show(context);
                  },
                ),
              ),
            ),
          ),

          ...viewRoutes
              .map((view) => view.destination ?? const SizedBox.shrink()),
          const PaddedDivider(padding: Constants.innerPadding),
          // Drop down menu for Groups.
          // TODO: Factor rounded rectangle shape to constants class.
          // This Card is a workaround until The ExpansionTile inkwell bug is fixed.
          Card(
            clipBehavior: Clip.hardEdge,
            elevation: 0,
            color: Colors.transparent,
            shape: const RoundedRectangleBorder(
              side: BorderSide(
                  style: BorderStyle.none,
                  strokeAlign: BorderSide.strokeAlignCenter),
              borderRadius:
                  BorderRadius.all(Radius.circular(Constants.roundedCorners)),
            ),
            child: ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(
                  horizontal: Constants.innerPadding + Constants.padding),
              shape: const RoundedRectangleBorder(
                side: BorderSide(
                    style: BorderStyle.none,
                    strokeAlign: BorderSide.strokeAlignCenter),
              ),
              collapsedShape: const RoundedRectangleBorder(
                  side: BorderSide(
                      style: BorderStyle.none,
                      strokeAlign: BorderSide.strokeAlignCenter),
                  borderRadius:
                      BorderRadius.all(Radius.circular(Constants.circular))),
              leading: const Icon(Icons.table_view_outlined),
              title: const Text(
                "Groups",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                softWrap: false,
              ),
              children: [
                // Tile for "See all groups"
                ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: Constants.padding + Constants.innerPadding),
                    shape: const RoundedRectangleBorder(
                        side: BorderSide(
                            style: BorderStyle.none,
                            strokeAlign: BorderSide.strokeAlignCenter),
                        borderRadius: BorderRadius.all(
                            Radius.circular(Constants.roundedCorners))),
                    leading: const Icon(Icons.workspaces_outlined),
                    title: const AutoSizeText(
                      "All Groups",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      softWrap: false,
                    ),
                    onTap: () => setState(() =>
                        selectedPageIndex = viewRoutes.indexOf(groupScreen))),

                ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: Constants.padding + Constants.innerPadding),
                    shape: const RoundedRectangleBorder(
                        side: BorderSide(
                            style: BorderStyle.none,
                            strokeAlign: BorderSide.strokeAlignCenter),
                        borderRadius: BorderRadius.all(
                            Radius.circular(Constants.roundedCorners))),
                    leading: const Icon(Icons.add_rounded),
                    title: const AutoSizeText(
                      "Add New",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      softWrap: false,
                    ),
                    onTap: () async {
                      return await showDialog(
                          barrierDismissible: false,
                          useRootNavigator: false,
                          context: context,
                          builder: (BuildContext context) =>
                              const CreateGroupScreen()).whenComplete(() {
                        resetNavGroups();
                      });
                    }),

                buildNavGroupTile(),
              ],
            ),
          )
        ]);
  }

  ListView buildNavGroupTile() {
    return ListView(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        children: [
          Consumer<GroupProvider>(builder:
              (BuildContext context, GroupProvider value, Widget? child) {
            return ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: value.recentGroups.length,
                itemBuilder: (BuildContext context, int index) {
                  return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal:
                              Constants.padding + Constants.innerPadding),
                      shape: const RoundedRectangleBorder(
                          side: BorderSide(
                              style: BorderStyle.none,
                              strokeAlign: BorderSide.strokeAlignCenter),
                          borderRadius: BorderRadius.all(
                              Radius.circular(Constants.roundedCorners))),
                      leading:
                          const Icon(Icons.playlist_add_check_circle_outlined),
                      title: AutoSizeText(value.recentGroups[index].name,
                          maxLines: 1,
                          overflow: TextOverflow.visible,
                          softWrap: false,
                          minFontSize: Constants.small),
                      onTap: () async {
                        value.curGroup = value.recentGroups[index];
                        return await showDialog(
                            barrierDismissible: false,
                            useRootNavigator: false,
                            context: context,
                            builder: (BuildContext context) =>
                                const UpdateGroupScreen()).whenComplete(() {
                          resetNavGroups();
                        });
                      },
                      trailing: (value.recentGroups[index].toDos.length > 1)
                          ? AutoSizeText(
                              "${value.recentGroups[index].toDos.length}",
                              maxLines: 1,
                              overflow: TextOverflow.visible,
                              softWrap: false,
                              minFontSize: Constants.small)
                          : null);
                });
          }),
          (subLoading)
              ? const Padding(
                  padding: EdgeInsets.all(Constants.padding),
                  child: Center(child: CircularProgressIndicator()),
                )
              : const SizedBox.shrink()
        ]);
  }
}

class ViewRoute {
  final String name;
  final NavigationDrawerDestination? destination;
  final Widget view;

  const ViewRoute({required this.name, this.destination, required this.view});
}
