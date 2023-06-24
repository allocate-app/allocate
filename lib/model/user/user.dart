// No tasks during burnout.
class User
{
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

  User({this.firstName, this.lastName, this.userName, this.userID, this.birthday, this.inMeltdown = false, this.bandwidth = 100, this.dayBandwidth=100});

  // TODO: Hashmap for routines > possibly factor into other class.
  // By which I mean day of the week.
}