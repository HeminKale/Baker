import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../orders/data/models/order.dart';
import '../../../orders/presentation/providers/order_providers.dart';
import '../../../orders/presentation/widgets/order_format.dart';

/// `/receipts` (06_profile_and_account.md Receipts & Invoices). Paid orders
/// with a Download action that fetches the signed invoice PDF URL and opens
/// it externally. Network-only, no Drift caching (Milestone 5 plan: "No
/// Drift caching for Order Again / Receipts").
class ReceiptsScreen extends ConsumerWidget {
  const ReceiptsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(ordersProvider((status: null, paid: true)));

    return Scaffold(
      appBar: AppBar(title: const Text('Receipts & Invoices')),
      body: ordersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Could not load receipts: $e')),
        data: (orders) {
          if (orders.isEmpty) {
            return const Center(child: Text('No paid orders yet'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) => _ReceiptRow(order: orders[index]),
          );
        },
      ),
    );
  }
}

class _ReceiptRow extends ConsumerStatefulWidget {
  const _ReceiptRow({required this.order});

  final Order order;

  @override
  ConsumerState<_ReceiptRow> createState() => _ReceiptRowState();
}

class _ReceiptRowState extends ConsumerState<_ReceiptRow> {
  bool _downloading = false;

  Future<void> _download() async {
    setState(() => _downloading = true);
    try {
      final url = await ref.read(orderRepositoryProvider).getInvoiceUrl(widget.order.id);
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not open invoice: $e')));
      }
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text('${orderCode(widget.order.id)} · ${formatOrderDate(widget.order.createdAt)}'),
        subtitle: Text(rupees(widget.order.total)),
        trailing: _downloading
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
            : OutlinedButton(onPressed: _download, child: const Text('Download')),
      ),
    );
  }
}
