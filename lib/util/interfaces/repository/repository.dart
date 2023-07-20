import "../sortable.dart";

abstract interface class Repository<T> {
  Future<void> create(T t);
  Future<void> update(T t);
  Future<void> updateBatch(List<T> t);
  // Retry can just be a bulk update.
  //Future<void> retry(List<T> t);
  Future<void> delete(T t);
  // Future: deleteLocal should be an external interface.
  Future<void> deleteLocal();
  Future<void> syncRepo();
  Future<void> fetchRepo();
  Future<List<T>> getRepoList();
  Future<List<T>> getRepoListBy({required SortableView<T> sorter});
  Future<T?> getByID({required int id});
}
