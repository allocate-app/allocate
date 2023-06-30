import '../enums.dart';

abstract interface class Repository<T>
{
  Future<void> create(T t);
  Future<void> update(T t);
  Future<void> updateBatch(List<T> t);
  Future<void> retry(List<T> t);
  Future<void> delete(T t);
  //Future<void> deleteBatch(List<T> t);
  Future<void> syncRepo({bool showLoading = true});
  Future<void> fetchRepo({bool showLoading = true});
  // This would be how to sort. Fiiigure this out at some point.
  Future<List<T>> getRepoList({bool showLoading = true});
  Future<List<T>> getRepoListBy({bool showLoading = true, SortMethod sortMethod = SortMethod.none});

}