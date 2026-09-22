import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/accounting_providers.dart';
import '../data/accounting_repository.dart';
import '../models/accounting_models.dart';

class _LineDraft {
  // ignore: unused_element_parameter -- account is set later via the dropdown, never at construction.
  _LineDraft({this.account, this.isDebit = true});
  LedgerAccount? account;
  bool isDebit;
  final amountController = TextEditingController();

  double get amount => double.tryParse(amountController.text.trim()) ?? 0;
}

class NewJournalEntryScreen extends ConsumerStatefulWidget {
  const NewJournalEntryScreen({super.key});

  @override
  ConsumerState<NewJournalEntryScreen> createState() => _NewJournalEntryScreenState();
}

class _NewJournalEntryScreenState extends ConsumerState<NewJournalEntryScreen> {
  final _narrationController = TextEditingController();
  DateTime _date = DateTime.now();
  final List<_LineDraft> _lines = [_LineDraft(isDebit: true), _LineDraft(isDebit: false)];
  bool _submitting = false;
  String? _error;

  double get _totalDebit =>
      _lines.where((l) => l.isDebit).fold(0.0, (sum, l) => sum + l.amount);
  double get _totalCredit =>
      _lines.where((l) => !l.isDebit).fold(0.0, (sum, l) => sum + l.amount);
  bool get _isBalanced =>
      _totalDebit > 0 && (_totalDebit - _totalCredit).abs() < 0.005;

  @override
  void dispose() {
    _narrationController.dispose();
    for (final line in _lines) {
      line.amountController.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (_narrationController.text.trim().isEmpty) {
      setState(() => _error = 'Narration is required.');
      return;
    }
    if (_lines.any((l) => l.account == null || l.amount <= 0)) {
      setState(() => _error = 'Every line needs an account and an amount greater than zero.');
      return;
    }
    if (!_isBalanced) {
      setState(() => _error = 'Total debit must equal total credit.');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      await ref.read(accountingRepositoryProvider).postJournalEntry(
            entryDate: _date.toIso8601String().split('T').first,
            narration: _narrationController.text.trim(),
            lines: _lines
                .map((l) => (
                      accountId: l.account!.id,
                      debit: l.isDebit ? l.amount : 0.0,
                      credit: l.isDebit ? 0.0 : l.amount,
                    ))
                .toList(),
          );
      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Journal entry posted.')));
      }
    } on AccountingException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final accountsAsync = ref.watch(accountsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('New Journal Entry')),
      body: accountsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Failed to load accounts: $err')),
        data: (accounts) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextField(
              controller: _narrationController,
              decoration: const InputDecoration(labelText: 'Narration'),
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Date'),
              subtitle: Text(_date.toIso8601String().split('T').first),
              trailing: const Icon(Icons.calendar_today, size: 18),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100),
                );
                if (picked != null) setState(() => _date = picked);
              },
            ),
            const SizedBox(height: 16),
            for (var i = 0; i < _lines.length; i++) _buildLineRow(i, accounts),
            TextButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Add line'),
              onPressed: () => setState(() => _lines.add(_LineDraft())),
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total Debit: ${_totalDebit.toStringAsFixed(2)}'),
                Text('Total Credit: ${_totalCredit.toStringAsFixed(2)}'),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(
                      height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Post Entry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLineRow(int index, List<LedgerAccount> accounts) {
    final line = _lines[index];
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 3,
            child: DropdownButtonFormField<LedgerAccount>(
              initialValue: line.account,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Account'),
              items: accounts
                  .map((a) => DropdownMenuItem(value: a, child: Text('${a.code} · ${a.name}')))
                  .toList(),
              onChanged: (value) => setState(() => line.account = value),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: TextField(
              controller: line.amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Amount'),
              onChanged: (_) => setState(() {}),
            ),
          ),
          const SizedBox(width: 8),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: true, label: Text('Dr')),
              ButtonSegment(value: false, label: Text('Cr')),
            ],
            selected: {line.isDebit},
            onSelectionChanged: (selection) => setState(() => line.isDebit = selection.first),
          ),
          if (_lines.length > 2)
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: () => setState(() => _lines.removeAt(index)),
            ),
        ],
      ),
    );
  }
}
