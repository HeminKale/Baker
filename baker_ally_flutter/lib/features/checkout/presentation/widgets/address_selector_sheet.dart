import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/address.dart';
import '../providers/checkout_providers.dart';

const _addressesErrorMessage = 'Failed to load addresses. Please try again.';

/// Address selector bottom sheet (05_cart_and_checkout.md §6). Radio-select an
/// existing address or expand an inline "Add New Address" form. Milestone 3
/// scope: list + add (edit/delete are Phase 5).
class AddressSelectorSheet extends ConsumerStatefulWidget {
  const AddressSelectorSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const AddressSelectorSheet(),
    );
  }

  @override
  ConsumerState<AddressSelectorSheet> createState() => _AddressSelectorSheetState();
}

class _AddressSelectorSheetState extends ConsumerState<AddressSelectorSheet> {
  bool _adding = false;

  @override
  Widget build(BuildContext context) {
    final addressesAsync = ref.watch(addressesProvider);
    final selected = ref.watch(selectedAddressProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Column(
            children: [
              const SizedBox(height: 8),
              Container(width: 40, height: 4, decoration: BoxDecoration(
                  color: Colors.grey, borderRadius: BorderRadius.circular(2))),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_adding ? 'Add New Address' : 'Select Delivery Address',
                        style: Theme.of(context).textTheme.titleLarge),
                    IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.close)),
                  ],
                ),
              ),
              Expanded(
                child: _adding
                    ? _AddAddressForm(
                        scrollController: scrollController,
                        onCancel: () => setState(() => _adding = false),
                        onSaved: (address) {
                          ref.read(selectedAddressProvider.notifier).state = address;
                          ref.invalidate(addressesProvider);
                          if (mounted) Navigator.of(context).pop();
                        },
                      )
                    : addressesAsync.when(
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (e, _) => const Center(child: Text(_addressesErrorMessage)),
                        data: (addresses) => ListView(
                          controller: scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          children: [
                            for (final address in addresses)
                              RadioListTile<String>(
                                value: address.id,
                                groupValue: selected?.id,
                                onChanged: (_) {
                                  ref.read(selectedAddressProvider.notifier).state = address;
                                  Navigator.of(context).pop();
                                },
                                title: Text(address.label ?? 'Address',
                                    style: const TextStyle(fontWeight: FontWeight.w600)),
                                subtitle: Text(
                                    '${address.line1}${address.line2 != null ? ', ${address.line2}' : ''}\n'
                                    '${address.city}, ${address.state} – ${address.pincode}'),
                                isThreeLine: true,
                                secondary: address.isDefault ? const Chip(label: Text('Default')) : null,
                              ),
                            const SizedBox(height: 8),
                            OutlinedButton.icon(
                              onPressed: () => setState(() => _adding = true),
                              icon: const Icon(Icons.add),
                              label: const Text('Add New Address'),
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AddAddressForm extends ConsumerStatefulWidget {
  const _AddAddressForm({required this.scrollController, required this.onCancel, required this.onSaved});

  final ScrollController scrollController;
  final VoidCallback onCancel;
  final ValueChanged<Address> onSaved;

  @override
  ConsumerState<_AddAddressForm> createState() => _AddAddressFormState();
}

class _AddAddressFormState extends ConsumerState<_AddAddressForm> {
  final _formKey = GlobalKey<FormState>();
  final _label = TextEditingController();
  final _line1 = TextEditingController();
  final _line2 = TextEditingController();
  final _city = TextEditingController();
  final _state = TextEditingController();
  final _pincode = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _label.dispose();
    _line1.dispose();
    _line2.dispose();
    _city.dispose();
    _state.dispose();
    _pincode.dispose();
    super.dispose();
  }

  String? _required(String? v) => (v == null || v.trim().isEmpty) ? 'Required' : null;

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final address = await ref.read(addressRepositoryProvider).addAddress(
            label: _label.text,
            line1: _line1.text,
            line2: _line2.text,
            city: _city.text,
            state: _state.text,
            pincode: _pincode.text,
          );
      widget.onSaved(address);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not save address: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        controller: widget.scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          TextFormField(controller: _label, decoration: const InputDecoration(labelText: 'Label (Home / Bakery)')),
          TextFormField(controller: _line1, validator: _required, decoration: const InputDecoration(labelText: 'Address Line 1')),
          TextFormField(controller: _line2, decoration: const InputDecoration(labelText: 'Address Line 2 (optional)')),
          TextFormField(controller: _city, validator: _required, decoration: const InputDecoration(labelText: 'City')),
          TextFormField(controller: _state, validator: _required, decoration: const InputDecoration(labelText: 'State')),
          TextFormField(
            controller: _pincode,
            validator: _required,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Pincode'),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: OutlinedButton(onPressed: _saving ? null : widget.onCancel, child: const Text('Cancel'))),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Save Address'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
