import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/checkout_providers.dart';

/// Payment mode bottom sheet (05_cart_and_checkout.md §7). Only selects a
/// preferred method label -- the actual payment UI is Razorpay's own sheet, so
/// Baker Ally never renders card/UPI input fields.
class PaymentModeSheet extends ConsumerWidget {
  const PaymentModeSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const PaymentModeSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedPaymentMethodProvider);

    Widget tile(PaymentMethod method, String title, String subtitle) {
      return RadioListTile<PaymentMethod>(
        value: method,
        groupValue: selected,
        onChanged: (_) {
          ref.read(selectedPaymentMethodProvider.notifier).state = method;
          Navigator.of(context).pop();
        },
        title: Text(title),
        subtitle: Text(subtitle),
      );
    }

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(width: 40, height: 4, decoration: BoxDecoration(
              color: Colors.grey, borderRadius: BorderRadius.circular(2))),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Choose Payment Method', style: Theme.of(context).textTheme.titleLarge),
            ),
          ),
          tile(PaymentMethod.upi, 'UPI', 'Google Pay, PhonePe, Paytm, any UPI app'),
          tile(PaymentMethod.card, 'Debit / Credit Card', 'Visa, Mastercard, RuPay'),
          tile(PaymentMethod.netbanking, 'Netbanking', 'All major Indian banks'),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('All payments secured by Razorpay', style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }
}
