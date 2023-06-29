import 'package:isar/isar.dart';
@collection
class User
{
  Id localID = Isar.autoIncrement;
  int? id;
  // These could probably go. Keeping for now.
  String? firstName;
  String? lastName;
  // Kinda cheesy, but this is for me.
  DateTime? birthday;
  String? userName;
  // PWD in main.
  int? userID;
  int bandwidth = 100;
  int dayBandwidth;

  bool inMeltdown;

  // Routine times

  // NumSubtasksPerRoutine

  // NumSubTasksPerLT.

  User({this.id, this.firstName, this.lastName, this.userName, this.userID, this.birthday, this.inMeltdown = false, this.bandwidth = 100, this.dayBandwidth=100});

  // TODO: Hashmap for routines > Changed idea, written down, handled by todo.
}