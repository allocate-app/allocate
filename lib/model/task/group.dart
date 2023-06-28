import 'package:isar/isar.dart';

part "group.g.dart";

@collection
class Group {
  Id id = Isar.autoIncrement;
  String name;
  String? description;
  Group({required this.name, this.description});

  Group.fromEntity({required Map<String, dynamic> entity}) :
    id = entity["id"] as Id,
    name = entity["name"] as String,
    description = entity["description"] as String?;

  Map<String, dynamic> toEntity() => {
    "id" : id,
    "name" : name,
    "description" : description
  };
}