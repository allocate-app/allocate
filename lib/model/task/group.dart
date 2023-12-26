import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';

import '../../util/constants.dart';
import '../../util/enums.dart';
import '../../util/interfaces/copyable.dart';
import '../../util/interfaces/i_model.dart';
import 'todo.dart';

part "group.g.dart";

@Collection(inheritance: false)
class Group with EquatableMixin implements Copyable<Group>, IModel {
  @ignore
  @override
  ModelType modelType = ModelType.group;

  @override
  @ignore
  Fade fade = Fade.none;

  @override
  @Index()
  Id id = Constants.generateID();

  @Index()
  int customViewIndex = -1;
  @override
  @Index()
  String name;
  String description;
  @Index()
  bool isSynced = false;
  @Index()
  bool toDelete = false;
  @override
  @Index()
  DateTime lastUpdated;

  @ignore
  List<ToDo> toDos = [];

  @ignore
  late ValueNotifier<int> toDoCount = ValueNotifier<int>(toDos.length);

  Group({
    required this.name,
    this.description = "",
    required this.lastUpdated,
  }) {
    while (Constants.intMax == id) {
      id = Constants.generateID();
    }
  }

  Group.fromEntity({required Map<String, dynamic> entity})
      : id = entity["id"] as Id,
        name = entity["name"] as String,
        description = entity["description"] as String,
        lastUpdated = DateTime.parse(entity["lastUpdated"]);

  Map<String, dynamic> toEntity() => {
        "id": id,
        "name": name,
        "description": description,
        "lastUpdated": lastUpdated.toIso8601String()
      };

  @override
  Group copy() => Group(
        name: name,
        description: description,
        lastUpdated: lastUpdated,
      );

  @override
  Group copyWith({
    String? name,
    String? description,
    DateTime? lastUpdated,
  }) =>
      Group(
        name: name ?? this.name,
        description: description ?? this.description,
        lastUpdated: lastUpdated ?? this.lastUpdated,
      );

  @ignore
  @override
  List<Object?> get props => [id];

  @override
  String toString() =>
      "Group(id: $id, customViewIndex: $customViewIndex, name: $name, "
      "description: $description, isSynced: $isSynced, toDelete: $toDelete, "
      "toDos: $toDos, "
      "lastUpdated: $lastUpdated";
}
