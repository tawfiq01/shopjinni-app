import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/app_user.dart';
import '../../core/auth/auth_state.dart';
import '../accounting/presentation/accounts_screen.dart';
import '../backup/presentation/backup_settings_screen.dart';
import '../branches/presentation/branches_screen.dart';
import '../catalog/presentation/catalog_home_screen.dart';
import '../customers/presentation/customers_screen.dart';
import '../distributors/presentation/distributors_screen.dart';
import '../expenses/presentation/expenses_screen.dart';
import '../inventory/presentation/stock_transfers_screen.dart';
import '../purchasing/presentation/purchases_screen.dart';
import '../reports/presentation/reports_home_screen.dart';
import '../sales/presentation/pos_screen.dart';
import '../users/presentation/users_screen.dart';
import 'widgets/change_password_dialog.dart';
import 'widgets/dashboard_summary_section.dart';

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
  _ModuleTile('Database Backup', Icons.backup_outlined,
      builder: (_) => const BackupSettingsScreen(), requiredPermission: 'backup.manage'),
];

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final AppUser? user = authState.user;
    final visibleModules = _modules
        .where((m) => m.requiredPermission == null || (user?.can(m.requiredPermission!) ?? false))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('MobiShop'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              switch (value) {
                case 'change_password':
                  showChangePasswordDialog(context, ref);
                  break;
                case 'logout':
                  ref.read(authControllerProvider.notifier).logout();
                  break;
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'change_password',
                child: ListTile(
                  leading: Icon(Icons.lock_outline),
                  title: Text('Change Password'),
                ),
              ),
              PopupMenuItem(
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
                      child: Text(user.name.isNotEmpty ? user.name[0].toUpperCase() : '?'),
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
                const SizedBox(height: 24),
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
            ),
    );
  }
}
