// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'todo_sorter.dart';

// **************************************************************************
// IsarEmbeddedGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

const ToDoSorterSchema = Schema(
  name: r'ToDoSorter',
  id: -1325271964906165540,
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
      enumMap: _ToDoSortersortMethodEnumValueMap,
    )
  },
  estimateSize: _toDoSorterEstimateSize,
  serialize: _toDoSorterSerialize,
  deserialize: _toDoSorterDeserialize,
  deserializeProp: _toDoSorterDeserializeProp,
);

int _toDoSorterEstimateSize(
  ToDoSorter object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  return bytesCount;
}

void _toDoSorterSerialize(
  ToDoSorter object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeBool(offsets[0], object.descending);
  writer.writeByte(offsets[1], object.sortMethod.index);
}

ToDoSorter _toDoSorterDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = ToDoSorter(
    descending: reader.readBoolOrNull(offsets[0]) ?? false,
    sortMethod:
        _ToDoSortersortMethodValueEnumMap[reader.readByteOrNull(offsets[1])] ??
            SortMethod.none,
  );
  return object;
}

P _toDoSorterDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readBoolOrNull(offset) ?? false) as P;
    case 1:
      return (_ToDoSortersortMethodValueEnumMap[
              reader.readByteOrNull(offset)] ??
          SortMethod.none) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

const _ToDoSortersortMethodEnumValueMap = {
  'none': 0,
  'name': 1,
  'dueDate': 2,
  'weight': 3,
  'priority': 4,
  'duration': 5,
};
const _ToDoSortersortMethodValueEnumMap = {
  0: SortMethod.none,
  1: SortMethod.name,
  2: SortMethod.dueDate,
  3: SortMethod.weight,
  4: SortMethod.priority,
  5: SortMethod.duration,
};

extension ToDoSorterQueryFilter
    on QueryBuilder<ToDoSorter, ToDoSorter, QFilterCondition> {
  QueryBuilder<ToDoSorter, ToDoSorter, QAfterFilterCondition> descendingEqualTo(
      bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'descending',
        value: value,
      ));
    });
  }

  QueryBuilder<ToDoSorter, ToDoSorter, QAfterFilterCondition> sortMethodEqualTo(
      SortMethod value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'sortMethod',
        value: value,
      ));
    });
  }

  QueryBuilder<ToDoSorter, ToDoSorter, QAfterFilterCondition>
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

  QueryBuilder<ToDoSorter, ToDoSorter, QAfterFilterCondition>
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

  QueryBuilder<ToDoSorter, ToDoSorter, QAfterFilterCondition> sortMethodBetween(
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

extension ToDoSorterQueryObject
    on QueryBuilder<ToDoSorter, ToDoSorter, QFilterCondition> {}
