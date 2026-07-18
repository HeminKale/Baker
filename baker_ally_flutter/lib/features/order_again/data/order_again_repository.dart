import 'package:dio/dio.dart';

import 'models/order_again_variant.dart';

/// Network-only, no Drift caching (Milestone 5 plan: "No Drift caching for
/// Order Again / Receipts") -- both endpoints are computed on-request from
/// the user's own order history, so there's nothing meaningfully stale to
/// serve offline.
class OrderAgainRepository {
  OrderAgainRepository({required Dio dio}) : _dio = dio;

  final Dio _dio;

  Future<List<FrequentlyBoughtGroup>> getFrequentlyBought() async {
    final response = await _dio.get<Map<String, dynamic>>('/v1/order-again/frequently-bought');
    return (response.data!['data'] as List)
        .map((e) => FrequentlyBoughtGroup.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<PreviouslyBoughtItem>> getPreviouslyBought({int page = 1, int limit = 20}) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/v1/order-again/previously-bought',
      queryParameters: {'page': page, 'limit': limit},
    );
    return (response.data!['data'] as List)
        .map((e) => PreviouslyBoughtItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
