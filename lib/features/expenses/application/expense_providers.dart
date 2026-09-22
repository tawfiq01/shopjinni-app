import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/expense_repository.dart';
import '../models/expense_models.dart';

final expenseCategoriesProvider = FutureProvider.autoDispose<List<ExpenseCategory>>((ref) {
  return ref.watch(expenseRepositoryProvider).getCategories();
});

final expensesProvider = FutureProvider.autoDispose<List<Expense>>((ref) {
  return ref.watch(expenseRepositoryProvider).getExpenses();
});
