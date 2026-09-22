import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/reports_repository.dart';
import '../models/report_models.dart';

class LowStockOnlyNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void set(bool value) => state = value;
}

final lowStockOnlyProvider = NotifierProvider<LowStockOnlyNotifier, bool>(LowStockOnlyNotifier.new);

class StockSearchNotifier extends Notifier<String> {
  @override
  String build() => '';

  void set(String value) => state = value;
}

final stockSearchProvider = NotifierProvider<StockSearchNotifier, String>(StockSearchNotifier.new);

class StockCategoryFilterNotifier extends Notifier<String?> {
  @override
  String? build() => null; // null = all categories

  void set(String? value) => state = value;
}

final stockCategoryFilterProvider =
    NotifierProvider<StockCategoryFilterNotifier, String?>(StockCategoryFilterNotifier.new);

final stockReportProvider = FutureProvider.autoDispose<StockReport>((ref) {
  final lowStockOnly = ref.watch(lowStockOnlyProvider);
  final search = ref.watch(stockSearchProvider);
  return ref.watch(reportsRepositoryProvider).getStockReport(lowStockOnly: lowStockOnly, search: search);
});

// Independent of the low-stock/search/category filters above — the
// Current Stock Details drill-down (Brand > Model > Color) always shows
// everything, so it stays predictable regardless of what's toggled on the
// other Current Stock report.
final stockDetailsProvider = FutureProvider.autoDispose<StockReport>((ref) {
  return ref.watch(reportsRepositoryProvider).getStockReport();
});

final salesSummaryProvider = FutureProvider.autoDispose<SalesSummary>((ref) {
  return ref.watch(reportsRepositoryProvider).getSalesSummary();
});

final purchaseSummaryProvider = FutureProvider.autoDispose<PurchaseSummary>((ref) {
  return ref.watch(reportsRepositoryProvider).getPurchaseSummary();
});

final purchasePriceHistoryProvider =
    FutureProvider.autoDispose.family<List<PurchasePriceHistoryRow>, int>((ref, skuId) {
  return ref.watch(reportsRepositoryProvider).getPurchasePriceHistory(skuId);
});

final stockMovementHistoryProvider =
    FutureProvider.autoDispose.family<StockMovementHistory, int>((ref, skuId) {
  return ref.watch(reportsRepositoryProvider).getStockMovements(skuId);
});

final duesReportProvider = FutureProvider.autoDispose<DuesReport>((ref) {
  return ref.watch(reportsRepositoryProvider).getDues();
});

final cashPositionProvider = FutureProvider.autoDispose<List<CashPositionRow>>((ref) {
  return ref.watch(reportsRepositoryProvider).getCashPosition();
});
