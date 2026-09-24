import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/role_providers.dart';
import '../data/role_repository.dart';
import '../models/role.dart';

class RolesScreen extends ConsumerWidget {
  const RolesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rolesAsync = ref.watch(rolesFullProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Roles')),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('New Role'),
        onPressed: () => _openRoleForm(context, ref, null),
      ),
      body: rolesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Failed to load roles: $err')),
        data: (roles) => ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: roles.length,
          itemBuilder: (context, index) {
            final role = roles[index];
            return Card(
              child: ListTile(
                title: Row(
                  children: [
                    Text(role.name),
                    if (role.isSystem) ...[
                      const SizedBox(width: 8),
                      const Chip(label: Text('Required'), visualDensity: VisualDensity.compact),
                    ],
                  ],
                ),
                subtitle: Text(
                  '${role.permissions.length} permission(s) · ${role.userCount} staff assigned',
                ),
                trailing: role.isSystem
                    ? IconButton(
                        icon: const Icon(Icons.visibility_outlined),
                        tooltip: 'View permissions',
                        onPressed: () => _openRoleForm(context, ref, role, readOnly: true),
                      )
                    : PopupMenuButton<String>(
                        onSelected: (action) {
                          if (action == 'edit') {
                            _openRoleForm(context, ref, role);
                          } else if (action == 'delete') {
                            _confirmDelete(context, ref, role);
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(value: 'edit', child: Text('Edit')),
                          const PopupMenuItem(value: 'delete', child: Text('Delete')),
                        ],
                      ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _openRoleForm(BuildContext context, WidgetRef ref, Role? role, {bool readOnly = false}) {
    showDialog<void>(context: context, builder: (_) => _RoleFormDialog(role: role, readOnly: readOnly));
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, Role role) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete "${role.name}"?'),
        content: Text(
          role.userCount > 0
              ? 'This role is assigned to ${role.userCount} staff member(s). Reassign them first.'
              : 'This cannot be undone.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Delete')),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      await ref.read(roleRepositoryProvider).deleteRole(role.id);
      ref.invalidate(rolesFullProvider);
    } on RoleException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }
}

class _RoleFormDialog extends ConsumerStatefulWidget {
  const _RoleFormDialog({this.role, this.readOnly = false});

  final Role? role;
  final bool readOnly;

  @override
  ConsumerState<_RoleFormDialog> createState() => _RoleFormDialogState();
}

class _RoleFormDialogState extends ConsumerState<_RoleFormDialog> {
  late final _nameController = TextEditingController(text: widget.role?.name);
  late final Set<String> _selectedPermissions = {...?widget.role?.permissions};
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty) {
      setState(() => _error = 'Role name is required.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final repo = ref.read(roleRepositoryProvider);
      if (widget.role == null) {
        await repo.createRole(name: _nameController.text.trim(), permissions: _selectedPermissions.toList());
      } else {
        await repo.updateRole(
          widget.role!.id,
          name: _nameController.text.trim(),
          permissions: _selectedPermissions.toList(),
        );
      }
      ref.invalidate(rolesFullProvider);
      if (mounted) Navigator.of(context).pop();
    } on RoleException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final catalogAsync = ref.watch(permissionCatalogProvider);

    return AlertDialog(
      title: Text(widget.readOnly ? widget.role!.name : (widget.role == null ? 'New role' : 'Edit role')),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!widget.readOnly)
                TextField(
                  controller: _nameController,
                  autofocus: true,
                  decoration: const InputDecoration(labelText: 'Role name'),
                ),
              const SizedBox(height: 12),
              Text('Permissions', style: Theme.of(context).textTheme.labelLarge),
              catalogAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (err, _) => Text('Failed to load permissions: $err'),
                data: (catalog) => Column(
                  children: catalog
                      .map((entry) => CheckboxListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            controlAffinity: ListTileControlAffinity.leading,
                            title: Text(entry.label),
                            value: _selectedPermissions.contains(entry.key),
                            onChanged: widget.readOnly
                                ? null
                                : (checked) => setState(() {
                                      if (checked ?? false) {
                                        _selectedPermissions.add(entry.key);
                                      } else {
                                        _selectedPermissions.remove(entry.key);
                                      }
                                    }),
                          ))
                      .toList(),
                ),
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
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(widget.readOnly ? 'Close' : 'Cancel'),
        ),
        if (!widget.readOnly)
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
