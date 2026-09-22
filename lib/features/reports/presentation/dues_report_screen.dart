import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/reports_providers.dart';
import '../models/report_models.dart';

class DuesReportScreen extends ConsumerWidget {
  const DuesReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final duesAsync = ref.watch(duesReportProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Dues'),
          bottom: const TabBar(tabs: [Tab(text: 'Customers'), Tab(text: 'Distributors')]),
        ),
        body: duesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text('Failed to load dues: $err')),
          data: (dues) => TabBarView(
            children: [
              _DueList(
                rows: dues.customers,
                total: dues.totalCustomerDue,
                emptyLabel: 'No customers with a due balance.',
              ),
              _DueList(
                rows: dues.distributors,
                total: dues.totalDistributorDue,
                emptyLabel: 'No distributors with a due balance.',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DueList extends StatelessWidget {
  const _DueList({required this.rows, required this.total, required this.emptyLabel});

  final List<DueRow> rows;
  final double total;
  final String emptyLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total Due', style: Theme.of(context).textTheme.titleMedium),
              Text(
                total.toStringAsFixed(2),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: total > 0 ? Colors.red.shade700 : Colors.green.shade700,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: rows.isEmpty
              ? Center(child: Text(emptyLabel))
              : ListView.separated(
                  itemCount: rows.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final row = rows[index];
                    return ListTile(
                      title: Text(row.name),
                      subtitle: Text(row.mobile),
                      trailing: Text(
                        row.due.toStringAsFixed(2),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: row.due > 0 ? Colors.red.shade700 : Colors.green.shade700,
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
