import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:synchronized/synchronized.dart';
import 'package:uuid/uuid.dart';

import '../helpers/debug_panel_preferences.dart';
import '../models/action_evaluation_request.dart';
import 'snapshot_service.dart';

class EvaluationQueueManager {
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
  late final Future<void> _initFuture;

  EvaluationQueueManager() {
    _initFuture = _initialize();
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
  }

  Future<void> addToQueue(ActionEvaluationRequest req) async {
    await _queueLock.synchronized(() => pending.add(req));
    await _persist();
  }

  Future<void> _execute(ActionEvaluationRequest req) async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (Random().nextDouble() < 0.2) {
      throw Exception('Simulated evaluation failure');
    }
  }

  Future<bool> _processSingleEvaluation(ActionEvaluationRequest req) async {
    var success = false;
    while (!success && req.attempts < 3) {
      try {
        await _execute(req);
        success = true;
      } catch (_) {
        req.attempts++;
        if (req.attempts < 3) {
          await Future.delayed(const Duration(milliseconds: 200));
        }
      }
    }
    return success;
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
    // Placeholder for any cleanup logic when disposing the manager.
  }
}
