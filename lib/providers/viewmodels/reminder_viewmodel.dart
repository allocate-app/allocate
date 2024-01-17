import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import '../../model/task/reminder.dart';
import '../../util/constants.dart';
import '../../util/enums.dart';
import '../../util/interfaces/view_model.dart';

class ReminderViewModel extends ChangeNotifier
    with EquatableMixin
    implements ViewModel<Reminder> {
  late int _id;
  late int? _repeatID;
  late int? _notificationID;
  late int _customViewIndex;

  late String _name;
  late DateTime? _dueDate;
  late DateTime? _originalDue;
  late TimeOfDay? _dueTime;

  late bool _repeatable;
  late Frequency _frequency;
  late RepeatableState _repeatableState;
  late Set<int> _weekdayList;
  late int _repeatSkip;
  late UniqueKey _repeatableKey;

  late bool _isSynced;
  late bool _toDelete;

  // CONSTRUCTORS
  ReminderViewModel()
      : _id = Constants.generateID(),
        _repeatID = Constants.generateID(),
        _notificationID = Constants.generate32ID(),
        _customViewIndex = -1,
        _name = "",
        _dueDate = null,
        _originalDue = null,
        _dueTime = null,
        _repeatable = false,
        _repeatSkip = 1,
        _frequency = Frequency.once,
        _repeatableState = RepeatableState.normal,
        _weekdayList = {},
        _repeatableKey = UniqueKey(),
        _isSynced = false,
        _toDelete = false;

  @override
  void fromModel({required Reminder model}) {
    _id = model.id;
    _repeatID = model.repeatID;
    _notificationID = model.notificationID;
    _customViewIndex = model.customViewIndex;
    _name = model.name;
    _dueDate = model.dueDate;
    _originalDue = model.originalDue;
    _dueTime =
        (null != model.dueDate) ? TimeOfDay.fromDateTime(model.dueDate!) : null;
    _repeatable = model.repeatable;
    _repeatSkip = model.repeatSkip;
    _frequency = model.frequency;
    _repeatableState = model.repeatableState;
    _weekdayList = weekdaysToSet(weekdays: model.repeatDays);
    _repeatableKey = UniqueKey();
    _isSynced = model.isSynced;
    _toDelete = model.toDelete;
  }

  @override
  Reminder toModel() => Reminder(
      id: _id,
      repeatID: _repeatID,
      notificationID: _notificationID,
      customViewIndex: _customViewIndex,
      name: _name,
      dueDate: mergeDateTime(date: _dueDate, time: _dueTime),
      originalDue:
          _originalDue ?? mergeDateTime(date: _dueDate, time: _dueTime),
      repeatable: _repeatable,
      repeatSkip: _repeatSkip,
      frequency: _frequency,
      repeatableState: _repeatableState,
      repeatDays: weekdaysToList(),
      lastUpdated: DateTime.now(),
      isSynced: _isSynced,
      toDelete: _toDelete);

  @override
  void clear() {
    _id = Constants.generateID();
    _repeatID = Constants.generateID();
    _notificationID = Constants.generate32ID();
    _customViewIndex = -1;
    _name = "";
    _dueDate = null;
    _originalDue = null;
    _dueTime = null;
    _repeatable = false;
    _repeatSkip = 1;
    _frequency = Frequency.once;
    _repeatableState = RepeatableState.normal;
    _weekdayList = {};
    _repeatableKey = UniqueKey();
    _isSynced = false;
    _toDelete = false;
  }

  // CONVENIENCE METHODS
  static Set<int> weekdaysToSet({required List<bool> weekdays}) {
    Set<int> weekdaySet = {};
    for (int i = 0; i < weekdays.length; i++) {
      if (weekdays[i]) {
        weekdaySet.add(i);
      }
    }
    return weekdaySet;
  }

  List<bool> weekdaysToList() {
    List<bool> repeatDays = List.generate(7, (i) => false);
    for (int index in _weekdayList) {
      repeatDays[index] = true;
    }
    return repeatDays;
  }

  DateTime? mergeDateTime({DateTime? date, TimeOfDay? time}) {
    return date?.copyWith(hour: time?.hour, minute: time?.minute);
  }

  void clearDateTime() {
    _dueDate = null;
    _dueTime = null;
    notifyListeners();
  }

  void updateDateTime({DateTime? newDate, TimeOfDay? newTime}) {
    _dueDate = newDate?.copyWith(second: 0, millisecond: 0, microsecond: 0);
    _dueTime = newTime;
    notifyListeners();
  }

  void clearRepeatable() {
    _frequency = Frequency.once;
    _weekdayList.clear();
    _repeatSkip = 1;
    _repeatableKey = UniqueKey();
    notifyListeners();
  }

  void updateRepeatable(
      {required Frequency newFreq,
      required Set<int> newWeekdays,
      required int newSkip}) {
    _frequency = newFreq;
    _weekdayList = newWeekdays;
    _repeatSkip = newSkip;
    _repeatableKey = UniqueKey();
    notifyListeners();
  }

  // GETSET
  int get id => _id;

  set id(int newID) {
    _id = newID;
    notifyListeners();
  }

  int? get repeatID => _repeatID;

  set repeatID(int? newID) {
    _repeatID = newID;
    notifyListeners();
  }

  int? get notificationID => _notificationID;

  set notificationID(int? newID) {
    _notificationID = newID;
    notifyListeners();
  }

  int get customViewIndex => _customViewIndex;

  set customViewIndex(int newIndex) {
    _customViewIndex = newIndex;
    notifyListeners();
  }

  String get name => _name;

  set name(String newName) {
    _name = newName;
    notifyListeners();
  }

  DateTime? get originalDue => _originalDue;

  set originalDue(DateTime? newDue) {
    _originalDue = newDue;
    notifyListeners();
  }

  DateTime? get dueDate => _dueDate;

  set dueDate(DateTime? newDue) {
    _dueDate = newDue;
    notifyListeners();
  }

  TimeOfDay? get dueTime => _dueTime;

  set dueTime(TimeOfDay? newTime) {
    _dueTime = newTime;
    notifyListeners();
  }

  bool get repeatable => _repeatable;

  set repeatable(bool repeatable) {
    _repeatable = repeatable;
    notifyListeners();
  }

  Frequency get frequency => _frequency;

  set frequency(Frequency newFreq) {
    _frequency = newFreq;
    _repeatableKey = UniqueKey();
    notifyListeners();
  }

  Set<int> get weekdayList => _weekdayList;

  set weekdayList(Set<int> newWeekdayList) {
    _weekdayList = newWeekdayList;
    _repeatableKey = UniqueKey();
    notifyListeners();
  }

  int get repeatSkip => _repeatSkip;

  set repeatSkip(int newRepeatSkip) {
    _repeatSkip = newRepeatSkip;
    _repeatableKey = UniqueKey();
    notifyListeners();
  }

  UniqueKey get repeatableKey => _repeatableKey;

  RepeatableState get repeatableState => _repeatableState;

  bool get isSynced => _isSynced;

  set isSynced(bool isSynced) {
    _isSynced = isSynced;
    notifyListeners();
  }

  bool get toDelete => _toDelete;

  set toDelete(bool delete) {
    _toDelete = delete;
    notifyListeners();
  }

  @override
  List<Object?> get props => [_id];
}
