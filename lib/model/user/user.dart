
import 'package:equatable/equatable.dart';
import 'package:isar/isar.dart';

import '../../util/enums.dart';
import '../../util/interfaces/copyable.dart';
import '../../util/sorting/deadline_sorter.dart';
import '../../util/sorting/group_sorter.dart';
import '../../util/sorting/reminder_sorter.dart';
import '../../util/sorting/routine_sorter.dart';
import '../../util/sorting/todo_sorter.dart';

part "user.g.dart";

@Collection(inheritance: false)
class User with EquatableMixin implements Copyable<User> {
  Id localID = Isar.autoIncrement;

  // Online stuff
  bool syncOnline;
  bool isSynced;

  bool checkDelete;

  @Index(unique: true, replace: true)
  String userName;

  int bandwidth;

  // User Theme.
  @Enumerated(EnumType.ordinal)
  UserThemeData curTheme;

  // Routines
  int? curMornID;
  int? curAftID;
  int? curEveID;

  // Routine TOD.
  int? mornHour;
  int? aftHour;
  int? eveHour;

  // Sorting preferences
  @ignore
  GroupSorter? groupSorter;

  @ignore
  DeadlineSorter? deadlineSorter;
  @ignore
  ReminderSorter? reminderSorter;
  @ignore
  RoutineSorter? routineSorter;
  @ignore
  ToDoSorter? toDoSorter;

  // Last login.
  DateTime lastOpened;

  User(
      {required this.userName,
      required this.syncOnline,
      this.checkDelete = true,
      this.isSynced = false,
      this.bandwidth = 100,
      this.curTheme = UserThemeData.dark,
      this.curMornID,
      this.curAftID,
      this.curEveID,
      this.groupSorter,
      this.deadlineSorter,
      this.reminderSorter,
      this.routineSorter,
      this.toDoSorter,
      required this.lastOpened});

  // This needs refactoring.
  User.fromEntity({required Map<String, dynamic> entity})
      : localID = entity["localID"] as int,
        userName = entity["userName"] as String,
        syncOnline = true,
        checkDelete = entity["checkDelete"],
        isSynced = entity["isSynced"],
        bandwidth = entity["bandwidth"] as int,
        curTheme = UserThemeData.values[entity["curTheme"]],
        curMornID = entity["curMornID"] as int?,
        curAftID = entity["curAftID"] as int?,
        curEveID = entity["curEveID"] as int?,
        groupSorter = (null != entity["groupSort"])
            ? GroupSorter(
                descending: entity["groupDesc"],
                sortMethod: entity["groupSort"])
            : null,
        deadlineSorter = (null != entity["deadlineSort"])
            ? DeadlineSorter(
                descending: entity["deadlineDesc"],
                sortMethod: entity["deadlineSort"])
            : null,
        reminderSorter = (null != entity["reminderSort"])
            ? ReminderSorter(
                descending: entity["reminderDesc"],
                sortMethod: entity["reminderSort"])
            : null,
        routineSorter = (null != entity["routineSort"])
            ? RoutineSorter(
                descending: entity["routineDesc"],
                sortMethod: entity["routineSort"],
              )
            : null,
        toDoSorter = (null != entity["toDoSort"])
            ? ToDoSorter(
                descending: entity["toDoDesc"],
                sortMethod: entity["toDoSort"],
              )
            : null,
        lastOpened = DateTime.parse(entity["lastOpened"]);

  Map<String, dynamic> toEntity() => {
        "userName": userName,
        "isSynced": isSynced,
        "checkDelete": checkDelete,
        "bandwidth": bandwidth,
        "curTheme": curTheme.index,
        "curMornID": curMornID,
        "curAftID": curAftID,
        "curEveID": curEveID,
        "groupSort": groupSorter?.sortMethod,
        "groupDesc": groupSorter?.descending,
        "deadlineSort": deadlineSorter?.sortMethod,
        "deadlineDesc": deadlineSorter?.descending,
        "routineSort": routineSorter?.sortMethod,
        "routineDesc": routineSorter?.descending,
        "reminderSort": reminderSorter?.sortMethod,
        "reminderDesc": reminderSorter?.descending,
        "toDoSorter": toDoSorter?.sortMethod,
        "toDoDesc": toDoSorter?.descending,
        "lastOpened": lastOpened.toIso8601String()
      };

  @override
  User copy() => User(
      userName: userName,
      syncOnline: syncOnline,
      bandwidth: bandwidth,
      curTheme: curTheme,
      curMornID: curMornID,
      curAftID: curAftID,
      curEveID: curEveID,
      groupSorter: groupSorter,
      deadlineSorter: deadlineSorter,
      reminderSorter: reminderSorter,
      routineSorter: routineSorter,
      toDoSorter: toDoSorter,
      isSynced: isSynced,
      lastOpened: lastOpened);

  @override
  User copyWith(
          {String? userName,
          bool? syncOnline,
          int? bandwidth,
          UserThemeData? curTheme,
          int? curMornID,
          int? curAftID,
          int? curEveID,
          GroupSorter? groupSorter,
          DeadlineSorter? deadlineSorter,
          ReminderSorter? reminderSorter,
          RoutineSorter? routineSorter,
          ToDoSorter? toDoSorter,
          bool? isSynced,
          DateTime? lastOpened}) =>
      User(
          userName: userName ?? this.userName,
          syncOnline: syncOnline ?? this.syncOnline,
          bandwidth: bandwidth ?? this.bandwidth,
          curTheme: curTheme ?? this.curTheme,
          curMornID: curMornID ?? this.curMornID,
          curAftID: curAftID ?? this.curAftID,
          curEveID: curEveID ?? this.curEveID,
          groupSorter: groupSorter ?? this.groupSorter,
          deadlineSorter: deadlineSorter ?? this.deadlineSorter,
          reminderSorter: reminderSorter ?? this.reminderSorter,
          routineSorter: routineSorter ?? this.routineSorter,
          toDoSorter: toDoSorter ?? this.toDoSorter,
          isSynced: isSynced ?? this.isSynced,
          lastOpened: lastOpened ?? this.lastOpened);

  @ignore
  @override
  List<Object?> get props => [
        localID,
        syncOnline,
        userName,
        bandwidth,
        curTheme,
        curMornID,
        curAftID,
        curEveID,
        groupSorter,
        deadlineSorter,
        reminderSorter,
        routineSorter,
        isSynced,
        lastOpened
      ];

  @override
  toString() =>
      "userName: $userName, syncOnline: $syncOnline, bandwidth: $bandwidth, "
      "curTheme: ${curTheme.name}, curMornID: $curMornID, curAftID: $curAftID, curEveID: $curEveID,"
      "groupSorter: $groupSorter, deadlineSorter: $deadlineSorter,"
      "reminderSorter: $reminderSorter, routineSorter: $routineSorter, "
      "isSynced: $isSynced, lastOpened: $lastOpened";
}
