import '../../i_model.dart';

abstract interface class Upcoming<T extends IModel> {
  Future<List<T>> getOverdues({int limit = 50, int offset = 0});
}
