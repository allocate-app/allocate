abstract interface class LocalNotifications<T> {
  Future<List<T>> getWarnMes({DateTime? now, int limit = 20});
}
