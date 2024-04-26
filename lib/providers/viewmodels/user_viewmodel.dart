// This is a wrapper class to encapsulate the User collection.

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

import '../../model/user/allocate_user.dart';
import '../../util/constants.dart';
import '../../util/enums.dart';
import '../../util/interfaces/view_model.dart';
import '../../util/sorting/deadline_sorter.dart';
import '../../util/sorting/group_sorter.dart';
import '../../util/sorting/reminder_sorter.dart';
import '../../util/sorting/routine_sorter.dart';
import '../../util/sorting/todo_sorter.dart';

class UserViewModel extends ChangeNotifier
    with EquatableMixin
    implements ViewModel<AllocateUser> {
  // INFO
  late int _id;
  late String? _uuid;
  late bool _syncOnline;
  late bool _isSynced;
  late String _username;
  late String? _email;
  late int _bandwidth;
  late DateTime _lastOpened;

  // ROUTINES
  late int? _curMornID;
  late int? _curAftID;
  late int? _curEveID;

  // THEME
  late ThemeType _themeType;
  late ToneMapping _toneMapping;
  late Effect _windowEffect;

  late int _primarySeed;
  late int? _secondarySeed;
  late int? _tertiarySeed;

  late double _sidebarOpacity;
  late double _scaffoldOpacity;

  // PREFERENCES
  late bool _checkDelete;
  late bool _checkClose;
  late bool _useUltraHighContrast;
  late bool _reduceMotion;
  late DeleteSchedule _deleteSchedule;

  // SORTING PREFERENCES
  late ToDoSorter? _toDoSorter;
  late RoutineSorter? _routineSorter;
  late ReminderSorter? _reminderSorter;
  late DeadlineSorter? _deadlineSorter;
  late GroupSorter? _groupSorter;

  // State flag
  late bool _pushUpdate;

  // CONSTRUCTORS
  UserViewModel()
      : _id = Constants.generateID(),
        _uuid = null,
        _syncOnline = false,
        _isSynced = false,
        _username = Constants.defaultUsername,
        _email = null,
        _bandwidth = Constants.maxBandwidth ~/ 2,
        _lastOpened = DateTime.now(),
        _curMornID = null,
        _curAftID = null,
        _curEveID = null,
        _themeType = ThemeType.system,
        _toneMapping = ToneMapping.system,
        _windowEffect = Constants.defaultWindowEffect,
        _primarySeed = Constants.defaultPrimaryColorSeed,
        _secondarySeed = null,
        _tertiarySeed = null,
        _sidebarOpacity = Constants.defaultSidebarOpacity,
        _scaffoldOpacity = Constants.defaultScaffoldOpacity,
        _checkClose = true,
        _checkDelete = true,
        _useUltraHighContrast = false,
        _reduceMotion = false,
        _deleteSchedule = DeleteSchedule.thirtyDays,
        _toDoSorter = ToDoSorter(),
        _routineSorter = RoutineSorter(),
        _reminderSorter = ReminderSorter(),
        _deadlineSorter = DeadlineSorter(),
        _groupSorter = GroupSorter(),
        _pushUpdate = false;

  @override
  void fromModel({required AllocateUser model, bool pushUpdate = false}) {
    _id = model.id;
    _uuid = model.uuid;
    _syncOnline = model.syncOnline;
    _isSynced = model.isSynced;
    _username = model.username;
    _email = model.email;
    _bandwidth = model.bandwidth;
    _lastOpened = model.lastOpened;

    _curMornID = model.curMornID;
    _curAftID = model.curAftID;
    _curEveID = model.curEveID;

    _themeType = model.themeType;
    _toneMapping = model.toneMapping;
    _windowEffect = model.windowEffect;
    _primarySeed = model.primarySeed;
    _secondarySeed = model.secondarySeed;
    _tertiarySeed = model.tertiarySeed;
    _sidebarOpacity = model.sidebarOpacity;
    _scaffoldOpacity = model.scaffoldOpacity;

    _checkDelete = model.checkDelete;
    _checkClose = model.checkClose;
    _useUltraHighContrast = model.useUltraHighContrast;
    _reduceMotion = model.reduceMotion;
    _deleteSchedule = model.deleteSchedule;

    _toDoSorter = model.toDoSorter;
    _routineSorter = model.routineSorter;
    _reminderSorter = model.reminderSorter;
    _deadlineSorter = model.deadlineSorter;
    _groupSorter = model.groupSorter;
    _pushUpdate = pushUpdate;
    notifyListeners();
  }

  @override
  void clear() {
    _id = Constants.generateID();
    _uuid = null;
    _syncOnline = false;
    _isSynced = false;
    _username = Constants.defaultUsername;
    _email = null;
    _bandwidth = Constants.maxBandwidth ~/ 2;
    _lastOpened = DateTime.now();
    _curMornID = null;
    _curAftID = null;
    _curEveID = null;
    _themeType = ThemeType.system;
    _toneMapping = ToneMapping.system;
    _windowEffect = Constants.defaultWindowEffect;
    _primarySeed = Constants.defaultPrimaryColorSeed;
    _secondarySeed = null;
    _tertiarySeed = null;
    _sidebarOpacity = Constants.defaultSidebarOpacity;
    _scaffoldOpacity = Constants.defaultScaffoldOpacity;
    _checkClose = true;
    _checkDelete = true;
    _useUltraHighContrast = false;
    _reduceMotion = false;
    _deleteSchedule = DeleteSchedule.thirtyDays;
    _toDoSorter = ToDoSorter();
    _routineSorter = RoutineSorter();
    _reminderSorter = ReminderSorter();
    _deadlineSorter = DeadlineSorter();
    _groupSorter = GroupSorter();
    _pushUpdate = false;
    notifyListeners();
  }

  @override
  AllocateUser toModel() => AllocateUser(
        id: _id,
        uuid: _uuid,
        syncOnline: _syncOnline,
        isSynced: _isSynced,
        username: _username,
        email: _email,
        bandwidth: _bandwidth,
        lastOpened: _lastOpened,
        lastUpdated: DateTime.now(),
        curMornID: _curMornID,
        curAftID: _curAftID,
        curEveID: _curEveID,
        themeType: _themeType,
        toneMapping: _toneMapping,
        windowEffect: _windowEffect,
        primarySeed: _primarySeed,
        secondarySeed: _secondarySeed,
        tertiarySeed: _tertiarySeed,
        sidebarOpacity: _sidebarOpacity,
        scaffoldOpacity: _scaffoldOpacity,
        checkDelete: _checkDelete,
        checkClose: _checkClose,
        useUltraHighContrast: _useUltraHighContrast,
        reduceMotion: _reduceMotion,
        deleteSchedule: _deleteSchedule,
        toDoSorter: _toDoSorter,
        routineSorter: _routineSorter,
        reminderSorter: _reminderSorter,
        deadlineSorter: _deadlineSorter,
        groupSorter: _groupSorter,
      );

  // GET/SET
  // INFO
  int get id => _id;

  set id(int id) {
    _id = id;
    _pushUpdate = true;
    notifyListeners();
  }

  String? get uuid => _uuid;

  set uuid(String? uuid) {
    _uuid = uuid;
    _pushUpdate = true;
    notifyListeners();
  }

  bool get syncOnline => _syncOnline;

  set syncOnline(bool syncOnline) {
    _syncOnline = syncOnline;
    _pushUpdate = true;
    notifyListeners();
  }

  bool get isSynced => _isSynced;

  set isSynced(bool isSynced) {
    _isSynced = isSynced;
    notifyListeners();
  }

  String get username => _username;

  set username(String username) {
    _username = username;
    _pushUpdate = true;
    notifyListeners();
  }

  String? get email => _email;

  set email(String? email) {
    _email = email;
    _pushUpdate = true;
    notifyListeners();
  }

  int get bandwidth => _bandwidth;

  set bandwidth(int bandwidth) {
    _bandwidth = bandwidth;
    notifyListeners();
  }

  DateTime get lastOpened => _lastOpened;

  set lastOpened(DateTime lastOpened) {
    _lastOpened = lastOpened;
    _pushUpdate = true;
    notifyListeners();
  }

  // ROUTINES
  int? get curMornID => _curMornID;

  set curMornID(int? newID) {
    _curMornID = newID;
    _pushUpdate = true;
    notifyListeners();
  }

  int? get curAftID => _curAftID;

  set curAftID(int? curAftID) {
    _curAftID = curAftID;
    _pushUpdate = true;
    notifyListeners();
  }

  int? get curEveID => _curEveID;

  set curEveID(int? curEveID) {
    _curEveID = curEveID;
    _pushUpdate = true;
    notifyListeners();
  }

  //THEME
  ThemeType get themeType => _themeType;

  set themeType(ThemeType themeType) {
    _themeType = themeType;
    _pushUpdate = true;
    notifyListeners();
  }

  ToneMapping get toneMapping => _toneMapping;

  set toneMapping(ToneMapping toneMapping) {
    _toneMapping = toneMapping;
    _pushUpdate = true;
    notifyListeners();
  }

  Effect get windowEffect => _windowEffect;

  set windowEffect(Effect windowEffect) {
    _windowEffect = windowEffect;
    _pushUpdate = true;
    notifyListeners();
  }

  int get primarySeed => _primarySeed;

  set primarySeed(int primarySeed) {
    _primarySeed = primarySeed;
    _pushUpdate = true;
    notifyListeners();
  }

  int? get secondarySeed => _secondarySeed;

  set secondarySeed(int? secondarySeed) {
    _secondarySeed = secondarySeed;
    _pushUpdate = true;
    notifyListeners();
  }

  int? get tertiarySeed => _tertiarySeed;

  set tertiarySeed(int? tertiarySeed) {
    _tertiarySeed = tertiarySeed;
    _pushUpdate = true;
    notifyListeners();
  }

  double get sidebarOpacity => _sidebarOpacity;

  set sidebarOpacity(double sidebarOpacity) {
    _sidebarOpacity = sidebarOpacity;
    notifyListeners();
  }

  double get scaffoldOpacity => _scaffoldOpacity;

  set scaffoldOpacity(double scaffoldOpacity) {
    _scaffoldOpacity = scaffoldOpacity;
    notifyListeners();
  }

  // PREFERENCES
  bool get checkDelete => _checkDelete;

  set checkDelete(bool checkDelete) {
    _checkDelete = checkDelete;
    _pushUpdate = true;
    notifyListeners();
  }

  bool get checkClose => _checkClose;

  set checkClose(bool check) {
    _checkClose = check;
    _pushUpdate = true;
    notifyListeners();
  }

  bool get useUltraHighContrast => _useUltraHighContrast;

  set useUltraHighContrast(bool useUltraHighContrast) {
    _useUltraHighContrast = useUltraHighContrast;
    _pushUpdate = true;
    notifyListeners();
  }

  bool get reduceMotion => _reduceMotion;

  set reduceMotion(bool reduceMotion) {
    _reduceMotion = reduceMotion;
    _pushUpdate = true;
    notifyListeners();
  }

  DeleteSchedule get deleteSchedule => _deleteSchedule;

  set deleteSchedule(DeleteSchedule deleteSchedule) {
    _deleteSchedule = deleteSchedule;
    _pushUpdate = true;
    notifyListeners();
  }

  DateTime? get deleteDate {
    return switch (_deleteSchedule) {
      DeleteSchedule.fifteenDays =>
        Constants.today.copyWith(day: Constants.today.day - 15),
      DeleteSchedule.thirtyDays =>
        Constants.today.copyWith(day: Constants.today.day - 30),
      DeleteSchedule.oneYear =>
        Constants.today.copyWith(year: Constants.today.year - 1),
      _ => null,
    };
  }

  // SORTING PREFERENCES
  ToDoSorter? get toDoSorter => _toDoSorter;

  set toDoSorter(ToDoSorter? toDoSorter) {
    _toDoSorter = toDoSorter;
    _pushUpdate = true;
    notifyListeners();
  }

  RoutineSorter? get routineSorter => _routineSorter;

  set routineSorter(RoutineSorter? routineSorter) {
    _routineSorter = routineSorter;
    _pushUpdate = true;
    notifyListeners();
  }

  ReminderSorter? get reminderSorter => _reminderSorter;

  set reminderSorter(ReminderSorter? reminderSorter) {
    _reminderSorter = reminderSorter;
    _pushUpdate = true;
    notifyListeners();
  }

  DeadlineSorter? get deadlineSorter => _deadlineSorter;

  set deadlineSorter(DeadlineSorter? newSorter) {
    _deadlineSorter = newSorter;
    _pushUpdate = true;
    notifyListeners();
  }

  GroupSorter? get groupSorter => _groupSorter;

  set groupSorter(GroupSorter? groupSorter) {
    _groupSorter = groupSorter;
    _pushUpdate = true;
    notifyListeners();
  }

  bool get pushUpdate => _pushUpdate;

  set pushUpdate(bool update) {
    _pushUpdate = update;
    // I don't thiiink this should notify?
  }

  @override
  List<Object?> get props => [_id];

  @override
  toString() =>
      "id: $id, uuid: $uuid, syncOnline: $syncOnline, lastOpened: $lastOpened ";
}
