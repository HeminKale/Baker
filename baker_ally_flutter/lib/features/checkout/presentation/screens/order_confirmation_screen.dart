import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

const _kMonths = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
String _formatDate(DateTime dt) => '${dt.day} ${_kMonths[dt.month - 1]}';

/// Shown after a confirmed payment (05_cart_and_checkout.md §10). No back
/// navigation to checkout -- reached via context.go (replace), and the cart is
/// already cleared by the confirm flow.
///
/// No WhatsApp confirmation banner -- that channel was explicitly removed
/// (00_common_architecture.md §12, decision dated 2026-07-12: "no
/// Interakt/WhatsApp integration... in-app + FCM push only"). The banner
/// below is the deliberate replacement, not an omission.
///
/// "Track Order" pushes to Milestone 5's `/orders/:orderId` (order status +
/// items + address) -- not real carrier tracking, which still needs
/// Milestone 4's Shiprocket/shipments (not built).
class OrderConfirmationScreen extends StatelessWidget {
  const OrderConfirmationScreen({super.key, this.orderId, this.total, this.paymentMethodLabel});

  final String? orderId;
  final int? total;
  final String? paymentMethodLabel;

  String get _shortId => orderId == null ? '' : orderId!.substring(0, orderId!.length.clamp(0, 8)).toUpperCase();

  String get _estimatedDelivery {
    final now = DateTime.now();
    final from = now.add(const Duration(days: 2));
    final to = now.add(const Duration(days: 5));
    return '${_formatDate(from)} – ${_formatDate(to)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(automaticallyImplyLeading: false, title: const Text('Order Confirmed')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: Colors.green.shade50,
                child: const Icon(Icons.check_circle, color: Colors.green, size: 56),
              ),
              const SizedBox(height: 16),
              Text('Order Placed Successfully!', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 4),
              const Text('Thank you for ordering with Baker Ally', style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 20),
              if (orderId != null || total != null)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        if (orderId != null) _InfoRow(label: 'Order ID', value: 'ORD-$_shortId'),
                        if (total != null)
                          _InfoRow(
                            label: 'Total paid',
                            value: '₹${(total! / 100).toStringAsFixed(0)}',
                            bold: true,
                          ),
                        if (paymentMethodLabel != null) _InfoRow(label: 'Payment', value: paymentMethodLabel!),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              Card(
                color: Theme.of(context).colorScheme.secondaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.notifications_outlined),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text("You'll get an order update here and a push notification shortly."),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text('Estimated delivery: $_estimatedDelivery', style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 24),
              Row(
                children: [
                  if (orderId != null) ...[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => context.push('/orders/$orderId'),
                        child: const Text('Track Order'),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: FilledButton(
                      onPressed: () => context.go('/catalog'),
                      child: const Text('Continue Shopping'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value, this.bold = false});

  final String label;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final style = bold ? const TextStyle(fontWeight: FontWeight.bold) : null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade700)),
          Text(value, style: style),
        ],
      ),
    );
  }
}
