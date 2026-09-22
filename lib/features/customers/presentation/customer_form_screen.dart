import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/customer_repository.dart';
import '../models/customer.dart';

class CustomerFormScreen extends ConsumerStatefulWidget {
  const CustomerFormScreen({super.key, this.customer});

  final Customer? customer;

  @override
  ConsumerState<CustomerFormScreen> createState() => _CustomerFormScreenState();
}

class _CustomerFormScreenState extends ConsumerState<CustomerFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.customer?.name);
  late final _mobile = TextEditingController(text: widget.customer?.mobile);
  late final _address = TextEditingController(text: widget.customer?.address);
  late final _email = TextEditingController(text: widget.customer?.email);
  late final _openingBalance = TextEditingController(
    text: widget.customer == null ? '0' : widget.customer!.openingBalance.toStringAsFixed(2),
  );
  late final _creditLimit = TextEditingController(
    text: widget.customer?.creditLimit?.toStringAsFixed(2),
  );
  late final _notes = TextEditingController(text: widget.customer?.notes);

  bool _submitting = false;
  String? _error;

  bool get _isEditing => widget.customer != null;

  @override
  void dispose() {
    for (final c in [_name, _mobile, _address, _email, _openingBalance, _creditLimit, _notes]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final repo = ref.read(customerRepositoryProvider);
      if (_isEditing) {
        await repo.updateCustomer(
          widget.customer!.id,
          name: _name.text.trim(),
          mobile: _mobile.text.trim(),
          address: _address.text.trim(),
          email: _email.text.trim(),
          creditLimit: double.tryParse(_creditLimit.text.trim()),
          notes: _notes.text.trim(),
        );
      } else {
        await repo.createCustomer(
          name: _name.text.trim(),
          mobile: _mobile.text.trim(),
          address: _address.text.trim(),
          email: _email.text.trim(),
          openingBalance: double.tryParse(_openingBalance.text.trim()),
          creditLimit: double.tryParse(_creditLimit.text.trim()),
          notes: _notes.text.trim(),
        );
      }
      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_isEditing ? 'Customer updated.' : 'Customer created.')),
        );
      }
    } on CustomerException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit Customer' : 'New Customer')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Customer name *'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _mobile,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Mobile *'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _address,
              decoration: const InputDecoration(labelText: 'Address'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _openingBalance,
              enabled: !_isEditing,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Opening balance (amount owed to us)',
                helperText: _isEditing
                    ? 'Opening balance can\'t be edited after creation — post a manual journal entry to correct it.'
                    : null,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _creditLimit,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Credit limit'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notes,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Notes'),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(
                      height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(_isEditing ? 'Save Changes' : 'Create Customer'),
            ),
          ],
        ),
      ),
    );
  }
}
