import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_state.dart';
import '../application/customer_providers.dart';
import 'customer_detail_screen.dart';
import 'customer_form_screen.dart';

class CustomersScreen extends ConsumerWidget {
  const CustomersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customersAsync = ref.watch(customersProvider);
    final canManage = ref.watch(authControllerProvider).user?.can('customers.manage') ?? false;

    return Scaffold(
      appBar: AppBar(title: const Text('Customers')),
      floatingActionButton: canManage
          ? FloatingActionButton.extended(
              icon: const Icon(Icons.add),
              label: const Text('New Customer'),
              onPressed: () async {
                final created = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(builder: (_) => const CustomerFormScreen()),
                );
                if (created == true) ref.invalidate(customersProvider);
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
                hintText: 'Search by name or mobile…',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (value) => ref.read(customerSearchProvider.notifier).set(value),
            ),
          ),
          Expanded(
            child: customersAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Failed to load customers: $err')),
              data: (customers) {
                if (customers.isEmpty) {
                  return const Center(child: Text('No customers yet.'));
                }
                return ListView.separated(
                  itemCount: customers.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final customer = customers[index];
                    final due = customer.currentBalance;
                    return ListTile(
                      title: Text(customer.name),
                      subtitle: Text(customer.mobile),
                      trailing: Text(
                        due == 0 ? 'Settled' : 'Due ${due.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: due > 0 ? Colors.red.shade700 : Colors.green.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onTap: () async {
                        await Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => CustomerDetailScreen(customer: customer),
                        ));
                        ref.invalidate(customersProvider);
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
