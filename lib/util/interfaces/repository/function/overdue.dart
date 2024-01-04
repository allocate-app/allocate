import '../../i_model.dart';

abstract interface class Overdue<T extends IModel> {
  Future<List<T>> getUpcoming({int limit = 50, int offset = 0});
}
