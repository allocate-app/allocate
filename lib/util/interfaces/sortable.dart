import '../enums.dart';

abstract interface class SortableView<T>
{
  late List<SortMethod> sortMethods;
  late bool descending = false;
  late SortMethod sortMethod = SortMethod.none;
}