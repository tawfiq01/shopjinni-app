import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/purchase_repository.dart';
import '../models/purchase_models.dart';

final purchasesProvider = FutureProvider.autoDispose<List<PurchaseInvoice>>((ref) {
  return ref.watch(purchaseRepositoryProvider).getPurchases();
});

final paymentMethodsProvider = FutureProvider.autoDispose<List<PaymentMethodOption>>((ref) {
  return ref.watch(purchaseRepositoryProvider).getPaymentMethods();
});
