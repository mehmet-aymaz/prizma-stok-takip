// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'price_history.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetPriceHistoryCollection on Isar {
  IsarCollection<PriceHistory> get priceHistorys => this.collection();
}

const PriceHistorySchema = CollectionSchema(
  name: r'PriceHistory',
  id: 960819451289402683,
  properties: {
    r'changeDate': PropertySchema(
      id: 0,
      name: r'changeDate',
      type: IsarType.dateTime,
    ),
    r'changedBy': PropertySchema(
      id: 1,
      name: r'changedBy',
      type: IsarType.string,
    ),
    r'newPurchasePrice': PropertySchema(
      id: 2,
      name: r'newPurchasePrice',
      type: IsarType.double,
    ),
    r'newSalesPrice': PropertySchema(
      id: 3,
      name: r'newSalesPrice',
      type: IsarType.double,
    ),
    r'oldPurchasePrice': PropertySchema(
      id: 4,
      name: r'oldPurchasePrice',
      type: IsarType.double,
    ),
    r'oldSalesPrice': PropertySchema(
      id: 5,
      name: r'oldSalesPrice',
      type: IsarType.double,
    ),
    r'productUuid': PropertySchema(
      id: 6,
      name: r'productUuid',
      type: IsarType.string,
    ),
    r'syncStatus': PropertySchema(
      id: 7,
      name: r'syncStatus',
      type: IsarType.byte,
      enumMap: _PriceHistorysyncStatusEnumValueMap,
    ),
    r'uuid': PropertySchema(
      id: 8,
      name: r'uuid',
      type: IsarType.string,
    )
  },
  estimateSize: _priceHistoryEstimateSize,
  serialize: _priceHistorySerialize,
  deserialize: _priceHistoryDeserialize,
  deserializeProp: _priceHistoryDeserializeProp,
  idName: r'id',
  indexes: {
    r'uuid': IndexSchema(
      id: 2134397340427724972,
      name: r'uuid',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'uuid',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _priceHistoryGetId,
  getLinks: _priceHistoryGetLinks,
  attach: _priceHistoryAttach,
  version: '3.1.0+1',
);

int _priceHistoryEstimateSize(
  PriceHistory object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.changedBy.length * 3;
  bytesCount += 3 + object.productUuid.length * 3;
  bytesCount += 3 + object.uuid.length * 3;
  return bytesCount;
}

void _priceHistorySerialize(
  PriceHistory object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDateTime(offsets[0], object.changeDate);
  writer.writeString(offsets[1], object.changedBy);
  writer.writeDouble(offsets[2], object.newPurchasePrice);
  writer.writeDouble(offsets[3], object.newSalesPrice);
  writer.writeDouble(offsets[4], object.oldPurchasePrice);
  writer.writeDouble(offsets[5], object.oldSalesPrice);
  writer.writeString(offsets[6], object.productUuid);
  writer.writeByte(offsets[7], object.syncStatus.index);
  writer.writeString(offsets[8], object.uuid);
}

PriceHistory _priceHistoryDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = PriceHistory();
  object.changeDate = reader.readDateTime(offsets[0]);
  object.changedBy = reader.readString(offsets[1]);
  object.id = id;
  object.newPurchasePrice = reader.readDouble(offsets[2]);
  object.newSalesPrice = reader.readDouble(offsets[3]);
  object.oldPurchasePrice = reader.readDouble(offsets[4]);
  object.oldSalesPrice = reader.readDouble(offsets[5]);
  object.productUuid = reader.readString(offsets[6]);
  object.syncStatus =
      _PriceHistorysyncStatusValueEnumMap[reader.readByteOrNull(offsets[7])] ??
          SyncStatus.pending;
  object.uuid = reader.readString(offsets[8]);
  return object;
}

P _priceHistoryDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDateTime(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readDouble(offset)) as P;
    case 3:
      return (reader.readDouble(offset)) as P;
    case 4:
      return (reader.readDouble(offset)) as P;
    case 5:
      return (reader.readDouble(offset)) as P;
    case 6:
      return (reader.readString(offset)) as P;
    case 7:
      return (_PriceHistorysyncStatusValueEnumMap[
              reader.readByteOrNull(offset)] ??
          SyncStatus.pending) as P;
    case 8:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

const _PriceHistorysyncStatusEnumValueMap = {
  'pending': 0,
  'synced': 1,
};
const _PriceHistorysyncStatusValueEnumMap = {
  0: SyncStatus.pending,
  1: SyncStatus.synced,
};

Id _priceHistoryGetId(PriceHistory object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _priceHistoryGetLinks(PriceHistory object) {
  return [];
}

void _priceHistoryAttach(
    IsarCollection<dynamic> col, Id id, PriceHistory object) {
  object.id = id;
}

extension PriceHistoryByIndex on IsarCollection<PriceHistory> {
  Future<PriceHistory?> getByUuid(String uuid) {
    return getByIndex(r'uuid', [uuid]);
  }

  PriceHistory? getByUuidSync(String uuid) {
    return getByIndexSync(r'uuid', [uuid]);
  }

  Future<bool> deleteByUuid(String uuid) {
    return deleteByIndex(r'uuid', [uuid]);
  }

  bool deleteByUuidSync(String uuid) {
    return deleteByIndexSync(r'uuid', [uuid]);
  }

  Future<List<PriceHistory?>> getAllByUuid(List<String> uuidValues) {
    final values = uuidValues.map((e) => [e]).toList();
    return getAllByIndex(r'uuid', values);
  }

  List<PriceHistory?> getAllByUuidSync(List<String> uuidValues) {
    final values = uuidValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'uuid', values);
  }

  Future<int> deleteAllByUuid(List<String> uuidValues) {
    final values = uuidValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'uuid', values);
  }

  int deleteAllByUuidSync(List<String> uuidValues) {
    final values = uuidValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'uuid', values);
  }

  Future<Id> putByUuid(PriceHistory object) {
    return putByIndex(r'uuid', object);
  }

  Id putByUuidSync(PriceHistory object, {bool saveLinks = true}) {
    return putByIndexSync(r'uuid', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByUuid(List<PriceHistory> objects) {
    return putAllByIndex(r'uuid', objects);
  }

  List<Id> putAllByUuidSync(List<PriceHistory> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'uuid', objects, saveLinks: saveLinks);
  }
}

extension PriceHistoryQueryWhereSort
    on QueryBuilder<PriceHistory, PriceHistory, QWhere> {
  QueryBuilder<PriceHistory, PriceHistory, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension PriceHistoryQueryWhere
    on QueryBuilder<PriceHistory, PriceHistory, QWhereClause> {
  QueryBuilder<PriceHistory, PriceHistory, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<PriceHistory, PriceHistory, QAfterWhereClause> idNotEqualTo(
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

  QueryBuilder<PriceHistory, PriceHistory, QAfterWhereClause> idGreaterThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<PriceHistory, PriceHistory, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<PriceHistory, PriceHistory, QAfterWhereClause> idBetween(
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

  QueryBuilder<PriceHistory, PriceHistory, QAfterWhereClause> uuidEqualTo(
      String uuid) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'uuid',
        value: [uuid],
      ));
    });
  }

  QueryBuilder<PriceHistory, PriceHistory, QAfterWhereClause> uuidNotEqualTo(
      String uuid) {
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
}

extension PriceHistoryQueryFilter
    on QueryBuilder<PriceHistory, PriceHistory, QFilterCondition> {
  QueryBuilder<PriceHistory, PriceHistory, QAfterFilterCondition>
      changeDateEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'changeDate',
        value: value,
      ));
    });
  }

  QueryBuilder<PriceHistory, PriceHistory, QAfterFilterCondition>
      changeDateGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'changeDate',
        value: value,
      ));
    });
  }

  QueryBuilder<PriceHistory, PriceHistory, QAfterFilterCondition>
      changeDateLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'changeDate',
        value: value,
      ));
    });
  }

  QueryBuilder<PriceHistory, PriceHistory, QAfterFilterCondition>
      changeDateBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'changeDate',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<PriceHistory, PriceHistory, QAfterFilterCondition>
      changedByEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'changedBy',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PriceHistory, PriceHistory, QAfterFilterCondition>
      changedByGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'changedBy',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PriceHistory, PriceHistory, QAfterFilterCondition>
      changedByLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'changedBy',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PriceHistory, PriceHistory, QAfterFilterCondition>
      changedByBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'changedBy',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PriceHistory, PriceHistory, QAfterFilterCondition>
      changedByStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'changedBy',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PriceHistory, PriceHistory, QAfterFilterCondition>
      changedByEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'changedBy',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PriceHistory, PriceHistory, QAfterFilterCondition>
      changedByContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'changedBy',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PriceHistory, PriceHistory, QAfterFilterCondition>
      changedByMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'changedBy',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PriceHistory, PriceHistory, QAfterFilterCondition>
      changedByIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'changedBy',
        value: '',
      ));
    });
  }

  QueryBuilder<PriceHistory, PriceHistory, QAfterFilterCondition>
      changedByIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'changedBy',
        value: '',
      ));
    });
  }

  QueryBuilder<PriceHistory, PriceHistory, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<PriceHistory, PriceHistory, QAfterFilterCondition> idGreaterThan(
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

  QueryBuilder<PriceHistory, PriceHistory, QAfterFilterCondition> idLessThan(
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

  QueryBuilder<PriceHistory, PriceHistory, QAfterFilterCondition> idBetween(
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

  QueryBuilder<PriceHistory, PriceHistory, QAfterFilterCondition>
      newPurchasePriceEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'newPurchasePrice',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PriceHistory, PriceHistory, QAfterFilterCondition>
      newPurchasePriceGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'newPurchasePrice',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PriceHistory, PriceHistory, QAfterFilterCondition>
      newPurchasePriceLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'newPurchasePrice',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PriceHistory, PriceHistory, QAfterFilterCondition>
      newPurchasePriceBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'newPurchasePrice',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PriceHistory, PriceHistory, QAfterFilterCondition>
      newSalesPriceEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'newSalesPrice',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PriceHistory, PriceHistory, QAfterFilterCondition>
      newSalesPriceGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'newSalesPrice',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PriceHistory, PriceHistory, QAfterFilterCondition>
      newSalesPriceLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'newSalesPrice',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PriceHistory, PriceHistory, QAfterFilterCondition>
      newSalesPriceBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'newSalesPrice',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PriceHistory, PriceHistory, QAfterFilterCondition>
      oldPurchasePriceEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'oldPurchasePrice',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PriceHistory, PriceHistory, QAfterFilterCondition>
      oldPurchasePriceGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'oldPurchasePrice',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PriceHistory, PriceHistory, QAfterFilterCondition>
      oldPurchasePriceLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'oldPurchasePrice',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PriceHistory, PriceHistory, QAfterFilterCondition>
      oldPurchasePriceBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'oldPurchasePrice',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PriceHistory, PriceHistory, QAfterFilterCondition>
      oldSalesPriceEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'oldSalesPrice',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PriceHistory, PriceHistory, QAfterFilterCondition>
      oldSalesPriceGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'oldSalesPrice',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PriceHistory, PriceHistory, QAfterFilterCondition>
      oldSalesPriceLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'oldSalesPrice',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PriceHistory, PriceHistory, QAfterFilterCondition>
      oldSalesPriceBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'oldSalesPrice',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<PriceHistory, PriceHistory, QAfterFilterCondition>
      productUuidEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'productUuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PriceHistory, PriceHistory, QAfterFilterCondition>
      productUuidGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'productUuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PriceHistory, PriceHistory, QAfterFilterCondition>
      productUuidLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'productUuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PriceHistory, PriceHistory, QAfterFilterCondition>
      productUuidBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'productUuid',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PriceHistory, PriceHistory, QAfterFilterCondition>
      productUuidStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'productUuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PriceHistory, PriceHistory, QAfterFilterCondition>
      productUuidEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'productUuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PriceHistory, PriceHistory, QAfterFilterCondition>
      productUuidContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'productUuid',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PriceHistory, PriceHistory, QAfterFilterCondition>
      productUuidMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'productUuid',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<PriceHistory, PriceHistory, QAfterFilterCondition>
      productUuidIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'productUuid',
        value: '',
      ));
    });
  }

  QueryBuilder<PriceHistory, PriceHistory, QAfterFilterCondition>
      productUuidIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'productUuid',
        value: '',
      ));
    });
  }

  QueryBuilder<PriceHistory, PriceHistory, QAfterFilterCondition>
      syncStatusEqualTo(SyncStatus value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'syncStatus',
        value: value,
      ));
    });
  }

  QueryBuilder<PriceHistory, PriceHistory, QAfterFilterCondition>
      syncStatusGreaterThan(
    SyncStatus value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'syncStatus',
        value: value,
      ));
    });
  }

  QueryBuilder<PriceHistory, PriceHistory, QAfterFilterCondition>
      syncStatusLessThan(
    SyncStatus value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'syncStatus',
        value: value,
      ));
    });
  }

  QueryBuilder<PriceHistory, PriceHistory, QAfterFilterCondition>
      syncStatusBetween(
    SyncStatus lower,
    SyncStatus upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'syncStatus',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<PriceHistory, PriceHistory, QAfterFilterCondition> uuidEqualTo(
    String value, {
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

  QueryBuilder<PriceHistory, PriceHistory, QAfterFilterCondition>
      uuidGreaterThan(
    String value, {
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

  QueryBuilder<PriceHistory, PriceHistory, QAfterFilterCondition> uuidLessThan(
    String value, {
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

  QueryBuilder<PriceHistory, PriceHistory, QAfterFilterCondition> uuidBetween(
    String lower,
    String upper, {
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

  QueryBuilder<PriceHistory, PriceHistory, QAfterFilterCondition>
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

  QueryBuilder<PriceHistory, PriceHistory, QAfterFilterCondition> uuidEndsWith(
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

  QueryBuilder<PriceHistory, PriceHistory, QAfterFilterCondition> uuidContains(
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

  QueryBuilder<PriceHistory, PriceHistory, QAfterFilterCondition> uuidMatches(
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

  QueryBuilder<PriceHistory, PriceHistory, QAfterFilterCondition>
      uuidIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'uuid',
        value: '',
      ));
    });
  }

  QueryBuilder<PriceHistory, PriceHistory, QAfterFilterCondition>
      uuidIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'uuid',
        value: '',
      ));
    });
  }
}

extension PriceHistoryQueryObject
    on QueryBuilder<PriceHistory, PriceHistory, QFilterCondition> {}

extension PriceHistoryQueryLinks
    on QueryBuilder<PriceHistory, PriceHistory, QFilterCondition> {}

extension PriceHistoryQuerySortBy
    on QueryBuilder<PriceHistory, PriceHistory, QSortBy> {
  QueryBuilder<PriceHistory, PriceHistory, QAfterSortBy> sortByChangeDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'changeDate', Sort.asc);
    });
  }

  QueryBuilder<PriceHistory, PriceHistory, QAfterSortBy>
      sortByChangeDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'changeDate', Sort.desc);
    });
  }

  QueryBuilder<PriceHistory, PriceHistory, QAfterSortBy> sortByChangedBy() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'changedBy', Sort.asc);
    });
  }

  QueryBuilder<PriceHistory, PriceHistory, QAfterSortBy> sortByChangedByDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'changedBy', Sort.desc);
    });
  }

  QueryBuilder<PriceHistory, PriceHistory, QAfterSortBy>
      sortByNewPurchasePrice() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'newPurchasePrice', Sort.asc);
    });
  }

  QueryBuilder<PriceHistory, PriceHistory, QAfterSortBy>
      sortByNewPurchasePriceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'newPurchasePrice', Sort.desc);
    });
  }

  QueryBuilder<PriceHistory, PriceHistory, QAfterSortBy> sortByNewSalesPrice() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'newSalesPrice', Sort.asc);
    });
  }

  QueryBuilder<PriceHistory, PriceHistory, QAfterSortBy>
      sortByNewSalesPriceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'newSalesPrice', Sort.desc);
    });
  }

  QueryBuilder<PriceHistory, PriceHistory, QAfterSortBy>
      sortByOldPurchasePrice() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'oldPurchasePrice', Sort.asc);
    });
  }

  QueryBuilder<PriceHistory, PriceHistory, QAfterSortBy>
      sortByOldPurchasePriceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'oldPurchasePrice', Sort.desc);
    });
  }

  QueryBuilder<PriceHistory, PriceHistory, QAfterSortBy> sortByOldSalesPrice() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'oldSalesPrice', Sort.asc);
    });
  }

  QueryBuilder<PriceHistory, PriceHistory, QAfterSortBy>
      sortByOldSalesPriceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'oldSalesPrice', Sort.desc);
    });
  }

  QueryBuilder<PriceHistory, PriceHistory, QAfterSortBy> sortByProductUuid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'productUuid', Sort.asc);
    });
  }

  QueryBuilder<PriceHistory, PriceHistory, QAfterSortBy>
      sortByProductUuidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'productUuid', Sort.desc);
    });
  }

  QueryBuilder<PriceHistory, PriceHistory, QAfterSortBy> sortBySyncStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncStatus', Sort.asc);
    });
  }

  QueryBuilder<PriceHistory, PriceHistory, QAfterSortBy>
      sortBySyncStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncStatus', Sort.desc);
    });
  }

  QueryBuilder<PriceHistory, PriceHistory, QAfterSortBy> sortByUuid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uuid', Sort.asc);
    });
  }

  QueryBuilder<PriceHistory, PriceHistory, QAfterSortBy> sortByUuidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uuid', Sort.desc);
    });
  }
}

extension PriceHistoryQuerySortThenBy
    on QueryBuilder<PriceHistory, PriceHistory, QSortThenBy> {
  QueryBuilder<PriceHistory, PriceHistory, QAfterSortBy> thenByChangeDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'changeDate', Sort.asc);
    });
  }

  QueryBuilder<PriceHistory, PriceHistory, QAfterSortBy>
      thenByChangeDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'changeDate', Sort.desc);
    });
  }

  QueryBuilder<PriceHistory, PriceHistory, QAfterSortBy> thenByChangedBy() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'changedBy', Sort.asc);
    });
  }

  QueryBuilder<PriceHistory, PriceHistory, QAfterSortBy> thenByChangedByDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'changedBy', Sort.desc);
    });
  }

  QueryBuilder<PriceHistory, PriceHistory, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<PriceHistory, PriceHistory, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<PriceHistory, PriceHistory, QAfterSortBy>
      thenByNewPurchasePrice() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'newPurchasePrice', Sort.asc);
    });
  }

  QueryBuilder<PriceHistory, PriceHistory, QAfterSortBy>
      thenByNewPurchasePriceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'newPurchasePrice', Sort.desc);
    });
  }

  QueryBuilder<PriceHistory, PriceHistory, QAfterSortBy> thenByNewSalesPrice() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'newSalesPrice', Sort.asc);
    });
  }

  QueryBuilder<PriceHistory, PriceHistory, QAfterSortBy>
      thenByNewSalesPriceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'newSalesPrice', Sort.desc);
    });
  }

  QueryBuilder<PriceHistory, PriceHistory, QAfterSortBy>
      thenByOldPurchasePrice() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'oldPurchasePrice', Sort.asc);
    });
  }

  QueryBuilder<PriceHistory, PriceHistory, QAfterSortBy>
      thenByOldPurchasePriceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'oldPurchasePrice', Sort.desc);
    });
  }

  QueryBuilder<PriceHistory, PriceHistory, QAfterSortBy> thenByOldSalesPrice() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'oldSalesPrice', Sort.asc);
    });
  }

  QueryBuilder<PriceHistory, PriceHistory, QAfterSortBy>
      thenByOldSalesPriceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'oldSalesPrice', Sort.desc);
    });
  }

  QueryBuilder<PriceHistory, PriceHistory, QAfterSortBy> thenByProductUuid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'productUuid', Sort.asc);
    });
  }

  QueryBuilder<PriceHistory, PriceHistory, QAfterSortBy>
      thenByProductUuidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'productUuid', Sort.desc);
    });
  }

  QueryBuilder<PriceHistory, PriceHistory, QAfterSortBy> thenBySyncStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncStatus', Sort.asc);
    });
  }

  QueryBuilder<PriceHistory, PriceHistory, QAfterSortBy>
      thenBySyncStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'syncStatus', Sort.desc);
    });
  }

  QueryBuilder<PriceHistory, PriceHistory, QAfterSortBy> thenByUuid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uuid', Sort.asc);
    });
  }

  QueryBuilder<PriceHistory, PriceHistory, QAfterSortBy> thenByUuidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'uuid', Sort.desc);
    });
  }
}

extension PriceHistoryQueryWhereDistinct
    on QueryBuilder<PriceHistory, PriceHistory, QDistinct> {
  QueryBuilder<PriceHistory, PriceHistory, QDistinct> distinctByChangeDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'changeDate');
    });
  }

  QueryBuilder<PriceHistory, PriceHistory, QDistinct> distinctByChangedBy(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'changedBy', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PriceHistory, PriceHistory, QDistinct>
      distinctByNewPurchasePrice() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'newPurchasePrice');
    });
  }

  QueryBuilder<PriceHistory, PriceHistory, QDistinct>
      distinctByNewSalesPrice() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'newSalesPrice');
    });
  }

  QueryBuilder<PriceHistory, PriceHistory, QDistinct>
      distinctByOldPurchasePrice() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'oldPurchasePrice');
    });
  }

  QueryBuilder<PriceHistory, PriceHistory, QDistinct>
      distinctByOldSalesPrice() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'oldSalesPrice');
    });
  }

  QueryBuilder<PriceHistory, PriceHistory, QDistinct> distinctByProductUuid(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'productUuid', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PriceHistory, PriceHistory, QDistinct> distinctBySyncStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'syncStatus');
    });
  }

  QueryBuilder<PriceHistory, PriceHistory, QDistinct> distinctByUuid(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'uuid', caseSensitive: caseSensitive);
    });
  }
}

extension PriceHistoryQueryProperty
    on QueryBuilder<PriceHistory, PriceHistory, QQueryProperty> {
  QueryBuilder<PriceHistory, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<PriceHistory, DateTime, QQueryOperations> changeDateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'changeDate');
    });
  }

  QueryBuilder<PriceHistory, String, QQueryOperations> changedByProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'changedBy');
    });
  }

  QueryBuilder<PriceHistory, double, QQueryOperations>
      newPurchasePriceProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'newPurchasePrice');
    });
  }

  QueryBuilder<PriceHistory, double, QQueryOperations> newSalesPriceProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'newSalesPrice');
    });
  }

  QueryBuilder<PriceHistory, double, QQueryOperations>
      oldPurchasePriceProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'oldPurchasePrice');
    });
  }

  QueryBuilder<PriceHistory, double, QQueryOperations> oldSalesPriceProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'oldSalesPrice');
    });
  }

  QueryBuilder<PriceHistory, String, QQueryOperations> productUuidProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'productUuid');
    });
  }

  QueryBuilder<PriceHistory, SyncStatus, QQueryOperations>
      syncStatusProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'syncStatus');
    });
  }

  QueryBuilder<PriceHistory, String, QQueryOperations> uuidProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'uuid');
    });
  }
}
