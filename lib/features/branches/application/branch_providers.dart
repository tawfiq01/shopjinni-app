import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/branch_repository.dart';
import '../models/branch.dart';

final branchesProvider = FutureProvider.autoDispose<List<Branch>>((ref) {
  return ref.watch(branchRepositoryProvider).getBranches();
});
