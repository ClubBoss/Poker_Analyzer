import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

import 'analytics_adapter.dart';

/// Production-ready telemetry writer for learning path events.
class LearningPathTelemetry {
  LearningPathTelemetry._({Directory? dir, this.maxBytes = 2 * 1024 * 1024})
      : _dirOverride = dir;

  /// Default singleton instance.
  static final LearningPathTelemetry instance = LearningPathTelemetry._();

  /// Creates a test instance with custom [dir] and [maxBytes].
  factory LearningPathTelemetry.test({Directory? dir, int? maxBytes}) {
    return LearningPathTelemetry._(
        dir: dir, maxBytes: maxBytes ?? 2 * 1024 * 1024);
  }

  final Directory? _dirOverride;
  final int maxBytes;

  AnalyticsAdapter adapter = const NullAnalyticsAdapter();

  String? deviceId;
  String? userId;
  String? _appVersion;
  Future<void> _queue = Future.value();

  Future<String> _version() async {
    return _appVersion ??= (await PackageInfo.fromPlatform()).version;
  }

  Future<Directory> get _logDir async {
    if (_dirOverride != null) return _dirOverride!;
    return await getApplicationDocumentsDirectory();
  }

  Future<File> get _logFile async {
    final dir = await _logDir;
    return File('${dir.path}/autogen_report.log');
  }

  Future<File> _rotated(int n) async {
    final dir = await _logDir;
    return File('${dir.path}/autogen_report.log.$n');
  }

  Future<void> log(String event, Map<String, Object?> data) async {
    final payload = <String, Object?>{
      'event': event,
      ...data,
      'tsIso': DateTime.now().toIso8601String(),
      'appVersion': await _version(),
      if (deviceId != null) 'deviceId': deviceId,
      if (userId != null) 'userId': userId,
    };
    final line = jsonEncode(payload);
    _queue = _queue.then((_) async {
      try {
        await _rotateIfNeeded();
        final file = await _logFile;
        final sink = file.openWrite(mode: FileMode.append);
        sink.writeln(line);
        await sink.flush();
        await sink.close();
      } catch (_) {}
    }).then((_) async {
      try {
        await adapter.send(event, payload);
      } catch (_) {}
    });
    await _queue;
  }

  Future<void> _rotateIfNeeded() async {
    final file = await _logFile;
    if (await file.exists()) {
      final length = await file.length();
      if (length > maxBytes) {
        final f1 = await _rotated(1);
        final f2 = await _rotated(2);
        if (await f2.exists()) {
          await f2.delete();
        }
        if (await f1.exists()) {
          await f1.rename(f2.path);
        }
        await file.rename(f1.path);
      }
    }
  }

}
