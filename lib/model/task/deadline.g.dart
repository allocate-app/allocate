// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'deadline.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetDeadlineCollection on Isar {
  IsarCollection<Deadline> get deadlines => this.collection();
}

const DeadlineSchema = CollectionSchema(
  name: r'Deadline',
  id: -3906690819049898737,
  properties: {
    r'customViewIndex': PropertySchema(
      id: 0,
      name: r'customViewIndex',
      type: IsarType.long,
    ),
    r'description': PropertySchema(
      id: 1,
      name: r'description',
      type: IsarType.string,
    ),
    r'dueDate': PropertySchema(
      id: 2,
      name: r'dueDate',
      type: IsarType.dateTime,
    ),
    r'frequency': PropertySchema(
      id: 3,
      name: r'frequency',
      type: IsarType.byte,
      enumMap: _DeadlinefrequencyEnumValueMap,
    ),
    r'isSynced': PropertySchema(
      id: 4,
      name: r'isSynced',
      type: IsarType.bool,
    ),
    r'lastUpdated': PropertySchema(
      id: 5,
      name: r'lastUpdated',
      type: IsarType.dateTime,
    ),
    r'name': PropertySchema(
      id: 6,
      name: r'name',
      type: IsarType.string,
    ),
    r'notificationID': PropertySchema(
      id: 7,
      name: r'notificationID',
      type: IsarType.long,
    ),
    r'priority': PropertySchema(
      id: 8,
      name: r'priority',
      type: IsarType.byte,
      enumMap: _DeadlinepriorityEnumValueMap,
    ),
    r'repeatDays': PropertySchema(
      id: 9,
      name: r'repeatDays',
      type: IsarType.boolList,
    ),
    r'repeatID': PropertySchema(
      id: 10,
      name: r'repeatID',
      type: IsarType.long,
    ),
    r'repeatSkip': PropertySchema(
      id: 11,
      name: r'repeatSkip',
      type: IsarType.long,
    ),
    r'repeatable': PropertySchema(
      id: 12,
      name: r'repeatable',
      type: IsarType.bool,
    ),
    r'startDate': PropertySchema(
      id: 13,
      name: r'startDate',
      type: IsarType.dateTime,
    ),
    r'toDelete': PropertySchema(
      id: 14,
      name: r'toDelete',
      type: IsarType.bool,
    ),
    r'warnDate': PropertySchema(
      id: 15,
      name: r'warnDate',
      type: IsarType.dateTime,
    ),
    r'warnMe': PropertySchema(
      id: 16,
      name: r'warnMe',
      type: IsarType.bool,
    )
  },
  estimateSize: _deadlineEstimateSize,
  serialize: _deadlineSerialize,
  deserialize: _deadlineDeserialize,
  deserializeProp: _deadlineDeserializeProp,
  idName: r'id',
  indexes: {
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
    r'notificationID': IndexSchema(
      id: -7217136984975172681,
      name: r'notificationID',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'notificationID',
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
    r'warnMe': IndexSchema(
      id: -3547939783881256235,
      name: r'warnMe',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'warnMe',
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
  getId: _deadlineGetId,
  getLinks: _deadlineGetLinks,
  attach: _deadlineAttach,
  version: '3.1.0+1',
);

int _deadlineEstimateSize(
  Deadline object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.description.length * 3;
  bytesCount += 3 + object.name.length * 3;
  bytesCount += 3 + object.repeatDays.length;
  return bytesCount;
}

void _deadlineSerialize(
  Deadline object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.customViewIndex);
  writer.writeString(offsets[1], object.description);
  writer.writeDateTime(offsets[2], object.dueDate);
  writer.writeByte(offsets[3], object.frequency.index);
  writer.writeBool(offsets[4], object.isSynced);
  writer.writeDateTime(offsets[5], object.lastUpdated);
  writer.writeString(offsets[6], object.name);
  writer.writeLong(offsets[7], object.notificationID);
  writer.writeByte(offsets[8], object.priority.index);
  writer.writeBoolList(offsets[9], object.repeatDays);
  writer.writeLong(offsets[10], object.repeatID);
  writer.writeLong(offsets[11], object.repeatSkip);
  writer.writeBool(offsets[12], object.repeatable);
  writer.writeDateTime(offsets[13], object.startDate);
  writer.writeBool(offsets[14], object.toDelete);
  writer.writeDateTime(offsets[15], object.warnDate);
  writer.writeBool(offsets[16], object.warnMe);
}

Deadline _deadlineDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = Deadline(
    description: reader.readStringOrNull(offsets[1]) ?? "",
    dueDate: reader.readDateTime(offsets[2]),
    frequency:
        _DeadlinefrequencyValueEnumMap[reader.readByteOrNull(offsets[3])] ??
            Frequency.once,
    lastUpdated: reader.readDateTime(offsets[5]),
    name: reader.readString(offsets[6]),
    notificationID: reader.readLongOrNull(offsets[7]),
    priority:
        _DeadlinepriorityValueEnumMap[reader.readByteOrNull(offsets[8])] ??
            Priority.low,
    repeatDays: reader.readBoolList(offsets[9]) ?? [],
    repeatID: reader.readLongOrNull(offsets[10]),
    repeatSkip: reader.readLongOrNull(offsets[11]) ?? 1,
    repeatable: reader.readBoolOrNull(offsets[12]) ?? false,
    startDate: reader.readDateTime(offsets[13]),
    warnDate: reader.readDateTime(offsets[15]),
    warnMe: reader.readBoolOrNull(offsets[16]) ?? false,
  );
  object.customViewIndex = reader.readLong(offsets[0]);
  object.id = id;
  object.isSynced = reader.readBool(offsets[4]);
  object.toDelete = reader.readBool(offsets[14]);
  return object;
}

P _deadlineDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readLong(offset)) as P;
    case 1:
      return (reader.readStringOrNull(offset) ?? "") as P;
    case 2:
      return (reader.readDateTime(offset)) as P;
    case 3:
      return (_DeadlinefrequencyValueEnumMap[reader.readByteOrNull(offset)] ??
          Frequency.once) as P;
    case 4:
      return (reader.readBool(offset)) as P;
    case 5:
      return (reader.readDateTime(offset)) as P;
    case 6:
      return (reader.readString(offset)) as P;
    case 7:
      return (reader.readLongOrNull(offset)) as P;
    case 8:
      return (_DeadlinepriorityValueEnumMap[reader.readByteOrNull(offset)] ??
          Priority.low) as P;
    case 9:
      return (reader.readBoolList(offset) ?? []) as P;
    case 10:
      return (reader.readLongOrNull(offset)) as P;
    case 11:
      return (reader.readLongOrNull(offset) ?? 1) as P;
    case 12:
      return (reader.readBoolOrNull(offset) ?? false) as P;
    case 13:
      return (reader.readDateTime(offset)) as P;
    case 14:
      return (reader.readBool(offset)) as P;
    case 15:
      return (reader.readDateTime(offset)) as P;
    case 16:
      return (reader.readBoolOrNull(offset) ?? false) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

const _DeadlinefrequencyEnumValueMap = {
  'once': 0,
  'daily': 1,
  'weekly': 2,
  'monthly': 3,
  'yearly': 4,
  'custom': 5,
};
const _DeadlinefrequencyValueEnumMap = {
  0: Frequency.once,
  1: Frequency.daily,
  2: Frequency.weekly,
  3: Frequency.monthly,
  4: Frequency.yearly,
  5: Frequency.custom,
};
const _DeadlinepriorityEnumValueMap = {
  'low': 0,
  'medium': 1,
  'high': 2,
};
const _DeadlinepriorityValueEnumMap = {
  0: Priority.low,
  1: Priority.medium,
  2: Priority.high,
};

Id _deadlineGetId(Deadline object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _deadlineGetLinks(Deadline object) {
  return [];
}

void _deadlineAttach(IsarCollection<dynamic> col, Id id, Deadline object) {
  object.id = id;
}

extension DeadlineQueryWhereSort on QueryBuilder<Deadline, Deadline, QWhere> {
  QueryBuilder<Deadline, Deadline, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<Deadline, Deadline, QAfterWhere> anyCustomViewIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'customViewIndex'),
      );
    });
  }

  QueryBuilder<Deadline, Deadline, QAfterWhere> anyRepeatID() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'repeatID'),
      );
    });
  }

  QueryBuilder<Deadline, Deadline, QAfterWhere> anyNotificationID() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'notificationID'),
      );
    });
  }

  QueryBuilder<Deadline, Deadline, QAfterWhere> anyDueDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'dueDate'),
      );
    });
  }

  QueryBuilder<Deadline, Deadline, QAfterWhere> anyWarnMe() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'warnMe'),
      );
    });
  }

  QueryBuilder<Deadline, Deadline, QAfterWhere> anyRepeatable() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'repeatable'),
      );
    });
  }

  QueryBuilder<Deadline, Deadline, QAfterWhere> anyIsSynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'isSynced'),
      );
    });
  }

  QueryBuilder<Deadline, Deadline, QAfterWhere> anyToDelete() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'toDelete'),
      );
    });
  }

  QueryBuilder<Deadline, Deadline, QAfterWhere> anyLastUpdated() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'lastUpdated'),
      );
    });
  }
}

extension DeadlineQueryWhere on QueryBuilder<Deadline, Deadline, QWhereClause> {
  QueryBuilder<Deadline, Deadline, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<Deadline, Deadline, QAfterWhereClause> idNotEqualTo(Id id) {
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

  QueryBuilder<Deadline, Deadline, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<Deadline, Deadline, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<Deadline, Deadline, QAfterWhereClause> idBetween(
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

  QueryBuilder<Deadline, Deadline, QAfterWhereClause> customViewIndexEqualTo(
      int customViewIndex) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'customViewIndex',
        value: [customViewIndex],
      ));
    });
  }

  QueryBuilder<Deadline, Deadline, QAfterWhereClause> customViewIndexNotEqualTo(
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

  QueryBuilder<Deadline, Deadline, QAfterWhereClause>
      customViewIndexGreaterThan(
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

  QueryBuilder<Deadline, Deadline, QAfterWhereClause> customViewIndexLessThan(
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

  QueryBuilder<Deadline, Deadline, QAfterWhereClause> customViewIndexBetween(
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

  QueryBuilder<Deadline, Deadline, QAfterWhereClause> repeatIDIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'repeatID',
        value: [null],
      ));
    });
  }

  QueryBuilder<Deadline, Deadline, QAfterWhereClause> repeatIDIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'repeatID',
        lower: [null],
        includeLower: false,
        upper: [],
      ));
    });
  }

  QueryBuilder<Deadline, Deadline, QAfterWhereClause> repeatIDEqualTo(
      int? repeatID) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'repeatID',
        value: [repeatID],
      ));
    });
  }

  QueryBuilder<Deadline, Deadline, QAfterWhereClause> repeatIDNotEqualTo(
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

  QueryBuilder<Deadline, Deadline, QAfterWhereClause> repeatIDGreaterThan(
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

  QueryBuilder<Deadline, Deadline, QAfterWhereClause> repeatIDLessThan(
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

  QueryBuilder<Deadline, Deadline, QAfterWhereClause> repeatIDBetween(
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

  QueryBuilder<Deadline, Deadline, QAfterWhereClause> notificationIDIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'notificationID',
        value: [null],
      ));
    });
  }

  QueryBuilder<Deadline, Deadline, QAfterWhereClause>
      notificationIDIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'notificationID',
        lower: [null],
        includeLower: false,
        upper: [],
      ));
    });
  }

  QueryBuilder<Deadline, Deadline, QAfterWhereClause> notificationIDEqualTo(
      int? notificationID) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'notificationID',
        value: [notificationID],
      ));
    });
  }

  QueryBuilder<Deadline, Deadline, QAfterWhereClause> notificationIDNotEqualTo(
      int? notificationID) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'notificationID',
              lower: [],
              upper: [notificationID],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'notificationID',
              lower: [notificationID],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'notificationID',
              lower: [notificationID],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'notificationID',
              lower: [],
              upper: [notificationID],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<Deadline, Deadline, QAfterWhereClause> notificationIDGreaterThan(
    int? notificationID, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'notificationID',
        lower: [notificationID],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<Deadline, Deadline, QAfterWhereClause> notificationIDLessThan(
    int? notificationID, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'notificationID',
        lower: [],
        upper: [notificationID],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<Deadline, Deadline, QAfterWhereClause> notificationIDBetween(
    int? lowerNotificationID,
    int? upperNotificationID, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'notificationID',
        lower: [lowerNotificationID],
        includeLower: includeLower,
        upper: [upperNotificationID],
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Deadline, Deadline, QAfterWhereClause> nameEqualTo(String name) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'name',
        value: [name],
      ));
    });
  }

  QueryBuilder<Deadline, Deadline, QAfterWhereClause> nameNotEqualTo(
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

  QueryBuilder<Deadline, Deadline, QAfterWhereClause> dueDateEqualTo(
      DateTime dueDate) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'dueDate',
        value: [dueDate],
      ));
    });
  }

  QueryBuilder<Deadline, Deadline, QAfterWhereClause> dueDateNotEqualTo(
      DateTime dueDate) {
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

  QueryBuilder<Deadline, Deadline, QAfterWhereClause> dueDateGreaterThan(
    DateTime dueDate, {
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

  QueryBuilder<Deadline, Deadline, QAfterWhereClause> dueDateLessThan(
    DateTime dueDate, {
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

  QueryBuilder<Deadline, Deadline, QAfterWhereClause> dueDateBetween(
    DateTime lowerDueDate,
    DateTime upperDueDate, {
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

  QueryBuilder<Deadline, Deadline, QAfterWhereClause> warnMeEqualTo(
      bool warnMe) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'warnMe',
        value: [warnMe],
      ));
    });
  }

  QueryBuilder<Deadline, Deadline, QAfterWhereClause> warnMeNotEqualTo(
      bool warnMe) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'warnMe',
              lower: [],
              upper: [warnMe],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'warnMe',
              lower: [warnMe],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'warnMe',
              lower: [warnMe],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'warnMe',
              lower: [],
              upper: [warnMe],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<Deadline, Deadline, QAfterWhereClause> repeatableEqualTo(
      bool repeatable) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'repeatable',
        value: [repeatable],
      ));
    });
  }

  QueryBuilder<Deadline, Deadline, QAfterWhereClause> repeatableNotEqualTo(
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

  QueryBuilder<Deadline, Deadline, QAfterWhereClause> isSyncedEqualTo(
      bool isSynced) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'isSynced',
        value: [isSynced],
      ));
    });
  }

  QueryBuilder<Deadline, Deadline, QAfterWhereClause> isSyncedNotEqualTo(
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

  QueryBuilder<Deadline, Deadline, QAfterWhereClause> toDeleteEqualTo(
      bool toDelete) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'toDelete',
        value: [toDelete],
      ));
    });
  }

  QueryBuilder<Deadline, Deadline, QAfterWhereClause> toDeleteNotEqualTo(
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

  QueryBuilder<Deadline, Deadline, QAfterWhereClause> lastUpdatedEqualTo(
      DateTime lastUpdated) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'lastUpdated',
        value: [lastUpdated],
      ));
    });
  }

  QueryBuilder<Deadline, Deadline, QAfterWhereClause> lastUpdatedNotEqualTo(
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

  QueryBuilder<Deadline, Deadline, QAfterWhereClause> lastUpdatedGreaterThan(
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

  QueryBuilder<Deadline, Deadline, QAfterWhereClause> lastUpdatedLessThan(
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

  QueryBuilder<Deadline, Deadline, QAfterWhereClause> lastUpdatedBetween(
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

extension DeadlineQueryFilter
    on QueryBuilder<Deadline, Deadline, QFilterCondition> {
  QueryBuilder<Deadline, Deadline, QAfterFilterCondition>
      customViewIndexEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'customViewIndex',
        value: value,
      ));
    });
  }

  QueryBuilder<Deadline, Deadline, QAfterFilterCondition>
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

  QueryBuilder<Deadline, Deadline, QAfterFilterCondition>
      customViewIndexLessThan(
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

  QueryBuilder<Deadline, Deadline, QAfterFilterCondition>
      customViewIndexBetween(
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

  QueryBuilder<Deadline, Deadline, QAfterFilterCondition> descriptionEqualTo(
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

  QueryBuilder<Deadline, Deadline, QAfterFilterCondition>
      descriptionGreaterThan(
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

  QueryBuilder<Deadline, Deadline, QAfterFilterCondition> descriptionLessThan(
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

  QueryBuilder<Deadline, Deadline, QAfterFilterCondition> descriptionBetween(
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

  QueryBuilder<Deadline, Deadline, QAfterFilterCondition> descriptionStartsWith(
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

  QueryBuilder<Deadline, Deadline, QAfterFilterCondition> descriptionEndsWith(
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

  QueryBuilder<Deadline, Deadline, QAfterFilterCondition> descriptionContains(
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

  QueryBuilder<Deadline, Deadline, QAfterFilterCondition> descriptionMatches(
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

  QueryBuilder<Deadline, Deadline, QAfterFilterCondition> descriptionIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'description',
        value: '',
      ));
    });
  }

  QueryBuilder<Deadline, Deadline, QAfterFilterCondition>
      descriptionIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'description',
        value: '',
      ));
    });
  }

  QueryBuilder<Deadline, Deadline, QAfterFilterCondition> dueDateEqualTo(
      DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'dueDate',
        value: value,
      ));
    });
  }

  QueryBuilder<Deadline, Deadline, QAfterFilterCondition> dueDateGreaterThan(
    DateTime value, {
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

  QueryBuilder<Deadline, Deadline, QAfterFilterCondition> dueDateLessThan(
    DateTime value, {
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

  QueryBuilder<Deadline, Deadline, QAfterFilterCondition> dueDateBetween(
    DateTime lower,
    DateTime upper, {
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

  QueryBuilder<Deadline, Deadline, QAfterFilterCondition> frequencyEqualTo(
      Frequency value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'frequency',
        value: value,
      ));
    });
  }

  QueryBuilder<Deadline, Deadline, QAfterFilterCondition> frequencyGreaterThan(
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

  QueryBuilder<Deadline, Deadline, QAfterFilterCondition> frequencyLessThan(
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

  QueryBuilder<Deadline, Deadline, QAfterFilterCondition> frequencyBetween(
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

  QueryBuilder<Deadline, Deadline, QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<Deadline, Deadline, QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<Deadline, Deadline, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<Deadline, Deadline, QAfterFilterCondition> idBetween(
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

  QueryBuilder<Deadline, Deadline, QAfterFilterCondition> isSyncedEqualTo(
      bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isSynced',
        value: value,
      ));
    });
  }

  QueryBuilder<Deadline, Deadline, QAfterFilterCondition> lastUpdatedEqualTo(
      DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastUpdated',
        value: value,
      ));
    });
  }

  QueryBuilder<Deadline, Deadline, QAfterFilterCondition>
      lastUpdatedGreaterThan(
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

  QueryBuilder<Deadline, Deadline, QAfterFilterCondition> lastUpdatedLessThan(
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

  QueryBuilder<Deadline, Deadline, QAfterFilterCondition> lastUpdatedBetween(
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

  QueryBuilder<Deadline, Deadline, QAfterFilterCondition> nameEqualTo(
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

  QueryBuilder<Deadline, Deadline, QAfterFilterCondition> nameGreaterThan(
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

  QueryBuilder<Deadline, Deadline, QAfterFilterCondition> nameLessThan(
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

  QueryBuilder<Deadline, Deadline, QAfterFilterCondition> nameBetween(
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

  QueryBuilder<Deadline, Deadline, QAfterFilterCondition> nameStartsWith(
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

  QueryBuilder<Deadline, Deadline, QAfterFilterCondition> nameEndsWith(
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

  QueryBuilder<Deadline, Deadline, QAfterFilterCondition> nameContains(
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

  QueryBuilder<Deadline, Deadline, QAfterFilterCondition> nameMatches(
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

  QueryBuilder<Deadline, Deadline, QAfterFilterCondition> nameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<Deadline, Deadline, QAfterFilterCondition> nameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<Deadline, Deadline, QAfterFilterCondition>
      notificationIDIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'notificationID',
      ));
    });
  }

  QueryBuilder<Deadline, Deadline, QAfterFilterCondition>
      notificationIDIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'notificationID',
      ));
    });
  }

  QueryBuilder<Deadline, Deadline, QAfterFilterCondition> notificationIDEqualTo(
      int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'notificationID',
        value: value,
      ));
    });
  }

  QueryBuilder<Deadline, Deadline, QAfterFilterCondition>
      notificationIDGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'notificationID',
        value: value,
      ));
    });
  }

  QueryBuilder<Deadline, Deadline, QAfterFilterCondition>
      notificationIDLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'notificationID',
        value: value,
      ));
    });
  }

  QueryBuilder<Deadline, Deadline, QAfterFilterCondition> notificationIDBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'notificationID',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Deadline, Deadline, QAfterFilterCondition> priorityEqualTo(
      Priority value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'priority',
        value: value,
      ));
    });
  }

  QueryBuilder<Deadline, Deadline, QAfterFilterCondition> priorityGreaterThan(
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

  QueryBuilder<Deadline, Deadline, QAfterFilterCondition> priorityLessThan(
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

  QueryBuilder<Deadline, Deadline, QAfterFilterCondition> priorityBetween(
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

  QueryBuilder<Deadline, Deadline, QAfterFilterCondition>
      repeatDaysElementEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'repeatDays',
        value: value,
      ));
    });
  }

  QueryBuilder<Deadline, Deadline, QAfterFilterCondition>
      repeatDaysLengthEqualTo(int length) {
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

  QueryBuilder<Deadline, Deadline, QAfterFilterCondition> repeatDaysIsEmpty() {
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

  QueryBuilder<Deadline, Deadline, QAfterFilterCondition>
      repeatDaysIsNotEmpty() {
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

  QueryBuilder<Deadline, Deadline, QAfterFilterCondition>
      repeatDaysLengthLessThan(
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

  QueryBuilder<Deadline, Deadline, QAfterFilterCondition>
      repeatDaysLengthGreaterThan(
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

  QueryBuilder<Deadline, Deadline, QAfterFilterCondition>
      repeatDaysLengthBetween(
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

  QueryBuilder<Deadline, Deadline, QAfterFilterCondition> repeatIDIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'repeatID',
      ));
    });
  }

  QueryBuilder<Deadline, Deadline, QAfterFilterCondition> repeatIDIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'repeatID',
      ));
    });
  }

  QueryBuilder<Deadline, Deadline, QAfterFilterCondition> repeatIDEqualTo(
      int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'repeatID',
        value: value,
      ));
    });
  }

  QueryBuilder<Deadline, Deadline, QAfterFilterCondition> repeatIDGreaterThan(
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

  QueryBuilder<Deadline, Deadline, QAfterFilterCondition> repeatIDLessThan(
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

  QueryBuilder<Deadline, Deadline, QAfterFilterCondition> repeatIDBetween(
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

  QueryBuilder<Deadline, Deadline, QAfterFilterCondition> repeatSkipEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'repeatSkip',
        value: value,
      ));
    });
  }

  QueryBuilder<Deadline, Deadline, QAfterFilterCondition> repeatSkipGreaterThan(
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

  QueryBuilder<Deadline, Deadline, QAfterFilterCondition> repeatSkipLessThan(
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

  QueryBuilder<Deadline, Deadline, QAfterFilterCondition> repeatSkipBetween(
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

  QueryBuilder<Deadline, Deadline, QAfterFilterCondition> repeatableEqualTo(
      bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'repeatable',
        value: value,
      ));
    });
  }

  QueryBuilder<Deadline, Deadline, QAfterFilterCondition> startDateEqualTo(
      DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'startDate',
        value: value,
      ));
    });
  }

  QueryBuilder<Deadline, Deadline, QAfterFilterCondition> startDateGreaterThan(
    DateTime value, {
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

  QueryBuilder<Deadline, Deadline, QAfterFilterCondition> startDateLessThan(
    DateTime value, {
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

  QueryBuilder<Deadline, Deadline, QAfterFilterCondition> startDateBetween(
    DateTime lower,
    DateTime upper, {
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

  QueryBuilder<Deadline, Deadline, QAfterFilterCondition> toDeleteEqualTo(
      bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'toDelete',
        value: value,
      ));
    });
  }

  QueryBuilder<Deadline, Deadline, QAfterFilterCondition> warnDateEqualTo(
      DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'warnDate',
        value: value,
      ));
    });
  }

  QueryBuilder<Deadline, Deadline, QAfterFilterCondition> warnDateGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'warnDate',
        value: value,
      ));
    });
  }

  QueryBuilder<Deadline, Deadline, QAfterFilterCondition> warnDateLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'warnDate',
        value: value,
      ));
    });
  }

  QueryBuilder<Deadline, Deadline, QAfterFilterCondition> warnDateBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'warnDate',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Deadline, Deadline, QAfterFilterCondition> warnMeEqualTo(
      bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'warnMe',
        value: value,
      ));
    });
  }
}

extension DeadlineQueryObject
    on QueryBuilder<Deadline, Deadline, QFilterCondition> {}

extension DeadlineQueryLinks
    on QueryBuilder<Deadline, Deadline, QFilterCondition> {}

extension DeadlineQuerySortBy on QueryBuilder<Deadline, Deadline, QSortBy> {
  QueryBuilder<Deadline, Deadline, QAfterSortBy> sortByCustomViewIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'customViewIndex', Sort.asc);
    });
  }

  QueryBuilder<Deadline, Deadline, QAfterSortBy> sortByCustomViewIndexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'customViewIndex', Sort.desc);
    });
  }

  QueryBuilder<Deadline, Deadline, QAfterSortBy> sortByDescription() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.asc);
    });
  }

  QueryBuilder<Deadline, Deadline, QAfterSortBy> sortByDescriptionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.desc);
    });
  }

  QueryBuilder<Deadline, Deadline, QAfterSortBy> sortByDueDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dueDate', Sort.asc);
    });
  }

  QueryBuilder<Deadline, Deadline, QAfterSortBy> sortByDueDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dueDate', Sort.desc);
    });
  }

  QueryBuilder<Deadline, Deadline, QAfterSortBy> sortByFrequency() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'frequency', Sort.asc);
    });
  }

  QueryBuilder<Deadline, Deadline, QAfterSortBy> sortByFrequencyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'frequency', Sort.desc);
    });
  }

  QueryBuilder<Deadline, Deadline, QAfterSortBy> sortByIsSynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.asc);
    });
  }

  QueryBuilder<Deadline, Deadline, QAfterSortBy> sortByIsSyncedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.desc);
    });
  }

  QueryBuilder<Deadline, Deadline, QAfterSortBy> sortByLastUpdated() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastUpdated', Sort.asc);
    });
  }

  QueryBuilder<Deadline, Deadline, QAfterSortBy> sortByLastUpdatedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastUpdated', Sort.desc);
    });
  }

  QueryBuilder<Deadline, Deadline, QAfterSortBy> sortByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<Deadline, Deadline, QAfterSortBy> sortByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<Deadline, Deadline, QAfterSortBy> sortByNotificationID() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notificationID', Sort.asc);
    });
  }

  QueryBuilder<Deadline, Deadline, QAfterSortBy> sortByNotificationIDDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notificationID', Sort.desc);
    });
  }

  QueryBuilder<Deadline, Deadline, QAfterSortBy> sortByPriority() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'priority', Sort.asc);
    });
  }

  QueryBuilder<Deadline, Deadline, QAfterSortBy> sortByPriorityDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'priority', Sort.desc);
    });
  }

  QueryBuilder<Deadline, Deadline, QAfterSortBy> sortByRepeatID() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'repeatID', Sort.asc);
    });
  }

  QueryBuilder<Deadline, Deadline, QAfterSortBy> sortByRepeatIDDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'repeatID', Sort.desc);
    });
  }

  QueryBuilder<Deadline, Deadline, QAfterSortBy> sortByRepeatSkip() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'repeatSkip', Sort.asc);
    });
  }

  QueryBuilder<Deadline, Deadline, QAfterSortBy> sortByRepeatSkipDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'repeatSkip', Sort.desc);
    });
  }

  QueryBuilder<Deadline, Deadline, QAfterSortBy> sortByRepeatable() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'repeatable', Sort.asc);
    });
  }

  QueryBuilder<Deadline, Deadline, QAfterSortBy> sortByRepeatableDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'repeatable', Sort.desc);
    });
  }

  QueryBuilder<Deadline, Deadline, QAfterSortBy> sortByStartDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startDate', Sort.asc);
    });
  }

  QueryBuilder<Deadline, Deadline, QAfterSortBy> sortByStartDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startDate', Sort.desc);
    });
  }

  QueryBuilder<Deadline, Deadline, QAfterSortBy> sortByToDelete() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'toDelete', Sort.asc);
    });
  }

  QueryBuilder<Deadline, Deadline, QAfterSortBy> sortByToDeleteDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'toDelete', Sort.desc);
    });
  }

  QueryBuilder<Deadline, Deadline, QAfterSortBy> sortByWarnDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'warnDate', Sort.asc);
    });
  }

  QueryBuilder<Deadline, Deadline, QAfterSortBy> sortByWarnDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'warnDate', Sort.desc);
    });
  }

  QueryBuilder<Deadline, Deadline, QAfterSortBy> sortByWarnMe() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'warnMe', Sort.asc);
    });
  }

  QueryBuilder<Deadline, Deadline, QAfterSortBy> sortByWarnMeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'warnMe', Sort.desc);
    });
  }
}

extension DeadlineQuerySortThenBy
    on QueryBuilder<Deadline, Deadline, QSortThenBy> {
  QueryBuilder<Deadline, Deadline, QAfterSortBy> thenByCustomViewIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'customViewIndex', Sort.asc);
    });
  }

  QueryBuilder<Deadline, Deadline, QAfterSortBy> thenByCustomViewIndexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'customViewIndex', Sort.desc);
    });
  }

  QueryBuilder<Deadline, Deadline, QAfterSortBy> thenByDescription() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.asc);
    });
  }

  QueryBuilder<Deadline, Deadline, QAfterSortBy> thenByDescriptionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.desc);
    });
  }

  QueryBuilder<Deadline, Deadline, QAfterSortBy> thenByDueDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dueDate', Sort.asc);
    });
  }

  QueryBuilder<Deadline, Deadline, QAfterSortBy> thenByDueDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dueDate', Sort.desc);
    });
  }

  QueryBuilder<Deadline, Deadline, QAfterSortBy> thenByFrequency() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'frequency', Sort.asc);
    });
  }

  QueryBuilder<Deadline, Deadline, QAfterSortBy> thenByFrequencyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'frequency', Sort.desc);
    });
  }

  QueryBuilder<Deadline, Deadline, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<Deadline, Deadline, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<Deadline, Deadline, QAfterSortBy> thenByIsSynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.asc);
    });
  }

  QueryBuilder<Deadline, Deadline, QAfterSortBy> thenByIsSyncedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.desc);
    });
  }

  QueryBuilder<Deadline, Deadline, QAfterSortBy> thenByLastUpdated() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastUpdated', Sort.asc);
    });
  }

  QueryBuilder<Deadline, Deadline, QAfterSortBy> thenByLastUpdatedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastUpdated', Sort.desc);
    });
  }

  QueryBuilder<Deadline, Deadline, QAfterSortBy> thenByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<Deadline, Deadline, QAfterSortBy> thenByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }

  QueryBuilder<Deadline, Deadline, QAfterSortBy> thenByNotificationID() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notificationID', Sort.asc);
    });
  }

  QueryBuilder<Deadline, Deadline, QAfterSortBy> thenByNotificationIDDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'notificationID', Sort.desc);
    });
  }

  QueryBuilder<Deadline, Deadline, QAfterSortBy> thenByPriority() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'priority', Sort.asc);
    });
  }

  QueryBuilder<Deadline, Deadline, QAfterSortBy> thenByPriorityDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'priority', Sort.desc);
    });
  }

  QueryBuilder<Deadline, Deadline, QAfterSortBy> thenByRepeatID() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'repeatID', Sort.asc);
    });
  }

  QueryBuilder<Deadline, Deadline, QAfterSortBy> thenByRepeatIDDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'repeatID', Sort.desc);
    });
  }

  QueryBuilder<Deadline, Deadline, QAfterSortBy> thenByRepeatSkip() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'repeatSkip', Sort.asc);
    });
  }

  QueryBuilder<Deadline, Deadline, QAfterSortBy> thenByRepeatSkipDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'repeatSkip', Sort.desc);
    });
  }

  QueryBuilder<Deadline, Deadline, QAfterSortBy> thenByRepeatable() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'repeatable', Sort.asc);
    });
  }

  QueryBuilder<Deadline, Deadline, QAfterSortBy> thenByRepeatableDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'repeatable', Sort.desc);
    });
  }

  QueryBuilder<Deadline, Deadline, QAfterSortBy> thenByStartDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startDate', Sort.asc);
    });
  }

  QueryBuilder<Deadline, Deadline, QAfterSortBy> thenByStartDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'startDate', Sort.desc);
    });
  }

  QueryBuilder<Deadline, Deadline, QAfterSortBy> thenByToDelete() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'toDelete', Sort.asc);
    });
  }

  QueryBuilder<Deadline, Deadline, QAfterSortBy> thenByToDeleteDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'toDelete', Sort.desc);
    });
  }

  QueryBuilder<Deadline, Deadline, QAfterSortBy> thenByWarnDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'warnDate', Sort.asc);
    });
  }

  QueryBuilder<Deadline, Deadline, QAfterSortBy> thenByWarnDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'warnDate', Sort.desc);
    });
  }

  QueryBuilder<Deadline, Deadline, QAfterSortBy> thenByWarnMe() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'warnMe', Sort.asc);
    });
  }

  QueryBuilder<Deadline, Deadline, QAfterSortBy> thenByWarnMeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'warnMe', Sort.desc);
    });
  }
}

extension DeadlineQueryWhereDistinct
    on QueryBuilder<Deadline, Deadline, QDistinct> {
  QueryBuilder<Deadline, Deadline, QDistinct> distinctByCustomViewIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'customViewIndex');
    });
  }

  QueryBuilder<Deadline, Deadline, QDistinct> distinctByDescription(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'description', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Deadline, Deadline, QDistinct> distinctByDueDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'dueDate');
    });
  }

  QueryBuilder<Deadline, Deadline, QDistinct> distinctByFrequency() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'frequency');
    });
  }

  QueryBuilder<Deadline, Deadline, QDistinct> distinctByIsSynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isSynced');
    });
  }

  QueryBuilder<Deadline, Deadline, QDistinct> distinctByLastUpdated() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastUpdated');
    });
  }

  QueryBuilder<Deadline, Deadline, QDistinct> distinctByName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'name', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Deadline, Deadline, QDistinct> distinctByNotificationID() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'notificationID');
    });
  }

  QueryBuilder<Deadline, Deadline, QDistinct> distinctByPriority() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'priority');
    });
  }

  QueryBuilder<Deadline, Deadline, QDistinct> distinctByRepeatDays() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'repeatDays');
    });
  }

  QueryBuilder<Deadline, Deadline, QDistinct> distinctByRepeatID() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'repeatID');
    });
  }

  QueryBuilder<Deadline, Deadline, QDistinct> distinctByRepeatSkip() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'repeatSkip');
    });
  }

  QueryBuilder<Deadline, Deadline, QDistinct> distinctByRepeatable() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'repeatable');
    });
  }

  QueryBuilder<Deadline, Deadline, QDistinct> distinctByStartDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'startDate');
    });
  }

  QueryBuilder<Deadline, Deadline, QDistinct> distinctByToDelete() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'toDelete');
    });
  }

  QueryBuilder<Deadline, Deadline, QDistinct> distinctByWarnDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'warnDate');
    });
  }

  QueryBuilder<Deadline, Deadline, QDistinct> distinctByWarnMe() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'warnMe');
    });
  }
}

extension DeadlineQueryProperty
    on QueryBuilder<Deadline, Deadline, QQueryProperty> {
  QueryBuilder<Deadline, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<Deadline, int, QQueryOperations> customViewIndexProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'customViewIndex');
    });
  }

  QueryBuilder<Deadline, String, QQueryOperations> descriptionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'description');
    });
  }

  QueryBuilder<Deadline, DateTime, QQueryOperations> dueDateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'dueDate');
    });
  }

  QueryBuilder<Deadline, Frequency, QQueryOperations> frequencyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'frequency');
    });
  }

  QueryBuilder<Deadline, bool, QQueryOperations> isSyncedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isSynced');
    });
  }

  QueryBuilder<Deadline, DateTime, QQueryOperations> lastUpdatedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastUpdated');
    });
  }

  QueryBuilder<Deadline, String, QQueryOperations> nameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'name');
    });
  }

  QueryBuilder<Deadline, int?, QQueryOperations> notificationIDProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'notificationID');
    });
  }

  QueryBuilder<Deadline, Priority, QQueryOperations> priorityProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'priority');
    });
  }

  QueryBuilder<Deadline, List<bool>, QQueryOperations> repeatDaysProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'repeatDays');
    });
  }

  QueryBuilder<Deadline, int?, QQueryOperations> repeatIDProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'repeatID');
    });
  }

  QueryBuilder<Deadline, int, QQueryOperations> repeatSkipProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'repeatSkip');
    });
  }

  QueryBuilder<Deadline, bool, QQueryOperations> repeatableProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'repeatable');
    });
  }

  QueryBuilder<Deadline, DateTime, QQueryOperations> startDateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'startDate');
    });
  }

  QueryBuilder<Deadline, bool, QQueryOperations> toDeleteProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'toDelete');
    });
  }

  QueryBuilder<Deadline, DateTime, QQueryOperations> warnDateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'warnDate');
    });
  }

  QueryBuilder<Deadline, bool, QQueryOperations> warnMeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'warnMe');
    });
  }
}
