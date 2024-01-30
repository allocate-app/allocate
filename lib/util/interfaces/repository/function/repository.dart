import '../../i_model.dart';
import '../../sortable.dart';

abstract interface class Repository<T extends IModel> {
  void init();

  Future<T> create(T t);

  Future<T> update(T t);

  Future<void> updateBatch(List<T> t);

  Future<void> delete(T t);

  Future<void> deleteSweep({DateTime? upTo});

  // This is for permanent deletion
  Future<void> remove(T t);

  // This is also for permanent deletion
  Future<List<int>> emptyTrash();

  // This is to wipe the db.
  Future<void> clearDB();

  Future<void> syncRepo();

  Future<List<T>> fetchRepo({int limit = 1000, int offset = 0});

  Future<List<T>> getRepoList({int limit = 50, int offset = 0});

  Future<List<T>> getRepoListBy(
      {int limit = 50, int offset = 0, required SortableView<T> sorter});

  Future<T?> getByID({required int id});

  Future<List<T>> getDeleted({int limit = 50, int offset = 0});
}
