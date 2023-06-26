import "../../util/interfaces/collection.dart";
import "../../util/interfaces/copyable.dart";
import "todo.dart";

/// These are mid-sized tasks, meant to be completed in a reasonable amount of time, roughly one
/// to three days depending on the demands of the full task. They contain a small number of subtasks
/// to help with organization and completion.

// TODO: factor this to be used by Routine + Partition classes.
class SubTask implements Copyable<SubTask>, Comparable<SubTask>{
  String name;
  bool completed;
  int weight;
  SubTask({required this.name, this.weight = 0, this.completed = false});

  @override
  int compareTo(SubTask st2) => name.compareTo(st2.name);

  // Instead this might need to implement a serializable interface. Ditto for large tasks
  @override
  SubTask copy() => SubTask(name: name, completed: completed);
  @override
  SubTask copyWith({String? name, bool? completed}) => SubTask(name: name ?? this.name, completed: completed ?? this.completed);

}

class LargeTask extends ToDo implements Copyable<LargeTask>, Collection<SubTask>{
  // TODO: refactor maxTasks, needs to be in a userprefs thing.
  // HANDLE IN THE REPOSITORY/VM.
  static const maxSubTasks = 5;
  final List<SubTask> subTasks;
  LargeTask(
      {required super.taskID,
        super.groupID,
      required super.name,
      super.description,
        super.expectedDuration = Duration.zero,
        super.priority,
        super.dueDate,
        super.focusTask,
        super.repeatable,
        List<SubTask>? subTasks,
      }) :
      subTasks = subTasks ?? [];

  @override
  LargeTask copy({bool copySubTasks = false}) => LargeTask(
    taskID: taskID,
    groupID: groupID,
    name: name,
    description: description,
    priority: priority,
    dueDate: dueDate,
    focusTask: focusTask,
    repeatable: repeatable,
    subTasks: (copySubTasks) ? List.from(subTasks) : null,
  );

  @override
  LargeTask copyWith({bool copySubTasks = false, int? taskID, int? groupID, String? name, String? description, Priority? priority, DateTime? dueDate, bool? focusTask, bool? repeatable, List<SubTask>? subTasks}) => LargeTask(taskID: taskID?? this.taskID, groupID: groupID ?? this.groupID, name: name ?? this.name, description: description ?? this.description, priority: priority ?? this.priority, dueDate: dueDate ?? this.dueDate, focusTask: focusTask ?? this.focusTask, repeatable: repeatable ?? this.repeatable, subTasks:(copySubTasks) ? List.from(this.subTasks) : subTasks ?? []);

  @override
  void add(SubTask st) {
    subTasks.add(st);
    updateWeight(st.weight);
  }

  @override
  void remove(SubTask st) {
    subTasks.remove(st);
    updateWeight(-st.weight);
  }

  @override
  void reorder(int oldIndex, int newIndex) {
    if(oldIndex < newIndex)
      {
        newIndex--;
      }
    SubTask st = subTasks.removeAt(oldIndex);
    subTasks.insert(newIndex, st);
  }

  // Lol. This may not be called.
  @override
  List<SubTask> sort(){
    List<SubTask> sorted = List.from(subTasks);
    sorted.sort();
    return sorted;
  }

  //{Valid sort methods: name, weight}
  // Consider SubtaskSortMethods, TaskSortMethds, etc.
  // TODO: Determine some way to limit which args?
  @override
  List<SubTask> sortBy({SortMethod sortMethod = SortMethod.name, bool descending = false}) {
    List<SubTask> sorted = List.from(subTasks);
    switch(sortMethod)
    {
      case SortMethod.name:
        sorted.sort();
        break;
      case SortMethod.weight:
        sorted.sort((a, b) => a.weight.compareTo(b.weight));
        break;
      default:
        // TODO: runtime error classes.
        throw Error();
    }

    if(descending)
      {
        sorted = sorted.reversed.toList();
      }
    return sorted;
  }


  // DEAL WITH THIS LATER.
  void updateWeight(int w) => weight = (weight + w > 0) ? weight + w : 0;
  void recalculateWeight() => weight = subTasks.fold(0, (p, c) => p + c.weight);

  //TODO: re-implement.
  @override
  List<Object> get props => super.props..add([subTasks]);


}