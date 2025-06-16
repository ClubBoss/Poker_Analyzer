import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:synchronized/synchronized.dart';
import 'package:uuid/uuid.dart';

import '../helpers/debug_panel_preferences.dart';
import '../models/action_evaluation_request.dart';
import 'snapshot_service.dart';
import 'retry_evaluation_service.dart';
import 'evaluation_executor_service.dart';
import 'backup_manager_service.dart';

class EvaluationQueueService {
  final List<ActionEvaluationRequest> pending = [];
  final List<ActionEvaluationRequest> completed = [];
  final List<ActionEvaluationRequest> failed = [];

  final Lock _queueLock = Lock();

  /// Indicates if queue processing is underway.
  bool processing = false;
  bool pauseRequested = false;
  bool cancelRequested = false;

  static const int _snapshotRetentionLimit = 50;

  static const _pendingOrderKey = 'pending_queue_order';
  static const _failedOrderKey = 'failed_queue_order';
  static const _completedOrderKey = 'completed_queue_order';

  final DebugPanelPreferences _prefs = DebugPanelPreferences();
  bool snapshotRetentionEnabled = true;
  int processingDelay = 500;

  // Cached application documents directory path to avoid repeated lookups.
  late final String _documentsDirPath;

  // Cached SharedPreferences instance for quick persistence operations.
  late final SharedPreferences _sharedPrefs;
  late final SnapshotService _snapshotService;
  late final EvaluationExecutorService _executorService;
  late final RetryEvaluationService _retryService;
  BackupManagerService? _backupManager;
  late final Future<void> _initFuture;
  /// Optional callback invoked whenever the queue state changes so the
  /// debug panel can update immediately.
  VoidCallback? debugPanelCallback;

  EvaluationQueueService({
    EvaluationExecutorService? executorService,
    RetryEvaluationService? retryService,
    this.debugPanelCallback,
  }) {
    _executorService = executorService ?? EvaluationExecutorService();
    _retryService =
        retryService ?? RetryEvaluationService(executorService: _executorService);
    _initFuture = _initialize();
  }

  /// Attach an external [BackupManagerService] for import/export operations.
  void attachBackupManager(BackupManagerService manager) {
    _backupManager = manager;
  }

  Future<void> _initialize() async {
    snapshotRetentionEnabled = await _prefs.getSnapshotRetentionEnabled();
    processingDelay = await _prefs.getProcessingDelay();
    _documentsDirPath = (await getApplicationDocumentsDirectory()).path;
    _sharedPrefs = await SharedPreferences.getInstance();
    _snapshotService =
        SnapshotService(_documentsDirPath, _snapshotRetentionLimit);
  }

  Future<void> _writeJson(File file, Object data) async {
    try {
      await file.writeAsString(jsonEncode(data), flush: true);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to write ${file.path}: $e');
      }
    }
  }

  Future<dynamic> _readJson(File file) async {
    try {
      final content = await file.readAsString();
      return jsonDecode(content);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to read ${file.path}: $e');
      }
      return null;
    }
  }

  String _queueEntryId(ActionEvaluationRequest r) => r.id;

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

  Future<Map<String, dynamic>> _state() async {
    final pendingJson = await _queueLock
        .synchronized(() => [for (final e in pending) e.toJson()]);
    return {
      'pending': pendingJson,
      'failed': [for (final e in failed) e.toJson()],
      'completed': [for (final e in completed) e.toJson()],
    };
  }

  /// Persist queue state to disk and preferences using cached resources.
  Future<void> _persist() async {
    try {
      await _initFuture;
      final file = File('$_documentsDirPath/evaluation_current_queue.json');
      final tmpFile = File('${file.path}.tmp');
      final state = await _state();
      await _writeJson(tmpFile, state);
      try {
        await tmpFile.rename(file.path);
      } catch (e) {
        if (kDebugMode) {
          debugPrint('Failed to replace ${file.path}: $e');
        }
      }

      final pendingIds = await _queueLock
          .synchronized(() => [for (final e in pending) _queueEntryId(e)]);
      await _sharedPrefs.setStringList(_pendingOrderKey, pendingIds);
      await _sharedPrefs.setStringList(_failedOrderKey,
          [for (final e in failed) _queueEntryId(e)]);
      await _sharedPrefs.setStringList(_completedOrderKey,
          [for (final e in completed) _queueEntryId(e)]);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Persist error: $e');
      }
    }
    debugPanelCallback?.call();
  }

  /// Exposes persistence for external helpers.
  Future<void> persist() async => _persist();

  Future<void> addToQueue(ActionEvaluationRequest req) async {
    await _queueLock.synchronized(() => pending.add(req));
    await _persist();
  }

  Future<bool> _processSingleEvaluation(ActionEvaluationRequest req) async {
    return _retryService.processEvaluation(req);
  }

  Future<void> processQueue() async {
    if (processing ||
        await _queueLock.synchronized(() => pending.isEmpty)) return;
    processing = true;
    while (await _queueLock.synchronized(() => pending.isNotEmpty)) {
      if (pauseRequested || cancelRequested) break;
      final req = await _queueLock.synchronized(() => pending.first);
      await Future.delayed(Duration(milliseconds: processingDelay));
      if (cancelRequested) break;
      if (await _queueLock.synchronized(() => pending.isEmpty)) break;
      final success = await _processSingleEvaluation(req);
      await _queueLock.synchronized(() {
        if (pending.isNotEmpty) {
          pending.removeAt(0);
        }
      });
      (success ? completed : failed).add(req);
      if (success) {
        await saveQueueSnapshot(showNotification: false);
        _backupManager?.scheduleSnapshotExport();
      }
      await _persist();
      if (pauseRequested || cancelRequested) break;
    }
    processing = false;
    pauseRequested = false;
    cancelRequested = false;
    await _persist();
  }

  /// Replace the current evaluation queue with data taken from the clipboard.
  Future<void> importFromClipboard() async {
    try {
      final data = await Clipboard.getData('text/plain');
      if (data == null || data.text == null) return;
      final decoded = jsonDecode(data.text!);
      // Validate structure before replacing queues
      if (decoded is Map &&
          decoded.containsKey('pending') && decoded['pending'] is List &&
          decoded.containsKey('failed') && decoded['failed'] is List &&
          decoded.containsKey('completed') && decoded['completed'] is List) {
        final queues = _decodeQueues(decoded);
        await _queueLock.synchronized(() {
          pending
            ..clear()
            ..addAll(queues['pending']!);
        });
        failed
          ..clear()
          ..addAll(queues['failed']!);
        completed
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

  /// Copy the current evaluation queue state to the clipboard as JSON.
  Future<void> exportToClipboard() async {
    final jsonStr = jsonEncode(await _state());
    await Clipboard.setData(ClipboardData(text: jsonStr));
  }

  Future<void> saveQueueSnapshot({bool showNotification = true}) async {
    await _initFuture;
    await _snapshotService.saveQueueSnapshot(
      await _state(),
      showNotification: showNotification,
      snapshotRetentionEnabled: snapshotRetentionEnabled,
    );
  }

  Future<void> loadQueueSnapshot() async {
    await _initFuture;
    final decoded = await _snapshotService.loadQueueSnapshot();
    if (decoded == null) return;
    final queues = _decodeQueues(decoded);
    await _queueLock.synchronized(() {
      pending
        ..clear()
        ..addAll(queues['pending']!);
    });
    failed
      ..clear()
      ..addAll(queues['failed']!);
    completed
      ..clear()
      ..addAll(queues['completed']!);
    await _persist();
  }

  /// Moves failed requests back into the pending queue.
  Future<void> retryFailedEvaluations() async {
    await _retryService.retryFailedEvaluations(this);
  }

  void applySavedOrder(List<ActionEvaluationRequest> list, List<String>? order) {
    if (order == null || order.isEmpty) return;
    final remaining = List<ActionEvaluationRequest>.from(list);
    final reordered = <ActionEvaluationRequest>[];
    for (final key in order) {
      final idx = remaining.indexWhere((e) => e.id == key);
      if (idx != -1) {
        reordered.add(remaining.removeAt(idx));
      }
    }
    reordered.addAll(remaining);
    list
      ..clear()
      ..addAll(reordered);
  }

  Future<void> cleanup() async {
    _backupManager?.dispose();
  }

  /// Load queue state persisted to disk on a previous run.
  ///
  /// Returns `true` if any queued items were loaded.
  Future<bool> loadSavedQueue() async {
    await _initFuture;
    final file = File('$_documentsDirPath/evaluation_current_queue.json');
    bool resumed = false;
    if (await file.exists()) {
      final decoded = await _readJson(file);
      if (decoded != null) {
        final queues = _decodeQueues(decoded);
        await _queueLock.synchronized(() {
          pending
            ..clear()
            ..addAll(queues['pending']!);
        });
        failed
          ..clear()
          ..addAll(queues['failed']!);
        completed
          ..clear()
          ..addAll(queues['completed']!);

        applySavedOrder(pending, _sharedPrefs.getStringList(_pendingOrderKey));
        applySavedOrder(failed, _sharedPrefs.getStringList(_failedOrderKey));
        applySavedOrder(completed, _sharedPrefs.getStringList(_completedOrderKey));

        resumed =
            pending.isNotEmpty || failed.isNotEmpty || completed.isNotEmpty;
        await _persist();
      }
      try {
        await file.delete();
      } catch (_) {}
    }
    return resumed;
  }

  /// Remove all queued evaluations and persist the empty state.
  Future<void> clearQueue() async {
    await _queueLock.synchronized(pending.clear);
    failed.clear();
    completed.clear();
    await _persist();
  }

  /// Remove only pending evaluations.
  Future<void> clearPending() async {
    await _queueLock.synchronized(pending.clear);
    await _persist();
  }

  /// Remove only failed evaluations.
  Future<void> clearFailed() async {
    failed.clear();
    await _persist();
  }

  /// Remove only completed evaluations.
  Future<void> clearCompleted() async {
    completed.clear();
    await _persist();
  }

  /// Replace the entire pending queue with [items].
  Future<void> setPending(List<ActionEvaluationRequest> items) async {
    await _queueLock.synchronized(() {
      pending
        ..clear()
        ..addAll(items);
    });
    await _persist();
  }

  /// Reorder [queue] moving the item at [oldIndex] to [newIndex].
  Future<void> reorderQueue(
      List<ActionEvaluationRequest> queue, int oldIndex, int newIndex) async {
    await _queueLock.synchronized(() {
      final item = queue.removeAt(oldIndex);
      queue.insert(newIndex, item);
    });
    await _persist();
  }

  int _deduplicateList(List<ActionEvaluationRequest> list, Set<String> seenIds) {
    final originalLength = list.length;
    final unique = <ActionEvaluationRequest>[];
    for (final entry in list) {
      if (seenIds.add(entry.id)) unique.add(entry);
    }
    list
      ..clear()
      ..addAll(unique);
    return originalLength - unique.length;
  }

  /// Remove duplicate entries across all queues. Returns the number removed.
  Future<int> removeDuplicateEvaluations() async {
    int removed = 0;
    await _queueLock.synchronized(() {
      final seen = <String>{};
      removed += _deduplicateList(pending, seen);
      removed += _deduplicateList(failed, seen);
      removed += _deduplicateList(completed, seen);
    });
    if (removed > 0) {
      await _persist();
    }
    return removed;
  }

  /// Ensure a request only exists in one of the queues. Returns items removed.
  Future<int> resolveQueueConflicts() async {
    int removed = 0;
    await _queueLock.synchronized(() {
      final seen = <String>{};

      final newCompleted = <ActionEvaluationRequest>[];
      for (final e in completed) {
        if (seen.add(e.id)) {
          newCompleted.add(e);
        } else {
          removed++;
        }
      }

      final newFailed = <ActionEvaluationRequest>[];
      for (final e in failed) {
        if (seen.add(e.id)) {
          newFailed.add(e);
        } else {
          removed++;
        }
      }

      final newPending = <ActionEvaluationRequest>[];
      for (final e in pending) {
        if (seen.add(e.id)) {
          newPending.add(e);
        } else {
          removed++;
        }
      }

      completed
        ..clear()
        ..addAll(newCompleted);
      failed
        ..clear()
        ..addAll(newFailed);
      pending
        ..clear()
        ..addAll(newPending);
    });

    if (removed > 0) {
      await _persist();
    }
    return removed;
  }

  int _compareEvaluationRequests(
      ActionEvaluationRequest a, ActionEvaluationRequest b) {
    final streetComp = a.street.compareTo(b.street);
    if (streetComp != 0) return streetComp;
    final playerComp = a.playerIndex.compareTo(b.playerIndex);
    if (playerComp != 0) return playerComp;
    return a.action.compareTo(b.action);
  }

  /// Sort all queues by street, player index and action.
  Future<void> sortQueues() async {
    await _queueLock.synchronized(() {
      pending.sort(_compareEvaluationRequests);
      failed.sort(_compareEvaluationRequests);
      completed.sort(_compareEvaluationRequests);
    });
    await _persist();
  }

  /// Toggle paused processing state. When resuming, processing restarts if
  /// pending items exist.
  Future<void> togglePauseProcessing() async {
    pauseRequested = !pauseRequested;
    if (!pauseRequested && !processing && pending.isNotEmpty) {
      await processQueue();
    }
  }

  /// Cancel processing and clear the pending queue.
  Future<void> cancelProcessing() async {
    cancelRequested = true;
    pauseRequested = false;
    await _queueLock.synchronized(pending.clear);
    processing = false;
    await _persist();
  }

  /// Force stop any running processing and restart if pending items remain.
  Future<void> forceRestartProcessing() async {
    if (processing) {
      cancelRequested = true;
      pauseRequested = false;
      while (processing) {
        await Future.delayed(const Duration(milliseconds: 50));
      }
    }
    processing = false;
    cancelRequested = false;
    if (pending.isNotEmpty) {
      await processQueue();
    }
  }

  // ----- Import/Export helpers delegated to [_backupManager] -----

  Future<void> startAutoBackupTimer() async {
    await _backupManager?.startAutoBackupTimer();
  }

  Future<void> exportEvaluationQueue(BuildContext context) async {
    await _backupManager?.exportEvaluationQueue(context);
  }

  Future<void> exportQueueToClipboard(BuildContext context) async {
    if (_backupManager != null) {
      await _backupManager!.exportQueueToClipboard(context);
    } else {
      await exportToClipboard();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Queue copied to clipboard')));
      }
    }
  }

  Future<void> importQueueFromClipboard(BuildContext context) async {
    if (_backupManager != null) {
      await _backupManager!.importQueueFromClipboard(context);
    } else {
      await importFromClipboard();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Queue imported from clipboard')));
      }
    }
  }

  Future<void> exportFullQueueState(BuildContext context) async {
    await _backupManager?.exportFullQueueState(context);
  }

  Future<void> importFullQueueState(BuildContext context) async {
    await _backupManager?.importFullQueueState(context);
  }

  Future<void> restoreFullQueueState(BuildContext context) async {
    await _backupManager?.restoreFullQueueState(context);
  }

  Future<void> backupEvaluationQueue(BuildContext context) async {
    await _backupManager?.backupEvaluationQueue(context);
  }

  Future<void> quickBackupEvaluationQueue(BuildContext context) async {
    await _backupManager?.quickBackupEvaluationQueue(context);
  }

  Future<void> importQuickBackups(BuildContext context) async {
    await _backupManager?.importQuickBackups(context);
  }

  Future<void> cleanupOldEvaluationSnapshots() async {
    await _backupManager?.cleanupOldEvaluationSnapshots();
  }

  Future<void> exportArchive(
      BuildContext context, String subfolder, String archivePrefix) async {
    await _backupManager?.exportArchive(context, subfolder, archivePrefix);
  }

  Future<void> exportAllEvaluationBackups(BuildContext context) async {
    await _backupManager?.exportAllEvaluationBackups(context);
  }

  Future<void> exportAutoBackups(BuildContext context) async {
    await _backupManager?.exportAutoBackups(context);
  }

  Future<void> exportSnapshots(BuildContext context) async {
    await _backupManager?.exportSnapshots(context);
  }

  Future<void> restoreFromAutoBackup(BuildContext context) async {
    await _backupManager?.restoreFromAutoBackup(context);
  }

  Future<void> exportAllEvaluationSnapshots(BuildContext context) async {
    await _backupManager?.exportAllEvaluationSnapshots(context);
  }

  Future<void> importEvaluationQueue(BuildContext context) async {
    await _backupManager?.importEvaluationQueue(context);
  }

  Future<void> restoreEvaluationQueue(BuildContext context) async {
    await _backupManager?.restoreEvaluationQueue(context);
  }

  Future<void> bulkImportEvaluationQueue(BuildContext context) async {
    await _backupManager?.bulkImportEvaluationQueue(context);
  }

  Future<void> bulkImportEvaluationBackups(BuildContext context) async {
    await _backupManager?.bulkImportEvaluationBackups(context);
  }

  Future<void> bulkImportAutoBackups(BuildContext context) async {
    await _backupManager?.bulkImportAutoBackups(context);
  }

  Future<void> importEvaluationQueueSnapshot(BuildContext context) async {
    await _backupManager?.importEvaluationQueueSnapshot(context);
  }

  Future<void> bulkImportEvaluationSnapshots(BuildContext context) async {
    await _backupManager?.bulkImportEvaluationSnapshots(context);
  }

  void disposeBackupManager() {
    _backupManager?.dispose();
  }
}
