import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:synchronized/synchronized.dart';

/// Handles saving and loading of evaluation queue snapshots for debugging.
class DebugSnapshotService {
  static const String snapshotsFolder = 'evaluation_snapshots';

  final int snapshotRetentionLimit;
  final Lock _ioLock = Lock();

  late final String _documentsDirPath;
  late final Future<void> _initFuture;

  DebugSnapshotService({this.snapshotRetentionLimit = 50}) {
    _initFuture = _initialize();
  }

  Future<void> _initialize() async {
    _documentsDirPath = (await getApplicationDocumentsDirectory()).path;
  }

  Future<Directory> _getDir(String subfolder) async {
    final target = Directory('$_documentsDirPath/$subfolder');
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

  /// Saves [state] as a snapshot JSON file.
  Future<void> saveQueueSnapshot(
    Map<String, dynamic> state, {
    bool showNotification = true,
    bool snapshotRetentionEnabled = true,
  }) async {
    await _initFuture;
    await _ioLock.synchronized(() async {
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
    });
  }

  /// Loads the most recent snapshot if available.
  Future<dynamic> loadQueueSnapshot() async {
    await _initFuture;
    return _ioLock.synchronized(() async {
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
    });
  }

  /// Removes old snapshot files keeping only [snapshotRetentionLimit] recent ones.
  Future<void> cleanupOldSnapshots() async {
    await _initFuture;
    await _ioLock.synchronized(
      () => _cleanupOldFiles(snapshotsFolder, snapshotRetentionLimit),
    );
  }

  /// Returns the directory containing snapshot files.
  Future<Directory> getSnapshotsDirectory() async {
    await _initFuture;
    return _getDir(snapshotsFolder);
  }

  /// Reads a snapshot JSON file and returns the decoded content.
  Future<dynamic> readSnapshotFile(File file) async {
    await _initFuture;
    return _readJson(file);
  }

  /// Exports all snapshot files as a ZIP archive selected by the user.
  Future<void> exportSnapshots(BuildContext context) async {
    await _initFuture;
    try {
      final dir = await _getDir(snapshotsFolder);
      if (!await dir.exists()) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No snapshot files found')),
          );
        }
        return;
      }
      final files = await dir.list(recursive: true).whereType<File>().toList();
      if (files.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No snapshot files found')),
          );
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Archive saved: $name')));
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to export snapshots')),
        );
      }
    }
  }
}
