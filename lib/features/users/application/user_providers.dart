import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/user_repository.dart';
import '../models/staff_user.dart';

final usersProvider = FutureProvider.autoDispose<List<StaffUser>>((ref) {
  return ref.watch(userRepositoryProvider).getUsers();
});

final rolesProvider = FutureProvider.autoDispose<List<String>>((ref) {
  return ref.watch(userRepositoryProvider).getRoles();
});
