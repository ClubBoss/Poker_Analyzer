import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../models/action_evaluation_request.dart';
import 'backup_service.dart';
import 'debug_preferences_service.dart';
import 'evaluation_queue_service.dart';

/// Manages creation, loading and cleanup of evaluation queue backups
/// and related import/export utilities.
class BackupManagerService {
  BackupManagerService({
    required this.queueService,
    required this.debugPrefs,
    BackupService? backupService,
  }) : backupService = backupService ?? BackupService();

  final EvaluationQueueService queueService;
  final DebugPreferencesService debugPrefs;
  final BackupService backupService;

  VoidCallback? debugPanelCallback;

  static const String backupsFolder = BackupService.backupsFolder;
  static const String autoBackupsFolder = BackupService.autoBackupsFolder;
  static const String snapshotsFolder = BackupService.snapshotsFolder;
  static const String exportsFolder = BackupService.exportsFolder;

  static const int _snapshotRetentionLimit = 50;
  static const int _backupRetentionLimit = 30;

  List<ActionEvaluationRequest> get _pending => queueService.pending;
  List<ActionEvaluationRequest> get _failed => queueService.failed;
  List<ActionEvaluationRequest> get _completed => queueService.completed;

  Map<String, dynamic> _currentState() => {
        'pending': [for (final e in _pending) e.toJson()],
        'failed': [for (final e in _failed) e.toJson()],
        'completed': [for (final e in _completed) e.toJson()],
      };

  String _timestamp() => DateFormat('yyyy-MM-dd_HH-mm-ss').format(DateTime.now());

  Future<File> _jsonFile(Directory dir, String name) async {
    await dir.create(recursive: true);
    return File('${dir.path}/$name');
  }

  ActionEvaluationRequest _decodeRequest(Map<String, dynamic> json) {
    final map = Map<String, dynamic>.from(json);
    if (map['id'] == null || map['id'] is! String || (map['id'] as String).isEmpty) {
      map['id'] = const Uuid().v4();
    }
    return ActionEvaluationRequest.fromJson(map);
  }

  List<ActionEvaluationRequest> _decodeList(dynamic list) {
    final items = <ActionEvaluationRequest>[];
    if (list is List) {
      for (final item in list) {
        if (item is Map) {
          try {
            items.add(_decodeRequest(Map<String, dynamic>.from(item)));
          } catch (_) {}
        }
      }
    }
    return items;
  }

  Map<String, List<ActionEvaluationRequest>> _decodeQueues(dynamic json) {
    if (json is List) {
      return {
        'pending': _decodeList(json),
        'failed': <ActionEvaluationRequest>[],
        'completed': <ActionEvaluationRequest>[],
      };
    } else if (json is Map) {
      return {
        'pending': _decodeList(json['pending']),
        'failed': _decodeList(json['failed']),
        'completed': _decodeList(json['completed']),
      };
    }
    throw const FormatException();
  }

  Future<Directory> _dir(String subfolder) async {
    return backupService.getBackupDirectory(subfolder);
  }

  Future<void> startAutoBackupTimer() async {
    backupService.startAutoBackupTimer(_currentState);
  }

  void dispose() {
    backupService.dispose();
  }

  Future<void> exportEvaluationQueue(BuildContext context) async {
    if (_pending.isEmpty) return;
    try {
      final dir = await _dir(exportsFolder);
      final fileName = 'evaluation_queue_${_timestamp()}.json';
      final file = await _jsonFile(dir, fileName);
      await backupService.writeJsonFile(file, [for (final e in _pending) e.toJson()]);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Файл сохранён: $fileName'),
            action: SnackBarAction(
              label: 'Открыть',
              onPressed: () => OpenFile.open(file.path),
            ),
          ),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не удалось экспортировать очередь')),
        );
      }
    }
  }

  Future<void> exportQueueToClipboard(BuildContext context) async {
    await queueService.exportToClipboard();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Queue copied to clipboard')),
      );
    }
  }

  Future<void> importQueueFromClipboard(BuildContext context) async {
    await queueService.importFromClipboard();
    if (context.mounted) {
      debugPanelCallback?.call();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Queue imported from clipboard')),
      );
    }
  }

  Future<void> exportFullQueueState(BuildContext context) async {
    try {
      final dir = await _dir(exportsFolder);
      final fileName = 'queue_export_${_timestamp()}.json';
      final savePath = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Full Queue State',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: ['json'],
        initialDirectory: dir.path,
      );
      if (savePath == null) return;
      final file = File(savePath);
      await backupService.writeJsonFile(file, _currentState());
      if (context.mounted) {
        final name = savePath.split(Platform.pathSeparator).last;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Queue exported: $name')),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to export queue')),
        );
      }
    }
  }

  Future<void> importFullQueueState(BuildContext context) async {
    try {
      final dir = await _dir(exportsFolder);
      if (!await dir.exists()) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No export files found')),
          );
        }
        return;
      }
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        initialDirectory: dir.path,
      );
      if (result == null || result.files.isEmpty) return;
      final path = result.files.single.path;
      if (path == null) return;
      final decoded = await backupService.readJsonFile(File(path));
      final queues = _decodeQueues(decoded);
      _pending
        ..clear()
        ..addAll(queues['pending']!);
      _failed
        ..clear()
        ..addAll(queues['failed']!);
      _completed
        ..clear()
        ..addAll(queues['completed']!);
      await queueService.persist();
      debugPanelCallback?.call();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Imported ${_pending.length} pending, ${_failed.length} failed, ${_completed.length} completed evaluations')),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to import queue state')),
        );
      }
    }
  }

  Future<void> restoreFullQueueState(BuildContext context) async {
    try {
      final dir = await _dir(exportsFolder);
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        initialDirectory: dir.path,
      );
      if (result == null || result.files.isEmpty) return;
      final path = result.files.single.path;
      if (path == null) return;
      final decoded = await backupService.readJsonFile(File(path));
      final queues = _decodeQueues(decoded);
      _pending
        ..clear()
        ..addAll(queues['pending']!);
      _failed
        ..clear()
        ..addAll(queues['failed']!);
      _completed
        ..clear()
        ..addAll(queues['completed']!);
      await queueService.persist();
      debugPanelCallback?.call();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Restored ${_pending.length} pending, ${_failed.length} failed, ${_completed.length} completed evaluations')),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to restore full queue state')),
        );
      }
    }
  }

  Future<void> backupEvaluationQueue(BuildContext context) async {
    if (_pending.isEmpty) return;
    try {
      final dir = await _dir(backupsFolder);
      final fileName = 'evaluation_backup_${_timestamp()}.json';
      final file = await _jsonFile(dir, fileName);
      await backupService.writeJsonFile(file, _currentState());
      Future(() => cleanupOldEvaluationBackups());
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Backup created: $fileName')),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не удалось создать бэкап')),
        );
      }
    }
  }

  Future<void> quickBackupEvaluationQueue(BuildContext context) async {
    try {
      final dir = await _dir(backupsFolder);
      final fileName = 'quick_backup_${_timestamp()}.json';
      final file = await _jsonFile(dir, fileName);
      await backupService.writeJsonFile(file, _currentState());
      Future(() => cleanupOldEvaluationBackups());
      debugPanelCallback?.call();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Quick backup saved: $fileName')),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to create quick backup')),
        );
      }
    }
  }

  Future<void> importQuickBackups(BuildContext context) async {
    try {
      final dir = await _dir(backupsFolder);
      if (!await dir.exists()) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No quick backup files found')),
          );
        }
        return;
      }
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        allowMultiple: true,
        initialDirectory: dir.path,
      );
      if (result == null || result.files.isEmpty) return;
      final importedPending = <ActionEvaluationRequest>[];
      final importedFailed = <ActionEvaluationRequest>[];
      final importedCompleted = <ActionEvaluationRequest>[];
      int skipped = 0;
      for (final f in result.files) {
        final path = f.path;
        if (path == null) {
          skipped++;
          continue;
        }
        final name = path.split(Platform.pathSeparator).last;
        if (!name.startsWith('quick_backup_')) {
          skipped++;
          continue;
        }
        try {
          final decoded = await backupService.readJsonFile(File(path));
          final queues = _decodeQueues(decoded);
          importedPending.addAll(queues['pending']!);
          importedFailed.addAll(queues['failed']!);
          importedCompleted.addAll(queues['completed']!);
        } catch (_) {
          skipped++;
        }
      }
      _pending.addAll(importedPending);
      _failed.addAll(importedFailed);
      _completed.addAll(importedCompleted);
      await queueService.persist();
      debugPanelCallback?.call();
      final total =
          importedPending.length + importedFailed.length + importedCompleted.length;
      final msg = skipped == 0
          ? 'Imported $total evaluations from ${result.files.length} files'
          : 'Imported $total evaluations, $skipped files skipped';
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to import quick backups')),
        );
      }
    }
  }

  Future<void> cleanupOldEvaluationBackups() async {
    await backupService.cleanupOldFiles(backupsFolder, _backupRetentionLimit);
  }

  Future<void> cleanupOldEvaluationSnapshots() async {
    await backupService.cleanupOldFiles(snapshotsFolder, _snapshotRetentionLimit);
  }

  Future<void> cleanupOldAutoBackups() async {
    await backupService.cleanupOldFiles(
        autoBackupsFolder, BackupService.defaultAutoBackupRetentionLimit);
  }

  Future<void> exportEvaluationQueueSnapshot(BuildContext context,
      {bool showNotification = true}) async {
    try {
      final dir = await _dir(snapshotsFolder);
      final fileName = 'snapshot_${_timestamp()}.json';
      final file = await _jsonFile(dir, fileName);
      await backupService.writeJsonFile(file, _currentState());
      if (debugPrefs.snapshotRetentionEnabled) {
        await cleanupOldEvaluationSnapshots();
      }
      if (showNotification && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Snapshot saved: ${file.path}')),
        );
      }
    } catch (e) {
      if (showNotification && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to export snapshot')),
        );
      } else if (kDebugMode) {
        debugPrint('Failed to export snapshot: $e');
      }
    }
  }

  void scheduleSnapshotExport() {
    unawaited(exportEvaluationQueueSnapshot(nullContext, showNotification: false));
  }

  /// Dummy context used when no context is available.
  final BuildContext nullContext = _FakeContext();

  Future<void> exportArchive(
      BuildContext context, String subfolder, String prefix) async {
    String emptyMsg;
    String failMsg;
    String dialogTitle;
    switch (subfolder) {
      case backupsFolder:
        emptyMsg = 'No backup files found';
        failMsg = 'Failed to export backups';
        dialogTitle = 'Save Backups Archive';
        break;
      case autoBackupsFolder:
        emptyMsg = 'No auto-backup files found';
        failMsg = 'Failed to export auto-backups';
        dialogTitle = 'Save Auto-Backups Archive';
        break;
      case snapshotsFolder:
        emptyMsg = 'No snapshot files found';
        failMsg = 'Failed to export snapshots';
        dialogTitle = 'Save Snapshots Archive';
        break;
      default:
        emptyMsg = 'No files found';
        failMsg = 'Failed to export archive';
        dialogTitle = 'Save Archive';
    }
    try {
      final dir = await _dir(subfolder);
      if (!await dir.exists()) {
        if (context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(emptyMsg)));
        }
        return;
      }
      final files = await dir.list(recursive: true).whereType<File>().toList();
      if (files.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(emptyMsg)));
        }
        return;
      }
      final archive = Archive();
      for (final file in files) {
        final data = await file.readAsBytes();
        final name = file.path.substring(dir.path.length + 1);
        archive.addFile(ArchiveFile(name, data.length, data));
      }
      final bytes = ZipEncoder().encode(archive);
      if (bytes == null) throw Exception('Could not create archive');
      final fileName = '${prefix}_${_timestamp()}.zip';
      final savePath = await FilePicker.platform.saveFile(
        dialogTitle: dialogTitle,
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: ['zip'],
      );
      if (savePath == null) return;
      final zipFile = File(savePath);
      await zipFile.writeAsBytes(bytes, flush: true);
      if (context.mounted) {
        final name = savePath.split(Platform.pathSeparator).last;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Archive saved: $name')));
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(failMsg)));
      }
    }
  }

  Future<void> exportAllEvaluationBackups(BuildContext context) async {
    await exportArchive(context, backupsFolder, 'evaluation_backups');
  }

  Future<void> exportAutoBackups(BuildContext context) async {
    await exportArchive(context, autoBackupsFolder, 'evaluation_autobackups');
  }

  Future<void> exportSnapshots(BuildContext context) async {
    await exportArchive(context, snapshotsFolder, 'evaluation_snapshots');
  }

  Future<void> restoreFromAutoBackup(BuildContext context) async {
    try {
      final dir = await _dir(autoBackupsFolder);
      if (!await dir.exists()) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No auto-backup files found')),
          );
        }
        return;
      }
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        initialDirectory: dir.path,
      );
      if (result == null || result.files.isEmpty) return;
      final path = result.files.single.path;
      if (path == null) return;
      final decoded = await backupService.readJsonFile(File(path));
      final queues = _decodeQueues(decoded);
      _pending
        ..clear()
        ..addAll(queues['pending']!);
      _failed
        ..clear()
        ..addAll(queues['failed']!);
      _completed
        ..clear()
        ..addAll(queues['completed']!);
      await queueService.persist();
      debugPanelCallback?.call();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Restored ${_pending.length} pending, ${_failed.length} failed, ${_completed.length} completed evaluations')),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to restore auto-backup')),
        );
      }
    }
  }

  Future<void> exportAllEvaluationSnapshots(BuildContext context) async {
    await exportArchive(context, snapshotsFolder, 'evaluation_snapshots');
  }

  Future<void> importEvaluationQueue(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (result == null || result.files.isEmpty) return;
      final path = result.files.single.path;
      if (path == null) return;
      final decoded = await backupService.readJsonFile(File(path));
      if (decoded is! List) throw const FormatException();
      final items = _decodeList(decoded);
      _pending
        ..clear()
        ..addAll(items);
      _failed.clear();
      await queueService.persist();
      debugPanelCallback?.call();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Imported ${items.length} evaluations')),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to import queue')),
        );
      }
    }
  }

  Future<void> restoreEvaluationQueue(BuildContext context) async {
    try {
      final dir = await _dir(backupsFolder);
      if (!await dir.exists()) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No backup files found')),
          );
        }
        return;
      }
      final files = await dir
          .list()
          .where((e) => e is File && e.path.endsWith('.json'))
          .cast<File>()
          .toList();
      if (files.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No backup files found')),
          );
        }
        return;
      }
      files.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));
      final selected = await showDialog<File>(
        context: context,
        builder: (context) => SimpleDialog(
          title: const Text('Select Backup'),
          children: [
            for (final f in files)
              SimpleDialogOption(
                onPressed: () => Navigator.pop(context, f),
                child: Text(f.uri.pathSegments.last),
              ),
          ],
        ),
      );
      if (selected == null) return;
      final decoded = await backupService.readJsonFile(selected);
      final queues = _decodeQueues(decoded);
      _pending
        ..clear()
        ..addAll(queues['pending']!);
      _failed
        ..clear()
        ..addAll(queues['failed']!);
      _completed
        ..clear()
        ..addAll(queues['completed']!);
      await queueService.persist();
      debugPanelCallback?.call();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Restored ${_pending.length} pending, ${_failed.length} failed, ${_completed.length} completed evaluations')),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to restore queue')),
        );
      }
    }
  }

  Future<void> _bulkImport(
    BuildContext context,
    String? initialDir,
    bool Function(String name)? fileFilter,
  ) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      allowMultiple: true,
      initialDirectory: initialDir,
    );
    if (result == null || result.files.isEmpty) return;
    final importedPending = <ActionEvaluationRequest>[];
    final importedFailed = <ActionEvaluationRequest>[];
    final importedCompleted = <ActionEvaluationRequest>[];
    int skipped = 0;
    for (final f in result.files) {
      final path = f.path;
      if (path == null) {
        skipped++;
        continue;
      }
      final name = path.split(Platform.pathSeparator).last;
      if (fileFilter != null && !fileFilter(name)) {
        skipped++;
        continue;
      }
      try {
        final decoded = await backupService.readJsonFile(File(path));
        final queues = _decodeQueues(decoded);
        importedPending.addAll(queues['pending']!);
        importedFailed.addAll(queues['failed']!);
        importedCompleted.addAll(queues['completed']!);
      } catch (_) {
        skipped++;
      }
    }
    _pending.addAll(importedPending);
    _failed.addAll(importedFailed);
    _completed.addAll(importedCompleted);
    await queueService.persist();
    debugPanelCallback?.call();
    final total =
        importedPending.length + importedFailed.length + importedCompleted.length;
    final msg = skipped == 0
        ? 'Imported $total evaluations from ${result.files.length} files'
        : 'Imported $total evaluations, $skipped files skipped';
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
    }
  }

  Future<void> bulkImportEvaluationQueue(BuildContext context) async {
    await _bulkImport(context, null, null);
  }

  Future<void> bulkImportEvaluationBackups(BuildContext context) async {
    final dir = await _dir(backupsFolder);
    if (!await dir.exists()) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No backup files found')),
        );
      }
      return;
    }
    await _bulkImport(context, dir.path, null);
  }

  Future<void> bulkImportAutoBackups(BuildContext context) async {
    final dir = await _dir(autoBackupsFolder);
    if (!await dir.exists()) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No auto-backup files found')),
        );
      }
      return;
    }
    await _bulkImport(context, dir.path, null);
  }

  Future<void> importEvaluationQueueSnapshot(BuildContext context) async {
    try {
      final dir = await _dir(snapshotsFolder);
      if (!await dir.exists()) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No snapshot files found')),
          );
        }
        return;
      }
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        initialDirectory: dir.path,
      );
      if (result == null || result.files.isEmpty) return;
      final path = result.files.single.path;
      if (path == null) return;
      final decoded = await backupService.readJsonFile(File(path));
      final queues = _decodeQueues(decoded);
      _pending
        ..clear()
        ..addAll(queues['pending']!);
      _failed
        ..clear()
        ..addAll(queues['failed']!);
      _completed
        ..clear()
        ..addAll(queues['completed']!);
      await queueService.persist();
      debugPanelCallback?.call();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Imported ${_pending.length} pending, ${_failed.length} failed, ${_completed.length} completed evaluations')),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to import snapshot')),
        );
      }
    }
  }

  Future<void> bulkImportEvaluationSnapshots(BuildContext context) async {
    final dir = await _dir(snapshotsFolder);
    if (!await dir.exists()) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No snapshot files found')),
        );
      }
      return;
    }
    await _bulkImport(context, dir.path, null);
  }
}

class _FakeContext extends BuildContext {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
