import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/role_repository.dart';
import '../models/permission_catalog_entry.dart';
import '../models/role.dart';

final rolesFullProvider = FutureProvider.autoDispose<List<Role>>((ref) {
  return ref.watch(roleRepositoryProvider).getRoles();
});

final permissionCatalogProvider = FutureProvider.autoDispose<List<PermissionCatalogEntry>>((ref) {
  return ref.watch(roleRepositoryProvider).getPermissionCatalog();
});
