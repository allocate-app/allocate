import "../sortable.dart";

abstract interface class Repository<T> {
  Future<void> create(T t);
  Future<void> update(T t);
  Future<void> updateBatch(List<T> t);

  Stream<List<T>> stream({required SortableView<T> sorter});

  Future<void> delete(T t);
  // Future: deleteLocal should probably be an external interface.
  Future<void> deleteLocal();
  Future<void> syncRepo();
  Future<void> fetchRepo();
  Future<List<T>> getRepoList(
      {required SortableView<T> sorter, required int limit, int offset});
  Future<List<T>> getRepoListBy({required SortableView<T> sorter});
  Future<T?> getByID({required int id});
}
