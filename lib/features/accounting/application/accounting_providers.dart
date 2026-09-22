import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/accounting_repository.dart';
import '../models/accounting_models.dart';

final accountsProvider = FutureProvider.autoDispose<List<LedgerAccount>>((ref) {
  return ref.watch(accountingRepositoryProvider).getAccounts();
});

final accountLedgerProvider =
    FutureProvider.autoDispose.family<List<LedgerLine>, int>((ref, accountId) {
  return ref.watch(accountingRepositoryProvider).getAccountLedger(accountId);
});
