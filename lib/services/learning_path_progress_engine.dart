import 'dart:math';
import 'package:collection/collection.dart';
import '../models/learning_path_template_v2.dart';
import 'learning_path_registry_service.dart';
import 'learning_path_track_library_service.dart';
import 'pack_library_service.dart';
import 'session_log_service.dart';

/// Callback for resolving training pack spot count.
typedef PackSizeLoader = Future<int?> Function(String packId);

/// Computes user progress across learning paths.
class LearningPathProgressEngine {
  final SessionLogService logs;
  final LearningPathRegistryService registry;
  final LearningPathTrackLibraryService tracks;
  final PackSizeLoader _packSize;

  LearningPathProgressEngine({
    required this.logs,
    LearningPathRegistryService? registry,
    LearningPathTrackLibraryService? trackLibrary,
    PackSizeLoader? packSizeLoader,
  })  : registry = registry ?? LearningPathRegistryService.instance,
        tracks = trackLibrary ?? LearningPathTrackLibraryService.instance,
        _packSize = packSizeLoader ?? _defaultPackSize;

  static Future<int?> _defaultPackSize(String id) async {
    final tpl = await PackLibraryService.instance.getById(id);
    if (tpl == null) return null;
    return tpl.spots.isNotEmpty ? tpl.spots.length : tpl.spotCount;
  }

  final Map<String, double> _pathProgress = {};
  DateTime _lastComputed = DateTime.fromMillisecondsSinceEpoch(0);
  Future<void>? _loading;

  Future<void> _ensureData() async {
    if (_loading != null) {
      await _loading;
      return;
    }
    if (_pathProgress.isNotEmpty &&
        DateTime.now().difference(_lastComputed) < const Duration(minutes: 5)) {
      return;
    }
    final future = _compute();
    _loading = future;
    await future;
    _loading = null;
  }

  Future<void> _compute() async {
    await logs.load();
    final handsByPack = <String, int>{};
    for (final l in logs.logs) {
      final count = l.correctCount + l.mistakeCount;
      handsByPack.update(l.templateId, (v) => v + count, ifAbsent: () => count);
    }

    final templates = await registry.loadAll();
    _pathProgress.clear();
    for (final t in templates) {
      final progress = await _computePath(t, handsByPack);
      _pathProgress[t.id] = progress;
    }
    _lastComputed = DateTime.now();
  }

  Future<double> _computePath(
    LearningPathTemplateV2 template,
    Map<String, int> handsByPack,
  ) async {
    var played = 0;
    var total = 0;
    for (final stage in template.stages) {
      final size = await _packSize(stage.packId) ?? 0;
      if (size <= 0) continue;
      final hands = handsByPack[stage.packId] ?? 0;
      played += min(hands, size);
      total += size;
    }
    if (total == 0) return 0.0;
    return played / total;
  }

  /// Returns completion ratio for [pathId].
  Future<double> getPathProgress(String pathId) async {
    await _ensureData();
    return _pathProgress[pathId] ?? 0.0;
  }

  /// Returns average progress across all paths in [trackId].
  Future<double> getTrackProgress(String trackId) async {
    await _ensureData();
    await tracks.reload();
    final track = tracks.getById(trackId);
    if (track == null || track.pathIds.isEmpty) return 0.0;
    final values =
        track.pathIds.map((id) => _pathProgress[id]).whereNotNull().toList();
    if (values.isEmpty) return 0.0;
    final sum = values.reduce((a, b) => a + b);
    return sum / values.length;
  }

  /// Returns progress for all loaded learning paths.
  Future<Map<String, double>> getAllPathProgress() async {
    await _ensureData();
    return Map.unmodifiable(_pathProgress);
  }

  /// Clears cached results forcing recomputation on next call.
  void clearCache() => _pathProgress.clear();
}
