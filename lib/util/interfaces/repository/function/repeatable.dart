abstract interface class Repeatable<T> {
  Future<List<T>> getRepeatables({DateTime? now});

  Future<List<T>> deleteFutures({required T deleteFrom});
}
