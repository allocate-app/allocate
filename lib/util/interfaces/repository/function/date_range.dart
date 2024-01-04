import '../../i_model.dart';

abstract interface class DateRange<T extends IModel> {
  Future<List<T>> getRange({DateTime? start, DateTime? end});
}
