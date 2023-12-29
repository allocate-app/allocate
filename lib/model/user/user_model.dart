// This is a wrapper class to encapsulate the User collection.

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

import '../../util/enums.dart';
import '../../util/sorting/group_sorter.dart';
import '../../util/sorting/reminder_sorter.dart';
import '../../util/sorting/routine_sorter.dart';
import '../../util/sorting/todo_sorter.dart';
import 'user.dart';

class UserModel extends ChangeNotifier with EquatableMixin {
  final User? _user;

  UserModel({User? user}) : _user = user;

  User? get user => _user;

  int? get id => _user?.id;

  set id(int? id) {
    if (null == id) {
      return;
    }
    _user?.id = id;
    notifyListeners();
  }

  String? get uuid => _user?.uuid;

  set uuid(String? uuid) {
    _user?.uuid = uuid;
    notifyListeners();
  }

  bool? get syncOnline => _user?.syncOnline;

  set syncOnline(bool? syncOnline) {
    if (null == syncOnline) {
      return;
    }
    _user?.syncOnline = syncOnline;
    notifyListeners();
  }

  bool? get isSynced => _user?.isSynced;

  set isSynced(bool? isSynced) {
    if (null == isSynced) {
      return;
    }
    _user?.isSynced = isSynced;
    notifyListeners();
  }

  bool? get checkDelete => _user?.checkDelete;

  set checkDelete(bool? checkDelete) {
    if (null == checkDelete) {
      return;
    }
    _user?.checkDelete = checkDelete;
    notifyListeners();
  }

  String? get userName => _user?.userName;

  set userName(String? userName) {
    if (null == userName) {
      return;
    }
    _user?.userName = userName;
    notifyListeners();
  }

  int? get bandwidth => _user?.bandwidth;

  set bandwidth(int? bandwidth) {
    if (null == bandwidth) {
      return;
    }
    _user?.bandwidth = bandwidth;
    notifyListeners();
  }

  int? get dayCost => _user?.dayCost;

  set dayCost(int? dayCost) {
    if (null == dayCost) {
      return;
    }
    _user?.dayCost = dayCost;
    notifyListeners();
  }

  ThemeType? get themeType => _user?.themeType;

  set themeType(ThemeType? themeType) {
    if (null == themeType) {
      return;
    }
    _user?.themeType = themeType;
    notifyListeners();
  }

  ToneMapping? get toneMapping => _user?.toneMapping;

  set toneMapping(ToneMapping? toneMapping) {
    if (null == toneMapping) {
      return;
    }
    _user?.toneMapping = toneMapping;
  }

  Effect? get windowEffect => _user?.windowEffect;

  set windowEffect(Effect? windowEffect) {
    if (null == windowEffect) {
      return;
    }
    _user?.windowEffect = windowEffect;
    notifyListeners();
  }

  int? get primarySeed => _user?.primarySeed;

  set primarySeed(int? primarySeed) {
    if (null == primarySeed) {
      return;
    }
    _user?.primarySeed = primarySeed;
    notifyListeners();
  }

  int? get secondarySeed => _user?.secondarySeed;

  set secondarySeed(int? secondarySeed) {
    _user?.secondarySeed = secondarySeed;
    notifyListeners();
  }

  int? get tertiarySeed => _user?.tertiarySeed;

  set teriarySeed(int? tertiarySeed) {
    _user?.tertiarySeed = tertiarySeed;
    notifyListeners();
  }

  double? get sidebarOpacity => _user?.sidebarOpacity;

  set sidebarOpacity(double? sidebarOpacity) {
    _user?.sidebarOpacity = sidebarOpacity;
    notifyListeners();
  }

  double? get scaffoldOpacity => _user?.scaffoldOpacity;

  set scaffoldOpacity(double? scaffoldOpacity) {
    _user?.scaffoldOpacity = scaffoldOpacity;
    notifyListeners();
  }

  bool? get useUltraHighContrast => _user?.useUltraHighContrast;

  set useUltraHighContrast(bool? useUltraHighContrast) {
    if (null == useUltraHighContrast) {
      return;
    }
    _user?.useUltraHighContrast = useUltraHighContrast;
    notifyListeners();
  }

  bool? get reduceMotion => _user?.reduceMotion;

  set reduceMotion(bool? reduceMotion) {
    if (null == reduceMotion) {
      return;
    }
    _user?.reduceMotion = reduceMotion;
    notifyListeners();
  }

  int? get curMornID => _user?.curMornID;

  set curMornID(int? curMornID) {
    _user?.curMornID = curMornID;
    notifyListeners();
  }

  int? get curAftID => _user?.curAftID;

  set curAftID(int? curAftID) {
    _user?.curAftID = curAftID;
    notifyListeners();
  }

  int? get curEveID => _user?.curEveID;

  set curEveID(int? curEveID) {
    _user?.curEveID = curEveID;
    notifyListeners();
  }

  GroupSorter? get groupSorter => _user?.groupSorter;

  set groupSorter(GroupSorter? groupSorter) {
    _user?.groupSorter = groupSorter;
    notifyListeners();
  }

  ReminderSorter? get reminderSorter => _user?.reminderSorter;

  set reminderSorter(ReminderSorter? reminderSorter) {
    _user?.reminderSorter = reminderSorter;
    notifyListeners();
  }

  RoutineSorter? get routineSorter => _user?.routineSorter;

  set routineSorter(RoutineSorter? routineSorter) {
    _user?.routineSorter = routineSorter;
    notifyListeners();
  }

  ToDoSorter? get toDoSorter => _user?.toDoSorter;

  set toDoSorter(ToDoSorter? toDoSorter) {
    _user?.toDoSorter = toDoSorter;
    notifyListeners();
  }

  DeleteSchedule? get deleteSchedule => _user?.deleteSchedule;

  set deleteSchedule(DeleteSchedule? deleteSchedule) {
    if (null == deleteSchedule) {
      return;
    }
    _user?.deleteSchedule = deleteSchedule;
    notifyListeners();
  }

  DateTime? get lastUpdated => _user?.lastUpdated;

  set lastUpdated(DateTime? lastUpdated) {
    if (null == lastUpdated) {
      return;
    }
    _user?.lastUpdated = lastUpdated;
    notifyListeners();
  }

  DateTime? get lastOpened => _user?.lastOpened;

  set lastOpened(DateTime? lastOpened) {
    if (null == lastOpened) {
      return;
    }
    _user?.lastOpened = lastOpened;
    notifyListeners();
  }

  @override
  List<Object?> get props => [_user];

  @override
  toString() => _user.toString();
}
