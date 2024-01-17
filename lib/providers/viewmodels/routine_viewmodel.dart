import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

import '../../model/task/routine.dart';
import '../../model/task/subtask.dart';
import '../../util/constants.dart';
import '../../util/interfaces/view_model.dart';
import '../../util/numbers.dart';

class RoutineViewModel extends ChangeNotifier
    with EquatableMixin
    implements ViewModel<Routine> {
  late int _id;
  late int _customViewIndex;
  late bool _isSynced;
  late bool _toDelete;
  late String _name;
  late int _weight;
  late int _expectedDuration;
  late int _realDuration;
  late int _routineTimes;
  late List<Subtask> _subtasks;
  late UniqueKey _subtaskKey;

  // CONSTRUCTORS
  RoutineViewModel()
      : _id = Constants.generateID(),
        _customViewIndex = -1,
        _isSynced = false,
        _toDelete = false,
        _name = "",
        _weight = 0,
        _expectedDuration = 0,
        _realDuration = 0,
        _routineTimes = 0,
        _subtasks = [],
        _subtaskKey = UniqueKey();

  @override
  void fromModel({required Routine model, int? times}) {
    _id = model.id;
    _customViewIndex = model.customViewIndex;
    _isSynced = model.isSynced;
    _toDelete = model.toDelete;
    _name = model.name;
    _weight = model.weight;
    _routineTimes = times ?? 0;
    _expectedDuration = model.expectedDuration;
    _realDuration = model.realDuration;
    _subtasks = model.subtasks;
    _subtaskKey = UniqueKey();
  }

  @override
  Routine toModel() => Routine(
        id: _id,
        customViewIndex: _customViewIndex,
        isSynced: _isSynced,
        toDelete: _toDelete,
        name: _name,
        weight: _weight,
        expectedDuration: _expectedDuration,
        realDuration: _realDuration,
        subtasks: _subtasks,
        lastUpdated: DateTime.now(),
      );

  @override
  void clear() {
    _id = Constants.generateID();
    _customViewIndex = -1;
    _isSynced = false;
    _toDelete = false;
    _name = "";
    _weight = 0;
    _expectedDuration = 0;
    _realDuration = 0;
    _subtasks = [];
    _routineTimes = 0;
    _subtaskKey = UniqueKey();
  }

  // CONVENIENCE METHODS
  void handleWeightChange(double? value) {
    if (null == value) {
      return;
    }
    weight = value.toInt();
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
    _realDuration = (remap(
                x: _weight,
                inMin: 0,
                inMax: Constants.medianWeight,
                outMin: Constants.lowerBound,
                outMax: Constants.upperBound) *
            _expectedDuration)
        .toInt();
  }

  // GETSET

  int get id => _id;

  set id(int newID) {
    _id = newID;
    notifyListeners();
  }

  int get customViewIndex => _customViewIndex;

  set customViewIndex(int newIndex) {
    _customViewIndex = newIndex;
    notifyListeners();
  }

  bool get isSynced => _isSynced;

  set isSynced(bool synced) {
    _isSynced = synced;
    notifyListeners();
  }

  bool get toDelete => _toDelete;

  set toDelete(bool synced) {
    _toDelete = synced;
    notifyListeners();
  }

  String get name => _name;

  set name(String newName) {
    _name = newName;
    notifyListeners();
  }

  int get weight => _weight;

  set weight(int newWeight) {
    _weight = newWeight;
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

  int get routineTimes => _routineTimes;

  set routineTimes(int times) {
    _routineTimes = times;
    notifyListeners();
  }

  set initRoutineTimes(int times) {
    _routineTimes = times;
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
