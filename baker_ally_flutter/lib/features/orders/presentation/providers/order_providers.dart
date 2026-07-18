import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers.dart';
import '../../data/models/order.dart';
import '../../data/models/order_detail.dart';
import '../../data/order_repository.dart';

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  return OrderRepository(dio: ref.watch(dioProvider), db: ref.watch(appDatabaseProvider));
});

/// Keyed by filter so "Your Orders" (unfiltered), "Order Status" (active),
/// and "Receipts" (paid) each get their own cached result. autoDispose so
/// stale data doesn't linger in memory once the screen is popped.
final ordersProvider =
    FutureProvider.autoDispose.family<List<Order>, ({String? status, bool? paid})>((ref, filter) async {
  return ref.watch(orderRepositoryProvider).getOrders(status: filter.status, paid: filter.paid);
});

final orderDetailProvider = FutureProvider.autoDispose.family<OrderDetail, String>((ref, orderId) async {
  return ref.watch(orderRepositoryProvider).getOrderDetail(orderId);
});
