import '../../sortable.dart';

abstract interface class Repository<T> {
  Future<void> create(T t);
  Future<void> update(T t);
  Future<void> updateBatch(List<T> t);

  Future<void> delete(T t);
  // Future: deleteLocal should probably be an external interface.
  Future<void> deleteLocal();
  Future<void> syncRepo();
  Future<void> fetchRepo();
  Future<List<T>> getRepoList({int limit = 50, int offset = 0});
  Future<List<T>> getRepoListBy({int limit = 50, int offset = 0, required SortableView<T> sorter});
  Future<T?> getByID({required int id});
}
