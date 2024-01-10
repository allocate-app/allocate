import 'package:equatable/equatable.dart';

import '../util/constants.dart';
import '../util/interfaces/i_repeatable.dart';

class CalendarEvent with EquatableMixin {
  final IRepeatable model;
  late DateTime startDate;
  late DateTime dueDate;

  CalendarEvent({
    required this.model,
  })  : startDate = (model.startDate ?? Constants.today).copyWith(
            hour: 0, minute: 0, second: 0, millisecond: 0, microsecond: 0),
        dueDate = (model.dueDate ?? Constants.today).copyWith(
            hour: 0, minute: 0, second: 0, millisecond: 0, microsecond: 0);

  @override
  String toString() => "Model: $model";

  @override
  List<Object?> get props => [model.repeatID, model.startDate, model.dueDate];
}
