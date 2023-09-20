import 'dart:collection';

import 'package:allocate/ui/views/sub_views/update_deadline.dart';
import 'package:allocate/ui/views/sub_views/update_reminder.dart';
import 'package:allocate/ui/views/sub_views/update_todo.dart';
import 'package:auto_size_text/auto_size_text.dart';
import "package:flutter/material.dart";
import 'package:jiffy/jiffy.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../model/task/deadline.dart';
import '../../../model/task/reminder.dart';
import '../../../model/task/todo.dart';
import '../../../providers/deadline_provider.dart';
import '../../../providers/reminder_provider.dart';
import '../../../providers/todo_provider.dart';
import '../../../util/constants.dart';
import '../../../util/enums.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({Key? key}) : super(key: key);

  @override
  State<CalendarScreen> createState() => _CalendarScreen();
}

// TODO: flesh out implementation, add reminders -> Add repeating functionality?
class _CalendarScreen extends State<CalendarScreen> {
  late final ValueNotifier<List<CalendarEvent>> _selectedEvents;
  late final LinkedHashMap<DateTime, Set<CalendarEvent>> _events;

  late final CalendarFormat calendarFormat;
  late DateTime _focusedDay;
  DateTime? _selectedDay;

  late final HeaderStyle headerStyle = const HeaderStyle(
      formatButtonVisible: false, titleTextStyle: Constants.headerStyle);

  late final CalendarStyle calendarStyle = CalendarStyle(
      selectedDecoration: BoxDecoration(
        color: Theme
            .of(context)
            .colorScheme
            .primary,
        shape: BoxShape.circle,
      ),
      todayDecoration: BoxDecoration(
        color: Theme
            .of(context)
            .colorScheme
            .primaryContainer,
        shape: BoxShape.circle,
      ),
      todayTextStyle: TextStyle(
        color: Theme
            .of(context)
            .colorScheme
            .primary,
      ));

  late ToDoProvider toDoProvider;
  late ReminderProvider reminderProvider;
  late DeadlineProvider deadlineProvider;

  @override
  void initState() {
    super.initState();
    initializeProviders();
  }

  void initializeProviders() {
    toDoProvider = Provider.of(context, listen: false);
    reminderProvider = Provider.of(context, listen: false);
    deadlineProvider = Provider.of(context, listen: false);
  }

  void initializeParameters() {
    calendarFormat = CalendarFormat.month;
    _focusedDay = Constants.today;
    _selectedDay = _focusedDay;
    _events = LinkedHashMap<DateTime, Set<CalendarEvent>>(
      equals: isSameDay,
      hashCode: getHashCode,
    );

    initializeEvents();
  }

  Future<void> initializeEvents() async {
    await getEvents().whenComplete(() {
      if (mounted) {
        setState(() {
          _selectedEvents = ValueNotifier(getEventsForDay(_selectedDay));
        });
      }
    });
  }

  Future<void> getEvents({DateTime? day}) async {
    day = day ?? Constants.today.copyWith(day: 0);

    DateTime end = Jiffy
        .parseFromDateTime(day)
        .add(months: 1)
        .dateTime;
    await Future.wait([
      getToDoEvents(start: day, end: end),
      getDeadlineEvents(start: day, end: end),
      getReminderEvents(start: day, end: end),
    ]).whenComplete(() => setState(() {}));
  }

  Future<void> getToDoEvents({DateTime? start, DateTime? end}) async {
    start = start ?? Constants.today.copyWith(day: 1);
    end = end ?? Jiffy
        .parseFromDateTime(start)
        .add(months: 1)
        .dateTime;

    List<ToDo> toDos =
    await toDoProvider.getToDosBetween(start: start, end: end);

    for (ToDo toDo in toDos) {
      DateTime day = toDo.dueDate.copyWith(
          hour: Constants.midnight.hour, minute: Constants.midnight.minute);
      CalendarEvent event = CalendarEvent(
          title: toDo.name, modelType: ModelType.toDo, toDo: toDo);
      if (_events.containsKey(day)) {
        _events[day]!.add(event);
      } else {
        _events[day] = {event};
      }
    }
  }

  Future<void> getDeadlineEvents({DateTime? start, DateTime? end}) async {
    start = start ?? Constants.today.copyWith(day: 1);
    end = end ?? Jiffy
        .parseFromDateTime(start)
        .add(months: 1)
        .dateTime;

    List<Deadline> deadlines =
    await deadlineProvider.getDeadlinesBetween(start: start, end: end);

    for (Deadline deadline in deadlines) {
      DateTime day = deadline.dueDate.copyWith(
          hour: Constants.midnight.hour, minute: Constants.midnight.minute);
      CalendarEvent event = CalendarEvent(
          title: deadline.name, modelType: ModelType.toDo, deadline: deadline);
      if (_events.containsKey(day)) {
        _events[day]!.add(event);
      } else {
        _events[day] = {event};
      }
    }
  }

  Future<void> getReminderEvents({DateTime? start, DateTime? end}) async {
    start = start ?? Constants.today.copyWith(day: 1);
    end = end ?? Jiffy
        .parseFromDateTime(start)
        .add(months: 1)
        .dateTime;

    List<Reminder> reminders =
    await reminderProvider.getRemindersBetween(start: start, end: end);

    for (Reminder reminder in reminders) {
      DateTime day = reminder.dueDate.copyWith(
          hour: Constants.midnight.hour, minute: Constants.midnight.minute);
      CalendarEvent event = CalendarEvent(
          title: reminder.name, modelType: ModelType.toDo, reminder: reminder);
      if (_events.containsKey(day)) {
        _events[day]!.add(event);
      } else {
        _events[day] = {event};
      }
    }
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
    return Column(
      mainAxisSize: MainAxisSize.min,
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
              if (focusedDay.isAfter(Constants.today)) {
                await Future.wait([
                  toDoProvider.populateCalendar(limit: focusedDay),
                  deadlineProvider.populateCalendar(limit: focusedDay),
                ]).whenComplete(() => setState(() {}));
              }
            }),
        Expanded(child: buildEvents())
      ],
    );
  }

  Widget buildEvents() {
    return ValueListenableBuilder<List<CalendarEvent>>(
      valueListenable: _selectedEvents,
      builder:
          (BuildContext context, List<CalendarEvent> value, Widget? child) {
        return ListView.builder(
            itemCount: value.length,
            itemBuilder: (BuildContext context, int index) {
              return ListTile(
                  contentPadding:
                  const EdgeInsets.symmetric(horizontal: Constants.padding),
                  title: AutoSizeText(
                    value[index].title,
                    minFontSize: Constants.medium,
                    maxLines: 1,
                    overflow: TextOverflow.visible,
                    softWrap: false,
                  ),
                  onTap: () async {
                    late Widget dialog;
                    switch (value[index].modelType) {
                      case ModelType.toDo:
                        dialog = const UpdateToDoScreen();
                        toDoProvider.curToDo = value[index].toDo;
                        break;
                      case ModelType.deadline:
                        dialog = const UpdateDeadlineScreen();
                        deadlineProvider.curDeadline = value[index].deadline;
                        break;
                      case ModelType.reminder:
                        dialog = const UpdateReminderScreen();
                        reminderProvider.curReminder = value[index].reminder;
                        break;
                    }
                    await showDialog(
                        barrierDismissible: false,
                        useRootNavigator: false,
                        context: context,
                        builder: (BuildContext context) => dialog);
                  });
            });
      },
    );
  }
}

// TODO: Possibly refactor this to grab via ID? Possibly not too terrible to store the object. Come back to this.
class CalendarEvent {
  final String title;
  final ModelType modelType;
  final ToDo? toDo;
  final Deadline? deadline;
  final Reminder? reminder;

  const CalendarEvent({required this.title,
    required this.modelType,
    this.toDo,
    this.deadline,
    this.reminder});

  @override
  String toString() => "Title: $title, Type: $modelType";
}
