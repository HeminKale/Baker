// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $AppSettingsTable extends AppSettings
    with TableInfo<$AppSettingsTable, AppSetting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppSetting> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  AppSetting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppSetting(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $AppSettingsTable createAlias(String alias) {
    return $AppSettingsTable(attachedDatabase, alias);
  }
}

class AppSetting extends DataClass implements Insertable<AppSetting> {
  final String key;
  final String value;
  const AppSetting({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  AppSettingsCompanion toCompanion(bool nullToAbsent) {
    return AppSettingsCompanion(key: Value(key), value: Value(value));
  }

  factory AppSetting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppSetting(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  AppSetting copyWith({String? key, String? value}) =>
      AppSetting(key: key ?? this.key, value: value ?? this.value);
  AppSetting copyWithCompanion(AppSettingsCompanion data) {
    return AppSetting(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppSetting(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppSetting &&
          other.key == this.key &&
          other.value == this.value);
}

class AppSettingsCompanion extends UpdateCompanion<AppSetting> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const AppSettingsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AppSettingsCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<AppSetting> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AppSettingsCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return AppSettingsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CachedCategoriesTable extends CachedCategories
    with TableInfo<$CachedCategoriesTable, CachedCategory> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedCategoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _imageUrlMeta = const VerificationMeta(
    'imageUrl',
  );
  @override
  late final GeneratedColumn<String> imageUrl = GeneratedColumn<String>(
    'image_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _subCategoryCountMeta = const VerificationMeta(
    'subCategoryCount',
  );
  @override
  late final GeneratedColumn<int> subCategoryCount = GeneratedColumn<int>(
    'sub_category_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    imageUrl,
    sortOrder,
    subCategoryCount,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_categories';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedCategory> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('image_url')) {
      context.handle(
        _imageUrlMeta,
        imageUrl.isAcceptableOrUnknown(data['image_url']!, _imageUrlMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    } else if (isInserting) {
      context.missing(_sortOrderMeta);
    }
    if (data.containsKey('sub_category_count')) {
      context.handle(
        _subCategoryCountMeta,
        subCategoryCount.isAcceptableOrUnknown(
          data['sub_category_count']!,
          _subCategoryCountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_subCategoryCountMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CachedCategory map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedCategory(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      imageUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_url'],
      ),
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      subCategoryCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sub_category_count'],
      )!,
    );
  }

  @override
  $CachedCategoriesTable createAlias(String alias) {
    return $CachedCategoriesTable(attachedDatabase, alias);
  }
}

class CachedCategory extends DataClass implements Insertable<CachedCategory> {
  final String id;
  final String name;
  final String? imageUrl;
  final int sortOrder;
  final int subCategoryCount;
  const CachedCategory({
    required this.id,
    required this.name,
    this.imageUrl,
    required this.sortOrder,
    required this.subCategoryCount,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || imageUrl != null) {
      map['image_url'] = Variable<String>(imageUrl);
    }
    map['sort_order'] = Variable<int>(sortOrder);
    map['sub_category_count'] = Variable<int>(subCategoryCount);
    return map;
  }

  CachedCategoriesCompanion toCompanion(bool nullToAbsent) {
    return CachedCategoriesCompanion(
      id: Value(id),
      name: Value(name),
      imageUrl: imageUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(imageUrl),
      sortOrder: Value(sortOrder),
      subCategoryCount: Value(subCategoryCount),
    );
  }

  factory CachedCategory.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedCategory(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      imageUrl: serializer.fromJson<String?>(json['imageUrl']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      subCategoryCount: serializer.fromJson<int>(json['subCategoryCount']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'imageUrl': serializer.toJson<String?>(imageUrl),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'subCategoryCount': serializer.toJson<int>(subCategoryCount),
    };
  }

  CachedCategory copyWith({
    String? id,
    String? name,
    Value<String?> imageUrl = const Value.absent(),
    int? sortOrder,
    int? subCategoryCount,
  }) => CachedCategory(
    id: id ?? this.id,
    name: name ?? this.name,
    imageUrl: imageUrl.present ? imageUrl.value : this.imageUrl,
    sortOrder: sortOrder ?? this.sortOrder,
    subCategoryCount: subCategoryCount ?? this.subCategoryCount,
  );
  CachedCategory copyWithCompanion(CachedCategoriesCompanion data) {
    return CachedCategory(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      imageUrl: data.imageUrl.present ? data.imageUrl.value : this.imageUrl,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      subCategoryCount: data.subCategoryCount.present
          ? data.subCategoryCount.value
          : this.subCategoryCount,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedCategory(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('imageUrl: $imageUrl, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('subCategoryCount: $subCategoryCount')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, imageUrl, sortOrder, subCategoryCount);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedCategory &&
          other.id == this.id &&
          other.name == this.name &&
          other.imageUrl == this.imageUrl &&
          other.sortOrder == this.sortOrder &&
          other.subCategoryCount == this.subCategoryCount);
}

class CachedCategoriesCompanion extends UpdateCompanion<CachedCategory> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> imageUrl;
  final Value<int> sortOrder;
  final Value<int> subCategoryCount;
  final Value<int> rowid;
  const CachedCategoriesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.imageUrl = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.subCategoryCount = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedCategoriesCompanion.insert({
    required String id,
    required String name,
    this.imageUrl = const Value.absent(),
    required int sortOrder,
    required int subCategoryCount,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       sortOrder = Value(sortOrder),
       subCategoryCount = Value(subCategoryCount);
  static Insertable<CachedCategory> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? imageUrl,
    Expression<int>? sortOrder,
    Expression<int>? subCategoryCount,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (imageUrl != null) 'image_url': imageUrl,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (subCategoryCount != null) 'sub_category_count': subCategoryCount,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedCategoriesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String?>? imageUrl,
    Value<int>? sortOrder,
    Value<int>? subCategoryCount,
    Value<int>? rowid,
  }) {
    return CachedCategoriesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      sortOrder: sortOrder ?? this.sortOrder,
      subCategoryCount: subCategoryCount ?? this.subCategoryCount,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (imageUrl.present) {
      map['image_url'] = Variable<String>(imageUrl.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (subCategoryCount.present) {
      map['sub_category_count'] = Variable<int>(subCategoryCount.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedCategoriesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('imageUrl: $imageUrl, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('subCategoryCount: $subCategoryCount, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CachedSubCategoriesTable extends CachedSubCategories
    with TableInfo<$CachedSubCategoriesTable, CachedSubCategory> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedSubCategoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
    'category_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _imageUrlMeta = const VerificationMeta(
    'imageUrl',
  );
  @override
  late final GeneratedColumn<String> imageUrl = GeneratedColumn<String>(
    'image_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    categoryId,
    name,
    imageUrl,
    sortOrder,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_sub_categories';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedSubCategory> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('image_url')) {
      context.handle(
        _imageUrlMeta,
        imageUrl.isAcceptableOrUnknown(data['image_url']!, _imageUrlMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    } else if (isInserting) {
      context.missing(_sortOrderMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CachedSubCategory map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedSubCategory(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      imageUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_url'],
      ),
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
    );
  }

  @override
  $CachedSubCategoriesTable createAlias(String alias) {
    return $CachedSubCategoriesTable(attachedDatabase, alias);
  }
}

class CachedSubCategory extends DataClass
    implements Insertable<CachedSubCategory> {
  final String id;
  final String categoryId;
  final String name;
  final String? imageUrl;
  final int sortOrder;
  const CachedSubCategory({
    required this.id,
    required this.categoryId,
    required this.name,
    this.imageUrl,
    required this.sortOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['category_id'] = Variable<String>(categoryId);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || imageUrl != null) {
      map['image_url'] = Variable<String>(imageUrl);
    }
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  CachedSubCategoriesCompanion toCompanion(bool nullToAbsent) {
    return CachedSubCategoriesCompanion(
      id: Value(id),
      categoryId: Value(categoryId),
      name: Value(name),
      imageUrl: imageUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(imageUrl),
      sortOrder: Value(sortOrder),
    );
  }

  factory CachedSubCategory.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedSubCategory(
      id: serializer.fromJson<String>(json['id']),
      categoryId: serializer.fromJson<String>(json['categoryId']),
      name: serializer.fromJson<String>(json['name']),
      imageUrl: serializer.fromJson<String?>(json['imageUrl']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'categoryId': serializer.toJson<String>(categoryId),
      'name': serializer.toJson<String>(name),
      'imageUrl': serializer.toJson<String?>(imageUrl),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  CachedSubCategory copyWith({
    String? id,
    String? categoryId,
    String? name,
    Value<String?> imageUrl = const Value.absent(),
    int? sortOrder,
  }) => CachedSubCategory(
    id: id ?? this.id,
    categoryId: categoryId ?? this.categoryId,
    name: name ?? this.name,
    imageUrl: imageUrl.present ? imageUrl.value : this.imageUrl,
    sortOrder: sortOrder ?? this.sortOrder,
  );
  CachedSubCategory copyWithCompanion(CachedSubCategoriesCompanion data) {
    return CachedSubCategory(
      id: data.id.present ? data.id.value : this.id,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      name: data.name.present ? data.name.value : this.name,
      imageUrl: data.imageUrl.present ? data.imageUrl.value : this.imageUrl,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedSubCategory(')
          ..write('id: $id, ')
          ..write('categoryId: $categoryId, ')
          ..write('name: $name, ')
          ..write('imageUrl: $imageUrl, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, categoryId, name, imageUrl, sortOrder);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedSubCategory &&
          other.id == this.id &&
          other.categoryId == this.categoryId &&
          other.name == this.name &&
          other.imageUrl == this.imageUrl &&
          other.sortOrder == this.sortOrder);
}

class CachedSubCategoriesCompanion extends UpdateCompanion<CachedSubCategory> {
  final Value<String> id;
  final Value<String> categoryId;
  final Value<String> name;
  final Value<String?> imageUrl;
  final Value<int> sortOrder;
  final Value<int> rowid;
  const CachedSubCategoriesCompanion({
    this.id = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.name = const Value.absent(),
    this.imageUrl = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedSubCategoriesCompanion.insert({
    required String id,
    required String categoryId,
    required String name,
    this.imageUrl = const Value.absent(),
    required int sortOrder,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       categoryId = Value(categoryId),
       name = Value(name),
       sortOrder = Value(sortOrder);
  static Insertable<CachedSubCategory> custom({
    Expression<String>? id,
    Expression<String>? categoryId,
    Expression<String>? name,
    Expression<String>? imageUrl,
    Expression<int>? sortOrder,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (categoryId != null) 'category_id': categoryId,
      if (name != null) 'name': name,
      if (imageUrl != null) 'image_url': imageUrl,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedSubCategoriesCompanion copyWith({
    Value<String>? id,
    Value<String>? categoryId,
    Value<String>? name,
    Value<String?>? imageUrl,
    Value<int>? sortOrder,
    Value<int>? rowid,
  }) {
    return CachedSubCategoriesCompanion(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      sortOrder: sortOrder ?? this.sortOrder,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (imageUrl.present) {
      map['image_url'] = Variable<String>(imageUrl.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedSubCategoriesCompanion(')
          ..write('id: $id, ')
          ..write('categoryId: $categoryId, ')
          ..write('name: $name, ')
          ..write('imageUrl: $imageUrl, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CachedProductsTable extends CachedProducts
    with TableInfo<$CachedProductsTable, CachedProduct> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedProductsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _subCategoryIdMeta = const VerificationMeta(
    'subCategoryId',
  );
  @override
  late final GeneratedColumn<String> subCategoryId = GeneratedColumn<String>(
    'sub_category_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
    'category_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isTrendingMeta = const VerificationMeta(
    'isTrending',
  );
  @override
  late final GeneratedColumn<bool> isTrending = GeneratedColumn<bool>(
    'is_trending',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_trending" IN (0, 1))',
    ),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _variantIdMeta = const VerificationMeta(
    'variantId',
  );
  @override
  late final GeneratedColumn<String> variantId = GeneratedColumn<String>(
    'variant_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _variantNameMeta = const VerificationMeta(
    'variantName',
  );
  @override
  late final GeneratedColumn<String> variantName = GeneratedColumn<String>(
    'variant_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _originalPriceMeta = const VerificationMeta(
    'originalPrice',
  );
  @override
  late final GeneratedColumn<int> originalPrice = GeneratedColumn<int>(
    'original_price',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _currentPriceMeta = const VerificationMeta(
    'currentPrice',
  );
  @override
  late final GeneratedColumn<int> currentPrice = GeneratedColumn<int>(
    'current_price',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _stockQtyMeta = const VerificationMeta(
    'stockQty',
  );
  @override
  late final GeneratedColumn<int> stockQty = GeneratedColumn<int>(
    'stock_qty',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _imageUrlMeta = const VerificationMeta(
    'imageUrl',
  );
  @override
  late final GeneratedColumn<String> imageUrl = GeneratedColumn<String>(
    'image_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    subCategoryId,
    categoryId,
    name,
    description,
    isTrending,
    createdAt,
    sortOrder,
    variantId,
    variantName,
    originalPrice,
    currentPrice,
    stockQty,
    imageUrl,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_products';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedProduct> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('sub_category_id')) {
      context.handle(
        _subCategoryIdMeta,
        subCategoryId.isAcceptableOrUnknown(
          data['sub_category_id']!,
          _subCategoryIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_subCategoryIdMeta);
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('is_trending')) {
      context.handle(
        _isTrendingMeta,
        isTrending.isAcceptableOrUnknown(data['is_trending']!, _isTrendingMeta),
      );
    } else if (isInserting) {
      context.missing(_isTrendingMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    } else if (isInserting) {
      context.missing(_sortOrderMeta);
    }
    if (data.containsKey('variant_id')) {
      context.handle(
        _variantIdMeta,
        variantId.isAcceptableOrUnknown(data['variant_id']!, _variantIdMeta),
      );
    }
    if (data.containsKey('variant_name')) {
      context.handle(
        _variantNameMeta,
        variantName.isAcceptableOrUnknown(
          data['variant_name']!,
          _variantNameMeta,
        ),
      );
    }
    if (data.containsKey('original_price')) {
      context.handle(
        _originalPriceMeta,
        originalPrice.isAcceptableOrUnknown(
          data['original_price']!,
          _originalPriceMeta,
        ),
      );
    }
    if (data.containsKey('current_price')) {
      context.handle(
        _currentPriceMeta,
        currentPrice.isAcceptableOrUnknown(
          data['current_price']!,
          _currentPriceMeta,
        ),
      );
    }
    if (data.containsKey('stock_qty')) {
      context.handle(
        _stockQtyMeta,
        stockQty.isAcceptableOrUnknown(data['stock_qty']!, _stockQtyMeta),
      );
    }
    if (data.containsKey('image_url')) {
      context.handle(
        _imageUrlMeta,
        imageUrl.isAcceptableOrUnknown(data['image_url']!, _imageUrlMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CachedProduct map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedProduct(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      subCategoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sub_category_id'],
      )!,
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      isTrending: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_trending'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      variantId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}variant_id'],
      ),
      variantName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}variant_name'],
      ),
      originalPrice: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}original_price'],
      ),
      currentPrice: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}current_price'],
      ),
      stockQty: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}stock_qty'],
      ),
      imageUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_url'],
      ),
    );
  }

  @override
  $CachedProductsTable createAlias(String alias) {
    return $CachedProductsTable(attachedDatabase, alias);
  }
}

class CachedProduct extends DataClass implements Insertable<CachedProduct> {
  final String id;
  final String subCategoryId;
  final String categoryId;
  final String name;
  final String? description;
  final bool isTrending;
  final DateTime createdAt;
  final int sortOrder;
  final String? variantId;
  final String? variantName;
  final int? originalPrice;
  final int? currentPrice;
  final int? stockQty;
  final String? imageUrl;
  const CachedProduct({
    required this.id,
    required this.subCategoryId,
    required this.categoryId,
    required this.name,
    this.description,
    required this.isTrending,
    required this.createdAt,
    required this.sortOrder,
    this.variantId,
    this.variantName,
    this.originalPrice,
    this.currentPrice,
    this.stockQty,
    this.imageUrl,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['sub_category_id'] = Variable<String>(subCategoryId);
    map['category_id'] = Variable<String>(categoryId);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['is_trending'] = Variable<bool>(isTrending);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['sort_order'] = Variable<int>(sortOrder);
    if (!nullToAbsent || variantId != null) {
      map['variant_id'] = Variable<String>(variantId);
    }
    if (!nullToAbsent || variantName != null) {
      map['variant_name'] = Variable<String>(variantName);
    }
    if (!nullToAbsent || originalPrice != null) {
      map['original_price'] = Variable<int>(originalPrice);
    }
    if (!nullToAbsent || currentPrice != null) {
      map['current_price'] = Variable<int>(currentPrice);
    }
    if (!nullToAbsent || stockQty != null) {
      map['stock_qty'] = Variable<int>(stockQty);
    }
    if (!nullToAbsent || imageUrl != null) {
      map['image_url'] = Variable<String>(imageUrl);
    }
    return map;
  }

  CachedProductsCompanion toCompanion(bool nullToAbsent) {
    return CachedProductsCompanion(
      id: Value(id),
      subCategoryId: Value(subCategoryId),
      categoryId: Value(categoryId),
      name: Value(name),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      isTrending: Value(isTrending),
      createdAt: Value(createdAt),
      sortOrder: Value(sortOrder),
      variantId: variantId == null && nullToAbsent
          ? const Value.absent()
          : Value(variantId),
      variantName: variantName == null && nullToAbsent
          ? const Value.absent()
          : Value(variantName),
      originalPrice: originalPrice == null && nullToAbsent
          ? const Value.absent()
          : Value(originalPrice),
      currentPrice: currentPrice == null && nullToAbsent
          ? const Value.absent()
          : Value(currentPrice),
      stockQty: stockQty == null && nullToAbsent
          ? const Value.absent()
          : Value(stockQty),
      imageUrl: imageUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(imageUrl),
    );
  }

  factory CachedProduct.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedProduct(
      id: serializer.fromJson<String>(json['id']),
      subCategoryId: serializer.fromJson<String>(json['subCategoryId']),
      categoryId: serializer.fromJson<String>(json['categoryId']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String?>(json['description']),
      isTrending: serializer.fromJson<bool>(json['isTrending']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      variantId: serializer.fromJson<String?>(json['variantId']),
      variantName: serializer.fromJson<String?>(json['variantName']),
      originalPrice: serializer.fromJson<int?>(json['originalPrice']),
      currentPrice: serializer.fromJson<int?>(json['currentPrice']),
      stockQty: serializer.fromJson<int?>(json['stockQty']),
      imageUrl: serializer.fromJson<String?>(json['imageUrl']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'subCategoryId': serializer.toJson<String>(subCategoryId),
      'categoryId': serializer.toJson<String>(categoryId),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String?>(description),
      'isTrending': serializer.toJson<bool>(isTrending),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'variantId': serializer.toJson<String?>(variantId),
      'variantName': serializer.toJson<String?>(variantName),
      'originalPrice': serializer.toJson<int?>(originalPrice),
      'currentPrice': serializer.toJson<int?>(currentPrice),
      'stockQty': serializer.toJson<int?>(stockQty),
      'imageUrl': serializer.toJson<String?>(imageUrl),
    };
  }

  CachedProduct copyWith({
    String? id,
    String? subCategoryId,
    String? categoryId,
    String? name,
    Value<String?> description = const Value.absent(),
    bool? isTrending,
    DateTime? createdAt,
    int? sortOrder,
    Value<String?> variantId = const Value.absent(),
    Value<String?> variantName = const Value.absent(),
    Value<int?> originalPrice = const Value.absent(),
    Value<int?> currentPrice = const Value.absent(),
    Value<int?> stockQty = const Value.absent(),
    Value<String?> imageUrl = const Value.absent(),
  }) => CachedProduct(
    id: id ?? this.id,
    subCategoryId: subCategoryId ?? this.subCategoryId,
    categoryId: categoryId ?? this.categoryId,
    name: name ?? this.name,
    description: description.present ? description.value : this.description,
    isTrending: isTrending ?? this.isTrending,
    createdAt: createdAt ?? this.createdAt,
    sortOrder: sortOrder ?? this.sortOrder,
    variantId: variantId.present ? variantId.value : this.variantId,
    variantName: variantName.present ? variantName.value : this.variantName,
    originalPrice: originalPrice.present
        ? originalPrice.value
        : this.originalPrice,
    currentPrice: currentPrice.present ? currentPrice.value : this.currentPrice,
    stockQty: stockQty.present ? stockQty.value : this.stockQty,
    imageUrl: imageUrl.present ? imageUrl.value : this.imageUrl,
  );
  CachedProduct copyWithCompanion(CachedProductsCompanion data) {
    return CachedProduct(
      id: data.id.present ? data.id.value : this.id,
      subCategoryId: data.subCategoryId.present
          ? data.subCategoryId.value
          : this.subCategoryId,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      name: data.name.present ? data.name.value : this.name,
      description: data.description.present
          ? data.description.value
          : this.description,
      isTrending: data.isTrending.present
          ? data.isTrending.value
          : this.isTrending,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      variantId: data.variantId.present ? data.variantId.value : this.variantId,
      variantName: data.variantName.present
          ? data.variantName.value
          : this.variantName,
      originalPrice: data.originalPrice.present
          ? data.originalPrice.value
          : this.originalPrice,
      currentPrice: data.currentPrice.present
          ? data.currentPrice.value
          : this.currentPrice,
      stockQty: data.stockQty.present ? data.stockQty.value : this.stockQty,
      imageUrl: data.imageUrl.present ? data.imageUrl.value : this.imageUrl,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedProduct(')
          ..write('id: $id, ')
          ..write('subCategoryId: $subCategoryId, ')
          ..write('categoryId: $categoryId, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('isTrending: $isTrending, ')
          ..write('createdAt: $createdAt, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('variantId: $variantId, ')
          ..write('variantName: $variantName, ')
          ..write('originalPrice: $originalPrice, ')
          ..write('currentPrice: $currentPrice, ')
          ..write('stockQty: $stockQty, ')
          ..write('imageUrl: $imageUrl')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    subCategoryId,
    categoryId,
    name,
    description,
    isTrending,
    createdAt,
    sortOrder,
    variantId,
    variantName,
    originalPrice,
    currentPrice,
    stockQty,
    imageUrl,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedProduct &&
          other.id == this.id &&
          other.subCategoryId == this.subCategoryId &&
          other.categoryId == this.categoryId &&
          other.name == this.name &&
          other.description == this.description &&
          other.isTrending == this.isTrending &&
          other.createdAt == this.createdAt &&
          other.sortOrder == this.sortOrder &&
          other.variantId == this.variantId &&
          other.variantName == this.variantName &&
          other.originalPrice == this.originalPrice &&
          other.currentPrice == this.currentPrice &&
          other.stockQty == this.stockQty &&
          other.imageUrl == this.imageUrl);
}

class CachedProductsCompanion extends UpdateCompanion<CachedProduct> {
  final Value<String> id;
  final Value<String> subCategoryId;
  final Value<String> categoryId;
  final Value<String> name;
  final Value<String?> description;
  final Value<bool> isTrending;
  final Value<DateTime> createdAt;
  final Value<int> sortOrder;
  final Value<String?> variantId;
  final Value<String?> variantName;
  final Value<int?> originalPrice;
  final Value<int?> currentPrice;
  final Value<int?> stockQty;
  final Value<String?> imageUrl;
  final Value<int> rowid;
  const CachedProductsCompanion({
    this.id = const Value.absent(),
    this.subCategoryId = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.isTrending = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.variantId = const Value.absent(),
    this.variantName = const Value.absent(),
    this.originalPrice = const Value.absent(),
    this.currentPrice = const Value.absent(),
    this.stockQty = const Value.absent(),
    this.imageUrl = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedProductsCompanion.insert({
    required String id,
    required String subCategoryId,
    required String categoryId,
    required String name,
    this.description = const Value.absent(),
    required bool isTrending,
    required DateTime createdAt,
    required int sortOrder,
    this.variantId = const Value.absent(),
    this.variantName = const Value.absent(),
    this.originalPrice = const Value.absent(),
    this.currentPrice = const Value.absent(),
    this.stockQty = const Value.absent(),
    this.imageUrl = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       subCategoryId = Value(subCategoryId),
       categoryId = Value(categoryId),
       name = Value(name),
       isTrending = Value(isTrending),
       createdAt = Value(createdAt),
       sortOrder = Value(sortOrder);
  static Insertable<CachedProduct> custom({
    Expression<String>? id,
    Expression<String>? subCategoryId,
    Expression<String>? categoryId,
    Expression<String>? name,
    Expression<String>? description,
    Expression<bool>? isTrending,
    Expression<DateTime>? createdAt,
    Expression<int>? sortOrder,
    Expression<String>? variantId,
    Expression<String>? variantName,
    Expression<int>? originalPrice,
    Expression<int>? currentPrice,
    Expression<int>? stockQty,
    Expression<String>? imageUrl,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (subCategoryId != null) 'sub_category_id': subCategoryId,
      if (categoryId != null) 'category_id': categoryId,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (isTrending != null) 'is_trending': isTrending,
      if (createdAt != null) 'created_at': createdAt,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (variantId != null) 'variant_id': variantId,
      if (variantName != null) 'variant_name': variantName,
      if (originalPrice != null) 'original_price': originalPrice,
      if (currentPrice != null) 'current_price': currentPrice,
      if (stockQty != null) 'stock_qty': stockQty,
      if (imageUrl != null) 'image_url': imageUrl,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedProductsCompanion copyWith({
    Value<String>? id,
    Value<String>? subCategoryId,
    Value<String>? categoryId,
    Value<String>? name,
    Value<String?>? description,
    Value<bool>? isTrending,
    Value<DateTime>? createdAt,
    Value<int>? sortOrder,
    Value<String?>? variantId,
    Value<String?>? variantName,
    Value<int?>? originalPrice,
    Value<int?>? currentPrice,
    Value<int?>? stockQty,
    Value<String?>? imageUrl,
    Value<int>? rowid,
  }) {
    return CachedProductsCompanion(
      id: id ?? this.id,
      subCategoryId: subCategoryId ?? this.subCategoryId,
      categoryId: categoryId ?? this.categoryId,
      name: name ?? this.name,
      description: description ?? this.description,
      isTrending: isTrending ?? this.isTrending,
      createdAt: createdAt ?? this.createdAt,
      sortOrder: sortOrder ?? this.sortOrder,
      variantId: variantId ?? this.variantId,
      variantName: variantName ?? this.variantName,
      originalPrice: originalPrice ?? this.originalPrice,
      currentPrice: currentPrice ?? this.currentPrice,
      stockQty: stockQty ?? this.stockQty,
      imageUrl: imageUrl ?? this.imageUrl,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (subCategoryId.present) {
      map['sub_category_id'] = Variable<String>(subCategoryId.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (isTrending.present) {
      map['is_trending'] = Variable<bool>(isTrending.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (variantId.present) {
      map['variant_id'] = Variable<String>(variantId.value);
    }
    if (variantName.present) {
      map['variant_name'] = Variable<String>(variantName.value);
    }
    if (originalPrice.present) {
      map['original_price'] = Variable<int>(originalPrice.value);
    }
    if (currentPrice.present) {
      map['current_price'] = Variable<int>(currentPrice.value);
    }
    if (stockQty.present) {
      map['stock_qty'] = Variable<int>(stockQty.value);
    }
    if (imageUrl.present) {
      map['image_url'] = Variable<String>(imageUrl.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedProductsCompanion(')
          ..write('id: $id, ')
          ..write('subCategoryId: $subCategoryId, ')
          ..write('categoryId: $categoryId, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('isTrending: $isTrending, ')
          ..write('createdAt: $createdAt, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('variantId: $variantId, ')
          ..write('variantName: $variantName, ')
          ..write('originalPrice: $originalPrice, ')
          ..write('currentPrice: $currentPrice, ')
          ..write('stockQty: $stockQty, ')
          ..write('imageUrl: $imageUrl, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CachedWishlistItemsTable extends CachedWishlistItems
    with TableInfo<$CachedWishlistItemsTable, CachedWishlistItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedWishlistItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _variantIdMeta = const VerificationMeta(
    'variantId',
  );
  @override
  late final GeneratedColumn<String> variantId = GeneratedColumn<String>(
    'variant_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _productIdMeta = const VerificationMeta(
    'productId',
  );
  @override
  late final GeneratedColumn<String> productId = GeneratedColumn<String>(
    'product_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _productNameMeta = const VerificationMeta(
    'productName',
  );
  @override
  late final GeneratedColumn<String> productName = GeneratedColumn<String>(
    'product_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _variantNameMeta = const VerificationMeta(
    'variantName',
  );
  @override
  late final GeneratedColumn<String> variantName = GeneratedColumn<String>(
    'variant_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _currentPriceMeta = const VerificationMeta(
    'currentPrice',
  );
  @override
  late final GeneratedColumn<int> currentPrice = GeneratedColumn<int>(
    'current_price',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _imageUrlMeta = const VerificationMeta(
    'imageUrl',
  );
  @override
  late final GeneratedColumn<String> imageUrl = GeneratedColumn<String>(
    'image_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    variantId,
    productId,
    productName,
    variantName,
    currentPrice,
    imageUrl,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_wishlist_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedWishlistItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('variant_id')) {
      context.handle(
        _variantIdMeta,
        variantId.isAcceptableOrUnknown(data['variant_id']!, _variantIdMeta),
      );
    } else if (isInserting) {
      context.missing(_variantIdMeta);
    }
    if (data.containsKey('product_id')) {
      context.handle(
        _productIdMeta,
        productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta),
      );
    } else if (isInserting) {
      context.missing(_productIdMeta);
    }
    if (data.containsKey('product_name')) {
      context.handle(
        _productNameMeta,
        productName.isAcceptableOrUnknown(
          data['product_name']!,
          _productNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_productNameMeta);
    }
    if (data.containsKey('variant_name')) {
      context.handle(
        _variantNameMeta,
        variantName.isAcceptableOrUnknown(
          data['variant_name']!,
          _variantNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_variantNameMeta);
    }
    if (data.containsKey('current_price')) {
      context.handle(
        _currentPriceMeta,
        currentPrice.isAcceptableOrUnknown(
          data['current_price']!,
          _currentPriceMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_currentPriceMeta);
    }
    if (data.containsKey('image_url')) {
      context.handle(
        _imageUrlMeta,
        imageUrl.isAcceptableOrUnknown(data['image_url']!, _imageUrlMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {variantId};
  @override
  CachedWishlistItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedWishlistItem(
      variantId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}variant_id'],
      )!,
      productId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_id'],
      )!,
      productName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_name'],
      )!,
      variantName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}variant_name'],
      )!,
      currentPrice: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}current_price'],
      )!,
      imageUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_url'],
      ),
    );
  }

  @override
  $CachedWishlistItemsTable createAlias(String alias) {
    return $CachedWishlistItemsTable(attachedDatabase, alias);
  }
}

class CachedWishlistItem extends DataClass
    implements Insertable<CachedWishlistItem> {
  final String variantId;
  final String productId;
  final String productName;
  final String variantName;
  final int currentPrice;
  final String? imageUrl;
  const CachedWishlistItem({
    required this.variantId,
    required this.productId,
    required this.productName,
    required this.variantName,
    required this.currentPrice,
    this.imageUrl,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['variant_id'] = Variable<String>(variantId);
    map['product_id'] = Variable<String>(productId);
    map['product_name'] = Variable<String>(productName);
    map['variant_name'] = Variable<String>(variantName);
    map['current_price'] = Variable<int>(currentPrice);
    if (!nullToAbsent || imageUrl != null) {
      map['image_url'] = Variable<String>(imageUrl);
    }
    return map;
  }

  CachedWishlistItemsCompanion toCompanion(bool nullToAbsent) {
    return CachedWishlistItemsCompanion(
      variantId: Value(variantId),
      productId: Value(productId),
      productName: Value(productName),
      variantName: Value(variantName),
      currentPrice: Value(currentPrice),
      imageUrl: imageUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(imageUrl),
    );
  }

  factory CachedWishlistItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedWishlistItem(
      variantId: serializer.fromJson<String>(json['variantId']),
      productId: serializer.fromJson<String>(json['productId']),
      productName: serializer.fromJson<String>(json['productName']),
      variantName: serializer.fromJson<String>(json['variantName']),
      currentPrice: serializer.fromJson<int>(json['currentPrice']),
      imageUrl: serializer.fromJson<String?>(json['imageUrl']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'variantId': serializer.toJson<String>(variantId),
      'productId': serializer.toJson<String>(productId),
      'productName': serializer.toJson<String>(productName),
      'variantName': serializer.toJson<String>(variantName),
      'currentPrice': serializer.toJson<int>(currentPrice),
      'imageUrl': serializer.toJson<String?>(imageUrl),
    };
  }

  CachedWishlistItem copyWith({
    String? variantId,
    String? productId,
    String? productName,
    String? variantName,
    int? currentPrice,
    Value<String?> imageUrl = const Value.absent(),
  }) => CachedWishlistItem(
    variantId: variantId ?? this.variantId,
    productId: productId ?? this.productId,
    productName: productName ?? this.productName,
    variantName: variantName ?? this.variantName,
    currentPrice: currentPrice ?? this.currentPrice,
    imageUrl: imageUrl.present ? imageUrl.value : this.imageUrl,
  );
  CachedWishlistItem copyWithCompanion(CachedWishlistItemsCompanion data) {
    return CachedWishlistItem(
      variantId: data.variantId.present ? data.variantId.value : this.variantId,
      productId: data.productId.present ? data.productId.value : this.productId,
      productName: data.productName.present
          ? data.productName.value
          : this.productName,
      variantName: data.variantName.present
          ? data.variantName.value
          : this.variantName,
      currentPrice: data.currentPrice.present
          ? data.currentPrice.value
          : this.currentPrice,
      imageUrl: data.imageUrl.present ? data.imageUrl.value : this.imageUrl,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedWishlistItem(')
          ..write('variantId: $variantId, ')
          ..write('productId: $productId, ')
          ..write('productName: $productName, ')
          ..write('variantName: $variantName, ')
          ..write('currentPrice: $currentPrice, ')
          ..write('imageUrl: $imageUrl')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    variantId,
    productId,
    productName,
    variantName,
    currentPrice,
    imageUrl,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedWishlistItem &&
          other.variantId == this.variantId &&
          other.productId == this.productId &&
          other.productName == this.productName &&
          other.variantName == this.variantName &&
          other.currentPrice == this.currentPrice &&
          other.imageUrl == this.imageUrl);
}

class CachedWishlistItemsCompanion extends UpdateCompanion<CachedWishlistItem> {
  final Value<String> variantId;
  final Value<String> productId;
  final Value<String> productName;
  final Value<String> variantName;
  final Value<int> currentPrice;
  final Value<String?> imageUrl;
  final Value<int> rowid;
  const CachedWishlistItemsCompanion({
    this.variantId = const Value.absent(),
    this.productId = const Value.absent(),
    this.productName = const Value.absent(),
    this.variantName = const Value.absent(),
    this.currentPrice = const Value.absent(),
    this.imageUrl = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedWishlistItemsCompanion.insert({
    required String variantId,
    required String productId,
    required String productName,
    required String variantName,
    required int currentPrice,
    this.imageUrl = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : variantId = Value(variantId),
       productId = Value(productId),
       productName = Value(productName),
       variantName = Value(variantName),
       currentPrice = Value(currentPrice);
  static Insertable<CachedWishlistItem> custom({
    Expression<String>? variantId,
    Expression<String>? productId,
    Expression<String>? productName,
    Expression<String>? variantName,
    Expression<int>? currentPrice,
    Expression<String>? imageUrl,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (variantId != null) 'variant_id': variantId,
      if (productId != null) 'product_id': productId,
      if (productName != null) 'product_name': productName,
      if (variantName != null) 'variant_name': variantName,
      if (currentPrice != null) 'current_price': currentPrice,
      if (imageUrl != null) 'image_url': imageUrl,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedWishlistItemsCompanion copyWith({
    Value<String>? variantId,
    Value<String>? productId,
    Value<String>? productName,
    Value<String>? variantName,
    Value<int>? currentPrice,
    Value<String?>? imageUrl,
    Value<int>? rowid,
  }) {
    return CachedWishlistItemsCompanion(
      variantId: variantId ?? this.variantId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      variantName: variantName ?? this.variantName,
      currentPrice: currentPrice ?? this.currentPrice,
      imageUrl: imageUrl ?? this.imageUrl,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (variantId.present) {
      map['variant_id'] = Variable<String>(variantId.value);
    }
    if (productId.present) {
      map['product_id'] = Variable<String>(productId.value);
    }
    if (productName.present) {
      map['product_name'] = Variable<String>(productName.value);
    }
    if (variantName.present) {
      map['variant_name'] = Variable<String>(variantName.value);
    }
    if (currentPrice.present) {
      map['current_price'] = Variable<int>(currentPrice.value);
    }
    if (imageUrl.present) {
      map['image_url'] = Variable<String>(imageUrl.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedWishlistItemsCompanion(')
          ..write('variantId: $variantId, ')
          ..write('productId: $productId, ')
          ..write('productName: $productName, ')
          ..write('variantName: $variantName, ')
          ..write('currentPrice: $currentPrice, ')
          ..write('imageUrl: $imageUrl, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CachedCartItemsTable extends CachedCartItems
    with TableInfo<$CachedCartItemsTable, CachedCartItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedCartItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _variantIdMeta = const VerificationMeta(
    'variantId',
  );
  @override
  late final GeneratedColumn<String> variantId = GeneratedColumn<String>(
    'variant_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _serverIdMeta = const VerificationMeta(
    'serverId',
  );
  @override
  late final GeneratedColumn<String> serverId = GeneratedColumn<String>(
    'server_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _productIdMeta = const VerificationMeta(
    'productId',
  );
  @override
  late final GeneratedColumn<String> productId = GeneratedColumn<String>(
    'product_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _productNameMeta = const VerificationMeta(
    'productName',
  );
  @override
  late final GeneratedColumn<String> productName = GeneratedColumn<String>(
    'product_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _variantNameMeta = const VerificationMeta(
    'variantName',
  );
  @override
  late final GeneratedColumn<String> variantName = GeneratedColumn<String>(
    'variant_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _currentPriceMeta = const VerificationMeta(
    'currentPrice',
  );
  @override
  late final GeneratedColumn<int> currentPrice = GeneratedColumn<int>(
    'current_price',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _originalPriceMeta = const VerificationMeta(
    'originalPrice',
  );
  @override
  late final GeneratedColumn<int> originalPrice = GeneratedColumn<int>(
    'original_price',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stockQtyMeta = const VerificationMeta(
    'stockQty',
  );
  @override
  late final GeneratedColumn<int> stockQty = GeneratedColumn<int>(
    'stock_qty',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _quantityMeta = const VerificationMeta(
    'quantity',
  );
  @override
  late final GeneratedColumn<int> quantity = GeneratedColumn<int>(
    'quantity',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _imageUrlMeta = const VerificationMeta(
    'imageUrl',
  );
  @override
  late final GeneratedColumn<String> imageUrl = GeneratedColumn<String>(
    'image_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    variantId,
    serverId,
    productId,
    productName,
    variantName,
    currentPrice,
    originalPrice,
    stockQty,
    quantity,
    imageUrl,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_cart_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedCartItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('variant_id')) {
      context.handle(
        _variantIdMeta,
        variantId.isAcceptableOrUnknown(data['variant_id']!, _variantIdMeta),
      );
    } else if (isInserting) {
      context.missing(_variantIdMeta);
    }
    if (data.containsKey('server_id')) {
      context.handle(
        _serverIdMeta,
        serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta),
      );
    }
    if (data.containsKey('product_id')) {
      context.handle(
        _productIdMeta,
        productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta),
      );
    } else if (isInserting) {
      context.missing(_productIdMeta);
    }
    if (data.containsKey('product_name')) {
      context.handle(
        _productNameMeta,
        productName.isAcceptableOrUnknown(
          data['product_name']!,
          _productNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_productNameMeta);
    }
    if (data.containsKey('variant_name')) {
      context.handle(
        _variantNameMeta,
        variantName.isAcceptableOrUnknown(
          data['variant_name']!,
          _variantNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_variantNameMeta);
    }
    if (data.containsKey('current_price')) {
      context.handle(
        _currentPriceMeta,
        currentPrice.isAcceptableOrUnknown(
          data['current_price']!,
          _currentPriceMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_currentPriceMeta);
    }
    if (data.containsKey('original_price')) {
      context.handle(
        _originalPriceMeta,
        originalPrice.isAcceptableOrUnknown(
          data['original_price']!,
          _originalPriceMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_originalPriceMeta);
    }
    if (data.containsKey('stock_qty')) {
      context.handle(
        _stockQtyMeta,
        stockQty.isAcceptableOrUnknown(data['stock_qty']!, _stockQtyMeta),
      );
    } else if (isInserting) {
      context.missing(_stockQtyMeta);
    }
    if (data.containsKey('quantity')) {
      context.handle(
        _quantityMeta,
        quantity.isAcceptableOrUnknown(data['quantity']!, _quantityMeta),
      );
    } else if (isInserting) {
      context.missing(_quantityMeta);
    }
    if (data.containsKey('image_url')) {
      context.handle(
        _imageUrlMeta,
        imageUrl.isAcceptableOrUnknown(data['image_url']!, _imageUrlMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {variantId};
  @override
  CachedCartItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedCartItem(
      variantId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}variant_id'],
      )!,
      serverId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}server_id'],
      ),
      productId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_id'],
      )!,
      productName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_name'],
      )!,
      variantName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}variant_name'],
      )!,
      currentPrice: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}current_price'],
      )!,
      originalPrice: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}original_price'],
      )!,
      stockQty: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}stock_qty'],
      )!,
      quantity: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}quantity'],
      )!,
      imageUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_url'],
      ),
    );
  }

  @override
  $CachedCartItemsTable createAlias(String alias) {
    return $CachedCartItemsTable(attachedDatabase, alias);
  }
}

class CachedCartItem extends DataClass implements Insertable<CachedCartItem> {
  final String variantId;
  final String? serverId;
  final String productId;
  final String productName;
  final String variantName;
  final int currentPrice;
  final int originalPrice;
  final int stockQty;
  final int quantity;
  final String? imageUrl;
  const CachedCartItem({
    required this.variantId,
    this.serverId,
    required this.productId,
    required this.productName,
    required this.variantName,
    required this.currentPrice,
    required this.originalPrice,
    required this.stockQty,
    required this.quantity,
    this.imageUrl,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['variant_id'] = Variable<String>(variantId);
    if (!nullToAbsent || serverId != null) {
      map['server_id'] = Variable<String>(serverId);
    }
    map['product_id'] = Variable<String>(productId);
    map['product_name'] = Variable<String>(productName);
    map['variant_name'] = Variable<String>(variantName);
    map['current_price'] = Variable<int>(currentPrice);
    map['original_price'] = Variable<int>(originalPrice);
    map['stock_qty'] = Variable<int>(stockQty);
    map['quantity'] = Variable<int>(quantity);
    if (!nullToAbsent || imageUrl != null) {
      map['image_url'] = Variable<String>(imageUrl);
    }
    return map;
  }

  CachedCartItemsCompanion toCompanion(bool nullToAbsent) {
    return CachedCartItemsCompanion(
      variantId: Value(variantId),
      serverId: serverId == null && nullToAbsent
          ? const Value.absent()
          : Value(serverId),
      productId: Value(productId),
      productName: Value(productName),
      variantName: Value(variantName),
      currentPrice: Value(currentPrice),
      originalPrice: Value(originalPrice),
      stockQty: Value(stockQty),
      quantity: Value(quantity),
      imageUrl: imageUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(imageUrl),
    );
  }

  factory CachedCartItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedCartItem(
      variantId: serializer.fromJson<String>(json['variantId']),
      serverId: serializer.fromJson<String?>(json['serverId']),
      productId: serializer.fromJson<String>(json['productId']),
      productName: serializer.fromJson<String>(json['productName']),
      variantName: serializer.fromJson<String>(json['variantName']),
      currentPrice: serializer.fromJson<int>(json['currentPrice']),
      originalPrice: serializer.fromJson<int>(json['originalPrice']),
      stockQty: serializer.fromJson<int>(json['stockQty']),
      quantity: serializer.fromJson<int>(json['quantity']),
      imageUrl: serializer.fromJson<String?>(json['imageUrl']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'variantId': serializer.toJson<String>(variantId),
      'serverId': serializer.toJson<String?>(serverId),
      'productId': serializer.toJson<String>(productId),
      'productName': serializer.toJson<String>(productName),
      'variantName': serializer.toJson<String>(variantName),
      'currentPrice': serializer.toJson<int>(currentPrice),
      'originalPrice': serializer.toJson<int>(originalPrice),
      'stockQty': serializer.toJson<int>(stockQty),
      'quantity': serializer.toJson<int>(quantity),
      'imageUrl': serializer.toJson<String?>(imageUrl),
    };
  }

  CachedCartItem copyWith({
    String? variantId,
    Value<String?> serverId = const Value.absent(),
    String? productId,
    String? productName,
    String? variantName,
    int? currentPrice,
    int? originalPrice,
    int? stockQty,
    int? quantity,
    Value<String?> imageUrl = const Value.absent(),
  }) => CachedCartItem(
    variantId: variantId ?? this.variantId,
    serverId: serverId.present ? serverId.value : this.serverId,
    productId: productId ?? this.productId,
    productName: productName ?? this.productName,
    variantName: variantName ?? this.variantName,
    currentPrice: currentPrice ?? this.currentPrice,
    originalPrice: originalPrice ?? this.originalPrice,
    stockQty: stockQty ?? this.stockQty,
    quantity: quantity ?? this.quantity,
    imageUrl: imageUrl.present ? imageUrl.value : this.imageUrl,
  );
  CachedCartItem copyWithCompanion(CachedCartItemsCompanion data) {
    return CachedCartItem(
      variantId: data.variantId.present ? data.variantId.value : this.variantId,
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      productId: data.productId.present ? data.productId.value : this.productId,
      productName: data.productName.present
          ? data.productName.value
          : this.productName,
      variantName: data.variantName.present
          ? data.variantName.value
          : this.variantName,
      currentPrice: data.currentPrice.present
          ? data.currentPrice.value
          : this.currentPrice,
      originalPrice: data.originalPrice.present
          ? data.originalPrice.value
          : this.originalPrice,
      stockQty: data.stockQty.present ? data.stockQty.value : this.stockQty,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
      imageUrl: data.imageUrl.present ? data.imageUrl.value : this.imageUrl,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedCartItem(')
          ..write('variantId: $variantId, ')
          ..write('serverId: $serverId, ')
          ..write('productId: $productId, ')
          ..write('productName: $productName, ')
          ..write('variantName: $variantName, ')
          ..write('currentPrice: $currentPrice, ')
          ..write('originalPrice: $originalPrice, ')
          ..write('stockQty: $stockQty, ')
          ..write('quantity: $quantity, ')
          ..write('imageUrl: $imageUrl')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    variantId,
    serverId,
    productId,
    productName,
    variantName,
    currentPrice,
    originalPrice,
    stockQty,
    quantity,
    imageUrl,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedCartItem &&
          other.variantId == this.variantId &&
          other.serverId == this.serverId &&
          other.productId == this.productId &&
          other.productName == this.productName &&
          other.variantName == this.variantName &&
          other.currentPrice == this.currentPrice &&
          other.originalPrice == this.originalPrice &&
          other.stockQty == this.stockQty &&
          other.quantity == this.quantity &&
          other.imageUrl == this.imageUrl);
}

class CachedCartItemsCompanion extends UpdateCompanion<CachedCartItem> {
  final Value<String> variantId;
  final Value<String?> serverId;
  final Value<String> productId;
  final Value<String> productName;
  final Value<String> variantName;
  final Value<int> currentPrice;
  final Value<int> originalPrice;
  final Value<int> stockQty;
  final Value<int> quantity;
  final Value<String?> imageUrl;
  final Value<int> rowid;
  const CachedCartItemsCompanion({
    this.variantId = const Value.absent(),
    this.serverId = const Value.absent(),
    this.productId = const Value.absent(),
    this.productName = const Value.absent(),
    this.variantName = const Value.absent(),
    this.currentPrice = const Value.absent(),
    this.originalPrice = const Value.absent(),
    this.stockQty = const Value.absent(),
    this.quantity = const Value.absent(),
    this.imageUrl = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedCartItemsCompanion.insert({
    required String variantId,
    this.serverId = const Value.absent(),
    required String productId,
    required String productName,
    required String variantName,
    required int currentPrice,
    required int originalPrice,
    required int stockQty,
    required int quantity,
    this.imageUrl = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : variantId = Value(variantId),
       productId = Value(productId),
       productName = Value(productName),
       variantName = Value(variantName),
       currentPrice = Value(currentPrice),
       originalPrice = Value(originalPrice),
       stockQty = Value(stockQty),
       quantity = Value(quantity);
  static Insertable<CachedCartItem> custom({
    Expression<String>? variantId,
    Expression<String>? serverId,
    Expression<String>? productId,
    Expression<String>? productName,
    Expression<String>? variantName,
    Expression<int>? currentPrice,
    Expression<int>? originalPrice,
    Expression<int>? stockQty,
    Expression<int>? quantity,
    Expression<String>? imageUrl,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (variantId != null) 'variant_id': variantId,
      if (serverId != null) 'server_id': serverId,
      if (productId != null) 'product_id': productId,
      if (productName != null) 'product_name': productName,
      if (variantName != null) 'variant_name': variantName,
      if (currentPrice != null) 'current_price': currentPrice,
      if (originalPrice != null) 'original_price': originalPrice,
      if (stockQty != null) 'stock_qty': stockQty,
      if (quantity != null) 'quantity': quantity,
      if (imageUrl != null) 'image_url': imageUrl,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedCartItemsCompanion copyWith({
    Value<String>? variantId,
    Value<String?>? serverId,
    Value<String>? productId,
    Value<String>? productName,
    Value<String>? variantName,
    Value<int>? currentPrice,
    Value<int>? originalPrice,
    Value<int>? stockQty,
    Value<int>? quantity,
    Value<String?>? imageUrl,
    Value<int>? rowid,
  }) {
    return CachedCartItemsCompanion(
      variantId: variantId ?? this.variantId,
      serverId: serverId ?? this.serverId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      variantName: variantName ?? this.variantName,
      currentPrice: currentPrice ?? this.currentPrice,
      originalPrice: originalPrice ?? this.originalPrice,
      stockQty: stockQty ?? this.stockQty,
      quantity: quantity ?? this.quantity,
      imageUrl: imageUrl ?? this.imageUrl,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (variantId.present) {
      map['variant_id'] = Variable<String>(variantId.value);
    }
    if (serverId.present) {
      map['server_id'] = Variable<String>(serverId.value);
    }
    if (productId.present) {
      map['product_id'] = Variable<String>(productId.value);
    }
    if (productName.present) {
      map['product_name'] = Variable<String>(productName.value);
    }
    if (variantName.present) {
      map['variant_name'] = Variable<String>(variantName.value);
    }
    if (currentPrice.present) {
      map['current_price'] = Variable<int>(currentPrice.value);
    }
    if (originalPrice.present) {
      map['original_price'] = Variable<int>(originalPrice.value);
    }
    if (stockQty.present) {
      map['stock_qty'] = Variable<int>(stockQty.value);
    }
    if (quantity.present) {
      map['quantity'] = Variable<int>(quantity.value);
    }
    if (imageUrl.present) {
      map['image_url'] = Variable<String>(imageUrl.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedCartItemsCompanion(')
          ..write('variantId: $variantId, ')
          ..write('serverId: $serverId, ')
          ..write('productId: $productId, ')
          ..write('productName: $productName, ')
          ..write('variantName: $variantName, ')
          ..write('currentPrice: $currentPrice, ')
          ..write('originalPrice: $originalPrice, ')
          ..write('stockQty: $stockQty, ')
          ..write('quantity: $quantity, ')
          ..write('imageUrl: $imageUrl, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CachedAddressesTable extends CachedAddresses
    with TableInfo<$CachedAddressesTable, CachedAddressesData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedAddressesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
    'label',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _line1Meta = const VerificationMeta('line1');
  @override
  late final GeneratedColumn<String> line1 = GeneratedColumn<String>(
    'line1',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _line2Meta = const VerificationMeta('line2');
  @override
  late final GeneratedColumn<String> line2 = GeneratedColumn<String>(
    'line2',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cityMeta = const VerificationMeta('city');
  @override
  late final GeneratedColumn<String> city = GeneratedColumn<String>(
    'city',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stateMeta = const VerificationMeta('state');
  @override
  late final GeneratedColumn<String> state = GeneratedColumn<String>(
    'state',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pincodeMeta = const VerificationMeta(
    'pincode',
  );
  @override
  late final GeneratedColumn<String> pincode = GeneratedColumn<String>(
    'pincode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isDefaultMeta = const VerificationMeta(
    'isDefault',
  );
  @override
  late final GeneratedColumn<bool> isDefault = GeneratedColumn<bool>(
    'is_default',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_default" IN (0, 1))',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    label,
    line1,
    line2,
    city,
    state,
    pincode,
    isDefault,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_addresses';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedAddressesData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('label')) {
      context.handle(
        _labelMeta,
        label.isAcceptableOrUnknown(data['label']!, _labelMeta),
      );
    }
    if (data.containsKey('line1')) {
      context.handle(
        _line1Meta,
        line1.isAcceptableOrUnknown(data['line1']!, _line1Meta),
      );
    } else if (isInserting) {
      context.missing(_line1Meta);
    }
    if (data.containsKey('line2')) {
      context.handle(
        _line2Meta,
        line2.isAcceptableOrUnknown(data['line2']!, _line2Meta),
      );
    }
    if (data.containsKey('city')) {
      context.handle(
        _cityMeta,
        city.isAcceptableOrUnknown(data['city']!, _cityMeta),
      );
    } else if (isInserting) {
      context.missing(_cityMeta);
    }
    if (data.containsKey('state')) {
      context.handle(
        _stateMeta,
        state.isAcceptableOrUnknown(data['state']!, _stateMeta),
      );
    } else if (isInserting) {
      context.missing(_stateMeta);
    }
    if (data.containsKey('pincode')) {
      context.handle(
        _pincodeMeta,
        pincode.isAcceptableOrUnknown(data['pincode']!, _pincodeMeta),
      );
    } else if (isInserting) {
      context.missing(_pincodeMeta);
    }
    if (data.containsKey('is_default')) {
      context.handle(
        _isDefaultMeta,
        isDefault.isAcceptableOrUnknown(data['is_default']!, _isDefaultMeta),
      );
    } else if (isInserting) {
      context.missing(_isDefaultMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CachedAddressesData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedAddressesData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      label: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label'],
      ),
      line1: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}line1'],
      )!,
      line2: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}line2'],
      ),
      city: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}city'],
      )!,
      state: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}state'],
      )!,
      pincode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pincode'],
      )!,
      isDefault: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_default'],
      )!,
    );
  }

  @override
  $CachedAddressesTable createAlias(String alias) {
    return $CachedAddressesTable(attachedDatabase, alias);
  }
}

class CachedAddressesData extends DataClass
    implements Insertable<CachedAddressesData> {
  final String id;
  final String? label;
  final String line1;
  final String? line2;
  final String city;
  final String state;
  final String pincode;
  final bool isDefault;
  const CachedAddressesData({
    required this.id,
    this.label,
    required this.line1,
    this.line2,
    required this.city,
    required this.state,
    required this.pincode,
    required this.isDefault,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || label != null) {
      map['label'] = Variable<String>(label);
    }
    map['line1'] = Variable<String>(line1);
    if (!nullToAbsent || line2 != null) {
      map['line2'] = Variable<String>(line2);
    }
    map['city'] = Variable<String>(city);
    map['state'] = Variable<String>(state);
    map['pincode'] = Variable<String>(pincode);
    map['is_default'] = Variable<bool>(isDefault);
    return map;
  }

  CachedAddressesCompanion toCompanion(bool nullToAbsent) {
    return CachedAddressesCompanion(
      id: Value(id),
      label: label == null && nullToAbsent
          ? const Value.absent()
          : Value(label),
      line1: Value(line1),
      line2: line2 == null && nullToAbsent
          ? const Value.absent()
          : Value(line2),
      city: Value(city),
      state: Value(state),
      pincode: Value(pincode),
      isDefault: Value(isDefault),
    );
  }

  factory CachedAddressesData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedAddressesData(
      id: serializer.fromJson<String>(json['id']),
      label: serializer.fromJson<String?>(json['label']),
      line1: serializer.fromJson<String>(json['line1']),
      line2: serializer.fromJson<String?>(json['line2']),
      city: serializer.fromJson<String>(json['city']),
      state: serializer.fromJson<String>(json['state']),
      pincode: serializer.fromJson<String>(json['pincode']),
      isDefault: serializer.fromJson<bool>(json['isDefault']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'label': serializer.toJson<String?>(label),
      'line1': serializer.toJson<String>(line1),
      'line2': serializer.toJson<String?>(line2),
      'city': serializer.toJson<String>(city),
      'state': serializer.toJson<String>(state),
      'pincode': serializer.toJson<String>(pincode),
      'isDefault': serializer.toJson<bool>(isDefault),
    };
  }

  CachedAddressesData copyWith({
    String? id,
    Value<String?> label = const Value.absent(),
    String? line1,
    Value<String?> line2 = const Value.absent(),
    String? city,
    String? state,
    String? pincode,
    bool? isDefault,
  }) => CachedAddressesData(
    id: id ?? this.id,
    label: label.present ? label.value : this.label,
    line1: line1 ?? this.line1,
    line2: line2.present ? line2.value : this.line2,
    city: city ?? this.city,
    state: state ?? this.state,
    pincode: pincode ?? this.pincode,
    isDefault: isDefault ?? this.isDefault,
  );
  CachedAddressesData copyWithCompanion(CachedAddressesCompanion data) {
    return CachedAddressesData(
      id: data.id.present ? data.id.value : this.id,
      label: data.label.present ? data.label.value : this.label,
      line1: data.line1.present ? data.line1.value : this.line1,
      line2: data.line2.present ? data.line2.value : this.line2,
      city: data.city.present ? data.city.value : this.city,
      state: data.state.present ? data.state.value : this.state,
      pincode: data.pincode.present ? data.pincode.value : this.pincode,
      isDefault: data.isDefault.present ? data.isDefault.value : this.isDefault,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedAddressesData(')
          ..write('id: $id, ')
          ..write('label: $label, ')
          ..write('line1: $line1, ')
          ..write('line2: $line2, ')
          ..write('city: $city, ')
          ..write('state: $state, ')
          ..write('pincode: $pincode, ')
          ..write('isDefault: $isDefault')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, label, line1, line2, city, state, pincode, isDefault);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedAddressesData &&
          other.id == this.id &&
          other.label == this.label &&
          other.line1 == this.line1 &&
          other.line2 == this.line2 &&
          other.city == this.city &&
          other.state == this.state &&
          other.pincode == this.pincode &&
          other.isDefault == this.isDefault);
}

class CachedAddressesCompanion extends UpdateCompanion<CachedAddressesData> {
  final Value<String> id;
  final Value<String?> label;
  final Value<String> line1;
  final Value<String?> line2;
  final Value<String> city;
  final Value<String> state;
  final Value<String> pincode;
  final Value<bool> isDefault;
  final Value<int> rowid;
  const CachedAddressesCompanion({
    this.id = const Value.absent(),
    this.label = const Value.absent(),
    this.line1 = const Value.absent(),
    this.line2 = const Value.absent(),
    this.city = const Value.absent(),
    this.state = const Value.absent(),
    this.pincode = const Value.absent(),
    this.isDefault = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedAddressesCompanion.insert({
    required String id,
    this.label = const Value.absent(),
    required String line1,
    this.line2 = const Value.absent(),
    required String city,
    required String state,
    required String pincode,
    required bool isDefault,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       line1 = Value(line1),
       city = Value(city),
       state = Value(state),
       pincode = Value(pincode),
       isDefault = Value(isDefault);
  static Insertable<CachedAddressesData> custom({
    Expression<String>? id,
    Expression<String>? label,
    Expression<String>? line1,
    Expression<String>? line2,
    Expression<String>? city,
    Expression<String>? state,
    Expression<String>? pincode,
    Expression<bool>? isDefault,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (label != null) 'label': label,
      if (line1 != null) 'line1': line1,
      if (line2 != null) 'line2': line2,
      if (city != null) 'city': city,
      if (state != null) 'state': state,
      if (pincode != null) 'pincode': pincode,
      if (isDefault != null) 'is_default': isDefault,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedAddressesCompanion copyWith({
    Value<String>? id,
    Value<String?>? label,
    Value<String>? line1,
    Value<String?>? line2,
    Value<String>? city,
    Value<String>? state,
    Value<String>? pincode,
    Value<bool>? isDefault,
    Value<int>? rowid,
  }) {
    return CachedAddressesCompanion(
      id: id ?? this.id,
      label: label ?? this.label,
      line1: line1 ?? this.line1,
      line2: line2 ?? this.line2,
      city: city ?? this.city,
      state: state ?? this.state,
      pincode: pincode ?? this.pincode,
      isDefault: isDefault ?? this.isDefault,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (line1.present) {
      map['line1'] = Variable<String>(line1.value);
    }
    if (line2.present) {
      map['line2'] = Variable<String>(line2.value);
    }
    if (city.present) {
      map['city'] = Variable<String>(city.value);
    }
    if (state.present) {
      map['state'] = Variable<String>(state.value);
    }
    if (pincode.present) {
      map['pincode'] = Variable<String>(pincode.value);
    }
    if (isDefault.present) {
      map['is_default'] = Variable<bool>(isDefault.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedAddressesCompanion(')
          ..write('id: $id, ')
          ..write('label: $label, ')
          ..write('line1: $line1, ')
          ..write('line2: $line2, ')
          ..write('city: $city, ')
          ..write('state: $state, ')
          ..write('pincode: $pincode, ')
          ..write('isDefault: $isDefault, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CachedOrdersTable extends CachedOrders
    with TableInfo<$CachedOrdersTable, CachedOrder> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedOrdersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _subtotalMeta = const VerificationMeta(
    'subtotal',
  );
  @override
  late final GeneratedColumn<int> subtotal = GeneratedColumn<int>(
    'subtotal',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _discountValueMeta = const VerificationMeta(
    'discountValue',
  );
  @override
  late final GeneratedColumn<int> discountValue = GeneratedColumn<int>(
    'discount_value',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _shippingCostMeta = const VerificationMeta(
    'shippingCost',
  );
  @override
  late final GeneratedColumn<int> shippingCost = GeneratedColumn<int>(
    'shipping_cost',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _totalMeta = const VerificationMeta('total');
  @override
  late final GeneratedColumn<int> total = GeneratedColumn<int>(
    'total',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _itemCountMeta = const VerificationMeta(
    'itemCount',
  );
  @override
  late final GeneratedColumn<int> itemCount = GeneratedColumn<int>(
    'item_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _thumbnailUrlMeta = const VerificationMeta(
    'thumbnailUrl',
  );
  @override
  late final GeneratedColumn<String> thumbnailUrl = GeneratedColumn<String>(
    'thumbnail_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    status,
    subtotal,
    discountValue,
    shippingCost,
    total,
    createdAt,
    itemCount,
    thumbnailUrl,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_orders';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedOrder> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('subtotal')) {
      context.handle(
        _subtotalMeta,
        subtotal.isAcceptableOrUnknown(data['subtotal']!, _subtotalMeta),
      );
    } else if (isInserting) {
      context.missing(_subtotalMeta);
    }
    if (data.containsKey('discount_value')) {
      context.handle(
        _discountValueMeta,
        discountValue.isAcceptableOrUnknown(
          data['discount_value']!,
          _discountValueMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_discountValueMeta);
    }
    if (data.containsKey('shipping_cost')) {
      context.handle(
        _shippingCostMeta,
        shippingCost.isAcceptableOrUnknown(
          data['shipping_cost']!,
          _shippingCostMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_shippingCostMeta);
    }
    if (data.containsKey('total')) {
      context.handle(
        _totalMeta,
        total.isAcceptableOrUnknown(data['total']!, _totalMeta),
      );
    } else if (isInserting) {
      context.missing(_totalMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('item_count')) {
      context.handle(
        _itemCountMeta,
        itemCount.isAcceptableOrUnknown(data['item_count']!, _itemCountMeta),
      );
    } else if (isInserting) {
      context.missing(_itemCountMeta);
    }
    if (data.containsKey('thumbnail_url')) {
      context.handle(
        _thumbnailUrlMeta,
        thumbnailUrl.isAcceptableOrUnknown(
          data['thumbnail_url']!,
          _thumbnailUrlMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CachedOrder map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedOrder(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      subtotal: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}subtotal'],
      )!,
      discountValue: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}discount_value'],
      )!,
      shippingCost: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}shipping_cost'],
      )!,
      total: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      itemCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}item_count'],
      )!,
      thumbnailUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}thumbnail_url'],
      ),
    );
  }

  @override
  $CachedOrdersTable createAlias(String alias) {
    return $CachedOrdersTable(attachedDatabase, alias);
  }
}

class CachedOrder extends DataClass implements Insertable<CachedOrder> {
  final String id;
  final String status;
  final int subtotal;
  final int discountValue;
  final int shippingCost;
  final int total;
  final DateTime createdAt;
  final int itemCount;
  final String? thumbnailUrl;
  const CachedOrder({
    required this.id,
    required this.status,
    required this.subtotal,
    required this.discountValue,
    required this.shippingCost,
    required this.total,
    required this.createdAt,
    required this.itemCount,
    this.thumbnailUrl,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['status'] = Variable<String>(status);
    map['subtotal'] = Variable<int>(subtotal);
    map['discount_value'] = Variable<int>(discountValue);
    map['shipping_cost'] = Variable<int>(shippingCost);
    map['total'] = Variable<int>(total);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['item_count'] = Variable<int>(itemCount);
    if (!nullToAbsent || thumbnailUrl != null) {
      map['thumbnail_url'] = Variable<String>(thumbnailUrl);
    }
    return map;
  }

  CachedOrdersCompanion toCompanion(bool nullToAbsent) {
    return CachedOrdersCompanion(
      id: Value(id),
      status: Value(status),
      subtotal: Value(subtotal),
      discountValue: Value(discountValue),
      shippingCost: Value(shippingCost),
      total: Value(total),
      createdAt: Value(createdAt),
      itemCount: Value(itemCount),
      thumbnailUrl: thumbnailUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(thumbnailUrl),
    );
  }

  factory CachedOrder.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedOrder(
      id: serializer.fromJson<String>(json['id']),
      status: serializer.fromJson<String>(json['status']),
      subtotal: serializer.fromJson<int>(json['subtotal']),
      discountValue: serializer.fromJson<int>(json['discountValue']),
      shippingCost: serializer.fromJson<int>(json['shippingCost']),
      total: serializer.fromJson<int>(json['total']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      itemCount: serializer.fromJson<int>(json['itemCount']),
      thumbnailUrl: serializer.fromJson<String?>(json['thumbnailUrl']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'status': serializer.toJson<String>(status),
      'subtotal': serializer.toJson<int>(subtotal),
      'discountValue': serializer.toJson<int>(discountValue),
      'shippingCost': serializer.toJson<int>(shippingCost),
      'total': serializer.toJson<int>(total),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'itemCount': serializer.toJson<int>(itemCount),
      'thumbnailUrl': serializer.toJson<String?>(thumbnailUrl),
    };
  }

  CachedOrder copyWith({
    String? id,
    String? status,
    int? subtotal,
    int? discountValue,
    int? shippingCost,
    int? total,
    DateTime? createdAt,
    int? itemCount,
    Value<String?> thumbnailUrl = const Value.absent(),
  }) => CachedOrder(
    id: id ?? this.id,
    status: status ?? this.status,
    subtotal: subtotal ?? this.subtotal,
    discountValue: discountValue ?? this.discountValue,
    shippingCost: shippingCost ?? this.shippingCost,
    total: total ?? this.total,
    createdAt: createdAt ?? this.createdAt,
    itemCount: itemCount ?? this.itemCount,
    thumbnailUrl: thumbnailUrl.present ? thumbnailUrl.value : this.thumbnailUrl,
  );
  CachedOrder copyWithCompanion(CachedOrdersCompanion data) {
    return CachedOrder(
      id: data.id.present ? data.id.value : this.id,
      status: data.status.present ? data.status.value : this.status,
      subtotal: data.subtotal.present ? data.subtotal.value : this.subtotal,
      discountValue: data.discountValue.present
          ? data.discountValue.value
          : this.discountValue,
      shippingCost: data.shippingCost.present
          ? data.shippingCost.value
          : this.shippingCost,
      total: data.total.present ? data.total.value : this.total,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      itemCount: data.itemCount.present ? data.itemCount.value : this.itemCount,
      thumbnailUrl: data.thumbnailUrl.present
          ? data.thumbnailUrl.value
          : this.thumbnailUrl,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedOrder(')
          ..write('id: $id, ')
          ..write('status: $status, ')
          ..write('subtotal: $subtotal, ')
          ..write('discountValue: $discountValue, ')
          ..write('shippingCost: $shippingCost, ')
          ..write('total: $total, ')
          ..write('createdAt: $createdAt, ')
          ..write('itemCount: $itemCount, ')
          ..write('thumbnailUrl: $thumbnailUrl')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    status,
    subtotal,
    discountValue,
    shippingCost,
    total,
    createdAt,
    itemCount,
    thumbnailUrl,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedOrder &&
          other.id == this.id &&
          other.status == this.status &&
          other.subtotal == this.subtotal &&
          other.discountValue == this.discountValue &&
          other.shippingCost == this.shippingCost &&
          other.total == this.total &&
          other.createdAt == this.createdAt &&
          other.itemCount == this.itemCount &&
          other.thumbnailUrl == this.thumbnailUrl);
}

class CachedOrdersCompanion extends UpdateCompanion<CachedOrder> {
  final Value<String> id;
  final Value<String> status;
  final Value<int> subtotal;
  final Value<int> discountValue;
  final Value<int> shippingCost;
  final Value<int> total;
  final Value<DateTime> createdAt;
  final Value<int> itemCount;
  final Value<String?> thumbnailUrl;
  final Value<int> rowid;
  const CachedOrdersCompanion({
    this.id = const Value.absent(),
    this.status = const Value.absent(),
    this.subtotal = const Value.absent(),
    this.discountValue = const Value.absent(),
    this.shippingCost = const Value.absent(),
    this.total = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.itemCount = const Value.absent(),
    this.thumbnailUrl = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedOrdersCompanion.insert({
    required String id,
    required String status,
    required int subtotal,
    required int discountValue,
    required int shippingCost,
    required int total,
    required DateTime createdAt,
    required int itemCount,
    this.thumbnailUrl = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       status = Value(status),
       subtotal = Value(subtotal),
       discountValue = Value(discountValue),
       shippingCost = Value(shippingCost),
       total = Value(total),
       createdAt = Value(createdAt),
       itemCount = Value(itemCount);
  static Insertable<CachedOrder> custom({
    Expression<String>? id,
    Expression<String>? status,
    Expression<int>? subtotal,
    Expression<int>? discountValue,
    Expression<int>? shippingCost,
    Expression<int>? total,
    Expression<DateTime>? createdAt,
    Expression<int>? itemCount,
    Expression<String>? thumbnailUrl,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (status != null) 'status': status,
      if (subtotal != null) 'subtotal': subtotal,
      if (discountValue != null) 'discount_value': discountValue,
      if (shippingCost != null) 'shipping_cost': shippingCost,
      if (total != null) 'total': total,
      if (createdAt != null) 'created_at': createdAt,
      if (itemCount != null) 'item_count': itemCount,
      if (thumbnailUrl != null) 'thumbnail_url': thumbnailUrl,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedOrdersCompanion copyWith({
    Value<String>? id,
    Value<String>? status,
    Value<int>? subtotal,
    Value<int>? discountValue,
    Value<int>? shippingCost,
    Value<int>? total,
    Value<DateTime>? createdAt,
    Value<int>? itemCount,
    Value<String?>? thumbnailUrl,
    Value<int>? rowid,
  }) {
    return CachedOrdersCompanion(
      id: id ?? this.id,
      status: status ?? this.status,
      subtotal: subtotal ?? this.subtotal,
      discountValue: discountValue ?? this.discountValue,
      shippingCost: shippingCost ?? this.shippingCost,
      total: total ?? this.total,
      createdAt: createdAt ?? this.createdAt,
      itemCount: itemCount ?? this.itemCount,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (subtotal.present) {
      map['subtotal'] = Variable<int>(subtotal.value);
    }
    if (discountValue.present) {
      map['discount_value'] = Variable<int>(discountValue.value);
    }
    if (shippingCost.present) {
      map['shipping_cost'] = Variable<int>(shippingCost.value);
    }
    if (total.present) {
      map['total'] = Variable<int>(total.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (itemCount.present) {
      map['item_count'] = Variable<int>(itemCount.value);
    }
    if (thumbnailUrl.present) {
      map['thumbnail_url'] = Variable<String>(thumbnailUrl.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedOrdersCompanion(')
          ..write('id: $id, ')
          ..write('status: $status, ')
          ..write('subtotal: $subtotal, ')
          ..write('discountValue: $discountValue, ')
          ..write('shippingCost: $shippingCost, ')
          ..write('total: $total, ')
          ..write('createdAt: $createdAt, ')
          ..write('itemCount: $itemCount, ')
          ..write('thumbnailUrl: $thumbnailUrl, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CachedHomeSectionsTable extends CachedHomeSections
    with TableInfo<$CachedHomeSectionsTable, CachedHomeSection> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedHomeSectionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _sectionMeta = const VerificationMeta(
    'section',
  );
  @override
  late final GeneratedColumn<String> section = GeneratedColumn<String>(
    'section',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _productIdMeta = const VerificationMeta(
    'productId',
  );
  @override
  late final GeneratedColumn<String> productId = GeneratedColumn<String>(
    'product_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _subCategoryIdMeta = const VerificationMeta(
    'subCategoryId',
  );
  @override
  late final GeneratedColumn<String> subCategoryId = GeneratedColumn<String>(
    'sub_category_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isTrendingMeta = const VerificationMeta(
    'isTrending',
  );
  @override
  late final GeneratedColumn<bool> isTrending = GeneratedColumn<bool>(
    'is_trending',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_trending" IN (0, 1))',
    ),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _variantIdMeta = const VerificationMeta(
    'variantId',
  );
  @override
  late final GeneratedColumn<String> variantId = GeneratedColumn<String>(
    'variant_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _variantNameMeta = const VerificationMeta(
    'variantName',
  );
  @override
  late final GeneratedColumn<String> variantName = GeneratedColumn<String>(
    'variant_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _originalPriceMeta = const VerificationMeta(
    'originalPrice',
  );
  @override
  late final GeneratedColumn<int> originalPrice = GeneratedColumn<int>(
    'original_price',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _currentPriceMeta = const VerificationMeta(
    'currentPrice',
  );
  @override
  late final GeneratedColumn<int> currentPrice = GeneratedColumn<int>(
    'current_price',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _stockQtyMeta = const VerificationMeta(
    'stockQty',
  );
  @override
  late final GeneratedColumn<int> stockQty = GeneratedColumn<int>(
    'stock_qty',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _imageUrlMeta = const VerificationMeta(
    'imageUrl',
  );
  @override
  late final GeneratedColumn<String> imageUrl = GeneratedColumn<String>(
    'image_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    section,
    productId,
    subCategoryId,
    name,
    isTrending,
    createdAt,
    sortOrder,
    variantId,
    variantName,
    originalPrice,
    currentPrice,
    stockQty,
    imageUrl,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_home_sections';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedHomeSection> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('section')) {
      context.handle(
        _sectionMeta,
        section.isAcceptableOrUnknown(data['section']!, _sectionMeta),
      );
    } else if (isInserting) {
      context.missing(_sectionMeta);
    }
    if (data.containsKey('product_id')) {
      context.handle(
        _productIdMeta,
        productId.isAcceptableOrUnknown(data['product_id']!, _productIdMeta),
      );
    } else if (isInserting) {
      context.missing(_productIdMeta);
    }
    if (data.containsKey('sub_category_id')) {
      context.handle(
        _subCategoryIdMeta,
        subCategoryId.isAcceptableOrUnknown(
          data['sub_category_id']!,
          _subCategoryIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_subCategoryIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('is_trending')) {
      context.handle(
        _isTrendingMeta,
        isTrending.isAcceptableOrUnknown(data['is_trending']!, _isTrendingMeta),
      );
    } else if (isInserting) {
      context.missing(_isTrendingMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    } else if (isInserting) {
      context.missing(_sortOrderMeta);
    }
    if (data.containsKey('variant_id')) {
      context.handle(
        _variantIdMeta,
        variantId.isAcceptableOrUnknown(data['variant_id']!, _variantIdMeta),
      );
    }
    if (data.containsKey('variant_name')) {
      context.handle(
        _variantNameMeta,
        variantName.isAcceptableOrUnknown(
          data['variant_name']!,
          _variantNameMeta,
        ),
      );
    }
    if (data.containsKey('original_price')) {
      context.handle(
        _originalPriceMeta,
        originalPrice.isAcceptableOrUnknown(
          data['original_price']!,
          _originalPriceMeta,
        ),
      );
    }
    if (data.containsKey('current_price')) {
      context.handle(
        _currentPriceMeta,
        currentPrice.isAcceptableOrUnknown(
          data['current_price']!,
          _currentPriceMeta,
        ),
      );
    }
    if (data.containsKey('stock_qty')) {
      context.handle(
        _stockQtyMeta,
        stockQty.isAcceptableOrUnknown(data['stock_qty']!, _stockQtyMeta),
      );
    }
    if (data.containsKey('image_url')) {
      context.handle(
        _imageUrlMeta,
        imageUrl.isAcceptableOrUnknown(data['image_url']!, _imageUrlMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {section, productId};
  @override
  CachedHomeSection map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedHomeSection(
      section: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}section'],
      )!,
      productId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_id'],
      )!,
      subCategoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sub_category_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      isTrending: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_trending'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      variantId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}variant_id'],
      ),
      variantName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}variant_name'],
      ),
      originalPrice: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}original_price'],
      ),
      currentPrice: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}current_price'],
      ),
      stockQty: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}stock_qty'],
      ),
      imageUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_url'],
      ),
    );
  }

  @override
  $CachedHomeSectionsTable createAlias(String alias) {
    return $CachedHomeSectionsTable(attachedDatabase, alias);
  }
}

class CachedHomeSection extends DataClass
    implements Insertable<CachedHomeSection> {
  final String section;
  final String productId;
  final String subCategoryId;
  final String name;
  final bool isTrending;
  final DateTime createdAt;
  final int sortOrder;
  final String? variantId;
  final String? variantName;
  final int? originalPrice;
  final int? currentPrice;
  final int? stockQty;
  final String? imageUrl;
  const CachedHomeSection({
    required this.section,
    required this.productId,
    required this.subCategoryId,
    required this.name,
    required this.isTrending,
    required this.createdAt,
    required this.sortOrder,
    this.variantId,
    this.variantName,
    this.originalPrice,
    this.currentPrice,
    this.stockQty,
    this.imageUrl,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['section'] = Variable<String>(section);
    map['product_id'] = Variable<String>(productId);
    map['sub_category_id'] = Variable<String>(subCategoryId);
    map['name'] = Variable<String>(name);
    map['is_trending'] = Variable<bool>(isTrending);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['sort_order'] = Variable<int>(sortOrder);
    if (!nullToAbsent || variantId != null) {
      map['variant_id'] = Variable<String>(variantId);
    }
    if (!nullToAbsent || variantName != null) {
      map['variant_name'] = Variable<String>(variantName);
    }
    if (!nullToAbsent || originalPrice != null) {
      map['original_price'] = Variable<int>(originalPrice);
    }
    if (!nullToAbsent || currentPrice != null) {
      map['current_price'] = Variable<int>(currentPrice);
    }
    if (!nullToAbsent || stockQty != null) {
      map['stock_qty'] = Variable<int>(stockQty);
    }
    if (!nullToAbsent || imageUrl != null) {
      map['image_url'] = Variable<String>(imageUrl);
    }
    return map;
  }

  CachedHomeSectionsCompanion toCompanion(bool nullToAbsent) {
    return CachedHomeSectionsCompanion(
      section: Value(section),
      productId: Value(productId),
      subCategoryId: Value(subCategoryId),
      name: Value(name),
      isTrending: Value(isTrending),
      createdAt: Value(createdAt),
      sortOrder: Value(sortOrder),
      variantId: variantId == null && nullToAbsent
          ? const Value.absent()
          : Value(variantId),
      variantName: variantName == null && nullToAbsent
          ? const Value.absent()
          : Value(variantName),
      originalPrice: originalPrice == null && nullToAbsent
          ? const Value.absent()
          : Value(originalPrice),
      currentPrice: currentPrice == null && nullToAbsent
          ? const Value.absent()
          : Value(currentPrice),
      stockQty: stockQty == null && nullToAbsent
          ? const Value.absent()
          : Value(stockQty),
      imageUrl: imageUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(imageUrl),
    );
  }

  factory CachedHomeSection.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedHomeSection(
      section: serializer.fromJson<String>(json['section']),
      productId: serializer.fromJson<String>(json['productId']),
      subCategoryId: serializer.fromJson<String>(json['subCategoryId']),
      name: serializer.fromJson<String>(json['name']),
      isTrending: serializer.fromJson<bool>(json['isTrending']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      variantId: serializer.fromJson<String?>(json['variantId']),
      variantName: serializer.fromJson<String?>(json['variantName']),
      originalPrice: serializer.fromJson<int?>(json['originalPrice']),
      currentPrice: serializer.fromJson<int?>(json['currentPrice']),
      stockQty: serializer.fromJson<int?>(json['stockQty']),
      imageUrl: serializer.fromJson<String?>(json['imageUrl']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'section': serializer.toJson<String>(section),
      'productId': serializer.toJson<String>(productId),
      'subCategoryId': serializer.toJson<String>(subCategoryId),
      'name': serializer.toJson<String>(name),
      'isTrending': serializer.toJson<bool>(isTrending),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'variantId': serializer.toJson<String?>(variantId),
      'variantName': serializer.toJson<String?>(variantName),
      'originalPrice': serializer.toJson<int?>(originalPrice),
      'currentPrice': serializer.toJson<int?>(currentPrice),
      'stockQty': serializer.toJson<int?>(stockQty),
      'imageUrl': serializer.toJson<String?>(imageUrl),
    };
  }

  CachedHomeSection copyWith({
    String? section,
    String? productId,
    String? subCategoryId,
    String? name,
    bool? isTrending,
    DateTime? createdAt,
    int? sortOrder,
    Value<String?> variantId = const Value.absent(),
    Value<String?> variantName = const Value.absent(),
    Value<int?> originalPrice = const Value.absent(),
    Value<int?> currentPrice = const Value.absent(),
    Value<int?> stockQty = const Value.absent(),
    Value<String?> imageUrl = const Value.absent(),
  }) => CachedHomeSection(
    section: section ?? this.section,
    productId: productId ?? this.productId,
    subCategoryId: subCategoryId ?? this.subCategoryId,
    name: name ?? this.name,
    isTrending: isTrending ?? this.isTrending,
    createdAt: createdAt ?? this.createdAt,
    sortOrder: sortOrder ?? this.sortOrder,
    variantId: variantId.present ? variantId.value : this.variantId,
    variantName: variantName.present ? variantName.value : this.variantName,
    originalPrice: originalPrice.present
        ? originalPrice.value
        : this.originalPrice,
    currentPrice: currentPrice.present ? currentPrice.value : this.currentPrice,
    stockQty: stockQty.present ? stockQty.value : this.stockQty,
    imageUrl: imageUrl.present ? imageUrl.value : this.imageUrl,
  );
  CachedHomeSection copyWithCompanion(CachedHomeSectionsCompanion data) {
    return CachedHomeSection(
      section: data.section.present ? data.section.value : this.section,
      productId: data.productId.present ? data.productId.value : this.productId,
      subCategoryId: data.subCategoryId.present
          ? data.subCategoryId.value
          : this.subCategoryId,
      name: data.name.present ? data.name.value : this.name,
      isTrending: data.isTrending.present
          ? data.isTrending.value
          : this.isTrending,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      variantId: data.variantId.present ? data.variantId.value : this.variantId,
      variantName: data.variantName.present
          ? data.variantName.value
          : this.variantName,
      originalPrice: data.originalPrice.present
          ? data.originalPrice.value
          : this.originalPrice,
      currentPrice: data.currentPrice.present
          ? data.currentPrice.value
          : this.currentPrice,
      stockQty: data.stockQty.present ? data.stockQty.value : this.stockQty,
      imageUrl: data.imageUrl.present ? data.imageUrl.value : this.imageUrl,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedHomeSection(')
          ..write('section: $section, ')
          ..write('productId: $productId, ')
          ..write('subCategoryId: $subCategoryId, ')
          ..write('name: $name, ')
          ..write('isTrending: $isTrending, ')
          ..write('createdAt: $createdAt, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('variantId: $variantId, ')
          ..write('variantName: $variantName, ')
          ..write('originalPrice: $originalPrice, ')
          ..write('currentPrice: $currentPrice, ')
          ..write('stockQty: $stockQty, ')
          ..write('imageUrl: $imageUrl')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    section,
    productId,
    subCategoryId,
    name,
    isTrending,
    createdAt,
    sortOrder,
    variantId,
    variantName,
    originalPrice,
    currentPrice,
    stockQty,
    imageUrl,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedHomeSection &&
          other.section == this.section &&
          other.productId == this.productId &&
          other.subCategoryId == this.subCategoryId &&
          other.name == this.name &&
          other.isTrending == this.isTrending &&
          other.createdAt == this.createdAt &&
          other.sortOrder == this.sortOrder &&
          other.variantId == this.variantId &&
          other.variantName == this.variantName &&
          other.originalPrice == this.originalPrice &&
          other.currentPrice == this.currentPrice &&
          other.stockQty == this.stockQty &&
          other.imageUrl == this.imageUrl);
}

class CachedHomeSectionsCompanion extends UpdateCompanion<CachedHomeSection> {
  final Value<String> section;
  final Value<String> productId;
  final Value<String> subCategoryId;
  final Value<String> name;
  final Value<bool> isTrending;
  final Value<DateTime> createdAt;
  final Value<int> sortOrder;
  final Value<String?> variantId;
  final Value<String?> variantName;
  final Value<int?> originalPrice;
  final Value<int?> currentPrice;
  final Value<int?> stockQty;
  final Value<String?> imageUrl;
  final Value<int> rowid;
  const CachedHomeSectionsCompanion({
    this.section = const Value.absent(),
    this.productId = const Value.absent(),
    this.subCategoryId = const Value.absent(),
    this.name = const Value.absent(),
    this.isTrending = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.variantId = const Value.absent(),
    this.variantName = const Value.absent(),
    this.originalPrice = const Value.absent(),
    this.currentPrice = const Value.absent(),
    this.stockQty = const Value.absent(),
    this.imageUrl = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedHomeSectionsCompanion.insert({
    required String section,
    required String productId,
    required String subCategoryId,
    required String name,
    required bool isTrending,
    required DateTime createdAt,
    required int sortOrder,
    this.variantId = const Value.absent(),
    this.variantName = const Value.absent(),
    this.originalPrice = const Value.absent(),
    this.currentPrice = const Value.absent(),
    this.stockQty = const Value.absent(),
    this.imageUrl = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : section = Value(section),
       productId = Value(productId),
       subCategoryId = Value(subCategoryId),
       name = Value(name),
       isTrending = Value(isTrending),
       createdAt = Value(createdAt),
       sortOrder = Value(sortOrder);
  static Insertable<CachedHomeSection> custom({
    Expression<String>? section,
    Expression<String>? productId,
    Expression<String>? subCategoryId,
    Expression<String>? name,
    Expression<bool>? isTrending,
    Expression<DateTime>? createdAt,
    Expression<int>? sortOrder,
    Expression<String>? variantId,
    Expression<String>? variantName,
    Expression<int>? originalPrice,
    Expression<int>? currentPrice,
    Expression<int>? stockQty,
    Expression<String>? imageUrl,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (section != null) 'section': section,
      if (productId != null) 'product_id': productId,
      if (subCategoryId != null) 'sub_category_id': subCategoryId,
      if (name != null) 'name': name,
      if (isTrending != null) 'is_trending': isTrending,
      if (createdAt != null) 'created_at': createdAt,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (variantId != null) 'variant_id': variantId,
      if (variantName != null) 'variant_name': variantName,
      if (originalPrice != null) 'original_price': originalPrice,
      if (currentPrice != null) 'current_price': currentPrice,
      if (stockQty != null) 'stock_qty': stockQty,
      if (imageUrl != null) 'image_url': imageUrl,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedHomeSectionsCompanion copyWith({
    Value<String>? section,
    Value<String>? productId,
    Value<String>? subCategoryId,
    Value<String>? name,
    Value<bool>? isTrending,
    Value<DateTime>? createdAt,
    Value<int>? sortOrder,
    Value<String?>? variantId,
    Value<String?>? variantName,
    Value<int?>? originalPrice,
    Value<int?>? currentPrice,
    Value<int?>? stockQty,
    Value<String?>? imageUrl,
    Value<int>? rowid,
  }) {
    return CachedHomeSectionsCompanion(
      section: section ?? this.section,
      productId: productId ?? this.productId,
      subCategoryId: subCategoryId ?? this.subCategoryId,
      name: name ?? this.name,
      isTrending: isTrending ?? this.isTrending,
      createdAt: createdAt ?? this.createdAt,
      sortOrder: sortOrder ?? this.sortOrder,
      variantId: variantId ?? this.variantId,
      variantName: variantName ?? this.variantName,
      originalPrice: originalPrice ?? this.originalPrice,
      currentPrice: currentPrice ?? this.currentPrice,
      stockQty: stockQty ?? this.stockQty,
      imageUrl: imageUrl ?? this.imageUrl,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (section.present) {
      map['section'] = Variable<String>(section.value);
    }
    if (productId.present) {
      map['product_id'] = Variable<String>(productId.value);
    }
    if (subCategoryId.present) {
      map['sub_category_id'] = Variable<String>(subCategoryId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (isTrending.present) {
      map['is_trending'] = Variable<bool>(isTrending.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (variantId.present) {
      map['variant_id'] = Variable<String>(variantId.value);
    }
    if (variantName.present) {
      map['variant_name'] = Variable<String>(variantName.value);
    }
    if (originalPrice.present) {
      map['original_price'] = Variable<int>(originalPrice.value);
    }
    if (currentPrice.present) {
      map['current_price'] = Variable<int>(currentPrice.value);
    }
    if (stockQty.present) {
      map['stock_qty'] = Variable<int>(stockQty.value);
    }
    if (imageUrl.present) {
      map['image_url'] = Variable<String>(imageUrl.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedHomeSectionsCompanion(')
          ..write('section: $section, ')
          ..write('productId: $productId, ')
          ..write('subCategoryId: $subCategoryId, ')
          ..write('name: $name, ')
          ..write('isTrending: $isTrending, ')
          ..write('createdAt: $createdAt, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('variantId: $variantId, ')
          ..write('variantName: $variantName, ')
          ..write('originalPrice: $originalPrice, ')
          ..write('currentPrice: $currentPrice, ')
          ..write('stockQty: $stockQty, ')
          ..write('imageUrl: $imageUrl, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $AppSettingsTable appSettings = $AppSettingsTable(this);
  late final $CachedCategoriesTable cachedCategories = $CachedCategoriesTable(
    this,
  );
  late final $CachedSubCategoriesTable cachedSubCategories =
      $CachedSubCategoriesTable(this);
  late final $CachedProductsTable cachedProducts = $CachedProductsTable(this);
  late final $CachedWishlistItemsTable cachedWishlistItems =
      $CachedWishlistItemsTable(this);
  late final $CachedCartItemsTable cachedCartItems = $CachedCartItemsTable(
    this,
  );
  late final $CachedAddressesTable cachedAddresses = $CachedAddressesTable(
    this,
  );
  late final $CachedOrdersTable cachedOrders = $CachedOrdersTable(this);
  late final $CachedHomeSectionsTable cachedHomeSections =
      $CachedHomeSectionsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    appSettings,
    cachedCategories,
    cachedSubCategories,
    cachedProducts,
    cachedWishlistItems,
    cachedCartItems,
    cachedAddresses,
    cachedOrders,
    cachedHomeSections,
  ];
}

typedef $$AppSettingsTableCreateCompanionBuilder =
    AppSettingsCompanion Function({
      required String key,
      required String value,
      Value<int> rowid,
    });
typedef $$AppSettingsTableUpdateCompanionBuilder =
    AppSettingsCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<int> rowid,
    });

class $$AppSettingsTableFilterComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AppSettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AppSettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$AppSettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AppSettingsTable,
          AppSetting,
          $$AppSettingsTableFilterComposer,
          $$AppSettingsTableOrderingComposer,
          $$AppSettingsTableAnnotationComposer,
          $$AppSettingsTableCreateCompanionBuilder,
          $$AppSettingsTableUpdateCompanionBuilder,
          (
            AppSetting,
            BaseReferences<_$AppDatabase, $AppSettingsTable, AppSetting>,
          ),
          AppSetting,
          PrefetchHooks Function()
        > {
  $$AppSettingsTableTableManager(_$AppDatabase db, $AppSettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AppSettingsCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => AppSettingsCompanion.insert(
                key: key,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AppSettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AppSettingsTable,
      AppSetting,
      $$AppSettingsTableFilterComposer,
      $$AppSettingsTableOrderingComposer,
      $$AppSettingsTableAnnotationComposer,
      $$AppSettingsTableCreateCompanionBuilder,
      $$AppSettingsTableUpdateCompanionBuilder,
      (
        AppSetting,
        BaseReferences<_$AppDatabase, $AppSettingsTable, AppSetting>,
      ),
      AppSetting,
      PrefetchHooks Function()
    >;
typedef $$CachedCategoriesTableCreateCompanionBuilder =
    CachedCategoriesCompanion Function({
      required String id,
      required String name,
      Value<String?> imageUrl,
      required int sortOrder,
      required int subCategoryCount,
      Value<int> rowid,
    });
typedef $$CachedCategoriesTableUpdateCompanionBuilder =
    CachedCategoriesCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String?> imageUrl,
      Value<int> sortOrder,
      Value<int> subCategoryCount,
      Value<int> rowid,
    });

class $$CachedCategoriesTableFilterComposer
    extends Composer<_$AppDatabase, $CachedCategoriesTable> {
  $$CachedCategoriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get imageUrl => $composableBuilder(
    column: $table.imageUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get subCategoryCount => $composableBuilder(
    column: $table.subCategoryCount,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedCategoriesTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedCategoriesTable> {
  $$CachedCategoriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imageUrl => $composableBuilder(
    column: $table.imageUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get subCategoryCount => $composableBuilder(
    column: $table.subCategoryCount,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedCategoriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedCategoriesTable> {
  $$CachedCategoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get imageUrl =>
      $composableBuilder(column: $table.imageUrl, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<int> get subCategoryCount => $composableBuilder(
    column: $table.subCategoryCount,
    builder: (column) => column,
  );
}

class $$CachedCategoriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedCategoriesTable,
          CachedCategory,
          $$CachedCategoriesTableFilterComposer,
          $$CachedCategoriesTableOrderingComposer,
          $$CachedCategoriesTableAnnotationComposer,
          $$CachedCategoriesTableCreateCompanionBuilder,
          $$CachedCategoriesTableUpdateCompanionBuilder,
          (
            CachedCategory,
            BaseReferences<
              _$AppDatabase,
              $CachedCategoriesTable,
              CachedCategory
            >,
          ),
          CachedCategory,
          PrefetchHooks Function()
        > {
  $$CachedCategoriesTableTableManager(
    _$AppDatabase db,
    $CachedCategoriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedCategoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedCategoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedCategoriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> imageUrl = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> subCategoryCount = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedCategoriesCompanion(
                id: id,
                name: name,
                imageUrl: imageUrl,
                sortOrder: sortOrder,
                subCategoryCount: subCategoryCount,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<String?> imageUrl = const Value.absent(),
                required int sortOrder,
                required int subCategoryCount,
                Value<int> rowid = const Value.absent(),
              }) => CachedCategoriesCompanion.insert(
                id: id,
                name: name,
                imageUrl: imageUrl,
                sortOrder: sortOrder,
                subCategoryCount: subCategoryCount,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedCategoriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedCategoriesTable,
      CachedCategory,
      $$CachedCategoriesTableFilterComposer,
      $$CachedCategoriesTableOrderingComposer,
      $$CachedCategoriesTableAnnotationComposer,
      $$CachedCategoriesTableCreateCompanionBuilder,
      $$CachedCategoriesTableUpdateCompanionBuilder,
      (
        CachedCategory,
        BaseReferences<_$AppDatabase, $CachedCategoriesTable, CachedCategory>,
      ),
      CachedCategory,
      PrefetchHooks Function()
    >;
typedef $$CachedSubCategoriesTableCreateCompanionBuilder =
    CachedSubCategoriesCompanion Function({
      required String id,
      required String categoryId,
      required String name,
      Value<String?> imageUrl,
      required int sortOrder,
      Value<int> rowid,
    });
typedef $$CachedSubCategoriesTableUpdateCompanionBuilder =
    CachedSubCategoriesCompanion Function({
      Value<String> id,
      Value<String> categoryId,
      Value<String> name,
      Value<String?> imageUrl,
      Value<int> sortOrder,
      Value<int> rowid,
    });

class $$CachedSubCategoriesTableFilterComposer
    extends Composer<_$AppDatabase, $CachedSubCategoriesTable> {
  $$CachedSubCategoriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get imageUrl => $composableBuilder(
    column: $table.imageUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedSubCategoriesTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedSubCategoriesTable> {
  $$CachedSubCategoriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imageUrl => $composableBuilder(
    column: $table.imageUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedSubCategoriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedSubCategoriesTable> {
  $$CachedSubCategoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get imageUrl =>
      $composableBuilder(column: $table.imageUrl, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);
}

class $$CachedSubCategoriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedSubCategoriesTable,
          CachedSubCategory,
          $$CachedSubCategoriesTableFilterComposer,
          $$CachedSubCategoriesTableOrderingComposer,
          $$CachedSubCategoriesTableAnnotationComposer,
          $$CachedSubCategoriesTableCreateCompanionBuilder,
          $$CachedSubCategoriesTableUpdateCompanionBuilder,
          (
            CachedSubCategory,
            BaseReferences<
              _$AppDatabase,
              $CachedSubCategoriesTable,
              CachedSubCategory
            >,
          ),
          CachedSubCategory,
          PrefetchHooks Function()
        > {
  $$CachedSubCategoriesTableTableManager(
    _$AppDatabase db,
    $CachedSubCategoriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedSubCategoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedSubCategoriesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$CachedSubCategoriesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> categoryId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> imageUrl = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedSubCategoriesCompanion(
                id: id,
                categoryId: categoryId,
                name: name,
                imageUrl: imageUrl,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String categoryId,
                required String name,
                Value<String?> imageUrl = const Value.absent(),
                required int sortOrder,
                Value<int> rowid = const Value.absent(),
              }) => CachedSubCategoriesCompanion.insert(
                id: id,
                categoryId: categoryId,
                name: name,
                imageUrl: imageUrl,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedSubCategoriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedSubCategoriesTable,
      CachedSubCategory,
      $$CachedSubCategoriesTableFilterComposer,
      $$CachedSubCategoriesTableOrderingComposer,
      $$CachedSubCategoriesTableAnnotationComposer,
      $$CachedSubCategoriesTableCreateCompanionBuilder,
      $$CachedSubCategoriesTableUpdateCompanionBuilder,
      (
        CachedSubCategory,
        BaseReferences<
          _$AppDatabase,
          $CachedSubCategoriesTable,
          CachedSubCategory
        >,
      ),
      CachedSubCategory,
      PrefetchHooks Function()
    >;
typedef $$CachedProductsTableCreateCompanionBuilder =
    CachedProductsCompanion Function({
      required String id,
      required String subCategoryId,
      required String categoryId,
      required String name,
      Value<String?> description,
      required bool isTrending,
      required DateTime createdAt,
      required int sortOrder,
      Value<String?> variantId,
      Value<String?> variantName,
      Value<int?> originalPrice,
      Value<int?> currentPrice,
      Value<int?> stockQty,
      Value<String?> imageUrl,
      Value<int> rowid,
    });
typedef $$CachedProductsTableUpdateCompanionBuilder =
    CachedProductsCompanion Function({
      Value<String> id,
      Value<String> subCategoryId,
      Value<String> categoryId,
      Value<String> name,
      Value<String?> description,
      Value<bool> isTrending,
      Value<DateTime> createdAt,
      Value<int> sortOrder,
      Value<String?> variantId,
      Value<String?> variantName,
      Value<int?> originalPrice,
      Value<int?> currentPrice,
      Value<int?> stockQty,
      Value<String?> imageUrl,
      Value<int> rowid,
    });

class $$CachedProductsTableFilterComposer
    extends Composer<_$AppDatabase, $CachedProductsTable> {
  $$CachedProductsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get subCategoryId => $composableBuilder(
    column: $table.subCategoryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isTrending => $composableBuilder(
    column: $table.isTrending,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get variantId => $composableBuilder(
    column: $table.variantId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get variantName => $composableBuilder(
    column: $table.variantName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get originalPrice => $composableBuilder(
    column: $table.originalPrice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get currentPrice => $composableBuilder(
    column: $table.currentPrice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get stockQty => $composableBuilder(
    column: $table.stockQty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get imageUrl => $composableBuilder(
    column: $table.imageUrl,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedProductsTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedProductsTable> {
  $$CachedProductsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get subCategoryId => $composableBuilder(
    column: $table.subCategoryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isTrending => $composableBuilder(
    column: $table.isTrending,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get variantId => $composableBuilder(
    column: $table.variantId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get variantName => $composableBuilder(
    column: $table.variantName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get originalPrice => $composableBuilder(
    column: $table.originalPrice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get currentPrice => $composableBuilder(
    column: $table.currentPrice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get stockQty => $composableBuilder(
    column: $table.stockQty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imageUrl => $composableBuilder(
    column: $table.imageUrl,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedProductsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedProductsTable> {
  $$CachedProductsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get subCategoryId => $composableBuilder(
    column: $table.subCategoryId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isTrending => $composableBuilder(
    column: $table.isTrending,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<String> get variantId =>
      $composableBuilder(column: $table.variantId, builder: (column) => column);

  GeneratedColumn<String> get variantName => $composableBuilder(
    column: $table.variantName,
    builder: (column) => column,
  );

  GeneratedColumn<int> get originalPrice => $composableBuilder(
    column: $table.originalPrice,
    builder: (column) => column,
  );

  GeneratedColumn<int> get currentPrice => $composableBuilder(
    column: $table.currentPrice,
    builder: (column) => column,
  );

  GeneratedColumn<int> get stockQty =>
      $composableBuilder(column: $table.stockQty, builder: (column) => column);

  GeneratedColumn<String> get imageUrl =>
      $composableBuilder(column: $table.imageUrl, builder: (column) => column);
}

class $$CachedProductsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedProductsTable,
          CachedProduct,
          $$CachedProductsTableFilterComposer,
          $$CachedProductsTableOrderingComposer,
          $$CachedProductsTableAnnotationComposer,
          $$CachedProductsTableCreateCompanionBuilder,
          $$CachedProductsTableUpdateCompanionBuilder,
          (
            CachedProduct,
            BaseReferences<_$AppDatabase, $CachedProductsTable, CachedProduct>,
          ),
          CachedProduct,
          PrefetchHooks Function()
        > {
  $$CachedProductsTableTableManager(
    _$AppDatabase db,
    $CachedProductsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedProductsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedProductsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedProductsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> subCategoryId = const Value.absent(),
                Value<String> categoryId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<bool> isTrending = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<String?> variantId = const Value.absent(),
                Value<String?> variantName = const Value.absent(),
                Value<int?> originalPrice = const Value.absent(),
                Value<int?> currentPrice = const Value.absent(),
                Value<int?> stockQty = const Value.absent(),
                Value<String?> imageUrl = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedProductsCompanion(
                id: id,
                subCategoryId: subCategoryId,
                categoryId: categoryId,
                name: name,
                description: description,
                isTrending: isTrending,
                createdAt: createdAt,
                sortOrder: sortOrder,
                variantId: variantId,
                variantName: variantName,
                originalPrice: originalPrice,
                currentPrice: currentPrice,
                stockQty: stockQty,
                imageUrl: imageUrl,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String subCategoryId,
                required String categoryId,
                required String name,
                Value<String?> description = const Value.absent(),
                required bool isTrending,
                required DateTime createdAt,
                required int sortOrder,
                Value<String?> variantId = const Value.absent(),
                Value<String?> variantName = const Value.absent(),
                Value<int?> originalPrice = const Value.absent(),
                Value<int?> currentPrice = const Value.absent(),
                Value<int?> stockQty = const Value.absent(),
                Value<String?> imageUrl = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedProductsCompanion.insert(
                id: id,
                subCategoryId: subCategoryId,
                categoryId: categoryId,
                name: name,
                description: description,
                isTrending: isTrending,
                createdAt: createdAt,
                sortOrder: sortOrder,
                variantId: variantId,
                variantName: variantName,
                originalPrice: originalPrice,
                currentPrice: currentPrice,
                stockQty: stockQty,
                imageUrl: imageUrl,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedProductsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedProductsTable,
      CachedProduct,
      $$CachedProductsTableFilterComposer,
      $$CachedProductsTableOrderingComposer,
      $$CachedProductsTableAnnotationComposer,
      $$CachedProductsTableCreateCompanionBuilder,
      $$CachedProductsTableUpdateCompanionBuilder,
      (
        CachedProduct,
        BaseReferences<_$AppDatabase, $CachedProductsTable, CachedProduct>,
      ),
      CachedProduct,
      PrefetchHooks Function()
    >;
typedef $$CachedWishlistItemsTableCreateCompanionBuilder =
    CachedWishlistItemsCompanion Function({
      required String variantId,
      required String productId,
      required String productName,
      required String variantName,
      required int currentPrice,
      Value<String?> imageUrl,
      Value<int> rowid,
    });
typedef $$CachedWishlistItemsTableUpdateCompanionBuilder =
    CachedWishlistItemsCompanion Function({
      Value<String> variantId,
      Value<String> productId,
      Value<String> productName,
      Value<String> variantName,
      Value<int> currentPrice,
      Value<String?> imageUrl,
      Value<int> rowid,
    });

class $$CachedWishlistItemsTableFilterComposer
    extends Composer<_$AppDatabase, $CachedWishlistItemsTable> {
  $$CachedWishlistItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get variantId => $composableBuilder(
    column: $table.variantId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get productId => $composableBuilder(
    column: $table.productId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get productName => $composableBuilder(
    column: $table.productName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get variantName => $composableBuilder(
    column: $table.variantName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get currentPrice => $composableBuilder(
    column: $table.currentPrice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get imageUrl => $composableBuilder(
    column: $table.imageUrl,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedWishlistItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedWishlistItemsTable> {
  $$CachedWishlistItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get variantId => $composableBuilder(
    column: $table.variantId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get productId => $composableBuilder(
    column: $table.productId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get productName => $composableBuilder(
    column: $table.productName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get variantName => $composableBuilder(
    column: $table.variantName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get currentPrice => $composableBuilder(
    column: $table.currentPrice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imageUrl => $composableBuilder(
    column: $table.imageUrl,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedWishlistItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedWishlistItemsTable> {
  $$CachedWishlistItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get variantId =>
      $composableBuilder(column: $table.variantId, builder: (column) => column);

  GeneratedColumn<String> get productId =>
      $composableBuilder(column: $table.productId, builder: (column) => column);

  GeneratedColumn<String> get productName => $composableBuilder(
    column: $table.productName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get variantName => $composableBuilder(
    column: $table.variantName,
    builder: (column) => column,
  );

  GeneratedColumn<int> get currentPrice => $composableBuilder(
    column: $table.currentPrice,
    builder: (column) => column,
  );

  GeneratedColumn<String> get imageUrl =>
      $composableBuilder(column: $table.imageUrl, builder: (column) => column);
}

class $$CachedWishlistItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedWishlistItemsTable,
          CachedWishlistItem,
          $$CachedWishlistItemsTableFilterComposer,
          $$CachedWishlistItemsTableOrderingComposer,
          $$CachedWishlistItemsTableAnnotationComposer,
          $$CachedWishlistItemsTableCreateCompanionBuilder,
          $$CachedWishlistItemsTableUpdateCompanionBuilder,
          (
            CachedWishlistItem,
            BaseReferences<
              _$AppDatabase,
              $CachedWishlistItemsTable,
              CachedWishlistItem
            >,
          ),
          CachedWishlistItem,
          PrefetchHooks Function()
        > {
  $$CachedWishlistItemsTableTableManager(
    _$AppDatabase db,
    $CachedWishlistItemsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedWishlistItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedWishlistItemsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$CachedWishlistItemsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> variantId = const Value.absent(),
                Value<String> productId = const Value.absent(),
                Value<String> productName = const Value.absent(),
                Value<String> variantName = const Value.absent(),
                Value<int> currentPrice = const Value.absent(),
                Value<String?> imageUrl = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedWishlistItemsCompanion(
                variantId: variantId,
                productId: productId,
                productName: productName,
                variantName: variantName,
                currentPrice: currentPrice,
                imageUrl: imageUrl,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String variantId,
                required String productId,
                required String productName,
                required String variantName,
                required int currentPrice,
                Value<String?> imageUrl = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedWishlistItemsCompanion.insert(
                variantId: variantId,
                productId: productId,
                productName: productName,
                variantName: variantName,
                currentPrice: currentPrice,
                imageUrl: imageUrl,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedWishlistItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedWishlistItemsTable,
      CachedWishlistItem,
      $$CachedWishlistItemsTableFilterComposer,
      $$CachedWishlistItemsTableOrderingComposer,
      $$CachedWishlistItemsTableAnnotationComposer,
      $$CachedWishlistItemsTableCreateCompanionBuilder,
      $$CachedWishlistItemsTableUpdateCompanionBuilder,
      (
        CachedWishlistItem,
        BaseReferences<
          _$AppDatabase,
          $CachedWishlistItemsTable,
          CachedWishlistItem
        >,
      ),
      CachedWishlistItem,
      PrefetchHooks Function()
    >;
typedef $$CachedCartItemsTableCreateCompanionBuilder =
    CachedCartItemsCompanion Function({
      required String variantId,
      Value<String?> serverId,
      required String productId,
      required String productName,
      required String variantName,
      required int currentPrice,
      required int originalPrice,
      required int stockQty,
      required int quantity,
      Value<String?> imageUrl,
      Value<int> rowid,
    });
typedef $$CachedCartItemsTableUpdateCompanionBuilder =
    CachedCartItemsCompanion Function({
      Value<String> variantId,
      Value<String?> serverId,
      Value<String> productId,
      Value<String> productName,
      Value<String> variantName,
      Value<int> currentPrice,
      Value<int> originalPrice,
      Value<int> stockQty,
      Value<int> quantity,
      Value<String?> imageUrl,
      Value<int> rowid,
    });

class $$CachedCartItemsTableFilterComposer
    extends Composer<_$AppDatabase, $CachedCartItemsTable> {
  $$CachedCartItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get variantId => $composableBuilder(
    column: $table.variantId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get productId => $composableBuilder(
    column: $table.productId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get productName => $composableBuilder(
    column: $table.productName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get variantName => $composableBuilder(
    column: $table.variantName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get currentPrice => $composableBuilder(
    column: $table.currentPrice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get originalPrice => $composableBuilder(
    column: $table.originalPrice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get stockQty => $composableBuilder(
    column: $table.stockQty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get imageUrl => $composableBuilder(
    column: $table.imageUrl,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedCartItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedCartItemsTable> {
  $$CachedCartItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get variantId => $composableBuilder(
    column: $table.variantId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get productId => $composableBuilder(
    column: $table.productId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get productName => $composableBuilder(
    column: $table.productName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get variantName => $composableBuilder(
    column: $table.variantName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get currentPrice => $composableBuilder(
    column: $table.currentPrice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get originalPrice => $composableBuilder(
    column: $table.originalPrice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get stockQty => $composableBuilder(
    column: $table.stockQty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imageUrl => $composableBuilder(
    column: $table.imageUrl,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedCartItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedCartItemsTable> {
  $$CachedCartItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get variantId =>
      $composableBuilder(column: $table.variantId, builder: (column) => column);

  GeneratedColumn<String> get serverId =>
      $composableBuilder(column: $table.serverId, builder: (column) => column);

  GeneratedColumn<String> get productId =>
      $composableBuilder(column: $table.productId, builder: (column) => column);

  GeneratedColumn<String> get productName => $composableBuilder(
    column: $table.productName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get variantName => $composableBuilder(
    column: $table.variantName,
    builder: (column) => column,
  );

  GeneratedColumn<int> get currentPrice => $composableBuilder(
    column: $table.currentPrice,
    builder: (column) => column,
  );

  GeneratedColumn<int> get originalPrice => $composableBuilder(
    column: $table.originalPrice,
    builder: (column) => column,
  );

  GeneratedColumn<int> get stockQty =>
      $composableBuilder(column: $table.stockQty, builder: (column) => column);

  GeneratedColumn<int> get quantity =>
      $composableBuilder(column: $table.quantity, builder: (column) => column);

  GeneratedColumn<String> get imageUrl =>
      $composableBuilder(column: $table.imageUrl, builder: (column) => column);
}

class $$CachedCartItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedCartItemsTable,
          CachedCartItem,
          $$CachedCartItemsTableFilterComposer,
          $$CachedCartItemsTableOrderingComposer,
          $$CachedCartItemsTableAnnotationComposer,
          $$CachedCartItemsTableCreateCompanionBuilder,
          $$CachedCartItemsTableUpdateCompanionBuilder,
          (
            CachedCartItem,
            BaseReferences<
              _$AppDatabase,
              $CachedCartItemsTable,
              CachedCartItem
            >,
          ),
          CachedCartItem,
          PrefetchHooks Function()
        > {
  $$CachedCartItemsTableTableManager(
    _$AppDatabase db,
    $CachedCartItemsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedCartItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedCartItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedCartItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> variantId = const Value.absent(),
                Value<String?> serverId = const Value.absent(),
                Value<String> productId = const Value.absent(),
                Value<String> productName = const Value.absent(),
                Value<String> variantName = const Value.absent(),
                Value<int> currentPrice = const Value.absent(),
                Value<int> originalPrice = const Value.absent(),
                Value<int> stockQty = const Value.absent(),
                Value<int> quantity = const Value.absent(),
                Value<String?> imageUrl = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedCartItemsCompanion(
                variantId: variantId,
                serverId: serverId,
                productId: productId,
                productName: productName,
                variantName: variantName,
                currentPrice: currentPrice,
                originalPrice: originalPrice,
                stockQty: stockQty,
                quantity: quantity,
                imageUrl: imageUrl,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String variantId,
                Value<String?> serverId = const Value.absent(),
                required String productId,
                required String productName,
                required String variantName,
                required int currentPrice,
                required int originalPrice,
                required int stockQty,
                required int quantity,
                Value<String?> imageUrl = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedCartItemsCompanion.insert(
                variantId: variantId,
                serverId: serverId,
                productId: productId,
                productName: productName,
                variantName: variantName,
                currentPrice: currentPrice,
                originalPrice: originalPrice,
                stockQty: stockQty,
                quantity: quantity,
                imageUrl: imageUrl,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedCartItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedCartItemsTable,
      CachedCartItem,
      $$CachedCartItemsTableFilterComposer,
      $$CachedCartItemsTableOrderingComposer,
      $$CachedCartItemsTableAnnotationComposer,
      $$CachedCartItemsTableCreateCompanionBuilder,
      $$CachedCartItemsTableUpdateCompanionBuilder,
      (
        CachedCartItem,
        BaseReferences<_$AppDatabase, $CachedCartItemsTable, CachedCartItem>,
      ),
      CachedCartItem,
      PrefetchHooks Function()
    >;
typedef $$CachedAddressesTableCreateCompanionBuilder =
    CachedAddressesCompanion Function({
      required String id,
      Value<String?> label,
      required String line1,
      Value<String?> line2,
      required String city,
      required String state,
      required String pincode,
      required bool isDefault,
      Value<int> rowid,
    });
typedef $$CachedAddressesTableUpdateCompanionBuilder =
    CachedAddressesCompanion Function({
      Value<String> id,
      Value<String?> label,
      Value<String> line1,
      Value<String?> line2,
      Value<String> city,
      Value<String> state,
      Value<String> pincode,
      Value<bool> isDefault,
      Value<int> rowid,
    });

class $$CachedAddressesTableFilterComposer
    extends Composer<_$AppDatabase, $CachedAddressesTable> {
  $$CachedAddressesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get line1 => $composableBuilder(
    column: $table.line1,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get line2 => $composableBuilder(
    column: $table.line2,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get city => $composableBuilder(
    column: $table.city,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pincode => $composableBuilder(
    column: $table.pincode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDefault => $composableBuilder(
    column: $table.isDefault,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedAddressesTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedAddressesTable> {
  $$CachedAddressesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get line1 => $composableBuilder(
    column: $table.line1,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get line2 => $composableBuilder(
    column: $table.line2,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get city => $composableBuilder(
    column: $table.city,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pincode => $composableBuilder(
    column: $table.pincode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDefault => $composableBuilder(
    column: $table.isDefault,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedAddressesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedAddressesTable> {
  $$CachedAddressesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  GeneratedColumn<String> get line1 =>
      $composableBuilder(column: $table.line1, builder: (column) => column);

  GeneratedColumn<String> get line2 =>
      $composableBuilder(column: $table.line2, builder: (column) => column);

  GeneratedColumn<String> get city =>
      $composableBuilder(column: $table.city, builder: (column) => column);

  GeneratedColumn<String> get state =>
      $composableBuilder(column: $table.state, builder: (column) => column);

  GeneratedColumn<String> get pincode =>
      $composableBuilder(column: $table.pincode, builder: (column) => column);

  GeneratedColumn<bool> get isDefault =>
      $composableBuilder(column: $table.isDefault, builder: (column) => column);
}

class $$CachedAddressesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedAddressesTable,
          CachedAddressesData,
          $$CachedAddressesTableFilterComposer,
          $$CachedAddressesTableOrderingComposer,
          $$CachedAddressesTableAnnotationComposer,
          $$CachedAddressesTableCreateCompanionBuilder,
          $$CachedAddressesTableUpdateCompanionBuilder,
          (
            CachedAddressesData,
            BaseReferences<
              _$AppDatabase,
              $CachedAddressesTable,
              CachedAddressesData
            >,
          ),
          CachedAddressesData,
          PrefetchHooks Function()
        > {
  $$CachedAddressesTableTableManager(
    _$AppDatabase db,
    $CachedAddressesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedAddressesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedAddressesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedAddressesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> label = const Value.absent(),
                Value<String> line1 = const Value.absent(),
                Value<String?> line2 = const Value.absent(),
                Value<String> city = const Value.absent(),
                Value<String> state = const Value.absent(),
                Value<String> pincode = const Value.absent(),
                Value<bool> isDefault = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedAddressesCompanion(
                id: id,
                label: label,
                line1: line1,
                line2: line2,
                city: city,
                state: state,
                pincode: pincode,
                isDefault: isDefault,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> label = const Value.absent(),
                required String line1,
                Value<String?> line2 = const Value.absent(),
                required String city,
                required String state,
                required String pincode,
                required bool isDefault,
                Value<int> rowid = const Value.absent(),
              }) => CachedAddressesCompanion.insert(
                id: id,
                label: label,
                line1: line1,
                line2: line2,
                city: city,
                state: state,
                pincode: pincode,
                isDefault: isDefault,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedAddressesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedAddressesTable,
      CachedAddressesData,
      $$CachedAddressesTableFilterComposer,
      $$CachedAddressesTableOrderingComposer,
      $$CachedAddressesTableAnnotationComposer,
      $$CachedAddressesTableCreateCompanionBuilder,
      $$CachedAddressesTableUpdateCompanionBuilder,
      (
        CachedAddressesData,
        BaseReferences<
          _$AppDatabase,
          $CachedAddressesTable,
          CachedAddressesData
        >,
      ),
      CachedAddressesData,
      PrefetchHooks Function()
    >;
typedef $$CachedOrdersTableCreateCompanionBuilder =
    CachedOrdersCompanion Function({
      required String id,
      required String status,
      required int subtotal,
      required int discountValue,
      required int shippingCost,
      required int total,
      required DateTime createdAt,
      required int itemCount,
      Value<String?> thumbnailUrl,
      Value<int> rowid,
    });
typedef $$CachedOrdersTableUpdateCompanionBuilder =
    CachedOrdersCompanion Function({
      Value<String> id,
      Value<String> status,
      Value<int> subtotal,
      Value<int> discountValue,
      Value<int> shippingCost,
      Value<int> total,
      Value<DateTime> createdAt,
      Value<int> itemCount,
      Value<String?> thumbnailUrl,
      Value<int> rowid,
    });

class $$CachedOrdersTableFilterComposer
    extends Composer<_$AppDatabase, $CachedOrdersTable> {
  $$CachedOrdersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get subtotal => $composableBuilder(
    column: $table.subtotal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get discountValue => $composableBuilder(
    column: $table.discountValue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get shippingCost => $composableBuilder(
    column: $table.shippingCost,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get total => $composableBuilder(
    column: $table.total,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get itemCount => $composableBuilder(
    column: $table.itemCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get thumbnailUrl => $composableBuilder(
    column: $table.thumbnailUrl,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedOrdersTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedOrdersTable> {
  $$CachedOrdersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get subtotal => $composableBuilder(
    column: $table.subtotal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get discountValue => $composableBuilder(
    column: $table.discountValue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get shippingCost => $composableBuilder(
    column: $table.shippingCost,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get total => $composableBuilder(
    column: $table.total,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get itemCount => $composableBuilder(
    column: $table.itemCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get thumbnailUrl => $composableBuilder(
    column: $table.thumbnailUrl,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedOrdersTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedOrdersTable> {
  $$CachedOrdersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get subtotal =>
      $composableBuilder(column: $table.subtotal, builder: (column) => column);

  GeneratedColumn<int> get discountValue => $composableBuilder(
    column: $table.discountValue,
    builder: (column) => column,
  );

  GeneratedColumn<int> get shippingCost => $composableBuilder(
    column: $table.shippingCost,
    builder: (column) => column,
  );

  GeneratedColumn<int> get total =>
      $composableBuilder(column: $table.total, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get itemCount =>
      $composableBuilder(column: $table.itemCount, builder: (column) => column);

  GeneratedColumn<String> get thumbnailUrl => $composableBuilder(
    column: $table.thumbnailUrl,
    builder: (column) => column,
  );
}

class $$CachedOrdersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedOrdersTable,
          CachedOrder,
          $$CachedOrdersTableFilterComposer,
          $$CachedOrdersTableOrderingComposer,
          $$CachedOrdersTableAnnotationComposer,
          $$CachedOrdersTableCreateCompanionBuilder,
          $$CachedOrdersTableUpdateCompanionBuilder,
          (
            CachedOrder,
            BaseReferences<_$AppDatabase, $CachedOrdersTable, CachedOrder>,
          ),
          CachedOrder,
          PrefetchHooks Function()
        > {
  $$CachedOrdersTableTableManager(_$AppDatabase db, $CachedOrdersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedOrdersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedOrdersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedOrdersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> subtotal = const Value.absent(),
                Value<int> discountValue = const Value.absent(),
                Value<int> shippingCost = const Value.absent(),
                Value<int> total = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> itemCount = const Value.absent(),
                Value<String?> thumbnailUrl = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedOrdersCompanion(
                id: id,
                status: status,
                subtotal: subtotal,
                discountValue: discountValue,
                shippingCost: shippingCost,
                total: total,
                createdAt: createdAt,
                itemCount: itemCount,
                thumbnailUrl: thumbnailUrl,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String status,
                required int subtotal,
                required int discountValue,
                required int shippingCost,
                required int total,
                required DateTime createdAt,
                required int itemCount,
                Value<String?> thumbnailUrl = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedOrdersCompanion.insert(
                id: id,
                status: status,
                subtotal: subtotal,
                discountValue: discountValue,
                shippingCost: shippingCost,
                total: total,
                createdAt: createdAt,
                itemCount: itemCount,
                thumbnailUrl: thumbnailUrl,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedOrdersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedOrdersTable,
      CachedOrder,
      $$CachedOrdersTableFilterComposer,
      $$CachedOrdersTableOrderingComposer,
      $$CachedOrdersTableAnnotationComposer,
      $$CachedOrdersTableCreateCompanionBuilder,
      $$CachedOrdersTableUpdateCompanionBuilder,
      (
        CachedOrder,
        BaseReferences<_$AppDatabase, $CachedOrdersTable, CachedOrder>,
      ),
      CachedOrder,
      PrefetchHooks Function()
    >;
typedef $$CachedHomeSectionsTableCreateCompanionBuilder =
    CachedHomeSectionsCompanion Function({
      required String section,
      required String productId,
      required String subCategoryId,
      required String name,
      required bool isTrending,
      required DateTime createdAt,
      required int sortOrder,
      Value<String?> variantId,
      Value<String?> variantName,
      Value<int?> originalPrice,
      Value<int?> currentPrice,
      Value<int?> stockQty,
      Value<String?> imageUrl,
      Value<int> rowid,
    });
typedef $$CachedHomeSectionsTableUpdateCompanionBuilder =
    CachedHomeSectionsCompanion Function({
      Value<String> section,
      Value<String> productId,
      Value<String> subCategoryId,
      Value<String> name,
      Value<bool> isTrending,
      Value<DateTime> createdAt,
      Value<int> sortOrder,
      Value<String?> variantId,
      Value<String?> variantName,
      Value<int?> originalPrice,
      Value<int?> currentPrice,
      Value<int?> stockQty,
      Value<String?> imageUrl,
      Value<int> rowid,
    });

class $$CachedHomeSectionsTableFilterComposer
    extends Composer<_$AppDatabase, $CachedHomeSectionsTable> {
  $$CachedHomeSectionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get section => $composableBuilder(
    column: $table.section,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get productId => $composableBuilder(
    column: $table.productId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get subCategoryId => $composableBuilder(
    column: $table.subCategoryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isTrending => $composableBuilder(
    column: $table.isTrending,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get variantId => $composableBuilder(
    column: $table.variantId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get variantName => $composableBuilder(
    column: $table.variantName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get originalPrice => $composableBuilder(
    column: $table.originalPrice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get currentPrice => $composableBuilder(
    column: $table.currentPrice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get stockQty => $composableBuilder(
    column: $table.stockQty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get imageUrl => $composableBuilder(
    column: $table.imageUrl,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedHomeSectionsTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedHomeSectionsTable> {
  $$CachedHomeSectionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get section => $composableBuilder(
    column: $table.section,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get productId => $composableBuilder(
    column: $table.productId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get subCategoryId => $composableBuilder(
    column: $table.subCategoryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isTrending => $composableBuilder(
    column: $table.isTrending,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get variantId => $composableBuilder(
    column: $table.variantId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get variantName => $composableBuilder(
    column: $table.variantName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get originalPrice => $composableBuilder(
    column: $table.originalPrice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get currentPrice => $composableBuilder(
    column: $table.currentPrice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get stockQty => $composableBuilder(
    column: $table.stockQty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imageUrl => $composableBuilder(
    column: $table.imageUrl,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedHomeSectionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedHomeSectionsTable> {
  $$CachedHomeSectionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get section =>
      $composableBuilder(column: $table.section, builder: (column) => column);

  GeneratedColumn<String> get productId =>
      $composableBuilder(column: $table.productId, builder: (column) => column);

  GeneratedColumn<String> get subCategoryId => $composableBuilder(
    column: $table.subCategoryId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<bool> get isTrending => $composableBuilder(
    column: $table.isTrending,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<String> get variantId =>
      $composableBuilder(column: $table.variantId, builder: (column) => column);

  GeneratedColumn<String> get variantName => $composableBuilder(
    column: $table.variantName,
    builder: (column) => column,
  );

  GeneratedColumn<int> get originalPrice => $composableBuilder(
    column: $table.originalPrice,
    builder: (column) => column,
  );

  GeneratedColumn<int> get currentPrice => $composableBuilder(
    column: $table.currentPrice,
    builder: (column) => column,
  );

  GeneratedColumn<int> get stockQty =>
      $composableBuilder(column: $table.stockQty, builder: (column) => column);

  GeneratedColumn<String> get imageUrl =>
      $composableBuilder(column: $table.imageUrl, builder: (column) => column);
}

class $$CachedHomeSectionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedHomeSectionsTable,
          CachedHomeSection,
          $$CachedHomeSectionsTableFilterComposer,
          $$CachedHomeSectionsTableOrderingComposer,
          $$CachedHomeSectionsTableAnnotationComposer,
          $$CachedHomeSectionsTableCreateCompanionBuilder,
          $$CachedHomeSectionsTableUpdateCompanionBuilder,
          (
            CachedHomeSection,
            BaseReferences<
              _$AppDatabase,
              $CachedHomeSectionsTable,
              CachedHomeSection
            >,
          ),
          CachedHomeSection,
          PrefetchHooks Function()
        > {
  $$CachedHomeSectionsTableTableManager(
    _$AppDatabase db,
    $CachedHomeSectionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedHomeSectionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedHomeSectionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedHomeSectionsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> section = const Value.absent(),
                Value<String> productId = const Value.absent(),
                Value<String> subCategoryId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<bool> isTrending = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<String?> variantId = const Value.absent(),
                Value<String?> variantName = const Value.absent(),
                Value<int?> originalPrice = const Value.absent(),
                Value<int?> currentPrice = const Value.absent(),
                Value<int?> stockQty = const Value.absent(),
                Value<String?> imageUrl = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedHomeSectionsCompanion(
                section: section,
                productId: productId,
                subCategoryId: subCategoryId,
                name: name,
                isTrending: isTrending,
                createdAt: createdAt,
                sortOrder: sortOrder,
                variantId: variantId,
                variantName: variantName,
                originalPrice: originalPrice,
                currentPrice: currentPrice,
                stockQty: stockQty,
                imageUrl: imageUrl,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String section,
                required String productId,
                required String subCategoryId,
                required String name,
                required bool isTrending,
                required DateTime createdAt,
                required int sortOrder,
                Value<String?> variantId = const Value.absent(),
                Value<String?> variantName = const Value.absent(),
                Value<int?> originalPrice = const Value.absent(),
                Value<int?> currentPrice = const Value.absent(),
                Value<int?> stockQty = const Value.absent(),
                Value<String?> imageUrl = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedHomeSectionsCompanion.insert(
                section: section,
                productId: productId,
                subCategoryId: subCategoryId,
                name: name,
                isTrending: isTrending,
                createdAt: createdAt,
                sortOrder: sortOrder,
                variantId: variantId,
                variantName: variantName,
                originalPrice: originalPrice,
                currentPrice: currentPrice,
                stockQty: stockQty,
                imageUrl: imageUrl,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedHomeSectionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedHomeSectionsTable,
      CachedHomeSection,
      $$CachedHomeSectionsTableFilterComposer,
      $$CachedHomeSectionsTableOrderingComposer,
      $$CachedHomeSectionsTableAnnotationComposer,
      $$CachedHomeSectionsTableCreateCompanionBuilder,
      $$CachedHomeSectionsTableUpdateCompanionBuilder,
      (
        CachedHomeSection,
        BaseReferences<
          _$AppDatabase,
          $CachedHomeSectionsTable,
          CachedHomeSection
        >,
      ),
      CachedHomeSection,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$AppSettingsTableTableManager get appSettings =>
      $$AppSettingsTableTableManager(_db, _db.appSettings);
  $$CachedCategoriesTableTableManager get cachedCategories =>
      $$CachedCategoriesTableTableManager(_db, _db.cachedCategories);
  $$CachedSubCategoriesTableTableManager get cachedSubCategories =>
      $$CachedSubCategoriesTableTableManager(_db, _db.cachedSubCategories);
  $$CachedProductsTableTableManager get cachedProducts =>
      $$CachedProductsTableTableManager(_db, _db.cachedProducts);
  $$CachedWishlistItemsTableTableManager get cachedWishlistItems =>
      $$CachedWishlistItemsTableTableManager(_db, _db.cachedWishlistItems);
  $$CachedCartItemsTableTableManager get cachedCartItems =>
      $$CachedCartItemsTableTableManager(_db, _db.cachedCartItems);
  $$CachedAddressesTableTableManager get cachedAddresses =>
      $$CachedAddressesTableTableManager(_db, _db.cachedAddresses);
  $$CachedOrdersTableTableManager get cachedOrders =>
      $$CachedOrdersTableTableManager(_db, _db.cachedOrders);
  $$CachedHomeSectionsTableTableManager get cachedHomeSections =>
      $$CachedHomeSectionsTableTableManager(_db, _db.cachedHomeSections);
}
