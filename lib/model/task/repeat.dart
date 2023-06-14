import "package:equatable/equatable.dart";
enum Frequency { none, daily, weekly, monthly, yearly }
class Repeat with EquatableMixin {
  // Calculated from start date.
  int numDays;
  bool custom;
  DateTime startDate;
  DateTime? endDate;
  Frequency frequency;

  Repeat(
      {this.numDays = 1,
        this.custom = false,
        DateTime? startDate,
        this.endDate,
        this.frequency = Frequency.none}):
      startDate = startDate ?? DateTime.now();

  void endRepeat() {
    frequency = Frequency.none;
  }
  @override
  List<Object> get props => [numDays, custom, startDate, endDate.toString(), frequency];
}