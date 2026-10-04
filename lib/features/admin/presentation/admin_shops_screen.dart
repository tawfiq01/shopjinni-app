import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/admin_providers.dart';
import '../data/admin_repository.dart';
import '../models/admin_company.dart';
import '../models/admin_plan.dart';

class AdminShopsScreen extends ConsumerStatefulWidget {
  const AdminShopsScreen({super.key});

  @override
  ConsumerState<AdminShopsScreen> createState() => _AdminShopsScreenState();
}

class _AdminShopsScreenState extends ConsumerState<AdminShopsScreen> {
  int? _busyCompanyId;

  Future<void> _toggleActive(AdminCompany company) async {
    setState(() => _busyCompanyId = company.id);
    try {
      final repo = ref.read(adminRepositoryProvider);
      if (company.isActive) {
        await repo.deactivateCompany(company.id);
      } else {
        await repo.activateCompany(company.id);
      }
      ref.invalidate(adminCompaniesProvider);
    } on AdminException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _busyCompanyId = null);
    }
  }

  Future<void> _setSuspended(AdminCompany company, bool suspend) async {
    setState(() => _busyCompanyId = company.id);
    try {
      await ref.read(adminRepositoryProvider).setSubscriptionStatus(company.id, suspend ? 'suspended' : 'active');
      ref.invalidate(adminCompaniesProvider);
    } on AdminException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _busyCompanyId = null);
    }
  }

  Future<void> _changePlan(AdminCompany company) async {
    setState(() => _busyCompanyId = company.id);
    try {
      final plans = await ref.read(adminPlansProvider.future);
      if (!mounted) return;
      final planId = await showDialog<int>(
        context: context,
        builder: (context) => _PlanSelectionDialog(
          plans: plans,
          currentPlanId: company.planId,
        ),
      );
      if (planId == null || !mounted) return;

      await ref.read(adminRepositoryProvider).setCompanyPlan(company.id, planId);
      ref.invalidate(adminCompaniesProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Shop package updated.')),
        );
      }
    } on AdminException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _busyCompanyId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final companiesAsync = ref.watch(adminCompaniesProvider);

    return companiesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Failed to load shops: $err')),
      data: (companies) => RefreshIndicator(
        onRefresh: () async => ref.invalidate(adminCompaniesProvider),
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: companies.length,
          itemBuilder: (context, index) {
            final company = companies[index];
            final busy = _busyCompanyId == company.id;

            return Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(company.name, style: Theme.of(context).textTheme.titleMedium),
                        ),
                        _StatusChip(status: company.subscriptionStatus, isActive: company.isActive),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${company.planName ?? 'No plan'} · ${company.userCount} user(s)'
                      '${company.phone != null ? ' · ${company.phone}' : ''}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      children: [
                        OutlinedButton(
                          onPressed: busy ? null : () => _toggleActive(company),
                          child: Text(company.isActive ? 'Deactivate shop' : 'Activate shop'),
                        ),
                        OutlinedButton.icon(
                          onPressed: busy ? null : () => _changePlan(company),
                          icon: const Icon(Icons.workspace_premium_outlined),
                          label: const Text('Change package'),
                        ),
                        if (company.subscriptionStatus == 'suspended')
                          FilledButton(
                            onPressed: busy ? null : () => _setSuspended(company, false),
                            child: const Text('Lift suspension'),
                          )
                        else
                          OutlinedButton(
                            onPressed: busy ? null : () => _setSuspended(company, true),
                            child: const Text('Suspend subscription'),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _PlanSelectionDialog extends StatefulWidget {
  const _PlanSelectionDialog({required this.plans, required this.currentPlanId});

  final List<AdminPlan> plans;
  final int? currentPlanId;

  @override
  State<_PlanSelectionDialog> createState() => _PlanSelectionDialogState();
}

class _PlanSelectionDialogState extends State<_PlanSelectionDialog> {
  int? _selectedPlanId;

  @override
  void initState() {
    super.initState();
    _selectedPlanId = widget.currentPlanId;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Change shop package'),
      content: widget.plans.isEmpty
          ? const Text('No packages are available.')
          : DropdownButtonFormField<int>(
              initialValue: widget.plans.any((plan) => plan.id == _selectedPlanId)
                  ? _selectedPlanId
                  : null,
              decoration: const InputDecoration(labelText: 'Package'),
              items: widget.plans
                  .map(
                    (plan) => DropdownMenuItem(
                      value: plan.id,
                      child: Text(
                        '${plan.name} · ৳${plan.monthlyPrice.toStringAsFixed(0)}/mo'
                        '${plan.isActive ? '' : ' (inactive)'}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (planId) => setState(() => _selectedPlanId = planId),
            ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _selectedPlanId == null || widget.plans.isEmpty
              ? null
              : () => Navigator.of(context).pop(_selectedPlanId),
          child: const Text('Change package'),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status, required this.isActive});

  final String? status;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    if (!isActive) {
      return const Chip(label: Text('Deactivated'), visualDensity: VisualDensity.compact);
    }

    final color = switch (status) {
      'trial' => Colors.blue,
      'active' => Colors.green,
      'payment_due' => Colors.orange,
      'grace' => Colors.deepOrange,
      'expired' => Colors.red,
      'suspended' => Colors.red,
      _ => Colors.grey,
    };

    return Chip(
      label: Text(status ?? 'unknown'),
      labelStyle: TextStyle(color: color),
      backgroundColor: color.withValues(alpha: 0.12),
      visualDensity: VisualDensity.compact,
    );
  }
}
