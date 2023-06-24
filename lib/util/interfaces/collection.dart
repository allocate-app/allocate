abstract interface class Collection<T>
{
  void add(T t);
  void remove(T t);
  void reorder(int oldIndex, int newIndex);
  void sort();
  void sortBy();
}