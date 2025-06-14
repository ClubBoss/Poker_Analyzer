import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/debug_panel_preferences.dart';
import '../models/action_evaluation_request.dart';

class EvaluationQueueManager {
  final List<ActionEvaluationRequest> pending = [];
  final List<ActionEvaluationRequest> completed = [];
  final List<ActionEvaluationRequest> failed = [];

  /// Indicates if queue processing is underway.
  bool processing = false;
  bool pauseRequested = false;
  bool cancelRequested = false;

  static const String _snapshotsFolder = 'evaluation_snapshots';
  static const int _snapshotRetentionLimit = 50;

  static const _pendingOrderKey = 'pending_queue_order';
  static const _failedOrderKey = 'failed_queue_order';
  static const _completedOrderKey = 'completed_queue_order';

  final DebugPanelPreferences _prefs = DebugPanelPreferences();
  bool snapshotRetentionEnabled = true;
  int processingDelay = 500;

  EvaluationQueueManager() {
    Future.microtask(() async {
      snapshotRetentionEnabled = await _prefs.getSnapshotRetentionEnabled();
      processingDelay = await _prefs.getProcessingDelay();
    });
  }

  Future<Directory> _getDir(String subfolder) async {
    final dir = await getApplicationDocumentsDirectory();
    final target = Directory('${dir.path}/$subfolder');
    try {
      await target.create(recursive: true);
    } catch (_) {}
    return target;
  }

  Future<void> _writeJson(File file, Object data) async {
    try {
      await file.writeAsString(jsonEncode(data), flush: true);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to write ${file.path}: $e');
      }
      rethrow;
    }
  }

  Future<dynamic> _readJson(File file) async {
    final content = await file.readAsString();
    return jsonDecode(content);
  }

  String _timestamp() => DateFormat('yyyy-MM-dd_HH-mm-ss').format(DateTime.now());

  Future<void> _cleanupOldFiles(String subfolder, int limit) async {
    try {
      final dir = await _getDir(subfolder);
      final entries = <MapEntry<File, DateTime>>[];
      await for (final entity in dir.list()) {
        if (entity is File && entity.path.endsWith('.json')) {
          try {
            final stat = await entity.stat();
            entries.add(MapEntry(entity, stat.modified));
          } catch (e) {
            if (kDebugMode) {
              debugPrint('Failed to stat ${entity.path}: $e');
            }
          }
        }
      }
      entries.sort((a, b) => b.value.compareTo(a.value));
      for (final entry in entries.skip(limit)) {
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

  Map<String, dynamic> _state() => {
        'pending': [for (final e in pending) e.toJson()],
        'failed': [for (final e in failed) e.toJson()],
        'completed': [for (final e in completed) e.toJson()],
      };

  Future<void> _persist() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/evaluation_current_queue.json');
      await _writeJson(file, _state());

      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_pendingOrderKey, [for (final e in pending) _queueEntryId(e)]);
      await prefs.setStringList(_failedOrderKey, [for (final e in failed) _queueEntryId(e)]);
      await prefs.setStringList(_completedOrderKey, [for (final e in completed) _queueEntryId(e)]);
    } catch (_) {}
  }

  Future<void> addToQueue(ActionEvaluationRequest req) async {
    pending.add(req);
    await _persist();
  }

  Future<void> _execute(ActionEvaluationRequest req) async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (Random().nextDouble() < 0.2) {
      throw Exception('Simulated evaluation failure');
    }
  }

  Future<void> processQueue() async {
    if (processing || pending.isEmpty) return;
    processing = true;
    while (pending.isNotEmpty) {
      if (pauseRequested || cancelRequested) break;
      final req = pending.first;
      await Future.delayed(Duration(milliseconds: processingDelay));
      if (cancelRequested) break;
      if (pending.isEmpty) break;
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
      pending.removeAt(0);
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
      final queues = _decodeQueues(decoded);
      pending
        ..clear()
        ..addAll(queues['pending']!);
      failed
        ..clear()
        ..addAll(queues['failed']!);
      completed
        ..clear()
        ..addAll(queues['completed']!);
      await _persist();
    } catch (_) {}
  }

  /// Copy the current evaluation queue state to the clipboard as JSON.
  Future<void> exportToClipboard() async {
    final jsonStr = jsonEncode(_state());
    await Clipboard.setData(ClipboardData(text: jsonStr));
  }

  Future<void> saveQueueSnapshot({bool showNotification = true}) async {
    try {
      final dir = await _getDir(_snapshotsFolder);
      final fileName = 'snapshot_${_timestamp()}.json';
      final file = File('${dir.path}/$fileName');
      await _writeJson(file, _state());
      if (snapshotRetentionEnabled) {
        await _cleanupOldFiles(_snapshotsFolder, _snapshotRetentionLimit);
      }
      if (showNotification && kDebugMode) {
        debugPrint('Snapshot saved: ${file.path}');
      }
    } catch (e) {
      if (showNotification && kDebugMode) {
        debugPrint('Failed to export snapshot: $e');
      }
    }
  }

  Future<void> loadQueueSnapshot() async {
    try {
      final dir = await _getDir(_snapshotsFolder);
      if (!await dir.exists()) return;
      final files = await dir
          .list()
          .where((e) => e is File && e.path.endsWith('.json'))
          .cast<File>()
          .toList();
      if (files.isEmpty) return;
      files.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));
      final decoded = await _readJson(files.first);
      final queues = _decodeQueues(decoded);
      pending
        ..clear()
        ..addAll(queues['pending']!);
      failed
        ..clear()
        ..addAll(queues['failed']!);
      completed
        ..clear()
        ..addAll(queues['completed']!);
      await _persist();
    } catch (_) {}
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
