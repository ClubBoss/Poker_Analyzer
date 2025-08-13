import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:synchronized/synchronized.dart';
import 'package:uuid/uuid.dart';

import '../models/action_evaluation_request.dart';
import 'backup_manager_service.dart';
import 'debug_snapshot_service.dart';
import 'cloud_sync_service.dart';

class EvaluationQueueService {
  final List<ActionEvaluationRequest> pending = [];
  final List<ActionEvaluationRequest> completed = [];
  final List<ActionEvaluationRequest> failed = [];

  final Lock _queueLock = Lock();

  /// Exposes the queue lock for synchronized access by helpers.
  Lock get queueLock => _queueLock;

  static const _pendingOrderKey = 'pending_queue_order';
  static const _failedOrderKey = 'failed_queue_order';
  static const _completedOrderKey = 'completed_queue_order';
  static const _timeKey = 'evaluation_queue_updated';

  bool snapshotRetentionEnabled = true;

  final CloudSyncService? cloud;

  // Cached application documents directory path to avoid repeated lookups.
  late final String _documentsDirPath;

  // Cached SharedPreferences instance for quick persistence operations.
  late final SharedPreferences _sharedPrefs;
  late final Future<void> _initFuture;

  /// Optional callback invoked whenever the queue state changes so the
  /// debug panel can update immediately.
  VoidCallback? debugPanelCallback;
  BackupManagerService? backupManager;
  DebugSnapshotService? debugSnapshotService;

  Timer? _persistTimer;

  void attachBackupManager(BackupManagerService manager) {
    backupManager = manager;
  }

  void attachDebugSnapshotService(DebugSnapshotService service) {
    debugSnapshotService = service;
  }

  EvaluationQueueService({
    this.debugPanelCallback,
    this.backupManager,
    this.debugSnapshotService,
    this.cloud,
  }) {
    _initFuture = _initialize();
  }

  Future<void> _initialize() async {
    _documentsDirPath = (await getApplicationDocumentsDirectory()).path;
    _sharedPrefs = await SharedPreferences.getInstance();
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

  Future<Map<String, dynamic>> state() async {
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
      final data = await state();
      await _writeJson(tmpFile, data);
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
      await _sharedPrefs.setStringList(
          _failedOrderKey, [for (final e in failed) _queueEntryId(e)]);
      await _sharedPrefs.setStringList(
          _completedOrderKey, [for (final e in completed) _queueEntryId(e)]);
      await _sharedPrefs.setString(_timeKey, DateTime.now().toIso8601String());
      if (cloud != null) {
        await cloud!.uploadQueue({
          'pending': [for (final e in pending) e.toJson()],
          'failed': [for (final e in failed) e.toJson()],
          'completed': [for (final e in completed) e.toJson()],
        });
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Persist error: $e');
      }
    }
    debugPanelCallback?.call();
  }

  void _schedulePersist() {
    _persistTimer?.cancel();
    _persistTimer = Timer(const Duration(seconds: 1), () {
      unawaited(_persist());
    });
  }

  /// Exposes persistence for external helpers.
  Future<void> persist() async => _persist();

  Future<void> addToQueue(ActionEvaluationRequest req) async {
    await _queueLock.synchronized(() => pending.add(req));
    _schedulePersist();
  }

  Future<void> saveQueueSnapshot({bool showNotification = true}) async {
    await _initFuture;
    await debugSnapshotService?.saveQueueSnapshot(
      await state(),
      showNotification: showNotification,
      snapshotRetentionEnabled: snapshotRetentionEnabled,
    );
  }

  Future<void> loadQueueSnapshot() async {
    await _initFuture;
    final decoded = await debugSnapshotService?.loadQueueSnapshot();
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

  void applySavedOrder(
      List<ActionEvaluationRequest> list, List<String>? order) {
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
    // No-op for now.
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
        applySavedOrder(
            completed, _sharedPrefs.getStringList(_completedOrderKey));

        resumed =
            pending.isNotEmpty || failed.isNotEmpty || completed.isNotEmpty;
        await _persist();
      }
      try {
        await file.delete();
      } catch (_) {}
    }
    await syncDown();
    return resumed;
  }

  /// Remove all queued evaluations and persist the empty state.
  Future<void> clearQueue() async {
    await _queueLock.synchronized(pending.clear);
    failed.clear();
    completed.clear();
    _schedulePersist();
  }

  /// Remove only pending evaluations.
  Future<void> clearPending() async {
    await _queueLock.synchronized(pending.clear);
    _schedulePersist();
  }

  /// Remove only failed evaluations.
  Future<void> clearFailed() async {
    failed.clear();
    _schedulePersist();
  }

  /// Remove only completed evaluations.
  Future<void> clearCompleted() async {
    completed.clear();
    _schedulePersist();
  }

  /// Replace the entire pending queue with [items].
  Future<void> setPending(List<ActionEvaluationRequest> items) async {
    await _queueLock.synchronized(() {
      pending
        ..clear()
        ..addAll(items);
    });
    _schedulePersist();
  }

  /// Reorder [queue] moving the item at [oldIndex] to [newIndex].
  Future<void> reorderQueue(
      List<ActionEvaluationRequest> queue, int oldIndex, int newIndex) async {
    await _queueLock.synchronized(() {
      final item = queue.removeAt(oldIndex);
      queue.insert(newIndex, item);
    });
    _schedulePersist();
  }

  int _deduplicateList(
      List<ActionEvaluationRequest> list, Set<String> seenIds) {
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
      _schedulePersist();
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
      _schedulePersist();
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

  Future<void> syncUp() async {
    if (cloud == null) return;
    await cloud!.uploadQueue(await state());
  }

  Future<void> syncDown() async {
    if (cloud == null) return;
    await _initFuture;
    final remote = await cloud!.downloadQueue();
    if (remote == null) return;
    final remoteAt = DateTime.tryParse(remote['updatedAt'] as String? ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0);
    final localAt = DateTime.tryParse(_sharedPrefs.getString(_timeKey) ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0);
    if (remoteAt.isAfter(localAt)) {
      final queues = _decodeQueues(remote);
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
      await _sharedPrefs.setStringList(
          _pendingOrderKey, [for (final e in pending) _queueEntryId(e)]);
      await _sharedPrefs.setStringList(
          _failedOrderKey, [for (final e in failed) _queueEntryId(e)]);
      await _sharedPrefs.setStringList(
          _completedOrderKey, [for (final e in completed) _queueEntryId(e)]);
      await _sharedPrefs.setString(_timeKey, remoteAt.toIso8601String());
      await _persist();
    } else if (localAt.isAfter(remoteAt)) {
      await syncUp();
    }
  }
}
