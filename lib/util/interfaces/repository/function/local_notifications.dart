abstract interface class LocalNotifications<T> {
  Future<List<T>> grabWarnMes({DateTime? now, int limit = 20});
}
