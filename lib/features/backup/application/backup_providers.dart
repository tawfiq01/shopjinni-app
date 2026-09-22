import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/backup_repository.dart';
import '../models/backup_models.dart';

final backupStatusProvider = FutureProvider.autoDispose<BackupStatus>((ref) {
  return ref.watch(backupRepositoryProvider).getStatus();
});

final backupLogsProvider = FutureProvider.autoDispose<List<BackupLogEntry>>((ref) {
  return ref.watch(backupRepositoryProvider).getLogs();
});
