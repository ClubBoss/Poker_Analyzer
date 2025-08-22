import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:uuid/uuid.dart';

import '../models/action_evaluation_request.dart';
import 'evaluation_queue_service.dart';
import 'backup_manager_service.dart';
import 'debug_snapshot_service.dart';
import '../utils/app_logger.dart';

class EvaluationQueueImportExportService {
  EvaluationQueueImportExportService({
    required this.queueService,
    this.backupManager,
    this.debugSnapshotService,
    this.debugPanelCallback,
  });

  final EvaluationQueueService queueService;
  BackupManagerService? backupManager;
  DebugSnapshotService? debugSnapshotService;
  VoidCallback? debugPanelCallback;

  void attachBackupManager(BackupManagerService manager) {
    backupManager = manager;
  }

  void attachDebugSnapshotService(DebugSnapshotService service) {
    debugSnapshotService = service;
  }

  Future<void> startAutoBackupTimer() async {
    await backupManager?.startAutoBackupTimer();
  }

  ActionEvaluationRequest _decodeRequest(Map<String, dynamic> json) {
    final map = Map<String, dynamic>.from(json);
    if (map['id'] == null ||
        map['id'] is! String ||
        (map['id'] as String).isEmpty) {
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

  Future<void> _persist() async {
    await queueService.persist();
    debugPanelCallback?.call();
  }

  Future<void> _importFromClipboard() async {
    try {
      final data = await Clipboard.getData('text/plain');
      if (data == null || data.text == null) return;
      final decoded = jsonDecode(data.text!);
      if (decoded is Map &&
          decoded.containsKey('pending') &&
          decoded['pending'] is List &&
          decoded.containsKey('failed') &&
          decoded['failed'] is List &&
          decoded.containsKey('completed') &&
          decoded['completed'] is List) {
        final queues = _decodeQueues(decoded);
        await queueService.queueLock.synchronized(() {
          queueService.pending
            ..clear()
            ..addAll(queues['pending']!);
        });
        queueService.failed
          ..clear()
          ..addAll(queues['failed']!);
        queueService.completed
          ..clear()
          ..addAll(queues['completed']!);
        await _persist();
      } else {
        AppLogger.warn('Invalid clipboard data format');
      }
    } catch (e, stack) {
      AppLogger.error('Failed to import from clipboard', e, stack);
    }
  }

  Future<void> _exportToClipboard() async {
    final jsonStr = jsonEncode(await queueService.state());
    await Clipboard.setData(ClipboardData(text: jsonStr));
  }

  Future<void> exportEvaluationQueue(BuildContext context) async {
    await backupManager?.exportEvaluationQueue(context);
  }

  Future<void> exportQueueToClipboard(BuildContext context) async {
    await _exportToClipboard();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Queue copied to clipboard')),
      );
    }
  }

  Future<void> importQueueFromClipboard(BuildContext context) async {
    await _importFromClipboard();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Queue imported from clipboard')),
      );
    }
    debugPanelCallback?.call();
  }

  Future<void> exportFullQueueState(BuildContext context) async {
    await backupManager?.exportFullQueueState(context);
  }

  Future<void> importFullQueueState(BuildContext context) async {
    await backupManager?.importFullQueueState(context);
    debugPanelCallback?.call();
  }

  Future<void> restoreFullQueueState(BuildContext context) async {
    await backupManager?.restoreFullQueueState(context);
    debugPanelCallback?.call();
  }

  Future<void> backupEvaluationQueue(BuildContext context) async {
    await backupManager?.backupEvaluationQueue(context);
  }

  Future<void> quickBackupEvaluationQueue(BuildContext context) async {
    await backupManager?.quickBackupEvaluationQueue(context);
    debugPanelCallback?.call();
  }

  Future<void> importQuickBackups(BuildContext context) async {
    await backupManager?.importQuickBackups(context);
    debugPanelCallback?.call();
  }

  Future<void> cleanupOldEvaluationSnapshots() async {
    await debugSnapshotService?.cleanupOldSnapshots();
  }

  Future<void> exportEvaluationQueueSnapshot(
    BuildContext context, {
    bool showNotification = true,
  }) async {
    await debugSnapshotService?.saveQueueSnapshot(
      await queueService.state(),
      showNotification: showNotification,
      snapshotRetentionEnabled: queueService.snapshotRetentionEnabled,
    );
  }

  Future<void> exportArchive(
    BuildContext context,
    String subfolder,
    String archivePrefix,
  ) async {
    await backupManager?.exportArchive(context, subfolder, archivePrefix);
  }

  Future<void> exportAllEvaluationBackups(BuildContext context) async {
    await backupManager?.exportAllEvaluationBackups(context);
  }

  Future<void> exportAutoBackups(BuildContext context) async {
    await backupManager?.exportAutoBackups(context);
  }

  Future<void> exportSnapshots(BuildContext context) async {
    await debugSnapshotService?.exportSnapshots(context);
  }

  Future<void> restoreFromAutoBackup(BuildContext context) async {
    await backupManager?.restoreFromAutoBackup(context);
    debugPanelCallback?.call();
  }

  Future<void> exportAllEvaluationSnapshots(BuildContext context) async {
    await debugSnapshotService?.exportSnapshots(context);
  }

  Future<void> importEvaluationQueue(BuildContext context) async {
    await backupManager?.importEvaluationQueue(context);
    debugPanelCallback?.call();
  }

  Future<void> restoreEvaluationQueue(BuildContext context) async {
    await backupManager?.restoreEvaluationQueue(context);
  }

  Future<void> bulkImportEvaluationQueue(BuildContext context) async {
    await backupManager?.bulkImportEvaluationQueue(context);
    debugPanelCallback?.call();
  }

  Future<void> bulkImportEvaluationBackups(BuildContext context) async {
    await backupManager?.bulkImportEvaluationBackups(context);
    debugPanelCallback?.call();
  }

  Future<void> bulkImportAutoBackups(BuildContext context) async {
    await backupManager?.bulkImportAutoBackups(context);
    debugPanelCallback?.call();
  }

  Future<void> importEvaluationQueueSnapshot(BuildContext context) async {
    final dir = await debugSnapshotService?.getSnapshotsDirectory();
    if (dir == null) return;
    if (!await dir.exists()) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No snapshot files found')),
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
    final decoded = await debugSnapshotService!.readSnapshotFile(File(path));
    final queues = _decodeQueues(decoded);
    await queueService.queueLock.synchronized(() {
      queueService.pending
        ..clear()
        ..addAll(queues['pending']!);
    });
    queueService.failed
      ..clear()
      ..addAll(queues['failed']!);
    queueService.completed
      ..clear()
      ..addAll(queues['completed']!);
    await _persist();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Imported ${queueService.pending.length} pending, ${queueService.failed.length} failed, ${queueService.completed.length} completed evaluations',
          ),
        ),
      );
    }
    debugPanelCallback?.call();
  }

  Future<void> bulkImportEvaluationSnapshots(BuildContext context) async {
    final dir = await debugSnapshotService?.getSnapshotsDirectory();
    if (dir == null) return;
    if (!await dir.exists()) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No snapshot files found')),
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
      try {
        final decoded = await debugSnapshotService!.readSnapshotFile(
          File(path),
        );
        final queues = _decodeQueues(decoded);
        importedPending.addAll(queues['pending']!);
        importedFailed.addAll(queues['failed']!);
        importedCompleted.addAll(queues['completed']!);
      } catch (_) {
        skipped++;
      }
    }
    await queueService.queueLock.synchronized(() {
      queueService.pending.addAll(importedPending);
    });
    queueService.failed.addAll(importedFailed);
    queueService.completed.addAll(importedCompleted);
    await _persist();
    final total =
        importedPending.length +
        importedFailed.length +
        importedCompleted.length;
    final msg = skipped == 0
        ? 'Imported $total evaluations from ${result.files.length} files'
        : 'Imported $total evaluations, $skipped files skipped';
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
    debugPanelCallback?.call();
  }

  void disposeBackupManager() {
    backupManager?.dispose();
  }
}
