import 'dart:collection';

import 'package:allocate/ui/views/sub_views/update_deadline.dart';
import 'package:allocate/ui/views/sub_views/update_reminder.dart';
import 'package:allocate/ui/views/sub_views/update_todo.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:equatable/equatable.dart';
import "package:flutter/material.dart";
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

// TODO: Make calendar population more efficient -> Add an optional start date to method in service classes.
class _CalendarScreen extends State<CalendarScreen> {
  late final ValueNotifier<List<CalendarEvent>> _selectedEvents;
  late final LinkedHashMap<DateTime, Set<CalendarEvent>> _events;

  late final CalendarFormat calendarFormat;
  late DateTime _focusedDay;
  DateTime? _selectedDay;

  late DateTime latest;

  late final HeaderStyle headerStyle = const HeaderStyle(
      formatButtonVisible: false, titleTextStyle: Constants.headerStyle);

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

  @override
  void initState() {
    super.initState();
    initializeProviders();
    initializeParameters();
    resetEvents();
  }

  void initializeProviders() {
    toDoProvider = Provider.of(context, listen: false);
    reminderProvider = Provider.of(context, listen: false);
    deadlineProvider = Provider.of(context, listen: false);

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
            minute: Constants.midnight.minute);
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
    });
  }

  Future<void> getEvents({DateTime? day, DateTime? end}) async {
    day = day ?? Constants.today.copyWith(day: 1);

    end = end ?? day.copyWith(month: day.month + 1);
    await Future.wait([
      getToDoEvents(start: day, end: end),
      getDeadlineEvents(start: day, end: end),
      getReminderEvents(start: day, end: end),
    ]);
  }

  Future<void> getToDoEvents({DateTime? start, DateTime? end}) async {
    start = start ?? Constants.today.copyWith(day: 1);

    end = end ?? start.copyWith(month: start.month + 1);

    List<ToDo> toDos =
        await toDoProvider.getToDosBetween(start: start, end: end);

    for (ToDo toDo in toDos) {
      DateTime startDay = toDo.startDate.copyWith(
          hour: Constants.midnight.hour, minute: Constants.midnight.minute);
      DateTime dueDay = toDo.dueDate.copyWith(
          hour: Constants.midnight.hour, minute: Constants.midnight.minute);

      CalendarEvent startEvent = CalendarEvent(
          title: "Start: ${toDo.name}", modelType: ModelType.toDo, toDo: toDo);
      CalendarEvent dueEvent = CalendarEvent(
          title: "Due: ${toDo.name}", modelType: ModelType.toDo, toDo: toDo);

      if (_events.containsKey(startDay)) {
        _events[startDay]!.add(startEvent);
      } else {
        _events[startDay] = {startEvent};
      }

      if (_events.containsKey(dueDay)) {
        _events[dueDay]!.add(dueEvent);
      } else {
        _events[dueDay] = {dueEvent};
      }
    }
  }

  Future<void> getDeadlineEvents({DateTime? start, DateTime? end}) async {
    start = start ?? Constants.today.copyWith(day: 1);
    end = end ?? start.copyWith(month: start.month + 1);

    List<Deadline> deadlines =
        await deadlineProvider.getDeadlinesBetween(start: start, end: end);

    for (Deadline deadline in deadlines) {
      DateTime day = deadline.dueDate.copyWith(
          hour: Constants.midnight.hour, minute: Constants.midnight.minute);
      CalendarEvent event = CalendarEvent(
          title: deadline.name,
          modelType: ModelType.deadline,
          deadline: deadline);
      if (_events.containsKey(day)) {
        _events[day]!.add(event);
      } else {
        _events[day] = {event};
      }
    }
  }

  Future<void> getReminderEvents({DateTime? start, DateTime? end}) async {
    start = start ?? Constants.today.copyWith(day: 1);
    end = end ?? start.copyWith(month: start.month + 1);

    List<Reminder> reminders =
        await reminderProvider.getRemindersBetween(start: start, end: end);

    for (Reminder reminder in reminders) {
      DateTime day = reminder.dueDate.copyWith(
          hour: Constants.midnight.hour, minute: Constants.midnight.minute);
      CalendarEvent event = CalendarEvent(
          title: reminder.name,
          modelType: ModelType.reminder,
          reminder: reminder);
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
  void dispose() {
    toDoProvider.removeListener(resetEvents);
    reminderProvider.removeListener(resetEvents);
    deadlineProvider.removeListener(resetEvents);
    super.dispose();
  }

  Widget getModelIcon({required ModelType modelType}) {
    Icon icon = switch (modelType) {
      ModelType.toDo => const Icon(Icons.task_rounded),
      ModelType.deadline => const Icon(Icons.announcement_rounded),
      ModelType.reminder => const Icon(Icons.push_pin_rounded),
    };

    return DecoratedBox(
      decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
              color: Theme.of(context).colorScheme.outline,
              strokeAlign: BorderSide.strokeAlignOutside)),
      child: Padding(
        padding: const EdgeInsets.all(Constants.padding),
        child: icon,
      ),
    );
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
        Expanded(child: buildEventTile())
      ],
    );
  }

  Widget buildEventTile() {
    return ValueListenableBuilder<List<CalendarEvent>>(
      valueListenable: _selectedEvents,
      builder:
          (BuildContext context, List<CalendarEvent> value, Widget? child) {
        return ListView.builder(
            itemCount: value.length,
            itemBuilder: (BuildContext context, int index) {
              return Padding(
                padding: const EdgeInsets.all(Constants.halfPadding),
                child: ListTile(
                    shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(
                            Radius.circular(Constants.roundedCorners))),
                    leading: getModelIcon(modelType: value[index].modelType),
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
                    }),
              );
            });
      },
    );
  }
}

// TODO: Possibly refactor this to grab via ID? Possibly not too terrible to store the object. Come back to this.
class CalendarEvent with EquatableMixin {
  final String title;
  final ModelType modelType;
  final ToDo? toDo;
  final Deadline? deadline;
  final Reminder? reminder;

  const CalendarEvent(
      {required this.title,
      required this.modelType,
      this.toDo,
      this.deadline,
      this.reminder});

  @override
  String toString() => "Title: $title, Type: $modelType";

  @override
  List<Object?> get props => [title, modelType];
}
