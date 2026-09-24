import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/admin_providers.dart';
import '../data/admin_repository.dart';
import '../models/admin_company.dart';

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
