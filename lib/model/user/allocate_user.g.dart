// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'allocate_user.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetAllocateUserCollection on Isar {
  IsarCollection<AllocateUser> get allocateUsers => this.collection();
}

const AllocateUserSchema = CollectionSchema(
  name: r'AllocateUser',
  id: -2756271931436751004,
  properties: {
    r'bandwidth': PropertySchema(
      id: 0,
      name: r'bandwidth',
      type: IsarType.long,
    ),
    r'checkClose': PropertySchema(
      id: 1,
      name: r'checkClose',
      type: IsarType.bool,
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
    r'deleteSchedule': PropertySchema(
      id: 6,
      name: r'deleteSchedule',
      type: IsarType.byte,
      enumMap: _AllocateUserdeleteScheduleEnumValueMap,
    ),
    r'email': PropertySchema(
      id: 7,
      name: r'email',
      type: IsarType.string,
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
      enumMap: _AllocateUserthemeTypeEnumValueMap,
    ),
    r'toDelete': PropertySchema(
      id: 19,
      name: r'toDelete',
      type: IsarType.bool,
    ),
    r'toneMapping': PropertySchema(
      id: 20,
      name: r'toneMapping',
      type: IsarType.byte,
      enumMap: _AllocateUsertoneMappingEnumValueMap,
    ),
    r'useUltraHighContrast': PropertySchema(
      id: 21,
      name: r'useUltraHighContrast',
      type: IsarType.bool,
    ),
    r'username': PropertySchema(
      id: 22,
      name: r'username',
      type: IsarType.string,
    ),
    r'uuid': PropertySchema(
      id: 23,
      name: r'uuid',
      type: IsarType.string,
    ),
    r'windowEffect': PropertySchema(
      id: 24,
      name: r'windowEffect',
      type: IsarType.byte,
      enumMap: _AllocateUserwindowEffectEnumValueMap,
    )
  },
  estimateSize: _allocateUserEstimateSize,
  serialize: _allocateUserSerialize,
  deserialize: _allocateUserDeserialize,
  deserializeProp: _allocateUserDeserializeProp,
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
    r'username': IndexSchema(
      id: -2899563114555695793,
      name: r'username',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'username',
          type: IndexType.hash,
          caseSensitive: true,
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
  getId: _allocateUserGetId,
  getLinks: _allocateUserGetLinks,
  attach: _allocateUserAttach,
  version: '3.1.0+1',
);

int _allocateUserEstimateSize(
  AllocateUser object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.email;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.username.length * 3;
  {
    final value = object.uuid;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _allocateUserSerialize(
  AllocateUser object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.bandwidth);
  writer.writeBool(offsets[1], object.checkClose);
  writer.writeBool(offsets[2], object.checkDelete);
  writer.writeLong(offsets[3], object.curAftID);
  writer.writeLong(offsets[4], object.curEveID);
  writer.writeLong(offsets[5], object.curMornID);
  writer.writeByte(offsets[6], object.deleteSchedule.index);
  writer.writeString(offsets[7], object.email);
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
  writer.writeBool(offsets[19], object.toDelete);
  writer.writeByte(offsets[20], object.toneMapping.index);
  writer.writeBool(offsets[21], object.useUltraHighContrast);
  writer.writeString(offsets[22], object.username);
  writer.writeString(offsets[23], object.uuid);
  writer.writeByte(offsets[24], object.windowEffect.index);
}

AllocateUser _allocateUserDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = AllocateUser(
    bandwidth: reader.readLongOrNull(offsets[0]) ?? 100,
    checkClose: reader.readBoolOrNull(offsets[1]) ?? true,
    checkDelete: reader.readBoolOrNull(offsets[2]) ?? true,
    curAftID: reader.readLongOrNull(offsets[3]),
    curEveID: reader.readLongOrNull(offsets[4]),
    curMornID: reader.readLongOrNull(offsets[5]),
    deleteSchedule: _AllocateUserdeleteScheduleValueEnumMap[
            reader.readByteOrNull(offsets[6])] ??
        DeleteSchedule.never,
    email: reader.readStringOrNull(offsets[7]),
    id: id,
    isSynced: reader.readBoolOrNull(offsets[8]) ?? false,
    lastOpened: reader.readDateTime(offsets[9]),
    lastUpdated: reader.readDateTime(offsets[10]),
    primarySeed: reader.readLong(offsets[11]),
    reduceMotion: reader.readBoolOrNull(offsets[12]) ?? false,
    scaffoldOpacity: reader.readDoubleOrNull(offsets[13]) ?? 100,
    secondarySeed: reader.readLongOrNull(offsets[14]),
    sidebarOpacity: reader.readDoubleOrNull(offsets[15]) ?? 100,
    syncOnline: reader.readBoolOrNull(offsets[16]) ?? false,
    tertiarySeed: reader.readLongOrNull(offsets[17]),
    themeType: _AllocateUserthemeTypeValueEnumMap[
            reader.readByteOrNull(offsets[18])] ??
        ThemeType.system,
    toDelete: reader.readBoolOrNull(offsets[19]) ?? false,
    toneMapping: _AllocateUsertoneMappingValueEnumMap[
            reader.readByteOrNull(offsets[20])] ??
        ToneMapping.system,
    useUltraHighContrast: reader.readBoolOrNull(offsets[21]) ?? false,
    username: reader.readString(offsets[22]),
    uuid: reader.readStringOrNull(offsets[23]),
    windowEffect: _AllocateUserwindowEffectValueEnumMap[
            reader.readByteOrNull(offsets[24])] ??
        Effect.disabled,
  );
  return object;
}

P _allocateUserDeserializeProp<P>(
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
      return (reader.readBoolOrNull(offset) ?? true) as P;
    case 3:
      return (reader.readLongOrNull(offset)) as P;
    case 4:
      return (reader.readLongOrNull(offset)) as P;
    case 5:
      return (reader.readLongOrNull(offset)) as P;
    case 6:
      return (_AllocateUserdeleteScheduleValueEnumMap[
              reader.readByteOrNull(offset)] ??
          DeleteSchedule.never) as P;
    case 7:
      return (reader.readStringOrNull(offset)) as P;
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
      return (reader.readDoubleOrNull(offset) ?? 100) as P;
    case 14:
      return (reader.readLongOrNull(offset)) as P;
    case 15:
      return (reader.readDoubleOrNull(offset) ?? 100) as P;
    case 16:
      return (reader.readBoolOrNull(offset) ?? false) as P;
    case 17:
      return (reader.readLongOrNull(offset)) as P;
    case 18:
      return (_AllocateUserthemeTypeValueEnumMap[
              reader.readByteOrNull(offset)] ??
          ThemeType.system) as P;
    case 19:
      return (reader.readBoolOrNull(offset) ?? false) as P;
    case 20:
      return (_AllocateUsertoneMappingValueEnumMap[
              reader.readByteOrNull(offset)] ??
          ToneMapping.system) as P;
    case 21:
      return (reader.readBoolOrNull(offset) ?? false) as P;
    case 22:
      return (reader.readString(offset)) as P;
    case 23:
      return (reader.readStringOrNull(offset)) as P;
    case 24:
      return (_AllocateUserwindowEffectValueEnumMap[
              reader.readByteOrNull(offset)] ??
          Effect.disabled) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

const _AllocateUserdeleteScheduleEnumValueMap = {
  'never': 0,
  'fifteenDays': 1,
  'thirtyDays': 2,
  'oneYear': 3,
};
const _AllocateUserdeleteScheduleValueEnumMap = {
  0: DeleteSchedule.never,
  1: DeleteSchedule.fifteenDays,
  2: DeleteSchedule.thirtyDays,
  3: DeleteSchedule.oneYear,
};
const _AllocateUserthemeTypeEnumValueMap = {
  'system': 0,
  'light': 1,
  'dark': 2,
};
const _AllocateUserthemeTypeValueEnumMap = {
  0: ThemeType.system,
  1: ThemeType.light,
  2: ThemeType.dark,
};
const _AllocateUsertoneMappingEnumValueMap = {
  'system': 0,
  'soft': 1,
  'vivid': 2,
  'jolly': 3,
  'candy': 4,
  'monochromatic': 5,
  'high_contrast': 6,
  'ultra_high_contrast': 7,
};
const _AllocateUsertoneMappingValueEnumMap = {
  0: ToneMapping.system,
  1: ToneMapping.soft,
  2: ToneMapping.vivid,
  3: ToneMapping.jolly,
  4: ToneMapping.candy,
  5: ToneMapping.monochromatic,
  6: ToneMapping.high_contrast,
  7: ToneMapping.ultra_high_contrast,
};
const _AllocateUserwindowEffectEnumValueMap = {
  'disabled': 0,
  'transparent': 1,
  'aero': 2,
  'acrylic': 3,
  'mica': 4,
  'sidebar': 5,
};
const _AllocateUserwindowEffectValueEnumMap = {
  0: Effect.disabled,
  1: Effect.transparent,
  2: Effect.aero,
  3: Effect.acrylic,
  4: Effect.mica,
  5: Effect.sidebar,
};

Id _allocateUserGetId(AllocateUser object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _allocateUserGetLinks(AllocateUser object) {
  return [];
}

void _allocateUserAttach(
    IsarCollection<dynamic> col, Id id, AllocateUser object) {
  object.id = id;
}

extension AllocateUserQueryWhereSort
    on QueryBuilder<AllocateUser, AllocateUser, QWhere> {
  QueryBuilder<AllocateUser, AllocateUser, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<AllocateUser, AllocateUser, QAfterWhere> anyToDelete() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'toDelete'),
      );
    });
  }
}

extension AllocateUserQueryWhere
    on QueryBuilder<AllocateUser, AllocateUser, QWhereClause> {
  QueryBuilder<AllocateUser, AllocateUser, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<AllocateUser, AllocateUser, QAfterWhereClause> idNotEqualTo(
      Id id) {
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

  QueryBuilder<AllocateUser, AllocateUser, QAfterWhereClause> idGreaterThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<AllocateUser, AllocateUser, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<AllocateUser, AllocateUser, QAfterWhereClause> idBetween(
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

  QueryBuilder<AllocateUser, AllocateUser, QAfterWhereClause> uuidIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'uuid',
        value: [null],
      ));
    });
  }

  QueryBuilder<AllocateUser, AllocateUser, QAfterWhereClause> uuidIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'uuid',
        lower: [null],
        includeLower: false,
        upper: [],
      ));
    });
  }

  QueryBuilder<AllocateUser, AllocateUser, QAfterWhereClause> uuidEqualTo(
      String? uuid) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'uuid',
        value: [uuid],
      ));
    });
  }

  QueryBuilder<AllocateUser, AllocateUser, QAfterWhereClause> uuidNotEqualTo(
      String? uuid) {
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

  QueryBuilder<AllocateUser, AllocateUser, QAfterWhereClause> usernameEqualTo(
      String username) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'username',
        value: [username],
      ));
    });
  }

  QueryBuilder<AllocateUser, AllocateUser, QAfterWhereClause>
      usernameNotEqualTo(String username) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'username',
              lower: [],
              upper: [username],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'username',
              lower: [username],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'username',
              lower: [username],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'username',
              lower: [],
              upper: [username],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<AllocateUser, AllocateUser, QAfterWhereClause> toDeleteEqualTo(
      bool toDelete) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'toDelete',
        value: [toDelete],
      ));
    });
  }

  QueryBuilder<AllocateUser, AllocateUser, QAfterWhereClause>
      toDeleteNotEqualTo(bool toDelete) {
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

extension AllocateUserQueryFilter
    on QueryBuilder<AllocateUser, AllocateUser, QFilterCondition> {
  QueryBuilder<AllocateUser, AllocateUser, QAfterFilterCondition>
      bandwidthEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'bandwidth',
        value: value,
      ));
    });
  }

  QueryBuilder<AllocateUser, AllocateUser, QAfterFilterCondition>
      bandwidthGreaterThan(
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

  QueryBuilder<AllocateUser, AllocateUser, QAfterFilterCondition>
      bandwidthLessThan(
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

  QueryBuilder<AllocateUser, AllocateUser, QAfterFilterCondition>
      bandwidthBetween(
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

  QueryBuilder<AllocateUser, AllocateUser, QAfterFilterCondition>
      checkCloseEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'checkClose',
        value: value,
      ));
    });
  }

  QueryBuilder<AllocateUser, AllocateUser, QAfterFilterCondition>
      checkDeleteEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'checkDelete',
        value: value,
      ));
    });
  }

  QueryBuilder<AllocateUser, AllocateUser, QAfterFilterCondition>
      curAftIDIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'curAftID',
      ));
    });
  }

  QueryBuilder<AllocateUser, AllocateUser, QAfterFilterCondition>
      curAftIDIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'curAftID',
      ));
    });
  }

  QueryBuilder<AllocateUser, AllocateUser, QAfterFilterCondition>
      curAftIDEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'curAftID',
        value: value,
      ));
    });
  }

  QueryBuilder<AllocateUser, AllocateUser, QAfterFilterCondition>
      curAftIDGreaterThan(
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

  QueryBuilder<AllocateUser, AllocateUser, QAfterFilterCondition>
      curAftIDLessThan(
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

  QueryBuilder<AllocateUser, AllocateUser, QAfterFilterCondition>
      curAftIDBetween(
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

  QueryBuilder<AllocateUser, AllocateUser, QAfterFilterCondition>
      curEveIDIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'curEveID',
      ));
    });
  }

  QueryBuilder<AllocateUser, AllocateUser, QAfterFilterCondition>
      curEveIDIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'curEveID',
      ));
    });
  }

  QueryBuilder<AllocateUser, AllocateUser, QAfterFilterCondition>
      curEveIDEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'curEveID',
        value: value,
      ));
    });
  }

  QueryBuilder<AllocateUser, AllocateUser, QAfterFilterCondition>
      curEveIDGreaterThan(
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

  QueryBuilder<AllocateUser, AllocateUser, QAfterFilterCondition>
      curEveIDLessThan(
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

  QueryBuilder<AllocateUser, AllocateUser, QAfterFilterCondition>
      curEveIDBetween(
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

  QueryBuilder<AllocateUser, AllocateUser, QAfterFilterCondition>
      curMornIDIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'curMornID',
      ));
    });
  }

  QueryBuilder<AllocateUser, AllocateUser, QAfterFilterCondition>
      curMornIDIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'curMornID',
      ));
    });
  }

  QueryBuilder<AllocateUser, AllocateUser, QAfterFilterCondition>
      curMornIDEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'curMornID',
        value: value,
      ));
    });
  }

  QueryBuilder<AllocateUser, AllocateUser, QAfterFilterCondition>
      curMornIDGreaterThan(
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

  QueryBuilder<AllocateUser, AllocateUser, QAfterFilterCondition>
      curMornIDLessThan(
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

  QueryBuilder<AllocateUser, AllocateUser, QAfterFilterCondition>
      curMornIDBetween(
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

  QueryBuilder<AllocateUser, AllocateUser, QAfterFilterCondition>
      deleteScheduleEqualTo(DeleteSchedule value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'deleteSchedule',
        value: value,
      ));
    });
  }

  QueryBuilder<AllocateUser, AllocateUser, QAfterFilterCondition>
      deleteScheduleGreaterThan(
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

  QueryBuilder<AllocateUser, AllocateUser, QAfterFilterCondition>
      deleteScheduleLessThan(
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

  QueryBuilder<AllocateUser, AllocateUser, QAfterFilterCondition>
      deleteScheduleBetween(
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

  QueryBuilder<AllocateUser, AllocateUser, QAfterFilterCondition>
      emailIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'email',
      ));
    });
  }

  QueryBuilder<AllocateUser, AllocateUser, QAfterFilterCondition>
      emailIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'email',
      ));
    });
  }

  QueryBuilder<AllocateUser, AllocateUser, QAfterFilterCondition> emailEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'email',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AllocateUser, AllocateUser, QAfterFilterCondition>
      emailGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'email',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AllocateUser, AllocateUser, QAfterFilterCondition> emailLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'email',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AllocateUser, AllocateUser, QAfterFilterCondition> emailBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'email',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AllocateUser, AllocateUser, QAfterFilterCondition>
      emailStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'email',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AllocateUser, AllocateUser, QAfterFilterCondition> emailEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'email',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AllocateUser, AllocateUser, QAfterFilterCondition> emailContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'email',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AllocateUser, AllocateUser, QAfterFilterCondition> emailMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'email',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AllocateUser, AllocateUser, QAfterFilterCondition>
      emailIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'email',
        value: '',
      ));
    });
  }

  QueryBuilder<AllocateUser, AllocateUser, QAfterFilterCondition>
      emailIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'email',
        value: '',
      ));
    });
  }

  QueryBuilder<AllocateUser, AllocateUser, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<AllocateUser, AllocateUser, QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<AllocateUser, AllocateUser, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<AllocateUser, AllocateUser, QAfterFilterCondition> idBetween(
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

  QueryBuilder<AllocateUser, AllocateUser, QAfterFilterCondition>
      isSyncedEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isSynced',
        value: value,
      ));
    });
  }

  QueryBuilder<AllocateUser, AllocateUser, QAfterFilterCondition>
      lastOpenedEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastOpened',
        value: value,
      ));
    });
  }

  QueryBuilder<AllocateUser, AllocateUser, QAfterFilterCondition>
      lastOpenedGreaterThan(
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

  QueryBuilder<AllocateUser, AllocateUser, QAfterFilterCondition>
      lastOpenedLessThan(
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

  QueryBuilder<AllocateUser, AllocateUser, QAfterFilterCondition>
      lastOpenedBetween(
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

  QueryBuilder<AllocateUser, AllocateUser, QAfterFilterCondition>
      lastUpdatedEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lastUpdated',
        value: value,
      ));
    });
  }

  QueryBuilder<AllocateUser, AllocateUser, QAfterFilterCondition>
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

  QueryBuilder<AllocateUser, AllocateUser, QAfterFilterCondition>
      lastUpdatedLessThan(
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

  QueryBuilder<AllocateUser, AllocateUser, QAfterFilterCondition>
      lastUpdatedBetween(
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

  QueryBuilder<AllocateUser, AllocateUser, QAfterFilterCondition>
      primarySeedEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'primarySeed',
        value: value,
      ));
    });
  }

  QueryBuilder<AllocateUser, AllocateUser, QAfterFilterCondition>
      primarySeedGreaterThan(
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

  QueryBuilder<AllocateUser, AllocateUser, QAfterFilterCondition>
      primarySeedLessThan(
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

  QueryBuilder<AllocateUser, AllocateUser, QAfterFilterCondition>
      primarySeedBetween(
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

  QueryBuilder<AllocateUser, AllocateUser, QAfterFilterCondition>
      reduceMotionEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'reduceMotion',
        value: value,
      ));
    });
  }

  QueryBuilder<AllocateUser, AllocateUser, QAfterFilterCondition>
      scaffoldOpacityEqualTo(
    double value, {
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

  QueryBuilder<AllocateUser, AllocateUser, QAfterFilterCondition>
      scaffoldOpacityGreaterThan(
    double value, {
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

  QueryBuilder<AllocateUser, AllocateUser, QAfterFilterCondition>
      scaffoldOpacityLessThan(
    double value, {
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

  QueryBuilder<AllocateUser, AllocateUser, QAfterFilterCondition>
      scaffoldOpacityBetween(
    double lower,
    double upper, {
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

  QueryBuilder<AllocateUser, AllocateUser, QAfterFilterCondition>
      secondarySeedIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'secondarySeed',
      ));
    });
  }

  QueryBuilder<AllocateUser, AllocateUser, QAfterFilterCondition>
      secondarySeedIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'secondarySeed',
      ));
    });
  }

  QueryBuilder<AllocateUser, AllocateUser, QAfterFilterCondition>
      secondarySeedEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'secondarySeed',
        value: value,
      ));
    });
  }

  QueryBuilder<AllocateUser, AllocateUser, QAfterFilterCondition>
      secondarySeedGreaterThan(
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

  QueryBuilder<AllocateUser, AllocateUser, QAfterFilterCondition>
      secondarySeedLessThan(
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

  QueryBuilder<AllocateUser, AllocateUser, QAfterFilterCondition>
      secondarySeedBetween(
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

  QueryBuilder<AllocateUser, AllocateUser, QAfterFilterCondition>
      sidebarOpacityEqualTo(
    double value, {
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

  QueryBuilder<AllocateUser, AllocateUser, QAfterFilterCondition>
      sidebarOpacityGreaterThan(
    double value, {
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

  QueryBuilder<AllocateUser, AllocateUser, QAfterFilterCondition>
      sidebarOpacityLessThan(
    double value, {
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

  QueryBuilder<AllocateUser, AllocateUser, QAfterFilterCondition>
      sidebarOpacityBetween(
    double lower,
    double upper, {
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

  QueryBuilder<AllocateUser, AllocateUser, QAfterFilterCondition>
      syncOnlineEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'syncOnline',
        value: value,
      ));
    });
  }

  QueryBuilder<AllocateUser, AllocateUser, QAfterFilterCondition>
      tertiarySeedIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'tertiarySeed',
      ));
    });
  }

  QueryBuilder<AllocateUser, AllocateUser, QAfterFilterCondition>
      tertiarySeedIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'tertiarySeed',
      ));
    });
  }

  QueryBuilder<AllocateUser, AllocateUser, QAfterFilterCondition>
      tertiarySeedEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'tertiarySeed',
        value: value,
      ));
    });
  }

  QueryBuilder<AllocateUser, AllocateUser, QAfterFilterCondition>
      tertiarySeedGreaterThan(
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

  QueryBuilder<AllocateUser, AllocateUser, QAfterFilterCondition>
      tertiarySeedLessThan(
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

  QueryBuilder<AllocateUser, AllocateUser, QAfterFilterCondition>
      tertiarySeedBetween(
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

  QueryBuilder<AllocateUser, AllocateUser, QAfterFilterCondition>
      themeTypeEqualTo(ThemeType value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'themeType',
        value: value,
      ));
    });
  }

  QueryBuilder<AllocateUser, AllocateUser, QAfterFilterCondition>
      themeTypeGreaterThan(
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

  QueryBuilder<AllocateUser, AllocateUser, QAfterFilterCondition>
      themeTypeLessThan(
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

  QueryBuilder<AllocateUser, AllocateUser, QAfterFilterCondition>
      themeTypeBetween(
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

  QueryBuilder<AllocateUser, AllocateUser, QAfterFilterCondition>
      toDeleteEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'toDelete',
        value: value,
      ));
    });
  }

  QueryBuilder<AllocateUser, AllocateUser, QAfterFilterCondition>
      toneMappingEqualTo(ToneMapping value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'toneMapping',
        value: value,
      ));
    });
  }

  QueryBuilder<AllocateUser, AllocateUser, QAfterFilterCondition>
      toneMappingGreaterThan(
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

  QueryBuilder<AllocateUser, AllocateUser, QAfterFilterCondition>
      toneMappingLessThan(
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

  QueryBuilder<AllocateUser, AllocateUser, QAfterFilterCondition>
      toneMappingBetween(
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

  QueryBuilder<AllocateUser, AllocateUser, QAfterFilterCondition>
      useUltraHighContrastEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'useUltraHighContrast',
        value: value,
      ));
    });
  }

  QueryBuilder<AllocateUser, AllocateUser, QAfterFilterCondition>
      usernameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'username',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AllocateUser, AllocateUser, QAfterFilterCondition>
      usernameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'username',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AllocateUser, AllocateUser, QAfterFilterCondition>
      usernameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'username',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AllocateUser, AllocateUser, QAfterFilterCondition>
      usernameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'username',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AllocateUser, AllocateUser, QAfterFilterCondition>
      usernameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'username',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AllocateUser, AllocateUser, QAfterFilterCondition>
      usernameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'username',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AllocateUser, AllocateUser, QAfterFilterCondition>
      usernameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'username',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AllocateUser, AllocateUser, QAfterFilterCondition>
      usernameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'username',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AllocateUser, AllocateUser, QAfterFilterCondition>
      usernameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'username',
        value: '',
      ));
    });
  }

  QueryBuilder<AllocateUser, AllocateUser, QAfterFilterCondition>
      usernameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'username',
        value: '',
      ));
    });
  }

  QueryBuilder<AllocateUser, AllocateUser, QAfterFilterCondition> uuidIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'uuid',
      ));
    });
  }

  QueryBuilder<AllocateUser, AllocateUser, QAfterFilterCondition>
      uuidIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'uuid',
      ));
    });
  }

  QueryBuilder<AllocateUser, AllocateUser, QAfterFilterCondition> uuidEqualTo(
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

  QueryBuilder<AllocateUser, AllocateUser, QAfterFilterCondition>
      uuidGreaterThan(
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

  QueryBuilder<AllocateUser, AllocateUser, QAfterFilterCondition> uuidLessThan(
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

  QueryBuilder<AllocateUser, AllocateUser, QAfterFilterCondition> uuidBetween(
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

  QueryBuilder<AllocateUser, AllocateUser, QAfterFilterCondition>
      uuidStartsWith(
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

  QueryBuilder<AllocateUser, AllocateUser, QAfterFilterCondition> uuidEndsWith(
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

  QueryBuilder<AllocateUser, AllocateUser, QAfterFilterCondition> uuidContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'uuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AllocateUser, AllocateUser, QAfterFilterCondition> uuidMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'uuid',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<AllocateUser, AllocateUser, QAfterFilterCondition>
      uuidIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'uuid',
        value: '',
      ));
    });
  }

  QueryBuilder<AllocateUser, AllocateUser, QAfterFilterCondition>
      uuidIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'uuid',
        value: '',
      ));
    });
  }

  QueryBuilder<AllocateUser, AllocateUser, QAfterFilterCondition>
      windowEffectEqualTo(Effect value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'windowEffect',
        value: value,
      ));
    });
  }

  QueryBuilder<AllocateUser, AllocateUser, QAfterFilterCondition>
      windowEffectGreaterThan(
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

  QueryBuilder<AllocateUser, AllocateUser, QAfterFilterCondition>
      windowEffectLessThan(
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

  QueryBuilder<AllocateUser, AllocateUser, QAfterFilterCondition>
      windowEffectBetween(
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

extension AllocateUserQueryObject
    on QueryBuilder<AllocateUser, AllocateUser, QFilterCondition> {}

extension AllocateUserQueryLinks
    on QueryBuilder<AllocateUser, AllocateUser, QFilterCondition> {}

extension AllocateUserQuerySortBy
    on QueryBuilder<AllocateUser, AllocateUser, QSortBy> {
  QueryBuilder<AllocateUser, AllocateUser, QAfterSortBy> sortByBandwidth() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bandwidth', Sort.asc);
    });
  }

  QueryBuilder<AllocateUser, AllocateUser, QAfterSortBy> sortByBandwidthDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bandwidth', Sort.desc);
    });
  }

  QueryBuilder<AllocateUser, AllocateUser, QAfterSortBy> sortByCheckClose() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'checkClose', Sort.asc);
    });
  }

  QueryBuilder<AllocateUser, AllocateUser, QAfterSortBy>
      sortByCheckCloseDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'checkClose', Sort.desc);
    });
  }

  QueryBuilder<AllocateUser, AllocateUser, QAfterSortBy> sortByCheckDelete() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'checkDelete', Sort.asc);
    });
  }

  QueryBuilder<AllocateUser, AllocateUser, QAfterSortBy>
      sortByCheckDeleteDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'checkDelete', Sort.desc);
    });
  }

  QueryBuilder<AllocateUser, AllocateUser, QAfterSortBy> sortByCurAftID() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'curAftID', Sort.asc);
    });
  }

  QueryBuilder<AllocateUser, AllocateUser, QAfterSortBy> sortByCurAftIDDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'curAftID', Sort.desc);
    });
  }

  QueryBuilder<AllocateUser, AllocateUser, QAfterSortBy> sortByCurEveID() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'curEveID', Sort.asc);
    });
  }

  QueryBuilder<AllocateUser, AllocateUser, QAfterSortBy> sortByCurEveIDDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'curEveID', Sort.desc);
    });
  }

  QueryBuilder<AllocateUser, AllocateUser, QAfterSortBy> sortByCurMornID() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'curMornID', Sort.asc);
    });
  }

  QueryBuilder<AllocateUser, AllocateUser, QAfterSortBy> sortByCurMornIDDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'curMornID', Sort.desc);
    });
  }

  QueryBuilder<AllocateUser, AllocateUser, QAfterSortBy>
      sortByDeleteSchedule() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deleteSchedule', Sort.asc);
    });
  }

  QueryBuilder<AllocateUser, AllocateUser, QAfterSortBy>
      sortByDeleteScheduleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deleteSchedule', Sort.desc);
    });
  }

  QueryBuilder<AllocateUser, AllocateUser, QAfterSortBy> sortByEmail() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'email', Sort.asc);
    });
  }

  QueryBuilder<AllocateUser, AllocateUser, QAfterSortBy> sortByEmailDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'email', Sort.desc);
    });
  }

  QueryBuilder<AllocateUser, AllocateUser, QAfterSortBy> sortByIsSynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.asc);
    });
  }

  QueryBuilder<AllocateUser, AllocateUser, QAfterSortBy> sortByIsSyncedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.desc);
    });
  }

  QueryBuilder<AllocateUser, AllocateUser, QAfterSortBy> sortByLastOpened() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastOpened', Sort.asc);
    });
  }

  QueryBuilder<AllocateUser, AllocateUser, QAfterSortBy>
      sortByLastOpenedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastOpened', Sort.desc);
    });
  }

  QueryBuilder<AllocateUser, AllocateUser, QAfterSortBy> sortByLastUpdated() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastUpdated', Sort.asc);
    });
  }

  QueryBuilder<AllocateUser, AllocateUser, QAfterSortBy>
      sortByLastUpdatedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastUpdated', Sort.desc);
    });
  }

  QueryBuilder<AllocateUser, AllocateUser, QAfterSortBy> sortByPrimarySeed() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'primarySeed', Sort.asc);
    });
  }

  QueryBuilder<AllocateUser, AllocateUser, QAfterSortBy>
      sortByPrimarySeedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'primarySeed', Sort.desc);
    });
  }

  QueryBuilder<AllocateUser, AllocateUser, QAfterSortBy> sortByReduceMotion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'reduceMotion', Sort.asc);
    });
  }

  QueryBuilder<AllocateUser, AllocateUser, QAfterSortBy>
      sortByReduceMotionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'reduceMotion', Sort.desc);
    });
  }

  QueryBuilder<AllocateUser, AllocateUser, QAfterSortBy>
      sortByScaffoldOpacity() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'scaffoldOpacity', Sort.asc);
    });
  }

  QueryBuilder<AllocateUser, AllocateUser, QAfterSortBy>
      sortByScaffoldOpacityDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'scaffoldOpacity', Sort.desc);
    });
  }

  QueryBuilder<AllocateUser, AllocateUser, QAfterSortBy> sortBySecondarySeed() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'secondarySeed', Sort.asc);
    });
  }

  QueryBuilder<AllocateUser, AllocateUser, QAfterSortBy>
      sortBySecondarySeedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'secondarySeed', Sort.desc);
    });
  }

  QueryBuilder<AllocateUser, AllocateUser, QAfterSortBy>
      sortBySidebarOpacity() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sidebarOpacity', Sort.asc);
    });
  }

  QueryBuilder<AllocateUser, AllocateUser, QAfterSortBy>
      sortBySidebarOpacityDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sidebarOpacity', Sort.desc);
    });
  }

  QueryBuilder<AllocateUser, AllocateUser, QAfterSortBy> sortBySyncOnline() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncOnline', Sort.asc);
    });
  }

  QueryBuilder<AllocateUser, AllocateUser, QAfterSortBy>
      sortBySyncOnlineDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncOnline', Sort.desc);
    });
  }

  QueryBuilder<AllocateUser, AllocateUser, QAfterSortBy> sortByTertiarySeed() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tertiarySeed', Sort.asc);
    });
  }

  QueryBuilder<AllocateUser, AllocateUser, QAfterSortBy>
      sortByTertiarySeedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tertiarySeed', Sort.desc);
    });
  }

  QueryBuilder<AllocateUser, AllocateUser, QAfterSortBy> sortByThemeType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'themeType', Sort.asc);
    });
  }

  QueryBuilder<AllocateUser, AllocateUser, QAfterSortBy> sortByThemeTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'themeType', Sort.desc);
    });
  }

  QueryBuilder<AllocateUser, AllocateUser, QAfterSortBy> sortByToDelete() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'toDelete', Sort.asc);
    });
  }

  QueryBuilder<AllocateUser, AllocateUser, QAfterSortBy> sortByToDeleteDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'toDelete', Sort.desc);
    });
  }

  QueryBuilder<AllocateUser, AllocateUser, QAfterSortBy> sortByToneMapping() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'toneMapping', Sort.asc);
    });
  }

  QueryBuilder<AllocateUser, AllocateUser, QAfterSortBy>
      sortByToneMappingDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'toneMapping', Sort.desc);
    });
  }

  QueryBuilder<AllocateUser, AllocateUser, QAfterSortBy>
      sortByUseUltraHighContrast() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'useUltraHighContrast', Sort.asc);
    });
  }

  QueryBuilder<AllocateUser, AllocateUser, QAfterSortBy>
      sortByUseUltraHighContrastDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'useUltraHighContrast', Sort.desc);
    });
  }

  QueryBuilder<AllocateUser, AllocateUser, QAfterSortBy> sortByUsername() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'username', Sort.asc);
    });
  }

  QueryBuilder<AllocateUser, AllocateUser, QAfterSortBy> sortByUsernameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'username', Sort.desc);
    });
  }

  QueryBuilder<AllocateUser, AllocateUser, QAfterSortBy> sortByUuid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uuid', Sort.asc);
    });
  }

  QueryBuilder<AllocateUser, AllocateUser, QAfterSortBy> sortByUuidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uuid', Sort.desc);
    });
  }

  QueryBuilder<AllocateUser, AllocateUser, QAfterSortBy> sortByWindowEffect() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'windowEffect', Sort.asc);
    });
  }

  QueryBuilder<AllocateUser, AllocateUser, QAfterSortBy>
      sortByWindowEffectDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'windowEffect', Sort.desc);
    });
  }
}

extension AllocateUserQuerySortThenBy
    on QueryBuilder<AllocateUser, AllocateUser, QSortThenBy> {
  QueryBuilder<AllocateUser, AllocateUser, QAfterSortBy> thenByBandwidth() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bandwidth', Sort.asc);
    });
  }

  QueryBuilder<AllocateUser, AllocateUser, QAfterSortBy> thenByBandwidthDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'bandwidth', Sort.desc);
    });
  }

  QueryBuilder<AllocateUser, AllocateUser, QAfterSortBy> thenByCheckClose() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'checkClose', Sort.asc);
    });
  }

  QueryBuilder<AllocateUser, AllocateUser, QAfterSortBy>
      thenByCheckCloseDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'checkClose', Sort.desc);
    });
  }

  QueryBuilder<AllocateUser, AllocateUser, QAfterSortBy> thenByCheckDelete() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'checkDelete', Sort.asc);
    });
  }

  QueryBuilder<AllocateUser, AllocateUser, QAfterSortBy>
      thenByCheckDeleteDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'checkDelete', Sort.desc);
    });
  }

  QueryBuilder<AllocateUser, AllocateUser, QAfterSortBy> thenByCurAftID() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'curAftID', Sort.asc);
    });
  }

  QueryBuilder<AllocateUser, AllocateUser, QAfterSortBy> thenByCurAftIDDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'curAftID', Sort.desc);
    });
  }

  QueryBuilder<AllocateUser, AllocateUser, QAfterSortBy> thenByCurEveID() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'curEveID', Sort.asc);
    });
  }

  QueryBuilder<AllocateUser, AllocateUser, QAfterSortBy> thenByCurEveIDDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'curEveID', Sort.desc);
    });
  }

  QueryBuilder<AllocateUser, AllocateUser, QAfterSortBy> thenByCurMornID() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'curMornID', Sort.asc);
    });
  }

  QueryBuilder<AllocateUser, AllocateUser, QAfterSortBy> thenByCurMornIDDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'curMornID', Sort.desc);
    });
  }

  QueryBuilder<AllocateUser, AllocateUser, QAfterSortBy>
      thenByDeleteSchedule() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deleteSchedule', Sort.asc);
    });
  }

  QueryBuilder<AllocateUser, AllocateUser, QAfterSortBy>
      thenByDeleteScheduleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'deleteSchedule', Sort.desc);
    });
  }

  QueryBuilder<AllocateUser, AllocateUser, QAfterSortBy> thenByEmail() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'email', Sort.asc);
    });
  }

  QueryBuilder<AllocateUser, AllocateUser, QAfterSortBy> thenByEmailDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'email', Sort.desc);
    });
  }

  QueryBuilder<AllocateUser, AllocateUser, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<AllocateUser, AllocateUser, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<AllocateUser, AllocateUser, QAfterSortBy> thenByIsSynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.asc);
    });
  }

  QueryBuilder<AllocateUser, AllocateUser, QAfterSortBy> thenByIsSyncedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isSynced', Sort.desc);
    });
  }

  QueryBuilder<AllocateUser, AllocateUser, QAfterSortBy> thenByLastOpened() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastOpened', Sort.asc);
    });
  }

  QueryBuilder<AllocateUser, AllocateUser, QAfterSortBy>
      thenByLastOpenedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastOpened', Sort.desc);
    });
  }

  QueryBuilder<AllocateUser, AllocateUser, QAfterSortBy> thenByLastUpdated() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastUpdated', Sort.asc);
    });
  }

  QueryBuilder<AllocateUser, AllocateUser, QAfterSortBy>
      thenByLastUpdatedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lastUpdated', Sort.desc);
    });
  }

  QueryBuilder<AllocateUser, AllocateUser, QAfterSortBy> thenByPrimarySeed() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'primarySeed', Sort.asc);
    });
  }

  QueryBuilder<AllocateUser, AllocateUser, QAfterSortBy>
      thenByPrimarySeedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'primarySeed', Sort.desc);
    });
  }

  QueryBuilder<AllocateUser, AllocateUser, QAfterSortBy> thenByReduceMotion() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'reduceMotion', Sort.asc);
    });
  }

  QueryBuilder<AllocateUser, AllocateUser, QAfterSortBy>
      thenByReduceMotionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'reduceMotion', Sort.desc);
    });
  }

  QueryBuilder<AllocateUser, AllocateUser, QAfterSortBy>
      thenByScaffoldOpacity() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'scaffoldOpacity', Sort.asc);
    });
  }

  QueryBuilder<AllocateUser, AllocateUser, QAfterSortBy>
      thenByScaffoldOpacityDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'scaffoldOpacity', Sort.desc);
    });
  }

  QueryBuilder<AllocateUser, AllocateUser, QAfterSortBy> thenBySecondarySeed() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'secondarySeed', Sort.asc);
    });
  }

  QueryBuilder<AllocateUser, AllocateUser, QAfterSortBy>
      thenBySecondarySeedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'secondarySeed', Sort.desc);
    });
  }

  QueryBuilder<AllocateUser, AllocateUser, QAfterSortBy>
      thenBySidebarOpacity() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sidebarOpacity', Sort.asc);
    });
  }

  QueryBuilder<AllocateUser, AllocateUser, QAfterSortBy>
      thenBySidebarOpacityDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sidebarOpacity', Sort.desc);
    });
  }

  QueryBuilder<AllocateUser, AllocateUser, QAfterSortBy> thenBySyncOnline() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncOnline', Sort.asc);
    });
  }

  QueryBuilder<AllocateUser, AllocateUser, QAfterSortBy>
      thenBySyncOnlineDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncOnline', Sort.desc);
    });
  }

  QueryBuilder<AllocateUser, AllocateUser, QAfterSortBy> thenByTertiarySeed() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tertiarySeed', Sort.asc);
    });
  }

  QueryBuilder<AllocateUser, AllocateUser, QAfterSortBy>
      thenByTertiarySeedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'tertiarySeed', Sort.desc);
    });
  }

  QueryBuilder<AllocateUser, AllocateUser, QAfterSortBy> thenByThemeType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'themeType', Sort.asc);
    });
  }

  QueryBuilder<AllocateUser, AllocateUser, QAfterSortBy> thenByThemeTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'themeType', Sort.desc);
    });
  }

  QueryBuilder<AllocateUser, AllocateUser, QAfterSortBy> thenByToDelete() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'toDelete', Sort.asc);
    });
  }

  QueryBuilder<AllocateUser, AllocateUser, QAfterSortBy> thenByToDeleteDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'toDelete', Sort.desc);
    });
  }

  QueryBuilder<AllocateUser, AllocateUser, QAfterSortBy> thenByToneMapping() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'toneMapping', Sort.asc);
    });
  }

  QueryBuilder<AllocateUser, AllocateUser, QAfterSortBy>
      thenByToneMappingDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'toneMapping', Sort.desc);
    });
  }

  QueryBuilder<AllocateUser, AllocateUser, QAfterSortBy>
      thenByUseUltraHighContrast() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'useUltraHighContrast', Sort.asc);
    });
  }

  QueryBuilder<AllocateUser, AllocateUser, QAfterSortBy>
      thenByUseUltraHighContrastDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'useUltraHighContrast', Sort.desc);
    });
  }

  QueryBuilder<AllocateUser, AllocateUser, QAfterSortBy> thenByUsername() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'username', Sort.asc);
    });
  }

  QueryBuilder<AllocateUser, AllocateUser, QAfterSortBy> thenByUsernameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'username', Sort.desc);
    });
  }

  QueryBuilder<AllocateUser, AllocateUser, QAfterSortBy> thenByUuid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uuid', Sort.asc);
    });
  }

  QueryBuilder<AllocateUser, AllocateUser, QAfterSortBy> thenByUuidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uuid', Sort.desc);
    });
  }

  QueryBuilder<AllocateUser, AllocateUser, QAfterSortBy> thenByWindowEffect() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'windowEffect', Sort.asc);
    });
  }

  QueryBuilder<AllocateUser, AllocateUser, QAfterSortBy>
      thenByWindowEffectDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'windowEffect', Sort.desc);
    });
  }
}

extension AllocateUserQueryWhereDistinct
    on QueryBuilder<AllocateUser, AllocateUser, QDistinct> {
  QueryBuilder<AllocateUser, AllocateUser, QDistinct> distinctByBandwidth() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'bandwidth');
    });
  }

  QueryBuilder<AllocateUser, AllocateUser, QDistinct> distinctByCheckClose() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'checkClose');
    });
  }

  QueryBuilder<AllocateUser, AllocateUser, QDistinct> distinctByCheckDelete() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'checkDelete');
    });
  }

  QueryBuilder<AllocateUser, AllocateUser, QDistinct> distinctByCurAftID() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'curAftID');
    });
  }

  QueryBuilder<AllocateUser, AllocateUser, QDistinct> distinctByCurEveID() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'curEveID');
    });
  }

  QueryBuilder<AllocateUser, AllocateUser, QDistinct> distinctByCurMornID() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'curMornID');
    });
  }

  QueryBuilder<AllocateUser, AllocateUser, QDistinct>
      distinctByDeleteSchedule() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'deleteSchedule');
    });
  }

  QueryBuilder<AllocateUser, AllocateUser, QDistinct> distinctByEmail(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'email', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<AllocateUser, AllocateUser, QDistinct> distinctByIsSynced() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isSynced');
    });
  }

  QueryBuilder<AllocateUser, AllocateUser, QDistinct> distinctByLastOpened() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastOpened');
    });
  }

  QueryBuilder<AllocateUser, AllocateUser, QDistinct> distinctByLastUpdated() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lastUpdated');
    });
  }

  QueryBuilder<AllocateUser, AllocateUser, QDistinct> distinctByPrimarySeed() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'primarySeed');
    });
  }

  QueryBuilder<AllocateUser, AllocateUser, QDistinct> distinctByReduceMotion() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'reduceMotion');
    });
  }

  QueryBuilder<AllocateUser, AllocateUser, QDistinct>
      distinctByScaffoldOpacity() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'scaffoldOpacity');
    });
  }

  QueryBuilder<AllocateUser, AllocateUser, QDistinct>
      distinctBySecondarySeed() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'secondarySeed');
    });
  }

  QueryBuilder<AllocateUser, AllocateUser, QDistinct>
      distinctBySidebarOpacity() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'sidebarOpacity');
    });
  }

  QueryBuilder<AllocateUser, AllocateUser, QDistinct> distinctBySyncOnline() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'syncOnline');
    });
  }

  QueryBuilder<AllocateUser, AllocateUser, QDistinct> distinctByTertiarySeed() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'tertiarySeed');
    });
  }

  QueryBuilder<AllocateUser, AllocateUser, QDistinct> distinctByThemeType() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'themeType');
    });
  }

  QueryBuilder<AllocateUser, AllocateUser, QDistinct> distinctByToDelete() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'toDelete');
    });
  }

  QueryBuilder<AllocateUser, AllocateUser, QDistinct> distinctByToneMapping() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'toneMapping');
    });
  }

  QueryBuilder<AllocateUser, AllocateUser, QDistinct>
      distinctByUseUltraHighContrast() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'useUltraHighContrast');
    });
  }

  QueryBuilder<AllocateUser, AllocateUser, QDistinct> distinctByUsername(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'username', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<AllocateUser, AllocateUser, QDistinct> distinctByUuid(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'uuid', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<AllocateUser, AllocateUser, QDistinct> distinctByWindowEffect() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'windowEffect');
    });
  }
}

extension AllocateUserQueryProperty
    on QueryBuilder<AllocateUser, AllocateUser, QQueryProperty> {
  QueryBuilder<AllocateUser, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<AllocateUser, int, QQueryOperations> bandwidthProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'bandwidth');
    });
  }

  QueryBuilder<AllocateUser, bool, QQueryOperations> checkCloseProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'checkClose');
    });
  }

  QueryBuilder<AllocateUser, bool, QQueryOperations> checkDeleteProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'checkDelete');
    });
  }

  QueryBuilder<AllocateUser, int?, QQueryOperations> curAftIDProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'curAftID');
    });
  }

  QueryBuilder<AllocateUser, int?, QQueryOperations> curEveIDProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'curEveID');
    });
  }

  QueryBuilder<AllocateUser, int?, QQueryOperations> curMornIDProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'curMornID');
    });
  }

  QueryBuilder<AllocateUser, DeleteSchedule, QQueryOperations>
      deleteScheduleProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'deleteSchedule');
    });
  }

  QueryBuilder<AllocateUser, String?, QQueryOperations> emailProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'email');
    });
  }

  QueryBuilder<AllocateUser, bool, QQueryOperations> isSyncedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isSynced');
    });
  }

  QueryBuilder<AllocateUser, DateTime, QQueryOperations> lastOpenedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastOpened');
    });
  }

  QueryBuilder<AllocateUser, DateTime, QQueryOperations> lastUpdatedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lastUpdated');
    });
  }

  QueryBuilder<AllocateUser, int, QQueryOperations> primarySeedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'primarySeed');
    });
  }

  QueryBuilder<AllocateUser, bool, QQueryOperations> reduceMotionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'reduceMotion');
    });
  }

  QueryBuilder<AllocateUser, double, QQueryOperations>
      scaffoldOpacityProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'scaffoldOpacity');
    });
  }

  QueryBuilder<AllocateUser, int?, QQueryOperations> secondarySeedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'secondarySeed');
    });
  }

  QueryBuilder<AllocateUser, double, QQueryOperations>
      sidebarOpacityProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sidebarOpacity');
    });
  }

  QueryBuilder<AllocateUser, bool, QQueryOperations> syncOnlineProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'syncOnline');
    });
  }

  QueryBuilder<AllocateUser, int?, QQueryOperations> tertiarySeedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'tertiarySeed');
    });
  }

  QueryBuilder<AllocateUser, ThemeType, QQueryOperations> themeTypeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'themeType');
    });
  }

  QueryBuilder<AllocateUser, bool, QQueryOperations> toDeleteProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'toDelete');
    });
  }

  QueryBuilder<AllocateUser, ToneMapping, QQueryOperations>
      toneMappingProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'toneMapping');
    });
  }

  QueryBuilder<AllocateUser, bool, QQueryOperations>
      useUltraHighContrastProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'useUltraHighContrast');
    });
  }

  QueryBuilder<AllocateUser, String, QQueryOperations> usernameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'username');
    });
  }

  QueryBuilder<AllocateUser, String?, QQueryOperations> uuidProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'uuid');
    });
  }

  QueryBuilder<AllocateUser, Effect, QQueryOperations> windowEffectProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'windowEffect');
    });
  }
}
