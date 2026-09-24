import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/admin_providers.dart';
import '../data/admin_repository.dart';
import '../models/admin_plan.dart';

class AdminPlansScreen extends ConsumerWidget {
  const AdminPlansScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plansAsync = ref.watch(adminPlansProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openPlanForm(context, ref, null),
        child: const Icon(Icons.add),
      ),
      body: plansAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Failed to load plans: $err')),
        data: (plans) => ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: plans.length,
          itemBuilder: (context, index) {
            final plan = plans[index];
            return Card(
              child: ListTile(
                title: Text('${plan.name} (${plan.slug})'),
                subtitle: Text(
                  '৳${plan.monthlyPrice.toStringAsFixed(0)}/mo · ৳${plan.yearlyPrice.toStringAsFixed(0)}/yr · '
                  '${plan.maxUsers?.toString() ?? '∞'} users · ${plan.maxBranches?.toString() ?? '∞'} branches · '
                  '${plan.maxProducts?.toString() ?? '∞'} products'
                  '${plan.isActive ? '' : ' · inactive'}',
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => _openPlanForm(context, ref, plan),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _openPlanForm(BuildContext context, WidgetRef ref, AdminPlan? plan) {
    showDialog<void>(context: context, builder: (_) => _PlanFormDialog(plan: plan));
  }
}

class _PlanFormDialog extends ConsumerStatefulWidget {
  const _PlanFormDialog({this.plan});

  final AdminPlan? plan;

  @override
  ConsumerState<_PlanFormDialog> createState() => _PlanFormDialogState();
}

class _PlanFormDialogState extends ConsumerState<_PlanFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.plan?.name);
  late final _slug = TextEditingController(text: widget.plan?.slug);
  late final _monthlyPrice = TextEditingController(text: widget.plan?.monthlyPrice.toString());
  late final _yearlyPrice = TextEditingController(text: widget.plan?.yearlyPrice.toString());
  late final _maxUsers = TextEditingController(text: widget.plan?.maxUsers?.toString());
  late final _maxProducts = TextEditingController(text: widget.plan?.maxProducts?.toString());
  late final _maxBranches = TextEditingController(text: widget.plan?.maxBranches?.toString());
  late final _trialDays = TextEditingController(text: (widget.plan?.trialPeriodDays ?? 14).toString());
  late bool _advancedReports = widget.plan?.features.contains('advanced_reports') ?? false;
  late bool _isActive = widget.plan?.isActive ?? true;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [_name, _slug, _monthlyPrice, _yearlyPrice, _maxUsers, _maxProducts, _maxBranches, _trialDays]) {
      c.dispose();
    }
    super.dispose();
  }

  int? _parseNullableInt(String text) => text.trim().isEmpty ? null : int.tryParse(text.trim());

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });

    final data = {
      'name': _name.text.trim(),
      'slug': _slug.text.trim(),
      'monthly_price': double.tryParse(_monthlyPrice.text.trim()) ?? 0,
      'yearly_price': double.tryParse(_yearlyPrice.text.trim()) ?? 0,
      'max_users': _parseNullableInt(_maxUsers.text),
      'max_products': _parseNullableInt(_maxProducts.text),
      'max_branches': _parseNullableInt(_maxBranches.text),
      'trial_period_days': int.tryParse(_trialDays.text.trim()) ?? 14,
      'features': [if (_advancedReports) 'advanced_reports'],
      'is_active': _isActive,
    };

    try {
      final repo = ref.read(adminRepositoryProvider);
      if (widget.plan == null) {
        await repo.createPlan(data);
      } else {
        await repo.updatePlan(widget.plan!.id, data);
      }
      ref.invalidate(adminPlansProvider);
      if (mounted) Navigator.of(context).pop();
    } on AdminException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.plan == null ? 'New plan' : 'Edit plan'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
              ),
              TextFormField(
                controller: _slug,
                decoration: const InputDecoration(labelText: 'Slug (e.g. basic)'),
                validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
              ),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _monthlyPrice,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Monthly price'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _yearlyPrice,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Yearly price'),
                    ),
                  ),
                ],
              ),
              TextFormField(
                controller: _maxUsers,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Max users (blank = unlimited)'),
              ),
              TextFormField(
                controller: _maxBranches,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Max branches (blank = unlimited)'),
              ),
              TextFormField(
                controller: _maxProducts,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Max products (blank = unlimited)'),
              ),
              TextFormField(
                controller: _trialDays,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Trial period (days)'),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Advanced reports'),
                value: _advancedReports,
                onChanged: (v) => setState(() => _advancedReports = v),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Active (selectable by shops)'),
                value: _isActive,
                onChanged: (v) => setState(() => _isActive = v),
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Save'),
        ),
      ],
    );
  }
}
