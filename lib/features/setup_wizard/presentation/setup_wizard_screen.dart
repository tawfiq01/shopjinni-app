import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_state.dart';
import '../../catalog/application/catalog_providers.dart';
import '../../catalog/data/catalog_repository.dart';
import '../../catalog/presentation/catalog_home_screen.dart';
import '../../catalog/presentation/widgets/catalog_dialogs.dart';
import '../../company/application/company_providers.dart';
import '../../company/data/company_repository.dart';
import '../../company/models/company_details.dart';
import '../../company/models/company_profile_options.dart';
import '../../distributors/application/distributor_providers.dart';
import '../../distributors/presentation/distributor_form_screen.dart';
import '../../subscription/application/subscription_providers.dart';
import '../../subscription/presentation/subscription_screen.dart';
import '../../users/application/user_providers.dart';
import '../../users/presentation/users_screen.dart';

/// Shown once after a new shop's owner finishes onboarding — a dismissible
/// checklist, not a hard gate (see AppUser.needsSetupWizard). Every step
/// either pushes an existing, already-working screen (Distributors,
/// Catalog, Staff, Billing) or is a small inline form/dialog for the one
/// thing that had no UI at all yet (Product Categories).
class SetupWizardScreen extends ConsumerStatefulWidget {
  const SetupWizardScreen({super.key});

  @override
  ConsumerState<SetupWizardScreen> createState() => _SetupWizardScreenState();
}

class _SetupWizardScreenState extends ConsumerState<SetupWizardScreen> {
  bool _finishing = false;

  Future<void> _finish() async {
    setState(() => _finishing = true);
    try {
      await ref.read(companyRepositoryProvider).completeSetupWizard();
      await ref.read(authControllerProvider.notifier).refreshUser();
    } on CompanyException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _finishing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Set Up Your Shop'),
        actions: [
          TextButton(
            onPressed: _finishing ? null : _finish,
            child: const Text('Skip for now'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _ShopInformationStep(),
          SizedBox(height: 16),
          _PlanStep(),
          SizedBox(height: 16),
          _CategoriesStep(),
          SizedBox(height: 16),
          _DistributorsStep(),
          SizedBox(height: 16),
          _ProductsStep(),
          SizedBox(height: 16),
          _StaffStep(),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton(
            onPressed: _finishing ? null : _finish,
            child: _finishing
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Start Using Dashboard'),
          ),
        ),
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.number,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final int number;
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(radius: 16, child: Text('$number')),
                const SizedBox(width: 12),
                Icon(icon, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text(title, style: Theme.of(context).textTheme.titleMedium)),
              ],
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 44),
              child: Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
            ),
            const SizedBox(height: 12),
            Padding(padding: const EdgeInsets.only(left: 44), child: child),
          ],
        ),
      ),
    );
  }
}

class _ShopInformationStep extends ConsumerStatefulWidget {
  const _ShopInformationStep();

  @override
  ConsumerState<_ShopInformationStep> createState() => _ShopInformationStepState();
}

class _ShopInformationStepState extends ConsumerState<_ShopInformationStep> {
  final _ownerNameController = TextEditingController();
  final _districtController = TextEditingController();
  final _countryController = TextEditingController();
  String? _currency;
  String? _timezone;
  bool _initialized = false;
  bool _saving = false;
  String? _error;

  void _hydrate(CompanyDetails company) {
    if (_initialized) return;
    _initialized = true;
    _ownerNameController.text = company.ownerName ?? '';
    _districtController.text = company.district ?? '';
    _countryController.text = company.country ?? 'Bangladesh';
    _currency = company.currency ?? 'BDT';
    _timezone = company.timezone ?? 'Asia/Dhaka';
  }

  @override
  void dispose() {
    _ownerNameController.dispose();
    _districtController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  Future<void> _save(CompanyDetails company) async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(companyRepositoryProvider).updateCompany(
            name: company.name,
            ownerName: _ownerNameController.text.trim().isEmpty ? null : _ownerNameController.text.trim(),
            address: company.address,
            district: _districtController.text.trim().isEmpty ? null : _districtController.text.trim(),
            country: _countryController.text.trim().isEmpty ? null : _countryController.text.trim(),
            currency: _currency,
            timezone: _timezone,
            phone: company.phone,
          );
      ref.invalidate(companyDetailsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Shop information saved.')));
      }
    } on CompanyException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final companyAsync = ref.watch(companyDetailsProvider);

    return _StepCard(
      number: 1,
      icon: Icons.storefront_outlined,
      title: 'Shop Information',
      subtitle: 'A few more details for invoices and reports.',
      child: companyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Text('Failed to load: $err'),
        data: (company) {
          _hydrate(company);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _ownerNameController,
                decoration: const InputDecoration(labelText: 'Owner name'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _districtController,
                decoration: const InputDecoration(labelText: 'District'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _countryController,
                decoration: const InputDecoration(labelText: 'Country'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _currency,
                      decoration: const InputDecoration(labelText: 'Currency'),
                      items: CompanyProfileOptions.currencies
                          .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                          .toList(),
                      onChanged: (value) => setState(() => _currency = value),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _timezone,
                      decoration: const InputDecoration(labelText: 'Time zone'),
                      items: CompanyProfileOptions.timezones
                          .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                          .toList(),
                      onChanged: (value) => setState(() => _timezone = value),
                    ),
                  ),
                ],
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ],
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  onPressed: _saving ? null : () => _save(company),
                  child: _saving
                      ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Save'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PlanStep extends ConsumerWidget {
  const _PlanStep();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscriptionAsync = ref.watch(currentSubscriptionProvider);

    return _StepCard(
      number: 2,
      icon: Icons.workspace_premium_outlined,
      title: 'Select Subscription Plan',
      subtitle: 'You start on a free trial — upgrade any time.',
      child: Row(
        children: [
          Expanded(
            child: subscriptionAsync.when(
              loading: () => const Text('Loading…'),
              error: (err, _) => Text('$err'),
              data: (s) => Text('Current plan: ${s.plan.name} (${s.status})'),
            ),
          ),
          OutlinedButton(
            onPressed: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const SubscriptionScreen()))
                .then((_) => ref.invalidate(currentSubscriptionProvider)),
            child: const Text('View Plans'),
          ),
        ],
      ),
    );
  }
}

class _CategoriesStep extends ConsumerWidget {
  const _CategoriesStep();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final typesAsync = ref.watch(productTypesProvider);

    return _StepCard(
      number: 3,
      icon: Icons.category_outlined,
      title: 'Add Product Categories',
      subtitle: 'E.g. Smartphone, Feature Phone, Accessories.',
      child: Row(
        children: [
          Expanded(
            child: typesAsync.when(
              loading: () => const Text('Loading…'),
              error: (err, _) => Text('$err'),
              data: (types) => Text('${types.length} categor${types.length == 1 ? 'y' : 'ies'} added'),
            ),
          ),
          OutlinedButton(
            onPressed: () async {
              final name = await promptForText(context, title: 'New Category', label: 'Category name');
              if (name == null || name.isEmpty) return;
              try {
                await ref.read(catalogRepositoryProvider).createProductType(name);
                ref.invalidate(productTypesProvider);
                if (context.mounted) showSuccessSnackBar(context, 'Category created.');
              } on CatalogException catch (e) {
                if (context.mounted) showErrorSnackBar(context, e.message);
              }
            },
            child: const Text('Add Category'),
          ),
        ],
      ),
    );
  }
}

class _DistributorsStep extends ConsumerWidget {
  const _DistributorsStep();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final distributorsAsync = ref.watch(distributorsProvider);

    return _StepCard(
      number: 4,
      icon: Icons.local_shipping_outlined,
      title: 'Add Suppliers / Distributors',
      subtitle: 'Who you buy stock from.',
      child: Row(
        children: [
          Expanded(
            child: distributorsAsync.when(
              loading: () => const Text('Loading…'),
              error: (err, _) => Text('$err'),
              data: (list) => Text('${list.length} added'),
            ),
          ),
          OutlinedButton(
            onPressed: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const DistributorFormScreen()))
                .then((_) => ref.invalidate(distributorsProvider)),
            child: const Text('Add a Distributor'),
          ),
        ],
      ),
    );
  }
}

class _ProductsStep extends ConsumerWidget {
  const _ProductsStep();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modelsAsync = ref.watch(modelsProvider);

    return _StepCard(
      number: 5,
      icon: Icons.inventory_2_outlined,
      title: 'Add Initial Products',
      subtitle: 'Brands, models, and sellable SKUs.',
      child: Row(
        children: [
          Expanded(
            child: modelsAsync.when(
              loading: () => const Text('Loading…'),
              error: (err, _) => Text('$err'),
              data: (list) => Text('${list.length} model(s) added'),
            ),
          ),
          OutlinedButton(
            onPressed: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const CatalogHomeScreen()))
                .then((_) => ref.invalidate(modelsProvider)),
            child: const Text('Go to Catalog'),
          ),
        ],
      ),
    );
  }
}

class _StaffStep extends ConsumerWidget {
  const _StaffStep();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(usersProvider);

    return _StepCard(
      number: 6,
      icon: Icons.people_outline,
      title: 'Create Staff Users',
      subtitle: 'Give your team their own logins.',
      child: Row(
        children: [
          Expanded(
            child: usersAsync.when(
              loading: () => const Text('Loading…'),
              error: (err, _) => Text('$err'),
              data: (list) => Text('${list.length} staff account(s)'),
            ),
          ),
          OutlinedButton(
            onPressed: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const UsersScreen()))
                .then((_) => ref.invalidate(usersProvider)),
            child: const Text('Add Staff'),
          ),
        ],
      ),
    );
  }
}
