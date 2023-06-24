import "../../util/interfaces/collection.dart";
import "../../util/interfaces/copyable";
import "todo.dart";
import "task.dart";

/// These are mid-sized tasks, meant to be completed in a reasonable amount of time, roughly one
/// to three days depending on the demands of the full task. They contain a small number of subtasks
/// to help with organization and completion.

class LargeTask extends ToDo implements Copyable<LargeTask>, Collection<Task>{
  static const maxSubTasks = 5;
  List<Task> subTasks;
  //TODO: list needs to be assignable.
  //TODO: list needs to also be deep copied.
  LargeTask(
      {required super.id,
      required super.name,
      required super.description,
        super.priority,
        super.startDate,
        super.endDate,
        super.focusTask,
        super.repeatable,
        List<Task> ? subTasks,
      }) :
      subTasks = subTasks ?? [];


  @override
  LargeTask copy() => LargeTask(
    id: id,
    name: name,
    description: description,
    priority: priority,
    startDate: startDate,
    endDate: endDate,
    focusTask: focusTask,
    repeatable: repeatable,
      subTasks: List.from(subTasks)
  );

  // THIS NEEDS TO TAKE A BOOLEAN FOR DEEP COPY.
  @override
  LargeTask copyWith() {
    // TODO: implement copyWith
    throw UnimplementedError();
  }

  @override
  void add(Task t) {
    subTasks.add(t);
    updateWeight(t.weight);
    updateDuration(t.expectedDuration);
  }

  @override
  void remove(Task t) {
    subTasks.remove(t);
    updateWeight(-t.weight);
    updateDuration(-t.expectedDuration);
  }

  @override
  void reorder(int oldIndex, int newIndex) {
    if(oldIndex < newIndex)
      {
        newIndex -= 1;
      }
    Task task = subTasks.removeAt(oldIndex);
    subTasks.insert(newIndex, task);
  }

  @override
  void sort() {
    // TODO: implement sort
  }

  @override
  void sortBy() {
    // TODO: implement sortBy
  }
  // DEAL WITH THIS LATER.
  void updateWeight(int w) => weight = (weight + w > 0) ? weight + w : 0;
  void recalculateWeight() => weight = subTasks.fold(0, (p, c) => p + c.weight);

  void updateDuration(Duration d)
  {
    expectedDuration += d;
    if(expectedDuration.isNegative)
    {
      expectedDuration = Duration.zero;
    }
  }

  void recalculateDuration() => expectedDuration = subTasks.fold(Duration.zero, (p, c) => p + c.expectedDuration);

  //TODO: re-implement.
  @override
  List<Object> get props => super.props..add(todos);


}