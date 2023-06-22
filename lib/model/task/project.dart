import "todocollection.dart";
import "todo.dart";

/// These are for representing larger projects, hobbies, and wot.

class Project extends ToDo with ToDoCollection<ToDo>{

  String? description;

  Project({required super.name, this.description, super.priority = Priority.low, super.startDate, super.endDate, super.warnMe});

  // TODO: refactor duped code into generic static method.
  void updateWeight(int w) => weight = (weight + w > 0) ? weight + w : 0;
  void recalculateWeight() => weight = calculateWeight();
  void updateDuration(Duration d)
  {
    expectedDuration += d;
    if(expectedDuration.isNegative)
    {
      expectedDuration = Duration.zero;
    }
  }
  void recalculateDuration() => expectedDuration = calculateDuration();

  @override
  List<Object> get props => super.props..add([todos, description]);

}