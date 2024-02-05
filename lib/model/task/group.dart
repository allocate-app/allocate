import 'package:equatable/equatable.dart';
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
  late Id id;

  @Index()
  late int customViewIndex;
  @override
  @Index()
  String name;
  String description;
  @override
  @Index()
  bool isSynced;
  @override
  @Index()
  bool toDelete;
  @override
  @Index()
  DateTime lastUpdated;

  @ignore
  late List<ToDo> toDos;

  Group({
    required this.id,
    this.customViewIndex = -1,
    required this.name,
    this.description = "",
    this.isSynced = false,
    this.toDelete = false,
    required this.lastUpdated,
    this.toDos = const [],
  });

  Group.fromEntity({required Map<String, dynamic> entity})
      : id = entity["id"] as Id,
        customViewIndex = entity["customViewIndex"] as int,
        name = entity["name"] as String,
        description = entity["description"] as String,
        toDelete = entity["toDelete"] as bool,
        isSynced = true,
        lastUpdated =
            DateTime.tryParse(entity["lastUpdated"] ?? "") ?? Constants.today;

  Map<String, dynamic> toEntity() => {
        "id": id,
        "customViewIndex": customViewIndex,
        "name": name,
        "description": description,
        "toDelete": toDelete,
        "lastUpdated": lastUpdated.toIso8601String()
      };

  @override
  Group copy() => Group(
      id: Constants.generateID(),
      customViewIndex: customViewIndex,
      name: name,
      description: description,
      isSynced: isSynced,
      toDelete: toDelete,
      lastUpdated: lastUpdated,
      toDos: List.generate(toDos.length, (i) => toDos[i]));

  @override
  Group copyWith(
          {int? id,
          int? customViewIndex,
          String? name,
          String? description,
          bool? isSynced,
          bool? toDelete,
          DateTime? lastUpdated,
          List<ToDo>? toDos}) =>
      Group(
        id: id ?? Constants.generateID(),
        customViewIndex: customViewIndex ?? this.customViewIndex,
        name: name ?? this.name,
        description: description ?? this.description,
        isSynced: isSynced ?? this.isSynced,
        toDelete: toDelete ?? this.toDelete,
        toDos: (null != toDos)
            ? toDos
            : List.generate(this.toDos.length, (i) => this.toDos[i]),
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
