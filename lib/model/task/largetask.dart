import "todo.dart";
import "task.dart";
import "todocollection.dart";

/// These

class LargeTask extends ToDo
    with ToDoCollection<Task> {
  static const maxSubTasks = 5;
  LargeTask(
      {required super.name, super.priority, super.startDate, super.endDate, super.repeat});

  void updateWeight(int w) => weight = (weight + w > 0) ? weight + w : 0;
  void recalculateWeight() => weight = calculateWeight();

  void updateDuration(Duration d, bool add)
  {
    expectedDuration = (add)? expectedDuration + d : expectedDuration - d;
    if(expectedDuration.isNegative)
    {
      expectedDuration = Duration.zero;
    }
  }

  void recalculateDuration() => expectedDuration = calculateDuration();

  @override
  List<Object> get props => super.props..add([maxSubTasks, todos]);
}