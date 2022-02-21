// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// **************************************************************************
// MoorGenerator
// **************************************************************************

// ignore_for_file: unnecessary_brace_in_string_interps, unnecessary_this
class SymbolModel extends DataClass implements Insertable<SymbolModel> {
  final String name;
  final String code;
  final double pip;
  final double price;
  final bool selected;
  SymbolModel(
      {required this.name,
      required this.code,
      required this.pip,
      required this.price,
      required this.selected});
  factory SymbolModel.fromData(Map<String, dynamic> data, GeneratedDatabase db,
      {String? prefix}) {
    final effectivePrefix = prefix ?? '';
    return SymbolModel(
      name: const StringType()
          .mapFromDatabaseResponse(data['${effectivePrefix}name'])!,
      code: const StringType()
          .mapFromDatabaseResponse(data['${effectivePrefix}code'])!,
      pip: const RealType()
          .mapFromDatabaseResponse(data['${effectivePrefix}pip'])!,
      price: const RealType()
          .mapFromDatabaseResponse(data['${effectivePrefix}price'])!,
      selected: const BoolType()
          .mapFromDatabaseResponse(data['${effectivePrefix}selected'])!,
    );
  }
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['name'] = Variable<String>(name);
    map['code'] = Variable<String>(code);
    map['pip'] = Variable<double>(pip);
    map['price'] = Variable<double>(price);
    map['selected'] = Variable<bool>(selected);
    return map;
  }

  SymbolsCompanion toCompanion(bool nullToAbsent) {
    return SymbolsCompanion(
      name: Value(name),
      code: Value(code),
      pip: Value(pip),
      price: Value(price),
      selected: Value(selected),
    );
  }

  factory SymbolModel.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= moorRuntimeOptions.defaultSerializer;
    return SymbolModel(
      name: serializer.fromJson<String>(json['name']),
      code: serializer.fromJson<String>(json['code']),
      pip: serializer.fromJson<double>(json['pip']),
      price: serializer.fromJson<double>(json['price']),
      selected: serializer.fromJson<bool>(json['selected']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= moorRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'name': serializer.toJson<String>(name),
      'code': serializer.toJson<String>(code),
      'pip': serializer.toJson<double>(pip),
      'price': serializer.toJson<double>(price),
      'selected': serializer.toJson<bool>(selected),
    };
  }

  SymbolModel copyWith(
          {String? name,
          String? code,
          double? pip,
          double? price,
          bool? selected}) =>
      SymbolModel(
        name: name ?? this.name,
        code: code ?? this.code,
        pip: pip ?? this.pip,
        price: price ?? this.price,
        selected: selected ?? this.selected,
      );
  @override
  String toString() {
    return (StringBuffer('SymbolModel(')
          ..write('name: $name, ')
          ..write('code: $code, ')
          ..write('pip: $pip, ')
          ..write('price: $price, ')
          ..write('selected: $selected')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => $mrjf($mrjc(
      name.hashCode,
      $mrjc(code.hashCode,
          $mrjc(pip.hashCode, $mrjc(price.hashCode, selected.hashCode)))));
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SymbolModel &&
          other.name == this.name &&
          other.code == this.code &&
          other.pip == this.pip &&
          other.price == this.price &&
          other.selected == this.selected);
}

class SymbolsCompanion extends UpdateCompanion<SymbolModel> {
  final Value<String> name;
  final Value<String> code;
  final Value<double> pip;
  final Value<double> price;
  final Value<bool> selected;
  const SymbolsCompanion({
    this.name = const Value.absent(),
    this.code = const Value.absent(),
    this.pip = const Value.absent(),
    this.price = const Value.absent(),
    this.selected = const Value.absent(),
  });
  SymbolsCompanion.insert({
    required String name,
    required String code,
    required double pip,
    this.price = const Value.absent(),
    this.selected = const Value.absent(),
  })  : name = Value(name),
        code = Value(code),
        pip = Value(pip);
  static Insertable<SymbolModel> custom({
    Expression<String>? name,
    Expression<String>? code,
    Expression<double>? pip,
    Expression<double>? price,
    Expression<bool>? selected,
  }) {
    return RawValuesInsertable({
      if (name != null) 'name': name,
      if (code != null) 'code': code,
      if (pip != null) 'pip': pip,
      if (price != null) 'price': price,
      if (selected != null) 'selected': selected,
    });
  }

  SymbolsCompanion copyWith(
      {Value<String>? name,
      Value<String>? code,
      Value<double>? pip,
      Value<double>? price,
      Value<bool>? selected}) {
    return SymbolsCompanion(
      name: name ?? this.name,
      code: code ?? this.code,
      pip: pip ?? this.pip,
      price: price ?? this.price,
      selected: selected ?? this.selected,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (code.present) {
      map['code'] = Variable<String>(code.value);
    }
    if (pip.present) {
      map['pip'] = Variable<double>(pip.value);
    }
    if (price.present) {
      map['price'] = Variable<double>(price.value);
    }
    if (selected.present) {
      map['selected'] = Variable<bool>(selected.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SymbolsCompanion(')
          ..write('name: $name, ')
          ..write('code: $code, ')
          ..write('pip: $pip, ')
          ..write('price: $price, ')
          ..write('selected: $selected')
          ..write(')'))
        .toString();
  }
}

class $SymbolsTable extends Symbols with TableInfo<$SymbolsTable, SymbolModel> {
  final GeneratedDatabase _db;
  final String? _alias;
  $SymbolsTable(this._db, [this._alias]);
  final VerificationMeta _nameMeta = const VerificationMeta('name');
  late final GeneratedColumn<String?> name = GeneratedColumn<String?>(
      'name', aliasedName, false,
      typeName: 'TEXT', requiredDuringInsert: true);
  final VerificationMeta _codeMeta = const VerificationMeta('code');
  late final GeneratedColumn<String?> code = GeneratedColumn<String?>(
      'code', aliasedName, false,
      typeName: 'TEXT', requiredDuringInsert: true);
  final VerificationMeta _pipMeta = const VerificationMeta('pip');
  late final GeneratedColumn<double?> pip = GeneratedColumn<double?>(
      'pip', aliasedName, false,
      typeName: 'REAL', requiredDuringInsert: true);
  final VerificationMeta _priceMeta = const VerificationMeta('price');
  late final GeneratedColumn<double?> price = GeneratedColumn<double?>(
      'price', aliasedName, false,
      typeName: 'REAL',
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  final VerificationMeta _selectedMeta = const VerificationMeta('selected');
  late final GeneratedColumn<bool?> selected = GeneratedColumn<bool?>(
      'selected', aliasedName, false,
      typeName: 'INTEGER',
      requiredDuringInsert: false,
      defaultConstraints: 'CHECK (selected IN (0, 1))',
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns => [name, code, pip, price, selected];
  @override
  String get aliasedName => _alias ?? 'symbols';
  @override
  String get actualTableName => 'symbols';
  @override
  VerificationContext validateIntegrity(Insertable<SymbolModel> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('code')) {
      context.handle(
          _codeMeta, code.isAcceptableOrUnknown(data['code']!, _codeMeta));
    } else if (isInserting) {
      context.missing(_codeMeta);
    }
    if (data.containsKey('pip')) {
      context.handle(
          _pipMeta, pip.isAcceptableOrUnknown(data['pip']!, _pipMeta));
    } else if (isInserting) {
      context.missing(_pipMeta);
    }
    if (data.containsKey('price')) {
      context.handle(
          _priceMeta, price.isAcceptableOrUnknown(data['price']!, _priceMeta));
    }
    if (data.containsKey('selected')) {
      context.handle(_selectedMeta,
          selected.isAcceptableOrUnknown(data['selected']!, _selectedMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {code};
  @override
  SymbolModel map(Map<String, dynamic> data, {String? tablePrefix}) {
    return SymbolModel.fromData(data, _db,
        prefix: tablePrefix != null ? '$tablePrefix.' : null);
  }

  @override
  $SymbolsTable createAlias(String alias) {
    return $SymbolsTable(_db, alias);
  }
}

abstract class _$MyDatabase extends GeneratedDatabase {
  _$MyDatabase(QueryExecutor e) : super(SqlTypeSystem.defaultInstance, e);
  late final $SymbolsTable symbols = $SymbolsTable(this);
  late final SymbolsDao symbolsDao = SymbolsDao(this as MyDatabase);
  @override
  Iterable<TableInfo> get allTables => allSchemaEntities.whereType<TableInfo>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [symbols];
}
