import '../enums.dart';

abstract interface class SortableView<T>
{
  static final List<SortMethod> sortMethods = List.empty(growable: false);
  bool descending = false;
  SortMethod sortMethod = SortMethod.none;
}