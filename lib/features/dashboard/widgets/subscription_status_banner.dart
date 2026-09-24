import 'package:flutter/material.dart';

import '../../subscription/models/company_subscription.dart';

/// Shown on the dashboard for trial/payment_due/grace — a shorter, tappable
/// version of the full status card on SubscriptionScreen. Not shown at all
/// for a healthy `active`/lifetime subscription. `expired`/`suspended`
/// don't use this — DashboardScreen replaces the whole module grid with a
/// full-screen block for those instead (mirrors the backend's hard block
/// with a friendlier message than a raw 403 from every module tap).
class SubscriptionStatusBanner extends StatelessWidget {
  const SubscriptionStatusBanner({super.key, required this.subscription, required this.onTap});

  final CompanySubscription subscription;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final (Color color, String message) = switch (subscription.status) {
      'trial' => (
          scheme.primary,
          subscription.trialDaysLeft != null
              ? 'Trial — ${subscription.trialDaysLeft} day(s) left'
              : 'Your trial is active',
        ),
      'payment_due' => (Colors.orange, 'Payment due — renew to avoid interruption'),
      'grace' => (Colors.deepOrange, 'Subscription in grace period — renew now'),
      _ => (scheme.outline, ''),
    };

    if (message.isEmpty) return const SizedBox.shrink();

    return Card(
      color: color.withValues(alpha: 0.1),
      child: ListTile(
        leading: Icon(Icons.workspace_premium_outlined, color: color),
        title: Text(message, style: TextStyle(color: color)),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
