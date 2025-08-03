import 'dart:async';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/action_evaluation_request.dart';
import 'backup_file_manager.dart';
import 'evaluation_queue_serializer.dart';
import 'evaluation_queue_service.dart';
import '../utils/app_logger.dart';

/// Handles snapshot creation, loading and import/export utilities for the
/// evaluation queue.
class BackupSnapshotService {
  BackupSnapshotService({
    required this.queueService,
    required this.fileManager,
    required this.serializer,
    this.debugPanelCallback,
  });

  final EvaluationQueueService queueService;
  final BackupFileManager fileManager;
  final EvaluationQueueSerializer serializer;
  final VoidCallback? debugPanelCallback;

  static const String snapshotsFolder = BackupFileManager.snapshotsFolder;
  static const int _snapshotRetentionLimit = 50;

  List<ActionEvaluationRequest> get _pending => queueService.pending;
  List<ActionEvaluationRequest> get _failed => queueService.failed;
  List<ActionEvaluationRequest> get _completed => queueService.completed;

  String _timestamp() => DateFormat('yyyy-MM-dd_HH-mm-ss').format(DateTime.now());

  Future<void> cleanupOldEvaluationSnapshots() async {
    await fileManager.cleanupOldFiles(snapshotsFolder, _snapshotRetentionLimit);
  }

  Future<void> saveQueueSnapshot(
    Map<String, dynamic> state, {
    bool showNotification = true,
    bool snapshotRetentionEnabled = true,
  }) async {
    try {
      final dir = await fileManager.getBackupDirectory(snapshotsFolder);
      final fileName = 'snapshot_${_timestamp()}.json';
      final file = await fileManager.createFile(dir, fileName);
      await fileManager.writeJsonFile(file, state);
      if (snapshotRetentionEnabled) {
        await cleanupOldEvaluationSnapshots();
      }
      if (showNotification) {
        AppLogger.log('Snapshot saved: ${file.path}');
      }
    } catch (e, stack) {
      if (showNotification) {
        AppLogger.error('Failed to export snapshot', e, stack);
      }
    }
  }

  Future<dynamic> loadLatestQueueSnapshot() async {
    try {
      final dir = await fileManager.getBackupDirectory(snapshotsFolder);
      if (!await dir.exists()) return null;
      final files = await dir
          .list()
          .where((e) => e is File && e.path.endsWith('.json'))
          .cast<File>()
          .toList();
      if (files.isEmpty) return null;
      final results = await Future.wait(files.map((f) async {
        try {
          final stat = await f.stat();
          return MapEntry(f, stat.modified);
        } catch (_) {
          return null;
        }
      }));
      final entries = results.whereType<MapEntry<File, DateTime>>().toList();
      if (entries.isEmpty) return null;
      entries.sort((a, b) => b.value.compareTo(a.value));
      final file = entries.first.key;
      return await fileManager.readJsonFile(file);
    } catch (e, stack) {
      AppLogger.error('Failed to load snapshot', e, stack);
      return null;
    }
  }

  Future<void> exportSnapshots(BuildContext context) async {
    try {
      final dir = await fileManager.getBackupDirectory(snapshotsFolder);
      if (!await dir.exists()) {
        if (context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('No snapshot files found')));
        }
        return;
      }
      final files = await dir.list(recursive: true).whereType<File>().toList();
      if (files.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('No snapshot files found')));
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
      final fileName = 'evaluation_snapshots_${_timestamp()}.zip';
      final savePath = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Snapshots Archive',
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
            .showSnackBar(const SnackBar(content: Text('Failed to export snapshots')));
      }
    }
  }

  Future<void> importEvaluationQueueSnapshot(BuildContext context) async {
    try {
      final dir = await fileManager.getBackupDirectory(snapshotsFolder);
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
          const SnackBar(content: Text('Failed to import snapshot')),
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

  Future<void> bulkImportEvaluationSnapshots(BuildContext context) async {
    final dir = await fileManager.getBackupDirectory(snapshotsFolder);
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

