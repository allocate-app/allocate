import '../enums.dart';
import 'i_model.dart';

abstract interface class IRepeatable implements IModel {
  DateTime? startDate = DateTime.now();
  DateTime? dueDate = DateTime.now();
  Frequency frequency = Frequency.once;

  ModelType get repeatableType;
}
