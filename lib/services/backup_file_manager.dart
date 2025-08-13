import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

/// Manages file and directory operations for evaluation queue backups.
class BackupFileManager {
  static const String backupsFolder = 'evaluation_backups';
  static const String autoBackupsFolder = 'evaluation_autobackups';
  static const String snapshotsFolder = 'evaluation_snapshots';
  static const String exportsFolder = 'evaluation_exports';

  static const int defaultAutoBackupRetentionLimit = 50;

  final int autoBackupRetentionLimit;

  Timer? _autoBackupTimer;
  bool _autoBackupRunning = false;

  BackupFileManager(
      {this.autoBackupRetentionLimit = defaultAutoBackupRetentionLimit});

  /// Returns the backup directory for the given [subfolder], creating it if necessary.
  Future<Directory> getBackupDirectory(String subfolder) async {
    final Directory dir = await getApplicationDocumentsDirectory();
    final Directory target = Directory('${dir.path}/$subfolder');
    try {
      await target.create(recursive: true);
    } catch (_) {}
    return target;
  }

  /// Ensures [dir] exists and returns a file with [name] inside it.
  Future<File> createFile(Directory dir, String name) async {
    await dir.create(recursive: true);
    return File('${dir.path}/$name');
  }

  /// Writes [data] as JSON to [file].
  Future<void> writeJsonFile(File file, Object data) async {
    try {
      await file.writeAsString(jsonEncode(data), flush: true);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to write ${file.path}: $e');
      }
      rethrow;
    }
  }

  /// Reads and decodes a JSON object from [file].
  Future<dynamic> readJsonFile(File file) async {
    final String content = await file.readAsString();
    return jsonDecode(content);
  }

  String _timestamp() =>
      DateFormat('yyyy-MM-dd_HH-mm-ss').format(DateTime.now());

  /// Removes old files in [subfolder] keeping only [retentionLimit] most recent ones.
  Future<void> cleanupOldFiles(String subfolder, int retentionLimit) async {
    try {
      final Directory dir = await getBackupDirectory(subfolder);

      final List<MapEntry<File, DateTime>> entries =
          <MapEntry<File, DateTime>>[];
      await for (final FileSystemEntity entity in dir.list()) {
        if (entity is File && entity.path.endsWith('.json')) {
          try {
            final FileStat stat = await entity.stat();
            entries.add(MapEntry<File, DateTime>(entity, stat.modified));
          } catch (e) {
            if (kDebugMode) {
              debugPrint('Failed to stat ${entity.path}: $e');
            }
          }
        }
      }

      entries.sort((MapEntry<File, DateTime> a, MapEntry<File, DateTime> b) =>
          b.value.compareTo(a.value));
      for (final MapEntry<File, DateTime> entry
          in entries.skip(retentionLimit)) {
        try {
          await entry.key.delete();
        } catch (e) {
          if (kDebugMode) {
            debugPrint('Failed to delete ${entry.key.path}: $e');
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Cleanup error: $e');
      }
    }
  }

  /// Deletes old automatic backup files respecting [autoBackupRetentionLimit].
  Future<void> cleanupOldAutoBackups() async {
    await cleanupOldFiles(autoBackupsFolder, autoBackupRetentionLimit);
  }

  /// Creates a timestamped automatic backup of the evaluation queue returned by [queueStateProvider].
  Future<void> autoBackupEvaluationQueue(
      Map<String, dynamic> Function() queueStateProvider) async {
    if (_autoBackupRunning) return;
    _autoBackupRunning = true;
    try {
      final Directory backupDir = await getBackupDirectory(autoBackupsFolder);
      final File file =
          await createFile(backupDir, 'auto_${_timestamp()}.json');
      await writeJsonFile(file, queueStateProvider());
      await cleanupOldAutoBackups();
      if (kDebugMode) {
        debugPrint('Auto backup created: ${file.path}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Auto backup error: $e');
      }
    } finally {
      _autoBackupRunning = false;
    }
  }

  /// Starts a periodic timer that performs automatic backups using [queueStateProvider].
  void startAutoBackupTimer(Map<String, dynamic> Function() queueStateProvider,
      {Duration interval = const Duration(minutes: 15)}) {
    _autoBackupTimer?.cancel();
    _autoBackupTimer = Timer.periodic(
        interval, (_) => autoBackupEvaluationQueue(queueStateProvider));
  }

  /// Cancels the auto backup timer when no longer needed.
  void dispose() {
    _autoBackupTimer?.cancel();
  }
}
