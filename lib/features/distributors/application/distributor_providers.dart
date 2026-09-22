import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../accounting/models/accounting_models.dart';
import '../data/distributor_repository.dart';
import '../models/distributor.dart';

class DistributorSearchNotifier extends Notifier<String> {
  @override
  String build() => '';

  void set(String value) => state = value;
}

final distributorSearchProvider =
    NotifierProvider<DistributorSearchNotifier, String>(DistributorSearchNotifier.new);

final distributorsProvider = FutureProvider.autoDispose<List<Distributor>>((ref) {
  final search = ref.watch(distributorSearchProvider);
  return ref.watch(distributorRepositoryProvider).getDistributors(search: search);
});

final distributorLedgerProvider =
    FutureProvider.autoDispose.family<List<LedgerLine>, int>((ref, distributorId) {
  return ref.watch(distributorRepositoryProvider).getLedger(distributorId);
});
