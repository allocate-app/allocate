import 'package:flutter/foundation.dart';

import '../../model/task/subtask.dart';
import '../../util/constants.dart';
import '../../util/interfaces/view_model.dart';

class SubtaskViewModel extends ChangeNotifier implements ViewModel<Subtask> {
  late int _id;
  late String _name;
  late int _weight;
  late bool _completed;
  late int? _taskID;
  late int _customViewIndex;
  late bool _isSynced;
  late bool _toDelete;

  // CONSTRUCTORS
  SubtaskViewModel()
      : _id = Constants.generateID(),
        _name = "",
        _weight = 0,
        _completed = false,
        _taskID = null,
        _customViewIndex = -1,
        _isSynced = false,
        _toDelete = false;

  @override
  void fromModel({required Subtask model}) {
    _id = model.id;
    _name = model.name;
    _weight = model.weight;
    _completed = model.completed;
    _taskID = model.taskID;
    _customViewIndex = model.customViewIndex;
    _isSynced = model.isSynced;
    _toDelete = model.toDelete;
  }

  @override
  Subtask toModel() => Subtask(
        id: _id,
        name: _name,
        weight: _weight,
        completed: _completed,
        taskID: _taskID,
        customViewIndex: _customViewIndex,
        isSynced: _isSynced,
        toDelete: _toDelete,
        lastUpdated: DateTime.now(),
      );

  @override
  void clear() {
    _id = Constants.generateID();
    _name = "";
    _weight = 0;
    _completed = false;
    _taskID = null;
    _customViewIndex = -1;
    _isSynced = false;
    _toDelete = false;
  }

  // GETSET
  int get id => _id;

  set id(int id) {
    _id = id;
    notifyListeners();
  }

  String get name => _name;

  set name(String name) {
    _name = name;
    notifyListeners();
  }

  int get weight => _weight;

  set weight(int weight) {
    _weight = weight;
    notifyListeners();
  }

  bool get completed => _completed;

  set completed(bool completed) {
    _completed = completed;
    notifyListeners();
  }

  int? get taskID => _taskID;

  set taskID(int? newID) {
    _taskID = newID;
    // notifyListeners();
  }

  int get customViewIndex => _customViewIndex;

  set customViewIndex(int customViewIndex) {
    _customViewIndex = customViewIndex;
    notifyListeners();
  }

  bool get isSynced => _isSynced;

  set isSynced(bool isSynced) {
    _isSynced = isSynced;
    notifyListeners();
  }

  bool get toDelete => _toDelete;

  set toDelete(bool toDelete) {
    _toDelete = toDelete;
    notifyListeners();
  }
}
