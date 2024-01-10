import '../../i_repeatable.dart';

abstract interface class Repeatable<T extends IRepeatable> {
  Future<List<T>> getRepeatables({DateTime? now});

  Future<T?> getNextRepeat({required int repeatID, DateTime? now});

  Future<T?> getDelta({required DateTime onDate, required int repeatID});

  Future<T?> getTemplate({required int repeatID});

  Future<List<int>> deleteFutures({required T deleteFrom});
}
