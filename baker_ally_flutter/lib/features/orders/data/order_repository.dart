import 'package:dio/dio.dart';
import 'package:drift/drift.dart';

import '../../../shared/local_db/app_database.dart';
import 'models/order.dart';
import 'models/order_detail.dart';

/// Network-first; only the default unfiltered "Your Orders" list (page 1, no
/// status/paid filter) caches to Drift for offline fallback -- Order Status
/// (active filter) and Receipts (paid filter) are network-only (Milestone 5
/// plan: "No Drift caching for ... Receipts"). Order detail is also
/// network-only, mirroring product detail's existing not-cached precedent.
class OrderRepository {
  OrderRepository({required Dio dio, required AppDatabase db}) : _dio = dio, _db = db;

  final Dio _dio;
  final AppDatabase _db;

  Future<List<Order>> getOrders({int page = 1, int limit = 50, String? status, bool? paid}) async {
    final cacheable = status == null && paid == null && page == 1;
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/v1/orders',
        queryParameters: {
          'page': page,
          'limit': limit,
          if (status != null) 'status': status,
          if (paid != null) 'paid': paid,
        },
      );
      final orders = (response.data!['data'] as List).map((e) => Order.fromJson(e as Map<String, dynamic>)).toList();
      if (cacheable) await _cache(orders);
      return orders;
    } on DioException {
      if (cacheable) {
        final cached = await _db.select(_db.cachedOrders).get();
        if (cached.isNotEmpty) {
          return cached
              .map((r) => Order(
                    id: r.id,
                    status: r.status,
                    subtotal: r.subtotal,
                    discountValue: r.discountValue,
                    shippingCost: r.shippingCost,
                    total: r.total,
                    createdAt: r.createdAt,
                    itemCount: r.itemCount,
                    thumbnailUrl: r.thumbnailUrl,
                  ))
              .toList();
        }
      }
      rethrow;
    }
  }

  Future<OrderDetail> getOrderDetail(String orderId) async {
    final response = await _dio.get<Map<String, dynamic>>('/v1/orders/$orderId');
    return OrderDetail.fromJson(response.data!['data'] as Map<String, dynamic>);
  }

  Future<String> getInvoiceUrl(String orderId) async {
    final response = await _dio.get<Map<String, dynamic>>('/v1/orders/$orderId/invoice');
    return (response.data!['data'] as Map<String, dynamic>)['url'] as String;
  }

  Future<void> _cache(List<Order> orders) async {
    await _db.transaction(() async {
      await _db.delete(_db.cachedOrders).go();
      if (orders.isEmpty) return;
      await _db.batch((batch) {
        batch.insertAll(
          _db.cachedOrders,
          orders.map(
            (o) => CachedOrdersCompanion.insert(
              id: o.id,
              status: o.status,
              subtotal: o.subtotal,
              discountValue: o.discountValue,
              shippingCost: o.shippingCost,
              total: o.total,
              createdAt: o.createdAt,
              itemCount: o.itemCount,
              thumbnailUrl: Value(o.thumbnailUrl),
            ),
          ),
        );
      });
    });
  }
}
