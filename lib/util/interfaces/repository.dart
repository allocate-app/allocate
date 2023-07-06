import 'package:allocate/util/interfaces/sortable.dart';
abstract interface class Repository<T>
{
  Future<void> create(T t);
  Future<void> update(T t);
  Future<void> updateBatch(List<T> t);
  Future<void> retry(List<T> t);
  Future<void> delete(T t);
  //Future<void> deleteBatch(List<T> t);
  Future<void> syncRepo();
  Future<void> fetchRepo();
  // This would be how to sort. Fiiigure this out at some point.
  Future<List<T>> getRepoList();
  Future<List<T>> getRepoListBy({required SortableView<T> sorter});

}