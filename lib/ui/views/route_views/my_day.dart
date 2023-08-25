import "dart:io";

import "package:flutter/material.dart";

import '../../../util/interfaces/crossbuild.dart';
import '../sub_views/calendar.dart';
import 'my_day_listview.dart';

// MYDAY:
// Init -> Calculate weight (todoprovider/routineprovider).
// Mobile:
// --NavigationBar: MyDayList & Calendar
// Desktop:
// --Row: MyDayListView & Calendar.

class MyDayScreen extends StatefulWidget {
  MyDayScreen({Key? key}) : super(key: key);

  @override
  State<MyDayScreen> createState() => _MyDayScreen();
}

class _MyDayScreen extends State<MyDayScreen> implements CrossBuild {
  // This is for mobile -> 0, 1 = My Day List, Calendar.
  int selectedPageIndex = 0;

  // Destination Junk. TODO: Pick icons.
  static const List<NavigationDestination> destinations = [
    NavigationDestination(
      selectedIcon: Icon(Icons.abc),
      icon: Icon(Icons.abc_outlined),
      label: "My Day",
    ),
    NavigationDestination(
      selectedIcon: Icon(Icons.calendar_today),
      icon: Icon(Icons.calendar_today_outlined),
      label: "Calendar",
    )
  ];

  @override
  void initState() {
    throw UnimplementedError();
  }

  // CONTAINER
  @override
  Widget build(BuildContext context) {
    if (Platform.isAndroid || Platform.isIOS) {
      return buildMobile(context: context);
    }
    return buildDesktop(context: context);
  }

  @override
  Widget buildDesktop({required BuildContext context}) {
    return Row(
      children: [MyDayListScreen(), CalendarScreen()],
    );
  }

  @override
  Widget buildMobile({required BuildContext context}) {
    return Column(
      children: [
        NavigationBar(
          selectedIndex: selectedPageIndex,
          onDestinationSelected: (int index) => setState(() => selectedPageIndex = index),
          destinations: destinations,
        ),
        [const MyDayListScreen(), const CalendarScreen()][selectedPageIndex]
      ],
    );
  }
}
