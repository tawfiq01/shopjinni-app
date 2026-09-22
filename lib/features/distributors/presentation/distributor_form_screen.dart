import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/distributor_repository.dart';
import '../models/distributor.dart';

class DistributorFormScreen extends ConsumerStatefulWidget {
  const DistributorFormScreen({super.key, this.distributor});

  final Distributor? distributor;

  @override
  ConsumerState<DistributorFormScreen> createState() => _DistributorFormScreenState();
}

class _DistributorFormScreenState extends ConsumerState<DistributorFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.distributor?.name);
  late final _companyName = TextEditingController(text: widget.distributor?.companyName);
  late final _contactPerson = TextEditingController(text: widget.distributor?.contactPerson);
  late final _mobile = TextEditingController(text: widget.distributor?.mobile);
  late final _altMobile = TextEditingController(text: widget.distributor?.altMobile);
  late final _address = TextEditingController(text: widget.distributor?.address);
  late final _email = TextEditingController(text: widget.distributor?.email);
  late final _openingBalance = TextEditingController(
    text: widget.distributor == null ? '0' : widget.distributor!.openingBalance.toStringAsFixed(2),
  );
  late final _creditLimit = TextEditingController(
    text: widget.distributor?.creditLimit?.toStringAsFixed(2),
  );
  late final _paymentTerms = TextEditingController(text: widget.distributor?.paymentTerms);
  late final _notes = TextEditingController(text: widget.distributor?.notes);

  bool _submitting = false;
  String? _error;

  bool get _isEditing => widget.distributor != null;

  @override
  void dispose() {
    for (final c in [
      _name,
      _companyName,
      _contactPerson,
      _mobile,
      _altMobile,
      _address,
      _email,
      _openingBalance,
      _creditLimit,
      _paymentTerms,
      _notes,
    ]) {
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
      final repo = ref.read(distributorRepositoryProvider);
      if (_isEditing) {
        await repo.updateDistributor(
          widget.distributor!.id,
          name: _name.text.trim(),
          mobile: _mobile.text.trim(),
          companyName: _companyName.text.trim(),
          contactPerson: _contactPerson.text.trim(),
          altMobile: _altMobile.text.trim(),
          address: _address.text.trim(),
          email: _email.text.trim(),
          creditLimit: double.tryParse(_creditLimit.text.trim()),
          paymentTerms: _paymentTerms.text.trim(),
          notes: _notes.text.trim(),
        );
      } else {
        await repo.createDistributor(
          name: _name.text.trim(),
          mobile: _mobile.text.trim(),
          companyName: _companyName.text.trim(),
          contactPerson: _contactPerson.text.trim(),
          altMobile: _altMobile.text.trim(),
          address: _address.text.trim(),
          email: _email.text.trim(),
          openingBalance: double.tryParse(_openingBalance.text.trim()),
          creditLimit: double.tryParse(_creditLimit.text.trim()),
          paymentTerms: _paymentTerms.text.trim(),
          notes: _notes.text.trim(),
        );
      }
      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_isEditing ? 'Distributor updated.' : 'Distributor created.')),
        );
      }
    } on DistributorException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit Distributor' : 'New Distributor')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Distributor name *'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _companyName,
              decoration: const InputDecoration(labelText: 'Company name'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _contactPerson,
              decoration: const InputDecoration(labelText: 'Contact person'),
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
              controller: _altMobile,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Alternative mobile'),
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
                labelText: 'Opening balance (amount owed to them)',
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
              controller: _paymentTerms,
              decoration: const InputDecoration(labelText: 'Payment terms'),
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
                  : Text(_isEditing ? 'Save Changes' : 'Create Distributor'),
            ),
          ],
        ),
      ),
    );
  }
}
