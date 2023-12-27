import 'package:equatable/equatable.dart';
import 'package:isar/isar.dart';

import '../../util/constants.dart';
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
  // Local ID
  Id id = Constants.generateID();

  // Online id
  @Index()
  String? uuid;

  // Online stuff
  bool syncOnline;
  bool isSynced;

  bool checkDelete;
  bool dontAsk;

  @Index()
  String userName;

  // Emotional bandwidth
  int bandwidth;

  // User Theme type.
  @Enumerated(EnumType.ordinal)
  ThemeType themeType;

  @Enumerated(EnumType.ordinal)
  // Routines
  int? curMornID;
  int? curAftID;
  int? curEveID;

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
      this.dontAsk = false,
      this.isSynced = false,
      this.bandwidth = 100,
      this.themeType = ThemeType.dark,
      this.curMornID,
      this.curAftID,
      this.curEveID,
      this.groupSorter,
      this.deadlineSorter,
      this.reminderSorter,
      this.routineSorter,
      this.toDoSorter,
      required this.lastOpened});

  User.fromEntity({required Map<String, dynamic> entity})
      : id = entity["id"] as int,
        uuid = entity["uuid"] as String,
        userName = entity["userName"] as String,
        syncOnline = true,
        checkDelete = entity["checkDelete"],
        dontAsk = entity["dontAsk"],
        isSynced = entity["isSynced"],
        bandwidth = entity["bandwidth"] as int,
        themeType = ThemeType.values[entity["curTheme"]],
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
        "id": id,
        "userName": userName,
        "isSynced": isSynced,
        "checkDelete": checkDelete,
        "dontAsk": dontAsk,
        "bandwidth": bandwidth,
        "curTheme": themeType.index,
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
      themeType: themeType,
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
          ThemeType? curTheme,
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
          themeType: curTheme ?? themeType,
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
  List<Object?> get props => [id];

  @override
  toString() =>
      "id: $id, uuid: $uuid, userName: $userName, syncOnline: $syncOnline, bandwidth: $bandwidth, "
      "curTheme: ${themeType.name}, curMornID: $curMornID, curAftID: $curAftID, curEveID: $curEveID,"
      "groupSorter: $groupSorter, deadlineSorter: $deadlineSorter,"
      "reminderSorter: $reminderSorter, routineSorter: $routineSorter, "
      "isSynced: $isSynced, lastOpened: $lastOpened";
}
