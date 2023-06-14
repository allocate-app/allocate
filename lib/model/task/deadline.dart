import 'package:equatable/equatable.dart';
class DeadLine with EquatableMixin {
  DateTime startDate;
  DateTime endDate;
  bool warnMe;

  DeadLine({DateTime? startDate, DateTime? endDate, this.warnMe = false}):
      startDate = startDate ?? DateTime.now(),
      endDate = endDate ?? DateTime.now();


  /// TODO: Add functionality to send a push notification to the user when approaching the deadline
  /// Maybe do an alert object.
  void setNotification()
  {

  }
  void cancelNotification()
  {

  }

  @override
  List<Object?> get props => [startDate, endDate, warnMe];

}