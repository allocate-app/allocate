abstract interface class Search<T> {
  Future<List<T>> search({required String searchString});
  Future<List<T>> mostRecent({int limit = 5});
}
