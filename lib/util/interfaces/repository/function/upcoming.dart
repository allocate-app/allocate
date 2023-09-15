abstract interface class Upcoming<T> {
  Future<List<T>> getOverdues({int limit = 50, int offset = 0});
}
