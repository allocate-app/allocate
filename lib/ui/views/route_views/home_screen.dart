import 'dart:async';
import 'dart:io';
import 'dart:ui';

import "package:auto_route/auto_route.dart";
import 'package:auto_size_text/auto_size_text.dart';
import "package:flutter/material.dart";
import 'package:flutter/rendering.dart';
import 'package:flutter_acrylic/widgets/titlebar_safe_area.dart';
import 'package:flutter_acrylic/widgets/transparent_macos_sidebar.dart';
import 'package:flutter_expandable_fab/flutter_expandable_fab.dart';
import "package:provider/provider.dart";
import 'package:window_manager/window_manager.dart';

import '../../../model/task/group.dart';
import '../../../providers/application/event_provider.dart';
import '../../../providers/application/layout_provider.dart';
import '../../../providers/application/search_provider.dart';
import '../../../providers/application/theme_provider.dart';
import '../../../providers/model/deadline_provider.dart';
import '../../../providers/model/group_provider.dart';
import '../../../providers/model/reminder_provider.dart';
import '../../../providers/model/routine_provider.dart';
import '../../../providers/model/subtask_provider.dart';
import '../../../providers/model/todo_provider.dart';
import '../../../providers/model/user_provider.dart';
import '../../../providers/viewmodels/user_viewmodel.dart';
import '../../../services/application_service.dart';
import '../../../services/daily_reset_service.dart';
import '../../../services/isar_service.dart';
import '../../../services/repeatable_service.dart';
import '../../../util/constants.dart';
import '../../../util/enums.dart';
import '../../../util/interfaces/i_model.dart';
import '../../blurred_dialog.dart';
import '../../widgets/battery_meter.dart';
import '../../widgets/desktop_drawer_wrapper.dart';
import '../../widgets/expanded_listtile.dart';
import '../../widgets/global_model_search.dart';
import '../../widgets/listviews.dart';
import '../../widgets/main_floating_action_button.dart';
import '../../widgets/padded_divider.dart';
import '../../widgets/tiles.dart';
import '../../widgets/windows_titlebar.dart';
import '../sub_views/create_group.dart';

@RoutePage()
class HomeScreen extends StatefulWidget {
  final int? index;

  const HomeScreen({super.key, this.index});

  @override
  State<HomeScreen> createState() => _HomeScreen();
}

class _HomeScreen extends State<HomeScreen> with WidgetsBindingObserver {
  final DailyResetService dailyResetProvider = DailyResetService.instance;
  late final ToDoProvider toDoProvider;
  late final RoutineProvider routineProvider;
  late final ReminderProvider reminderProvider;
  late final DeadlineProvider deadlineProvider;
  late final SubtaskProvider subtaskProvider;
  late final UserProvider userProvider;
  late final GroupProvider groupProvider;
  late final ThemeProvider themeProvider;
  late final SearchProvider searchProvider;
  late final LayoutProvider layoutProvider;
  late final EventProvider eventProvider;

  late final ApplicationService applicationService;

  late final ScrollController navScrollController;

  late final ScrollPhysics scrollPhysics;
  late final GlobalKey<ExpandableFabState> _fabKey;

  late Timer _refreshTimer;
  late bool _needsRefreshing;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    initializeProviders();
    initializeParams();
    initializeControllers();
    updateMyDay();
    resetNavGroups();
  }

  void initializeProviders() {
    toDoProvider = Provider.of<ToDoProvider>(context, listen: false);
    routineProvider = Provider.of<RoutineProvider>(context, listen: false);
    reminderProvider = Provider.of<ReminderProvider>(context, listen: false);
    deadlineProvider = Provider.of<DeadlineProvider>(context, listen: false);
    subtaskProvider = Provider.of<SubtaskProvider>(context, listen: false);
    userProvider = Provider.of<UserProvider>(context, listen: false);
    groupProvider = Provider.of<GroupProvider>(context, listen: false);
    themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    searchProvider = Provider.of<SearchProvider>(context, listen: false);

    eventProvider = Provider.of<EventProvider>(context, listen: false);
    layoutProvider = Provider.of<LayoutProvider>(context, listen: false);

    applicationService = ApplicationService.instance;
    applicationService.addListener(scrollToTop);

    toDoProvider.addListener(updateMyDay);
    routineProvider.addListener(updateMyDay);
    dailyResetProvider.addListener(dayReset);
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
    if (null != widget.index &&
        widget.index != layoutProvider.selectedPageIndex) {
      layoutProvider.initPageIndex = widget.index!;
    }

    _fabKey = GlobalKey<ExpandableFabState>();

    _needsRefreshing = false;

    // Reset the initial index in ApplicationService ->
    // This route is only pushed on an application launch, relaunch,
    // Or a deeplink routing.
    applicationService.initialPageIndex = null;

    // Currently this is on a 30s timer.
    // This is done to prevent repeated refreshing on app resume.
    _refreshTimer =
        Timer.periodic(Constants.updateTimer, (_) => _needsRefreshing = true);
  }

  void initializeControllers() {
    navScrollController = ScrollController();

    ScrollPhysics parentPhysics = (Platform.isIOS || Platform.isMacOS)
        ? const BouncingScrollPhysics()
        : const ClampingScrollPhysics();

    scrollPhysics = AlwaysScrollableScrollPhysics(parent: parentPhysics);

    // Stream for watching Isar Db.
    IsarService.instance.dbSize.addListener(alertSizeLimit);
  }

  void scrollToTop() {
    if (navScrollController.hasClients) {
      navScrollController.animateTo(
        0,
        duration: Constants.scrollDuration,
        curve: Constants.scrollCurve,
      );
    }
  }

  void updateMyDay() {
    int newMyDayTotal =
        toDoProvider.myDayWeight + routineProvider.routineWeight;

    // This is to avoid rebuilds.
    if (newMyDayTotal != userProvider.myDayTotal.value) {
      userProvider.myDayTotal.value = newMyDayTotal;
    }
  }

  // TODO: Refactor this; needs to be a unique key or it will not repaint.
  Future<void> resetNavGroups() async {
    List<Group> newGroups = await groupProvider.mostRecent();

    // This needs a set & comparison.
    if (!(userProvider.viewModel?.reduceMotion ?? false)) {
      Set<Group> itemSet = groupProvider.secondaryGroups.toSet();
      for (Group group in newGroups) {
        if (!itemSet.contains(group)) {
          group.fade = Fade.fadeIn;
        }
      }
    }

    groupProvider.secondaryGroups = newGroups;
    // for offset width on nav drawer expansion.
    layoutProvider.navGroupsLength = groupProvider.secondaryGroups.length;

    if (groupProvider.secondaryGroups.isEmpty) {
      return;
    }

    int newKey = groupProvider.secondaryGroups[0].id;
    if (newKey != groupProvider.navKey.value) {
      groupProvider.navKey.value = newKey;
    }
  }

  Future<void> dayReset() async {
    await Future.wait([
      userProvider.dayReset(),
      toDoProvider.dayReset(),
      routineProvider.dayReset(),
      deadlineProvider.dayReset(),
      reminderProvider.dayReset(),
      groupProvider.dayReset(),
      subtaskProvider.dayReset(),
    ]).catchError(
      (e) async {
        await Tiles.displayError(e: e);
        return [];
      },
    );

    await RepeatableService.instance.generateNextRepeats();
  }

  // This will crash the app on an unhandled postgres exception.
  Future<void> refreshRepo() async {
    if (!userProvider.isConnected.value) {
      return;
    }

    await Future.wait([
      userProvider.syncUser(),
      toDoProvider.refreshRepo(),
      routineProvider.refreshRepo(),
      deadlineProvider.refreshRepo(),
      reminderProvider.refreshRepo(),
      groupProvider.refreshRepo(),
      subtaskProvider.refreshRepo(),
    ]).catchError((e) async {
      await Tiles.displayError(e: e);
      return [];
    }).then((_) async {
      // Give enough time for all of the data to be fetched.
      await Future.delayed(const Duration(seconds: 1));

      _needsRefreshing = false;
      await eventProvider.resetCalendar();
    });
  }

  Future<void> syncRepo() async {
    if (!userProvider.isConnected.value) {
      return;
    }
    await Future.wait([
      userProvider.syncUser(),
      toDoProvider.syncRepo(),
      routineProvider.syncRepo(),
      deadlineProvider.syncRepo(),
      reminderProvider.syncRepo(),
      groupProvider.syncRepo(),
      subtaskProvider.syncRepo(),
    ]).catchError((e) async {
      await Tiles.displayError(e: e);
      return [];
    }).then((_) async {
      // Give enough time for all of the data to be fetched.
      // This may need increasing depending on the online bottleneck.
      await Future.delayed(const Duration(seconds: 1));
      await eventProvider.resetCalendar();
    });
  }

  @override
  void dispose() {
    toDoProvider.removeListener(updateMyDay);
    routineProvider.removeListener(updateMyDay);
    dailyResetProvider.removeListener(dayReset);
    groupProvider.removeListener(resetNavGroups);
    applicationService.removeListener(scrollToTop);
    navScrollController.dispose();
    _refreshTimer.cancel();
    IsarService.instance.dbSize.removeListener(alertSizeLimit);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (AppLifecycleState.resumed == state) {
      if (_needsRefreshing) {
        await refreshRepo();
      } else {
        await syncRepo();
      }

      // This is to cover when cron isn't running in the bg.
      // Probably okay to just like, sync stuff.
      userProvider.checkDay();

      if (userProvider.viewModel?.syncOnline ?? false) {
        userProvider.updateConnectionStatus();
      }
    }

    if (AppLifecycleState.hidden == state) {
      _needsRefreshing = true;
    }
  }

  void alertSizeLimit() {
    double dbSize = IsarService.instance.dbSize.value.toDouble();

    double onlineRatio = (dbSize / Constants.supabaseLimit.toDouble());
    double offlineRatio = (dbSize / Constants.isarLimit.toDouble());

    // If reaching the limit of the offline database, the online one has already been well-exceeded.
    if (offlineRatio >= Constants.alertThreshold) {
      ScaffoldMessenger.of(context).showMaterialBanner(
        MaterialBanner(
          padding: const EdgeInsets.all(Constants.halfPadding),
          content: Text("Offline storage at ${(offlineRatio * 100).round()}%"),
          leading: Icon(Icons.error_outline_rounded,
              color: Theme.of(context).colorScheme.error),
          actions: [
            TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
                },
                child: const Text("Dismiss")),
          ],
        ),
      );
      return;
    }

    if (onlineRatio >= Constants.alertThreshold) {
      ScaffoldMessenger.of(context).showMaterialBanner(
        MaterialBanner(
          padding: const EdgeInsets.all(Constants.halfPadding),
          content: Text("Online storage at ${(onlineRatio * 100).round()}%"),
          leading: Icon(Icons.error_outline_rounded,
              color: Theme.of(context).colorScheme.error),
          actions: [
            TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
                },
                child: const Text("Dismiss")),
          ],
        ),
      );
    }
  }

  void handlePop(bool didPop) {
    // Open the navigation drawer if mobile.
    if (layoutProvider.smallScreen) {
      Scaffold.of(context).openDrawer();
    }
    // Otherwise, assume the swipe is to open the nav drawer.
    layoutProvider.navDrawerWidth = Constants.navigationDrawerMaxWidth;
    layoutProvider.drawerOpened = true;
  }

  void handleDragEnd(DragEndDetails details) {
    layoutProvider.dragging = false;
    if ((0 - layoutProvider.navDrawerWidth).abs() <=
        ((layoutProvider.isMobile)
            ? Constants.navigationDrawerMinThreshold
            : Constants.navigationDrawerCloseThreshold)) {
      layoutProvider.navDrawerWidth = 0;
      layoutProvider.drawerOpened = false;
    }
  }

  void handleDragUpdate(DragUpdateDetails details) {
    if (!layoutProvider.drawerOpened) {
      layoutProvider.drawerOpened = !layoutProvider.drawerOpened;
    }
    layoutProvider.dragging = true;
    layoutProvider.navDrawerWidth =
        (layoutProvider.navDrawerWidth + details.delta.dx)
            .clamp(0, Constants.navigationDrawerMaxWidth);
  }

  @override
  Widget build(BuildContext context) {
    layoutProvider.size = MediaQuery.sizeOf(context);
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Stack(children: [
        (Platform.isWindows)
            ? PopScope(
                canPop: false,
                onPopInvoked: handlePop,
                child: DragToResizeArea(
                  child: Consumer<LayoutProvider>(builder:
                      (BuildContext context, LayoutProvider value,
                          Widget? child) {
                    return (value.largeScreen)
                        ? _buildDesktop(context: context)
                        : _buildMobile(context: context);
                  }),
                ),
              )
            : PopScope(
                canPop: false,
                onPopInvoked: handlePop,
                child: Consumer<LayoutProvider>(builder: (BuildContext context,
                    LayoutProvider value, Widget? child) {
                  return (value.largeScreen)
                      ? _buildDesktop(context: context)
                      : _buildMobile(context: context);
                }),
              ),
        // Add to blurredDismissible.
        if (layoutProvider.isMobile)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).padding.top,
            child: GestureDetector(
                onTap: applicationService.scrollToTop,
                excludeFromSemantics: true,
                behavior: HitTestBehavior.translucent),
          ),
      ]),
    );
  }

  Widget _buildDesktop({required BuildContext context}) {
    return Stack(
      children: [
        Row(children: [
          // This is a workaround for a standard navigation drawer
          // until m3 spec is fully implemented in flutter.
          // Slideable for touchscreens
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            supportedDevices: const {PointerDeviceKind.touch},
            onHorizontalDragEnd: handleDragEnd,
            onHorizontalDragUpdate: handleDragUpdate,
            child: TitlebarSafeArea(
              child: TweenAnimationBuilder<double>(
                  duration: Duration(
                      milliseconds: (layoutProvider.dragging)
                          ? 0
                          : Constants.drawerSlideTime),
                  curve: Curves.easeOutQuint,
                  tween: Tween<double>(
                    begin: layoutProvider.drawerOpened
                        ? layoutProvider.navDrawerWidth
                        : 0.0,
                    end: layoutProvider.drawerOpened
                        ? layoutProvider.navDrawerWidth
                        : 0.0,
                  ),
                  builder: (BuildContext context, double value, Widget? child) {
                    //TransparentMacOSSidebar
                    return TransparentMacOSSidebar(
                      child: Container(
                        width: value,
                        clipBehavior: Clip.hardEdge,
                        decoration: const BoxDecoration(),
                        child: OverflowBox(
                          minWidth: Constants.navigationDrawerMaxWidth,
                          maxWidth: Constants.navigationDrawerMaxWidth,
                          child: Consumer<ThemeProvider>(builder:
                              (BuildContext context, ThemeProvider value,
                                  Widget? child) {
                            return DesktopDrawerWrapper(
                              elevation: value.sidebarElevation,
                              drawer: buildNavigationDrawer(
                                  context: context, largeScreen: true),
                            );
                          }),
                        ),
                      ),
                    );
                  }),
            ),
          ),
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            supportedDevices: PointerDeviceKind.values.toSet(),
            onHorizontalDragEnd: handleDragEnd,
            onHorizontalDragUpdate: handleDragUpdate,
            child: TweenAnimationBuilder<double>(
                duration:
                    const Duration(milliseconds: Constants.drawerSlideTime),
                curve: Curves.easeInQuint,
                tween: Tween<double>(
                  begin: layoutProvider.drawerOpened ? 1 : 0.0,
                  end: layoutProvider.drawerOpened ? 1 : 0.0,
                ),
                builder: (BuildContext context, double value, Widget? child) {
                  return TransparentMacOSSidebar(
                    effect: themeProvider.getWindowEffect(
                        effect: themeProvider.windowEffect),
                    child: Material(
                      color: Colors.transparent,
                      shadowColor: Colors.transparent,
                      child: Ink(
                        color: (Platform.isWindows || Platform.isMacOS)
                            ? Colors.transparent
                            : Color.lerp(
                                Theme.of(context).colorScheme.surface,
                                Theme.of(context).colorScheme.outlineVariant,
                                value),
                        child: InkWell(
                          mouseCursor: (Platform.isMacOS)
                              ? SystemMouseCursors.resizeLeftRight
                              : SystemMouseCursors.resizeUpRightDownLeft,
                          onHover: (value) {},
                          onTapUp: (TapUpDetails details) {
                            if (!layoutProvider.drawerOpened) {
                              layoutProvider.navDrawerWidth =
                                  Constants.navigationDrawerMaxWidth;
                            } else {
                              layoutProvider.navDrawerWidth = 0;
                            }
                            layoutProvider.drawerOpened =
                                !layoutProvider.drawerOpened;
                          },
                          child: VerticalDivider(
                            width: lerpDouble(
                                Constants.verticalDividerThickness * 3,
                                Constants.verticalDividerThickness,
                                value),
                            thickness: lerpDouble(
                                Constants.verticalDividerThickness * 3,
                                Constants.verticalDividerThickness,
                                value),
                            color: Colors.transparent,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
          ),

          Expanded(
            child: Consumer<ThemeProvider>(builder:
                (BuildContext context, ThemeProvider value, Widget? child) {
              return Scaffold(
                  backgroundColor: (!(Platform.isIOS || Platform.isAndroid))
                      ? Theme.of(context)
                          .scaffoldBackgroundColor
                          .withOpacity(themeProvider.scaffoldOpacity)
                      : Theme.of(context).scaffoldBackgroundColor,
                  floatingActionButtonLocation: ExpandableFab.location,
                  floatingActionButton: MainFloatingActionButton(
                    fabKey: _fabKey,
                  ),
                  resizeToAvoidBottomInset: false,
                  appBar: buildAppBar(mobile: false),
                  body: SafeArea(
                      child: Constants
                          .viewRoutes[layoutProvider.selectedPageIndex].view));
            }),
          )
        ]),
        if (Platform.isWindows) ...windowsTitlebar()
      ],
    );
  }

  Widget _buildMobile({required BuildContext context}) {
    return Scaffold(
        backgroundColor: (!(Platform.isIOS || Platform.isAndroid))
            ? Theme.of(context)
                .scaffoldBackgroundColor
                .withOpacity(themeProvider.scaffoldOpacity)
            : Theme.of(context).scaffoldBackgroundColor,
        appBar: buildAppBar(mobile: true),
        drawer: buildNavigationDrawer(context: context, largeScreen: false),
        floatingActionButtonLocation: ExpandableFab.location,
        floatingActionButton: MainFloatingActionButton(
          fabKey: _fabKey,
        ),
        resizeToAvoidBottomInset: false,
        body: SafeArea(
            child:
                Constants.viewRoutes[layoutProvider.selectedPageIndex].view));
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
            "Allocate",
            style: Constants.largeHeaderStyle,
            minFontSize: Constants.huge,
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.visible,
          ),
          Tooltip(
            message: "Remaining energy for tasks",
            child: ValueListenableBuilder<int>(
              valueListenable: userProvider.myDayTotal,
              builder: (BuildContext context, int myDay, Widget? child) {
                return Selector<UserViewModel, int>(
                  selector: (BuildContext context, UserViewModel vm) =>
                      vm.bandwidth,
                  builder:
                      (BuildContext context, int bandwidth, Widget? child) =>
                          BatteryMeter(
                              showDifference: true,
                              scale: .65,
                              weight: myDay.toDouble(),
                              max: bandwidth.toDouble(),
                              constraints: const BoxConstraints(maxWidth: 120)),
                );
              },
            ),
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
        if (Platform.isMacOS) {
          return TitlebarSafeArea(
            child: IconButton(
                hoverColor: Colors.transparent,
                icon: const Icon(Icons.menu_rounded),
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                }),
          );
        }
        return IconButton(
            icon: const Icon(Icons.menu_rounded),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            });
      });
    }

    // These should select from LayoutProvider
    if (layoutProvider.drawerOpened) {
      return IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            layoutProvider.drawerOpened = false;
            layoutProvider.navDrawerWidth = 1.0;
          });
    }

    if (Platform.isMacOS) {
      return TitlebarSafeArea(
        child: IconButton(
            hoverColor: Colors.transparent,
            icon: const Icon(Icons.menu_rounded),
            onPressed: () {
              layoutProvider.drawerOpened = true;
              layoutProvider.navDrawerWidth =
                  Constants.navigationDrawerMaxWidth;
            }),
      );
    }
    return IconButton(
        icon: const Icon(Icons.menu_rounded),
        onPressed: () {
          layoutProvider.drawerOpened = true;
          layoutProvider.navDrawerWidth = Constants.navigationDrawerMaxWidth;
        });
  }

  Widget buildNavigationDrawer(
      {required BuildContext context, bool largeScreen = false}) {
    Widget drawer = NavigationDrawer(
        backgroundColor:
            (largeScreen && (!(Platform.isIOS || Platform.isAndroid)))
                ? Theme.of(context)
                    .colorScheme
                    .surface
                    .withOpacity(themeProvider.sidebarOpacity)
                : null,
        onDestinationSelected: (index) {
          layoutProvider.selectedPageIndex = index;

          ExpandableFabState? fabState = _fabKey.currentState;
          if (null != fabState && fabState.isOpen) {
            fabState.toggle();
          }

          if (!largeScreen) {
            Navigator.pop(context);
          }

          resetProviders();
        },
        selectedIndex: layoutProvider.selectedPageIndex,
        children: [
          Padding(
            padding: const EdgeInsets.all(
              Constants.padding,
            ),
            child: ListTile(
              shape: const RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.all(Radius.circular(Constants.circular))),
              leading: CircleAvatar(
                radius: Constants.circleAvatarRadius,
                child: Selector<UserViewModel, String>(
                    selector: (BuildContext context, UserViewModel vm) =>
                        vm.username,
                    builder:
                        (BuildContext context, String value, Widget? child) =>
                            Text(value[0].toUpperCase())),
              ),
              title: ValueListenableBuilder(
                valueListenable: userProvider.isConnected,
                builder: (BuildContext context, bool online, Widget? child) =>
                    Selector<UserViewModel, String>(
                        selector: (BuildContext context, UserViewModel vm) =>
                            vm.username,
                        builder: (BuildContext context, String value,
                                Widget? child) =>
                            Text(value)),
              ),
              subtitle: ValueListenableBuilder(
                valueListenable: userProvider.isConnected,
                builder: (BuildContext context, bool online, Widget? child) =>
                    online ? const Text("Online") : const Text("Offline"),
              ),
              onTap: () {
                resetProviders();
                layoutProvider.selectedPageIndex =
                    Constants.viewRoutes.indexOf(Constants.settingsScreen);
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
              initiallyExpanded: layoutProvider.navGroupsExpanded,
              onExpansionChanged: ({bool expanded = false}) {
                Future.delayed(
                    const Duration(milliseconds: Constants.footerDelay), () {
                  layoutProvider.navGroupsExpanded = expanded;
                  layoutProvider.footerTween = true;
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
                      if (!largeScreen) {
                        Navigator.pop(context);
                      }
                    }),
                Tiles.addTile(
                    title: "Add New",
                    onTap: () async {
                      await blurredNonDismissible(
                          context: context, dialog: const CreateGroupScreen());
                      // await showDialog(
                      //     barrierDismissible: false,
                      //     useRootNavigator: false,
                      //     context: context,
                      //     builder: (BuildContext context) =>
                      //         const CreateGroupScreen());
                    }),

                ValueListenableBuilder(
                  valueListenable: groupProvider.navKey,
                  builder: (BuildContext context, int value, Widget? child) =>
                      ListViews.navDrawerGroups(
                    groups: groupProvider.secondaryGroups,
                  ),
                ),

                // refactor listview
              ]),
          const PaddedDivider(padding: Constants.doublePadding),
          (layoutProvider.footerTween)
              ? TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: Constants.footerTime),
                  curve: Curves.fastOutSlowIn,
                  onEnd: () {
                    layoutProvider.footerTween = false;
                  },
                  tween: Tween<double>(
                    begin: layoutProvider.navGroupsExpanded
                        ? layoutProvider.footerOffset
                        : layoutProvider.footerOffsetOpened,
                    end: layoutProvider.navGroupsExpanded
                        ? layoutProvider.footerOffsetOpened
                        : layoutProvider.footerOffset,
                  ),
                  builder: (BuildContext context, double value, Widget? child) {
                    return Padding(
                      padding: EdgeInsets.only(bottom: value),
                      child: const SizedBox.shrink(),
                    );
                  })
              : Padding(
                  padding: EdgeInsets.only(
                      bottom: (layoutProvider.navGroupsExpanded)
                          ? layoutProvider.footerOffsetOpened
                          : layoutProvider.footerOffset),
                  child: const SizedBox.shrink()),
          Constants.settingsScreen.destination,
          Constants.trashScreen.destination,
          const Padding(
              padding: EdgeInsets.symmetric(
                vertical: Constants.padding,
              ),
              child: SizedBox.shrink()),
        ]);

    return (layoutProvider.isMobile)
        ? Scrollbar(
            controller: navScrollController,
            child: Scrollable(
                controller: navScrollController,
                viewportBuilder:
                    (BuildContext context, ViewportOffset offset) => drawer),
          )
        : drawer;
  }
}
