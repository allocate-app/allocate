import "todocollection.dart";
import "todo.dart";

/// These are for representing larger projects, hobbies, and wot.

class Project extends ToDo with ToDoCollection<ToDo>{

  String? description;

  Project({required super.name, this.description, super.priority = Priority.low, super.startDate, super.endDate, super.warnMe});

  @override
  List<Object> get props => super.props..add([todos, description]);

}