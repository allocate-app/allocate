abstract interface class DateRange<T> {
  Future<List<T>> getRange({DateTime? start, DateTime? end});
}
