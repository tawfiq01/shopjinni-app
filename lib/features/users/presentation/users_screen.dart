import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_state.dart';
import '../../branches/application/branch_providers.dart';
import '../../branches/models/branch.dart';
import '../application/user_providers.dart';
import '../data/user_repository.dart';
import '../models/staff_user.dart';

class UsersScreen extends ConsumerWidget {
  const UsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(usersProvider);
    final currentUserId = ref.watch(authControllerProvider).user?.id;

    return Scaffold(
      appBar: AppBar(title: const Text('Staff Accounts')),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.person_add_outlined),
        label: const Text('New Staff'),
        onPressed: () => _showUserFormDialog(context, ref, existing: null),
      ),
      body: usersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Failed to load staff: $err')),
        data: (users) {
          if (users.isEmpty) {
            return const Center(child: Text('No staff accounts yet.'));
          }
          return ListView.separated(
            itemCount: users.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final user = users[index];
              return ListTile(
                leading: CircleAvatar(child: Text(user.name.isNotEmpty ? user.name[0].toUpperCase() : '?')),
                title: Text(user.name),
                subtitle: Text([
                  user.email,
                  if (user.role != null) user.role!,
                  if (user.branchName != null) user.branchName!,
                  if (!user.isActive) 'Inactive',
                ].join(' · ')),
                trailing: PopupMenuButton<String>(
                  onSelected: (action) {
                    if (action == 'edit') {
                      _showUserFormDialog(context, ref, existing: user);
                    } else if (action == 'reset_password') {
                      _showResetPasswordDialog(context, ref, user);
                    } else if (action == 'toggle_active') {
                      _toggleActive(context, ref, user);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'edit', child: Text('Edit')),
                    const PopupMenuItem(value: 'reset_password', child: Text('Reset Password')),
                    if (user.id != currentUserId)
                      PopupMenuItem(
                        value: 'toggle_active',
                        child: Text(user.isActive ? 'Deactivate' : 'Activate'),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _toggleActive(BuildContext context, WidgetRef ref, StaffUser user) async {
    try {
      await ref.read(userRepositoryProvider).updateUser(user.id, isActive: !user.isActive);
      ref.invalidate(usersProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(user.isActive ? 'Staff account deactivated.' : 'Staff account activated.')),
        );
      }
    } on UserManagementException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  Future<void> _showResetPasswordDialog(BuildContext context, WidgetRef ref, StaffUser user) async {
    final controller = TextEditingController();
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reset password for ${user.name}'),
        content: TextField(
          controller: controller,
          obscureText: true,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'New password (min 8 characters)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Save')),
        ],
      ),
    );

    if (saved != true || !context.mounted) return;
    if (controller.text.trim().length < 8) return;

    try {
      await ref.read(userRepositoryProvider).resetPassword(user.id, controller.text.trim());
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password updated.')));
      }
    } on UserManagementException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  Future<void> _showUserFormDialog(
    BuildContext context,
    WidgetRef ref, {
    required StaffUser? existing,
  }) async {
    final roles = await ref.read(rolesProvider.future);
    final branches = await ref.read(branchesProvider.future);

    if (!context.mounted) return;

    final nameController = TextEditingController(text: existing?.name);
    final emailController = TextEditingController(text: existing?.email);
    final phoneController = TextEditingController(text: existing?.phone);
    final passwordController = TextEditingController();
    String? role = existing?.role ?? (roles.isNotEmpty ? roles.first : null);
    Branch? branch = existing == null
        ? null
        : branches.where((b) => b.id == existing.branchId).firstOrNull;

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(existing == null ? 'New Staff Account' : 'Edit Staff Account'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: nameController,
                  autofocus: true,
                  decoration: const InputDecoration(labelText: 'Full name'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email (used to log in)'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(labelText: 'Phone (optional)'),
                ),
                if (existing == null) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Password (min 8 characters)'),
                  ),
                ],
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: role,
                  decoration: const InputDecoration(labelText: 'Role'),
                  items: roles.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                  onChanged: (value) => setState(() => role = value),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<Branch?>(
                  initialValue: branch,
                  decoration: const InputDecoration(labelText: 'Branch (optional)'),
                  items: [
                    const DropdownMenuItem<Branch?>(value: null, child: Text('No branch')),
                    ...branches.map((b) => DropdownMenuItem(value: b, child: Text(b.name))),
                  ],
                  onChanged: (value) => setState(() => branch = value),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(existing == null ? 'Create' : 'Save'),
            ),
          ],
        ),
      ),
    );

    if (saved != true || !context.mounted) return;
    if (nameController.text.trim().isEmpty || emailController.text.trim().isEmpty || role == null) {
      return;
    }

    try {
      if (existing == null) {
        if (passwordController.text.trim().length < 8) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Password too short'),
              content: const Text('Password must be at least 8 characters.'),
              actions: [
                TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('OK')),
              ],
            ),
          );
          return;
        }
        await ref.read(userRepositoryProvider).createUser(
              name: nameController.text.trim(),
              email: emailController.text.trim(),
              password: passwordController.text.trim(),
              role: role!,
              phone: phoneController.text.trim(),
              branchId: branch?.id,
            );
      } else {
        await ref.read(userRepositoryProvider).updateUser(
              existing.id,
              name: nameController.text.trim(),
              email: emailController.text.trim(),
              phone: phoneController.text.trim(),
              branchId: branch?.id,
              role: role,
            );
      }
      ref.invalidate(usersProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(existing == null ? 'Staff account created.' : 'Staff account updated.')),
        );
      }
    } on UserManagementException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }
}
