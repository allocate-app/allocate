abstract interface class Repository<T>
{
  Future<void> update(T t);
  Future<void> create(T t);
  Future<void> delete(T t);
  Future<void> syncRepo({bool showLoading = true});
  Future<void> fetchRepo({bool showLoading = true});
  // This would be how to sort. Fiiigure this out at some point.
  Future<List<T>> getRepoList({bool showLoading = true});
  Future<List<T>> getRepoListBy({bool showLoading = true});

}