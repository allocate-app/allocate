abstract interface class DataCache<T>
{
  // Consider using DI and grabbing a datacache singleton.
  late T current;
  late List<T> currents;
  final List<T> cache = List.empty(growable: true);
}