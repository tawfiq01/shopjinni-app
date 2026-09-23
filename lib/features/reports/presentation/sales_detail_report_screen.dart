import 'dart:typed_data';

import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/reports_providers.dart';
import '../data/reports_repository.dart';
import '../models/report_models.dart';

class SalesDetailReportScreen extends ConsumerStatefulWidget {
  const SalesDetailReportScreen({super.key});

  @override
  ConsumerState<SalesDetailReportScreen> createState() => _SalesDetailReportScreenState();
}

class _SalesDetailReportScreenState extends ConsumerState<SalesDetailReportScreen> {
  bool _downloading = false;

  Future<void> _pickDateRange() async {
    final current = ref.read(salesDetailsDateRangeProvider);
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: current,
    );
    if (picked != null) {
      ref.read(salesDetailsDateRangeProvider.notifier).set(picked);
    }
  }

  Future<void> _download(SalesDetailReport report) async {
    setState(() => _downloading = true);
    try {
      final range = ref.read(salesDetailsDateRangeProvider);
      final bytes = await ref.read(reportsRepositoryProvider).exportSalesDetails(
            from: range?.start,
            to: range?.end,
          );
      await FileSaver.instance.saveFile(
        name: 'sales-details_${report.from}_to_${report.to}',
        bytes: Uint8List.fromList(bytes),
        fileExtension: 'xlsx',
        mimeType: MimeType.microsoftExcel,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Excel file downloaded.')));
      }
    } on ReportsException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final reportAsync = ref.watch(salesDetailsReportProvider);
    final range = ref.watch(salesDetailsDateRangeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales Details Report'),
        actions: [
          reportAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
            data: (report) => IconButton(
              icon: _downloading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.download_outlined),
              tooltip: 'Download as Excel',
              onPressed: _downloading ? null : () => _download(report),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: OutlinedButton.icon(
              icon: const Icon(Icons.date_range_outlined),
              label: Text(
                range == null
                    ? 'Last 30 days (tap to change)'
                    : '${_fmt(range.start)} to ${_fmt(range.end)}',
              ),
              onPressed: _pickDateRange,
            ),
          ),
          Expanded(
            child: reportAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Failed to load sales details: $err')),
              data: (report) {
                if (report.rows.isEmpty) {
                  return const Center(child: Text('No sales in this range.'));
                }
                return Column(
                  children: [
                    Container(
                      width: double.infinity,
                      color: Theme.of(context).colorScheme.surfaceContainerLow,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${report.totalQuantity} unit(s) · ${report.rows.length} line(s)'),
                          Text(
                            'Total: ${report.totalSales.toStringAsFixed(2)}'
                            '${report.totalProfit != null ? ' · Profit: ${report.totalProfit!.toStringAsFixed(2)}' : ''}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.separated(
                        itemCount: report.rows.length,
                        separatorBuilder: (context, index) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final row = report.rows[index];
                          return ListTile(
                            title: Text(
                              row.isDemo ? '${row.displayName} · DEMO' : row.displayName,
                              style: TextStyle(
                                color: row.isDemo ? Colors.red.shade700 : null,
                                fontWeight: row.isDemo ? FontWeight.bold : null,
                              ),
                            ),
                            subtitle: Text(
                              '${row.invoiceNumber} · ${row.saleDate}'
                              '${row.customer != null ? ' · ${row.customer}' : ''}'
                              '${row.imei != null ? ' · IMEI ${row.imei}' : ''}'
                              '\n${row.quantity} × ${row.unitPrice.toStringAsFixed(2)}'
                              '${row.discount > 0 ? ' - ${row.discount.toStringAsFixed(2)} disc.' : ''}'
                              '${row.profit != null ? ' · profit ${row.profit!.toStringAsFixed(2)}' : ''}',
                            ),
                            isThreeLine: true,
                            trailing: Text(
                              row.lineTotal.toStringAsFixed(2),
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
