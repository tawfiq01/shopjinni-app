class BackupStatus {
  const BackupStatus({
    required this.googleConnected,
    this.googleAccountEmail,
    this.driveFolderId,
    this.driveFolderName,
    this.backupTime,
    required this.isEnabled,
    this.lastBackupAt,
    this.lastBackupStatus,
    this.lastBackupMessage,
  });

  factory BackupStatus.fromJson(Map<String, dynamic> json) => BackupStatus(
        googleConnected: json['google_connected'] as bool,
        googleAccountEmail: json['google_account_email'] as String?,
        driveFolderId: json['drive_folder_id'] as String?,
        driveFolderName: json['drive_folder_name'] as String?,
        backupTime: json['backup_time'] as String?,
        isEnabled: json['is_enabled'] as bool,
        lastBackupAt: json['last_backup_at'] as String?,
        lastBackupStatus: json['last_backup_status'] as String?,
        lastBackupMessage: json['last_backup_message'] as String?,
      );

  final bool googleConnected;
  final String? googleAccountEmail;
  final String? driveFolderId;
  final String? driveFolderName;
  /// "HH:mm", null when no schedule has been picked yet.
  final String? backupTime;
  final bool isEnabled;
  final String? lastBackupAt;
  final String? lastBackupStatus;
  final String? lastBackupMessage;
}

class DriveFolder {
  const DriveFolder({required this.id, required this.name});

  factory DriveFolder.fromJson(Map<String, dynamic> json) => DriveFolder(
        id: json['id'] as String,
        name: json['name'] as String,
      );

  final String id;
  final String name;
}

class BackupLogEntry {
  const BackupLogEntry({
    required this.id,
    required this.trigger,
    required this.status,
    this.fileName,
    this.fileSizeBytes,
    this.message,
    required this.createdAt,
  });

  factory BackupLogEntry.fromJson(Map<String, dynamic> json) => BackupLogEntry(
        id: json['id'] as int,
        trigger: json['trigger'] as String,
        status: json['status'] as String,
        fileName: json['file_name'] as String?,
        fileSizeBytes: json['file_size_bytes'] as int?,
        message: json['message'] as String?,
        createdAt: json['created_at'] as String,
      );

  final int id;
  final String trigger; // 'manual' or 'scheduled'
  final String status; // 'success' or 'failed'
  final String? fileName;
  final int? fileSizeBytes;
  final String? message;
  final String createdAt;

  bool get isSuccess => status == 'success';
}
