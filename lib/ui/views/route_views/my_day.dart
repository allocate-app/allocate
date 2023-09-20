import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/user_provider.dart';
import '../../../util/constants.dart';
import '../sub_views/calendar.dart';
import '../sub_views/my_day_routines.dart';
import '../sub_views/my_day_todos.dart';

class MyDayScreen extends StatefulWidget {
  const MyDayScreen({Key? key}) : super(key: key);

  @override
  State<MyDayScreen> createState() => _MyDayScreen();
}

class _MyDayScreen extends State<MyDayScreen> {
  late final UserProvider userProvider;

  // TODO: factor out.
  static const List<Tab> tabs = [
    Tab(text: "Tasks"),
    Tab(text: "Routines"),
    Tab(text: "Calendar")
  ];

  // THESE NEED TO BE STATEFUL WIDGETS.
  static const List<Widget> views = [
    MyDayToDos(),
    MyDayRoutines(),
    CalendarScreen(),
  ];

  @override
  void initState() {
    super.initState();
    initializeProviders();
  }

  void initializeProviders() {
    userProvider = Provider.of<UserProvider>(context, listen: false);
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    bool largeScreen = (width >= Constants.largeScreen);
    bool smallScreen = (width <= Constants.smallScreen);
    bool hugeScreen = (width >= Constants.hugeScreen);

    if (userProvider.myDayIndex == tabs.length - 1 && hugeScreen) {
      userProvider.myDayIndex = 0;
    }

    return (hugeScreen)
        ? buildHuge(context: context)
        : Padding(
            padding: const EdgeInsets.all(Constants.innerPadding),
            child: buildRegular(context: context, buildCalendar: true),
          );
  }

  Widget buildRegular(
      {required BuildContext context, bool buildCalendar = false}) {
    // Structure:
    // Header
    // Navigation bar: ToDos / Routines / Calendar

    return Column(children: [
      const Row(
          mainAxisAlignment: MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(Constants.padding),
                child: AutoSizeText("My Day",
                    style: Constants.largeHeaderStyle,
                    softWrap: false,
                    maxLines: 1,
                    overflow: TextOverflow.visible,
                    minFontSize: Constants.large),
              ),
            ),
          ]),
      Expanded(
        child: DefaultTabController(
            initialIndex: userProvider.myDayIndex,
            length: (buildCalendar) ? 3 : 2,
            child: Builder(builder: (context) {
              userProvider.myDayIndex = DefaultTabController.of(context).index;
              return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TabBar(
                      indicatorSize: TabBarIndicatorSize.tab,
                      indicator: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: const BorderRadius.all(
                              Radius.circular(Constants.roundedCorners))),
                      splashBorderRadius: const BorderRadius.all(
                          Radius.circular(Constants.roundedCorners)),
                      dividerColor: Colors.transparent,
                      tabs: (buildCalendar)
                          ? tabs
                          : tabs.sublist(0, tabs.length - 1),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: Constants.innerPadding),
                        child: TabBarView(
                          children: (buildCalendar)
                              ? views
                              : views.sublist(0, views.length - 1),
                        ),
                      ),
                    ),
                  ]);
            })),
      ),
    ]);
  }

  Widget buildHuge({required BuildContext context}) {
    // Structure:
    // Split view: HEADER + NavigationBar Bar: ToDos / Routines
    // Calendar on the side, possibly with title.
    //return const DebugPlaceholder(debugName: "MY DAY");
    return Padding(
        padding: const EdgeInsets.all(Constants.innerPadding),
        child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Flexible(
                  child: buildRegular(context: context, buildCalendar: false)),
              const VerticalDivider(),
              Flexible(child: views[views.length - 1])
            ]));
  }
}
