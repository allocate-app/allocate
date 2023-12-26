import '../enums.dart';

abstract interface class IModel {
  String name = "";

  int id = 0;
  late ModelType modelType;
  late Fade fade;
  late DateTime lastUpdated;
}
