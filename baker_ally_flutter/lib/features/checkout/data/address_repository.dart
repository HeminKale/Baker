import 'package:dio/dio.dart';
import 'package:drift/drift.dart';

import '../../../shared/local_db/app_database.dart';
import 'models/address.dart';

/// Network-first with Drift fallback (same shape as CatalogRepository), so the
/// checkout address selector still has data offline. List + add only for
/// Milestone 3; edit/delete land in Phase 5.
class AddressRepository {
  AddressRepository({required Dio dio, required AppDatabase db}) : _dio = dio, _db = db;

  final Dio _dio;
  final AppDatabase _db;

  Future<List<Address>> getAddresses() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/v1/addresses');
      final addresses =
          (response.data!['data'] as List).map((e) => Address.fromJson(e as Map<String, dynamic>)).toList();
      await _cache(addresses);
      return addresses;
    } on DioException {
      final cached = await _db.select(_db.cachedAddresses).get();
      if (cached.isEmpty) rethrow;
      return cached
          .map((r) => Address(
                id: r.id,
                label: r.label,
                line1: r.line1,
                line2: r.line2,
                city: r.city,
                state: r.state,
                pincode: r.pincode,
                isDefault: r.isDefault,
              ))
          .toList();
    }
  }

  Future<Address> addAddress({
    String? label,
    required String line1,
    String? line2,
    required String city,
    required String state,
    required String pincode,
    bool isDefault = false,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/v1/addresses',
      data: {
        if (label != null && label.isNotEmpty) 'label': label,
        'line1': line1,
        if (line2 != null && line2.isNotEmpty) 'line2': line2,
        'city': city,
        'state': state,
        'pincode': pincode,
        'isDefault': isDefault,
      },
    );
    return Address.fromJson(response.data!['data'] as Map<String, dynamic>);
  }

  Future<void> _cache(List<Address> addresses) async {
    await _db.transaction(() async {
      await _db.delete(_db.cachedAddresses).go();
      if (addresses.isEmpty) return;
      await _db.batch((batch) {
        batch.insertAll(
          _db.cachedAddresses,
          addresses.map(
            (a) => CachedAddressesCompanion.insert(
              id: a.id,
              label: Value(a.label),
              line1: a.line1,
              line2: Value(a.line2),
              city: a.city,
              state: a.state,
              pincode: a.pincode,
              isDefault: a.isDefault,
            ),
          ),
        );
      });
    });
  }
}
