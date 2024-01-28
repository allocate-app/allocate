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

part "allocate_user.g.dart";

@Collection(inheritance: false)
class AllocateUser with EquatableMixin implements Copyable<AllocateUser> {
  // Local ID
  @Index()
  late Id id;

  // Online id
  @Index()
  String? uuid;

  // Online stuff
  bool syncOnline;
  bool isSynced;

  bool checkDelete;
  bool checkClose;

  @Index()
  String username;

  String? email;

  // Emotional bandwidth
  int bandwidth;

  // User Theme type.
  @Enumerated(EnumType.ordinal)
  ThemeType themeType;

  @Enumerated(EnumType.ordinal)
  ToneMapping toneMapping;

  @Enumerated(EnumType.ordinal)
  Effect windowEffect;

  int primarySeed;
  int? secondarySeed;
  int? tertiarySeed;

  double sidebarOpacity;
  double scaffoldOpacity;

  bool useUltraHighContrast;
  bool reduceMotion;

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

  @Enumerated(EnumType.ordinal)
  DeleteSchedule deleteSchedule;

  DateTime lastUpdated;

  // Last login.
  DateTime lastOpened;

  @Index()
  bool toDelete;

  AllocateUser(
      {required this.id,
      this.uuid,
      required this.username,
      this.email,
      this.checkDelete = true,
      this.checkClose = true,
      this.bandwidth = 100,
      this.themeType = ThemeType.system,
      this.toneMapping = ToneMapping.system,
      this.windowEffect = Effect.disabled,
      this.sidebarOpacity = 100,
      this.scaffoldOpacity = 100,
      required this.primarySeed,
      this.secondarySeed,
      this.tertiarySeed,
      this.useUltraHighContrast = false,
      this.reduceMotion = false,
      this.curMornID,
      this.curAftID,
      this.curEveID,
      this.groupSorter,
      this.deadlineSorter,
      this.reminderSorter,
      this.routineSorter,
      this.toDoSorter,
      this.deleteSchedule = DeleteSchedule.never,
      this.isSynced = false,
      this.syncOnline = false,
      this.toDelete = false,
      required this.lastOpened,
      required this.lastUpdated});

  AllocateUser.fromEntity({required Map<String, dynamic> entity})
      : id = entity["id"] as int,
        uuid = entity["uuid"] as String,
        username = entity["username"] as String,
        bandwidth = entity["bandwidth"] as int,
        checkDelete = entity["checkDelete"],
        checkClose = entity["checkClose"],
        curMornID = entity["curMornID"] as int?,
        curAftID = entity["curAftID"] as int?,
        curEveID = entity["curEveID"] as int?,
        themeType = ThemeType.values[entity["themeType"]],
        toneMapping = ToneMapping.values[entity["toneMapping"]],
        primarySeed = entity["primarySeed"] as int,
        secondarySeed = entity["secondarySeed"] as int?,
        tertiarySeed = entity["tertiarySeed"] as int?,
        useUltraHighContrast = entity["useUltraHighContrast"] as bool,
        reduceMotion = entity["reduceMotion"] as bool,
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
        isSynced = true,
        syncOnline = true,
        deleteSchedule = DeleteSchedule.values[entity["deleteSchedule"]],
        lastOpened = DateTime.parse(entity["lastOpened"]),
        lastUpdated = DateTime.parse(entity["lastUpdated"]),
        // Local Parameters
        windowEffect = Effect.disabled,
        scaffoldOpacity = 100,
        sidebarOpacity = 100,
        toDelete = false;

  // TODO: supabase - link user table by user.auth.uuid + email.
  Map<String, dynamic> toEntity() => {
        "id": id,
        // TODO: remove this -> should already be in table.
        "uuid": uuid,
        // TODO: remove this -> should already be in table.
        "email": email,
        "username": username,
        "bandwidth": bandwidth,
        "checkDelete": checkDelete,
        "checkClose": checkClose,
        "curMornID": curMornID,
        "curAftID": curAftID,
        "curEveID": curEveID,
        "themeType": themeType.index,
        "toneMapping": toneMapping.index,
        "windowEffect": windowEffect,
        "primarySeed": primarySeed,
        "secondarySeed": secondarySeed,
        "tertiarySeed": tertiarySeed,
        "useUltraHighContrast": useUltraHighContrast,
        "reduceMotion": reduceMotion,
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
        "deleteSchedule": deleteSchedule.index,
        "lastOpened": lastOpened.toIso8601String(),
        "lastUpdated": lastUpdated.toIso8601String(),
      };

  // TODO: decide whether or not to copy the id.
  // ALSO: whether or not to uuid.
  @override
  AllocateUser copy() => AllocateUser(
        id: Constants.generateID(),
        uuid: null,
        username: username,
        bandwidth: bandwidth,
        checkDelete: checkDelete,
        checkClose: checkClose,
        curMornID: curMornID,
        curAftID: curAftID,
        curEveID: curEveID,
        themeType: themeType,
        toneMapping: toneMapping,
        windowEffect: windowEffect,
        primarySeed: primarySeed,
        secondarySeed: secondarySeed,
        tertiarySeed: tertiarySeed,
        scaffoldOpacity: scaffoldOpacity,
        sidebarOpacity: sidebarOpacity,
        useUltraHighContrast: useUltraHighContrast,
        reduceMotion: reduceMotion,
        groupSorter: groupSorter,
        deadlineSorter: deadlineSorter,
        reminderSorter: reminderSorter,
        routineSorter: routineSorter,
        toDoSorter: toDoSorter,
        deleteSchedule: deleteSchedule,
        isSynced: isSynced,
        syncOnline: syncOnline,
        lastOpened: lastOpened,
        lastUpdated: lastUpdated,
        toDelete: toDelete,
      );

  @override
  AllocateUser copyWith(
          {int? id,
          String? uuid,
          String? username,
          int? bandwidth,
          bool? checkDelete,
          bool? checkClose,
          int? curMornID,
          int? curAftID,
          int? curEveID,
          ThemeType? themeType,
          ToneMapping? toneMapping,
          Effect? windowEffect,
          int? primarySeed,
          int? secondarySeed,
          int? tertiarySeed,
          double? scaffoldOpacity,
          double? sidebarOpacity,
          bool? useUltraHighContrast,
          bool? reduceMotion,
          ToDoSorter? toDoSorter,
          GroupSorter? groupSorter,
          DeadlineSorter? deadlineSorter,
          ReminderSorter? reminderSorter,
          RoutineSorter? routineSorter,
          bool? syncOnline,
          bool? isSynced,
          DeleteSchedule? deleteSchedule,
          DateTime? lastOpened,
          DateTime? lastUpdated,
          bool? toDelete}) =>
      AllocateUser(
          id: id ?? Constants.generateID(),
          uuid: uuid,
          username: username ?? this.username,
          bandwidth: bandwidth ?? this.bandwidth,
          checkDelete: checkDelete ?? this.checkDelete,
          checkClose: checkClose ?? this.checkClose,
          curMornID: curMornID ?? this.curMornID,
          curAftID: curAftID ?? this.curAftID,
          curEveID: curEveID ?? this.curEveID,
          themeType: themeType ?? this.themeType,
          toneMapping: toneMapping ?? this.toneMapping,
          windowEffect: windowEffect ?? this.windowEffect,
          primarySeed: primarySeed ?? this.primarySeed,
          secondarySeed: secondarySeed ?? this.secondarySeed,
          tertiarySeed: tertiarySeed ?? this.tertiarySeed,
          scaffoldOpacity: scaffoldOpacity ?? this.scaffoldOpacity,
          sidebarOpacity: sidebarOpacity ?? this.sidebarOpacity,
          useUltraHighContrast:
              useUltraHighContrast ?? this.useUltraHighContrast,
          reduceMotion: reduceMotion ?? this.reduceMotion,
          toDoSorter: toDoSorter ?? this.toDoSorter,
          groupSorter: groupSorter ?? this.groupSorter,
          deadlineSorter: deadlineSorter ?? this.deadlineSorter,
          reminderSorter: reminderSorter ?? this.reminderSorter,
          routineSorter: routineSorter ?? this.routineSorter,
          syncOnline: syncOnline ?? this.syncOnline,
          isSynced: isSynced ?? this.isSynced,
          deleteSchedule: deleteSchedule ?? this.deleteSchedule,
          lastOpened: lastOpened ?? this.lastOpened,
          lastUpdated: lastUpdated ?? this.lastUpdated,
          toDelete: toDelete ?? this.toDelete);

  @ignore
  @override
  List<Object?> get props => [id, uuid];

  @override
  toString() =>
      "id: $id, uuid: $uuid, username: $username, syncOnline: $syncOnline, bandwidth: $bandwidth, "
      "curTheme: ${themeType.name}, curMornID: $curMornID, curAftID: $curAftID, curEveID: $curEveID,"
      "groupSorter: $groupSorter, deadlineSorter: $deadlineSorter,"
      "reminderSorter: $reminderSorter, routineSorter: $routineSorter, "
      "isSynced: $isSynced, lastOpened: $lastOpened";
}
