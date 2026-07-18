import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:go_router/go_router.dart';

import '../../../checkout/data/models/address.dart';
import '../../../checkout/presentation/providers/checkout_providers.dart';

const _kIndianStates = <String>[
  'Andhra Pradesh', 'Arunachal Pradesh', 'Assam', 'Bihar', 'Chhattisgarh', 'Goa',
  'Gujarat', 'Haryana', 'Himachal Pradesh', 'Jharkhand', 'Karnataka', 'Kerala',
  'Madhya Pradesh', 'Maharashtra', 'Manipur', 'Meghalaya', 'Mizoram', 'Nagaland',
  'Odisha', 'Punjab', 'Rajasthan', 'Sikkim', 'Tamil Nadu', 'Telangana', 'Tripura',
  'Uttar Pradesh', 'Uttarakhand', 'West Bengal', 'Andaman and Nicobar Islands',
  'Chandigarh', 'Dadra and Nagar Haveli and Daman and Diu', 'Delhi',
  'Jammu and Kashmir', 'Ladakh', 'Lakshadweep', 'Puducherry',
];

/// `/addresses/new` and `/addresses/:id/edit` (06_profile_and_account.md).
/// The doc's mockup field list also shows Full Name/Phone, but the
/// `addresses` table has no such columns (those live on `users` and are
/// edited from `/profile/edit`) -- this form matches the actual
/// create/update contract in routes/addresses.ts instead of inventing fields
/// that would need a migration (Milestone 5 plan: zero new DB migrations).
///
/// `existing` arrives via GoRouter `extra` from the list screen (already
/// loaded from GET /addresses), same pattern as OrderConfirmationScreen --
/// there's no GET /addresses/:id to re-fetch a single row.
class AddressFormScreen extends ConsumerStatefulWidget {
  const AddressFormScreen({super.key, this.existing});

  final Address? existing;

  @override
  ConsumerState<AddressFormScreen> createState() => _AddressFormScreenState();
}

class _AddressFormScreenState extends ConsumerState<AddressFormScreen> {
  final _formKey = GlobalKey<FormBuilderState>();
  bool _saving = false;

  bool get _isEdit => widget.existing != null;

  Future<void> _save() async {
    if (!(_formKey.currentState?.saveAndValidate() ?? false)) return;
    final values = _formKey.currentState!.value;

    setState(() => _saving = true);
    try {
      final repo = ref.read(addressRepositoryProvider);
      if (_isEdit) {
        await repo.updateAddress(
          widget.existing!.id,
          label: values['label'] as String?,
          line1: values['line1'] as String?,
          line2: values['line2'] as String?,
          city: values['city'] as String?,
          state: values['state'] as String?,
          pincode: values['pincode'] as String?,
          isDefault: values['isDefault'] as bool?,
        );
      } else {
        await repo.addAddress(
          label: values['label'] as String?,
          line1: values['line1'] as String,
          line2: values['line2'] as String?,
          city: values['city'] as String,
          state: values['state'] as String,
          pincode: values['pincode'] as String,
          isDefault: values['isDefault'] as bool? ?? false,
        );
      }
      ref.invalidate(addressesProvider);
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not save address: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final existing = widget.existing;

    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Edit Address' : 'Add New Address')),
      body: FormBuilder(
        key: _formKey,
        initialValue: {
          'label': existing?.label ?? '',
          'line1': existing?.line1 ?? '',
          'line2': existing?.line2 ?? '',
          'city': existing?.city ?? '',
          'state': existing?.state,
          'pincode': existing?.pincode ?? '',
          'isDefault': existing?.isDefault ?? false,
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            FormBuilderTextField(
              name: 'label',
              decoration: const InputDecoration(labelText: 'Label (Home / Bakery / Other)'),
            ),
            const SizedBox(height: 12),
            FormBuilderTextField(
              name: 'line1',
              decoration: const InputDecoration(labelText: 'Address Line 1'),
              validator: FormBuilderValidators.required(),
            ),
            const SizedBox(height: 12),
            FormBuilderTextField(
              name: 'line2',
              decoration: const InputDecoration(labelText: 'Address Line 2 (optional)'),
            ),
            const SizedBox(height: 12),
            FormBuilderTextField(
              name: 'city',
              decoration: const InputDecoration(labelText: 'City'),
              validator: FormBuilderValidators.required(),
            ),
            const SizedBox(height: 12),
            FormBuilderDropdown<String>(
              name: 'state',
              decoration: const InputDecoration(labelText: 'State'),
              validator: FormBuilderValidators.required(),
              items: _kIndianStates.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
            ),
            const SizedBox(height: 12),
            FormBuilderTextField(
              name: 'pincode',
              decoration: const InputDecoration(labelText: 'Pincode'),
              keyboardType: TextInputType.number,
              validator: FormBuilderValidators.compose([
                FormBuilderValidators.required(),
                FormBuilderValidators.numeric(),
                FormBuilderValidators.equalLength(6),
              ]),
            ),
            const SizedBox(height: 4),
            FormBuilderSwitch(
              name: 'isDefault',
              title: const Text('Set as default address'),
              decoration: const InputDecoration(border: InputBorder.none),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Save Address'),
            ),
          ],
        ),
      ),
    );
  }
}
