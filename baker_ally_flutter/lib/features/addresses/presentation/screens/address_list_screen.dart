import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../checkout/data/models/address.dart';
import '../../../checkout/presentation/providers/checkout_providers.dart';

/// `/addresses` (06_profile_and_account.md Delivery Addresses). Cards with a
/// default badge, Edit/Delete, "+ Add New". Reuses the checkout feature's
/// AddressRepository/addressesProvider rather than duplicating them.
class AddressListScreen extends ConsumerWidget {
  const AddressListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final addressesAsync = ref.watch(addressesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Delivery Addresses'),
        actions: [
          TextButton.icon(
            onPressed: () => context.push('/addresses/new'),
            icon: const Icon(Icons.add),
            label: const Text('Add New'),
          ),
        ],
      ),
      body: addressesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Could not load addresses: $e')),
        data: (addresses) {
          if (addresses.isEmpty) {
            return const Center(child: Text('No saved addresses yet'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: addresses.length,
            itemBuilder: (context, index) => _AddressCard(address: addresses[index]),
          );
        },
      ),
    );
  }
}

class _AddressCard extends ConsumerWidget {
  const _AddressCard({required this.address});

  final Address address;

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Address'),
        content: Text('Delete "${address.label ?? 'this address'}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ref.read(addressRepositoryProvider).deleteAddress(address.id);
      ref.invalidate(addressesProvider);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not delete address: $e')));
      }
    }
  }

  Future<void> _setDefault(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(addressRepositoryProvider).updateAddress(address.id, isDefault: true);
      ref.invalidate(addressesProvider);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not set default: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.location_on_outlined, size: 18, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(address.label ?? 'Address', style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
                if (address.isDefault)
                  const Padding(
                    padding: EdgeInsets.only(right: 4),
                    child: Chip(label: Text('Default'), visualDensity: VisualDensity.compact),
                  ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: 'Edit',
                  onPressed: () => context.push('/addresses/${address.id}/edit', extra: address),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Delete',
                  onPressed: () => _delete(context, ref),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${address.line1}${address.line2 != null && address.line2!.isNotEmpty ? ', ${address.line2}' : ''}',
            ),
            Text('${address.city}, ${address.state} – ${address.pincode}'),
            if (!address.isDefault)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => _setDefault(context, ref),
                  child: const Text('Set as Default'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
