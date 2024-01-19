import 'dart:io';
import 'dart:math';
import 'dart:ui';

import "package:auto_route/auto_route.dart";
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/foundation.dart';
import "package:flutter/material.dart";
import 'package:macos_window_utils/widgets/transparent_macos_sidebar.dart';
import "package:provider/provider.dart";

import '../../../model/task/group.dart';
import '../../../providers/application/layout_provider.dart';
import '../../../providers/application/search_provider.dart';
import '../../../providers/application/theme_provider.dart';
import '../../../providers/model/deadline_provider.dart';
import '../../../providers/model/group_provider.dart';
import '../../../providers/model/reminder_provider.dart';
import '../../../providers/model/routine_provider.dart';
import '../../../providers/model/todo_provider.dart';
import '../../../providers/model/user_provider.dart';
import '../../../services/supabase_service.dart';
import '../../../util/constants.dart';
import '../../../util/enums.dart';
import '../../../util/interfaces/i_model.dart';
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

// TODO: clean up setState -> listen to layoutProvider.
// TODO: read UserModel.reduceMotion and set tween duration.
class _HomeScreen extends State<HomeScreen> {
  // late int _selectedPageIndex;

  late final ToDoProvider toDoProvider;
  late final RoutineProvider routineProvider;
  late final ReminderProvider reminderProvider;
  late final DeadlineProvider deadlineProvider;
  late final UserProvider userProvider;
  late final GroupProvider groupProvider;
  late final ThemeProvider themeProvider;
  late final SearchProvider searchProvider;
  late final LayoutProvider layoutProvider;

  late final ScrollController navScrollController;

  late final ScrollPhysics scrollPhysics;

  // NavigationDrawer stuff
  late bool _opened;
  late bool _navDrawerExpanded;
  late bool _footerTween;
  late double _navDrawerWidth;
  late bool _dragging;

  // This is a hacky, hacky way of creating a footer.
  // ie. number of tiles + user tile + room for 1 extra tile *
  // approx tile height in lp.
  double get footerOffset => max(userProvider.size.height - tileSpace, 0);

  double get footerOffsetOpened =>
      max(userProvider.size.height - tileSpaceOpened, 0);

  double get tileSpace =>
      (Constants.viewRoutes.length + 2) * Constants.navDestinationHeight +
      2.5 * Constants.doublePadding;

  double get tileSpaceOpened =>
      (Constants.viewRoutes.length +
              2 +
              groupProvider.secondaryGroups.length +
              2) *
          Constants.navDestinationHeight +
      3 * Constants.padding;

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
    searchProvider = Provider.of<SearchProvider>(context, listen: false);

    layoutProvider = Provider.of<LayoutProvider>(context, listen: false);
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
    // _selectedPageIndex = widget.index ?? 0;
    layoutProvider.initPageIndex = widget.index ?? 0;
    _navDrawerWidth = Constants.navigationDrawerMaxWidth;
    _opened = userProvider.drawerOpened;
    _dragging = false;
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

    if (!(userProvider.curUser?.reduceMotion ?? false)) {
      for (Group group in groupProvider.secondaryGroups) {
        group.fade = Fade.fadeIn;
      }
    }

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
    layoutProvider.size = MediaQuery.sizeOf(context);
    print("MQ: ${userProvider.size}");

    return (layoutProvider.largeScreen)
        ? buildDesktop(context: context)
        : buildMobile(context: context);
  }

  Widget buildDesktop({required BuildContext context}) {
    return Row(children: [
      // This is a workaround for a standard navigation drawer
      // until m3 spec is fully implemented in flutter.
      TweenAnimationBuilder<double>(
          duration: Duration(
              milliseconds: (_dragging) ? 0 : Constants.drawerSlideTime),
          curve: Curves.easeOutQuint,
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
                    elevation: value.sidebarElevation,
                    drawer: buildNavigationDrawer(
                        context: context, largeScreen: true),
                  );
                }),
              ),
            ));
          }),
      GestureDetector(
        behavior: HitTestBehavior.translucent,
        supportedDevices: PointerDeviceKind.values.toSet(),
        onHorizontalDragEnd: (DragEndDetails details) {
          _dragging = false;
          if ((0 - _navDrawerWidth).abs() <= precisionErrorTolerance) {
            _opened = false;
            userProvider.drawerOpened = _opened;
            // _navDrawerWidth = Constants.navigationDrawerMaxWidth;
            userProvider.navDrawerWidth = _navDrawerWidth;
            if (mounted) {
              setState(() {});
            }
          }
        },
        onHorizontalDragUpdate: (DragUpdateDetails details) {
          if (!_opened) {
            _opened = !_opened;
            userProvider.drawerOpened = _opened;
          }
          _dragging = true;
          _navDrawerWidth = (_navDrawerWidth + details.delta.dx)
              .clamp(0, Constants.navigationDrawerMaxWidth);
          userProvider.navDrawerWidth = _navDrawerWidth;
          if (mounted) {
            setState(() {});
          }
        },
        child: TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: Constants.drawerSlideTime),
            curve: Curves.easeInQuint,
            tween: Tween<double>(
              begin: _opened ? 1 : 0.0,
              end: _opened ? 1 : 0.0,
            ),
            builder: (BuildContext context, double value, Widget? child) {
              return Material(
                child: Ink(
                  color: Color.lerp(Theme.of(context).colorScheme.surface,
                      Theme.of(context).colorScheme.outlineVariant, value),
                  child: InkWell(
                    mouseCursor: SystemMouseCursors.resizeLeftRight,
                    onHover: (value) {},
                    onTapUp: (TapUpDetails details) {
                      if (!_opened) {
                        _navDrawerWidth = Constants.navigationDrawerMaxWidth;
                        userProvider.navDrawerWidth = _navDrawerWidth;
                      } else {
                        _navDrawerWidth = 0;
                        userProvider.navDrawerWidth = _navDrawerWidth;
                      }
                      _opened = !_opened;
                      userProvider.drawerOpened = _opened;
                      if (mounted) {
                        setState(() {});
                      }
                    },
                    child: VerticalDivider(
                      width: lerpDouble(Constants.verticalDividerThickness * 3,
                          Constants.verticalDividerThickness, value),
                      thickness: lerpDouble(
                          Constants.verticalDividerThickness * 3,
                          Constants.verticalDividerThickness,
                          value),
                      color: Colors.transparent,
                    ),
                  ),
                ),
              );
            }),
      ),

      Expanded(
        child: Selector<ThemeProvider, double>(
          selector: (BuildContext context, ThemeProvider tp) =>
              tp.scaffoldOpacity,
          builder: (BuildContext context, double opacity, Widget? child) {
            return Selector<LayoutProvider, int>(
                selector: (BuildContext context, LayoutProvider lp) =>
                    lp.selectedPageIndex,
                builder: (BuildContext context, int index, Widget? child) {
                  return Scaffold(
                      backgroundColor: Theme.of(context)
                          .scaffoldBackgroundColor
                          .withOpacity(opacity),
                      appBar: buildAppBar(mobile: false),
                      body: SafeArea(child: Constants.viewRoutes[index].view));
                });
          },
        ),
      )
    ]);
  }

  Widget buildMobile({required BuildContext context}) {
    return Selector<ThemeProvider, double>(
      selector: (BuildContext context, ThemeProvider tp) => tp.scaffoldOpacity,
      builder: (BuildContext context, double opacity, Widget? child) {
        return Selector<LayoutProvider, int>(
            selector: (BuildContext context, LayoutProvider lp) =>
                lp.selectedPageIndex,
            builder: (BuildContext context, int index, Widget? child) {
              return Scaffold(
                  backgroundColor: Theme.of(context)
                      .scaffoldBackgroundColor
                      .withOpacity(opacity),
                  appBar: buildAppBar(mobile: true),
                  body: SafeArea(child: Constants.viewRoutes[index].view));
            });
      },
    );
    // return Consumer<ThemeProvider>(
    //   builder: (BuildContext context, ThemeProvider value, Widget? child) {
    //     return Scaffold(
    //         backgroundColor: Theme.of(context)
    //             .scaffoldBackgroundColor
    //             .withOpacity(value.scaffoldOpacity),
    //         appBar: buildAppBar(mobile: true),
    //         drawer: buildNavigationDrawer(context: context, largeScreen: false),
    //         body: SafeArea(
    //             child: Constants
    //                 .viewRoutes[layoutProvider.selectedPageIndex].view));
    //   },
    // );
  }

  AppBar buildAppBar({bool mobile = false}) {
    return AppBar(
      backgroundColor: Colors.transparent,
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
          onPressed: () {
            _opened = false;
            userProvider.drawerOpened = _opened;
            _navDrawerWidth = 1.0;
            userProvider.navDrawerWidth = _navDrawerWidth;
            if (mounted) {
              setState(() {});
            }
          });
    }
    return IconButton(
        icon: const Icon(Icons.menu_rounded),
        onPressed: () {
          if (mounted) {
            setState(() {
              _opened = true;
              userProvider.drawerOpened = _opened;
              _navDrawerWidth = Constants.navigationDrawerMaxWidth;
              userProvider.navDrawerWidth = _navDrawerWidth;
            });
          }
        });
  }

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
          layoutProvider.selectedPageIndex = index;

          if (!largeScreen) {
            Navigator.pop(context);
          }

          resetProviders();
        },
        selectedIndex: layoutProvider.selectedPageIndex,
        children: [
          // User name bar
          // Possible stretch Goal: add user images?
          Padding(
            padding: const EdgeInsets.only(
              top: Constants.doublePadding,
              bottom: Constants.padding,
              right: Constants.padding,
              left: Constants.padding,
            ),
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
                  // TODO: come up with a clever way to avoid looping.
                  layoutProvider.selectedPageIndex =
                      Constants.viewRoutes.indexOf(Constants.settingsScreen);
                });
                if (!largeScreen) {
                  Navigator.pop(context);
                }
              },
              trailing: GlobalModelSearch(
                mostRecent: () async {
                  List<List<IModel>> models = await Future.wait([
                    toDoProvider.mostRecent(),
                    routineProvider.mostRecent(),
                    reminderProvider.mostRecent(),
                    deadlineProvider.mostRecent(),
                    groupProvider.mostRecent(),
                  ]);

                  return searchProvider.batchProcess(models: models.cast());
                },
                search: ({required String searchString}) async {
                  List<List<IModel>> models = await Future.wait([
                    toDoProvider.searchToDos(searchString: searchString),
                    routineProvider.searchRoutines(searchString: searchString),
                    reminderProvider.searchReminders(
                        searchString: searchString),
                    deadlineProvider.searchDeadlines(
                        searchString: searchString),
                    groupProvider.searchGroups(searchString: searchString),
                  ]);

                  return searchProvider.batchProcess(
                      models: models.cast(), searchString: searchString);
                },
              ),
            ),
          ),
          const PaddedDivider(padding: Constants.doublePadding),

          ...Constants.viewRoutes
              .where((view) => view.inMainNav)
              .map((view) => view.destination),
          const PaddedDivider(padding: Constants.doublePadding),
          // Drop down menu for Groups.
          ExpandedListTile(
              outerPadding:
                  const EdgeInsets.symmetric(horizontal: Constants.padding),
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
                        horizontal: Constants.doublePadding),
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
                      layoutProvider.selectedPageIndex =
                          Constants.viewRoutes.length - 1;
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
                  groups: groupProvider.secondaryGroups,
                ),
                // refactor listview
              ]),
          const PaddedDivider(padding: Constants.doublePadding),
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
          const Padding(
              padding: EdgeInsets.symmetric(
                vertical: Constants.padding,
              ),
              child: SizedBox.shrink()),
        ]);
  }
}
