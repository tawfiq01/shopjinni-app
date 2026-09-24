import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/company_repository.dart';
import '../models/company_details.dart';

final companyDetailsProvider = FutureProvider.autoDispose<CompanyDetails>((ref) {
  return ref.watch(companyRepositoryProvider).getCompany();
});
