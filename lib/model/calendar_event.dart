import 'package:equatable/equatable.dart';

import '../util/enums.dart';
import '../util/interfaces/i_repeatable.dart';

class CalendarEvent with EquatableMixin {
  final RepeatableType repeatableType;
  final IRepeatable model;

  const CalendarEvent({
    required this.model,
    required this.repeatableType,
  });

  @override
  String toString() => "RepeatableType: $repeatableType, Model: $model";

  @override
  List<Object?> get props => [repeatableType, model];
}
