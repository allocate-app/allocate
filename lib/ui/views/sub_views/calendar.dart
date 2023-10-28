import 'dart:collection';
import 'dart:io';

import 'package:another_flushbar/flushbar.dart';
import "package:flutter/material.dart";
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../model/calendar_event.dart';
import '../../../providers/deadline_provider.dart';
import '../../../providers/group_provider.dart';
import '../../../providers/reminder_provider.dart';
import '../../../providers/todo_provider.dart';
import '../../../util/constants.dart';
import '../../../util/enums.dart';
import '../../../util/exceptions.dart';
import '../../../util/interfaces/i_repeatable.dart';
import '../../widgets/flushbars.dart';
import '../../widgets/listviews.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({Key? key}) : super(key: key);

  @override
  State<CalendarScreen> createState() => _CalendarScreen();
}

class _CalendarScreen extends State<CalendarScreen> {
  late final ValueNotifier<List<CalendarEvent>> _selectedEvents;
  late final LinkedHashMap<DateTime, Set<CalendarEvent>> _events;

  late final CalendarFormat calendarFormat;
  late DateTime _focusedDay;
  DateTime? _selectedDay;

  late DateTime latest;

  late final HeaderStyle headerStyle = const HeaderStyle(
      titleCentered: true,
      formatButtonVisible: false,
      titleTextStyle: Constants.headerStyle);

  late final CalendarStyle calendarStyle = CalendarStyle(
      selectedDecoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        shape: BoxShape.circle,
      ),
      todayDecoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        shape: BoxShape.circle,
      ),
      todayTextStyle: TextStyle(
        color: Theme.of(context).colorScheme.primary,
      ));

  late ToDoProvider toDoProvider;
  late ReminderProvider reminderProvider;
  late DeadlineProvider deadlineProvider;
  late GroupProvider groupProvider;

  late ScrollController mainScrollController;
  late ScrollPhysics scrollPhysics;

  @override
  void initState() {
    super.initState();
    initializeProviders();
    initializeParameters();
    initializeControllers();
    resetEvents();
  }

  @override
  void dispose() {
    toDoProvider.removeListener(resetEvents);
    reminderProvider.removeListener(resetEvents);
    deadlineProvider.removeListener(resetEvents);
    mainScrollController.dispose();
    super.dispose();
  }

  void initializeProviders() {
    toDoProvider = Provider.of(context, listen: false);
    reminderProvider = Provider.of(context, listen: false);
    deadlineProvider = Provider.of(context, listen: false);
    groupProvider = Provider.of(context, listen: false);

    toDoProvider.addListener(resetEvents);
    reminderProvider.addListener(resetEvents);
    deadlineProvider.addListener(resetEvents);
  }

  void initializeParameters() {
    calendarFormat = CalendarFormat.month;
    _focusedDay = Constants.today;
    _selectedDay = _focusedDay;
    latest = _focusedDay.copyWith(day: 1, month: _focusedDay.month + 1);
    _events = LinkedHashMap<DateTime, Set<CalendarEvent>>(
      equals: isSameDay,
      hashCode: getHashCode,
    );

    _selectedEvents = ValueNotifier(getEventsForDay(_selectedDay));
  }

  void initializeControllers() {
    mainScrollController = ScrollController();
    scrollPhysics = (Platform.isIOS || Platform.isMacOS)
        ? const BouncingScrollPhysics()
        : const ClampingScrollPhysics();
  }

  Future<void> initializeEvents() async {
    await getEvents().whenComplete(() {
      if (mounted) {
        setState(() {
          _selectedEvents.value = getEventsForDay(_selectedDay);
        });
      }
    });
  }

  // Grab all events up to the current limit.
  Future<void> resetEvents() async {
    _events.clear();
    await populateCalendars(limit: latest);
  }

  Future<void> populateCalendars({DateTime? startDay, DateTime? limit}) async {
    startDay = startDay ??
        Constants.today.copyWith(
            day: 1,
            hour: Constants.midnight.hour,
            minute: Constants.midnight.minute,
            second: 0,
            microsecond: 0,
            millisecond: 0);
    limit = limit ?? startDay.copyWith(month: startDay.month + 1);
    await Future.wait([
      toDoProvider.populateCalendar(limit: limit),
      deadlineProvider.populateCalendar(limit: limit),
      reminderProvider.populateCalendar(limit: limit),
    ]).whenComplete(() async {
      await getEvents(day: startDay, end: limit).whenComplete(() {
        if (mounted) {
          setState(() {
            latest = limit!;
            _selectedEvents.value = getEventsForDay(_selectedDay);
          });
        }
      });
    }).catchError((e) {
      Flushbar? error;

      error = Flushbars.createError(
        message: e.cause,
        context: context,
        dismissCallback: () => error?.dismiss(),
      );

      error.show(context);
      return [];
    },
        test: (e) =>
            e is FailureToUploadException || e is FailureToUpdateException);
  }

  // TODO: Factor this into an EventProvider class?
  Future<void> getEvents({DateTime? day, DateTime? end}) async {
    day = day ?? Constants.today.copyWith(day: 1);
    end = end ?? day.copyWith(month: day.month + 1);

    await Future.wait([
      toDoProvider.getToDosBetween(
        start: day,
        end: end,
      ),
      deadlineProvider.getDeadlinesBetween(start: day, end: end),
      reminderProvider.getRemindersBetween(start: day, end: end),
    ]).then((data) {
      for (int i = 0; i < data.length; i++) {
        for (IRepeatable eventModel in data[i]) {
          DateTime startDay = eventModel.startDate.copyWith(
              hour: Constants.midnight.hour, minute: Constants.midnight.minute);
          DateTime dueDay = eventModel.dueDate.copyWith(
              hour: Constants.midnight.hour, minute: Constants.midnight.minute);

          CalendarEvent event = CalendarEvent(
              model: eventModel, repeatableType: RepeatableType.values[i]);
          if (_events.containsKey(startDay)) {
            _events[startDay]!.add(event);
          } else {
            _events[startDay] = {event};
          }

          if (_events.containsKey(dueDay)) {
            _events[dueDay]!.add(event);
          } else {
            _events[dueDay] = {event};
          }
        }
      }
    });
  }

  List<CalendarEvent> getEventsForDay(DateTime? day) {
    return _events[day]?.toList() ?? [];
  }

  int getHashCode(DateTime key) {
    return key.day * 1000000 + key.month * 10000 + key.year;
  }

  void handleDaySelected(
      {required DateTime selectedDay, required DateTime focusedDay}) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
      });
    }
    _selectedEvents.value = getEventsForDay(selectedDay);
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    bool largeScreen = (width >= Constants.largeScreen);
    bool smallScreen = (width <= Constants.smallScreen);
    bool hugeScreen = (width >= Constants.hugeScreen);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
            child: Scrollbar(
          thumbVisibility: true,
          controller: mainScrollController,
          child: ListView(
              shrinkWrap: true,
              physics: AlwaysScrollableScrollPhysics(parent: scrollPhysics),
              controller: mainScrollController,
              children: [
                TableCalendar(
                    firstDay: DateTime(1970),
                    lastDay: DateTime(3000),
                    focusedDay: _focusedDay,
                    headerStyle: headerStyle,
                    calendarStyle: calendarStyle,
                    calendarFormat: calendarFormat,
                    eventLoader: getEventsForDay,
                    selectedDayPredicate: (day) {
                      return isSameDay(_selectedDay, day);
                    },
                    onDaySelected: (selectedDay, focusedDay) {
                      handleDaySelected(
                          selectedDay: selectedDay, focusedDay: focusedDay);
                    },
                    onPageChanged: (focusedDay) async {
                      _focusedDay = focusedDay;
                      DateTime testDay =
                          focusedDay.copyWith(month: focusedDay.month + 1);
                      if (testDay.isAfter(latest)) {
                        // Populate new data if existing -- grabs events afterward.
                        await populateCalendars(startDay: focusedDay);
                      } else {
                        // Just grab events.
                        getEvents(day: focusedDay, end: latest);
                      }
                    }),
                ListViews.eventList(
                    selectedEvents: _selectedEvents, smallScreen: smallScreen)
              ]),
        )),
      ],
    );
  }
}
