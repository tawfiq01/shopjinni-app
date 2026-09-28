import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/app_user.dart';
import '../../core/auth/auth_state.dart';
import '../../core/theme/theme_controller.dart';
import '../accounting/presentation/accounts_screen.dart';
import '../backup/presentation/backup_settings_screen.dart';
import '../branches/presentation/branches_screen.dart';
import '../catalog/presentation/catalog_home_screen.dart';
import '../company/presentation/company_settings_screen.dart';
import '../customers/presentation/customers_screen.dart';
import '../distributors/presentation/distributors_screen.dart';
import '../expenses/presentation/expenses_screen.dart';
import '../inventory/presentation/stock_transfers_screen.dart';
import '../purchasing/presentation/purchases_screen.dart';
import '../reports/presentation/reports_home_screen.dart';
import '../roles/presentation/roles_screen.dart';
import '../sales/presentation/pos_screen.dart';
import '../subscription/application/subscription_providers.dart';
import '../subscription/models/company_subscription.dart';
import '../subscription/presentation/subscription_screen.dart';
import '../users/presentation/users_screen.dart';
import 'widgets/change_password_dialog.dart';
import 'widgets/dashboard_summary_section.dart';
import 'widgets/edit_profile_dialog.dart';
import 'widgets/subscription_status_banner.dart';

class _ModuleTile {
  const _ModuleTile(this.label, this.icon, {this.builder, this.requiredPermission});
  final String label;
  final IconData icon;
  final WidgetBuilder? builder;
  // If set, the tile is hidden entirely for users without this permission
  // (the backend gives them a flat 403 for the whole module, unlike most
  // other screens which just hide admin-only actions).
  final String? requiredPermission;

  bool get enabled => builder != null;
}

final _modules = [
  _ModuleTile('Catalog', Icons.category_outlined, builder: (_) => const CatalogHomeScreen()),
  _ModuleTile('Distributors', Icons.local_shipping_outlined,
      builder: (_) => const DistributorsScreen()),
  _ModuleTile('Purchases', Icons.shopping_bag_outlined, builder: (_) => const PurchasesScreen()),
  _ModuleTile('POS / Sales', Icons.point_of_sale_outlined, builder: (_) => const PosScreen()),
  _ModuleTile('Customers', Icons.people_outline, builder: (_) => const CustomersScreen()),
  _ModuleTile('Accounts', Icons.account_balance_outlined, builder: (_) => const AccountsScreen()),
  _ModuleTile('Expenses', Icons.receipt_long_outlined, builder: (_) => const ExpensesScreen()),
  _ModuleTile('Reports', Icons.bar_chart_outlined, builder: (_) => const ReportsHomeScreen()),
  _ModuleTile('Branches', Icons.store_outlined, builder: (_) => const BranchesScreen()),
  _ModuleTile('Stock Transfer', Icons.compare_arrows, builder: (_) => const StockTransfersScreen()),
  _ModuleTile('Staff Accounts', Icons.admin_panel_settings_outlined,
      builder: (_) => const UsersScreen(), requiredPermission: 'users.manage'),
  _ModuleTile('Manage Roles', Icons.shield_outlined,
      builder: (_) => const RolesScreen(), requiredPermission: 'users.manage'),
  _ModuleTile('Database Backup', Icons.backup_outlined,
      builder: (_) => const BackupSettingsScreen(), requiredPermission: 'backup.manage'),
];

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final AppUser? user = authState.user;
    final subscriptionAsync = ref.watch(currentSubscriptionProvider);
    final isBlocked = subscriptionAsync.asData?.value.isBlocked ?? false;
    final isDarkMode = ref.watch(themeModeProvider) == ThemeMode.dark;
    final visibleModules = _modules
        .where((m) => m.requiredPermission == null || (user?.can(m.requiredPermission!) ?? false))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundImage:
                  user?.companyLogoUrl != null ? NetworkImage(user!.companyLogoUrl!) : null,
              child: user?.companyLogoUrl == null
                  ? const Icon(Icons.storefront_outlined, size: 18)
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                user?.companyName ?? 'শপজিনি',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              switch (value) {
                case 'shop_settings':
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const CompanySettingsScreen()),
                  );
                  break;
                case 'billing':
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
                  );
                  break;
                case 'my_profile':
                  showEditProfileDialog(context, ref);
                  break;
                case 'change_password':
                  showChangePasswordDialog(context, ref);
                  break;
                case 'toggle_theme':
                  ref.read(themeModeProvider.notifier).toggle();
                  break;
                case 'logout':
                  ref.read(authControllerProvider.notifier).logout();
                  break;
              }
            },
            itemBuilder: (context) => [
              if (user?.can('company.manage') ?? false) ...[
                const PopupMenuItem(
                  value: 'shop_settings',
                  child: ListTile(
                    leading: Icon(Icons.storefront_outlined),
                    title: Text('Shop Settings'),
                  ),
                ),
                const PopupMenuItem(
                  value: 'billing',
                  child: ListTile(
                    leading: Icon(Icons.workspace_premium_outlined),
                    title: Text('Billing / Subscription'),
                  ),
                ),
              ],
              const PopupMenuItem(
                value: 'my_profile',
                child: ListTile(
                  leading: Icon(Icons.person_outline),
                  title: Text('My Profile'),
                ),
              ),
              const PopupMenuItem(
                value: 'change_password',
                child: ListTile(
                  leading: Icon(Icons.lock_outline),
                  title: Text('Change Password'),
                ),
              ),
              PopupMenuItem(
                value: 'toggle_theme',
                child: ListTile(
                  leading: Icon(isDarkMode ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
                  title: Text(isDarkMode ? 'Light Mode' : 'Dark Mode'),
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: ListTile(
                  leading: Icon(Icons.logout),
                  title: Text('Log out'),
                ),
              ),
            ],
          ),
        ],
      ),
      body: user == null
          ? const SizedBox.shrink()
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundImage: user.avatarUrl != null ? NetworkImage(user.avatarUrl!) : null,
                      child: user.avatarUrl == null
                          ? Text(user.name.isNotEmpty ? user.name[0].toUpperCase() : '?')
                          : null,
                    ),
                    title: Text(user.name),
                    subtitle: Text(
                      [
                        user.email,
                        if (user.branchName != null) user.branchName!,
                        user.roles.join(', '),
                      ].join(' · '),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ...switch (subscriptionAsync.asData?.value) {
                  null => const <Widget>[],
                  final s when s.isBlocked => [
                      _BlockedSubscriptionNotice(
                        subscription: s,
                        onTap: () => Navigator.of(context)
                            .push(MaterialPageRoute(builder: (_) => const SubscriptionScreen())),
                      ),
                    ],
                  final s when s.status == 'trial' || s.status == 'payment_due' => [
                      SubscriptionStatusBanner(
                        subscription: s,
                        onTap: () => Navigator.of(context)
                            .push(MaterialPageRoute(builder: (_) => const SubscriptionScreen())),
                      ),
                    ],
                  _ => const <Widget>[],
                },
                if (!isBlocked) ...[
                  const SizedBox(height: 16),
                  Text('Overview', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  const DashboardSummarySection(),
                  const SizedBox(height: 24),
                  Text('Modules', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: visibleModules.length,
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 180,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.1,
                  ),
                  itemBuilder: (context, index) {
                    final module = visibleModules[index];
                    return Card(
                      color: Theme.of(context).colorScheme.surfaceContainerLow,
                      child: InkWell(
                        onTap: module.enabled
                            ? () => Navigator.of(context).push(
                                  MaterialPageRoute(builder: module.builder!),
                                )
                            : () => ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('${module.label} — coming soon')),
                                ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(module.icon, size: 32),
                              const SizedBox(height: 8),
                              Text(module.label, textAlign: TextAlign.center),
                              if (!module.enabled) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'Coming soon',
                                  style: Theme.of(context).textTheme.labelSmall,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                  ),
                ],
              ],
            ),
    );
  }
}

class _BlockedSubscriptionNotice extends StatelessWidget {
  const _BlockedSubscriptionNotice({required this.subscription, required this.onTap});

  final CompanySubscription subscription;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final message = switch (subscription.status) {
      'grace' => "Your shop's subscription is in its grace period. Renew now to avoid losing access.",
      'expired' => "Your shop's subscription has expired. Renew to keep using শপজিনি.",
      'suspended' => 'Your shop has been suspended. Contact support for help.',
      _ => "Your shop's subscription needs attention.",
    };

    return Card(
      color: scheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.lock_outline, color: scheme.onErrorContainer, size: 32),
            const SizedBox(height: 12),
            Text(message, style: TextStyle(color: scheme.onErrorContainer)),
            const SizedBox(height: 16),
            FilledButton(onPressed: onTap, child: const Text('View billing')),
          ],
        ),
      ),
    );
  }
}
