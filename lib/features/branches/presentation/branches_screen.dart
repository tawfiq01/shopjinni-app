import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_state.dart';
import '../application/branch_providers.dart';
import '../data/branch_repository.dart';
import '../models/branch.dart';

class BranchesScreen extends ConsumerWidget {
  const BranchesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final branchesAsync = ref.watch(branchesProvider);
    final canManage = ref.watch(authControllerProvider).user?.can('branches.manage') ?? false;

    return Scaffold(
      appBar: AppBar(title: const Text('Branches')),
      floatingActionButton: canManage
          ? FloatingActionButton.extended(
              icon: const Icon(Icons.add),
              label: const Text('New Branch'),
              onPressed: () => _showAddBranchDialog(context, ref),
            )
          : null,
      body: branchesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Failed to load branches: $err')),
        data: (branches) {
          if (branches.isEmpty) {
            return const Center(child: Text('No branches yet.'));
          }
          return ListView.separated(
            itemCount: branches.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final branch = branches[index];
              return ListTile(
                title: Text(branch.name),
                subtitle: Text([
                  if (branch.isMain) 'Main branch',
                  if (branch.address != null) branch.address!,
                  if (branch.phone != null) branch.phone!,
                ].join(' · ')),
                trailing: canManage ? const Icon(Icons.edit_outlined, size: 20) : null,
                onTap: canManage ? () => _showEditBranchDialog(context, ref, branch) : null,
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _showAddBranchDialog(BuildContext context, WidgetRef ref) async {
    final nameController = TextEditingController();
    final addressController = TextEditingController();
    final phoneController = TextEditingController();

    final created = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Branch'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Branch name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: addressController,
              decoration: const InputDecoration(labelText: 'Address (optional)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(labelText: 'Phone (optional)'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Create')),
        ],
      ),
    );

    if (created != true || !context.mounted) return;
    if (nameController.text.trim().isEmpty) return;

    try {
      await ref.read(branchRepositoryProvider).createBranch(
            name: nameController.text.trim(),
            address: addressController.text.trim(),
            phone: phoneController.text.trim(),
          );
      ref.invalidate(branchesProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Branch created.')));
      }
    } on BranchException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  Future<void> _showEditBranchDialog(BuildContext context, WidgetRef ref, Branch branch) async {
    final nameController = TextEditingController(text: branch.name);
    final addressController = TextEditingController(text: branch.address);
    final phoneController = TextEditingController(text: branch.phone);
    bool isActive = branch.isActive;

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit Branch'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Branch name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: addressController,
                decoration: const InputDecoration(labelText: 'Address (optional)'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: 'Phone (optional)'),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Active'),
                value: isActive,
                onChanged: (value) => setState(() => isActive = value),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Save')),
          ],
        ),
      ),
    );

    if (saved != true || !context.mounted) return;

    try {
      await ref.read(branchRepositoryProvider).updateBranch(
            branch.id,
            name: nameController.text.trim(),
            address: addressController.text.trim(),
            phone: phoneController.text.trim(),
            isActive: isActive,
          );
      ref.invalidate(branchesProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Branch updated.')));
      }
    } on BranchException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }
}
