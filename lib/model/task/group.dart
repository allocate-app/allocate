import 'package:allocate/model/task/todo.dart';
import 'package:equatable/equatable.dart';
import 'package:isar/isar.dart';

import '../../util/interfaces/copyable.dart';

part "group.g.dart";

@collection
class Group with EquatableMixin implements Copyable<Group> {
  Id id = Isar.autoIncrement;
  @Index()
  int customViewIndex = -1;
  @Index()
  String name;
  String description;
  @Index()
  bool isSynced = false;
  @Index()
  bool toDelete = false;
  late List<ToDo> toDos;

  Group({required this.name, this.description = ""});

  Group.fromEntity({required Map<String, dynamic> entity})
      : id = entity["id"] as Id,
        name = entity["name"] as String,
        description = entity["description"] as String;

  Map<String, dynamic> toEntity() =>
      {"id": id, "name": name, "description": description};

  @override
  Group copy() => Group(name: name, description: description);

  @override
  Group copyWith({String? name, String? description}) => Group(
      name: name ?? this.name, description: description ?? this.description);

  @override
  // TODO: implement props
  List<Object?> get props =>
      [id, customViewIndex, name, description, isSynced, toDelete];
}
