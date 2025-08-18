import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

class SnapshotService {
  static const String snapshotsFolder = 'evaluation_snapshots';

  final String documentsDirPath;
  final int snapshotRetentionLimit;

  SnapshotService(this.documentsDirPath, this.snapshotRetentionLimit);

  Future<Directory> _getDir(String subfolder) async {
    final target = Directory('$documentsDirPath/$subfolder');
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

  String _timestamp() =>
      DateFormat('yyyy-MM-dd_HH-mm-ss').format(DateTime.now());

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

  Future<void> saveQueueSnapshot(
    Map<String, dynamic> state, {
    bool showNotification = true,
    bool snapshotRetentionEnabled = true,
  }) async {
    try {
      final dir = await _getDir(snapshotsFolder);
      final fileName = 'snapshot_${_timestamp()}.json';
      final file = File('${dir.path}/$fileName');
      await _writeJson(file, state);
      if (snapshotRetentionEnabled) {
        await _cleanupOldFiles(snapshotsFolder, snapshotRetentionLimit);
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

  Future<dynamic> loadQueueSnapshot() async {
    try {
      final dir = await _getDir(snapshotsFolder);
      if (!await dir.exists()) return null;
      final files = await dir
          .list()
          .where((e) => e is File && e.path.endsWith('.json'))
          .cast<File>()
          .toList();
      if (files.isEmpty) return null;
      final results = await Future.wait(
        files.map((f) async {
          try {
            final stat = await f.stat();
            return MapEntry(f, stat.modified);
          } catch (e) {
            if (kDebugMode) {
              debugPrint('Failed to stat ${f.path}: $e');
            }
            return null;
          }
        }),
      );
      final entries = results.whereType<MapEntry<File, DateTime>>().toList();
      if (entries.isEmpty) return null;
      entries.sort((a, b) => b.value.compareTo(a.value));
      final file = entries.first.key;
      return await _readJson(file);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to load snapshot: $e');
      }
      return null;
    }
  }
}
