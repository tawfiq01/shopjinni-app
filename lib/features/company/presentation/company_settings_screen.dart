import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../application/company_providers.dart';
import '../data/company_repository.dart';
import '../models/company_details.dart';
import '../models/company_profile_options.dart';

class CompanySettingsScreen extends ConsumerStatefulWidget {
  const CompanySettingsScreen({super.key});

  @override
  ConsumerState<CompanySettingsScreen> createState() => _CompanySettingsScreenState();
}

class _CompanySettingsScreenState extends ConsumerState<CompanySettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _districtController = TextEditingController();
  final _countryController = TextEditingController();
  final _phoneController = TextEditingController();
  String? _currency;
  String? _timezone;
  bool _initialized = false;
  bool _savingDetails = false;
  bool _uploadingLogo = false;
  String? _error;

  void _hydrate(CompanyDetails company) {
    if (_initialized) return;
    _initialized = true;
    _nameController.text = company.name;
    _ownerNameController.text = company.ownerName ?? '';
    _addressController.text = company.address ?? '';
    _districtController.text = company.district ?? '';
    _countryController.text = company.country ?? 'Bangladesh';
    _currency = company.currency ?? 'BDT';
    _timezone = company.timezone ?? 'Asia/Dhaka';
    _phoneController.text = company.phone ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ownerNameController.dispose();
    _addressController.dispose();
    _districtController.dispose();
    _countryController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _saveDetails() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _savingDetails = true;
      _error = null;
    });

    try {
      await ref.read(companyRepositoryProvider).updateCompany(
            name: _nameController.text.trim(),
            ownerName: _ownerNameController.text.trim().isEmpty ? null : _ownerNameController.text.trim(),
            address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
            district: _districtController.text.trim().isEmpty ? null : _districtController.text.trim(),
            country: _countryController.text.trim().isEmpty ? null : _countryController.text.trim(),
            currency: _currency,
            timezone: _timezone,
            phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
          );
      ref.invalidate(companyDetailsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Shop details saved.')));
      }
    } on CompanyException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _savingDetails = false);
    }
  }

  Future<void> _pickAndUploadLogo() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 800);
    if (picked == null || !mounted) return;

    setState(() {
      _uploadingLogo = true;
      _error = null;
    });

    try {
      final bytes = await picked.readAsBytes();
      await ref.read(companyRepositoryProvider).uploadLogo(bytes: bytes, filename: picked.name);
      ref.invalidate(companyDetailsProvider);
    } on CompanyException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _uploadingLogo = false);
    }
  }

  Future<void> _removeLogo() async {
    setState(() {
      _uploadingLogo = true;
      _error = null;
    });

    try {
      await ref.read(companyRepositoryProvider).deleteLogo();
      ref.invalidate(companyDetailsProvider);
    } on CompanyException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _uploadingLogo = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final companyAsync = ref.watch(companyDetailsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Shop Settings')),
      body: companyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Failed to load shop details: $err')),
        data: (company) {
          _hydrate(company);
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 48,
                      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
                      backgroundImage: company.logoUrl != null ? NetworkImage(company.logoUrl!) : null,
                      child: company.logoUrl == null
                          ? Icon(Icons.storefront_outlined,
                              size: 40, color: Theme.of(context).colorScheme.onSurfaceVariant)
                          : null,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextButton.icon(
                          onPressed: _uploadingLogo ? null : _pickAndUploadLogo,
                          icon: _uploadingLogo
                              ? const SizedBox(
                                  height: 14, width: 14, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.image_outlined, size: 18),
                          label: Text(company.logoUrl == null ? 'Add logo' : 'Change logo'),
                        ),
                        if (company.logoUrl != null)
                          TextButton.icon(
                            onPressed: _uploadingLogo ? null : _removeLogo,
                            icon: const Icon(Icons.delete_outline, size: 18),
                            label: const Text('Remove'),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Shop / company name'),
                      validator: (value) =>
                          (value == null || value.isEmpty) ? 'Shop name is required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _ownerNameController,
                      decoration: const InputDecoration(labelText: 'Owner name (optional)'),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _addressController,
                      decoration: const InputDecoration(labelText: 'Address (optional)'),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _districtController,
                      decoration: const InputDecoration(labelText: 'District (optional)'),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _countryController,
                      decoration: const InputDecoration(labelText: 'Country'),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _currency,
                      decoration: const InputDecoration(labelText: 'Currency'),
                      items: CompanyProfileOptions.currencies
                          .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                          .toList(),
                      onChanged: (value) => setState(() => _currency = value),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _timezone,
                      decoration: const InputDecoration(labelText: 'Time zone'),
                      items: CompanyProfileOptions.timezones
                          .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                          .toList(),
                      onChanged: (value) => setState(() => _timezone = value),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(labelText: 'Phone (optional)'),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                    ],
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _savingDetails ? null : _saveDetails,
                      child: _savingDetails
                          ? const SizedBox(
                              height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Save'),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
