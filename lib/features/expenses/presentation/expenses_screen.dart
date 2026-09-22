import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../accounting/application/accounting_providers.dart';
import '../../accounting/models/accounting_models.dart';
import '../application/expense_providers.dart';
import '../data/expense_repository.dart';
import '../models/expense_models.dart';

class ExpensesScreen extends StatelessWidget {
  const ExpensesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Expenses'),
          bottom: const TabBar(tabs: [Tab(text: 'Expenses'), Tab(text: 'Categories')]),
        ),
        body: const TabBarView(children: [_ExpensesTab(), _CategoriesTab()]),
      ),
    );
  }
}

class _ExpensesTab extends ConsumerWidget {
  const _ExpensesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(expensesProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('New Expense'),
        onPressed: () async {
          final created = await showDialog<bool>(
            context: context,
            builder: (_) => const _AddExpenseDialog(),
          );
          if (created == true) {
            ref.invalidate(expensesProvider);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Expense recorded.')));
            }
          }
        },
      ),
      body: expensesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Failed to load expenses: $err')),
        data: (expenses) {
          if (expenses.isEmpty) {
            return const Center(child: Text('No expenses recorded yet.'));
          }
          return ListView.separated(
            itemCount: expenses.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final expense = expenses[index];
              return ListTile(
                title: Text(expense.categoryName),
                subtitle: Text(
                  [expense.date, expense.paymentAccountName, expense.description]
                      .where((s) => s != null && s.isNotEmpty)
                      .join(' · '),
                ),
                trailing: Text(
                  expense.amount.toStringAsFixed(2),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _CategoriesTab extends ConsumerWidget {
  const _CategoriesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(expenseCategoriesProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('New Category'),
        onPressed: () async {
          final controller = TextEditingController();
          final name = await showDialog<String>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('New Expense Category'),
              content: TextField(
                controller: controller,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Category name'),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(controller.text.trim()),
                  child: const Text('Save'),
                ),
              ],
            ),
          );
          if (name == null || name.isEmpty) return;
          try {
            await ref.read(expenseRepositoryProvider).createCategory(name);
            ref.invalidate(expenseCategoriesProvider);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Category created.')));
            }
          } on ExpenseException catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
            }
          }
        },
      ),
      body: categoriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Failed to load categories: $err')),
        data: (categories) => ListView.separated(
          itemCount: categories.length,
          separatorBuilder: (context, index) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final category = categories[index];
            return ListTile(
              title: Text(category.name),
              subtitle: Text('Account ${category.accountCode}'),
              trailing: Text(
                category.totalSpent.toStringAsFixed(2),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _AddExpenseDialog extends ConsumerStatefulWidget {
  const _AddExpenseDialog();

  @override
  ConsumerState<_AddExpenseDialog> createState() => _AddExpenseDialogState();
}

class _AddExpenseDialogState extends ConsumerState<_AddExpenseDialog> {
  ExpenseCategory? _category;
  LedgerAccount? _paymentAccount;
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime _date = DateTime.now();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final amount = double.tryParse(_amountController.text.trim());
    if (_category == null || _paymentAccount == null || amount == null || amount <= 0) {
      setState(() => _error = 'Select a category, payment account, and a valid amount.');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      await ref.read(expenseRepositoryProvider).createExpense(
            categoryId: _category!.id,
            date: _date.toIso8601String().split('T').first,
            amount: amount,
            paymentAccountId: _paymentAccount!.id,
            description: _descriptionController.text.trim(),
          );
      if (mounted) Navigator.of(context).pop(true);
    } on ExpenseException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(expenseCategoriesProvider);
    final accountsAsync = ref.watch(accountsProvider);

    return AlertDialog(
      title: const Text('New Expense'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              categoriesAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (err, _) => Text('Failed to load categories: $err'),
                data: (categories) => DropdownButtonFormField<ExpenseCategory>(
                  initialValue: _category,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: categories
                      .map((c) => DropdownMenuItem(value: c, child: Text(c.name)))
                      .toList(),
                  onChanged: (value) => setState(() => _category = value),
                ),
              ),
              const SizedBox(height: 12),
              accountsAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (err, _) => Text('Failed to load accounts: $err'),
                data: (accounts) {
                  final cashLike = accounts.where((a) => a.type == 'asset').toList();
                  return DropdownButtonFormField<LedgerAccount>(
                    initialValue: _paymentAccount,
                    decoration: const InputDecoration(labelText: 'Paid from'),
                    items: cashLike
                        .map((a) => DropdownMenuItem(value: a, child: Text(a.name)))
                        .toList(),
                    onChanged: (value) => setState(() => _paymentAccount = value),
                  );
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Amount'),
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
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description (optional)'),
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
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        FilledButton(
          onPressed: _submitting ? null : _submit,
          child: _submitting
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Save'),
        ),
      ],
    );
  }
}
