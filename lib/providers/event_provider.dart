import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:table_calendar/table_calendar.dart';

import '../model/calendar_event.dart';
import '../model/task/todo.dart';
import '../model/user/user_model.dart';
import '../util/constants.dart';
import '../util/enums.dart';
import '../util/interfaces/i_repeatable.dart';

class EventProvider extends ChangeNotifier {
  // TODO: This could just be a list.
  late final ValueNotifier<List<CalendarEvent>> _selectedEvents;
  late DateTime _focusedDay;
  late DateTime? _selectedDay;

  // Bring in the repositories? Or possibly just query.
  // late final ToDoRepository toDoRepo = ToDoRepo.instance;
  // Maybe keep a ptr to usrmodel

  // TODO: implement USERMODEL, IMPLEMENT PROXYPROVIDERS
  late UserModel? _userModel;

  set userModel(UserModel? newUserModel) {
    _userModel = newUserModel;
    notifyListeners();
  }

  late DateTime _latest;

  ValueNotifier<List<CalendarEvent>> get selectedEvents => _selectedEvents;

  DateTime get latest => _latest;

  set latest(DateTime newLatest) {
    _latest = newLatest;
    notifyListeners();
  }

  EventProvider({DateTime? focusedDay, UserModel? userModel})
      : _focusedDay = focusedDay ?? Constants.today,
        _selectedDay = focusedDay ?? Constants.today,
        _latest = (focusedDay ?? Constants.today).copyWith(),
        _userModel = userModel {
    _selectedEvents = ValueNotifier(getEventsForDay(_selectedDay));
  }

  void handleDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
    }
    _selectedEvents.value = getEventsForDay(_selectedDay);
    notifyListeners();
  }

  // TODO: implement a reset function.
  // ie.

  // TODO: read reducemotion from userModel
  void updateEventModel(
      {List<IRepeatable>? events, bool reduceMotion = false}) {
    if (null == events) {
      return;
    }
    for (IRepeatable eventModel in events) {
      if (ModelType.task == eventModel.modelType &&
          (eventModel as ToDo).myDay) {
        eventModel.startDate = eventModel.startDate ?? Constants.today;
        eventModel.dueDate = eventModel.dueDate ?? Constants.today;
      }

      DateTime startDay = eventModel.startDate!.copyWith(
          hour: 0, minute: 0, second: 0, millisecond: 0, microsecond: 0);

      DateTime dueDay = eventModel.dueDate!.copyWith(
          hour: 0, minute: 0, second: 0, millisecond: 0, microsecond: 0);

      if (!reduceMotion) {
        eventModel.fade = Fade.fadeIn;
      }

      CalendarEvent event = CalendarEvent(model: eventModel);

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

    notifyListeners();
  }

  final Map<DateTime, Set<CalendarEvent>> _events = LinkedHashMap(
    equals: isSameDay,
    hashCode: getDateTimeHashCode,
  );

  List<CalendarEvent> getEventsForDay(DateTime? day) {
    return _events[day]?.toList() ?? [];
  }

  static int getDateTimeHashCode(DateTime key) {
    return key.day * 1000000 + key.month * 10000 + key.year;
  }
}
