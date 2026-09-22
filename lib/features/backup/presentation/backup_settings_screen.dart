import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../application/backup_providers.dart';
import '../data/backup_repository.dart';
import '../models/backup_models.dart';

class BackupSettingsScreen extends ConsumerStatefulWidget {
  const BackupSettingsScreen({super.key});

  @override
  ConsumerState<BackupSettingsScreen> createState() => _BackupSettingsScreenState();
}

class _BackupSettingsScreenState extends ConsumerState<BackupSettingsScreen> {
  bool _connecting = false;
  bool _savingSettings = false;
  bool _runningBackup = false;
  bool _disconnecting = false;

  List<DriveFolder>? _folders;
  bool _loadingFolders = false;
  String? _folderError;

  DriveFolder? _selectedFolder;
  TimeOfDay? _selectedTime;
  bool _enabled = false;
  bool _localStateInitialized = false;

  void _initLocalStateOnce(BackupStatus status) {
    if (_localStateInitialized) return;
    _localStateInitialized = true;
    _enabled = status.isEnabled;
    if (status.backupTime != null) {
      final parts = status.backupTime!.split(':');
      _selectedTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    }
    if (status.driveFolderId != null && status.driveFolderName != null) {
      _selectedFolder = DriveFolder(id: status.driveFolderId!, name: status.driveFolderName!);
    }
  }

  Future<void> _connectGoogle() async {
    setState(() => _connecting = true);
    try {
      final url = await ref.read(backupRepositoryProvider).getGoogleAuthUrl();
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Finish signing in with Google in the new tab, then come back and tap Refresh.'),
          duration: Duration(seconds: 6),
        ));
      }
    } on BackupException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _connecting = false);
    }
  }

  Future<void> _disconnectGoogle() async {
    setState(() => _disconnecting = true);
    try {
      await ref.read(backupRepositoryProvider).disconnectGoogle();
      _localStateInitialized = false;
      _selectedFolder = null;
      _folders = null;
      ref.invalidate(backupStatusProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Disconnected from Google Drive.')));
      }
    } on BackupException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _disconnecting = false);
    }
  }

  Future<void> _loadFolders() async {
    setState(() {
      _loadingFolders = true;
      _folderError = null;
    });
    try {
      final folders = await ref.read(backupRepositoryProvider).getDriveFolders();
      if (mounted) setState(() => _folders = folders);
    } on BackupException catch (e) {
      if (mounted) setState(() => _folderError = e.message);
    } finally {
      if (mounted) setState(() => _loadingFolders = false);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? const TimeOfDay(hour: 2, minute: 0),
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  Future<void> _saveSettings() async {
    if (_enabled && _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pick a daily backup time before enabling automatic backups.')),
      );
      return;
    }

    setState(() => _savingSettings = true);
    try {
      await ref.read(backupRepositoryProvider).saveSettings(
            driveFolderId: _selectedFolder?.id,
            driveFolderName: _selectedFolder?.name,
            backupTime: _selectedTime == null
                ? null
                : '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}',
            isEnabled: _enabled,
          );
      ref.invalidate(backupStatusProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Backup settings saved.')));
      }
    } on BackupException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _savingSettings = false);
    }
  }

  Future<void> _runNow() async {
    setState(() => _runningBackup = true);
    try {
      final message = await ref.read(backupRepositoryProvider).runNow();
      ref.invalidate(backupStatusProvider);
      ref.invalidate(backupLogsProvider);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } on BackupException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _runningBackup = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusAsync = ref.watch(backupStatusProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Database Backup'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () {
              ref.invalidate(backupStatusProvider);
              ref.invalidate(backupLogsProvider);
            },
          ),
        ],
      ),
      body: statusAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Failed to load backup status: $err')),
        data: (status) {
          _initLocalStateOnce(status);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            status.googleConnected ? Icons.check_circle : Icons.cancel_outlined,
                            color: status.googleConnected ? Colors.green.shade700 : Colors.grey,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            status.googleConnected ? 'Connected to Google Drive' : 'Not connected',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                      if (status.googleConnected && status.googleAccountEmail != null) ...[
                        const SizedBox(height: 4),
                        Text(status.googleAccountEmail!),
                      ],
                      const SizedBox(height: 12),
                      if (!status.googleConnected)
                        FilledButton.icon(
                          icon: const Icon(Icons.login),
                          label: const Text('Connect Google Drive'),
                          onPressed: _connecting ? null : _connectGoogle,
                        )
                      else
                        OutlinedButton.icon(
                          icon: const Icon(Icons.link_off),
                          label: const Text('Disconnect'),
                          onPressed: _disconnecting ? null : _disconnectGoogle,
                        ),
                    ],
                  ),
                ),
              ),
              if (status.googleConnected) ...[
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Destination folder', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        if (_folders == null)
                          FilledButton.tonalIcon(
                            icon: _loadingFolders
                                ? const SizedBox(
                                    height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                                : const Icon(Icons.folder_outlined),
                            label: Text(_loadingFolders ? 'Loading folders…' : 'Load my Drive folders'),
                            onPressed: _loadingFolders ? null : _loadFolders,
                          )
                        else
                          DropdownButtonFormField<DriveFolder>(
                            initialValue: _folders!.any((f) => f.id == _selectedFolder?.id) ? _selectedFolder : null,
                            decoration: const InputDecoration(labelText: 'Folder'),
                            items: _folders!
                                .map((f) => DropdownMenuItem(value: f, child: Text(f.name)))
                                .toList(),
                            onChanged: (value) => setState(() => _selectedFolder = value),
                          ),
                        if (_folderError != null) ...[
                          const SizedBox(height: 8),
                          Text(_folderError!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                        ],
                        if (_selectedFolder == null && _folders == null && status.driveFolderName != null) ...[
                          const SizedBox(height: 8),
                          Text('Currently set to: ${status.driveFolderName}'),
                        ],
                        const SizedBox(height: 16),
                        Text('Daily backup time', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.schedule),
                          title: Text(_selectedTime == null ? 'Not set' : _selectedTime!.format(context)),
                          trailing: const Icon(Icons.edit_outlined, size: 18),
                          onTap: _pickTime,
                        ),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Enable automatic daily backup'),
                          value: _enabled,
                          onChanged: (value) => setState(() => _enabled = value),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: FilledButton(
                                onPressed: _savingSettings ? null : _saveSettings,
                                child: _savingSettings
                                    ? const SizedBox(
                                        height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                                    : const Text('Save Settings'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.backup_outlined),
                                label: Text(_runningBackup ? 'Running…' : 'Backup Now'),
                                onPressed: _runningBackup ? null : _runNow,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                if (status.lastBackupAt != null) ...[
                  const SizedBox(height: 16),
                  Card(
                    child: ListTile(
                      leading: Icon(
                        status.lastBackupStatus == 'success' ? Icons.check_circle_outline : Icons.error_outline,
                        color: status.lastBackupStatus == 'success' ? Colors.green.shade700 : Colors.red.shade700,
                      ),
                      title: Text('Last backup: ${status.lastBackupStatus ?? '-'}'),
                      subtitle: Text(status.lastBackupMessage ?? status.lastBackupAt!),
                    ),
                  ),
                ],
              ],
              const SizedBox(height: 24),
              Text('History', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              _BackupHistoryList(),
            ],
          );
        },
      ),
    );
  }
}

class _BackupHistoryList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(backupLogsProvider);

    return logsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (err, _) => Text('Failed to load history: $err'),
      data: (logs) {
        if (logs.isEmpty) {
          return const Text('No backups have run yet.');
        }
        return Column(
          children: [
            for (final log in logs)
              ListTile(
                leading: Icon(
                  log.isSuccess ? Icons.check_circle_outline : Icons.error_outline,
                  color: log.isSuccess ? Colors.green.shade700 : Colors.red.shade700,
                ),
                title: Text(log.fileName ?? (log.isSuccess ? 'Backup' : 'Backup failed')),
                subtitle: Text(
                  '${log.createdAt} · ${log.trigger}'
                  '${log.message != null ? ' · ${log.message}' : ''}',
                ),
                trailing: log.fileSizeBytes != null
                    ? Text('${(log.fileSizeBytes! / 1024).toStringAsFixed(0)} KB')
                    : null,
              ),
          ],
        );
      },
    );
  }
}
