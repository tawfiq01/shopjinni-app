import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/subscription_providers.dart';
import '../data/subscription_repository.dart';
import '../models/company_subscription.dart';

class SubscriptionScreen extends ConsumerStatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  ConsumerState<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends ConsumerState<SubscriptionScreen> {
  int? _changingPlanId;

  Future<void> _changePlan(int planId) async {
    setState(() => _changingPlanId = planId);
    try {
      await ref.read(subscriptionRepositoryProvider).changePlan(planId);
      ref.invalidate(currentSubscriptionProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Plan updated. Pay via bKash/bank and share your reference to activate it.'),
        ));
      }
    } on SubscriptionException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _changingPlanId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final subscriptionAsync = ref.watch(currentSubscriptionProvider);
    final plansAsync = ref.watch(subscriptionPlansProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Billing & Subscription')),
      body: subscriptionAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Failed to load subscription: $err')),
        data: (subscription) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _StatusCard(subscription: subscription),
            const SizedBox(height: 24),
            Text('Usage', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            _UsageBar(label: 'Staff accounts', usage: subscription.usersUsage),
            _UsageBar(label: 'Branches', usage: subscription.branchesUsage),
            _UsageBar(label: 'Products', usage: subscription.productsUsage),
            const SizedBox(height: 24),
            Text('Plans', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            plansAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Text('Failed to load plans: $err'),
              data: (plans) => Column(
                children: plans
                    .map((plan) => _PlanCard(
                          plan: plan,
                          isCurrent: plan.id == subscription.plan.id,
                          isChanging: _changingPlanId == plan.id,
                          onSelect: () => _changePlan(plan.id),
                        ))
                    .toList(),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'To renew or switch plans, pay via bKash/Bank/Cash and share the payment reference with '
                  'your account manager. A super admin will confirm the payment and activate it, usually '
                  'within one business day.',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.subscription});

  final CompanySubscription subscription;

  ({Color color, String label}) _statusMeta(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return switch (subscription.status) {
      'trial' => (color: scheme.primary, label: 'Trial'),
      'active' => (color: Colors.green, label: 'Active'),
      'payment_due' => (color: Colors.orange, label: 'Payment due'),
      'grace' => (color: Colors.deepOrange, label: 'Grace period'),
      'expired' => (color: scheme.error, label: 'Expired'),
      'suspended' => (color: scheme.error, label: 'Suspended'),
      _ => (color: scheme.outline, label: subscription.status),
    };
  }

  @override
  Widget build(BuildContext context) {
    final meta = _statusMeta(context);

    String? subtitle;
    if (subscription.isLifetime) {
      subtitle = 'Never expires';
    } else if (subscription.isTrial && subscription.trialDaysLeft != null) {
      subtitle = '${subscription.trialDaysLeft} day(s) left in trial';
    } else if (subscription.currentPeriodEndsAt != null) {
      final d = subscription.currentPeriodEndsAt!;
      subtitle = 'Renews / ends on ${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: meta.color.withValues(alpha: 0.15),
              child: Icon(Icons.workspace_premium_outlined, color: meta.color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(subscription.plan.name, style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: meta.color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(meta.label, style: TextStyle(color: meta.color, fontSize: 12)),
                      ),
                    ],
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UsageBar extends StatelessWidget {
  const _UsageBar({required this.label, required this.usage});

  final String label;
  final SubscriptionUsage usage;

  @override
  Widget build(BuildContext context) {
    final ratio = usage.isUnlimited ? 0.0 : (usage.max! == 0 ? 1.0 : usage.current / usage.max!);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: Theme.of(context).textTheme.bodyMedium),
              Text(
                usage.isUnlimited ? '${usage.current} / Unlimited' : '${usage.current} / ${usage.max}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 4),
          if (!usage.isUnlimited)
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: ratio.clamp(0.0, 1.0),
                minHeight: 6,
                color: ratio >= 1.0 ? Theme.of(context).colorScheme.error : null,
              ),
            ),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.isCurrent,
    required this.isChanging,
    required this.onSelect,
  });

  final SubscriptionPlanSummary plan;
  final bool isCurrent;
  final bool isChanging;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(plan.name, style: Theme.of(context).textTheme.titleMedium),
                Text('৳${plan.monthlyPrice.toStringAsFixed(0)}/mo · ৳${plan.yearlyPrice.toStringAsFixed(0)}/yr'),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              [
                plan.maxUsers == null ? 'Unlimited staff' : 'Up to ${plan.maxUsers} staff',
                plan.maxBranches == null ? 'unlimited branches' : 'up to ${plan.maxBranches} branch(es)',
                plan.maxProducts == null ? 'unlimited products' : 'up to ${plan.maxProducts} products',
              ].join(' · '),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (plan.features.contains('advanced_reports')) ...[
              const SizedBox(height: 4),
              const Text('Includes advanced cost/profit reports', style: TextStyle(fontSize: 12)),
            ],
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: isCurrent
                  ? const Chip(label: Text('Current plan'))
                  : FilledButton(
                      onPressed: isChanging ? null : onSelect,
                      child: isChanging
                          ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Switch to this plan'),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
