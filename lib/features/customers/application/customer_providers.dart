import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../accounting/models/accounting_models.dart';
import '../data/customer_repository.dart';
import '../models/customer.dart';

class CustomerSearchNotifier extends Notifier<String> {
  @override
  String build() => '';

  void set(String value) => state = value;
}

final customerSearchProvider =
    NotifierProvider<CustomerSearchNotifier, String>(CustomerSearchNotifier.new);

final customersProvider = FutureProvider.autoDispose<List<Customer>>((ref) {
  final search = ref.watch(customerSearchProvider);
  return ref.watch(customerRepositoryProvider).getCustomers(search: search);
});

final customerLedgerProvider =
    FutureProvider.autoDispose.family<List<LedgerLine>, int>((ref, customerId) {
  return ref.watch(customerRepositoryProvider).getLedger(customerId);
});
