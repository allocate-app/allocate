import 'dart:collection';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../model/calendar_event.dart';
import '../../repositories/deadline_repo.dart';
import '../../repositories/reminder_repo.dart';
import '../../repositories/todo_repo.dart';
import '../../services/repeatable_service.dart';
import '../../util/constants.dart';
import '../../util/enums.dart';
import '../../util/interfaces/i_repeatable.dart';
import '../../util/interfaces/repository/model/deadline_repository.dart';
import '../../util/interfaces/repository/model/reminder_repository.dart';
import '../../util/interfaces/repository/model/todo_repository.dart';
import '../viewmodels/user_viewmodel.dart';

class EventProvider extends ChangeNotifier {
  bool generatingEvents = false;
  bool loadingEvents = false;
  bool clearing = false;

  int _totalStoredEvents = 0;
  int _totalStoredRepeatingEvents = 0;

  bool get belowEventCap => _totalStoredEvents < Constants.calendarLimit;

  bool get belowRepeatCap =>
      _totalStoredRepeatingEvents < Constants.repeatingLimit;

  // TODO: This could just be a list.
  late final ValueNotifier<List<CalendarEvent>> _selectedEvents;
  late DateTime _focusedDay;
  late DateTime? _selectedDay;

  late UserViewModel? _userModel;

  // This will need to clear & re-init hashmaps.
  set userModel(UserViewModel? newUserModel) {
    _userModel = newUserModel;
    _selectedEvents.value = getEventsForDay(_selectedDay);
    notifyListeners();
  }

  late DateTime _latest;
  late DateTime _earliest;

  ValueNotifier<List<CalendarEvent>> get selectedEvents => _selectedEvents;

  DateTime get latest => _latest;

  set latest(DateTime newLatest) {
    _latest = newLatest;
    _selectedEvents.value = getEventsForDay(_selectedDay);
    notifyListeners();
  }

  DateTime get focusedDay => _focusedDay;

  set focusedDay(DateTime newFocusedDay) {
    _focusedDay = newFocusedDay;

    DateTime testLatest =
        _focusedDay.copyWith(month: _focusedDay.month + 2, day: 0);

    DateTime testEarliest =
        _focusedDay.copyWith(month: _focusedDay.month - 1, day: 0);

    if (!testLatest.isBefore(_latest) && !generatingEvents && belowRepeatCap) {
      _latest = testLatest;
      checkRepeating(end: _latest).whenComplete(() {
        _selectedEvents.value = getEventsForDay(_selectedDay);
        notifyListeners();
      });
      return;
    }

    if (testEarliest.isBefore(_earliest) && !loadingEvents && belowEventCap) {
      DateTime previous = _earliest;
      _earliest = testEarliest;
      getCalendarEvents(start: _earliest, end: previous).whenComplete(() {
        resetSelectedEvents();
      });
      return;
    }

    notifyListeners();
  }

  DateTime? get selectedDay => _selectedDay;

  set selectedDay(DateTime? newSelectedDay) {
    _selectedDay = newSelectedDay;
    _selectedEvents.value = getEventsForDay(_selectedDay);
    notifyListeners();
  }

  // CALENDAR EVENTS
  final Map<DateTime, Set<CalendarEvent>> _events = LinkedHashMap(
    equals: isSameDay,
    hashCode: getDateTimeHashCode,
  );

  // REPEATING EVENTS
  final Map<int, Map<DateTime, IRepeatable>> _repeatingEvents = {};

  // REPOSITORIES
  late final ToDoRepository _toDoRepo;
  late final DeadlineRepository _deadlineRepo;
  late final ReminderRepository _reminderRepo;

  // REPEATABLE SERVICE
  late final RepeatableService _repeatService;

  // CONSTRUCTOR
  EventProvider(
      {DateTime? focusedDay,
      UserViewModel? userModel,
      ToDoRepository? toDoRepository,
      DeadlineRepository? deadlineRepository,
      ReminderRepository? reminderRepository})
      : _userModel = userModel,
        _repeatService = RepeatableService.instance,
        _toDoRepo = toDoRepository ?? ToDoRepo.instance,
        _deadlineRepo = deadlineRepository ?? DeadlineRepo.instance,
        _reminderRepo = reminderRepository ?? ReminderRepo.instance {
    // init dates
    _focusedDay = focusedDay ?? Constants.today;
    _selectedDay = _focusedDay;
    // Latest is 1 Month + 2 weeks at start
    _latest = _focusedDay.copyWith(year: _focusedDay.year + 1);
    // earliest is 1 month - 2 weeks before.
    _earliest = _focusedDay.copyWith(year: _focusedDay.year - 1);
    // Initialize to empty list
    _selectedEvents = ValueNotifier(getEventsForDay(_selectedDay));

    getCalendarEvents().whenComplete(() {
      resetSelectedEvents();
    });
  }

  Future<void> resetCalendar() async {
    clearing = true;
    notifyListeners();

    _events.clear();
    _repeatingEvents.clear();
    _totalStoredEvents = 0;
    _totalStoredRepeatingEvents = 0;
    _latest = _focusedDay.copyWith(year: _focusedDay.year + 1);
    _earliest = _focusedDay.copyWith(year: _focusedDay.year - 1);
    await getCalendarEvents();
    clearing = false;

    resetSelectedEvents();
  }

  void resetSelectedEvents() {
    _selectedEvents.value = getEventsForDay(_selectedDay);
    notifyListeners();
  }

  void handleDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
    }

    resetSelectedEvents();
  }

  Future<void> getCalendarEvents({DateTime? start, DateTime? end}) async {
    loadingEvents = true;
    start = start ?? _earliest;
    end = end ?? _latest;

    List<List<IRepeatable>> dataModelList = await Future.wait([
      _toDoRepo.getRange(start: start, end: end),
      _deadlineRepo.getRange(start: start, end: end),
      _reminderRepo.getRange(start: start, end: end)
    ]);

    // This is effectively as fast as batch insertion,
    // but catches repeating events.
    for (List<IRepeatable> dataModel in dataModelList) {
      for (IRepeatable model in dataModel) {
        await insertEventModel(model: model);
      }
    }
    loadingEvents = false;
  }

  Future<void> insertEventModel(
      {IRepeatable? model, bool notify = false}) async {
    if (!belowEventCap) {
      return;
    }
    if (null == model || null == model.startDate || null == model.dueDate) {
      return;
    }

    if (!(_userModel?.reduceMotion ?? false)) {
      model.fade = Fade.fadeIn;
    }
    if (!model.toDelete) {
      CalendarEvent newEvent = CalendarEvent(model: model);

      if (_events.containsKey(newEvent.startDate)) {
        if (!_events[newEvent.startDate]!.contains(newEvent)) {
          _totalStoredEvents++;
        }
        _events[newEvent.startDate]!.add(newEvent);
      } else {
        _events[newEvent.startDate] = {newEvent};
        _totalStoredEvents++;
      }
      if (_events.containsKey(newEvent.dueDate)) {
        if (!_events[newEvent.startDate]!.contains(newEvent)) {
          _totalStoredEvents++;
        }
        _events[newEvent.dueDate]!.add(newEvent);
      } else {
        _events[newEvent.dueDate] = {newEvent};
        _totalStoredEvents++;
      }
    }

    if (model.repeatable) {
      await insertRepeating(model: model, end: _latest);
    }
    if (notify) {
      resetSelectedEvents();
    }
  }

  Future<void> updateEventModel(
      {IRepeatable? oldModel,
      IRepeatable? newModel,
      bool notify = false}) async {
    if (null == oldModel ||
        null == oldModel.startDate ||
        null == oldModel.dueDate) {
      return insertEventModel(model: newModel);
    }

    if (RepeatableState.projected == oldModel.repeatableState) {
      return await updateRepeating(model: oldModel);
    }

    if (oldModel.repeatable) {
      clearRepeating(repeatID: oldModel.repeatID, notify: false);
    }

    // Remove old - notify on early escape
    removeEventModel(model: oldModel, notify: (null == newModel));

    // Insert new - repeatables will be caught & notify accordingly
    return await insertEventModel(model: newModel, notify: notify);
  }

  void removeEventModel({IRepeatable? model, bool notify = false}) {
    if (null == model || null == model.startDate || null == model.dueDate) {
      return;
    }

    // Remove old
    CalendarEvent oldEvent = CalendarEvent(model: model);
    if (_events.containsKey(oldEvent.startDate)) {
      bool removed = _events[oldEvent.startDate]!.remove(oldEvent);
      if (removed) {
        _totalStoredEvents--;
      }
    }
    if (_events.containsKey(oldEvent.dueDate)) {
      bool removed = _events[oldEvent.dueDate]!.remove(oldEvent);
      if (removed) {
        _totalStoredEvents--;
      }
    }

    // In case of negative from miscount.
    _totalStoredEvents = max(_totalStoredEvents, 0);

    if (notify) {
      resetSelectedEvents();
    }
  }

  Future<void> updateRepeating({IRepeatable? model}) async {
    if (null == model || null == model.repeatID) {
      return;
    }

    if (!_repeatingEvents.containsKey(model.repeatID!)) {
      return;
    }

    clearRepeating(repeatID: model.repeatID);

    IRepeatable? newRepeatable = switch (model.modelType) {
      ModelType.task =>
        await _toDoRepo.getNextRepeat(repeatID: model.repeatID!, now: _latest),
      ModelType.deadline => await _deadlineRepo.getNextRepeat(
          repeatID: model.repeatID!, now: _latest),
      ModelType.reminder => await _reminderRepo.getNextRepeat(
          repeatID: model.repeatID!, now: _latest),
      _ => null,
    };

    // Get the new starting
    await insertEventModel(model: newRepeatable);
    return;
  }

  Future<void> checkRepeating({DateTime? end}) async {
    end = end ?? _latest;

    for (int repeatID in _repeatingEvents.keys) {
      // Get the latest inserted repeating event.
      IRepeatable? model =
          _repeatingEvents[repeatID]!.entries.lastOrNull?.value;
      if (null == model || null == model.originalStart) {
        continue;
      }

      DateTime? startDate = model.originalStart;

      while (startDate!.isBefore(end)) {
        if (!_repeatingEvents[repeatID]!.containsKey(startDate)) {
          await insertRepeating(
            model: model,
            end: end,
          );
          return;
        }

        model = _repeatingEvents[repeatID]![startDate] ?? model;
        startDate = _repeatService.getRepeatDate(model: model);
        if (null == startDate) {
          return;
        }
      }
    }
  }

  void removeRepeating({IRepeatable? model, bool notify = false}) {
    if (null == model) {
      return;
    }
    // Get previously repeating events.
    Iterable<IRepeatable> oldModels = _repeatingEvents[model.repeatID]!.values;

    // Remove from calendar
    for (IRepeatable oldModel in oldModels) {
      if (oldModel.startDate!.isBefore(model.startDate!)) {
        continue;
      }
      removeEventModel(model: oldModel);
    }

    if (notify) {
      resetSelectedEvents();
    }
  }

  IRepeatable? clearRepeating({int? repeatID, bool notify = false}) {
    if (null == repeatID) {
      return null;
    }

    // Entries preserve their inserted order with linkedhashmap.
    // The first entry is expected to be the earliest.
    IRepeatable? model = _repeatingEvents[repeatID]?.values.firstOrNull;

    // Clear the calendar, then clear repeating.
    if (null != model) {
      removeRepeating(model: model);
    }

    Map<DateTime, IRepeatable>? entry = _repeatingEvents.remove(repeatID);
    if (null != entry) {
      _totalStoredRepeatingEvents -= entry.length;

      // In case of <0.
      _totalStoredRepeatingEvents = max(0, _totalStoredRepeatingEvents);
    }
    if (notify) {
      resetSelectedEvents();
    }
    return model;
  }

  Future<void> insertRepeating(
      {IRepeatable? model,
      DateTime? start,
      DateTime? end,
      ModelType? modelType}) async {
    generatingEvents = true;
    if (null == model) {
      notifyListeners();
      return;
    }

    end = end ?? _latest;

    if (!_repeatingEvents.containsKey(model.repeatID)) {
      _repeatingEvents[model.repeatID!] = LinkedHashMap<DateTime, IRepeatable>(
        equals: isSameDay,
        hashCode: getDateTimeHashCode,
      );
    }

    List<IRepeatable> newEvents =
        await _repeatService.populateCalendar(model: model, limit: end);

    // This is a case where the hashmap has been cleared.
    if (RepeatableState.projected == model.repeatableState) {
      newEvents.insert(0, model);
    }

    // Add each repeatable into the repeating hashmap.
    for (IRepeatable newEvent in newEvents) {
      // This is never expected to happen
      if (null == newEvent.startDate || null == newEvent.dueDate) {
        continue;
      }
      DateTime startDate = newEvent.startDate!.copyWith(
          hour: 0, minute: 0, second: 0, millisecond: 0, microsecond: 0);
      _repeatingEvents[newEvent.repeatID!]![startDate] = newEvent;
    }

    // Update the estimated hashmap entries.
    _totalStoredRepeatingEvents += newEvents.length;

    // Return the repeating events to the main calendar.
    batchUpdateEventModel(events: newEvents);

    // Allow for regeneration.
    generatingEvents = false;
  }

  void batchUpdateEventModel({List<IRepeatable>? events}) {
    if (null == events) {
      return;
    }
    for (IRepeatable eventModel in events) {
      if (!(_userModel?.reduceMotion ?? false)) {
        eventModel.fade = Fade.fadeIn;
      }

      CalendarEvent event = CalendarEvent(model: eventModel);

      if (_events.containsKey(event.startDate)) {
        _events[event.startDate]!.add(event);
      } else {
        _events[event.startDate] = {event};
      }

      if (_events.containsKey(event.dueDate)) {
        _events[event.dueDate]!.add(event);
      } else {
        _events[event.dueDate] = {event};
      }
    }
    _selectedEvents.value = getEventsForDay(_selectedDay);

    notifyListeners();
  }

  List<CalendarEvent> getEventsForDay(DateTime? day) {
    return _events[day]?.toList() ?? [];
  }

  static int getDateTimeHashCode(DateTime key) {
    return key.day * 1000000 + key.month * 10000 + key.year;
  }
}
