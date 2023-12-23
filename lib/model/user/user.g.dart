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
    r'bandwidth': PropertySchema(
      id: 0,
      name: r'bandwidth',
      type: IsarType.long,
    ),
    r'checkDelete': PropertySchema(
      id: 1,
      name: r'checkDelete',
      type: IsarType.bool,
    ),
    r'curAftID': PropertySchema(
      id: 2,
      name: r'curAftID',
      type: IsarType.long,
    ),
    r'curEveID': PropertySchema(
      id: 3,
      name: r'curEveID',
      type: IsarType.long,
    ),
    r'curMornID': PropertySchema(
      id: 4,
      name: r'curMornID',
      type: IsarType.long,
    ),
    r'isSynced': PropertySchema(
      id: 5,
      name: r'isSynced',
      type: IsarType.bool,
    ),
    r'lastOpened': PropertySchema(
      id: 6,
      name: r'lastOpened',
      type: IsarType.dateTime,
    ),
    r'syncOnline': PropertySchema(
      id: 7,
      name: r'syncOnline',
      type: IsarType.bool,
    ),
    r'themeType': PropertySchema(
      id: 8,
      name: r'themeType',
      type: IsarType.byte,
      enumMap: _UserthemeTypeEnumValueMap,
    ),
    r'userName': PropertySchema(
      id: 9,
      name: r'userName',
      type: IsarType.string,
    ),
    r'uuid': PropertySchema(
      id: 10,
      name: r'uuid',
      type: IsarType.string,
    )
  },
  estimateSize: _userEstimateSize,
  serialize: _userSerialize,
  deserialize: _userDeserialize,
  deserializeProp: _userDeserializeProp,
  idName: r'id',
  indexes: {
    r'uuid': IndexSchema(
      id: 2134397340427724972,
      name: r'uuid',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'uuid',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    ),
    r'userName': IndexSchema(
      id: -1677712070637581736,
      name: r'userName',
      unique: false,
      replace: false,
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
  embeddedSchemas: {},
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
  bytesCount += 3 + object.userName.length * 3;
  {
    final value = object.uuid;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _userSerialize(
  User object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.bandwidth);
  writer.writeBool(offsets[1], object.checkDelete);
  writer.writeLong(offsets[2], object.curAftID);
  writer.writeLong(offsets[3], object.curEveID);
  writer.writeLong(offsets[4], object.curMornID);
  writer.writeBool(offsets[5], object.isSynced);
  writer.writeDateTime(offsets[6], object.lastOpened);
  writer.writeBool(offsets[7], object.syncOnline);
  writer.writeByte(offsets[8], object.themeType.index);
  writer.writeString(offsets[9], object.userName);
  writer.writeString(offsets[10], object.uuid);
}

User _userDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = User(
    bandwidth: reader.readLongOrNull(offsets[0]) ?? 100,
    checkDelete: reader.readBoolOrNull(offsets[1]) ?? true,
    curAftID: reader.readLongOrNull(offsets[2]),
    curEveID: reader.readLongOrNull(offsets[3]),
    curMornID: reader.readLongOrNull(offsets[4]),
    isSynced: reader.readBoolOrNull(offsets[5]) ?? false,
    lastOpened: reader.readDateTime(offsets[6]),
    syncOnline: reader.readBool(offsets[7]),
    themeType: _UserthemeTypeValueEnumMap[reader.readByteOrNull(offsets[8])] ??
        ThemeType.dark,
    userName: reader.readString(offsets[9]),
  );
  object.id = id;
  object.uuid = reader.readStringOrNull(offsets[10]);
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
      return (reader.readLongOrNull(offset) ?? 100) as P;
    case 1:
      return (reader.readBoolOrNull(offset) ?? true) as P;
    case 2:
      return (reader.readLongOrNull(offset)) as P;
    case 3:
      return (reader.readLongOrNull(offset)) as P;
    case 4:
      return (reader.readLongOrNull(offset)) as P;
    case 5:
      return (reader.readBoolOrNull(offset) ?? false) as P;
    case 6:
      return (reader.readDateTime(offset)) as P;
    case 7:
      return (reader.readBool(offset)) as P;
    case 8:
      return (_UserthemeTypeValueEnumMap[reader.readByteOrNull(offset)] ??
          ThemeType.dark) as P;
    case 9:
      return (reader.readString(offset)) as P;
    case 10:
      return (reader.readStringOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

const _UserthemeTypeEnumValueMap = {
  'adaptive': 0,
  'light': 1,
  'dark': 2,
  'hi_contrast': 3,
};
const _UserthemeTypeValueEnumMap = {
  0: ThemeType.adaptive,
  1: ThemeType.light,
  2: ThemeType.dark,
  3: ThemeType.hi_contrast,
};

Id _userGetId(User object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _userGetLinks(User object) {
  return [];
}

void _userAttach(IsarCollection<dynamic> col, Id id, User object) {
  object.id = id;
}

extension UserQueryWhereSort on QueryBuilder<User, User, QWhere> {
  QueryBuilder<User, User, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension UserQueryWhere on QueryBuilder<User, User, QWhereClause> {
  QueryBuilder<User, User, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<User, User, QAfterWhereClause> idNotEqualTo(Id id) {
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

  QueryBuilder<User, User, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<User, User, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<User, User, QAfterWhereClause> idBetween(
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

  QueryBuilder<User, User, QAfterWhereClause> uuidIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'uuid',
        value: [null],
      ));
    });
  }

  QueryBuilder<User, User, QAfterWhereClause> uuidIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'uuid',
        lower: [null],
        includeLower: false,
        upper: [],
      ));
    });
  }

  QueryBuilder<User, User, QAfterWhereClause> uuidEqualTo(String? uuid) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'uuid',
        value: [uuid],
      ));
    });
  }

  QueryBuilder<User, User, QAfterWhereClause> uuidNotEqualTo(String? uuid) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'uuid',
              lower: [],
              upper: [uuid],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'uuid',
              lower: [uuid],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'uuid',
              lower: [uuid],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'uuid',
              lower: [],
              upper: [uuid],
              includeUpper: false,
            ));
      }
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

  QueryBuilder<User, User, QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<User, User, QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<User, User, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<User, User, QAfterFilterCondition> idBetween(
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

  QueryBuilder<User, User, QAfterFilterCondition> syncOnlineEqualTo(
      bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'syncOnline',
        value: value,
      ));
    });
  }

  QueryBuilder<User, User, QAfterFilterCondition> themeTypeEqualTo(
      ThemeType value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'themeType',
        value: value,
      ));
    });
  }

  QueryBuilder<User, User, QAfterFilterCondition> themeTypeGreaterThan(
    ThemeType value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'themeType',
        value: value,
      ));
    });
  }

  QueryBuilder<User, User, QAfterFilterCondition> themeTypeLessThan(
    ThemeType value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'themeType',
        value: value,
      ));
    });
  }

  QueryBuilder<User, User, QAfterFilterCondition> themeTypeBetween(
    ThemeType lower,
    ThemeType upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'themeType',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
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

  QueryBuilder<User, User, QAfterFilterCondition> uuidIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'uuid',
      ));
    });
  }

  QueryBuilder<User, User, QAfterFilterCondition> uuidIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'uuid',
      ));
    });
  }

  QueryBuilder<User, User, QAfterFilterCondition> uuidEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'uuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<User, User, QAfterFilterCondition> uuidGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'uuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<User, User, QAfterFilterCondition> uuidLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'uuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<User, User, QAfterFilterCondition> uuidBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'uuid',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<User, User, QAfterFilterCondition> uuidStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'uuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<User, User, QAfterFilterCondition> uuidEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'uuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<User, User, QAfterFilterCondition> uuidContains(String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'uuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<User, User, QAfterFilterCondition> uuidMatches(String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'uuid',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<User, User, QAfterFilterCondition> uuidIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'uuid',
        value: '',
      ));
    });
  }

  QueryBuilder<User, User, QAfterFilterCondition> uuidIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'uuid',
        value: '',
      ));
    });
  }
}

extension UserQueryObject on QueryBuilder<User, User, QFilterCondition> {}

extension UserQueryLinks on QueryBuilder<User, User, QFilterCondition> {}

extension UserQuerySortBy on QueryBuilder<User, User, QSortBy> {
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

  QueryBuilder<User, User, QAfterSortBy> sortByThemeType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'themeType', Sort.asc);
    });
  }

  QueryBuilder<User, User, QAfterSortBy> sortByThemeTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'themeType', Sort.desc);
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

  QueryBuilder<User, User, QAfterSortBy> sortByUuid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uuid', Sort.asc);
    });
  }

  QueryBuilder<User, User, QAfterSortBy> sortByUuidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uuid', Sort.desc);
    });
  }
}

extension UserQuerySortThenBy on QueryBuilder<User, User, QSortThenBy> {
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

  QueryBuilder<User, User, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<User, User, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
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

  QueryBuilder<User, User, QAfterSortBy> thenByThemeType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'themeType', Sort.asc);
    });
  }

  QueryBuilder<User, User, QAfterSortBy> thenByThemeTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'themeType', Sort.desc);
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

  QueryBuilder<User, User, QAfterSortBy> thenByUuid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uuid', Sort.asc);
    });
  }

  QueryBuilder<User, User, QAfterSortBy> thenByUuidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uuid', Sort.desc);
    });
  }
}

extension UserQueryWhereDistinct on QueryBuilder<User, User, QDistinct> {
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

  QueryBuilder<User, User, QDistinct> distinctBySyncOnline() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'syncOnline');
    });
  }

  QueryBuilder<User, User, QDistinct> distinctByThemeType() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'themeType');
    });
  }

  QueryBuilder<User, User, QDistinct> distinctByUserName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'userName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<User, User, QDistinct> distinctByUuid(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'uuid', caseSensitive: caseSensitive);
    });
  }
}

extension UserQueryProperty on QueryBuilder<User, User, QQueryProperty> {
  QueryBuilder<User, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
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

  QueryBuilder<User, bool, QQueryOperations> syncOnlineProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'syncOnline');
    });
  }

  QueryBuilder<User, ThemeType, QQueryOperations> themeTypeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'themeType');
    });
  }

  QueryBuilder<User, String, QQueryOperations> userNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'userName');
    });
  }

  QueryBuilder<User, String?, QQueryOperations> uuidProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'uuid');
    });
  }
}
