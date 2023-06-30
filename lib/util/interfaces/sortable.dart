import '../enums.dart';

abstract interface class SortableView<T>
{
  late List<SortMethod> sortMethods;
  bool reverse = false;
  SortMethod sortMethod = SortMethod.none;
}