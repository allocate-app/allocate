import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import '../../model/task/subtask.dart';
import '../../model/task/todo.dart';
import '../../util/constants.dart';
import '../../util/enums.dart';
import '../../util/interfaces/view_model.dart';
import '../../util/numbers.dart';

class ToDoViewModel extends ChangeNotifier
    with EquatableMixin
    implements ViewModel<ToDo> {
  late int _id;
  late int? _groupID;
  late int? _repeatID;

  late int _groupIndex;
  late int _customViewIndex;

  late TaskType _taskType;

  late String _name;
  late String _description;
  late int _weight;
  late int _sumWeight;
  late int _expectedDuration;
  late int _realDuration;

  late Priority _priority;
  late bool _completed;

  late DateTime? _startDate;
  late DateTime? _originalStart;
  late TimeOfDay? _startTime;

  late DateTime? _dueDate;
  late DateTime? _originalDue;
  late TimeOfDay? _dueTime;

  late bool _myDay;

  late bool _repeatable;
  late Frequency _frequency;
  late RepeatableState _repeatableState;
  late Set<int> _weekdayList;
  late int _repeatSkip;
  late UniqueKey _repeatableKey;

  late bool _isSynced;
  late bool _toDelete;

  late List<Subtask> _subtasks;
  late UniqueKey _subtaskKey;

  // CONSTRUCTORS
  ToDoViewModel()
      : _id = Constants.generateID(),
        _groupID = null,
        _repeatID = Constants.generateID(),
        _customViewIndex = -1,
        _groupIndex = -1,
        _taskType = TaskType.small,
        _name = "",
        _description = "",
        _weight = 0,
        _sumWeight = 0,
        _expectedDuration = 0,
        _realDuration = 0,
        _priority = Priority.low,
        _completed = false,
        _startDate = null,
        _startTime = null,
        _originalStart = null,
        _dueDate = null,
        _originalDue = null,
        _dueTime = null,
        _myDay = false,
        _repeatable = false,
        _frequency = Frequency.once,
        _repeatableState = RepeatableState.normal,
        _weekdayList = {},
        _repeatSkip = 1,
        _repeatableKey = UniqueKey(),
        _isSynced = false,
        _toDelete = false,
        _subtasks = [],
        _subtaskKey = UniqueKey();

  @override
  void fromModel({required ToDo model}) {
    _id = model.id;
    _groupID = model.groupID;
    _repeatID = model.repeatID;
    _groupIndex = model.groupIndex;
    _customViewIndex = model.customViewIndex;
    _taskType = model.taskType;
    _name = model.name;
    _description = model.description;
    _weight = (TaskType.small == model.taskType) ? model.weight : 0;
    _sumWeight = (TaskType.small == model.taskType) ? 0 : model.weight;
    _expectedDuration = model.expectedDuration;
    _realDuration = model.realDuration;
    _priority = model.priority;
    _completed = model.completed;
    _startDate = model.startDate;
    _startTime = (null != model.startDate)
        ? TimeOfDay.fromDateTime(model.startDate!)
        : null;
    _originalStart = model.originalStart;
    _dueDate = model.dueDate;
    _dueTime = (null != model.dueDate)
        ? TimeOfDay.fromDateTime(model.startDate!)
        : null;
    _originalDue = model.originalDue;
    _myDay = model.myDay;
    _repeatable = model.repeatable;
    _frequency = model.frequency;
    _repeatableState = model.repeatableState;
    _weekdayList = weekdaysToSet(weekdays: model.repeatDays);
    _repeatSkip = model.repeatSkip;
    _isSynced = model.isSynced;
    _toDelete = model.toDelete;
    _subtasks = model.subtasks;
    _subtaskKey = UniqueKey();
  }

  @override
  void clear() {
    _id = Constants.generateID();
    _groupID = null;
    _repeatID = Constants.generateID();
    _customViewIndex = -1;
    _groupIndex = -1;
    _taskType = TaskType.small;
    _name = "";
    _description = "";
    _weight = 0;
    _sumWeight = 0;
    _expectedDuration = 0;
    _realDuration = 0;
    _priority = Priority.low;
    _completed = false;
    _startDate = null;
    _startTime = null;
    _originalStart = null;
    _dueDate = null;
    _originalDue = null;
    _dueTime = null;
    _myDay = false;
    _repeatable = false;
    _frequency = Frequency.once;
    _repeatableState = RepeatableState.normal;
    _weekdayList = {};
    _repeatSkip = 1;
    _isSynced = false;
    _toDelete = false;
    _subtasks = [];
    _subtaskKey = UniqueKey();
  }

  @override
  ToDo toModel() => ToDo(
        id: _id,
        groupID: _groupID,
        repeatID: _repeatID,
        groupIndex: _groupIndex,
        customViewIndex: _customViewIndex,
        taskType: _taskType,
        name: _name,
        description: _description,
        weight: (TaskType.small == _taskType) ? _weight : _sumWeight,
        expectedDuration: _expectedDuration,
        realDuration: _realDuration,
        priority: _priority,
        completed: _completed,
        startDate: mergeDateTime(date: _startDate, time: _startTime),
        originalStart: _originalStart ?? _startDate,
        dueDate: mergeDateTime(date: _dueDate, time: _dueTime),
        originalDue: _originalDue ?? _dueDate,
        myDay: _myDay,
        repeatable: _repeatable,
        frequency: _frequency,
        repeatableState: _repeatableState,
        repeatDays: weekdaysToList(),
        repeatSkip: _repeatSkip,
        isSynced: _isSynced,
        toDelete: _toDelete,
        lastUpdated: DateTime.now(),
        subtasks: _subtasks,
      );

  // Convenience methods
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

  void completeToDo(bool? value) {
    if (null == value) {
      return;
    }
    completed = !_completed;
  }

  void handleWeightChange(double? value) {
    if (null == value) {
      return;
    }
    weight = value.toInt();
  }

  void toggleMyDay() {
    myDay = !_myDay;
  }

  void updatePriority(Set<Priority> newPriority) {
    priority = newPriority.first;
  }

  void clearDuration() {
    expectedDuration = 0;
  }

  void updateDuration(
    int? newDuration,
  ) {
    expectedDuration = newDuration ?? _expectedDuration;
  }

  void _setRealDuration() {
    int w = (TaskType.small == _taskType) ? _weight : _sumWeight;
    _realDuration = (remap(
                x: w,
                inMin: 0,
                inMax: Constants.medianWeight,
                outMin: Constants.lowerBound,
                outMax: Constants.upperBound) *
            _expectedDuration)
        .toInt();
  }

  void clearDates() {
    _startDate = null;
    _dueDate = null;
    notifyListeners();
  }

  void updateDates({
    DateTime? newStart,
    DateTime? newDue,
  }) {
    _startDate = newStart?.copyWith(second: 0, millisecond: 0, microsecond: 0);
    _dueDate = newDue?.copyWith(second: 0, millisecond: 0, microsecond: 0);
    notifyListeners();
  }

  void clearTimes() {
    _startTime = null;
    _dueTime = null;
    notifyListeners();
  }

  void updateTimes({TimeOfDay? newStart, TimeOfDay? newDue}) {
    _startTime = newStart;
    _dueTime = newDue;
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

  int? get groupID => _groupID;

  set groupID(int? newID) {
    _groupID = newID;
    notifyListeners();
  }

  set initGroupID(int? newID) {
    _groupID = newID;
  }

  int? get repeatID => _repeatID;

  set repeatID(int? newID) {
    _repeatID = newID;
    notifyListeners();
  }

  int get groupIndex => _groupIndex;

  set groupIndex(int newIndex) {
    _groupIndex = newIndex;
    notifyListeners();
  }

  int get customViewIndex => _customViewIndex;

  set customViewIndex(int newIndex) {
    _customViewIndex = newIndex;
    notifyListeners();
  }

  TaskType get taskType => _taskType;

  set taskType(TaskType newType) {
    _taskType = newType;
    _setRealDuration();
    notifyListeners();
  }

  String get name => _name;

  set name(String newName) {
    _name = newName;
    notifyListeners();
  }

  String get description => _description;

  set description(String newDescription) {
    _description = newDescription;
    notifyListeners();
  }

  int get weight => (TaskType.small == _taskType) ? _weight : _sumWeight;

  set weight(int newWeight) {
    if (TaskType.small == _taskType) {
      _weight = newWeight;
    } else {
      _sumWeight = newWeight;
    }
    _setRealDuration();
    notifyListeners();
  }

  int get expectedDuration => _expectedDuration;

  set expectedDuration(int duration) {
    _expectedDuration = duration;
    _setRealDuration();
    notifyListeners();
  }

  int get realDuration => _realDuration;

  Priority get priority => _priority;

  set priority(Priority priority) {
    _priority = priority;
    notifyListeners();
  }

  bool get completed => _completed;

  set completed(bool completed) {
    _completed = completed;
    notifyListeners();
  }

  DateTime? get startDate => _startDate;

  set startDate(DateTime? newStart) {
    _startDate = newStart;
    notifyListeners();
  }

  DateTime? get originalStart => _originalStart;

  set originalStart(DateTime? newStart) {
    _originalStart = newStart;
    notifyListeners();
  }

  TimeOfDay? get startTime => _startTime;

  set startTime(TimeOfDay? newTime) {
    _startTime = newTime;
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

  bool get myDay => _myDay;

  set myDay(bool myDay) {
    _myDay = myDay;
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

  List<Subtask> get subtasks => _subtasks;

  set subtasks(List<Subtask> newSubtasks) {
    _subtasks = newSubtasks;
    _subtaskKey = UniqueKey();
    notifyListeners();
  }

  UniqueKey get subtaskKey => _subtaskKey;

  @override
  List<Object?> get props => [_id];
}
