import '../../i_model.dart';
import '../../sortable.dart';

abstract interface class Repository<T extends IModel> {
  Future<T> create(T t);

  Future<T> update(T t);

  Future<void> updateBatch(List<T> t);

  Future<void> delete(T t);

  Future<void> deleteSweep();

  // This is for permanent deletion
  Future<void> remove(T t);

  // This is also for permanent deletion
  Future<List<int>> emptyTrash();

  Future<void> syncRepo();

  Future<void> fetchRepo();

  Future<List<T>> getRepoList({int limit = 50, int offset = 0});

  Future<List<T>> getRepoListBy(
      {int limit = 50, int offset = 0, required SortableView<T> sorter});

  Future<T?> getByID({required int id});

  Future<List<T>> getDeleted({int limit = 50, int offset = 0});
}
