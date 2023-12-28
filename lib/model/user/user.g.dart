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
    r'dayCost': PropertySchema(
      id: 5,
      name: r'dayCost',
      type: IsarType.long,
    ),
    r'deleteSchedule': PropertySchema(
      id: 6,
      name: r'deleteSchedule',
      type: IsarType.byte,
      enumMap: _UserdeleteScheduleEnumValueMap,
    ),
    r'dontAsk': PropertySchema(
      id: 7,
      name: r'dontAsk',
      type: IsarType.bool,
    ),
    r'isSynced': PropertySchema(
      id: 8,
      name: r'isSynced',
      type: IsarType.bool,
    ),
    r'lastOpened': PropertySchema(
      id: 9,
      name: r'lastOpened',
      type: IsarType.dateTime,
    ),
    r'lastUpdated': PropertySchema(
      id: 10,
      name: r'lastUpdated',
      type: IsarType.dateTime,
    ),
    r'primarySeed': PropertySchema(
      id: 11,
      name: r'primarySeed',
      type: IsarType.long,
    ),
    r'reduceMotion': PropertySchema(
      id: 12,
      name: r'reduceMotion',
      type: IsarType.bool,
    ),
    r'scaffoldOpacity': PropertySchema(
      id: 13,
      name: r'scaffoldOpacity',
      type: IsarType.double,
    ),
    r'secondarySeed': PropertySchema(
      id: 14,
      name: r'secondarySeed',
      type: IsarType.long,
    ),
    r'sidebarOpacity': PropertySchema(
      id: 15,
      name: r'sidebarOpacity',
      type: IsarType.double,
    ),
    r'syncOnline': PropertySchema(
      id: 16,
      name: r'syncOnline',
      type: IsarType.bool,
    ),
    r'tertiarySeed': PropertySchema(
      id: 17,
      name: r'tertiarySeed',
      type: IsarType.long,
    ),
    r'themeType': PropertySchema(
      id: 18,
      name: r'themeType',
      type: IsarType.byte,
      enumMap: _UserthemeTypeEnumValueMap,
    ),
    r'toneMapping': PropertySchema(
      id: 19,
      name: r'toneMapping',
      type: IsarType.byte,
      enumMap: _UsertoneMappingEnumValueMap,
    ),
    r'useUltraHighContrast': PropertySchema(
      id: 20,
      name: r'useUltraHighContrast',
      type: IsarType.bool,
    ),
    r'userName': PropertySchema(
      id: 21,
      name: r'userName',
      type: IsarType.string,
    ),
    r'uuid': PropertySchema(
      id: 22,
      name: r'uuid',
      type: IsarType.string,
    ),
    r'windowEffect': PropertySchema(
      id: 23,
      name: r'windowEffect',
      type: IsarType.byte,
      enumMap: _UserwindowEffectEnumValueMap,
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
  writer.writeLong(offsets[5], object.dayCost);
  writer.writeByte(offsets[6], object.deleteSchedule.index);
  writer.writeBool(offsets[7], object.dontAsk);
  writer.writeBool(offsets[8], object.isSynced);
  writer.writeDateTime(offsets[9], object.lastOpened);
  writer.writeDateTime(offsets[10], object.lastUpdated);
  writer.writeLong(offsets[11], object.primarySeed);
  writer.writeBool(offsets[12], object.reduceMotion);
  writer.writeDouble(offsets[13], object.scaffoldOpacity);
  writer.writeLong(offsets[14], object.secondarySeed);
  writer.writeDouble(offsets[15], object.sidebarOpacity);
  writer.writeBool(offsets[16], object.syncOnline);
  writer.writeLong(offsets[17], object.tertiarySeed);
  writer.writeByte(offsets[18], object.themeType.index);
  writer.writeByte(offsets[19], object.toneMapping.index);
  writer.writeBool(offsets[20], object.useUltraHighContrast);
  writer.writeString(offsets[21], object.userName);
  writer.writeString(offsets[22], object.uuid);
  writer.writeByte(offsets[23], object.windowEffect.index);
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
    dayCost: reader.readLongOrNull(offsets[5]) ?? 0,
    deleteSchedule:
        _UserdeleteScheduleValueEnumMap[reader.readByteOrNull(offsets[6])] ??
            DeleteSchedule.never,
    dontAsk: reader.readBoolOrNull(offsets[7]) ?? false,
    isSynced: reader.readBoolOrNull(offsets[8]) ?? false,
    lastOpened: reader.readDateTime(offsets[9]),
    lastUpdated: reader.readDateTime(offsets[10]),
    primarySeed: reader.readLong(offsets[11]),
    reduceMotion: reader.readBoolOrNull(offsets[12]) ?? false,
    scaffoldOpacity: reader.readDoubleOrNull(offsets[13]),
    secondarySeed: reader.readLongOrNull(offsets[14]),
    sidebarOpacity: reader.readDoubleOrNull(offsets[15]),
    syncOnline: reader.readBoolOrNull(offsets[16]) ?? false,
    tertiarySeed: reader.readLongOrNull(offsets[17]),
    themeType: _UserthemeTypeValueEnumMap[reader.readByteOrNull(offsets[18])] ??
        ThemeType.system,
    toneMapping:
        _UsertoneMappingValueEnumMap[reader.readByteOrNull(offsets[19])] ??
            ToneMapping.system,
    useUltraHighContrast: reader.readBoolOrNull(offsets[20]) ?? false,
    userName: reader.readString(offsets[21]),
    windowEffect:
        _UserwindowEffectValueEnumMap[reader.readByteOrNull(offsets[23])] ??
            Effect.disabled,
  );
  object.id = id;
  object.uuid = reader.readStringOrNull(offsets[22]);
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
      return (reader.readLongOrNull(offset) ?? 0) as P;
    case 6:
      return (_UserdeleteScheduleValueEnumMap[reader.readByteOrNull(offset)] ??
          DeleteSchedule.never) as P;
    case 7:
      return (reader.readBoolOrNull(offset) ?? false) as P;
    case 8:
      return (reader.readBoolOrNull(offset) ?? false) as P;
    case 9:
      return (reader.readDateTime(offset)) as P;
    case 10:
      return (reader.readDateTime(offset)) as P;
    case 11:
      return (reader.readLong(offset)) as P;
    case 12:
      return (reader.readBoolOrNull(offset) ?? false) as P;
    case 13:
      return (reader.readDoubleOrNull(offset)) as P;
    case 14:
      return (reader.readLongOrNull(offset)) as P;
    case 15:
      return (reader.readDoubleOrNull(offset)) as P;
    case 16:
      return (reader.readBoolOrNull(offset) ?? false) as P;
    case 17:
      return (reader.readLongOrNull(offset)) as P;
    case 18:
      return (_UserthemeTypeValueEnumMap[reader.readByteOrNull(offset)] ??
          ThemeType.system) as P;
    case 19:
      return (_UsertoneMappingValueEnumMap[reader.readByteOrNull(offset)] ??
          ToneMapping.system) as P;
    case 20:
      return (reader.readBoolOrNull(offset) ?? false) as P;
    case 21:
      return (reader.readString(offset)) as P;
    case 22:
      return (reader.readStringOrNull(offset)) as P;
    case 23:
      return (_UserwindowEffectValueEnumMap[reader.readByteOrNull(offset)] ??
          Effect.disabled) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

const _UserdeleteScheduleEnumValueMap = {
  'never': 0,
  'monthly': 1,
  'yearly': 2,
};
const _UserdeleteScheduleValueEnumMap = {
  0: DeleteSchedule.never,
  1: DeleteSchedule.monthly,
  2: DeleteSchedule.yearly,
};
const _UserthemeTypeEnumValueMap = {
  'system': 0,
  'light': 1,
  'dark': 2,
  'hi_contrast_light': 3,
  'hi_contrast_dark': 4,
};
const _UserthemeTypeValueEnumMap = {
  0: ThemeType.system,
  1: ThemeType.light,
  2: ThemeType.dark,
  3: ThemeType.hi_contrast_light,
  4: ThemeType.hi_contrast_dark,
};
const _UsertoneMappingEnumValueMap = {
  'system': 0,
  'soft': 1,
  'vivid': 2,
  'monochromatic': 3,
  'hi_contrast': 4,
  'ultra_hi_contrast': 5,
};
const _UsertoneMappingValueEnumMap = {
  0: ToneMapping.system,
  1: ToneMapping.soft,
  2: ToneMapping.vivid,
  3: ToneMapping.monochromatic,
  4: ToneMapping.hi_contrast,
  5: ToneMapping.ultra_hi_contrast,
};
const _UserwindowEffectEnumValueMap = {
  'disabled': 0,
  'transparent': 1,
  'aero': 2,
  'acrylic': 3,
  'sidebar': 4,
};
const _UserwindowEffectValueEnumMap = {
  0: Effect.disabled,
  1: Effect.transparent,
  2: Effect.aero,
  3: Effect.acrylic,
  4: Effect.sidebar,
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

  QueryBuilder<User, User, QAfterFilterCondition> dayCostEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'dayCost',
        value: value,
      ));
    });
  }

  QueryBuilder<User, User, QAfterFilterCondition> dayCostGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'dayCost',
        value: value,
      ));
    });
  }

  QueryBuilder<User, User, QAfterFilterCondition> dayCostLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'dayCost',
        value: value,
      ));
    });
  }

  QueryBuilder<User, User, QAfterFilterCondition> dayCostBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'dayCost',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<User, User, QAfterFilterCondition> deleteScheduleEqualTo(
      DeleteSchedule value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'deleteSchedule',
        value: value,
      ));
    });
  }

  QueryBuilder<User, User, QAfterFilterCondition> deleteScheduleGreaterThan(
    DeleteSchedule value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'deleteSchedule',
        value: value,
      ));
    });
  }

  QueryBuilder<User, User, QAfterFilterCondition> deleteScheduleLessThan(
    DeleteSchedule value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'deleteSchedule',
        value: value,
      ));
    });
  }

  QueryBuilder<User, User, QAfterFilterCondition> deleteScheduleBetween(
    DeleteSchedule lower,
    DeleteSchedule upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'deleteSchedule',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<User, User, QAfterFilterCondition> dontAskEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'dontAsk',
        value: value,
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

  QueryBuilder<User, User, QAfterFilterCondition> lastUpdatedEqualTo(
      DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastUpdated',
        value: value,
      ));
    });
  }

  QueryBuilder<User, User, QAfterFilterCondition> lastUpdatedGreaterThan(
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

  QueryBuilder<User, User, QAfterFilterCondition> lastUpdatedLessThan(
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

  QueryBuilder<User, User, QAfterFilterCondition> lastUpdatedBetween(
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

  QueryBuilder<User, User, QAfterFilterCondition> primarySeedEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'primarySeed',
        value: value,
      ));
    });
  }

  QueryBuilder<User, User, QAfterFilterCondition> primarySeedGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'primarySeed',
        value: value,
      ));
    });
  }

  QueryBuilder<User, User, QAfterFilterCondition> primarySeedLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'primarySeed',
        value: value,
      ));
    });
  }

  QueryBuilder<User, User, QAfterFilterCondition> primarySeedBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'primarySeed',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<User, User, QAfterFilterCondition> reduceMotionEqualTo(
      bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'reduceMotion',
        value: value,
      ));
    });
  }

  QueryBuilder<User, User, QAfterFilterCondition> scaffoldOpacityIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'scaffoldOpacity',
      ));
    });
  }

  QueryBuilder<User, User, QAfterFilterCondition> scaffoldOpacityIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'scaffoldOpacity',
      ));
    });
  }

  QueryBuilder<User, User, QAfterFilterCondition> scaffoldOpacityEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'scaffoldOpacity',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<User, User, QAfterFilterCondition> scaffoldOpacityGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'scaffoldOpacity',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<User, User, QAfterFilterCondition> scaffoldOpacityLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'scaffoldOpacity',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<User, User, QAfterFilterCondition> scaffoldOpacityBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'scaffoldOpacity',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<User, User, QAfterFilterCondition> secondarySeedIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'secondarySeed',
      ));
    });
  }

  QueryBuilder<User, User, QAfterFilterCondition> secondarySeedIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'secondarySeed',
      ));
    });
  }

  QueryBuilder<User, User, QAfterFilterCondition> secondarySeedEqualTo(
      int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'secondarySeed',
        value: value,
      ));
    });
  }

  QueryBuilder<User, User, QAfterFilterCondition> secondarySeedGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'secondarySeed',
        value: value,
      ));
    });
  }

  QueryBuilder<User, User, QAfterFilterCondition> secondarySeedLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'secondarySeed',
        value: value,
      ));
    });
  }

  QueryBuilder<User, User, QAfterFilterCondition> secondarySeedBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'secondarySeed',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<User, User, QAfterFilterCondition> sidebarOpacityIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'sidebarOpacity',
      ));
    });
  }

  QueryBuilder<User, User, QAfterFilterCondition> sidebarOpacityIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'sidebarOpacity',
      ));
    });
  }

  QueryBuilder<User, User, QAfterFilterCondition> sidebarOpacityEqualTo(
    double? value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'sidebarOpacity',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<User, User, QAfterFilterCondition> sidebarOpacityGreaterThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'sidebarOpacity',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<User, User, QAfterFilterCondition> sidebarOpacityLessThan(
    double? value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'sidebarOpacity',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<User, User, QAfterFilterCondition> sidebarOpacityBetween(
    double? lower,
    double? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'sidebarOpacity',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
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

  QueryBuilder<User, User, QAfterFilterCondition> tertiarySeedIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'tertiarySeed',
      ));
    });
  }

  QueryBuilder<User, User, QAfterFilterCondition> tertiarySeedIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'tertiarySeed',
      ));
    });
  }

  QueryBuilder<User, User, QAfterFilterCondition> tertiarySeedEqualTo(
      int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'tertiarySeed',
        value: value,
      ));
    });
  }

  QueryBuilder<User, User, QAfterFilterCondition> tertiarySeedGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'tertiarySeed',
        value: value,
      ));
    });
  }

  QueryBuilder<User, User, QAfterFilterCondition> tertiarySeedLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'tertiarySeed',
        value: value,
      ));
    });
  }

  QueryBuilder<User, User, QAfterFilterCondition> tertiarySeedBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'tertiarySeed',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
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

  QueryBuilder<User, User, QAfterFilterCondition> toneMappingEqualTo(
      ToneMapping value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'toneMapping',
        value: value,
      ));
    });
  }

  QueryBuilder<User, User, QAfterFilterCondition> toneMappingGreaterThan(
    ToneMapping value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'toneMapping',
        value: value,
      ));
    });
  }

  QueryBuilder<User, User, QAfterFilterCondition> toneMappingLessThan(
    ToneMapping value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'toneMapping',
        value: value,
      ));
    });
  }

  QueryBuilder<User, User, QAfterFilterCondition> toneMappingBetween(
    ToneMapping lower,
    ToneMapping upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'toneMapping',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<User, User, QAfterFilterCondition> useUltraHighContrastEqualTo(
      bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'useUltraHighContrast',
        value: value,
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

  QueryBuilder<User, User, QAfterFilterCondition> windowEffectEqualTo(
      Effect value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'windowEffect',
        value: value,
      ));
    });
  }

  QueryBuilder<User, User, QAfterFilterCondition> windowEffectGreaterThan(
    Effect value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'windowEffect',
        value: value,
      ));
    });
  }

  QueryBuilder<User, User, QAfterFilterCondition> windowEffectLessThan(
    Effect value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'windowEffect',
        value: value,
      ));
    });
  }

  QueryBuilder<User, User, QAfterFilterCondition> windowEffectBetween(
    Effect lower,
    Effect upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'windowEffect',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
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

  QueryBuilder<User, User, QAfterSortBy> sortByDayCost() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dayCost', Sort.asc);
    });
  }

  QueryBuilder<User, User, QAfterSortBy> sortByDayCostDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dayCost', Sort.desc);
    });
  }

  QueryBuilder<User, User, QAfterSortBy> sortByDeleteSchedule() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deleteSchedule', Sort.asc);
    });
  }

  QueryBuilder<User, User, QAfterSortBy> sortByDeleteScheduleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deleteSchedule', Sort.desc);
    });
  }

  QueryBuilder<User, User, QAfterSortBy> sortByDontAsk() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dontAsk', Sort.asc);
    });
  }

  QueryBuilder<User, User, QAfterSortBy> sortByDontAskDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dontAsk', Sort.desc);
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

  QueryBuilder<User, User, QAfterSortBy> sortByLastUpdated() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastUpdated', Sort.asc);
    });
  }

  QueryBuilder<User, User, QAfterSortBy> sortByLastUpdatedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastUpdated', Sort.desc);
    });
  }

  QueryBuilder<User, User, QAfterSortBy> sortByPrimarySeed() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'primarySeed', Sort.asc);
    });
  }

  QueryBuilder<User, User, QAfterSortBy> sortByPrimarySeedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'primarySeed', Sort.desc);
    });
  }

  QueryBuilder<User, User, QAfterSortBy> sortByReduceMotion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'reduceMotion', Sort.asc);
    });
  }

  QueryBuilder<User, User, QAfterSortBy> sortByReduceMotionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'reduceMotion', Sort.desc);
    });
  }

  QueryBuilder<User, User, QAfterSortBy> sortByScaffoldOpacity() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'scaffoldOpacity', Sort.asc);
    });
  }

  QueryBuilder<User, User, QAfterSortBy> sortByScaffoldOpacityDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'scaffoldOpacity', Sort.desc);
    });
  }

  QueryBuilder<User, User, QAfterSortBy> sortBySecondarySeed() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'secondarySeed', Sort.asc);
    });
  }

  QueryBuilder<User, User, QAfterSortBy> sortBySecondarySeedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'secondarySeed', Sort.desc);
    });
  }

  QueryBuilder<User, User, QAfterSortBy> sortBySidebarOpacity() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sidebarOpacity', Sort.asc);
    });
  }

  QueryBuilder<User, User, QAfterSortBy> sortBySidebarOpacityDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sidebarOpacity', Sort.desc);
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

  QueryBuilder<User, User, QAfterSortBy> sortByTertiarySeed() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tertiarySeed', Sort.asc);
    });
  }

  QueryBuilder<User, User, QAfterSortBy> sortByTertiarySeedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tertiarySeed', Sort.desc);
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

  QueryBuilder<User, User, QAfterSortBy> sortByToneMapping() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'toneMapping', Sort.asc);
    });
  }

  QueryBuilder<User, User, QAfterSortBy> sortByToneMappingDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'toneMapping', Sort.desc);
    });
  }

  QueryBuilder<User, User, QAfterSortBy> sortByUseUltraHighContrast() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'useUltraHighContrast', Sort.asc);
    });
  }

  QueryBuilder<User, User, QAfterSortBy> sortByUseUltraHighContrastDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'useUltraHighContrast', Sort.desc);
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

  QueryBuilder<User, User, QAfterSortBy> sortByWindowEffect() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'windowEffect', Sort.asc);
    });
  }

  QueryBuilder<User, User, QAfterSortBy> sortByWindowEffectDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'windowEffect', Sort.desc);
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

  QueryBuilder<User, User, QAfterSortBy> thenByDayCost() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dayCost', Sort.asc);
    });
  }

  QueryBuilder<User, User, QAfterSortBy> thenByDayCostDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dayCost', Sort.desc);
    });
  }

  QueryBuilder<User, User, QAfterSortBy> thenByDeleteSchedule() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deleteSchedule', Sort.asc);
    });
  }

  QueryBuilder<User, User, QAfterSortBy> thenByDeleteScheduleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deleteSchedule', Sort.desc);
    });
  }

  QueryBuilder<User, User, QAfterSortBy> thenByDontAsk() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dontAsk', Sort.asc);
    });
  }

  QueryBuilder<User, User, QAfterSortBy> thenByDontAskDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dontAsk', Sort.desc);
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

  QueryBuilder<User, User, QAfterSortBy> thenByLastUpdated() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastUpdated', Sort.asc);
    });
  }

  QueryBuilder<User, User, QAfterSortBy> thenByLastUpdatedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastUpdated', Sort.desc);
    });
  }

  QueryBuilder<User, User, QAfterSortBy> thenByPrimarySeed() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'primarySeed', Sort.asc);
    });
  }

  QueryBuilder<User, User, QAfterSortBy> thenByPrimarySeedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'primarySeed', Sort.desc);
    });
  }

  QueryBuilder<User, User, QAfterSortBy> thenByReduceMotion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'reduceMotion', Sort.asc);
    });
  }

  QueryBuilder<User, User, QAfterSortBy> thenByReduceMotionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'reduceMotion', Sort.desc);
    });
  }

  QueryBuilder<User, User, QAfterSortBy> thenByScaffoldOpacity() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'scaffoldOpacity', Sort.asc);
    });
  }

  QueryBuilder<User, User, QAfterSortBy> thenByScaffoldOpacityDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'scaffoldOpacity', Sort.desc);
    });
  }

  QueryBuilder<User, User, QAfterSortBy> thenBySecondarySeed() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'secondarySeed', Sort.asc);
    });
  }

  QueryBuilder<User, User, QAfterSortBy> thenBySecondarySeedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'secondarySeed', Sort.desc);
    });
  }

  QueryBuilder<User, User, QAfterSortBy> thenBySidebarOpacity() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sidebarOpacity', Sort.asc);
    });
  }

  QueryBuilder<User, User, QAfterSortBy> thenBySidebarOpacityDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sidebarOpacity', Sort.desc);
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

  QueryBuilder<User, User, QAfterSortBy> thenByTertiarySeed() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tertiarySeed', Sort.asc);
    });
  }

  QueryBuilder<User, User, QAfterSortBy> thenByTertiarySeedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tertiarySeed', Sort.desc);
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

  QueryBuilder<User, User, QAfterSortBy> thenByToneMapping() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'toneMapping', Sort.asc);
    });
  }

  QueryBuilder<User, User, QAfterSortBy> thenByToneMappingDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'toneMapping', Sort.desc);
    });
  }

  QueryBuilder<User, User, QAfterSortBy> thenByUseUltraHighContrast() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'useUltraHighContrast', Sort.asc);
    });
  }

  QueryBuilder<User, User, QAfterSortBy> thenByUseUltraHighContrastDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'useUltraHighContrast', Sort.desc);
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

  QueryBuilder<User, User, QAfterSortBy> thenByWindowEffect() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'windowEffect', Sort.asc);
    });
  }

  QueryBuilder<User, User, QAfterSortBy> thenByWindowEffectDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'windowEffect', Sort.desc);
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

  QueryBuilder<User, User, QDistinct> distinctByDayCost() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'dayCost');
    });
  }

  QueryBuilder<User, User, QDistinct> distinctByDeleteSchedule() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'deleteSchedule');
    });
  }

  QueryBuilder<User, User, QDistinct> distinctByDontAsk() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'dontAsk');
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

  QueryBuilder<User, User, QDistinct> distinctByLastUpdated() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastUpdated');
    });
  }

  QueryBuilder<User, User, QDistinct> distinctByPrimarySeed() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'primarySeed');
    });
  }

  QueryBuilder<User, User, QDistinct> distinctByReduceMotion() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'reduceMotion');
    });
  }

  QueryBuilder<User, User, QDistinct> distinctByScaffoldOpacity() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'scaffoldOpacity');
    });
  }

  QueryBuilder<User, User, QDistinct> distinctBySecondarySeed() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'secondarySeed');
    });
  }

  QueryBuilder<User, User, QDistinct> distinctBySidebarOpacity() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'sidebarOpacity');
    });
  }

  QueryBuilder<User, User, QDistinct> distinctBySyncOnline() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'syncOnline');
    });
  }

  QueryBuilder<User, User, QDistinct> distinctByTertiarySeed() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'tertiarySeed');
    });
  }

  QueryBuilder<User, User, QDistinct> distinctByThemeType() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'themeType');
    });
  }

  QueryBuilder<User, User, QDistinct> distinctByToneMapping() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'toneMapping');
    });
  }

  QueryBuilder<User, User, QDistinct> distinctByUseUltraHighContrast() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'useUltraHighContrast');
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

  QueryBuilder<User, User, QDistinct> distinctByWindowEffect() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'windowEffect');
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

  QueryBuilder<User, int, QQueryOperations> dayCostProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'dayCost');
    });
  }

  QueryBuilder<User, DeleteSchedule, QQueryOperations>
      deleteScheduleProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'deleteSchedule');
    });
  }

  QueryBuilder<User, bool, QQueryOperations> dontAskProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'dontAsk');
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

  QueryBuilder<User, DateTime, QQueryOperations> lastUpdatedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastUpdated');
    });
  }

  QueryBuilder<User, int, QQueryOperations> primarySeedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'primarySeed');
    });
  }

  QueryBuilder<User, bool, QQueryOperations> reduceMotionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'reduceMotion');
    });
  }

  QueryBuilder<User, double?, QQueryOperations> scaffoldOpacityProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'scaffoldOpacity');
    });
  }

  QueryBuilder<User, int?, QQueryOperations> secondarySeedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'secondarySeed');
    });
  }

  QueryBuilder<User, double?, QQueryOperations> sidebarOpacityProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sidebarOpacity');
    });
  }

  QueryBuilder<User, bool, QQueryOperations> syncOnlineProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'syncOnline');
    });
  }

  QueryBuilder<User, int?, QQueryOperations> tertiarySeedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'tertiarySeed');
    });
  }

  QueryBuilder<User, ThemeType, QQueryOperations> themeTypeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'themeType');
    });
  }

  QueryBuilder<User, ToneMapping, QQueryOperations> toneMappingProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'toneMapping');
    });
  }

  QueryBuilder<User, bool, QQueryOperations> useUltraHighContrastProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'useUltraHighContrast');
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

  QueryBuilder<User, Effect, QQueryOperations> windowEffectProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'windowEffect');
    });
  }
}
