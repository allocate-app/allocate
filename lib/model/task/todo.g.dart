// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'todo.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetToDoCollection on Isar {
  IsarCollection<ToDo> get toDos => this.collection();
}

const ToDoSchema = CollectionSchema(
  name: r'ToDo',
  id: 8921182537089852344,
  properties: {
    r'completed': PropertySchema(
      id: 0,
      name: r'completed',
      type: IsarType.bool,
    ),
    r'customViewIndex': PropertySchema(
      id: 1,
      name: r'customViewIndex',
      type: IsarType.long,
    ),
    r'description': PropertySchema(
      id: 2,
      name: r'description',
      type: IsarType.string,
    ),
    r'dueDate': PropertySchema(
      id: 3,
      name: r'dueDate',
      type: IsarType.dateTime,
    ),
    r'expectedDuration': PropertySchema(
      id: 4,
      name: r'expectedDuration',
      type: IsarType.long,
    ),
    r'frequency': PropertySchema(
      id: 5,
      name: r'frequency',
      type: IsarType.byte,
      enumMap: _ToDofrequencyEnumValueMap,
    ),
    r'groupID': PropertySchema(
      id: 6,
      name: r'groupID',
      type: IsarType.long,
    ),
    r'groupIndex': PropertySchema(
      id: 7,
      name: r'groupIndex',
      type: IsarType.long,
    ),
    r'isSynced': PropertySchema(
      id: 8,
      name: r'isSynced',
      type: IsarType.bool,
    ),
    r'lastUpdated': PropertySchema(
      id: 9,
      name: r'lastUpdated',
      type: IsarType.dateTime,
    ),
    r'myDay': PropertySchema(
      id: 10,
      name: r'myDay',
      type: IsarType.bool,
    ),
    r'name': PropertySchema(
      id: 11,
      name: r'name',
      type: IsarType.string,
    ),
    r'originalDue': PropertySchema(
      id: 12,
      name: r'originalDue',
      type: IsarType.dateTime,
    ),
    r'originalStart': PropertySchema(
      id: 13,
      name: r'originalStart',
      type: IsarType.dateTime,
    ),
    r'priority': PropertySchema(
      id: 14,
      name: r'priority',
      type: IsarType.byte,
      enumMap: _ToDopriorityEnumValueMap,
    ),
    r'realDuration': PropertySchema(
      id: 15,
      name: r'realDuration',
      type: IsarType.long,
    ),
    r'repeatDays': PropertySchema(
      id: 16,
      name: r'repeatDays',
      type: IsarType.boolList,
    ),
    r'repeatID': PropertySchema(
      id: 17,
      name: r'repeatID',
      type: IsarType.long,
    ),
    r'repeatSkip': PropertySchema(
      id: 18,
      name: r'repeatSkip',
      type: IsarType.long,
    ),
    r'repeatable': PropertySchema(
      id: 19,
      name: r'repeatable',
      type: IsarType.bool,
    ),
    r'repeatableState': PropertySchema(
      id: 20,
      name: r'repeatableState',
      type: IsarType.byte,
      enumMap: _ToDorepeatableStateEnumValueMap,
    ),
    r'startDate': PropertySchema(
      id: 21,
      name: r'startDate',
      type: IsarType.dateTime,
    ),
    r'taskType': PropertySchema(
      id: 22,
      name: r'taskType',
      type: IsarType.byte,
      enumMap: _ToDotaskTypeEnumValueMap,
    ),
    r'toDelete': PropertySchema(
      id: 23,
      name: r'toDelete',
      type: IsarType.bool,
    ),
    r'weight': PropertySchema(
      id: 24,
      name: r'weight',
      type: IsarType.long,
    )
  },
  estimateSize: _toDoEstimateSize,
  serialize: _toDoSerialize,
  deserialize: _toDoDeserialize,
  deserializeProp: _toDoDeserializeProp,
  idName: r'id',
  indexes: {
    r'groupID': IndexSchema(
      id: 1344231740305601694,
      name: r'groupID',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'groupID',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    ),
    r'name': IndexSchema(
      id: 879695947855722453,
      name: r'name',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'name',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'completed': IndexSchema(
      id: -1755850151728404861,
      name: r'completed',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'completed',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    ),
    r'startDate': IndexSchema(
      id: 7723980484494730382,
      name: r'startDate',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'startDate',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    ),
    r'originalStart': IndexSchema(
      id: 7011030668398527848,
      name: r'originalStart',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'originalStart',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    ),
    r'dueDate': IndexSchema(
      id: -7871003637559820552,
      name: r'dueDate',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'dueDate',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    ),
    r'myDay': IndexSchema(
      id: -2232907535184232127,
      name: r'myDay',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'myDay',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    ),
    r'repeatable': IndexSchema(
      id: -187828716759116876,
      name: r'repeatable',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'repeatable',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    ),
    r'repeatID': IndexSchema(
      id: -1773997408086213934,
      name: r'repeatID',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'repeatID',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    ),
    r'repeatableState': IndexSchema(
      id: 7598622448942463528,
      name: r'repeatableState',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'repeatableState',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    ),
    r'isSynced': IndexSchema(
      id: -39763503327887510,
      name: r'isSynced',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'isSynced',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    ),
    r'toDelete': IndexSchema(
      id: -1258472419680751990,
      name: r'toDelete',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'toDelete',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _toDoGetId,
  getLinks: _toDoGetLinks,
  attach: _toDoAttach,
  version: '3.1.0+1',
);

int _toDoEstimateSize(
  ToDo object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.description.length * 3;
  bytesCount += 3 + object.name.length * 3;
  bytesCount += 3 + object.repeatDays.length;
  return bytesCount;
}

void _toDoSerialize(
  ToDo object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeBool(offsets[0], object.completed);
  writer.writeLong(offsets[1], object.customViewIndex);
  writer.writeString(offsets[2], object.description);
  writer.writeDateTime(offsets[3], object.dueDate);
  writer.writeLong(offsets[4], object.expectedDuration);
  writer.writeByte(offsets[5], object.frequency.index);
  writer.writeLong(offsets[6], object.groupID);
  writer.writeLong(offsets[7], object.groupIndex);
  writer.writeBool(offsets[8], object.isSynced);
  writer.writeDateTime(offsets[9], object.lastUpdated);
  writer.writeBool(offsets[10], object.myDay);
  writer.writeString(offsets[11], object.name);
  writer.writeDateTime(offsets[12], object.originalDue);
  writer.writeDateTime(offsets[13], object.originalStart);
  writer.writeByte(offsets[14], object.priority.index);
  writer.writeLong(offsets[15], object.realDuration);
  writer.writeBoolList(offsets[16], object.repeatDays);
  writer.writeLong(offsets[17], object.repeatID);
  writer.writeLong(offsets[18], object.repeatSkip);
  writer.writeBool(offsets[19], object.repeatable);
  writer.writeByte(offsets[20], object.repeatableState.index);
  writer.writeDateTime(offsets[21], object.startDate);
  writer.writeByte(offsets[22], object.taskType.index);
  writer.writeBool(offsets[23], object.toDelete);
  writer.writeLong(offsets[24], object.weight);
}

ToDo _toDoDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = ToDo(
    completed: reader.readBoolOrNull(offsets[0]) ?? false,
    customViewIndex: reader.readLongOrNull(offsets[1]) ?? -1,
    description: reader.readStringOrNull(offsets[2]) ?? "",
    dueDate: reader.readDateTimeOrNull(offsets[3]),
    expectedDuration: reader.readLong(offsets[4]),
    frequency: _ToDofrequencyValueEnumMap[reader.readByteOrNull(offsets[5])] ??
        Frequency.once,
    groupID: reader.readLongOrNull(offsets[6]),
    groupIndex: reader.readLongOrNull(offsets[7]) ?? -1,
    lastUpdated: reader.readDateTime(offsets[9]),
    myDay: reader.readBoolOrNull(offsets[10]) ?? false,
    name: reader.readString(offsets[11]),
    originalDue: reader.readDateTimeOrNull(offsets[12]),
    originalStart: reader.readDateTimeOrNull(offsets[13]),
    priority: _ToDopriorityValueEnumMap[reader.readByteOrNull(offsets[14])] ??
        Priority.low,
    realDuration: reader.readLong(offsets[15]),
    repeatDays: reader.readBoolList(offsets[16]) ?? [],
    repeatID: reader.readLongOrNull(offsets[17]),
    repeatSkip: reader.readLongOrNull(offsets[18]) ?? 1,
    repeatable: reader.readBoolOrNull(offsets[19]) ?? false,
    repeatableState:
        _ToDorepeatableStateValueEnumMap[reader.readByteOrNull(offsets[20])] ??
            RepeatableState.normal,
    startDate: reader.readDateTimeOrNull(offsets[21]),
    taskType: _ToDotaskTypeValueEnumMap[reader.readByteOrNull(offsets[22])] ??
        TaskType.small,
    weight: reader.readLongOrNull(offsets[24]) ?? 0,
  );
  object.id = id;
  object.isSynced = reader.readBool(offsets[8]);
  object.toDelete = reader.readBool(offsets[23]);
  return object;
}

P _toDoDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readBoolOrNull(offset) ?? false) as P;
    case 1:
      return (reader.readLongOrNull(offset) ?? -1) as P;
    case 2:
      return (reader.readStringOrNull(offset) ?? "") as P;
    case 3:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 4:
      return (reader.readLong(offset)) as P;
    case 5:
      return (_ToDofrequencyValueEnumMap[reader.readByteOrNull(offset)] ??
          Frequency.once) as P;
    case 6:
      return (reader.readLongOrNull(offset)) as P;
    case 7:
      return (reader.readLongOrNull(offset) ?? -1) as P;
    case 8:
      return (reader.readBool(offset)) as P;
    case 9:
      return (reader.readDateTime(offset)) as P;
    case 10:
      return (reader.readBoolOrNull(offset) ?? false) as P;
    case 11:
      return (reader.readString(offset)) as P;
    case 12:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 13:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 14:
      return (_ToDopriorityValueEnumMap[reader.readByteOrNull(offset)] ??
          Priority.low) as P;
    case 15:
      return (reader.readLong(offset)) as P;
    case 16:
      return (reader.readBoolList(offset) ?? []) as P;
    case 17:
      return (reader.readLongOrNull(offset)) as P;
    case 18:
      return (reader.readLongOrNull(offset) ?? 1) as P;
    case 19:
      return (reader.readBoolOrNull(offset) ?? false) as P;
    case 20:
      return (_ToDorepeatableStateValueEnumMap[reader.readByteOrNull(offset)] ??
          RepeatableState.normal) as P;
    case 21:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 22:
      return (_ToDotaskTypeValueEnumMap[reader.readByteOrNull(offset)] ??
          TaskType.small) as P;
    case 23:
      return (reader.readBool(offset)) as P;
    case 24:
      return (reader.readLongOrNull(offset) ?? 0) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

const _ToDofrequencyEnumValueMap = {
  'once': 0,
  'daily': 1,
  'weekly': 2,
  'monthly': 3,
  'yearly': 4,
  'custom': 5,
};
const _ToDofrequencyValueEnumMap = {
  0: Frequency.once,
  1: Frequency.daily,
  2: Frequency.weekly,
  3: Frequency.monthly,
  4: Frequency.yearly,
  5: Frequency.custom,
};
const _ToDopriorityEnumValueMap = {
  'low': 0,
  'medium': 1,
  'high': 2,
};
const _ToDopriorityValueEnumMap = {
  0: Priority.low,
  1: Priority.medium,
  2: Priority.high,
};
const _ToDorepeatableStateEnumValueMap = {
  'normal': 0,
  'projected': 1,
  'template': 2,
  'delta': 3,
};
const _ToDorepeatableStateValueEnumMap = {
  0: RepeatableState.normal,
  1: RepeatableState.projected,
  2: RepeatableState.template,
  3: RepeatableState.delta,
};
const _ToDotaskTypeEnumValueMap = {
  'small': 0,
  'large': 1,
  'huge': 2,
};
const _ToDotaskTypeValueEnumMap = {
  0: TaskType.small,
  1: TaskType.large,
  2: TaskType.huge,
};

Id _toDoGetId(ToDo object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _toDoGetLinks(ToDo object) {
  return [];
}

void _toDoAttach(IsarCollection<dynamic> col, Id id, ToDo object) {
  object.id = id;
}

extension ToDoQueryWhereSort on QueryBuilder<ToDo, ToDo, QWhere> {
  QueryBuilder<ToDo, ToDo, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterWhere> anyGroupID() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'groupID'),
      );
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterWhere> anyCompleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'completed'),
      );
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterWhere> anyStartDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'startDate'),
      );
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterWhere> anyOriginalStart() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'originalStart'),
      );
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterWhere> anyDueDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'dueDate'),
      );
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterWhere> anyMyDay() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'myDay'),
      );
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterWhere> anyRepeatable() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'repeatable'),
      );
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterWhere> anyRepeatID() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'repeatID'),
      );
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterWhere> anyRepeatableState() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'repeatableState'),
      );
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterWhere> anyIsSynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'isSynced'),
      );
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterWhere> anyToDelete() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'toDelete'),
      );
    });
  }
}

extension ToDoQueryWhere on QueryBuilder<ToDo, ToDo, QWhereClause> {
  QueryBuilder<ToDo, ToDo, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterWhereClause> idNotEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterWhereClause> groupIDIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'groupID',
        value: [null],
      ));
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterWhereClause> groupIDIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'groupID',
        lower: [null],
        includeLower: false,
        upper: [],
      ));
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterWhereClause> groupIDEqualTo(int? groupID) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'groupID',
        value: [groupID],
      ));
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterWhereClause> groupIDNotEqualTo(int? groupID) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'groupID',
              lower: [],
              upper: [groupID],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'groupID',
              lower: [groupID],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'groupID',
              lower: [groupID],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'groupID',
              lower: [],
              upper: [groupID],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterWhereClause> groupIDGreaterThan(
    int? groupID, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'groupID',
        lower: [groupID],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterWhereClause> groupIDLessThan(
    int? groupID, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'groupID',
        lower: [],
        upper: [groupID],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterWhereClause> groupIDBetween(
    int? lowerGroupID,
    int? upperGroupID, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'groupID',
        lower: [lowerGroupID],
        includeLower: includeLower,
        upper: [upperGroupID],
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterWhereClause> nameEqualTo(String name) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'name',
        value: [name],
      ));
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterWhereClause> nameNotEqualTo(String name) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'name',
              lower: [],
              upper: [name],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'name',
              lower: [name],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'name',
              lower: [name],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'name',
              lower: [],
              upper: [name],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterWhereClause> completedEqualTo(bool completed) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'completed',
        value: [completed],
      ));
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterWhereClause> completedNotEqualTo(
      bool completed) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'completed',
              lower: [],
              upper: [completed],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'completed',
              lower: [completed],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'completed',
              lower: [completed],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'completed',
              lower: [],
              upper: [completed],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterWhereClause> startDateIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'startDate',
        value: [null],
      ));
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterWhereClause> startDateIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'startDate',
        lower: [null],
        includeLower: false,
        upper: [],
      ));
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterWhereClause> startDateEqualTo(
      DateTime? startDate) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'startDate',
        value: [startDate],
      ));
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterWhereClause> startDateNotEqualTo(
      DateTime? startDate) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'startDate',
              lower: [],
              upper: [startDate],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'startDate',
              lower: [startDate],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'startDate',
              lower: [startDate],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'startDate',
              lower: [],
              upper: [startDate],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterWhereClause> startDateGreaterThan(
    DateTime? startDate, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'startDate',
        lower: [startDate],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterWhereClause> startDateLessThan(
    DateTime? startDate, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'startDate',
        lower: [],
        upper: [startDate],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterWhereClause> startDateBetween(
    DateTime? lowerStartDate,
    DateTime? upperStartDate, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'startDate',
        lower: [lowerStartDate],
        includeLower: includeLower,
        upper: [upperStartDate],
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterWhereClause> originalStartIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'originalStart',
        value: [null],
      ));
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterWhereClause> originalStartIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'originalStart',
        lower: [null],
        includeLower: false,
        upper: [],
      ));
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterWhereClause> originalStartEqualTo(
      DateTime? originalStart) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'originalStart',
        value: [originalStart],
      ));
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterWhereClause> originalStartNotEqualTo(
      DateTime? originalStart) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'originalStart',
              lower: [],
              upper: [originalStart],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'originalStart',
              lower: [originalStart],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'originalStart',
              lower: [originalStart],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'originalStart',
              lower: [],
              upper: [originalStart],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterWhereClause> originalStartGreaterThan(
    DateTime? originalStart, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'originalStart',
        lower: [originalStart],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterWhereClause> originalStartLessThan(
    DateTime? originalStart, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'originalStart',
        lower: [],
        upper: [originalStart],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterWhereClause> originalStartBetween(
    DateTime? lowerOriginalStart,
    DateTime? upperOriginalStart, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'originalStart',
        lower: [lowerOriginalStart],
        includeLower: includeLower,
        upper: [upperOriginalStart],
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterWhereClause> dueDateIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'dueDate',
        value: [null],
      ));
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterWhereClause> dueDateIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'dueDate',
        lower: [null],
        includeLower: false,
        upper: [],
      ));
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterWhereClause> dueDateEqualTo(
      DateTime? dueDate) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'dueDate',
        value: [dueDate],
      ));
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterWhereClause> dueDateNotEqualTo(
      DateTime? dueDate) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'dueDate',
              lower: [],
              upper: [dueDate],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'dueDate',
              lower: [dueDate],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'dueDate',
              lower: [dueDate],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'dueDate',
              lower: [],
              upper: [dueDate],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterWhereClause> dueDateGreaterThan(
    DateTime? dueDate, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'dueDate',
        lower: [dueDate],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterWhereClause> dueDateLessThan(
    DateTime? dueDate, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'dueDate',
        lower: [],
        upper: [dueDate],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterWhereClause> dueDateBetween(
    DateTime? lowerDueDate,
    DateTime? upperDueDate, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'dueDate',
        lower: [lowerDueDate],
        includeLower: includeLower,
        upper: [upperDueDate],
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterWhereClause> myDayEqualTo(bool myDay) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'myDay',
        value: [myDay],
      ));
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterWhereClause> myDayNotEqualTo(bool myDay) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'myDay',
              lower: [],
              upper: [myDay],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'myDay',
              lower: [myDay],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'myDay',
              lower: [myDay],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'myDay',
              lower: [],
              upper: [myDay],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterWhereClause> repeatableEqualTo(
      bool repeatable) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'repeatable',
        value: [repeatable],
      ));
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterWhereClause> repeatableNotEqualTo(
      bool repeatable) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'repeatable',
              lower: [],
              upper: [repeatable],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'repeatable',
              lower: [repeatable],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'repeatable',
              lower: [repeatable],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'repeatable',
              lower: [],
              upper: [repeatable],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterWhereClause> repeatIDIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'repeatID',
        value: [null],
      ));
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterWhereClause> repeatIDIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'repeatID',
        lower: [null],
        includeLower: false,
        upper: [],
      ));
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterWhereClause> repeatIDEqualTo(int? repeatID) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'repeatID',
        value: [repeatID],
      ));
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterWhereClause> repeatIDNotEqualTo(
      int? repeatID) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'repeatID',
              lower: [],
              upper: [repeatID],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'repeatID',
              lower: [repeatID],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'repeatID',
              lower: [repeatID],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'repeatID',
              lower: [],
              upper: [repeatID],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterWhereClause> repeatIDGreaterThan(
    int? repeatID, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'repeatID',
        lower: [repeatID],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterWhereClause> repeatIDLessThan(
    int? repeatID, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'repeatID',
        lower: [],
        upper: [repeatID],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterWhereClause> repeatIDBetween(
    int? lowerRepeatID,
    int? upperRepeatID, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'repeatID',
        lower: [lowerRepeatID],
        includeLower: includeLower,
        upper: [upperRepeatID],
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterWhereClause> repeatableStateEqualTo(
      RepeatableState repeatableState) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'repeatableState',
        value: [repeatableState],
      ));
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterWhereClause> repeatableStateNotEqualTo(
      RepeatableState repeatableState) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'repeatableState',
              lower: [],
              upper: [repeatableState],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'repeatableState',
              lower: [repeatableState],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'repeatableState',
              lower: [repeatableState],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'repeatableState',
              lower: [],
              upper: [repeatableState],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterWhereClause> repeatableStateGreaterThan(
    RepeatableState repeatableState, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'repeatableState',
        lower: [repeatableState],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterWhereClause> repeatableStateLessThan(
    RepeatableState repeatableState, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'repeatableState',
        lower: [],
        upper: [repeatableState],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterWhereClause> repeatableStateBetween(
    RepeatableState lowerRepeatableState,
    RepeatableState upperRepeatableState, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'repeatableState',
        lower: [lowerRepeatableState],
        includeLower: includeLower,
        upper: [upperRepeatableState],
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterWhereClause> isSyncedEqualTo(bool isSynced) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'isSynced',
        value: [isSynced],
      ));
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterWhereClause> isSyncedNotEqualTo(
      bool isSynced) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'isSynced',
              lower: [],
              upper: [isSynced],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'isSynced',
              lower: [isSynced],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'isSynced',
              lower: [isSynced],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'isSynced',
              lower: [],
              upper: [isSynced],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterWhereClause> toDeleteEqualTo(bool toDelete) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'toDelete',
        value: [toDelete],
      ));
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterWhereClause> toDeleteNotEqualTo(
      bool toDelete) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'toDelete',
              lower: [],
              upper: [toDelete],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'toDelete',
              lower: [toDelete],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'toDelete',
              lower: [toDelete],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'toDelete',
              lower: [],
              upper: [toDelete],
              includeUpper: false,
            ));
      }
    });
  }
}

extension ToDoQueryFilter on QueryBuilder<ToDo, ToDo, QFilterCondition> {
  QueryBuilder<ToDo, ToDo, QAfterFilterCondition> completedEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'completed',
        value: value,
      ));
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterFilterCondition> customViewIndexEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'customViewIndex',
        value: value,
      ));
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterFilterCondition> customViewIndexGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'customViewIndex',
        value: value,
      ));
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterFilterCondition> customViewIndexLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'customViewIndex',
        value: value,
      ));
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterFilterCondition> customViewIndexBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'customViewIndex',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterFilterCondition> descriptionEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterFilterCondition> descriptionGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterFilterCondition> descriptionLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterFilterCondition> descriptionBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'description',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterFilterCondition> descriptionStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterFilterCondition> descriptionEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterFilterCondition> descriptionContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterFilterCondition> descriptionMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'description',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterFilterCondition> descriptionIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'description',
        value: '',
      ));
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterFilterCondition> descriptionIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'description',
        value: '',
      ));
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterFilterCondition> dueDateIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'dueDate',
      ));
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterFilterCondition> dueDateIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'dueDate',
      ));
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterFilterCondition> dueDateEqualTo(
      DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'dueDate',
        value: value,
      ));
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterFilterCondition> dueDateGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'dueDate',
        value: value,
      ));
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterFilterCondition> dueDateLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'dueDate',
        value: value,
      ));
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterFilterCondition> dueDateBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'dueDate',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterFilterCondition> expectedDurationEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'expectedDuration',
        value: value,
      ));
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterFilterCondition> expectedDurationGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'expectedDuration',
        value: value,
      ));
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterFilterCondition> expectedDurationLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'expectedDuration',
        value: value,
      ));
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterFilterCondition> expectedDurationBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'expectedDuration',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterFilterCondition> frequencyEqualTo(
      Frequency value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'frequency',
        value: value,
      ));
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterFilterCondition> frequencyGreaterThan(
    Frequency value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'frequency',
        value: value,
      ));
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterFilterCondition> frequencyLessThan(
    Frequency value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'frequency',
        value: value,
      ));
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterFilterCondition> frequencyBetween(
    Frequency lower,
    Frequency upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'frequency',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterFilterCondition> groupIDIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'groupID',
      ));
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterFilterCondition> groupIDIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'groupID',
      ));
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterFilterCondition> groupIDEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'groupID',
        value: value,
      ));
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterFilterCondition> groupIDGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'groupID',
        value: value,
      ));
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterFilterCondition> groupIDLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'groupID',
        value: value,
      ));
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterFilterCondition> groupIDBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'groupID',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterFilterCondition> groupIndexEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'groupIndex',
        value: value,
      ));
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterFilterCondition> groupIndexGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'groupIndex',
        value: value,
      ));
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterFilterCondition> groupIndexLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'groupIndex',
        value: value,
      ));
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterFilterCondition> groupIndexBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'groupIndex',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterFilterCondition> idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterFilterCondition> idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterFilterCondition> idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterFilterCondition> isSyncedEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isSynced',
        value: value,
      ));
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterFilterCondition> lastUpdatedEqualTo(
      DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastUpdated',
        value: value,
      ));
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterFilterCondition> lastUpdatedGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'lastUpdated',
        value: value,
      ));
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterFilterCondition> lastUpdatedLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'lastUpdated',
        value: value,
      ));
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterFilterCondition> lastUpdatedBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'lastUpdated',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterFilterCondition> myDayEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'myDay',
        value: value,
      ));
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterFilterCondition> nameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterFilterCondition> nameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterFilterCondition> nameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterFilterCondition> nameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'name',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterFilterCondition> nameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterFilterCondition> nameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterFilterCondition> nameContains(String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterFilterCondition> nameMatches(String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'name',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterFilterCondition> nameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterFilterCondition> nameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterFilterCondition> originalDueIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'originalDue',
      ));
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterFilterCondition> originalDueIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'originalDue',
      ));
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterFilterCondition> originalDueEqualTo(
      DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'originalDue',
        value: value,
      ));
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterFilterCondition> originalDueGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'originalDue',
        value: value,
      ));
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterFilterCondition> originalDueLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'originalDue',
        value: value,
      ));
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterFilterCondition> originalDueBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'originalDue',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterFilterCondition> originalStartIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'originalStart',
      ));
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterFilterCondition> originalStartIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'originalStart',
      ));
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterFilterCondition> originalStartEqualTo(
      DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'originalStart',
        value: value,
      ));
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterFilterCondition> originalStartGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'originalStart',
        value: value,
      ));
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterFilterCondition> originalStartLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'originalStart',
        value: value,
      ));
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterFilterCondition> originalStartBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'originalStart',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterFilterCondition> priorityEqualTo(
      Priority value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'priority',
        value: value,
      ));
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterFilterCondition> priorityGreaterThan(
    Priority value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'priority',
        value: value,
      ));
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterFilterCondition> priorityLessThan(
    Priority value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'priority',
        value: value,
      ));
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterFilterCondition> priorityBetween(
    Priority lower,
    Priority upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'priority',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterFilterCondition> realDurationEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'realDuration',
        value: value,
      ));
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterFilterCondition> realDurationGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'realDuration',
        value: value,
      ));
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterFilterCondition> realDurationLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'realDuration',
        value: value,
      ));
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterFilterCondition> realDurationBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'realDuration',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterFilterCondition> repeatDaysElementEqualTo(
      bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'repeatDays',
        value: value,
      ));
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterFilterCondition> repeatDaysLengthEqualTo(
      int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'repeatDays',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterFilterCondition> repeatDaysIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'repeatDays',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterFilterCondition> repeatDaysIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'repeatDays',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterFilterCondition> repeatDaysLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'repeatDays',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterFilterCondition> repeatDaysLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'repeatDays',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterFilterCondition> repeatDaysLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'repeatDays',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterFilterCondition> repeatIDIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'repeatID',
      ));
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterFilterCondition> repeatIDIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'repeatID',
      ));
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterFilterCondition> repeatIDEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'repeatID',
        value: value,
      ));
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterFilterCondition> repeatIDGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'repeatID',
        value: value,
      ));
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterFilterCondition> repeatIDLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'repeatID',
        value: value,
      ));
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterFilterCondition> repeatIDBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'repeatID',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterFilterCondition> repeatSkipEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'repeatSkip',
        value: value,
      ));
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterFilterCondition> repeatSkipGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'repeatSkip',
        value: value,
      ));
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterFilterCondition> repeatSkipLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'repeatSkip',
        value: value,
      ));
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterFilterCondition> repeatSkipBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'repeatSkip',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterFilterCondition> repeatableEqualTo(
      bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'repeatable',
        value: value,
      ));
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterFilterCondition> repeatableStateEqualTo(
      RepeatableState value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'repeatableState',
        value: value,
      ));
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterFilterCondition> repeatableStateGreaterThan(
    RepeatableState value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'repeatableState',
        value: value,
      ));
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterFilterCondition> repeatableStateLessThan(
    RepeatableState value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'repeatableState',
        value: value,
      ));
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterFilterCondition> repeatableStateBetween(
    RepeatableState lower,
    RepeatableState upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'repeatableState',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterFilterCondition> startDateIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'startDate',
      ));
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterFilterCondition> startDateIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'startDate',
      ));
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterFilterCondition> startDateEqualTo(
      DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'startDate',
        value: value,
      ));
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterFilterCondition> startDateGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'startDate',
        value: value,
      ));
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterFilterCondition> startDateLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'startDate',
        value: value,
      ));
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterFilterCondition> startDateBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'startDate',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterFilterCondition> taskTypeEqualTo(
      TaskType value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'taskType',
        value: value,
      ));
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterFilterCondition> taskTypeGreaterThan(
    TaskType value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'taskType',
        value: value,
      ));
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterFilterCondition> taskTypeLessThan(
    TaskType value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'taskType',
        value: value,
      ));
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterFilterCondition> taskTypeBetween(
    TaskType lower,
    TaskType upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'taskType',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterFilterCondition> toDeleteEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'toDelete',
        value: value,
      ));
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterFilterCondition> weightEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'weight',
        value: value,
      ));
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterFilterCondition> weightGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'weight',
        value: value,
      ));
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterFilterCondition> weightLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'weight',
        value: value,
      ));
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterFilterCondition> weightBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'weight',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension ToDoQueryObject on QueryBuilder<ToDo, ToDo, QFilterCondition> {}

extension ToDoQueryLinks on QueryBuilder<ToDo, ToDo, QFilterCondition> {}

extension ToDoQuerySortBy on QueryBuilder<ToDo, ToDo, QSortBy> {
  QueryBuilder<ToDo, ToDo, QAfterSortBy> sortByCompleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'completed', Sort.asc);
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterSortBy> sortByCompletedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'completed', Sort.desc);
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterSortBy> sortByCustomViewIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'customViewIndex', Sort.asc);
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterSortBy> sortByCustomViewIndexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'customViewIndex', Sort.desc);
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterSortBy> sortByDescription() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.asc);
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterSortBy> sortByDescriptionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.desc);
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterSortBy> sortByDueDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dueDate', Sort.asc);
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterSortBy> sortByDueDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dueDate', Sort.desc);
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterSortBy> sortByExpectedDuration() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'expectedDuration', Sort.asc);
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterSortBy> sortByExpectedDurationDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'expectedDuration', Sort.desc);
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterSortBy> sortByFrequency() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'frequency', Sort.asc);
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterSortBy> sortByFrequencyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'frequency', Sort.desc);
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterSortBy> sortByGroupID() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'groupID', Sort.asc);
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterSortBy> sortByGroupIDDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'groupID', Sort.desc);
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterSortBy> sortByGroupIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'groupIndex', Sort.asc);
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterSortBy> sortByGroupIndexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'groupIndex', Sort.desc);
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterSortBy> sortByIsSynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.asc);
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterSortBy> sortByIsSyncedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.desc);
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterSortBy> sortByLastUpdated() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastUpdated', Sort.asc);
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterSortBy> sortByLastUpdatedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastUpdated', Sort.desc);
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterSortBy> sortByMyDay() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'myDay', Sort.asc);
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterSortBy> sortByMyDayDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'myDay', Sort.desc);
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterSortBy> sortByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterSortBy> sortByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterSortBy> sortByOriginalDue() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'originalDue', Sort.asc);
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterSortBy> sortByOriginalDueDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'originalDue', Sort.desc);
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterSortBy> sortByOriginalStart() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'originalStart', Sort.asc);
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterSortBy> sortByOriginalStartDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'originalStart', Sort.desc);
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterSortBy> sortByPriority() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'priority', Sort.asc);
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterSortBy> sortByPriorityDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'priority', Sort.desc);
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterSortBy> sortByRealDuration() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'realDuration', Sort.asc);
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterSortBy> sortByRealDurationDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'realDuration', Sort.desc);
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterSortBy> sortByRepeatID() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'repeatID', Sort.asc);
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterSortBy> sortByRepeatIDDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'repeatID', Sort.desc);
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterSortBy> sortByRepeatSkip() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'repeatSkip', Sort.asc);
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterSortBy> sortByRepeatSkipDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'repeatSkip', Sort.desc);
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterSortBy> sortByRepeatable() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'repeatable', Sort.asc);
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterSortBy> sortByRepeatableDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'repeatable', Sort.desc);
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterSortBy> sortByRepeatableState() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'repeatableState', Sort.asc);
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterSortBy> sortByRepeatableStateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'repeatableState', Sort.desc);
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterSortBy> sortByStartDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startDate', Sort.asc);
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterSortBy> sortByStartDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startDate', Sort.desc);
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterSortBy> sortByTaskType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'taskType', Sort.asc);
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterSortBy> sortByTaskTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'taskType', Sort.desc);
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterSortBy> sortByToDelete() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'toDelete', Sort.asc);
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterSortBy> sortByToDeleteDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'toDelete', Sort.desc);
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterSortBy> sortByWeight() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'weight', Sort.asc);
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterSortBy> sortByWeightDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'weight', Sort.desc);
    });
  }
}

extension ToDoQuerySortThenBy on QueryBuilder<ToDo, ToDo, QSortThenBy> {
  QueryBuilder<ToDo, ToDo, QAfterSortBy> thenByCompleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'completed', Sort.asc);
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterSortBy> thenByCompletedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'completed', Sort.desc);
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterSortBy> thenByCustomViewIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'customViewIndex', Sort.asc);
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterSortBy> thenByCustomViewIndexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'customViewIndex', Sort.desc);
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterSortBy> thenByDescription() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.asc);
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterSortBy> thenByDescriptionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.desc);
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterSortBy> thenByDueDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dueDate', Sort.asc);
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterSortBy> thenByDueDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dueDate', Sort.desc);
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterSortBy> thenByExpectedDuration() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'expectedDuration', Sort.asc);
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterSortBy> thenByExpectedDurationDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'expectedDuration', Sort.desc);
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterSortBy> thenByFrequency() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'frequency', Sort.asc);
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterSortBy> thenByFrequencyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'frequency', Sort.desc);
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterSortBy> thenByGroupID() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'groupID', Sort.asc);
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterSortBy> thenByGroupIDDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'groupID', Sort.desc);
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterSortBy> thenByGroupIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'groupIndex', Sort.asc);
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterSortBy> thenByGroupIndexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'groupIndex', Sort.desc);
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterSortBy> thenByIsSynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.asc);
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterSortBy> thenByIsSyncedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.desc);
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterSortBy> thenByLastUpdated() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastUpdated', Sort.asc);
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterSortBy> thenByLastUpdatedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastUpdated', Sort.desc);
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterSortBy> thenByMyDay() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'myDay', Sort.asc);
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterSortBy> thenByMyDayDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'myDay', Sort.desc);
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterSortBy> thenByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterSortBy> thenByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterSortBy> thenByOriginalDue() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'originalDue', Sort.asc);
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterSortBy> thenByOriginalDueDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'originalDue', Sort.desc);
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterSortBy> thenByOriginalStart() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'originalStart', Sort.asc);
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterSortBy> thenByOriginalStartDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'originalStart', Sort.desc);
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterSortBy> thenByPriority() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'priority', Sort.asc);
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterSortBy> thenByPriorityDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'priority', Sort.desc);
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterSortBy> thenByRealDuration() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'realDuration', Sort.asc);
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterSortBy> thenByRealDurationDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'realDuration', Sort.desc);
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterSortBy> thenByRepeatID() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'repeatID', Sort.asc);
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterSortBy> thenByRepeatIDDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'repeatID', Sort.desc);
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterSortBy> thenByRepeatSkip() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'repeatSkip', Sort.asc);
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterSortBy> thenByRepeatSkipDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'repeatSkip', Sort.desc);
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterSortBy> thenByRepeatable() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'repeatable', Sort.asc);
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterSortBy> thenByRepeatableDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'repeatable', Sort.desc);
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterSortBy> thenByRepeatableState() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'repeatableState', Sort.asc);
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterSortBy> thenByRepeatableStateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'repeatableState', Sort.desc);
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterSortBy> thenByStartDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startDate', Sort.asc);
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterSortBy> thenByStartDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startDate', Sort.desc);
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterSortBy> thenByTaskType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'taskType', Sort.asc);
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterSortBy> thenByTaskTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'taskType', Sort.desc);
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterSortBy> thenByToDelete() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'toDelete', Sort.asc);
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterSortBy> thenByToDeleteDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'toDelete', Sort.desc);
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterSortBy> thenByWeight() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'weight', Sort.asc);
    });
  }

  QueryBuilder<ToDo, ToDo, QAfterSortBy> thenByWeightDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'weight', Sort.desc);
    });
  }
}

extension ToDoQueryWhereDistinct on QueryBuilder<ToDo, ToDo, QDistinct> {
  QueryBuilder<ToDo, ToDo, QDistinct> distinctByCompleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'completed');
    });
  }

  QueryBuilder<ToDo, ToDo, QDistinct> distinctByCustomViewIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'customViewIndex');
    });
  }

  QueryBuilder<ToDo, ToDo, QDistinct> distinctByDescription(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'description', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ToDo, ToDo, QDistinct> distinctByDueDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'dueDate');
    });
  }

  QueryBuilder<ToDo, ToDo, QDistinct> distinctByExpectedDuration() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'expectedDuration');
    });
  }

  QueryBuilder<ToDo, ToDo, QDistinct> distinctByFrequency() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'frequency');
    });
  }

  QueryBuilder<ToDo, ToDo, QDistinct> distinctByGroupID() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'groupID');
    });
  }

  QueryBuilder<ToDo, ToDo, QDistinct> distinctByGroupIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'groupIndex');
    });
  }

  QueryBuilder<ToDo, ToDo, QDistinct> distinctByIsSynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isSynced');
    });
  }

  QueryBuilder<ToDo, ToDo, QDistinct> distinctByLastUpdated() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastUpdated');
    });
  }

  QueryBuilder<ToDo, ToDo, QDistinct> distinctByMyDay() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'myDay');
    });
  }

  QueryBuilder<ToDo, ToDo, QDistinct> distinctByName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'name', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ToDo, ToDo, QDistinct> distinctByOriginalDue() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'originalDue');
    });
  }

  QueryBuilder<ToDo, ToDo, QDistinct> distinctByOriginalStart() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'originalStart');
    });
  }

  QueryBuilder<ToDo, ToDo, QDistinct> distinctByPriority() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'priority');
    });
  }

  QueryBuilder<ToDo, ToDo, QDistinct> distinctByRealDuration() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'realDuration');
    });
  }

  QueryBuilder<ToDo, ToDo, QDistinct> distinctByRepeatDays() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'repeatDays');
    });
  }

  QueryBuilder<ToDo, ToDo, QDistinct> distinctByRepeatID() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'repeatID');
    });
  }

  QueryBuilder<ToDo, ToDo, QDistinct> distinctByRepeatSkip() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'repeatSkip');
    });
  }

  QueryBuilder<ToDo, ToDo, QDistinct> distinctByRepeatable() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'repeatable');
    });
  }

  QueryBuilder<ToDo, ToDo, QDistinct> distinctByRepeatableState() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'repeatableState');
    });
  }

  QueryBuilder<ToDo, ToDo, QDistinct> distinctByStartDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'startDate');
    });
  }

  QueryBuilder<ToDo, ToDo, QDistinct> distinctByTaskType() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'taskType');
    });
  }

  QueryBuilder<ToDo, ToDo, QDistinct> distinctByToDelete() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'toDelete');
    });
  }

  QueryBuilder<ToDo, ToDo, QDistinct> distinctByWeight() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'weight');
    });
  }
}

extension ToDoQueryProperty on QueryBuilder<ToDo, ToDo, QQueryProperty> {
  QueryBuilder<ToDo, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<ToDo, bool, QQueryOperations> completedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'completed');
    });
  }

  QueryBuilder<ToDo, int, QQueryOperations> customViewIndexProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'customViewIndex');
    });
  }

  QueryBuilder<ToDo, String, QQueryOperations> descriptionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'description');
    });
  }

  QueryBuilder<ToDo, DateTime?, QQueryOperations> dueDateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'dueDate');
    });
  }

  QueryBuilder<ToDo, int, QQueryOperations> expectedDurationProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'expectedDuration');
    });
  }

  QueryBuilder<ToDo, Frequency, QQueryOperations> frequencyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'frequency');
    });
  }

  QueryBuilder<ToDo, int?, QQueryOperations> groupIDProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'groupID');
    });
  }

  QueryBuilder<ToDo, int, QQueryOperations> groupIndexProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'groupIndex');
    });
  }

  QueryBuilder<ToDo, bool, QQueryOperations> isSyncedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isSynced');
    });
  }

  QueryBuilder<ToDo, DateTime, QQueryOperations> lastUpdatedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastUpdated');
    });
  }

  QueryBuilder<ToDo, bool, QQueryOperations> myDayProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'myDay');
    });
  }

  QueryBuilder<ToDo, String, QQueryOperations> nameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'name');
    });
  }

  QueryBuilder<ToDo, DateTime?, QQueryOperations> originalDueProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'originalDue');
    });
  }

  QueryBuilder<ToDo, DateTime?, QQueryOperations> originalStartProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'originalStart');
    });
  }

  QueryBuilder<ToDo, Priority, QQueryOperations> priorityProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'priority');
    });
  }

  QueryBuilder<ToDo, int, QQueryOperations> realDurationProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'realDuration');
    });
  }

  QueryBuilder<ToDo, List<bool>, QQueryOperations> repeatDaysProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'repeatDays');
    });
  }

  QueryBuilder<ToDo, int?, QQueryOperations> repeatIDProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'repeatID');
    });
  }

  QueryBuilder<ToDo, int, QQueryOperations> repeatSkipProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'repeatSkip');
    });
  }

  QueryBuilder<ToDo, bool, QQueryOperations> repeatableProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'repeatable');
    });
  }

  QueryBuilder<ToDo, RepeatableState, QQueryOperations>
      repeatableStateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'repeatableState');
    });
  }

  QueryBuilder<ToDo, DateTime?, QQueryOperations> startDateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'startDate');
    });
  }

  QueryBuilder<ToDo, TaskType, QQueryOperations> taskTypeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'taskType');
    });
  }

  QueryBuilder<ToDo, bool, QQueryOperations> toDeleteProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'toDelete');
    });
  }

  QueryBuilder<ToDo, int, QQueryOperations> weightProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'weight');
    });
  }
}
