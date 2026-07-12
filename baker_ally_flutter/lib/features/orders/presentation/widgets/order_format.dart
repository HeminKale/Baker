import 'package:flutter/material.dart';

/// Shared by the order history, order detail, and receipts screens so date/
/// status/money rendering stays consistent across all three.
const _kMonths = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

/// No human-readable order number exists on the backend -- this derives one
/// from the id, matching the "ORD-3391" style in 06_profile_and_account.md's
/// mockups without inventing a new column.
String orderCode(String id) => 'ORD-${id.substring(0, 6).toUpperCase()}';

String formatOrderDate(DateTime dt) => '${dt.day} ${_kMonths[dt.month - 1]} ${dt.year}';

String rupees(int paise) => '₹${(paise / 100).toStringAsFixed(0)}';

class OrderStatusInfo {
  const OrderStatusInfo(this.label, this.icon, this.color);

  final String label;
  final IconData icon;
  final Color color;
}

/// Only pending/confirmed/cancelled are realistically reachable until a
/// later phase can advance the state machine further (see routes/orders.ts
/// comment) -- all six are mapped anyway so nothing here needs to change
/// once that happens.
OrderStatusInfo orderStatusInfo(String status) {
  switch (status) {
    case 'pending':
      return const OrderStatusInfo('Pending', Icons.hourglass_empty, Colors.grey);
    case 'confirmed':
      return const OrderStatusInfo('Confirmed', Icons.check_circle_outline, Colors.blue);
    case 'processing':
      return const OrderStatusInfo('Processing', Icons.autorenew, Colors.orange);
    case 'shipped':
      return const OrderStatusInfo('In Transit', Icons.local_shipping, Colors.blue);
    case 'delivered':
      return const OrderStatusInfo('Delivered', Icons.check_circle, Colors.green);
    case 'cancelled':
      return const OrderStatusInfo('Cancelled', Icons.cancel, Colors.red);
    default:
      return OrderStatusInfo(status, Icons.info_outline, Colors.grey);
  }
}

class OrderStatusChip extends StatelessWidget {
  const OrderStatusChip({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final info = orderStatusInfo(status);
    return Chip(
      avatar: Icon(info.icon, size: 16, color: info.color),
      label: Text(info.label),
      visualDensity: VisualDensity.compact,
    );
  }
}
