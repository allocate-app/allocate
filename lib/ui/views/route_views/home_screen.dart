import 'dart:io';
import 'dart:math';
import 'dart:ui';

import "package:auto_route/auto_route.dart";
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/foundation.dart';
import "package:flutter/material.dart";
import 'package:macos_window_utils/widgets/transparent_macos_sidebar.dart';
import "package:provider/provider.dart";

import '../../../providers/deadline_provider.dart';
import '../../../providers/group_provider.dart';
import '../../../providers/reminder_provider.dart';
import '../../../providers/routine_provider.dart';
import '../../../providers/theme_provider.dart';
import '../../../providers/todo_provider.dart';
import '../../../providers/user_provider.dart';
import '../../../services/supabase_service.dart';
import '../../../util/constants.dart';
import '../../../util/interfaces/i_model.dart';
import '../../../util/strings.dart';
import '../../widgets/battery_meter.dart';
import '../../widgets/desktop_drawer_wrapper.dart';
import '../../widgets/expanded_listtile.dart';
import '../../widgets/global_model_search.dart';
import '../../widgets/listviews.dart';
import '../../widgets/padded_divider.dart';
import '../../widgets/tiles.dart';
import '../sub_views/create_group.dart';

@RoutePage()
class HomeScreen extends StatefulWidget {
  final int? index;

  const HomeScreen({super.key, this.index});

  @override
  State<HomeScreen> createState() => _HomeScreen();
}

// TODO: remove all the setstate and just use consumer
class _HomeScreen extends State<HomeScreen> {
  late int selectedPageIndex;

  late final ToDoProvider toDoProvider;
  late final RoutineProvider routineProvider;
  late final ReminderProvider reminderProvider;
  late final DeadlineProvider deadlineProvider;
  late final UserProvider userProvider;
  late final GroupProvider groupProvider;
  late final ThemeProvider themeProvider;

  late final ScrollController navScrollController;

  late final ScrollPhysics scrollPhysics;

  // NavigationDrawer stuff
  late bool _opened;
  late bool _navDrawerExpanded;
  late bool _footerTween;
  late double _navDrawerWidth;

  // This is a hacky, hacky way of creating a footer.
  // ie. number of tiles + user tile + room for 1 extra tile *
  // approx tile height in lp.
  double get footerOffset => max(userProvider.size.height - tileSpace, 0);

  double get footerOffsetOpened =>
      max(userProvider.size.height - tileSpaceOpened, 0);

  double get tileSpace =>
      (Constants.viewRoutes.length + 2) * Constants.navDestinationHeight +
      2 * Constants.innerPadding;

  double get tileSpaceOpened =>
      (Constants.viewRoutes.length +
              2 +
              groupProvider.secondaryGroups.length +
              2) *
          Constants.navDestinationHeight +
      2 * Constants.padding;

  // I haven't fully thought this through yet. => Also, should probably just BE a double
  // + userProvider.curUser?.dayCost;
  int get myDayTotal =>
      userProvider.myDayTotal +
      routineProvider.routineWeight +
      (userProvider.curUser?.dayCost ?? 0);

  @override
  void initState() {
    super.initState();
    initializeProviders();
    initializeParams();
    initializeControllers();
    updateMyDayWeight();
    resetNavGroups();
  }

  void initializeProviders() {
    toDoProvider = Provider.of<ToDoProvider>(context, listen: false);
    routineProvider = Provider.of<RoutineProvider>(context, listen: false);
    reminderProvider = Provider.of<ReminderProvider>(context, listen: false);
    deadlineProvider = Provider.of<DeadlineProvider>(context, listen: false);
    userProvider = Provider.of<UserProvider>(context, listen: false);
    groupProvider = Provider.of<GroupProvider>(context, listen: false);
    themeProvider = Provider.of<ThemeProvider>(context, listen: false);

    toDoProvider.addListener(updateMyDayWeight);
    groupProvider.addListener(resetNavGroups);
  }

  void resetProviders() {
    toDoProvider.softRebuild = true;
    routineProvider.softRebuild = true;
    deadlineProvider.softRebuild = true;
    reminderProvider.softRebuild = true;
    groupProvider.softRebuild = true;
  }

  void initializeParams() {
    selectedPageIndex = widget.index ?? 0;
    _navDrawerWidth = Constants.navigationDrawerMaxWidth;
    _opened = userProvider.drawerOpened;
    _navDrawerExpanded = false;
    _footerTween = false;
  }

  void initializeControllers() {
    navScrollController = ScrollController();

    ScrollPhysics parentPhysics = (Platform.isIOS || Platform.isMacOS)
        ? const BouncingScrollPhysics()
        : const ClampingScrollPhysics();

    scrollPhysics = AlwaysScrollableScrollPhysics(parent: parentPhysics);
  }

  Future<void> resetNavGroups() async {
    groupProvider.secondaryGroups = await groupProvider.mostRecent();
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    navScrollController.dispose();
    toDoProvider.removeListener(updateMyDayWeight);
    groupProvider.removeListener(resetNavGroups);
    super.dispose();
  }

  Future<void> updateMyDayWeight() async {
    userProvider.myDayTotal = await toDoProvider.getMyDayWeight();
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    userProvider.size = MediaQuery.sizeOf(context);
    print("MQ: ${userProvider.size}");

    return (userProvider.largeScreen)
        ? buildDesktop(context: context)
        : buildMobile(context: context);
  }

  Widget buildDesktop({required BuildContext context}) {
    return Row(children: [
      // This is a workaround for a standard navigation drawer
      // until m3 spec is fully implemented in flutter.
      TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 1000),
          curve: Curves.fastLinearToSlowEaseIn,
          tween: Tween<double>(
            begin: _opened ? _navDrawerWidth : 0.0,
            end: _opened ? _navDrawerWidth : 0.0,
          ),
          builder: (BuildContext context, double value, Widget? child) {
            return TransparentMacOSSidebar(
                child: Container(
              width: value,
              clipBehavior: Clip.hardEdge,
              decoration: const BoxDecoration(),
              child: OverflowBox(
                minWidth: Constants.navigationDrawerMaxWidth,
                maxWidth: Constants.navigationDrawerMaxWidth,
                child: Consumer<ThemeProvider>(builder:
                    (BuildContext context, ThemeProvider value, Widget? child) {
                  return DesktopDrawerWrapper(
                    drawer: buildNavigationDrawer(
                        context: context, largeScreen: true),
                  );
                }),
              ),
            ));
          }),
      // Possibly only render this on open.
      if (_opened)
        MouseRegion(
          hitTestBehavior: HitTestBehavior.translucent,
          cursor: SystemMouseCursors.resizeLeftRight,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            supportedDevices: PointerDeviceKind.values.toSet(),
            onHorizontalDragEnd: (DragEndDetails details) {
              if ((0 - _navDrawerWidth).abs() <= precisionErrorTolerance) {
                _opened = false;
                userProvider.drawerOpened = _opened;
                _navDrawerWidth = Constants.navigationDrawerMaxWidth;
                userProvider.navDrawerWidth = _navDrawerWidth;
                if (mounted) {
                  setState(() {});
                }
              }
            },
            onHorizontalDragUpdate: (DragUpdateDetails details) {
              if (mounted) {
                setState(() {
                  _navDrawerWidth = (_navDrawerWidth + details.delta.dx)
                      .clamp(0, Constants.navigationDrawerMaxWidth);
                  userProvider.navDrawerWidth = _navDrawerWidth;
                });
              }
            },
            // TODO: remove row. Too jittery.
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // VerticalDivider(
                //   color: Theme.of(context)
                //       .colorScheme
                //       .surface
                //       .withOpacity(sidebarOpacity),
                //   thickness: Constants.verticalDividerThickness,
                //   width: Constants.verticalDividerThickness,
                // ),
                VerticalDivider(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  thickness: Constants.verticalDividerThickness,
                  width: Constants.verticalDividerThickness,
                ),
                // VerticalDivider(
                //   color: Theme.of(context)
                //       .scaffoldBackgroundColor
                //       .withOpacity(scaffoldOpacity),
                //   thickness: Constants.verticalDividerThickness,
                //   width: Constants.verticalDividerThickness,
                // )
              ],
            ),
          ),
        ),

      Expanded(
        child: Consumer<ThemeProvider>(
          builder: (BuildContext context, ThemeProvider value, Widget? child) {
            return Scaffold(
                backgroundColor: Theme.of(context)
                    .scaffoldBackgroundColor
                    .withOpacity(themeProvider.scaffoldOpacity),
                appBar: buildAppBar(mobile: false),
                body: SafeArea(
                    child: Constants.viewRoutes[selectedPageIndex].view));
          },
        ),
      )
    ]);
  }

  Widget buildMobile({required BuildContext context}) {
    return Scaffold(
        backgroundColor: Theme.of(context)
            .scaffoldBackgroundColor
            .withOpacity(themeProvider.scaffoldOpacity),
        appBar: buildAppBar(mobile: true),
        drawer: buildNavigationDrawer(context: context, largeScreen: false),
        body: SafeArea(child: Constants.viewRoutes[selectedPageIndex].view));
  }

  AppBar buildAppBar({bool mobile = false}) {
    return AppBar(
      // elevation: 1.0,
      leading: getAppBarLeading(mobile: mobile),
      automaticallyImplyLeading: false,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        mainAxisSize: MainAxisSize.min,
        children: [
          const AutoSizeText(
            "Allocate:",
            style: Constants.largeHeaderStyle,
            minFontSize: Constants.huge,
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.visible,
          ),
          Tooltip(
            message: "Remaining energy for tasks",
            child: BatteryMeter(
                showDifference: true,
                scale: .65,
                weight: myDayTotal.toDouble(),
                max: userProvider.curUser?.bandwidth.toDouble() ??
                    Constants.maxBandwidthDouble,
                constraints: const BoxConstraints(maxWidth: 120)),
          ),
        ],
      ),
      centerTitle: true,
      scrolledUnderElevation: 0,
    );
  }

  Widget getAppBarLeading({bool mobile = false}) {
    if (mobile) {
      return Builder(builder: (BuildContext context) {
        return IconButton(
            icon: const Icon(Icons.menu_rounded),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            });
      });
    }

    if (_opened) {
      return IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () async {
            if (mounted) {
              setState(() {
                _opened = false;
                userProvider.drawerOpened = _opened;
              });
            }
          });
    }
    return IconButton(
        icon: const Icon(Icons.menu_rounded),
        onPressed: () async {
          if (mounted) {
            setState(() {
              _opened = true;
              userProvider.drawerOpened = _opened;
            });
          }
        });
  }

  // TODO: include index -within- the constants class
  NavigationDrawer buildNavigationDrawer(
      {required BuildContext context, bool largeScreen = false}) {
    return NavigationDrawer(
        backgroundColor: (largeScreen)
            ? Theme.of(context)
                .colorScheme
                .surface
                .withOpacity(themeProvider.sidebarOpacity)
            : null,
        onDestinationSelected: (index) {
          setState(() {
            selectedPageIndex = index;
          });

          if (!largeScreen) {
            Navigator.pop(context);
          }

          resetProviders();
        },
        selectedIndex: selectedPageIndex,
        children: [
          // User name bar
          // Possible stretch Goal: add user images?
          Padding(
            padding: const EdgeInsets.symmetric(
                vertical: Constants.innerPadding,
                horizontal: Constants.padding),
            child: ListTile(
              shape: const RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.all(Radius.circular(Constants.circular))),
              leading: CircleAvatar(
                  radius: Constants.circleAvatarRadius,
                  child: Text(
                      "${userProvider.curUser?.username[0].toUpperCase()}")),
              // Possible TODO: Refactor this to take a first/last name?
              title: Text("${userProvider.curUser?.username}"),
              // Possible TODO: Refactor this to use an enum.
              subtitle: (null !=
                      SupabaseService
                          .instance.supabaseClient.auth.currentSession)
                  ? const Text("Online")
                  : const Text("Offline"),
              onTap: () {
                setState(() {
                  resetProviders();
                  selectedPageIndex =
                      Constants.viewRoutes.indexOf(Constants.settingsScreen);
                });
                if (!largeScreen) {
                  Navigator.pop(context);
                }
              },
              trailing: GlobalModelSearch(
                mostRecent: () async {
                  List<IModel> modelCollection = [];
                  await Future.wait([
                    toDoProvider.mostRecent(),
                    routineProvider.mostRecent(),
                    reminderProvider.mostRecent(),
                    deadlineProvider.mostRecent(),
                    groupProvider.mostRecent(),
                  ]).then((model) {
                    for (List<IModel> list in model.cast<List<IModel>>()) {
                      modelCollection.addAll(list);
                    }
                  });

                  return modelCollection;
                },
                search: ({required String searchString}) async {
                  List<IModel> modelCollection = [];
                  await Future.wait([
                    toDoProvider.searchToDos(searchString: searchString),
                    routineProvider.searchRoutines(searchString: searchString),
                    reminderProvider.searchReminders(
                        searchString: searchString),
                    deadlineProvider.searchDeadlines(
                        searchString: searchString),
                    groupProvider.searchGroups(searchString: searchString),
                  ]).then((model) {
                    for (List<IModel> list in model.cast<List<IModel>>()) {
                      modelCollection.addAll(list);
                    }
                  });

                  return modelCollection
                    ..sort((m1, m2) =>
                        levenshteinDistance(s1: m1.name, s2: searchString)
                            .compareTo(levenshteinDistance(
                                s1: m2.name, s2: searchString)));
                  // For now, going with string distance.
                  // ..sort((m1, m2) {
                  //   if (m1.lastUpdated.isBefore(m2.lastUpdated)) {
                  //     return -1;
                  //   } else if (m1.lastUpdated.isAfter(m2.lastUpdated)) {
                  //     return 1;
                  //   }
                  //   return 0;
                  // });
                },
              ),
            ),
          ),
          const PaddedDivider(padding: Constants.innerPadding),

          ...Constants.viewRoutes
              .where((view) => view.inMainNav)
              .map((view) => view.destination),
          const PaddedDivider(padding: Constants.innerPadding),
          // Drop down menu for Groups.
          ExpandedListTile(
              title: const AutoSizeText(
                "Groups",
                maxLines: 1,
                overflow: TextOverflow.visible,
                softWrap: false,
                maxFontSize: Constants.xtraLarge,
                minFontSize: Constants.large,
              ),
              border: BorderSide.none,
              leading: const Icon(Icons.table_view_rounded),
              initiallyExpanded: _navDrawerExpanded,
              onExpansionChanged: ({bool expanded = false}) {
                Future.delayed(
                    const Duration(milliseconds: Constants.footerDelay), () {
                  if (mounted) {
                    setState(() => _navDrawerExpanded = expanded);
                    _footerTween = true;
                  }
                });
              },
              children: [
                ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: Constants.innerPadding),
                    shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(
                            Radius.circular(Constants.semiCircular))),
                    leading: const Icon(Icons.workspaces_outlined),
                    title: const AutoSizeText(
                      "All Groups",
                      maxLines: 1,
                      overflow: TextOverflow.visible,
                      softWrap: false,
                      maxFontSize: Constants.xtraLarge,
                      minFontSize: Constants.large,
                    ),
                    onTap: () {
                      groupProvider.softRebuild = true;
                      selectedPageIndex = Constants.viewRoutes.length - 1;
                      // Constants.viewRoutes.indexOf(Constants.groupScreen);
                      if (mounted) {
                        setState(() {});
                      }
                      if (!largeScreen) {
                        Navigator.pop(context);
                      }
                    }),
                Tiles.addTile(
                    title: "Add New",
                    onTap: () async {
                      await showDialog(
                          barrierDismissible: false,
                          useRootNavigator: false,
                          context: context,
                          builder: (BuildContext context) =>
                              const CreateGroupScreen());
                    }),
                ListViews.navDrawerGroups(
                  context: context,
                  groups: groupProvider.secondaryGroups,
                  // TODO: tweak
                  outerPadding:
                      const EdgeInsets.symmetric(horizontal: Constants.padding),
                  innerPadding:
                      const EdgeInsets.symmetric(horizontal: Constants.padding),
                ),
                // refactor listview
              ]),
          const PaddedDivider(padding: Constants.innerPadding),
          (_footerTween)
              ? TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: Constants.footerTime),
                  curve: Curves.fastOutSlowIn,
                  onEnd: () {
                    if (mounted) {
                      setState(() => _footerTween = false);
                    }
                  },
                  tween: Tween<double>(
                    begin:
                        _navDrawerExpanded ? footerOffset : footerOffsetOpened,
                    end: _navDrawerExpanded ? footerOffsetOpened : footerOffset,
                  ),
                  builder: (BuildContext context, double value, Widget? child) {
                    return Padding(
                      padding: EdgeInsets.only(bottom: value),
                      child: const SizedBox.shrink(),
                    );
                  })
              : Padding(
                  padding: EdgeInsets.only(
                      bottom: (_navDrawerExpanded)
                          ? footerOffsetOpened
                          : footerOffset),
                  child: const SizedBox.shrink()),
          Constants.settingsScreen.destination,
          Constants.trashScreen.destination,
        ]);
  }
}
