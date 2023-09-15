abstract interface class Overdue<T> {
  Future<List<T>> getUpcoming({int limit = 50, int offset = 0});
}
