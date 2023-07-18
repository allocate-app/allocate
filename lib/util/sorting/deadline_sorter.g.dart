// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'deadline_sorter.dart';

// **************************************************************************
// IsarEmbeddedGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

const DeadlineSorterSchema = Schema(
  name: r'DeadlineSorter',
  id: -991015892129741851,
  properties: {
    r'descending': PropertySchema(
      id: 0,
      name: r'descending',
      type: IsarType.bool,
    ),
    r'sortMethod': PropertySchema(
      id: 1,
      name: r'sortMethod',
      type: IsarType.byte,
      enumMap: _DeadlineSortersortMethodEnumValueMap,
    )
  },
  estimateSize: _deadlineSorterEstimateSize,
  serialize: _deadlineSorterSerialize,
  deserialize: _deadlineSorterDeserialize,
  deserializeProp: _deadlineSorterDeserializeProp,
);

int _deadlineSorterEstimateSize(
  DeadlineSorter object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  return bytesCount;
}

void _deadlineSorterSerialize(
  DeadlineSorter object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeBool(offsets[0], object.descending);
  writer.writeByte(offsets[1], object.sortMethod.index);
}

DeadlineSorter _deadlineSorterDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = DeadlineSorter(
    descending: reader.readBoolOrNull(offsets[0]) ?? false,
    sortMethod: _DeadlineSortersortMethodValueEnumMap[
            reader.readByteOrNull(offsets[1])] ??
        SortMethod.none,
  );
  return object;
}

P _deadlineSorterDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readBoolOrNull(offset) ?? false) as P;
    case 1:
      return (_DeadlineSortersortMethodValueEnumMap[
              reader.readByteOrNull(offset)] ??
          SortMethod.none) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

const _DeadlineSortersortMethodEnumValueMap = {
  'none': 0,
  'name': 1,
  'dueDate': 2,
  'weight': 3,
  'priority': 4,
  'duration': 5,
};
const _DeadlineSortersortMethodValueEnumMap = {
  0: SortMethod.none,
  1: SortMethod.name,
  2: SortMethod.dueDate,
  3: SortMethod.weight,
  4: SortMethod.priority,
  5: SortMethod.duration,
};

extension DeadlineSorterQueryFilter
    on QueryBuilder<DeadlineSorter, DeadlineSorter, QFilterCondition> {
  QueryBuilder<DeadlineSorter, DeadlineSorter, QAfterFilterCondition>
      descendingEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'descending',
        value: value,
      ));
    });
  }

  QueryBuilder<DeadlineSorter, DeadlineSorter, QAfterFilterCondition>
      sortMethodEqualTo(SortMethod value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'sortMethod',
        value: value,
      ));
    });
  }

  QueryBuilder<DeadlineSorter, DeadlineSorter, QAfterFilterCondition>
      sortMethodGreaterThan(
    SortMethod value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'sortMethod',
        value: value,
      ));
    });
  }

  QueryBuilder<DeadlineSorter, DeadlineSorter, QAfterFilterCondition>
      sortMethodLessThan(
    SortMethod value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'sortMethod',
        value: value,
      ));
    });
  }

  QueryBuilder<DeadlineSorter, DeadlineSorter, QAfterFilterCondition>
      sortMethodBetween(
    SortMethod lower,
    SortMethod upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'sortMethod',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension DeadlineSorterQueryObject
    on QueryBuilder<DeadlineSorter, DeadlineSorter, QFilterCondition> {}
