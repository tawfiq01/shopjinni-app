import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/subscription_repository.dart';
import '../models/company_subscription.dart';

final currentSubscriptionProvider = FutureProvider.autoDispose<CompanySubscription>((ref) {
  return ref.watch(subscriptionRepositoryProvider).getCurrent();
});

final subscriptionPlansProvider = FutureProvider.autoDispose<List<SubscriptionPlanSummary>>((ref) {
  return ref.watch(subscriptionRepositoryProvider).getPlans();
});
