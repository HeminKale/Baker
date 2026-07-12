import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/order_detail.dart';
import '../providers/order_providers.dart';
import '../widgets/order_format.dart';

/// `/orders/:orderId` (06_profile_and_account.md). Items, bill breakdown,
/// delivery address. No carrier/AWB/tracking -- that needs a shipments table
/// this milestone doesn't add (Milestone 5 plan: zero new DB migrations).
class OrderDetailScreen extends ConsumerWidget {
  const OrderDetailScreen({super.key, required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(orderDetailProvider(orderId));

    return Scaffold(
      appBar: AppBar(title: const Text('Order Details')),
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Could not load order: $e')),
        data: (detail) => _OrderDetailBody(detail: detail),
      ),
    );
  }
}

class _OrderDetailBody extends StatelessWidget {
  const _OrderDetailBody({required this.detail});

  final OrderDetail detail;

  @override
  Widget build(BuildContext context) {
    final order = detail.order;
    final address = detail.address;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(orderCode(order.id), style: Theme.of(context).textTheme.titleLarge),
            OrderStatusChip(status: order.status),
          ],
        ),
        const SizedBox(height: 4),
        Text(formatOrderDate(order.createdAt), style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 20),
        Text('Items (${detail.items.length})', style: Theme.of(context).textTheme.titleMedium),
        const Divider(),
        for (final item in detail.items) _OrderItemRow(item: item),
        const SizedBox(height: 20),
        Text('Bill Summary', style: Theme.of(context).textTheme.titleMedium),
        const Divider(),
        _BillRow(label: 'Subtotal', value: order.subtotal),
        if (order.discountValue > 0) _BillRow(label: 'Discount', value: -order.discountValue),
        _BillRow(label: 'Shipping', value: order.shippingCost),
        const Divider(),
        _BillRow(label: 'Total', value: order.total, bold: true),
        if (address != null) ...[
          const SizedBox(height: 20),
          Text('Delivery Address', style: Theme.of(context).textTheme.titleMedium),
          const Divider(),
          Text(address.label ?? 'Address', style: const TextStyle(fontWeight: FontWeight.w600)),
          Text('${address.line1}${address.line2 != null && address.line2!.isNotEmpty ? ', ${address.line2}' : ''}'),
          Text('${address.city}, ${address.state} – ${address.pincode}'),
        ],
      ],
    );
  }
}

class _OrderItemRow extends StatelessWidget {
  const _OrderItemRow({required this.item});

  final OrderItem item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.productName, style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(
                  '${item.variantName} × ${item.quantity}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
                ),
              ],
            ),
          ),
          Text(rupees(item.unitPrice * item.quantity)),
        ],
      ),
    );
  }
}

class _BillRow extends StatelessWidget {
  const _BillRow({required this.label, required this.value, this.bold = false});

  final String label;
  final int value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final style = bold ? const TextStyle(fontWeight: FontWeight.bold, fontSize: 16) : null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text(value < 0 ? '-${rupees(-value)}' : rupees(value), style: style),
        ],
      ),
    );
  }
}
