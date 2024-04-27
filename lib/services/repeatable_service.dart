import 'package:table_calendar/table_calendar.dart';

import '../model/task/deadline.dart';
import '../model/task/reminder.dart';
import '../model/task/todo.dart';
import '../repositories/deadline_repo.dart';
import '../repositories/reminder_repo.dart';
import '../repositories/todo_repo.dart';
import '../util/constants.dart';
import '../util/enums.dart';
import '../util/exceptions.dart';
import '../util/interfaces/i_repeatable.dart';
import '../util/interfaces/repository/model/deadline_repository.dart';
import '../util/interfaces/repository/model/reminder_repository.dart';
import '../util/interfaces/repository/model/todo_repository.dart';

class RepeatableService {
  static final RepeatableService _instance = RepeatableService._internal();

  static RepeatableService get instance => _instance;

  final ToDoRepository _toDoRepository = ToDoRepo.instance;
  final DeadlineRepository _deadlineRepository = DeadlineRepo.instance;
  final ReminderRepository _reminderRepository = ReminderRepo.instance;

  // NOTE: THIS THROWS
  Future<void> handleRepeating(
      {IRepeatable? oldModel,
      IRepeatable? newModel,
      bool? single = false,
      bool delete = false}) async {
    if (null == oldModel || null == single) {
      return;
    }

    // In the event that a delta object is not sent,
    // this implies a deletion operation is going to happen - From one of the list screens.
    newModel = newModel ?? oldModel;

    // If update all, but no start date/due date from which to update the template.
    if (!single &&
        !delete &&
        (null == oldModel.startDate || null == oldModel.dueDate)) {
      throw InvalidRepeatingException(
          "InvalidRepeating: ${oldModel.toString()}");
    }

    // If this is a future event:
    if (RepeatableState.projected == oldModel.repeatableState) {
      return await handleDelta(model: newModel, single: single, delete: delete);
    }

    // This is for updating a single event which exists, but the next one may not have been
    // generated.
    // -> Generate the next event to prevent data issues
    // -> Consider the existing event to be a delta from the chain of repeating events.
    if (single) {
      // In the case that a model is being deleted, update the template date
      newModel.toDelete = delete;
      switch (oldModel.modelType) {
        case ModelType.task:
          if (isSameDay(newModel.startDate, Constants.today)) {
            await nextRepeat(model: newModel);
            newModel.frequency = Frequency.once;
          }
          newModel.repeatableState = RepeatableState.delta;
          await _toDoRepository.update(newModel as ToDo);
          return;
        case ModelType.deadline:
          if (isSameDay(newModel.startDate, Constants.today)) {
            await nextRepeat(model: newModel);
            newModel.frequency = Frequency.once;
          }
          newModel.repeatableState = RepeatableState.delta;
          await _deadlineRepository.update(newModel as Deadline);
          return;
        case ModelType.reminder:
          if (isSameDay(newModel.startDate, Constants.today)) {
            await nextRepeat(model: newModel);
            newModel.frequency = Frequency.once;
          }
          newModel.repeatableState = RepeatableState.delta;
          await _reminderRepository.update(newModel as Reminder);
          return;
        default:
          return;
      }
    }

    if (delete) {
      return await deleteTemplateAndFutures(model: oldModel);
    }

    // In the case that all models are to be updated, update the template.
    return await updateTemplate(model: newModel);
  }

  Future<void> handleDelta(
      {required IRepeatable model,
      bool single = false,
      bool delete = false}) async {
    // if it's a single update, create a delta in case of future generated models.
    if (single) {
      // These should have the same originalDate + originalDue as expected.
      // Delete is the same as update.
      switch (model.modelType) {
        case ModelType.task:
          ToDo toDo = model as ToDo;
          ToDo delta = toDo.copyWith(
              frequency: Frequency.once,
              repeatableState: RepeatableState.delta,
              myDay: false);
          delta.toDelete = delete;

          delta.id = toDo.id;

          await _toDoRepository.update(delta);
          return;
        case ModelType.deadline:
          Deadline deadline = model as Deadline;
          Deadline delta = deadline.copyWith(
              frequency: Frequency.once,
              repeatableState: RepeatableState.delta);
          delta.toDelete = delete;
          await _deadlineRepository.update(delta);
          return;
        case ModelType.reminder:
          Reminder reminder = model as Reminder;
          Reminder delta = reminder.copyWith(
              frequency: Frequency.once,
              repeatableState: RepeatableState.delta);
          delta.toDelete = delete;
          await _reminderRepository.update(delta);
          return;
        default:
          return;
      }
    }

    // if deleting all, delete the template and delete all models from today onward.
    if (delete) {
      return await deleteTemplateAndFutures(model: model);
    }

    // if updating all, update the template
    await updateTemplate(model: model);
  }

  //This method is/should be called on a day-to-day basis.
  // Atm, not parameterizing the date.
  Future<void> generateNextRepeats() async {
    DateTime today = DateTime.now();
    await Future.wait([
      _toDoRepository.getRepeatables(now: today),
      _deadlineRepository.getRepeatables(now: today),
      _reminderRepository.getRepeatables(now: today)
    ]).then((data) async {
      List<IRepeatable> repeatables = [...data[0], ...data[1], ...data[2]];
      for (IRepeatable repeatable in repeatables) {
        await nextRepeat(model: repeatable);
      }
    });
  }

  Future<void> nextRepeat({IRepeatable? model}) async {
    if (null == model) {
      return;
    }

    DateTime? nextRepeatDate;

    switch (model.modelType) {
      case ModelType.task:
        ToDo toDo = model as ToDo;
        ToDo? template =
            await _toDoRepository.getTemplate(repeatID: model.repeatID!);

        // This should probably throw an error.
        if (null == template ||
            null == template.originalStart ||
            null == template.originalDue) {
          toDo.repeatable = false;
          toDo.frequency = Frequency.once;
          await _toDoRepository.update(toDo);
          return;
        }

        // Get the next repeat date using the template.
        // Use the max date between the template and the original to only
        // update future events.
        DateTime? startDate =
            (toDo.originalStart?.isAfter(template.originalStart!) ?? false)
                ? toDo.originalStart
                : template.originalStart;
        nextRepeatDate =
            getRepeatDate(model: template.copyWith(originalStart: startDate));

        if (null == nextRepeatDate) {
          toDo.repeatable = false;
          toDo.frequency = Frequency.once;
          await _toDoRepository.update(toDo);
          return;
        }

        ToDo? delta = await _toDoRepository.getDelta(
            onDate: nextRepeatDate, repeatID: model.repeatID!);

        int offset = getDateTimeDayOffset(
            start: template.startDate, end: template.dueDate);
        DateTime newDue =
            nextRepeatDate.copyWith(day: nextRepeatDate.day + offset);
        ToDo newToDo;
        // If there is no delta, generate accordingly.
        if (null == delta) {
          newToDo = template.copyWith(
            id: toDo.id + 1,
            startDate: nextRepeatDate,
            originalStart: nextRepeatDate,
            dueDate: newDue,
            originalDue: newDue,
            repeatableState: RepeatableState.normal,
            completed: false,
            repeatable: true,
            isSynced: false,
            myDay: false,
            lastUpdated: DateTime.now(),
          );
        } else {
          newToDo = delta.copyWith(
              id: toDo.id + 1,
              originalStart: nextRepeatDate,
              originalDue: newDue,
              repeatableState: RepeatableState.normal,
              myDay: false,
              isSynced: false,
              lastUpdated: DateTime.now());

          newToDo.toDelete = delta.toDelete;

          await _toDoRepository.delete(delta);
        }

        toDo.repeatable = false;

        // Check for collisions.
        bool inDB = await _toDoRepository.containsID(id: newToDo.id);

        while (inDB) {
          newToDo.id = newToDo.id + 1;
          inDB = await _toDoRepository.containsID(id: newToDo.id);
        }

        return await _toDoRepository.updateBatch([toDo, newToDo]);

      case ModelType.deadline:
        Deadline deadline = model as Deadline;
        Deadline? template =
            await _deadlineRepository.getTemplate(repeatID: model.repeatID!);

        // This should probably throw an error.
        if (null == template ||
            null == template.originalStart ||
            null == template.originalDue) {
          deadline.repeatable = false;
          deadline.frequency = Frequency.once;
          await _deadlineRepository.update(deadline);
          return;
        }

        // Get the next repeat date using the template.
        // Use the max date between the template and the original to only
        // update future events.
        DateTime? startDate =
            (deadline.originalStart?.isAfter(template.originalStart!) ?? false)
                ? deadline.originalStart
                : template.originalStart;

        nextRepeatDate =
            getRepeatDate(model: template.copyWith(originalStart: startDate));
        // Get the next repeat date using the template.
        nextRepeatDate =
            getRepeatDate(model: template.copyWith(originalStart: startDate));

        if (null == nextRepeatDate) {
          deadline.repeatable = false;
          deadline.frequency = Frequency.once;
          await _deadlineRepository.update(deadline);
          return;
        }

        Deadline? delta = await _deadlineRepository.getDelta(
            onDate: nextRepeatDate, repeatID: model.repeatID!);

        int offset = getDateTimeDayOffset(
            start: template.startDate, end: template.dueDate);

        int warnOffset = getDateTimeDayOffset(
            start: template.startDate, end: template.warnDate);
        DateTime newDue =
            nextRepeatDate.copyWith(day: nextRepeatDate.day + offset);

        DateTime newWarn =
            nextRepeatDate.copyWith(day: nextRepeatDate.day + warnOffset);
        Deadline newDeadline;
        // If there is no delta, generate accordingly.
        if (null == delta) {
          newDeadline = template.copyWith(
            id: deadline.id + 1,
            startDate: nextRepeatDate,
            originalStart: nextRepeatDate,
            warnDate: newWarn,
            originalWarn: newWarn,
            dueDate: newDue,
            originalDue: newDue,
            repeatableState: RepeatableState.normal,
            repeatable: true,
            isSynced: false,
            lastUpdated: DateTime.now(),
          );
        } else {
          newDeadline = delta.copyWith(
              id: deadline.id + 1,
              originalStart: nextRepeatDate,
              originalDue: newDue,
              originalWarn: newWarn,
              repeatableState: RepeatableState.normal,
              isSynced: false,
              lastUpdated: DateTime.now());

          newDeadline.toDelete = delta.toDelete;

          // Then, delete the delta
          await _deadlineRepository.delete(delta);
        }
        deadline.repeatable = false;

        // Check for collisions.
        bool inDB = await _deadlineRepository.containsID(id: newDeadline.id);

        while (inDB) {
          newDeadline.id = newDeadline.id + 1;
          inDB = await _deadlineRepository.containsID(id: newDeadline.id);
        }

        return await _deadlineRepository.updateBatch([deadline, newDeadline]);
      case ModelType.reminder:
        Reminder reminder = model as Reminder;
        Reminder? template =
            await _reminderRepository.getTemplate(repeatID: model.repeatID!);

        // This should probably throw an error.
        if (null == template || null == template.originalDue) {
          reminder.repeatable = false;
          reminder.frequency = Frequency.once;
          await _reminderRepository.update(reminder);
          return;
        }

        // Get the next repeat date using the template.
        // Use the max date between the template and the original to only
        // update future events.
        DateTime? dueDate =
            (reminder.originalDue?.isAfter(template.originalDue!) ?? false)
                ? reminder.originalDue
                : template.originalDue;
        // Get the next repeat date using the template.
        nextRepeatDate =
            getRepeatDate(model: template.copyWith(originalDue: dueDate));

        if (null == nextRepeatDate) {
          reminder.repeatable = false;
          reminder.frequency = Frequency.once;
          await _reminderRepository.update(reminder);
          return;
        }

        Reminder? delta = await _reminderRepository.getDelta(
            onDate: nextRepeatDate, repeatID: model.repeatID!);

        Reminder newReminder;
        // If there is no delta, generate accordingly.
        if (null == delta) {
          newReminder = template.copyWith(
            id: reminder.id + 1,
            originalDue: nextRepeatDate,
            dueDate: nextRepeatDate,
            repeatableState: RepeatableState.normal,
            repeatable: true,
            isSynced: false,
            lastUpdated: DateTime.now(),
          );
        } else {
          newReminder = delta.copyWith(
              id: reminder.id + 1,
              originalDue: nextRepeatDate,
              repeatableState: RepeatableState.normal,
              isSynced: false,
              lastUpdated: DateTime.now());

          newReminder.toDelete = delta.toDelete;
          // Then, delete the delta
          await _reminderRepository.delete(delta);
        }

        reminder.repeatable = false;

        // Check for collisions.
        bool inDB = await _reminderRepository.containsID(id: newReminder.id);

        while (inDB) {
          newReminder.id = newReminder.id + 1;
          inDB = await _reminderRepository.containsID(id: newReminder.id);
        }

        return await _reminderRepository.updateBatch([reminder, newReminder]);
      default:
        break;
    }
  }

  Future<void> deleteTemplateAndFutures({IRepeatable? model}) async {
    if (null == model) {
      return;
    }
    switch (model.modelType) {
      case ModelType.task:
        ToDo? template =
            await _toDoRepository.getTemplate(repeatID: model.repeatID!);

        // as a fallback, delete from today
        model.startDate ??= DateTime.now();

        await _toDoRepository.deleteFutures(deleteFrom: model as ToDo);

        // get the next repeating
        ToDo? nextRepeating = await _toDoRepository.getNextRepeat(
            repeatID: model.repeatID!,
            now: Constants.today.copyWith(year: Constants.today.year + 1));
        nextRepeating?.frequency = Frequency.once;
        nextRepeating?.repeatable = false;

        if (null != nextRepeating) {
          await _toDoRepository.update(nextRepeating);
        }

        if (null == template) {
          if (RepeatableState.projected != model.repeatableState) {
            await _toDoRepository.delete(model);
          }
          return;
        }
        await _toDoRepository.delete(template);
        if (RepeatableState.projected != model.repeatableState) {
          await _toDoRepository.delete(model);
        }
        return;
      case ModelType.deadline:
        Deadline? template =
            await _deadlineRepository.getTemplate(repeatID: model.repeatID!);
        model.startDate ??= DateTime.now();
        await _deadlineRepository.deleteFutures(deleteFrom: model as Deadline);

        // get the next repeating
        Deadline? nextRepeating = await _deadlineRepository.getNextRepeat(
            repeatID: model.repeatID!,
            now: Constants.today.copyWith(year: Constants.today.year + 1));
        nextRepeating?.frequency = Frequency.once;
        nextRepeating?.repeatable = false;

        if (null != nextRepeating) {
          await _deadlineRepository.update(nextRepeating);
        }

        if (null == template) {
          if (RepeatableState.projected != model.repeatableState) {
            await _deadlineRepository.delete(model);
          }
          return;
        }
        await _deadlineRepository.delete(template);
        if (RepeatableState.projected != model.repeatableState) {
          await _deadlineRepository.delete(model);
        }
        return;
      case ModelType.reminder:
        Reminder? template =
            await _reminderRepository.getTemplate(repeatID: model.repeatID!);
        model.startDate ??= DateTime.now();
        await _reminderRepository.deleteFutures(deleteFrom: model as Reminder);

        // get the next repeating
        Reminder? nextRepeating = await _reminderRepository.getNextRepeat(
            repeatID: model.repeatID!,
            now: Constants.today.copyWith(year: Constants.today.year + 1));
        nextRepeating?.frequency = Frequency.once;
        nextRepeating?.repeatable = false;

        if (null != nextRepeating) {
          await _reminderRepository.update(nextRepeating);
        }

        if (null == template) {
          if (RepeatableState.projected != model.repeatableState) {
            await _reminderRepository.delete(model);
          }
          return;
        }
        await _reminderRepository.delete(template);
        if (RepeatableState.projected != model.repeatableState) {
          await _reminderRepository.delete(model);
        }
        return;
      default:
        return;
    }
  }

  Future<void> updateTemplate({IRepeatable? model}) async {
    if (null == model) {
      return;
    }

    switch (model.modelType) {
      case ModelType.task:
        ToDo toDo = model as ToDo;

        toDo.repeatableState = RepeatableState.normal;
        ToDo? template =
            await _toDoRepository.getTemplate(repeatID: model.repeatID!);

        if (null == template) {
          toDo.frequency = Frequency.once;
          toDo.repeatable = false;
          await _toDoRepository.update(toDo);
          return;
        }

        int id = template.id;

        template = toDo.copyWith(
          originalStart: toDo.startDate,
          originalDue: toDo.dueDate,
          repeatable: (Frequency.once != toDo.frequency),
          myDay: false,
          repeatableState: RepeatableState.template,
        );

        template.toDelete = (Frequency.once == toDo.frequency);

        toDo.originalStart = toDo.startDate;
        toDo.originalDue = toDo.dueDate;

        template.id = id;

        List<ToDo> repeatables =
            await _toDoRepository.getRepeatables(now: toDo.originalStart);

        // Setting the previous model to false implies this model
        // is the most recent and the next to be generated
        if (repeatables.isNotEmpty) {
          toDo.repeatable = true;
        }

        for (ToDo repeatable in repeatables) {
          repeatable.repeatable = false;
          repeatable.frequency = Frequency.once;
        }

        await _toDoRepository.updateBatch(repeatables);
        await _toDoRepository.update(template);
        await _toDoRepository.update(toDo);
        return;
      case ModelType.deadline:
        Deadline deadline = model as Deadline;
        deadline.repeatableState = RepeatableState.normal;
        Deadline? template =
            await _deadlineRepository.getTemplate(repeatID: model.repeatID!);
        if (null == template) {
          deadline.frequency = Frequency.once;
          deadline.repeatable = false;
          await _deadlineRepository.update(deadline);
          return;
        }
        int id = template.id;

        template = deadline.copyWith(
          originalStart: deadline.startDate,
          originalDue: deadline.dueDate,
          originalWarn: deadline.warnDate,
          repeatable: (Frequency.once != deadline.frequency),
          repeatableState: RepeatableState.template,
        );

        template.toDelete = (Frequency.once == deadline.frequency);

        template.id = id;

        deadline.originalStart = deadline.startDate;
        deadline.originalDue = deadline.dueDate;
        deadline.originalWarn = deadline.warnDate;

        List<Deadline> repeatables = await _deadlineRepository.getRepeatables(
            now: deadline.originalStart);

        if (repeatables.isNotEmpty) {
          deadline.repeatable = true;
        }

        for (Deadline repeatable in repeatables) {
          repeatable.repeatable = false;
          repeatable.frequency = Frequency.once;
        }

        await _deadlineRepository.updateBatch(repeatables);
        await _deadlineRepository.update(template);
        await _deadlineRepository.update(deadline);

        return;
      case ModelType.reminder:
        Reminder reminder = model as Reminder;
        reminder.repeatableState = RepeatableState.normal;
        Reminder? template =
            await _reminderRepository.getTemplate(repeatID: model.repeatID!);
        if (null == template) {
          reminder.frequency = Frequency.once;
          reminder.repeatable = false;
          await _reminderRepository.update(reminder);
          return;
        }
        int id = template.id;

        template = reminder.copyWith(
          originalDue: reminder.dueDate,
          repeatable: (Frequency.once != reminder.frequency),
          repeatableState: RepeatableState.template,
        );

        template.toDelete = (Frequency.once == reminder.frequency);

        template.id = id;

        reminder.originalDue = reminder.dueDate;

        List<Reminder> repeatables =
            await _reminderRepository.getRepeatables(now: reminder.originalDue);

        if (repeatables.isNotEmpty) {
          reminder.repeatable = true;
        }

        for (Reminder repeatable in repeatables) {
          repeatable.repeatable = false;
          repeatable.frequency = Frequency.once;
        }

        await _reminderRepository.updateBatch(repeatables);
        await _reminderRepository.update(template);
        await _reminderRepository.update(reminder);
        return;
      default:
        return;
    }
  }

  Future<List<IRepeatable>> populateCalendar({
    DateTime? limit,
    int? repeatID,
    ModelType? modelType,
    IRepeatable? model,
  }) async {
    if ((null == repeatID || null == modelType) && null == model) {
      return [];
    }

    limit = limit ?? Constants.today;

    modelType = modelType ?? model!.modelType;
    repeatID = repeatID ?? model!.repeatID;

    List<IRepeatable> newRepeatables = List.empty(growable: true);
    switch (modelType) {
      case ModelType.task:
        ToDo? nextRepeating;
        if (null != model) {
          nextRepeating = model as ToDo;
        } else {
          nextRepeating = await _toDoRepository.getNextRepeat(
              repeatID: repeatID!, now: limit);
        }
        if (null == nextRepeating) {
          return newRepeatables;
        }
        ToDo? template = await _toDoRepository.getTemplate(repeatID: repeatID!);
        if (null == template ||
            null == template.originalStart ||
            null == template.originalDue) {
          return newRepeatables;
        }

        DateTime? startDate =
            (nextRepeating.originalStart?.isAfter(template.originalStart!) ??
                    false)
                ? nextRepeating.originalStart
                : template.originalStart;

        if (null == startDate) {
          return newRepeatables;
        }

        while (startDate!.isBefore(limit)) {
          // get the next repeat date
          DateTime? nextRepeatDate =
              getRepeatDate(model: template.copyWith(originalStart: startDate));
          // if it's somehow null, there's an issue and just return early.
          if (null == nextRepeatDate) {
            return newRepeatables;
          }

          int offset = getDateTimeDayOffset(
              start: template.startDate, end: template.dueDate);
          DateTime newDue =
              nextRepeatDate.copyWith(day: nextRepeatDate.day + offset);

          ToDo? delta = await _toDoRepository.getDelta(
              onDate: nextRepeatDate, repeatID: repeatID);

          ToDo newToDo;
          // If there's no delta, create from the template.
          if (null == delta) {
            newToDo = template.copyWith(
              startDate: nextRepeatDate,
              originalStart: nextRepeatDate,
              dueDate: newDue,
              originalDue: newDue,
              repeatableState: RepeatableState.projected,
              completed: false,
              repeatable: true,
              myDay: false,
              isSynced: false,
              lastUpdated: DateTime.now(),
            );

            if (TaskType.small != newToDo.taskType) {
              newToDo.weight = 0;
            }

            newRepeatables.add(newToDo);
          }

          // Increment the loop
          startDate = nextRepeatDate;
        }

        /// DELTAS.

        List<ToDo> deltas = await _toDoRepository.getDeltas(
            repeatID: nextRepeating.repeatID!, now: Constants.today);

        for (ToDo delta in deltas) {
          if (!delta.toDelete) {
            newRepeatables.add(delta);
          }
        }

        break;
      case ModelType.deadline:
        Deadline? nextRepeating;
        if (null != model) {
          nextRepeating = model as Deadline;
        } else {
          nextRepeating = await _deadlineRepository.getNextRepeat(
              repeatID: repeatID!, now: limit);
        }
        if (null == nextRepeating) {
          return newRepeatables;
        }

        Deadline? template =
            await _deadlineRepository.getTemplate(repeatID: repeatID!);
        if (null == template ||
            null == template.originalStart ||
            null == template.originalDue) {
          return newRepeatables;
        }

        DateTime? startDate =
            (nextRepeating.originalStart?.isAfter(template.originalStart!) ??
                    false)
                ? nextRepeating.originalStart
                : template.originalStart;

        if (null == startDate) {
          return newRepeatables;
        }

        while (startDate!.isBefore(limit)) {
          // get the next repeat date
          DateTime? nextRepeatDate =
              getRepeatDate(model: template.copyWith(originalStart: startDate));
          // if it's somehow null, there's an issue and just return early.
          if (null == nextRepeatDate) {
            return newRepeatables;
          }

          int offset = getDateTimeDayOffset(
              start: template.startDate, end: template.dueDate);
          int warnOffset = getDateTimeDayOffset(
              start: template.startDate, end: template.warnDate);

          DateTime? newDue =
              nextRepeatDate.copyWith(day: nextRepeatDate.day + offset);

          DateTime? newWarn =
              nextRepeatDate.copyWith(day: nextRepeatDate.day + warnOffset);

          Deadline? delta = await _deadlineRepository.getDelta(
              onDate: nextRepeatDate, repeatID: repeatID);

          Deadline newDeadline;
          // If there's no delta, create from the template.
          if (null == delta) {
            newDeadline = template.copyWith(
              startDate: nextRepeatDate,
              originalStart: nextRepeatDate,
              dueDate: newDue,
              originalDue: newDue,
              warnDate: newWarn,
              originalWarn: newWarn,
              repeatableState: RepeatableState.projected,
              repeatable: true,
              isSynced: false,
              lastUpdated: DateTime.now(),
            );
            newRepeatables.add(newDeadline);
          }

          // Increment the loop
          startDate = nextRepeatDate;
        }

        /// DELTAS.

        List<Deadline> deltas = await _deadlineRepository.getDeltas(
            repeatID: nextRepeating.repeatID!, now: Constants.today);

        for (Deadline delta in deltas) {
          if (!delta.toDelete) {
            newRepeatables.add(delta);
          }
        }
        break;
      case ModelType.reminder:
        Reminder? nextRepeating;
        if (null != model) {
          nextRepeating = model as Reminder;
        } else {
          nextRepeating = await _reminderRepository.getNextRepeat(
              repeatID: repeatID!, now: limit);
        }
        if (null == nextRepeating) {
          return newRepeatables;
        }
        Reminder? template =
            await _reminderRepository.getTemplate(repeatID: repeatID!);
        if (null == template || null == template.originalDue) {
          return newRepeatables;
        }

        DateTime? dueDate =
            (nextRepeating.originalDue?.isAfter(template.originalDue!) ?? false)
                ? nextRepeating.originalStart
                : template.originalStart;

        if (null == dueDate) {
          return newRepeatables;
        }

        while (dueDate!.isBefore(limit)) {
          // get the next repeat date
          DateTime? nextRepeatDate =
              getRepeatDate(model: template.copyWith(originalDue: dueDate));
          // if it's somehow null, there's an issue and just return early.
          if (null == nextRepeatDate) {
            return newRepeatables;
          }

          Reminder? delta = await _reminderRepository.getDelta(
              onDate: nextRepeatDate, repeatID: repeatID);
          Reminder newReminder;
          // If there's no delta, create from the template.
          if (null == delta) {
            newReminder = template.copyWith(
              dueDate: nextRepeatDate,
              originalDue: nextRepeatDate,
              repeatableState: RepeatableState.projected,
              repeatable: true,
              isSynced: false,
              lastUpdated: DateTime.now(),
            );
            newRepeatables.add(newReminder);
          }

          // Increment the loop
          dueDate = nextRepeatDate;
        }

        /// DELTAS.

        List<Reminder> deltas = await _reminderRepository.getDeltas(
            repeatID: nextRepeating.repeatID!, now: Constants.today);

        for (Reminder delta in deltas) {
          if (!delta.toDelete) {
            newRepeatables.add(delta);
          }
        }

        break;
      default:
        return newRepeatables;
    }

    return newRepeatables;
  }

  Future<List<int>> deleteFutures({IRepeatable? model}) async {
    if (null == model) {
      return [];
    }

    // This may not cast properly.
    return switch (model.modelType) {
      ModelType.deadline =>
        await _deadlineRepository.deleteFutures(deleteFrom: model as Deadline),
      ModelType.reminder =>
        await _reminderRepository.deleteFutures(deleteFrom: model as Reminder),
      _ => await _toDoRepository.deleteFutures(deleteFrom: model as ToDo),
    };
  }

  int getDateTimeDayOffset({DateTime? start, DateTime? end}) {
    if (null == start || null == end) {
      return 0;
    }
    start = DateTime.utc(start.year, start.month, start.day, start.hour,
        start.minute, start.second, start.millisecond, start.microsecond);
    end = DateTime.utc(end.year, end.month, end.day, end.hour, end.minute,
        end.second, end.millisecond, end.microsecond);
    return end.difference(start).inDays;
  }

  DateTime? getRepeatDate({IRepeatable? model}) {
    if (null == model) {
      return null;
    }
    if (null == model.originalStart) {
      return null;
    }
    return switch (model.frequency) {
      Frequency.daily => model.originalStart!.copyWith(
          day: model.originalStart!.day + model.repeatSkip,
        ),
      Frequency.weekly => model.originalStart!.copyWith(
          day: model.originalStart!.day + (model.repeatSkip * 7),
        ),
      Frequency.monthly => model.originalStart!.copyWith(
          month: model.originalStart!.month + model.repeatSkip,
        ),
      Frequency.yearly => model.originalStart!.copyWith(
          year: model.originalStart!.year + model.repeatSkip,
        ),
      Frequency.custom => getCustom(model: model),
      _ => null,
    };
  }

  DateTime? getCustom({IRepeatable? model}) {
    if (null == model) {
      return null;
    }

    int start = model.originalStart!.weekday - 1;
    int end = model.repeatDays.indexOf(true, start + 1 % 7);
    int offset = 0;
    if (end == -1) {
      end = model.repeatDays.indexOf(true);
      offset = (end - start).abs();
      return model.originalStart!.copyWith(
          day: model.originalStart!.day + (7 * model.repeatSkip) - offset);
    }
    offset = (end - start).abs();

    return model.originalStart!
        .copyWith(day: model.originalStart!.day + offset);
  }

  RepeatableService._internal();
}
