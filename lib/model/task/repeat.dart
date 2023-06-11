import "package:equatable/equatable.dart";

enum Frequency { none, daily, weekly, monthly, yearly }
class Repeat with EquatableMixin {
  // Calculated from start date.
  int numDays;
  bool custom;
  DateTime startDate = DateTime.now();
  DateTime? endDate;
  Frequency repeatFactor;

  Repeat(
      {this.numDays = 1,
        this.custom = false,
        this.endDate,
        this.repeatFactor = Frequency.none});

  // Should probably have some sort of DateTime listener for the endDate.
  // TODO: design this.
  void endRepeat() {
    repeatFactor = Frequency.none;
  }
  @override
  List<Object> get props => [numDays, custom, startDate, endDate.toString(), repeatFactor];
}