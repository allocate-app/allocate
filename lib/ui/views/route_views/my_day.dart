import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:jiffy/jiffy.dart';
import 'package:provider/provider.dart';

import '../../../model/task/todo.dart';
import '../../../providers/application/layout_provider.dart';
import '../../../providers/model/todo_provider.dart';
import '../../../util/constants.dart';
import '../../../util/enums.dart';
import '../../../util/sorting/todo_sorter.dart';
import '../../widgets/listview_header.dart';

class MyDayScreen extends StatefulWidget {
  const MyDayScreen({super.key});

  @override
  State<MyDayScreen> createState() => _MyDayScreen();
}

class _MyDayScreen extends State<MyDayScreen> {
  late final LayoutProvider layoutProvider;
  late final ToDoProvider toDoProvider;

  @override
  void initState() {
    super.initState();
    initializeProviders();
  }

  void initializeProviders() {
    toDoProvider = Provider.of<ToDoProvider>(context, listen: false);
    layoutProvider = Provider.of<LayoutProvider>(context, listen: false);
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        // Constraints are calculated in layoutProvider.
        if (layoutProvider.wideView) {
          return buildHuge(context: context);
        }
        return Padding(
          padding: const EdgeInsets.all(Constants.padding),
          child: buildRegular(
              context: context,
              buildCalendar: true,
              smallScreen: layoutProvider.smallScreen),
        );
      },
    );
  }

  Widget buildRegular(
      {required BuildContext context,
      bool buildCalendar = false,
      bool smallScreen = false}) {
    return Column(children: [
      Selector<LayoutProvider, int>(
        selector: (BuildContext context, LayoutProvider lp) => lp.myDayIndex,
        builder: (BuildContext context, int value, Widget? child) =>
            Selector<ToDoProvider, ToDoSorter>(
                selector: (BuildContext context, ToDoProvider tp) => tp.sorter,
                builder: (BuildContext context, ToDoSorter sorter,
                        Widget? child) =>
                    ListViewHeader<ToDo>(
                        outerPadding: const EdgeInsets.all(Constants.padding),
                        sorter: toDoProvider.sorter,
                        leadingIcon: const Icon(Icons.wb_sunny_outlined),
                        subtitle: AutoSizeText(
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
                        showSorter: (value == 0),
                        header: "My Day",
                        onChanged: ({SortMethod? sortMethod}) {
                          if (null == sortMethod) {
                            return;
                          }
                          toDoProvider.sortMethod = sortMethod;
                        })),
      ),
      Expanded(
        child: DefaultTabController(
            initialIndex: layoutProvider.myDayIndex,
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
                            .withOpacity(Constants.tabBarOpacity),
                      ),
                      child: TabBar(
                        onTap: (int newIndex) {
                          layoutProvider.myDayIndex = newIndex;
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

  // TODO: make vertical divider slideable.
  Widget buildHuge({required BuildContext context}) {
    return Padding(
        padding: const EdgeInsets.all(Constants.doublePadding),
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
