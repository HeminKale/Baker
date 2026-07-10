import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

/// Key-value settings -- also used to stash `catalog_last_synced_at`
/// (00_common_architecture.md §15 "Last updated X hours ago" banner) instead
/// of a dedicated single-row table.
class AppSettings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

/// Catalog cache (Milestone 2 / Phase 2, 02_catalog_tab.md §9). Products are
/// denormalized -- each row embeds its "display" variant + image directly
/// (mirrors the backend's list-endpoint shape) rather than joining separate
/// variant/image tables, since product detail is explicitly NOT cached
/// (00_common_architecture.md §15) and the catalog grid never needs more
/// than the display variant/image offline.

class CachedCategories extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get imageUrl => text().nullable()();
  IntColumn get sortOrder => integer()();
  IntColumn get subCategoryCount => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

class CachedSubCategories extends Table {
  TextColumn get id => text()();
  TextColumn get categoryId => text()();
  TextColumn get name => text()();
  TextColumn get imageUrl => text().nullable()();
  IntColumn get sortOrder => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

class CachedProducts extends Table {
  TextColumn get id => text()();
  TextColumn get subCategoryId => text()();
  TextColumn get categoryId => text()();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  BoolColumn get isTrending => boolean()();
  DateTimeColumn get createdAt => dateTime()();
  IntColumn get sortOrder => integer()();
  TextColumn get variantId => text().nullable()();
  TextColumn get variantName => text().nullable()();
  IntColumn get originalPrice => integer().nullable()();
  IntColumn get currentPrice => integer().nullable()();
  IntColumn get stockQty => integer().nullable()();
  TextColumn get imageUrl => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Cached so the wishlist heart shows the right state offline
/// (02_catalog_tab.md §9 "Wishlist state -> Drift-cached").
class CachedWishlistItems extends Table {
  TextColumn get variantId => text()();
  TextColumn get productId => text()();
  TextColumn get productName => text()();
  TextColumn get variantName => text()();
  IntColumn get currentPrice => integer()();
  TextColumn get imageUrl => text().nullable()();

  @override
  Set<Column> get primaryKey => {variantId};
}

@DriftDatabase(tables: [
  AppSettings,
  CachedCategories,
  CachedSubCategories,
  CachedProducts,
  CachedWishlistItems,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.createTable(cachedCategories);
            await m.createTable(cachedSubCategories);
            await m.createTable(cachedProducts);
            await m.createTable(cachedWishlistItems);
          }
        },
      );

  /// Called on logout -- wipes all locally cached app state.
  Future<void> clearAll() async {
    for (final table in allTables) {
      await delete(table).go();
    }
  }
}

QueryExecutor _openConnection() {
  return driftDatabase(name: 'baker_ally');
}
