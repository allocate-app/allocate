import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

import '../../model/task/group.dart';
import '../../model/task/todo.dart';
import '../../util/constants.dart';
import '../../util/interfaces/view_model.dart';

class GroupViewModel extends ChangeNotifier
    with EquatableMixin
    implements ViewModel<Group> {
  // PARAMETERS
  late int _id;
  late int _customViewIndex;
  late String _name;
  late String _description;
  late bool _isSynced;
  late bool _toDelete;
  late List<ToDo> _toDos;
  late UniqueKey _toDoKey;

  // CONSTRUCTORS
  GroupViewModel()
      : _id = Constants.generateID(),
        _customViewIndex = -1,
        _name = "",
        _description = "",
        _isSynced = false,
        _toDelete = false,
        _toDos = [],
        _toDoKey = UniqueKey();

  @override
  void fromModel({required Group model}) {
    _id = model.id;
    _customViewIndex = model.customViewIndex;
    _name = model.name;
    _description = model.description;
    _isSynced = model.isSynced;
    _toDelete = model.toDelete;
    _toDos = model.toDos;
    _toDoKey = UniqueKey();
  }

  @override
  Group toModel() => Group(
        id: _id,
        customViewIndex: _customViewIndex,
        name: _name,
        description: _description,
        isSynced: _isSynced,
        toDelete: _toDelete,
        toDos: _toDos,
        lastUpdated: DateTime.now(),
      );

  @override
  void clear() {
    _id = Constants.generateID();
    _customViewIndex = -1;
    _name = "";
    _description = "";
    _isSynced = false;
    _toDelete = false;
    _toDos = [];
    _toDoKey = UniqueKey();
  }

  // CONVENIENCE METHODS

  // GETSET
  int get id => _id;

  set id(int newID) {
    _id = newID;
    notifyListeners();
  }

  int get customViewIndex => _customViewIndex;

  set customViewIndex(int newID) {
    _customViewIndex = newID;
    notifyListeners();
  }

  String get name => _name;

  set name(String newName) {
    _name = newName;
    notifyListeners();
  }

  String get description => _description;

  set description(String newName) {
    _description = newName;
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

  List<ToDo> get toDos => _toDos;

  set toDos(List<ToDo> newToDos) {
    _toDos = newToDos;
    notifyListeners();
  }

  UniqueKey get toDoKey => _toDoKey;

  @override
  List<Object?> get props => [_id];
}
