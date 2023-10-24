import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:jiffy/jiffy.dart';
import 'package:provider/provider.dart';

import '../../../model/task/todo.dart';
import '../../../providers/todo_provider.dart';
import '../../../providers/user_provider.dart';
import '../../../util/constants.dart';
import '../../../util/enums.dart';
import '../../widgets/listview_header.dart';
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

  late final ToDoProvider toDoProvider;

  // TODO: factor out?
  static const List<Tab> tabs = [
    Tab(text: "Tasks"),
    Tab(text: "Routines"),
    Tab(text: "Calendar")
  ];

  // TODO: factor out?
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
    toDoProvider = Provider.of<ToDoProvider>(context, listen: false);
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
            child: buildRegular(
                context: context,
                buildCalendar: true,
                smallScreen: smallScreen),
          );
  }

  Widget buildRegular(
      {required BuildContext context,
      bool buildCalendar = false,
      bool smallScreen = false}) {
    // Structure:
    // Header
    // Navigation bar: ToDos / Routines / Calendar
    return Column(children: [
      ListViewHeader<ToDo>(
          sorter: toDoProvider.sorter,
          leadingIcon: const Icon(Icons.wb_sunny_outlined),
          subTitle: AutoSizeText(
              Jiffy.now().format(
                  pattern:
                      (smallScreen) ? "EE. MMM. d, 'yy" : "EEEE, MMMM d, yyyy"),
              style: Constants.headerStyle,
              softWrap: false,
              maxLines: 1,
              overflow: TextOverflow.visible,
              minFontSize: Constants.large),
          showSorter: (userProvider.myDayIndex == 0),
          header: "My Day",
          onChanged: (SortMethod? method) {
            if (null == method) {
              return;
            }
            if (mounted) {
              setState(() {
                toDoProvider.sortMethod = method;
              });
            }
          }),
      Expanded(
        child: DefaultTabController(
            initialIndex: userProvider.myDayIndex,
            length: (buildCalendar) ? 3 : 2,
            child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: Constants.padding),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.all(
                            Radius.circular(Constants.roundedCorners)),
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceVariant
                            .withOpacity(Constants.myDayOpacity),
                      ),
                      child: TabBar(
                        onTap: (int newIndex) {
                          setState(() {
                            userProvider.myDayIndex = newIndex;
                          });
                        },
                        indicatorSize: TabBarIndicatorSize.tab,
                        indicator: BoxDecoration(
                            color:
                                Theme.of(context).colorScheme.primaryContainer,
                            borderRadius: const BorderRadius.all(
                                Radius.circular(Constants.roundedCorners))),
                        splashBorderRadius: const BorderRadius.all(
                            Radius.circular(Constants.roundedCorners)),
                        dividerColor: Colors.transparent,
                        tabs: (buildCalendar)
                            ? tabs
                            : tabs.sublist(0, tabs.length - 1),
                      ),
                    ),
                  ),
                  Expanded(
                    child: TabBarView(
                      children: (buildCalendar)
                          ? views
                          : views.sublist(0, views.length - 1),
                    ),
                  ),
                ])),
      ),
    ]);
  }

  Widget buildHuge({required BuildContext context}) {
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
