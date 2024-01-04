import '../enums.dart';
import 'i_model.dart';

abstract interface class IRepeatable implements IModel {
  DateTime? startDate = DateTime.now();
  DateTime? originalStart = DateTime.now();
  DateTime? originalDue = DateTime.now();
  DateTime? dueDate = DateTime.now();
  Frequency frequency = Frequency.once;
  int? repeatID;
  bool repeatable = false;
  int repeatSkip = 1;
  final List<bool> repeatDays = [];
  RepeatableState repeatableState = RepeatableState.normal;
}
