import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../models/action_evaluation_request.dart';
import 'evaluation_queue_service.dart';
import 'backup_manager_service.dart';

class EvaluationQueueImportExportService {
  EvaluationQueueImportExportService({
    required this.queueService,
    this.backupManager,
    this.debugPanelCallback,
  });

  final EvaluationQueueService queueService;
  BackupManagerService? backupManager;
  VoidCallback? debugPanelCallback;

  void attachBackupManager(BackupManagerService manager) {
    backupManager = manager;
  }

  Future<void> startAutoBackupTimer() async {
    await backupManager?.startAutoBackupTimer();
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
          decoded.containsKey('pending') && decoded['pending'] is List &&
          decoded.containsKey('failed') && decoded['failed'] is List &&
          decoded.containsKey('completed') && decoded['completed'] is List) {
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
      } else if (kDebugMode) {
        debugPrint('Invalid clipboard data format');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to import from clipboard: $e');
      }
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
    if (backupManager != null) {
      await backupManager!.exportQueueToClipboard(context);
    } else {
      await _exportToClipboard();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Queue copied to clipboard')),
        );
      }
    }
  }

  Future<void> importQueueFromClipboard(BuildContext context) async {
    if (backupManager != null) {
      await backupManager!.importQueueFromClipboard(context);
    } else {
      await _importFromClipboard();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Queue imported from clipboard')),
        );
      }
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
    await backupManager?.cleanupOldEvaluationSnapshots();
  }

  Future<void> exportEvaluationQueueSnapshot(BuildContext context,
      {bool showNotification = true}) async {
    await backupManager?.exportEvaluationQueueSnapshot(context,
        showNotification: showNotification);
  }

  Future<void> exportArchive(
      BuildContext context, String subfolder, String archivePrefix) async {
    await backupManager?.exportArchive(context, subfolder, archivePrefix);
  }

  Future<void> exportAllEvaluationBackups(BuildContext context) async {
    await backupManager?.exportAllEvaluationBackups(context);
  }

  Future<void> exportAutoBackups(BuildContext context) async {
    await backupManager?.exportAutoBackups(context);
  }

  Future<void> exportSnapshots(BuildContext context) async {
    await backupManager?.exportSnapshots(context);
  }

  Future<void> restoreFromAutoBackup(BuildContext context) async {
    await backupManager?.restoreFromAutoBackup(context);
    debugPanelCallback?.call();
  }

  Future<void> exportAllEvaluationSnapshots(BuildContext context) async {
    await backupManager?.exportAllEvaluationSnapshots(context);
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
    await backupManager?.importEvaluationQueueSnapshot(context);
    debugPanelCallback?.call();
  }

  Future<void> bulkImportEvaluationSnapshots(BuildContext context) async {
    await backupManager?.bulkImportEvaluationSnapshots(context);
    debugPanelCallback?.call();
  }

  void disposeBackupManager() {
    backupManager?.dispose();
  }
}
