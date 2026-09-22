import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/dio_provider.dart';
import '../models/accounting_models.dart';

class AccountingException implements Exception {
  AccountingException(this.message);
  final String message;

  @override
  String toString() => message;
}

class AccountingRepository {
  AccountingRepository(this._dio);

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
            throw AccountingException(firstField.first.toString());
          }
        }
        if (data['message'] is String) {
          throw AccountingException(data['message'] as String);
        }
      }
      throw AccountingException('Something went wrong. Please check your connection and try again.');
    }
  }

  Future<List<LedgerAccount>> getAccounts() => _run(() async {
        final res = await _dio.get('/accounting/accounts');
        return (res.data['data'] as List).map((e) => LedgerAccount.fromJson(e)).toList();
      });

  Future<List<LedgerLine>> getAccountLedger(int accountId) => _run(() async {
        final res = await _dio.get('/accounting/accounts/$accountId/ledger');
        return (res.data['lines'] as List).map((e) => LedgerLine.fromJson(e)).toList();
      });

  Future<void> postJournalEntry({
    required String entryDate,
    required String narration,
    required List<({int accountId, double debit, double credit})> lines,
  }) =>
      _run(() async {
        await _dio.post('/accounting/journal-entries', data: {
          'entry_date': entryDate,
          'narration': narration,
          'lines': lines
              .map((l) => {
                    'account_id': l.accountId,
                    if (l.debit > 0) 'debit': l.debit,
                    if (l.credit > 0) 'credit': l.credit,
                  })
              .toList(),
        });
      });
}

final accountingRepositoryProvider = Provider<AccountingRepository>((ref) {
  return AccountingRepository(ref.watch(dioProvider));
});
