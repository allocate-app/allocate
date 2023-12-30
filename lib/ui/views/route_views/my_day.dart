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

class MyDayScreen extends StatefulWidget {
  const MyDayScreen({super.key});

  @override
  State<MyDayScreen> createState() => _MyDayScreen();
}

class _MyDayScreen extends State<MyDayScreen> {
  late final UserProvider userProvider;

  late final ToDoProvider toDoProvider;

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
    if (userProvider.myDayIndex == Constants.tabs.length - 1 &&
        userProvider.hugeScreen) {
      userProvider.myDayIndex = 0;
    }
    MediaQuery.of(context).size;

    return (userProvider.hugeScreen)
        ? buildHuge(context: context)
        : Padding(
            padding: const EdgeInsets.all(Constants.innerPadding),
            child: buildRegular(
                context: context,
                buildCalendar: true,
                smallScreen: userProvider.smallScreen),
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
              Jiffy.now().format(pattern: "EEEE, MMMM d, yyyy"),
              style: Constants.headerStyle,
              softWrap: false,
              maxLines: 1,
              overflowReplacement: AutoSizeText(
                  Jiffy.now().format(pattern: "EE. MMM. d, 'yy"),
                  style: Constants.headerStyle,
                  softWrap: false,
                  maxLines: 1,
                  overflow: TextOverflow.visible,
                  minFontSize: Constants.large),
              minFontSize: Constants.large),
          showSorter: (userProvider.myDayIndex == 0),
          header: "My Day",
          onChanged: ({SortMethod? sortMethod}) {
            if (null == sortMethod) {
              return;
            }
            if (mounted) {
              setState(() {
                toDoProvider.sortMethod = sortMethod;
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
                            Radius.circular(Constants.semiCircular)),
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
                                Radius.circular(Constants.semiCircular))),
                        splashBorderRadius: const BorderRadius.all(
                            Radius.circular(Constants.semiCircular)),
                        dividerColor: Colors.transparent,
                        tabs: (buildCalendar)
                            ? Constants.tabs
                            : Constants.tabs
                                .sublist(0, Constants.tabs.length - 1),
                      ),
                    ),
                  ),
                  Expanded(
                    child: TabBarView(
                      children: (buildCalendar)
                          ? Constants.views
                          : Constants.views
                              .sublist(0, Constants.views.length - 1),
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
              Padding(
                padding: const EdgeInsets.only(
                    left: Constants.padding, right: Constants.halfPadding),
                child: VerticalDivider(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  thickness: Constants.verticalDividerThickness,
                ),
              ),
              Flexible(child: Constants.views[Constants.views.length - 1])
            ]));
  }
}
