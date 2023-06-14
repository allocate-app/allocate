import "todo.dart";
import "task.dart";
import "todocollection.dart";

/// These are mid-sized tasks, meant to be completed in a reasonable amount of time, roughly one
/// to three days depending on the demands of the full task. They contain a small number of subtasks
/// to help with organization and completion.

class LargeTask extends ToDo
    with ToDoCollection<Task> {
  static const maxSubTasks = 5;
  LargeTask(
      {required super.name, super.priority, super.startDate, super.endDate, super.repeat});

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
  List<Object> get props => super.props..add(todos);
}