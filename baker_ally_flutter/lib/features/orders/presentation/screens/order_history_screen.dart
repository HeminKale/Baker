import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/order.dart';
import '../providers/order_providers.dart';
import '../widgets/order_format.dart';

/// `/orders` (06_profile_and_account.md Your Orders / Order Status). The
/// Profile Overlay's "Order Status" tile pushes here with
/// `extra: {'status': 'active'}`; "Your Orders" pushes with no extra.
class OrderHistoryScreen extends ConsumerWidget {
  const OrderHistoryScreen({super.key, this.status});

  final String? status;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(ordersProvider((status: status, paid: null)));
    final isActiveFilter = status == 'active';

    return Scaffold(
      appBar: AppBar(title: Text(isActiveFilter ? 'Order Status' : 'Your Orders')),
      body: ordersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Could not load orders: $e')),
        data: (orders) {
          if (orders.isEmpty) {
            return Center(child: Text(isActiveFilter ? 'No active orders' : 'No orders yet'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) => _OrderCard(order: orders[index]),
          );
        },
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push('/orders/${order.id}'),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 56,
                  height: 56,
                  child: order.thumbnailUrl != null
                      ? CachedNetworkImage(imageUrl: order.thumbnailUrl!, fit: BoxFit.cover)
                      : Container(
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                          child: const Icon(Icons.image_not_supported_outlined),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${orderCode(order.id)} · ${formatOrderDate(order.createdAt)} · ${order.itemCount} items',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        OrderStatusChip(status: order.status),
                        const SizedBox(width: 8),
                        Text(rupees(order.total)),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
