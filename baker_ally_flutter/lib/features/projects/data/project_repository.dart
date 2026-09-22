import 'package:dio/dio.dart';

import '../../../shared/local_db/app_database.dart';
import 'models/project.dart';
import 'models/project_detail.dart';

/// Network-first (07_projects.md §9 "Offline caching scope decision") --
/// Projects list/detail are browse/manage surfaces, not a hot path like the
/// wishlist heart, so only the flattened variantId set gets a Drift cache.
class ProjectRepository {
  ProjectRepository({required Dio dio, required AppDatabase db}) : _dio = dio, _db = db;

  final Dio _dio;
  final AppDatabase _db;

  Future<List<Project>> getAll({String? status}) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/v1/projects',
      queryParameters: status != null ? {'status': status} : null,
    );
    return (response.data!['data'] as List).map((e) => Project.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<ProjectDetail> getDetail(String projectId) async {
    final response = await _dio.get<Map<String, dynamic>>('/v1/projects/$projectId');
    return ProjectDetail.fromJson(response.data!['data'] as Map<String, dynamic>);
  }

  Future<Project> create({
    required String name,
    DateTime? eventDate,
    String? clientName,
    String? clientPhone,
    String? notes,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/v1/projects',
      data: {
        'name': name,
        if (eventDate != null) 'eventDate': eventDate.toIso8601String(),
        if (clientName != null && clientName.isNotEmpty) 'clientName': clientName,
        if (clientPhone != null && clientPhone.isNotEmpty) 'clientPhone': clientPhone,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      },
    );
    return Project.fromJson(response.data!['data'] as Map<String, dynamic>);
  }

  /// Rename / edit event-client details / mark complete / reopen (§6, §6b,
  /// §10 decision 1) -- one PATCH, `null` values clear a field.
  Future<ProjectDetail> update(
    String projectId, {
    String? name,
    String? status,
    Object? eventDate = _unset,
    Object? clientName = _unset,
    Object? clientPhone = _unset,
    Object? notes = _unset,
  }) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/v1/projects/$projectId',
      data: {
        if (name != null) 'name': name,
        if (status != null) 'status': status,
        if (eventDate != _unset) 'eventDate': (eventDate as DateTime?)?.toIso8601String(),
        if (clientName != _unset) 'clientName': clientName,
        if (clientPhone != _unset) 'clientPhone': clientPhone,
        if (notes != _unset) 'notes': notes,
      },
    );
    return ProjectDetail.fromJson(response.data!['data'] as Map<String, dynamic>);
  }

  Future<void> delete(String projectId) async {
    await _dio.delete<void>('/v1/projects/$projectId');
  }

  Future<ProjectDetail> addItem(String projectId, String variantId, {int quantity = 1}) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/v1/projects/$projectId/items',
      data: {'variantId': variantId, 'quantity': quantity},
    );
    await _refreshItemVariantIdsQuietly();
    return ProjectDetail.fromJson(response.data!['data'] as Map<String, dynamic>);
  }

  Future<ProjectDetail> updateItemQuantity(String projectId, String itemId, int quantity) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/v1/projects/$projectId/items/$itemId',
      data: {'quantity': quantity},
    );
    await _refreshItemVariantIdsQuietly();
    return ProjectDetail.fromJson(response.data!['data'] as Map<String, dynamic>);
  }

  Future<ProjectDetail> removeItem(String projectId, String itemId) async {
    final response = await _dio.delete<Map<String, dynamic>>('/v1/projects/$projectId/items/$itemId');
    await _refreshItemVariantIdsQuietly();
    return ProjectDetail.fromJson(response.data!['data'] as Map<String, dynamic>);
  }

  /// Add-to-Project dialog toggle (§4) -- add/remove by variantId, no item id
  /// tracking needed client-side.
  Future<void> setMembership(String projectId, String variantId, bool inProject) async {
    if (inProject) {
      await _dio.post<void>('/v1/projects/$projectId/items', data: {'variantId': variantId});
    } else {
      await _dio.delete<void>('/v1/projects/$projectId/items/by-variant/$variantId');
    }
    await _refreshItemVariantIdsQuietly();
  }

  /// Which of the caller's active projects already contain this variant --
  /// backs the dialog's per-row checkbox state.
  Future<Set<String>> getMembership(String variantId) async {
    final response = await _dio.get<Map<String, dynamic>>('/v1/projects/item-membership/$variantId');
    return (response.data!['data'] as List).cast<String>().toSet();
  }

  Future<Set<String>> getCachedItemVariantIds() async {
    final rows = await _db.select(_db.cachedProjectItemVariantIds).get();
    return rows.map((r) => r.variantId).toSet();
  }

  /// Replaces the local cache with the server's flattened active-project
  /// variantId set -- mirrors `WishlistRepository.refresh()`.
  Future<Set<String>> refreshItemVariantIds() async {
    final response = await _dio.get<Map<String, dynamic>>('/v1/projects/item-variant-ids');
    final ids = (response.data!['data'] as List).cast<String>().toSet();

    await _db.delete(_db.cachedProjectItemVariantIds).go();
    await _db.batch((batch) {
      batch.insertAllOnConflictUpdate(
        _db.cachedProjectItemVariantIds,
        ids.map((id) => CachedProjectItemVariantIdsCompanion.insert(variantId: id)),
      );
    });
    return ids;
  }

  Future<void> _refreshItemVariantIdsQuietly() async {
    try {
      await refreshItemVariantIds();
    } catch (_) {
      // Offline -- the icon's fill state just stays as it was.
    }
  }
}

const _unset = Object();
