import 'package:equatable/equatable.dart';
import 'package:isar/isar.dart';

import '../../util/interfaces/copyable.dart';
import '../../util/interfaces/i_model.dart';
import 'todo.dart';

part "group.g.dart";

@Collection(inheritance: false)
class Group with EquatableMixin implements Copyable<Group>, IModel {
  Id id = Isar.autoIncrement;

  @override
  @Index() // TODO: REMOVE THIS AND REFACTOR DB TO HOLD A LOCAL ID.
  int? localID;

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
  @Index()
  DateTime lastUpdated;

  // TODO: Make non-null when revisiting to refactor. It's not necessary.

  @ignore
  List<ToDo>? toDos = [];

  Group({required this.name,
    this.description = "",
    required this.lastUpdated,
    this.localID,
    this.toDos});

  Group.fromEntity({required Map<String, dynamic> entity})
      : id = entity["id"] as Id,
        localID = entity["localID"] as int?,
        name = entity["name"] as String,
        description = entity["description"] as String,
        lastUpdated = DateTime.parse(entity["lastUpdated"]);

  Map<String, dynamic> toEntity() =>
      {
        "name": name,
        "localID": localID,
        "description": description,
        "lastUpdated": lastUpdated.toIso8601String()
      };

  @override
  Group copy() =>
      Group(
          name: name,
          description: description,
          lastUpdated: lastUpdated,
          localID: localID,
          toDos: List.from(toDos ?? []));

  @override
  Group copyWith({String? name,
    String? description,
    DateTime? lastUpdated,
    int? localID,
    List<ToDo>? toDos}) =>
      Group(
          name: name ?? this.name,
          description: description ?? this.description,
          lastUpdated: lastUpdated ?? this.lastUpdated,
          localID: localID ?? this.localID,
          toDos: List.from(toDos ?? this.toDos ?? []));

  @ignore
  @override
  List<Object?> get props =>
      [id, customViewIndex, name, description, isSynced, toDelete, lastUpdated];

  @override
  String toString() =>
      "Group(id: $id, customViewIndex: $customViewIndex, name: $name, "
          "description: $description, isSynced: $isSynced, toDelete: $toDelete, "
          "toDos: $toDos, "
          "lastUpdated: $lastUpdated";
}
