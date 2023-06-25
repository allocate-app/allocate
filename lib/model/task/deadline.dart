import 'package:equatable/equatable.dart';

// TODO: REIMPLEMENT.
/// DeadLines are meant for large-projects that have a due-date. They are just the project description
/// and that alone, so as to not overwhelm with the temptation of overloading subtasks.
/// Ideally, this is possibly something to store separately in the db.
/// On each day, grab the "warn me's": if it's today & 10mins (aprox) before, WARN!.
///
/// These should probably have priority.
class DeadLine with EquatableMixin {
  DateTime startDate;
  DateTime endDate;
  bool warnMe;

  DeadLine({DateTime? startDate, DateTime? endDate, this.warnMe = false}):
      startDate = startDate ?? DateTime.now(),
      endDate = endDate ?? DateTime.now();


  /// TODO: Add functionality to send a push notification to the user when approaching the deadline
  /// Maybe do an alert object. Or use firebase. Look this stuff up.
  void setNotification()
  {
    // Get the cron package/localnotifications.
  }
  void cancelNotification()
  {
    // ibid.
  }

  @override
  List<Object?> get props => [startDate, endDate, warnMe];

}