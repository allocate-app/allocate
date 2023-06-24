import '../task/todocollection.dart';
class RepositoryPrefs
{
  SortMethod curSort;
  bool revSort;
  RepositoryPrefs({this.curSort = SortMethod.custom, this.revSort = false});
}