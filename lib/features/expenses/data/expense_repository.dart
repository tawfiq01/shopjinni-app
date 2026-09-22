import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/dio_provider.dart';
import '../models/expense_models.dart';

class ExpenseException implements Exception {
  ExpenseException(this.message);
  final String message;

  @override
  String toString() => message;
}

class ExpenseRepository {
  ExpenseRepository(this._dio);

  final Dio _dio;

  Future<T> _run<T>(Future<T> Function() body) async {
    try {
      return await body();
    } on DioException catch (e) {
      final data = e.response?.data;
      if (data is Map<String, dynamic>) {
        final errors = data['errors'];
        if (errors is Map<String, dynamic> && errors.isNotEmpty) {
          final firstField = errors.values.first;
          if (firstField is List && firstField.isNotEmpty) {
            throw ExpenseException(firstField.first.toString());
          }
        }
        if (data['message'] is String) {
          throw ExpenseException(data['message'] as String);
        }
      }
      throw ExpenseException('Something went wrong. Please check your connection and try again.');
    }
  }

  Future<List<ExpenseCategory>> getCategories() => _run(() async {
        final res = await _dio.get('/expense-categories');
        return (res.data['data'] as List).map((e) => ExpenseCategory.fromJson(e)).toList();
      });

  Future<ExpenseCategory> createCategory(String name) => _run(() async {
        final res = await _dio.post('/expense-categories', data: {'name': name});
        return ExpenseCategory.fromJson(res.data['data']);
      });

  Future<List<Expense>> getExpenses() => _run(() async {
        final res = await _dio.get('/expenses');
        return (res.data['data'] as List).map((e) => Expense.fromJson(e)).toList();
      });

  Future<Expense> createExpense({
    required int categoryId,
    required String date,
    required double amount,
    required int paymentAccountId,
    String? description,
  }) =>
      _run(() async {
        final res = await _dio.post('/expenses', data: {
          'expense_category_id': categoryId,
          'date': date,
          'amount': amount,
          'payment_account_id': paymentAccountId,
          'description': ?description,
        });
        return Expense.fromJson(res.data['data']);
      });
}

final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  return ExpenseRepository(ref.watch(dioProvider));
});
