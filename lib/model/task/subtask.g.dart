// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subtask.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetSubtaskCollection on Isar {
  IsarCollection<Subtask> get subtasks => this.collection();
}

const SubtaskSchema = CollectionSchema(
  name: r'Subtask',
  id: 8377947618195409234,
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
    r'isSynced': PropertySchema(
      id: 2,
      name: r'isSynced',
      type: IsarType.bool,
    ),
    r'lastUpdated': PropertySchema(
      id: 3,
      name: r'lastUpdated',
      type: IsarType.dateTime,
    ),
    r'name': PropertySchema(
      id: 4,
      name: r'name',
      type: IsarType.string,
    ),
    r'taskID': PropertySchema(
      id: 5,
      name: r'taskID',
      type: IsarType.long,
    ),
    r'toDelete': PropertySchema(
      id: 6,
      name: r'toDelete',
      type: IsarType.bool,
    ),
    r'weight': PropertySchema(
      id: 7,
      name: r'weight',
      type: IsarType.long,
    )
  },
  estimateSize: _subtaskEstimateSize,
  serialize: _subtaskSerialize,
  deserialize: _subtaskDeserialize,
  deserializeProp: _subtaskDeserializeProp,
  idName: r'id',
  indexes: {
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
    r'taskID': IndexSchema(
      id: 483623562622605292,
      name: r'taskID',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'taskID',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    ),
    r'customViewIndex': IndexSchema(
      id: -5365858424493440132,
      name: r'customViewIndex',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'customViewIndex',
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
    ),
    r'lastUpdated': IndexSchema(
      id: 8989359681631629925,
      name: r'lastUpdated',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'lastUpdated',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _subtaskGetId,
  getLinks: _subtaskGetLinks,
  attach: _subtaskAttach,
  version: '3.1.0+1',
);

int _subtaskEstimateSize(
  Subtask object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.name.length * 3;
  return bytesCount;
}

void _subtaskSerialize(
  Subtask object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeBool(offsets[0], object.completed);
  writer.writeLong(offsets[1], object.customViewIndex);
  writer.writeBool(offsets[2], object.isSynced);
  writer.writeDateTime(offsets[3], object.lastUpdated);
  writer.writeString(offsets[4], object.name);
  writer.writeLong(offsets[5], object.taskID);
  writer.writeBool(offsets[6], object.toDelete);
  writer.writeLong(offsets[7], object.weight);
}

Subtask _subtaskDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = Subtask(
    completed: reader.readBoolOrNull(offsets[0]) ?? false,
    customViewIndex: reader.readLongOrNull(offsets[1]) ?? -1,
    lastUpdated: reader.readDateTime(offsets[3]),
    name: reader.readStringOrNull(offsets[4]) ?? "",
    taskID: reader.readLongOrNull(offsets[5]),
    weight: reader.readLongOrNull(offsets[7]) ?? 0,
  );
  object.id = id;
  object.isSynced = reader.readBool(offsets[2]);
  object.toDelete = reader.readBool(offsets[6]);
  return object;
}

P _subtaskDeserializeProp<P>(
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
      return (reader.readBool(offset)) as P;
    case 3:
      return (reader.readDateTime(offset)) as P;
    case 4:
      return (reader.readStringOrNull(offset) ?? "") as P;
    case 5:
      return (reader.readLongOrNull(offset)) as P;
    case 6:
      return (reader.readBool(offset)) as P;
    case 7:
      return (reader.readLongOrNull(offset) ?? 0) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _subtaskGetId(Subtask object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _subtaskGetLinks(Subtask object) {
  return [];
}

void _subtaskAttach(IsarCollection<dynamic> col, Id id, Subtask object) {
  object.id = id;
}

extension SubtaskQueryWhereSort on QueryBuilder<Subtask, Subtask, QWhere> {
  QueryBuilder<Subtask, Subtask, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<Subtask, Subtask, QAfterWhere> anyCompleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'completed'),
      );
    });
  }

  QueryBuilder<Subtask, Subtask, QAfterWhere> anyTaskID() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'taskID'),
      );
    });
  }

  QueryBuilder<Subtask, Subtask, QAfterWhere> anyCustomViewIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'customViewIndex'),
      );
    });
  }

  QueryBuilder<Subtask, Subtask, QAfterWhere> anyIsSynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'isSynced'),
      );
    });
  }

  QueryBuilder<Subtask, Subtask, QAfterWhere> anyToDelete() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'toDelete'),
      );
    });
  }

  QueryBuilder<Subtask, Subtask, QAfterWhere> anyLastUpdated() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'lastUpdated'),
      );
    });
  }
}

extension SubtaskQueryWhere on QueryBuilder<Subtask, Subtask, QWhereClause> {
  QueryBuilder<Subtask, Subtask, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<Subtask, Subtask, QAfterWhereClause> idNotEqualTo(Id id) {
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

  QueryBuilder<Subtask, Subtask, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<Subtask, Subtask, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<Subtask, Subtask, QAfterWhereClause> idBetween(
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

  QueryBuilder<Subtask, Subtask, QAfterWhereClause> nameEqualTo(String name) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'name',
        value: [name],
      ));
    });
  }

  QueryBuilder<Subtask, Subtask, QAfterWhereClause> nameNotEqualTo(
      String name) {
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

  QueryBuilder<Subtask, Subtask, QAfterWhereClause> completedEqualTo(
      bool completed) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'completed',
        value: [completed],
      ));
    });
  }

  QueryBuilder<Subtask, Subtask, QAfterWhereClause> completedNotEqualTo(
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

  QueryBuilder<Subtask, Subtask, QAfterWhereClause> taskIDIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'taskID',
        value: [null],
      ));
    });
  }

  QueryBuilder<Subtask, Subtask, QAfterWhereClause> taskIDIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'taskID',
        lower: [null],
        includeLower: false,
        upper: [],
      ));
    });
  }

  QueryBuilder<Subtask, Subtask, QAfterWhereClause> taskIDEqualTo(int? taskID) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'taskID',
        value: [taskID],
      ));
    });
  }

  QueryBuilder<Subtask, Subtask, QAfterWhereClause> taskIDNotEqualTo(
      int? taskID) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'taskID',
              lower: [],
              upper: [taskID],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'taskID',
              lower: [taskID],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'taskID',
              lower: [taskID],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'taskID',
              lower: [],
              upper: [taskID],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<Subtask, Subtask, QAfterWhereClause> taskIDGreaterThan(
    int? taskID, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'taskID',
        lower: [taskID],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<Subtask, Subtask, QAfterWhereClause> taskIDLessThan(
    int? taskID, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'taskID',
        lower: [],
        upper: [taskID],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<Subtask, Subtask, QAfterWhereClause> taskIDBetween(
    int? lowerTaskID,
    int? upperTaskID, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'taskID',
        lower: [lowerTaskID],
        includeLower: includeLower,
        upper: [upperTaskID],
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Subtask, Subtask, QAfterWhereClause> customViewIndexEqualTo(
      int customViewIndex) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'customViewIndex',
        value: [customViewIndex],
      ));
    });
  }

  QueryBuilder<Subtask, Subtask, QAfterWhereClause> customViewIndexNotEqualTo(
      int customViewIndex) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'customViewIndex',
              lower: [],
              upper: [customViewIndex],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'customViewIndex',
              lower: [customViewIndex],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'customViewIndex',
              lower: [customViewIndex],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'customViewIndex',
              lower: [],
              upper: [customViewIndex],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<Subtask, Subtask, QAfterWhereClause> customViewIndexGreaterThan(
    int customViewIndex, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'customViewIndex',
        lower: [customViewIndex],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<Subtask, Subtask, QAfterWhereClause> customViewIndexLessThan(
    int customViewIndex, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'customViewIndex',
        lower: [],
        upper: [customViewIndex],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<Subtask, Subtask, QAfterWhereClause> customViewIndexBetween(
    int lowerCustomViewIndex,
    int upperCustomViewIndex, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'customViewIndex',
        lower: [lowerCustomViewIndex],
        includeLower: includeLower,
        upper: [upperCustomViewIndex],
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Subtask, Subtask, QAfterWhereClause> isSyncedEqualTo(
      bool isSynced) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'isSynced',
        value: [isSynced],
      ));
    });
  }

  QueryBuilder<Subtask, Subtask, QAfterWhereClause> isSyncedNotEqualTo(
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

  QueryBuilder<Subtask, Subtask, QAfterWhereClause> toDeleteEqualTo(
      bool toDelete) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'toDelete',
        value: [toDelete],
      ));
    });
  }

  QueryBuilder<Subtask, Subtask, QAfterWhereClause> toDeleteNotEqualTo(
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

  QueryBuilder<Subtask, Subtask, QAfterWhereClause> lastUpdatedEqualTo(
      DateTime lastUpdated) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'lastUpdated',
        value: [lastUpdated],
      ));
    });
  }

  QueryBuilder<Subtask, Subtask, QAfterWhereClause> lastUpdatedNotEqualTo(
      DateTime lastUpdated) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'lastUpdated',
              lower: [],
              upper: [lastUpdated],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'lastUpdated',
              lower: [lastUpdated],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'lastUpdated',
              lower: [lastUpdated],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'lastUpdated',
              lower: [],
              upper: [lastUpdated],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<Subtask, Subtask, QAfterWhereClause> lastUpdatedGreaterThan(
    DateTime lastUpdated, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'lastUpdated',
        lower: [lastUpdated],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<Subtask, Subtask, QAfterWhereClause> lastUpdatedLessThan(
    DateTime lastUpdated, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'lastUpdated',
        lower: [],
        upper: [lastUpdated],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<Subtask, Subtask, QAfterWhereClause> lastUpdatedBetween(
    DateTime lowerLastUpdated,
    DateTime upperLastUpdated, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'lastUpdated',
        lower: [lowerLastUpdated],
        includeLower: includeLower,
        upper: [upperLastUpdated],
        includeUpper: includeUpper,
      ));
    });
  }
}

extension SubtaskQueryFilter
    on QueryBuilder<Subtask, Subtask, QFilterCondition> {
  QueryBuilder<Subtask, Subtask, QAfterFilterCondition> completedEqualTo(
      bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'completed',
        value: value,
      ));
    });
  }

  QueryBuilder<Subtask, Subtask, QAfterFilterCondition> customViewIndexEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'customViewIndex',
        value: value,
      ));
    });
  }

  QueryBuilder<Subtask, Subtask, QAfterFilterCondition>
      customViewIndexGreaterThan(
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

  QueryBuilder<Subtask, Subtask, QAfterFilterCondition> customViewIndexLessThan(
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

  QueryBuilder<Subtask, Subtask, QAfterFilterCondition> customViewIndexBetween(
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

  QueryBuilder<Subtask, Subtask, QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<Subtask, Subtask, QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<Subtask, Subtask, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<Subtask, Subtask, QAfterFilterCondition> idBetween(
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

  QueryBuilder<Subtask, Subtask, QAfterFilterCondition> isSyncedEqualTo(
      bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isSynced',
        value: value,
      ));
    });
  }

  QueryBuilder<Subtask, Subtask, QAfterFilterCondition> lastUpdatedEqualTo(
      DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastUpdated',
        value: value,
      ));
    });
  }

  QueryBuilder<Subtask, Subtask, QAfterFilterCondition> lastUpdatedGreaterThan(
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

  QueryBuilder<Subtask, Subtask, QAfterFilterCondition> lastUpdatedLessThan(
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

  QueryBuilder<Subtask, Subtask, QAfterFilterCondition> lastUpdatedBetween(
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

  QueryBuilder<Subtask, Subtask, QAfterFilterCondition> nameEqualTo(
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

  QueryBuilder<Subtask, Subtask, QAfterFilterCondition> nameGreaterThan(
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

  QueryBuilder<Subtask, Subtask, QAfterFilterCondition> nameLessThan(
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

  QueryBuilder<Subtask, Subtask, QAfterFilterCondition> nameBetween(
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

  QueryBuilder<Subtask, Subtask, QAfterFilterCondition> nameStartsWith(
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

  QueryBuilder<Subtask, Subtask, QAfterFilterCondition> nameEndsWith(
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

  QueryBuilder<Subtask, Subtask, QAfterFilterCondition> nameContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Subtask, Subtask, QAfterFilterCondition> nameMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'name',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Subtask, Subtask, QAfterFilterCondition> nameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<Subtask, Subtask, QAfterFilterCondition> nameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<Subtask, Subtask, QAfterFilterCondition> taskIDIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'taskID',
      ));
    });
  }

  QueryBuilder<Subtask, Subtask, QAfterFilterCondition> taskIDIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'taskID',
      ));
    });
  }

  QueryBuilder<Subtask, Subtask, QAfterFilterCondition> taskIDEqualTo(
      int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'taskID',
        value: value,
      ));
    });
  }

  QueryBuilder<Subtask, Subtask, QAfterFilterCondition> taskIDGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'taskID',
        value: value,
      ));
    });
  }

  QueryBuilder<Subtask, Subtask, QAfterFilterCondition> taskIDLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'taskID',
        value: value,
      ));
    });
  }

  QueryBuilder<Subtask, Subtask, QAfterFilterCondition> taskIDBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'taskID',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Subtask, Subtask, QAfterFilterCondition> toDeleteEqualTo(
      bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'toDelete',
        value: value,
      ));
    });
  }

  QueryBuilder<Subtask, Subtask, QAfterFilterCondition> weightEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'weight',
        value: value,
      ));
    });
  }

  QueryBuilder<Subtask, Subtask, QAfterFilterCondition> weightGreaterThan(
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

  QueryBuilder<Subtask, Subtask, QAfterFilterCondition> weightLessThan(
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

  QueryBuilder<Subtask, Subtask, QAfterFilterCondition> weightBetween(
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

extension SubtaskQueryObject
    on QueryBuilder<Subtask, Subtask, QFilterCondition> {}

extension SubtaskQueryLinks
    on QueryBuilder<Subtask, Subtask, QFilterCondition> {}

extension SubtaskQuerySortBy on QueryBuilder<Subtask, Subtask, QSortBy> {
  QueryBuilder<Subtask, Subtask, QAfterSortBy> sortByCompleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'completed', Sort.asc);
    });
  }

  QueryBuilder<Subtask, Subtask, QAfterSortBy> sortByCompletedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'completed', Sort.desc);
    });
  }

  QueryBuilder<Subtask, Subtask, QAfterSortBy> sortByCustomViewIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'customViewIndex', Sort.asc);
    });
  }

  QueryBuilder<Subtask, Subtask, QAfterSortBy> sortByCustomViewIndexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'customViewIndex', Sort.desc);
    });
  }

  QueryBuilder<Subtask, Subtask, QAfterSortBy> sortByIsSynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.asc);
    });
  }

  QueryBuilder<Subtask, Subtask, QAfterSortBy> sortByIsSyncedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.desc);
    });
  }

  QueryBuilder<Subtask, Subtask, QAfterSortBy> sortByLastUpdated() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastUpdated', Sort.asc);
    });
  }

  QueryBuilder<Subtask, Subtask, QAfterSortBy> sortByLastUpdatedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastUpdated', Sort.desc);
    });
  }

  QueryBuilder<Subtask, Subtask, QAfterSortBy> sortByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<Subtask, Subtask, QAfterSortBy> sortByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<Subtask, Subtask, QAfterSortBy> sortByTaskID() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'taskID', Sort.asc);
    });
  }

  QueryBuilder<Subtask, Subtask, QAfterSortBy> sortByTaskIDDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'taskID', Sort.desc);
    });
  }

  QueryBuilder<Subtask, Subtask, QAfterSortBy> sortByToDelete() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'toDelete', Sort.asc);
    });
  }

  QueryBuilder<Subtask, Subtask, QAfterSortBy> sortByToDeleteDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'toDelete', Sort.desc);
    });
  }

  QueryBuilder<Subtask, Subtask, QAfterSortBy> sortByWeight() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'weight', Sort.asc);
    });
  }

  QueryBuilder<Subtask, Subtask, QAfterSortBy> sortByWeightDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'weight', Sort.desc);
    });
  }
}

extension SubtaskQuerySortThenBy
    on QueryBuilder<Subtask, Subtask, QSortThenBy> {
  QueryBuilder<Subtask, Subtask, QAfterSortBy> thenByCompleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'completed', Sort.asc);
    });
  }

  QueryBuilder<Subtask, Subtask, QAfterSortBy> thenByCompletedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'completed', Sort.desc);
    });
  }

  QueryBuilder<Subtask, Subtask, QAfterSortBy> thenByCustomViewIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'customViewIndex', Sort.asc);
    });
  }

  QueryBuilder<Subtask, Subtask, QAfterSortBy> thenByCustomViewIndexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'customViewIndex', Sort.desc);
    });
  }

  QueryBuilder<Subtask, Subtask, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<Subtask, Subtask, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<Subtask, Subtask, QAfterSortBy> thenByIsSynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.asc);
    });
  }

  QueryBuilder<Subtask, Subtask, QAfterSortBy> thenByIsSyncedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.desc);
    });
  }

  QueryBuilder<Subtask, Subtask, QAfterSortBy> thenByLastUpdated() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastUpdated', Sort.asc);
    });
  }

  QueryBuilder<Subtask, Subtask, QAfterSortBy> thenByLastUpdatedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastUpdated', Sort.desc);
    });
  }

  QueryBuilder<Subtask, Subtask, QAfterSortBy> thenByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<Subtask, Subtask, QAfterSortBy> thenByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<Subtask, Subtask, QAfterSortBy> thenByTaskID() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'taskID', Sort.asc);
    });
  }

  QueryBuilder<Subtask, Subtask, QAfterSortBy> thenByTaskIDDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'taskID', Sort.desc);
    });
  }

  QueryBuilder<Subtask, Subtask, QAfterSortBy> thenByToDelete() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'toDelete', Sort.asc);
    });
  }

  QueryBuilder<Subtask, Subtask, QAfterSortBy> thenByToDeleteDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'toDelete', Sort.desc);
    });
  }

  QueryBuilder<Subtask, Subtask, QAfterSortBy> thenByWeight() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'weight', Sort.asc);
    });
  }

  QueryBuilder<Subtask, Subtask, QAfterSortBy> thenByWeightDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'weight', Sort.desc);
    });
  }
}

extension SubtaskQueryWhereDistinct
    on QueryBuilder<Subtask, Subtask, QDistinct> {
  QueryBuilder<Subtask, Subtask, QDistinct> distinctByCompleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'completed');
    });
  }

  QueryBuilder<Subtask, Subtask, QDistinct> distinctByCustomViewIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'customViewIndex');
    });
  }

  QueryBuilder<Subtask, Subtask, QDistinct> distinctByIsSynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isSynced');
    });
  }

  QueryBuilder<Subtask, Subtask, QDistinct> distinctByLastUpdated() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastUpdated');
    });
  }

  QueryBuilder<Subtask, Subtask, QDistinct> distinctByName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'name', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Subtask, Subtask, QDistinct> distinctByTaskID() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'taskID');
    });
  }

  QueryBuilder<Subtask, Subtask, QDistinct> distinctByToDelete() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'toDelete');
    });
  }

  QueryBuilder<Subtask, Subtask, QDistinct> distinctByWeight() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'weight');
    });
  }
}

extension SubtaskQueryProperty
    on QueryBuilder<Subtask, Subtask, QQueryProperty> {
  QueryBuilder<Subtask, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<Subtask, bool, QQueryOperations> completedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'completed');
    });
  }

  QueryBuilder<Subtask, int, QQueryOperations> customViewIndexProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'customViewIndex');
    });
  }

  QueryBuilder<Subtask, bool, QQueryOperations> isSyncedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isSynced');
    });
  }

  QueryBuilder<Subtask, DateTime, QQueryOperations> lastUpdatedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastUpdated');
    });
  }

  QueryBuilder<Subtask, String, QQueryOperations> nameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'name');
    });
  }

  QueryBuilder<Subtask, int?, QQueryOperations> taskIDProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'taskID');
    });
  }

  QueryBuilder<Subtask, bool, QQueryOperations> toDeleteProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'toDelete');
    });
  }

  QueryBuilder<Subtask, int, QQueryOperations> weightProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'weight');
    });
  }
}
