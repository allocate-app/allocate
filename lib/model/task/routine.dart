import "../../util/interfaces/collection.dart";
// TODO: fix lt reference once subtasks factored out.
import "../../util/interfaces/copyable.dart";
import "../../util/numbers.dart";
import "largetask.dart";

enum RoutineTime{morning, afternoon, evening}

// TODO: this should implement a repeatable interface, once written.
// Store in a separate table.
class Routine implements Collection<SubTask>, Comparable<Routine>, Copyable<Routine>{
  // Factor this out to a user preferences class mb?
  // Or a constructor setting > with a scale of 0-10?
  // Not sure; figure this out.

  // OR! Hear me out: a maximum weight? I am unsure.
  int maxTasksPerRoutine = 10;
  int routineID;
  String name;
  // Consider making this an ID.
  RoutineTime routineTime;
  int weight;
  Duration expectedDuration;
  // This may need to be a thing? not sure yet.
  bool repeatable;
  List<SubTask> routineTasks = [];

  Routine({required this.routineID, required this.name, required this.routineTime, this.weight = 0, this.expectedDuration = const Duration(hours: 1), this.repeatable = true});

  Duration get realDuration
  {
    num factor = smoothstep(x: weight, v0: 1, v1: 10);
    return expectedDuration * factor;
  }

  @override
  int compareTo(Routine r2) => name.compareTo(r2.name);

  @override
  void add(SubTask st) {
    routineTasks.add(st);
    updateWeight(st.weight);
  }

  @override
  void remove(SubTask st) {
    routineTasks.remove(st);
    updateWeight(-st.weight);
  }

  @override
  void reorder(int oldIndex, int newIndex) {
    if(oldIndex < newIndex)
      {
        newIndex--;
      }
    SubTask rt = routineTasks.removeAt(oldIndex);
    routineTasks.insert(newIndex, rt);
  }

  @override
  List<SubTask> sort() {
    List<SubTask> sorted = List.from(routineTasks);
    sorted.sort();
    return sorted;
  }

  // Identical to large task sorting for subtasks.
  @override
  List<SubTask> sortBy() {
    // TODO: implement sortBy
    throw UnimplementedError();
  }

  void updateWeight(int w) => weight = (weight + w > 0) ? weight + w : 0;
  void recalculateWeight() => weight = routineTasks.fold(0, (p, c) => p + c.weight);

  //TODO: implement.
  @override
  List<Object> get props => [];

  @override
  Routine copy() {
    // TODO: implement copy
    throw UnimplementedError();
  }

  @override
  Routine copyWith() {
    // TODO: implement copyWith
    throw UnimplementedError();
  }


}



