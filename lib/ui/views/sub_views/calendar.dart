import 'dart:io';

import "package:flutter/material.dart";
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../providers/event_provider.dart';
import '../../../providers/user_provider.dart';
import '../../../util/constants.dart';
import '../../widgets/listviews.dart';

// TODO: UPDATE THIS TO ONLY SHOW IN GUI, NOT UPDATE DB.
// TODO: REFACTOR EVENTPROVIDER
class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreen();
}

class _CalendarScreen extends State<CalendarScreen> {
  late ScrollController mainScrollController;
  late ScrollPhysics scrollPhysics;

  late EventProvider eventProvider;

  // TODO: MIGRATE TO APPPROVIDER
  late UserProvider userProvider;

  @override
  void initState() {
    super.initState();
    initializeProviders();
    initializeControllers();
  }

  @override
  void dispose() {
    mainScrollController.dispose();
    super.dispose();
  }

  void initializeProviders() {
    eventProvider = Provider.of<EventProvider>(context, listen: false);
    userProvider = Provider.of<UserProvider>(context, listen: false);
  }

  void initializeControllers() {
    mainScrollController = ScrollController();
    scrollPhysics = (Platform.isIOS || Platform.isMacOS)
        ? const BouncingScrollPhysics()
        : const ClampingScrollPhysics();
  }

  @override
  Widget build(BuildContext context) {
    MediaQuery.sizeOf(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Consumer<EventProvider>(builder:
            (BuildContext context, EventProvider value, Widget? child) {
          return Flexible(
              child: Scrollbar(
            thumbVisibility: true,
            controller: mainScrollController,
            child: ListView(
                shrinkWrap: true,
                physics: AlwaysScrollableScrollPhysics(parent: scrollPhysics),
                controller: mainScrollController,
                children: [
                  TableCalendar(
                      // January 1st, 5 years ago
                      firstDay: DateTime(
                          Constants.today.year - Constants.yearOffset, 1, 1),
                      // January 31st, 5 years from now.
                      lastDay: DateTime(
                          Constants.today.year + Constants.yearOffset, 2, 0),
                      focusedDay: value.focusedDay,
                      headerStyle: Constants.calendarHeaderStyle,
                      calendarStyle: Constants.calendarStyle(context),
                      calendarFormat: CalendarFormat.month,
                      pageJumpingEnabled: true,
                      eventLoader: value.getEventsForDay,
                      selectedDayPredicate: (day) {
                        return isSameDay(value.selectedDay, day);
                      },
                      onDaySelected: value.handleDaySelected,
                      onPageChanged: (focusedDay) {
                        value.focusedDay = focusedDay;
                      }),
                  ListViews.eventList(
                      selectedEvents: value.selectedEvents,
                      smallScreen: userProvider.smallScreen),
                ]),
          ));
        }),
      ],
    );
  }
}
