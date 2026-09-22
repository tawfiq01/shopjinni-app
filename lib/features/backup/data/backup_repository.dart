import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/dio_provider.dart';
import '../models/backup_models.dart';

class BackupException implements Exception {
  BackupException(this.message);
  final String message;

  @override
  String toString() => message;
}

class BackupRepository {
  BackupRepository(this._dio);

  final Dio _dio;

  Future<T> _run<T>(Future<T> Function() body) async {
    try {
      return await body();
    } on DioException catch (e) {
      final data = e.response?.data;
      if (data is Map<String, dynamic> && data['message'] is String) {
        throw BackupException(data['message'] as String);
      }
      throw BackupException('Something went wrong. Please check your connection and try again.');
    }
  }

  Future<BackupStatus> getStatus() => _run(() async {
        final res = await _dio.get('/backup/status');
        return BackupStatus.fromJson(res.data);
      });

  Future<String> getGoogleAuthUrl() => _run(() async {
        final res = await _dio.get('/backup/google-auth-url');
        return res.data['url'] as String;
      });

  Future<void> disconnectGoogle() => _run(() async {
        await _dio.post('/backup/google-disconnect');
      });

  Future<List<DriveFolder>> getDriveFolders() => _run(() async {
        final res = await _dio.get('/backup/drive-folders');
        return (res.data['data'] as List).map((e) => DriveFolder.fromJson(e as Map<String, dynamic>)).toList();
      });

  Future<void> saveSettings({
    String? driveFolderId,
    String? driveFolderName,
    String? backupTime,
    required bool isEnabled,
  }) =>
      _run(() async {
        await _dio.post('/backup/settings', data: {
          'drive_folder_id': driveFolderId,
          'drive_folder_name': driveFolderName,
          'backup_time': backupTime,
          'is_enabled': isEnabled,
        });
      });

  Future<String> runNow() => _run(() async {
        final res = await _dio.post('/backup/run-now');
        return res.data['message'] as String;
      });

  Future<List<BackupLogEntry>> getLogs() => _run(() async {
        final res = await _dio.get('/backup/logs');
        return (res.data['data'] as List).map((e) => BackupLogEntry.fromJson(e as Map<String, dynamic>)).toList();
      });
}

final backupRepositoryProvider = Provider<BackupRepository>((ref) {
  return BackupRepository(ref.watch(dioProvider));
});
