import 'dart:async';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';

import '../models/action_evaluation_request.dart';
import 'backup_file_manager.dart';
import 'evaluation_queue_serializer.dart';
import 'evaluation_queue_service.dart';

/// Handles manual export, import and backup operations for evaluation queues.
class BackupImportExportService {
  BackupImportExportService({
    required this.queueService,
    required this.fileManager,
    required this.serializer,
    this.debugPanelCallback,
  });

  final EvaluationQueueService queueService;
  final BackupFileManager fileManager;
  final EvaluationQueueSerializer serializer;
  final VoidCallback? debugPanelCallback;

  static const String backupsFolder = BackupFileManager.backupsFolder;
  static const String autoBackupsFolder = BackupFileManager.autoBackupsFolder;
  static const String snapshotsFolder = BackupFileManager.snapshotsFolder;
  static const String exportsFolder = BackupFileManager.exportsFolder;
  static const int _backupRetentionLimit = 30;

  List<ActionEvaluationRequest> get _pending => queueService.pending;
  List<ActionEvaluationRequest> get _failed => queueService.failed;
  List<ActionEvaluationRequest> get _completed => queueService.completed;

  Map<String, dynamic> _currentState() => serializer.encodeQueues(
        pending: _pending,
        failed: _failed,
        completed: _completed,
      );

  String _timestamp() => DateFormat('yyyy-MM-dd_HH-mm-ss').format(DateTime.now());

  Future<void> exportEvaluationQueue(BuildContext context) async {
    if (_pending.isEmpty) return;
    try {
      final dir = await fileManager.getBackupDirectory(exportsFolder);
      final fileName = 'evaluation_queue_${_timestamp()}.json';
      final file = await fileManager.createFile(dir, fileName);
      await fileManager.writeJsonFile(file, [for (final e in _pending) e.toJson()]);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Файл сохранён: $fileName'),
            action: SnackBarAction(
              label: 'Открыть',
              onPressed: () => OpenFilex.open(file.path),
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

  Future<void> exportFullQueueState(BuildContext context) async {
    try {
      final dir = await fileManager.getBackupDirectory(exportsFolder);
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
      await fileManager.writeJsonFile(file, _currentState());
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
      final dir = await fileManager.getBackupDirectory(exportsFolder);
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
      final decoded = await fileManager.readJsonFile(File(path));
      final queues = serializer.decodeQueues(decoded);
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
      final dir = await fileManager.getBackupDirectory(exportsFolder);
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        initialDirectory: dir.path,
      );
      if (result == null || result.files.isEmpty) return;
      final path = result.files.single.path;
      if (path == null) return;
      final decoded = await fileManager.readJsonFile(File(path));
      final queues = serializer.decodeQueues(decoded);
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
      final dir = await fileManager.getBackupDirectory(backupsFolder);
      final fileName = 'evaluation_backup_${_timestamp()}.json';
      final file = await fileManager.createFile(dir, fileName);
      await fileManager.writeJsonFile(file, _currentState());
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
      final dir = await fileManager.getBackupDirectory(backupsFolder);
      final fileName = 'quick_backup_${_timestamp()}.json';
      final file = await fileManager.createFile(dir, fileName);
      await fileManager.writeJsonFile(file, _currentState());
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
      final dir = await fileManager.getBackupDirectory(backupsFolder);
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
          final decoded = await fileManager.readJsonFile(File(path));
          final queues = serializer.decodeQueues(decoded);
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
    await fileManager.cleanupOldFiles(backupsFolder, _backupRetentionLimit);
  }

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
      final dir = await fileManager.getBackupDirectory(subfolder);
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

  Future<void> restoreFromAutoBackup(BuildContext context) async {
    try {
      final dir = await fileManager.getBackupDirectory(autoBackupsFolder);
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
      final decoded = await fileManager.readJsonFile(File(path));
      final queues = serializer.decodeQueues(decoded);
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
        final decoded = await fileManager.readJsonFile(File(path));
        final queues = serializer.decodeQueues(decoded);
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
    final dir = await fileManager.getBackupDirectory(backupsFolder);
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
    final dir = await fileManager.getBackupDirectory(autoBackupsFolder);
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
}

