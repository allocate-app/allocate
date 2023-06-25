enum SortMethod {none, name, dueDate, weight, priority, duration}
abstract interface class Collection<T>
{
  void add(T t);
  void remove(T t);
  void reorder(int oldIndex, int newIndex);
  List<T> sort();
  List<T> sortBy();
}