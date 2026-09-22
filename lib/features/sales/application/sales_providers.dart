import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/sales_repository.dart';
import '../models/sale_models.dart';

final salesProvider = FutureProvider.autoDispose<List<SalesInvoiceSummary>>((ref) {
  return ref.watch(salesRepositoryProvider).getSales();
});
