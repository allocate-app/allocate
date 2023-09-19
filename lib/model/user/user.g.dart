// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetUserCollection on Isar {
  IsarCollection<User> get users => this.collection();
}

const UserSchema = CollectionSchema(
  name: r'User',
  id: -7838171048429979076,
  properties: {
    r'aftHour': PropertySchema(
      id: 0,
      name: r'aftHour',
      type: IsarType.long,
    ),
    r'bandwidth': PropertySchema(
      id: 1,
      name: r'bandwidth',
      type: IsarType.long,
    ),
    r'checkDelete': PropertySchema(
      id: 2,
      name: r'checkDelete',
      type: IsarType.bool,
    ),
    r'curAftID': PropertySchema(
      id: 3,
      name: r'curAftID',
      type: IsarType.long,
    ),
    r'curEveID': PropertySchema(
      id: 4,
      name: r'curEveID',
      type: IsarType.long,
    ),
    r'curMornID': PropertySchema(
      id: 5,
      name: r'curMornID',
      type: IsarType.long,
    ),
    r'curTheme': PropertySchema(
      id: 6,
      name: r'curTheme',
      type: IsarType.byte,
      enumMap: _UsercurThemeEnumValueMap,
    ),
    r'deadlineSorter': PropertySchema(
      id: 7,
      name: r'deadlineSorter',
      type: IsarType.object,
      target: r'DeadlineSorter',
    ),
    r'eveHour': PropertySchema(
      id: 8,
      name: r'eveHour',
      type: IsarType.long,
    ),
    r'groupSorter': PropertySchema(
      id: 9,
      name: r'groupSorter',
      type: IsarType.object,
      target: r'GroupSorter',
    ),
    r'isSynced': PropertySchema(
      id: 10,
      name: r'isSynced',
      type: IsarType.bool,
    ),
    r'lastOpened': PropertySchema(
      id: 11,
      name: r'lastOpened',
      type: IsarType.dateTime,
    ),
    r'mornHour': PropertySchema(
      id: 12,
      name: r'mornHour',
      type: IsarType.long,
    ),
    r'reminderSorter': PropertySchema(
      id: 13,
      name: r'reminderSorter',
      type: IsarType.object,
      target: r'ReminderSorter',
    ),
    r'routineSorter': PropertySchema(
      id: 14,
      name: r'routineSorter',
      type: IsarType.object,
      target: r'RoutineSorter',
    ),
    r'syncOnline': PropertySchema(
      id: 15,
      name: r'syncOnline',
      type: IsarType.bool,
    ),
    r'toDoSorter': PropertySchema(
      id: 16,
      name: r'toDoSorter',
      type: IsarType.object,
      target: r'ToDoSorter',
    ),
    r'userName': PropertySchema(
      id: 17,
      name: r'userName',
      type: IsarType.string,
    )
  },
  estimateSize: _userEstimateSize,
  serialize: _userSerialize,
  deserialize: _userDeserialize,
  deserializeProp: _userDeserializeProp,
  idName: r'localID',
  indexes: {
    r'userName': IndexSchema(
      id: -1677712070637581736,
      name: r'userName',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'userName',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {
    r'GroupSorter': GroupSorterSchema,
    r'DeadlineSorter': DeadlineSorterSchema,
    r'ReminderSorter': ReminderSorterSchema,
    r'RoutineSorter': RoutineSorterSchema,
    r'ToDoSorter': ToDoSorterSchema
  },
  getId: _userGetId,
  getLinks: _userGetLinks,
  attach: _userAttach,
  version: '3.1.0+1',
);

int _userEstimateSize(
  User object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.deadlineSorter;
    if (value != null) {
      bytesCount += 3 +
          DeadlineSorterSchema.estimateSize(
              value, allOffsets[DeadlineSorter]!, allOffsets);
    }
  }
  {
    final value = object.groupSorter;
    if (value != null) {
      bytesCount += 3 +
          GroupSorterSchema.estimateSize(
              value, allOffsets[GroupSorter]!, allOffsets);
    }
  }
  {
    final value = object.reminderSorter;
    if (value != null) {
      bytesCount += 3 +
          ReminderSorterSchema.estimateSize(
              value, allOffsets[ReminderSorter]!, allOffsets);
    }
  }
  {
    final value = object.routineSorter;
    if (value != null) {
      bytesCount += 3 +
          RoutineSorterSchema.estimateSize(
              value, allOffsets[RoutineSorter]!, allOffsets);
    }
  }
  {
    final value = object.toDoSorter;
    if (value != null) {
      bytesCount += 3 +
          ToDoSorterSchema.estimateSize(
              value, allOffsets[ToDoSorter]!, allOffsets);
    }
  }
  bytesCount += 3 + object.userName.length * 3;
  return bytesCount;
}

void _userSerialize(
  User object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.aftHour);
  writer.writeLong(offsets[1], object.bandwidth);
  writer.writeBool(offsets[2], object.checkDelete);
  writer.writeLong(offsets[3], object.curAftID);
  writer.writeLong(offsets[4], object.curEveID);
  writer.writeLong(offsets[5], object.curMornID);
  writer.writeByte(offsets[6], object.curTheme.index);
  writer.writeObject<DeadlineSorter>(
    offsets[7],
    allOffsets,
    DeadlineSorterSchema.serialize,
    object.deadlineSorter,
  );
  writer.writeLong(offsets[8], object.eveHour);
  writer.writeObject<GroupSorter>(
    offsets[9],
    allOffsets,
    GroupSorterSchema.serialize,
    object.groupSorter,
  );
  writer.writeBool(offsets[10], object.isSynced);
  writer.writeDateTime(offsets[11], object.lastOpened);
  writer.writeLong(offsets[12], object.mornHour);
  writer.writeObject<ReminderSorter>(
    offsets[13],
    allOffsets,
    ReminderSorterSchema.serialize,
    object.reminderSorter,
  );
  writer.writeObject<RoutineSorter>(
    offsets[14],
    allOffsets,
    RoutineSorterSchema.serialize,
    object.routineSorter,
  );
  writer.writeBool(offsets[15], object.syncOnline);
  writer.writeObject<ToDoSorter>(
    offsets[16],
    allOffsets,
    ToDoSorterSchema.serialize,
    object.toDoSorter,
  );
  writer.writeString(offsets[17], object.userName);
}

User _userDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = User(
    bandwidth: reader.readLongOrNull(offsets[1]) ?? 100,
    checkDelete: reader.readBoolOrNull(offsets[2]) ?? true,
    curAftID: reader.readLongOrNull(offsets[3]),
    curEveID: reader.readLongOrNull(offsets[4]),
    curMornID: reader.readLongOrNull(offsets[5]),
    curTheme: _UsercurThemeValueEnumMap[reader.readByteOrNull(offsets[6])] ??
        UserThemeData.dark,
    deadlineSorter: reader.readObjectOrNull<DeadlineSorter>(
      offsets[7],
      DeadlineSorterSchema.deserialize,
      allOffsets,
    ),
    groupSorter: reader.readObjectOrNull<GroupSorter>(
      offsets[9],
      GroupSorterSchema.deserialize,
      allOffsets,
    ),
    isSynced: reader.readBoolOrNull(offsets[10]) ?? false,
    lastOpened: reader.readDateTime(offsets[11]),
    reminderSorter: reader.readObjectOrNull<ReminderSorter>(
      offsets[13],
      ReminderSorterSchema.deserialize,
      allOffsets,
    ),
    routineSorter: reader.readObjectOrNull<RoutineSorter>(
      offsets[14],
      RoutineSorterSchema.deserialize,
      allOffsets,
    ),
    syncOnline: reader.readBool(offsets[15]),
    toDoSorter: reader.readObjectOrNull<ToDoSorter>(
      offsets[16],
      ToDoSorterSchema.deserialize,
      allOffsets,
    ),
    userName: reader.readString(offsets[17]),
  );
  object.aftHour = reader.readLongOrNull(offsets[0]);
  object.eveHour = reader.readLongOrNull(offsets[8]);
  object.localID = id;
  object.mornHour = reader.readLongOrNull(offsets[12]);
  return object;
}

P _userDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readLongOrNull(offset)) as P;
    case 1:
      return (reader.readLongOrNull(offset) ?? 100) as P;
    case 2:
      return (reader.readBoolOrNull(offset) ?? true) as P;
    case 3:
      return (reader.readLongOrNull(offset)) as P;
    case 4:
      return (reader.readLongOrNull(offset)) as P;
    case 5:
      return (reader.readLongOrNull(offset)) as P;
    case 6:
      return (_UsercurThemeValueEnumMap[reader.readByteOrNull(offset)] ??
          UserThemeData.dark) as P;
    case 7:
      return (reader.readObjectOrNull<DeadlineSorter>(
        offset,
        DeadlineSorterSchema.deserialize,
        allOffsets,
      )) as P;
    case 8:
      return (reader.readLongOrNull(offset)) as P;
    case 9:
      return (reader.readObjectOrNull<GroupSorter>(
        offset,
        GroupSorterSchema.deserialize,
        allOffsets,
      )) as P;
    case 10:
      return (reader.readBoolOrNull(offset) ?? false) as P;
    case 11:
      return (reader.readDateTime(offset)) as P;
    case 12:
      return (reader.readLongOrNull(offset)) as P;
    case 13:
      return (reader.readObjectOrNull<ReminderSorter>(
        offset,
        ReminderSorterSchema.deserialize,
        allOffsets,
      )) as P;
    case 14:
      return (reader.readObjectOrNull<RoutineSorter>(
        offset,
        RoutineSorterSchema.deserialize,
        allOffsets,
      )) as P;
    case 15:
      return (reader.readBool(offset)) as P;
    case 16:
      return (reader.readObjectOrNull<ToDoSorter>(
        offset,
        ToDoSorterSchema.deserialize,
        allOffsets,
      )) as P;
    case 17:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

const _UsercurThemeEnumValueMap = {
  'light': 0,
  'dark': 1,
  'hi_contrast': 2,
};
const _UsercurThemeValueEnumMap = {
  0: UserThemeData.light,
  1: UserThemeData.dark,
  2: UserThemeData.hi_contrast,
};

Id _userGetId(User object) {
  return object.localID;
}

List<IsarLinkBase<dynamic>> _userGetLinks(User object) {
  return [];
}

void _userAttach(IsarCollection<dynamic> col, Id id, User object) {
  object.localID = id;
}

extension UserByIndex on IsarCollection<User> {
  Future<User?> getByUserName(String userName) {
    return getByIndex(r'userName', [userName]);
  }

  User? getByUserNameSync(String userName) {
    return getByIndexSync(r'userName', [userName]);
  }

  Future<bool> deleteByUserName(String userName) {
    return deleteByIndex(r'userName', [userName]);
  }

  bool deleteByUserNameSync(String userName) {
    return deleteByIndexSync(r'userName', [userName]);
  }

  Future<List<User?>> getAllByUserName(List<String> userNameValues) {
    final values = userNameValues.map((e) => [e]).toList();
    return getAllByIndex(r'userName', values);
  }

  List<User?> getAllByUserNameSync(List<String> userNameValues) {
    final values = userNameValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'userName', values);
  }

  Future<int> deleteAllByUserName(List<String> userNameValues) {
    final values = userNameValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'userName', values);
  }

  int deleteAllByUserNameSync(List<String> userNameValues) {
    final values = userNameValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'userName', values);
  }

  Future<Id> putByUserName(User object) {
    return putByIndex(r'userName', object);
  }

  Id putByUserNameSync(User object, {bool saveLinks = true}) {
    return putByIndexSync(r'userName', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByUserName(List<User> objects) {
    return putAllByIndex(r'userName', objects);
  }

  List<Id> putAllByUserNameSync(List<User> objects, {bool saveLinks = true}) {
    return putAllByIndexSync(r'userName', objects, saveLinks: saveLinks);
  }
}

extension UserQueryWhereSort on QueryBuilder<User, User, QWhere> {
  QueryBuilder<User, User, QAfterWhere> anyLocalID() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension UserQueryWhere on QueryBuilder<User, User, QWhereClause> {
  QueryBuilder<User, User, QAfterWhereClause> localIDEqualTo(Id localID) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: localID,
        upper: localID,
      ));
    });
  }

  QueryBuilder<User, User, QAfterWhereClause> localIDNotEqualTo(Id localID) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: localID, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: localID, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: localID, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: localID, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<User, User, QAfterWhereClause> localIDGreaterThan(Id localID,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: localID, includeLower: include),
      );
    });
  }

  QueryBuilder<User, User, QAfterWhereClause> localIDLessThan(Id localID,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: localID, includeUpper: include),
      );
    });
  }

  QueryBuilder<User, User, QAfterWhereClause> localIDBetween(
    Id lowerLocalID,
    Id upperLocalID, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerLocalID,
        includeLower: includeLower,
        upper: upperLocalID,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<User, User, QAfterWhereClause> userNameEqualTo(String userName) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'userName',
        value: [userName],
      ));
    });
  }

  QueryBuilder<User, User, QAfterWhereClause> userNameNotEqualTo(
      String userName) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'userName',
              lower: [],
              upper: [userName],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'userName',
              lower: [userName],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'userName',
              lower: [userName],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'userName',
              lower: [],
              upper: [userName],
              includeUpper: false,
            ));
      }
    });
  }
}

extension UserQueryFilter on QueryBuilder<User, User, QFilterCondition> {
  QueryBuilder<User, User, QAfterFilterCondition> aftHourIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'aftHour',
      ));
    });
  }

  QueryBuilder<User, User, QAfterFilterCondition> aftHourIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'aftHour',
      ));
    });
  }

  QueryBuilder<User, User, QAfterFilterCondition> aftHourEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'aftHour',
        value: value,
      ));
    });
  }

  QueryBuilder<User, User, QAfterFilterCondition> aftHourGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'aftHour',
        value: value,
      ));
    });
  }

  QueryBuilder<User, User, QAfterFilterCondition> aftHourLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'aftHour',
        value: value,
      ));
    });
  }

  QueryBuilder<User, User, QAfterFilterCondition> aftHourBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'aftHour',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<User, User, QAfterFilterCondition> bandwidthEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'bandwidth',
        value: value,
      ));
    });
  }

  QueryBuilder<User, User, QAfterFilterCondition> bandwidthGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'bandwidth',
        value: value,
      ));
    });
  }

  QueryBuilder<User, User, QAfterFilterCondition> bandwidthLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'bandwidth',
        value: value,
      ));
    });
  }

  QueryBuilder<User, User, QAfterFilterCondition> bandwidthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'bandwidth',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<User, User, QAfterFilterCondition> checkDeleteEqualTo(
      bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'checkDelete',
        value: value,
      ));
    });
  }

  QueryBuilder<User, User, QAfterFilterCondition> curAftIDIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'curAftID',
      ));
    });
  }

  QueryBuilder<User, User, QAfterFilterCondition> curAftIDIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'curAftID',
      ));
    });
  }

  QueryBuilder<User, User, QAfterFilterCondition> curAftIDEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'curAftID',
        value: value,
      ));
    });
  }

  QueryBuilder<User, User, QAfterFilterCondition> curAftIDGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'curAftID',
        value: value,
      ));
    });
  }

  QueryBuilder<User, User, QAfterFilterCondition> curAftIDLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'curAftID',
        value: value,
      ));
    });
  }

  QueryBuilder<User, User, QAfterFilterCondition> curAftIDBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'curAftID',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<User, User, QAfterFilterCondition> curEveIDIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'curEveID',
      ));
    });
  }

  QueryBuilder<User, User, QAfterFilterCondition> curEveIDIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'curEveID',
      ));
    });
  }

  QueryBuilder<User, User, QAfterFilterCondition> curEveIDEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'curEveID',
        value: value,
      ));
    });
  }

  QueryBuilder<User, User, QAfterFilterCondition> curEveIDGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'curEveID',
        value: value,
      ));
    });
  }

  QueryBuilder<User, User, QAfterFilterCondition> curEveIDLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'curEveID',
        value: value,
      ));
    });
  }

  QueryBuilder<User, User, QAfterFilterCondition> curEveIDBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'curEveID',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<User, User, QAfterFilterCondition> curMornIDIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'curMornID',
      ));
    });
  }

  QueryBuilder<User, User, QAfterFilterCondition> curMornIDIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'curMornID',
      ));
    });
  }

  QueryBuilder<User, User, QAfterFilterCondition> curMornIDEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'curMornID',
        value: value,
      ));
    });
  }

  QueryBuilder<User, User, QAfterFilterCondition> curMornIDGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'curMornID',
        value: value,
      ));
    });
  }

  QueryBuilder<User, User, QAfterFilterCondition> curMornIDLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'curMornID',
        value: value,
      ));
    });
  }

  QueryBuilder<User, User, QAfterFilterCondition> curMornIDBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'curMornID',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<User, User, QAfterFilterCondition> curThemeEqualTo(
      UserThemeData value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'curTheme',
        value: value,
      ));
    });
  }

  QueryBuilder<User, User, QAfterFilterCondition> curThemeGreaterThan(
    UserThemeData value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'curTheme',
        value: value,
      ));
    });
  }

  QueryBuilder<User, User, QAfterFilterCondition> curThemeLessThan(
    UserThemeData value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'curTheme',
        value: value,
      ));
    });
  }

  QueryBuilder<User, User, QAfterFilterCondition> curThemeBetween(
    UserThemeData lower,
    UserThemeData upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'curTheme',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<User, User, QAfterFilterCondition> deadlineSorterIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'deadlineSorter',
      ));
    });
  }

  QueryBuilder<User, User, QAfterFilterCondition> deadlineSorterIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'deadlineSorter',
      ));
    });
  }

  QueryBuilder<User, User, QAfterFilterCondition> eveHourIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'eveHour',
      ));
    });
  }

  QueryBuilder<User, User, QAfterFilterCondition> eveHourIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'eveHour',
      ));
    });
  }

  QueryBuilder<User, User, QAfterFilterCondition> eveHourEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'eveHour',
        value: value,
      ));
    });
  }

  QueryBuilder<User, User, QAfterFilterCondition> eveHourGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'eveHour',
        value: value,
      ));
    });
  }

  QueryBuilder<User, User, QAfterFilterCondition> eveHourLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'eveHour',
        value: value,
      ));
    });
  }

  QueryBuilder<User, User, QAfterFilterCondition> eveHourBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'eveHour',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<User, User, QAfterFilterCondition> groupSorterIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'groupSorter',
      ));
    });
  }

  QueryBuilder<User, User, QAfterFilterCondition> groupSorterIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'groupSorter',
      ));
    });
  }

  QueryBuilder<User, User, QAfterFilterCondition> isSyncedEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isSynced',
        value: value,
      ));
    });
  }

  QueryBuilder<User, User, QAfterFilterCondition> lastOpenedEqualTo(
      DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastOpened',
        value: value,
      ));
    });
  }

  QueryBuilder<User, User, QAfterFilterCondition> lastOpenedGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'lastOpened',
        value: value,
      ));
    });
  }

  QueryBuilder<User, User, QAfterFilterCondition> lastOpenedLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'lastOpened',
        value: value,
      ));
    });
  }

  QueryBuilder<User, User, QAfterFilterCondition> lastOpenedBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'lastOpened',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<User, User, QAfterFilterCondition> localIDEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'localID',
        value: value,
      ));
    });
  }

  QueryBuilder<User, User, QAfterFilterCondition> localIDGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'localID',
        value: value,
      ));
    });
  }

  QueryBuilder<User, User, QAfterFilterCondition> localIDLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'localID',
        value: value,
      ));
    });
  }

  QueryBuilder<User, User, QAfterFilterCondition> localIDBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'localID',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<User, User, QAfterFilterCondition> mornHourIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'mornHour',
      ));
    });
  }

  QueryBuilder<User, User, QAfterFilterCondition> mornHourIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'mornHour',
      ));
    });
  }

  QueryBuilder<User, User, QAfterFilterCondition> mornHourEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'mornHour',
        value: value,
      ));
    });
  }

  QueryBuilder<User, User, QAfterFilterCondition> mornHourGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'mornHour',
        value: value,
      ));
    });
  }

  QueryBuilder<User, User, QAfterFilterCondition> mornHourLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'mornHour',
        value: value,
      ));
    });
  }

  QueryBuilder<User, User, QAfterFilterCondition> mornHourBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'mornHour',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<User, User, QAfterFilterCondition> reminderSorterIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'reminderSorter',
      ));
    });
  }

  QueryBuilder<User, User, QAfterFilterCondition> reminderSorterIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'reminderSorter',
      ));
    });
  }

  QueryBuilder<User, User, QAfterFilterCondition> routineSorterIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'routineSorter',
      ));
    });
  }

  QueryBuilder<User, User, QAfterFilterCondition> routineSorterIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'routineSorter',
      ));
    });
  }

  QueryBuilder<User, User, QAfterFilterCondition> syncOnlineEqualTo(
      bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'syncOnline',
        value: value,
      ));
    });
  }

  QueryBuilder<User, User, QAfterFilterCondition> toDoSorterIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'toDoSorter',
      ));
    });
  }

  QueryBuilder<User, User, QAfterFilterCondition> toDoSorterIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'toDoSorter',
      ));
    });
  }

  QueryBuilder<User, User, QAfterFilterCondition> userNameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'userName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<User, User, QAfterFilterCondition> userNameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'userName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<User, User, QAfterFilterCondition> userNameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'userName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<User, User, QAfterFilterCondition> userNameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'userName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<User, User, QAfterFilterCondition> userNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'userName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<User, User, QAfterFilterCondition> userNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'userName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<User, User, QAfterFilterCondition> userNameContains(String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'userName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<User, User, QAfterFilterCondition> userNameMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'userName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<User, User, QAfterFilterCondition> userNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'userName',
        value: '',
      ));
    });
  }

  QueryBuilder<User, User, QAfterFilterCondition> userNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'userName',
        value: '',
      ));
    });
  }
}

extension UserQueryObject on QueryBuilder<User, User, QFilterCondition> {
  QueryBuilder<User, User, QAfterFilterCondition> deadlineSorter(
      FilterQuery<DeadlineSorter> q) {
    return QueryBuilder.apply(this, (query) {
      return query.object(q, r'deadlineSorter');
    });
  }

  QueryBuilder<User, User, QAfterFilterCondition> groupSorter(
      FilterQuery<GroupSorter> q) {
    return QueryBuilder.apply(this, (query) {
      return query.object(q, r'groupSorter');
    });
  }

  QueryBuilder<User, User, QAfterFilterCondition> reminderSorter(
      FilterQuery<ReminderSorter> q) {
    return QueryBuilder.apply(this, (query) {
      return query.object(q, r'reminderSorter');
    });
  }

  QueryBuilder<User, User, QAfterFilterCondition> routineSorter(
      FilterQuery<RoutineSorter> q) {
    return QueryBuilder.apply(this, (query) {
      return query.object(q, r'routineSorter');
    });
  }

  QueryBuilder<User, User, QAfterFilterCondition> toDoSorter(
      FilterQuery<ToDoSorter> q) {
    return QueryBuilder.apply(this, (query) {
      return query.object(q, r'toDoSorter');
    });
  }
}

extension UserQueryLinks on QueryBuilder<User, User, QFilterCondition> {}

extension UserQuerySortBy on QueryBuilder<User, User, QSortBy> {
  QueryBuilder<User, User, QAfterSortBy> sortByAftHour() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'aftHour', Sort.asc);
    });
  }

  QueryBuilder<User, User, QAfterSortBy> sortByAftHourDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'aftHour', Sort.desc);
    });
  }

  QueryBuilder<User, User, QAfterSortBy> sortByBandwidth() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bandwidth', Sort.asc);
    });
  }

  QueryBuilder<User, User, QAfterSortBy> sortByBandwidthDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bandwidth', Sort.desc);
    });
  }

  QueryBuilder<User, User, QAfterSortBy> sortByCheckDelete() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'checkDelete', Sort.asc);
    });
  }

  QueryBuilder<User, User, QAfterSortBy> sortByCheckDeleteDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'checkDelete', Sort.desc);
    });
  }

  QueryBuilder<User, User, QAfterSortBy> sortByCurAftID() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'curAftID', Sort.asc);
    });
  }

  QueryBuilder<User, User, QAfterSortBy> sortByCurAftIDDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'curAftID', Sort.desc);
    });
  }

  QueryBuilder<User, User, QAfterSortBy> sortByCurEveID() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'curEveID', Sort.asc);
    });
  }

  QueryBuilder<User, User, QAfterSortBy> sortByCurEveIDDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'curEveID', Sort.desc);
    });
  }

  QueryBuilder<User, User, QAfterSortBy> sortByCurMornID() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'curMornID', Sort.asc);
    });
  }

  QueryBuilder<User, User, QAfterSortBy> sortByCurMornIDDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'curMornID', Sort.desc);
    });
  }

  QueryBuilder<User, User, QAfterSortBy> sortByCurTheme() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'curTheme', Sort.asc);
    });
  }

  QueryBuilder<User, User, QAfterSortBy> sortByCurThemeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'curTheme', Sort.desc);
    });
  }

  QueryBuilder<User, User, QAfterSortBy> sortByEveHour() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'eveHour', Sort.asc);
    });
  }

  QueryBuilder<User, User, QAfterSortBy> sortByEveHourDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'eveHour', Sort.desc);
    });
  }

  QueryBuilder<User, User, QAfterSortBy> sortByIsSynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.asc);
    });
  }

  QueryBuilder<User, User, QAfterSortBy> sortByIsSyncedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.desc);
    });
  }

  QueryBuilder<User, User, QAfterSortBy> sortByLastOpened() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastOpened', Sort.asc);
    });
  }

  QueryBuilder<User, User, QAfterSortBy> sortByLastOpenedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastOpened', Sort.desc);
    });
  }

  QueryBuilder<User, User, QAfterSortBy> sortByMornHour() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mornHour', Sort.asc);
    });
  }

  QueryBuilder<User, User, QAfterSortBy> sortByMornHourDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mornHour', Sort.desc);
    });
  }

  QueryBuilder<User, User, QAfterSortBy> sortBySyncOnline() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncOnline', Sort.asc);
    });
  }

  QueryBuilder<User, User, QAfterSortBy> sortBySyncOnlineDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncOnline', Sort.desc);
    });
  }

  QueryBuilder<User, User, QAfterSortBy> sortByUserName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userName', Sort.asc);
    });
  }

  QueryBuilder<User, User, QAfterSortBy> sortByUserNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userName', Sort.desc);
    });
  }
}

extension UserQuerySortThenBy on QueryBuilder<User, User, QSortThenBy> {
  QueryBuilder<User, User, QAfterSortBy> thenByAftHour() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'aftHour', Sort.asc);
    });
  }

  QueryBuilder<User, User, QAfterSortBy> thenByAftHourDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'aftHour', Sort.desc);
    });
  }

  QueryBuilder<User, User, QAfterSortBy> thenByBandwidth() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bandwidth', Sort.asc);
    });
  }

  QueryBuilder<User, User, QAfterSortBy> thenByBandwidthDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bandwidth', Sort.desc);
    });
  }

  QueryBuilder<User, User, QAfterSortBy> thenByCheckDelete() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'checkDelete', Sort.asc);
    });
  }

  QueryBuilder<User, User, QAfterSortBy> thenByCheckDeleteDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'checkDelete', Sort.desc);
    });
  }

  QueryBuilder<User, User, QAfterSortBy> thenByCurAftID() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'curAftID', Sort.asc);
    });
  }

  QueryBuilder<User, User, QAfterSortBy> thenByCurAftIDDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'curAftID', Sort.desc);
    });
  }

  QueryBuilder<User, User, QAfterSortBy> thenByCurEveID() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'curEveID', Sort.asc);
    });
  }

  QueryBuilder<User, User, QAfterSortBy> thenByCurEveIDDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'curEveID', Sort.desc);
    });
  }

  QueryBuilder<User, User, QAfterSortBy> thenByCurMornID() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'curMornID', Sort.asc);
    });
  }

  QueryBuilder<User, User, QAfterSortBy> thenByCurMornIDDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'curMornID', Sort.desc);
    });
  }

  QueryBuilder<User, User, QAfterSortBy> thenByCurTheme() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'curTheme', Sort.asc);
    });
  }

  QueryBuilder<User, User, QAfterSortBy> thenByCurThemeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'curTheme', Sort.desc);
    });
  }

  QueryBuilder<User, User, QAfterSortBy> thenByEveHour() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'eveHour', Sort.asc);
    });
  }

  QueryBuilder<User, User, QAfterSortBy> thenByEveHourDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'eveHour', Sort.desc);
    });
  }

  QueryBuilder<User, User, QAfterSortBy> thenByIsSynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.asc);
    });
  }

  QueryBuilder<User, User, QAfterSortBy> thenByIsSyncedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.desc);
    });
  }

  QueryBuilder<User, User, QAfterSortBy> thenByLastOpened() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastOpened', Sort.asc);
    });
  }

  QueryBuilder<User, User, QAfterSortBy> thenByLastOpenedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastOpened', Sort.desc);
    });
  }

  QueryBuilder<User, User, QAfterSortBy> thenByLocalID() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localID', Sort.asc);
    });
  }

  QueryBuilder<User, User, QAfterSortBy> thenByLocalIDDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'localID', Sort.desc);
    });
  }

  QueryBuilder<User, User, QAfterSortBy> thenByMornHour() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mornHour', Sort.asc);
    });
  }

  QueryBuilder<User, User, QAfterSortBy> thenByMornHourDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mornHour', Sort.desc);
    });
  }

  QueryBuilder<User, User, QAfterSortBy> thenBySyncOnline() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncOnline', Sort.asc);
    });
  }

  QueryBuilder<User, User, QAfterSortBy> thenBySyncOnlineDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncOnline', Sort.desc);
    });
  }

  QueryBuilder<User, User, QAfterSortBy> thenByUserName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userName', Sort.asc);
    });
  }

  QueryBuilder<User, User, QAfterSortBy> thenByUserNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userName', Sort.desc);
    });
  }
}

extension UserQueryWhereDistinct on QueryBuilder<User, User, QDistinct> {
  QueryBuilder<User, User, QDistinct> distinctByAftHour() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'aftHour');
    });
  }

  QueryBuilder<User, User, QDistinct> distinctByBandwidth() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'bandwidth');
    });
  }

  QueryBuilder<User, User, QDistinct> distinctByCheckDelete() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'checkDelete');
    });
  }

  QueryBuilder<User, User, QDistinct> distinctByCurAftID() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'curAftID');
    });
  }

  QueryBuilder<User, User, QDistinct> distinctByCurEveID() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'curEveID');
    });
  }

  QueryBuilder<User, User, QDistinct> distinctByCurMornID() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'curMornID');
    });
  }

  QueryBuilder<User, User, QDistinct> distinctByCurTheme() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'curTheme');
    });
  }

  QueryBuilder<User, User, QDistinct> distinctByEveHour() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'eveHour');
    });
  }

  QueryBuilder<User, User, QDistinct> distinctByIsSynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isSynced');
    });
  }

  QueryBuilder<User, User, QDistinct> distinctByLastOpened() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastOpened');
    });
  }

  QueryBuilder<User, User, QDistinct> distinctByMornHour() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'mornHour');
    });
  }

  QueryBuilder<User, User, QDistinct> distinctBySyncOnline() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'syncOnline');
    });
  }

  QueryBuilder<User, User, QDistinct> distinctByUserName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'userName', caseSensitive: caseSensitive);
    });
  }
}

extension UserQueryProperty on QueryBuilder<User, User, QQueryProperty> {
  QueryBuilder<User, int, QQueryOperations> localIDProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'localID');
    });
  }

  QueryBuilder<User, int?, QQueryOperations> aftHourProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'aftHour');
    });
  }

  QueryBuilder<User, int, QQueryOperations> bandwidthProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'bandwidth');
    });
  }

  QueryBuilder<User, bool, QQueryOperations> checkDeleteProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'checkDelete');
    });
  }

  QueryBuilder<User, int?, QQueryOperations> curAftIDProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'curAftID');
    });
  }

  QueryBuilder<User, int?, QQueryOperations> curEveIDProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'curEveID');
    });
  }

  QueryBuilder<User, int?, QQueryOperations> curMornIDProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'curMornID');
    });
  }

  QueryBuilder<User, UserThemeData, QQueryOperations> curThemeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'curTheme');
    });
  }

  QueryBuilder<User, DeadlineSorter?, QQueryOperations>
      deadlineSorterProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'deadlineSorter');
    });
  }

  QueryBuilder<User, int?, QQueryOperations> eveHourProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'eveHour');
    });
  }

  QueryBuilder<User, GroupSorter?, QQueryOperations> groupSorterProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'groupSorter');
    });
  }

  QueryBuilder<User, bool, QQueryOperations> isSyncedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isSynced');
    });
  }

  QueryBuilder<User, DateTime, QQueryOperations> lastOpenedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastOpened');
    });
  }

  QueryBuilder<User, int?, QQueryOperations> mornHourProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'mornHour');
    });
  }

  QueryBuilder<User, ReminderSorter?, QQueryOperations>
      reminderSorterProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'reminderSorter');
    });
  }

  QueryBuilder<User, RoutineSorter?, QQueryOperations> routineSorterProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'routineSorter');
    });
  }

  QueryBuilder<User, bool, QQueryOperations> syncOnlineProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'syncOnline');
    });
  }

  QueryBuilder<User, ToDoSorter?, QQueryOperations> toDoSorterProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'toDoSorter');
    });
  }

  QueryBuilder<User, String, QQueryOperations> userNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'userName');
    });
  }
}
