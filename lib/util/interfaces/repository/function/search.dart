import '../../i_model.dart';

abstract interface class Search<T extends IModel> {
  Future<List<T>> search({required String searchString});

  Future<List<T>> mostRecent({int limit = 5});
}
