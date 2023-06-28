abstract interface class Repository<T>
{
  Future<void> update(T t);
  Future<void> create(T t);
  Future<void> delete(T t);
  Future<void> getRepoList({bool showLoading = true});

  // This would be how to sort. Fiiigure this out at some point.
  Future<void> getRepoListBy();

}