import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_state.dart';
import '../application/distributor_providers.dart';
import 'distributor_detail_screen.dart';
import 'distributor_form_screen.dart';

class DistributorsScreen extends ConsumerWidget {
  const DistributorsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final distributorsAsync = ref.watch(distributorsProvider);
    final canManage = ref.watch(authControllerProvider).user?.can('distributors.manage') ?? false;

    return Scaffold(
      appBar: AppBar(title: const Text('Distributors')),
      floatingActionButton: canManage
          ? FloatingActionButton.extended(
              icon: const Icon(Icons.add),
              label: const Text('New Distributor'),
              onPressed: () async {
                final created = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(builder: (_) => const DistributorFormScreen()),
                );
                if (created == true) ref.invalidate(distributorsProvider);
              },
            )
          : null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search by name, company, or mobile…',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (value) => ref.read(distributorSearchProvider.notifier).set(value),
            ),
          ),
          Expanded(
            child: distributorsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Failed to load distributors: $err')),
              data: (distributors) {
                if (distributors.isEmpty) {
                  return const Center(child: Text('No distributors yet.'));
                }
                return ListView.separated(
                  itemCount: distributors.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final distributor = distributors[index];
                    final due = distributor.currentBalance;
                    return ListTile(
                      title: Text(distributor.name),
                      subtitle: Text(distributor.companyName ?? distributor.mobile),
                      trailing: Text(
                        due == 0 ? 'Settled' : 'Due ${due.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: due > 0 ? Colors.red.shade700 : Colors.green.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onTap: () async {
                        await Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => DistributorDetailScreen(distributor: distributor),
                        ));
                        ref.invalidate(distributorsProvider);
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
