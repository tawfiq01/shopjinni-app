import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/admin_repository.dart';
import '../models/admin_company.dart';
import '../models/admin_payment.dart';
import '../models/admin_plan.dart';
import '../models/admin_report_summary.dart';

final adminCompaniesProvider = FutureProvider.autoDispose<List<AdminCompany>>((ref) {
  return ref.watch(adminRepositoryProvider).getCompanies();
});

final adminPlansProvider = FutureProvider.autoDispose<List<AdminPlan>>((ref) {
  return ref.watch(adminRepositoryProvider).getPlans();
});

final adminPaymentsProvider = FutureProvider.autoDispose<List<AdminPayment>>((ref) {
  return ref.watch(adminRepositoryProvider).getPayments();
});

final adminReportSummaryProvider = FutureProvider.autoDispose<AdminReportSummary>((ref) {
  return ref.watch(adminRepositoryProvider).getReportSummary();
});
