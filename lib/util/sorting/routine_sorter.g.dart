// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'routine_sorter.dart';

// **************************************************************************
// IsarEmbeddedGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

const RoutineSorterSchema = Schema(
  name: r'RoutineSorter',
  id: 8585437832506813197,
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
      enumMap: _RoutineSortersortMethodEnumValueMap,
    )
  },
  estimateSize: _routineSorterEstimateSize,
  serialize: _routineSorterSerialize,
  deserialize: _routineSorterDeserialize,
  deserializeProp: _routineSorterDeserializeProp,
);

int _routineSorterEstimateSize(
  RoutineSorter object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  return bytesCount;
}

void _routineSorterSerialize(
  RoutineSorter object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeBool(offsets[0], object.descending);
  writer.writeByte(offsets[1], object.sortMethod.index);
}

RoutineSorter _routineSorterDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = RoutineSorter(
    descending: reader.readBoolOrNull(offsets[0]) ?? false,
    sortMethod: _RoutineSortersortMethodValueEnumMap[
            reader.readByteOrNull(offsets[1])] ??
        SortMethod.none,
  );
  return object;
}

P _routineSorterDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readBoolOrNull(offset) ?? false) as P;
    case 1:
      return (_RoutineSortersortMethodValueEnumMap[
              reader.readByteOrNull(offset)] ??
          SortMethod.none) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

const _RoutineSortersortMethodEnumValueMap = {
  'none': 0,
  'name': 1,
  'dueDate': 2,
  'weight': 3,
  'priority': 4,
  'duration': 5,
};
const _RoutineSortersortMethodValueEnumMap = {
  0: SortMethod.none,
  1: SortMethod.name,
  2: SortMethod.due_date,
  3: SortMethod.weight,
  4: SortMethod.priority,
  5: SortMethod.duration,
};

extension RoutineSorterQueryFilter
    on QueryBuilder<RoutineSorter, RoutineSorter, QFilterCondition> {
  QueryBuilder<RoutineSorter, RoutineSorter, QAfterFilterCondition>
      descendingEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'descending',
        value: value,
      ));
    });
  }

  QueryBuilder<RoutineSorter, RoutineSorter, QAfterFilterCondition>
      sortMethodEqualTo(SortMethod value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'sortMethod',
        value: value,
      ));
    });
  }

  QueryBuilder<RoutineSorter, RoutineSorter, QAfterFilterCondition>
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

  QueryBuilder<RoutineSorter, RoutineSorter, QAfterFilterCondition>
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

  QueryBuilder<RoutineSorter, RoutineSorter, QAfterFilterCondition>
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

extension RoutineSorterQueryObject
    on QueryBuilder<RoutineSorter, RoutineSorter, QFilterCondition> {}
