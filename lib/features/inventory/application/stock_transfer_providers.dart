import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/stock_transfer_repository.dart';
import '../models/stock_transfer_models.dart';

final stockTransfersProvider = FutureProvider.autoDispose<List<StockTransferSummary>>((ref) {
  return ref.watch(stockTransferRepositoryProvider).getTransfers();
});
