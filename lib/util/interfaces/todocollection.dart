abstract interface class ToDoCollection<T>
{
  void add(T t);
  void remove(T t);
  void reorder(int oldIndex, int newIndex);
  List<T> sort();
  List<T> sortBy();
}