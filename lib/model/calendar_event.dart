import 'package:equatable/equatable.dart';

import '../util/interfaces/i_repeatable.dart';

class CalendarEvent with EquatableMixin {
  final IRepeatable model;

  const CalendarEvent({
    required this.model,
  });

  @override
  String toString() => "Model: $model";

  @override
  List<Object?> get props => [model];
}
