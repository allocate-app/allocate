abstract interface class Repeatable<T> {
  Future<List<T>> getRepeatables({DateTime? now});
  Future<void> deleteFutures({required T deleteFrom});
}
