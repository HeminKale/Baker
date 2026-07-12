import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Shown after a confirmed payment (05_cart_and_checkout.md §10). No back
/// navigation to checkout -- reached via context.go (replace), and the cart is
/// already cleared by the confirm flow. Order tracking (Track Order) lands in
/// Phase 4, so that CTA is omitted here.
class OrderConfirmationScreen extends StatelessWidget {
  const OrderConfirmationScreen({super.key, this.orderId, this.total});

  final String? orderId;
  final int? total;

  String get _shortId => orderId == null ? '' : orderId!.substring(0, orderId!.length.clamp(0, 8)).toUpperCase();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(automaticallyImplyLeading: false, title: const Text('Order Confirmed')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 72),
              const SizedBox(height: 16),
              Text('Order Placed Successfully!', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              if (orderId != null) Text('Order ID: ORD-$_shortId'),
              if (total != null)
                Text('Total paid: ₹${(total! / 100).toStringAsFixed(0)}',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.chat_outlined),
                      const SizedBox(width: 8),
                      Expanded(child: Text("You'll receive a WhatsApp confirmation shortly.")),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text('Estimated delivery: 2–5 business days', style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => context.go('/catalog'),
                child: const Text('Continue Shopping'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
