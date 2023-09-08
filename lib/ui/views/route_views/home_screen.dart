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
        selectedIcon: Icon(Icons.home),
      ),
      view: MyDayScreen(),
      name: "My Day",
    ),

    const ViewRoute(
      destination: NavigationDrawerDestination(
        icon: Icon(Icons.notifications_outlined),
        label: Text("Notifications"),
        selectedIcon: Icon(Icons.notifications),
      ),
      view: NotificationsScreen(),
      name: "Notifications",
    ),

    const ViewRoute(
        destination: NavigationDrawerDestination(
          icon: Icon(Icons.task_outlined),
          label: Text("Tasks"),
          selectedIcon: Icon(Icons.task),
        ),
        view: ToDosListScreen(key: PageStorageKey<String>("ToDoListPage")),
        name: "Tasks"),

    // Completed
    const ViewRoute(
        destination: NavigationDrawerDestination(
          icon: Icon(Icons.task_alt_outlined),
          label: Text("Completed"),
          selectedIcon: Icon(Icons.task_alt),
        ),
        view: CompletedListScreen(),
        name: "Completed"),
    // Routines
    const ViewRoute(
        destination: NavigationDrawerDestination(
          icon: Icon(Icons.repeat_outlined),
          label: Text("Routines"),
          selectedIcon: Icon(Icons.repeat),
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
        (MediaQuery.of(context).size.width >= Constants.largeScreen);
    bool smallScreen =
        (MediaQuery.of(context).size.width <= Constants.smallScreen);

    return (largeScreen)
        ? buildDesktop(context: context)
        : buildMobile(context: context);
  }

  Widget buildDesktop({required BuildContext context, Widget? view}) {
    return Row(children: [
      // This is a workaround for a standard navigation drawer
      // until m3 spec is fully implemented in flutter.
      DesktopDrawerWrapper(drawer: buildNavigationDrawer(context: context)),

      Expanded(
          child: Scaffold(
              appBar: buildAppBar(),
              body: SafeArea(
                  child: PageStorage(
                      bucket: bucket,
                      child: viewRoutes[selectedPageIndex].view))))
    ]);
  }

  Widget buildMobile({required BuildContext context, Widget? view}) {
    return Scaffold(
        appBar: buildAppBar(),
        drawer: buildNavigationDrawer(context: context),
        body: SafeArea(
            child: PageStorage(
                bucket: bucket, child: viewRoutes[selectedPageIndex].view)));
  }

  AppBar buildAppBar() {
    return AppBar(
      title: Text(viewRoutes.elementAt(selectedPageIndex).name),
      centerTitle: true,
    );
  }

  NavigationDrawer buildNavigationDrawer({required BuildContext context}) {
    return NavigationDrawer(
        onDestinationSelected: (index) {
          setState(() {
            selectedPageIndex = index;
            resetProviders();
          });
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
                      "Everything",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      softWrap: false,
                    ),
                    onTap: () => setState(() =>
                        selectedPageIndex = viewRoutes.indexOf(groupScreen))),
                buildNavGroupTile(),
              ],
            ),
          )
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
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: groups.length,
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
                      title: AutoSizeText(groups[index].name,
                          maxLines: 1,
                          overflow: TextOverflow.visible,
                          softWrap: false,
                          minFontSize: Constants.small),
                      onTap: () async => await showDialog(
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

class ViewRoute {
  final String name;
  final NavigationDrawerDestination? destination;
  final Widget view;

  const ViewRoute({required this.name, this.destination, required this.view});
}
