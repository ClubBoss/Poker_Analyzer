import 'dart:math';
import 'package:flutter/material.dart';
import 'pack_library_loader_service.dart';
import 'session_log_service.dart';
import 'training_pack_stats_service.dart';
import 'mastery_persistence_service.dart';
import '../models/v2/training_pack_template.dart';

class TagMasteryService {
  final SessionLogService logs;
  TagMasteryService({required this.logs});

  static Map<String, double>? _cache;
  static DateTime _cacheTime = DateTime.fromMillisecondsSinceEpoch(0);
  static Map<String, DateTime>? _lastTrained;
  static Map<String, double>? _lastAccuracy;
  static DateTime _metaTime = DateTime.fromMillisecondsSinceEpoch(0);

  Future<Map<String, double>> computeMastery({bool force = false}) async {
    if (!force &&
        _cache != null &&
        DateTime.now().difference(_cacheTime) < const Duration(hours: 6)) {
      return _cache!;
    }

    await logs.load();
    await PackLibraryLoaderService.instance.loadLibrary();
    final library = PackLibraryLoaderService.instance.library;
    final byId = {for (final t in library) t.id: t};

    final sums = <String, double>{};
    final counts = <String, int>{};
    final spotCounts = <String, int>{};
    final lastTrained = <String, DateTime>{};
    final lastAcc = <String, double>{};

    for (final t in library) {
      for (final s in t.spots) {
        for (final tag in s.tags) {
          final key = tag.trim().toLowerCase();
          if (key.isEmpty) continue;
          spotCounts.update(key, (v) => v + 1, ifAbsent: () => 1);
        }
      }
    }

    for (final log in logs.logs) {
      final tpl = byId[log.templateId];
      if (tpl == null) continue;
      final total = log.correctCount + log.mistakeCount;
      if (total == 0) continue;
      final acc = log.correctCount / total;
      for (final tag in tpl.tags) {
        final key = tag.trim().toLowerCase();
        if (key.isEmpty) continue;
        sums[key] = (sums[key] ?? 0) + acc;
        counts[key] = (counts[key] ?? 0) + 1;
        final prev = lastTrained[key];
        if (prev == null || log.completedAt.isAfter(prev)) {
          lastTrained[key] = log.completedAt;
          lastAcc[key] = acc;
        }
      }
    }

    final stats = await TrainingPackStatsService.getCategoryStats();
    for (final e in stats.entries) {
      final key = e.key.trim().toLowerCase();
      sums[key] = (sums[key] ?? 0) + e.value;
      counts[key] = (counts[key] ?? 0) + 1;
    }

    final result = <String, double>{};
    for (final e in sums.entries) {
      final c = counts[e.key]!;
      if ((spotCounts[e.key] ?? 0) < 3) continue;
      result[e.key] = (e.value / c).clamp(0.0, 1.0);
    }

    if (result.isEmpty) {
      _cache = {};
      _cacheTime = DateTime.now();
      _lastTrained = lastTrained;
      _lastAccuracy = lastAcc;
      _metaTime = DateTime.now();
      return _cache!;
    }

    final values = result.values.toList();
    final minVal = values.reduce(min);
    final maxVal = values.reduce(max);

    final normalized = <String, double>{};
    if (maxVal > minVal) {
      result.forEach((k, v) {
        normalized[k] = (v - minVal) / (maxVal - minVal);
      });
    } else {
      for (final k in result.keys) {
        normalized[k] = 1.0;
      }
    }

    _cache = normalized;
    _cacheTime = DateTime.now();
    _lastTrained = lastTrained;
    _lastAccuracy = lastAcc;
    _metaTime = DateTime.now();
    return normalized;
  }

  Future<List<String>> topWeakTags(int count) async {
    final map = await computeMastery();
    final list = map.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    return [for (final e in list.take(count)) e.key];
  }

  Future<List<String>> topStrongTags(int count) async {
    final map = await computeMastery();
    final list = map.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return [for (final e in list.take(count)) e.key];
  }

  /// Returns the weakest [count] tags sorted by mastery ascending.
  Future<List<String>> bottomWeakTags(int count) async {
    final map = await computeMastery();
    final list = map.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    return [for (final e in list.take(count)) e.key];
  }

  /// Returns all tags with mastery below [threshold].
  Future<List<String>> getWeakTags([double threshold = 0.7]) async {
    final map = await computeMastery();
    return [
      for (final e in map.entries)
        if (e.value < threshold) e.key,
    ];
  }

  /// Returns all tags with mastery below [threshold], sorted ascending.
  Future<List<String>> findWeakTags({double threshold = 0.7}) async {
    final map = await computeMastery();
    final list = [
      for (final e in map.entries)
        if (e.value < threshold) MapEntry(e.key, e.value),
    ]..sort((a, b) => a.value.compareTo(b.value));
    return [for (final e in list) e.key];
  }

  /// Computes mastery deltas for a completed training [session]. When
  /// [dryRun] is true (default) the underlying data is not persisted.
  Future<Map<String, double>> updateWithSession({
    required TrainingPackTemplate template,
    required Map<String, bool> results,
    double learningRate = 0.15,
    bool dryRun = true,
    bool applyCompletionBonus = false,
    int requiredHands = 0,
    double requiredAccuracy = 0.0,
  }) async {
    final current = await computeMastery();
    final totals = <String, int>{};
    final correct = <String, int>{};

    final spotsById = {for (final s in template.spots) s.id: s};
    for (final entry in results.entries) {
      final spot = spotsById[entry.key];
      if (spot == null) continue;
      final tags = <String>{...spot.tags, ...spot.categories}
        ..removeWhere((t) => t.trim().isEmpty);
      for (final t in tags) {
        final key = t.trim().toLowerCase();
        totals.update(key, (v) => v + 1, ifAbsent: () => 1);
        if (entry.value) correct.update(key, (v) => v + 1, ifAbsent: () => 1);
      }
    }

    final deltas = <String, double>{};
    final updated = Map<String, double>.from(current);
    for (final tag in totals.keys) {
      final tot = totals[tag] ?? 0;
      final corr = correct[tag] ?? 0;
      final acc = tot == 0 ? 0.0 : corr / tot;
      final old = updated[tag] ?? 0.5;
      final neu = (old + (acc - old) * learningRate).clamp(0.0, 1.0);
      final delta = neu - old;
      if (delta.abs() > 1e-6) {
        deltas[tag] = delta;
        updated[tag] = neu;
      }
    }

    if (applyCompletionBonus) {
      final totalHands = results.length;
      final correctHands = results.values.where((e) => e).length;
      final accuracy = totalHands == 0 ? 0.0 : correctHands * 100 / totalHands;
      if (totalHands >= requiredHands && accuracy >= requiredAccuracy) {
        for (final tag in template.tags) {
          final key = tag.trim().toLowerCase();
          if (key.isEmpty) continue;
          final old = updated[key] ?? 0.5;
          final neu = (old + 0.1).clamp(0.0, 1.0);
          final delta = neu - old;
          if (delta.abs() > 1e-6) {
            deltas[key] = (deltas[key] ?? 0) + delta;
            updated[key] = neu;
          }
        }
      }
    }

    if (!dryRun) {
      _cache = updated;
      _cacheTime = DateTime.now();
      await MasteryPersistenceService().save(updated);
    }

    return deltas;
  }

  Future<Map<String, double>> computeDelta({bool fromLastWeek = false}) async {
    await logs.load();
    final now = DateTime.now();
    final thisWeekStart = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - 1));
    final lastWeekStart = thisWeekStart.subtract(const Duration(days: 7));
    final thisWeekLogs = logs.filter(range: DateTimeRange(thisWeekStart, now));
    final lastWeekLogs = logs.filter(
      range: DateTimeRange(
        lastWeekStart,
        thisWeekStart.subtract(const Duration(seconds: 1)),
      ),
    );

    final current = await _computeForLogs(thisWeekLogs);
    final previous = await _computeForLogs(lastWeekLogs);

    final delta = <String, double>{};
    for (final e in current.entries) {
      final prev = previous[e.key];
      if (prev != null) delta[e.key] = e.value - prev;
    }
    return delta;
  }

  Future<Map<String, double>> _computeForLogs(List<SessionLog> list) async {
    await PackLibraryLoaderService.instance.loadLibrary();
    final library = PackLibraryLoaderService.instance.library;
    final byId = {for (final t in library) t.id: t};

    final sums = <String, double>{};
    final counts = <String, int>{};
    final spotCounts = <String, int>{};

    for (final t in library) {
      for (final s in t.spots) {
        for (final tag in s.tags) {
          final key = tag.trim().toLowerCase();
          if (key.isEmpty) continue;
          spotCounts.update(key, (v) => v + 1, ifAbsent: () => 1);
        }
      }
    }

    for (final log in list) {
      final tpl = byId[log.templateId];
      if (tpl == null) continue;
      final total = log.correctCount + log.mistakeCount;
      if (total == 0) continue;
      final acc = log.correctCount / total;
      for (final tag in tpl.tags) {
        final key = tag.trim().toLowerCase();
        if (key.isEmpty) continue;
        sums[key] = (sums[key] ?? 0) + acc;
        counts[key] = (counts[key] ?? 0) + 1;
      }
    }

    final result = <String, double>{};
    for (final e in sums.entries) {
      final c = counts[e.key]!;
      if ((spotCounts[e.key] ?? 0) < 3) continue;
      result[e.key] = (e.value / c).clamp(0.0, 1.0);
    }

    if (result.isEmpty) return {};
    final values = result.values.toList();
    final minVal = values.reduce(min);
    final maxVal = values.reduce(max);

    final normalized = <String, double>{};
    if (maxVal > minVal) {
      result.forEach((k, v) {
        normalized[k] = (v - minVal) / (maxVal - minVal);
      });
    } else {
      for (final k in result.keys) {
        normalized[k] = 1.0;
      }
    }
    return normalized;
  }

  /// Computes the total number of hands played for each tag.
  Future<Map<String, int>> computeAttempts() async {
    await logs.load();
    await PackLibraryLoaderService.instance.loadLibrary();
    final library = {
      for (final t in PackLibraryLoaderService.instance.library) t.id: t,
    };

    final counts = <String, int>{};
    for (final log in logs.logs) {
      final tpl = library[log.templateId];
      if (tpl == null) continue;
      final total = log.correctCount + log.mistakeCount;
      for (final tag in tpl.tags) {
        final key = tag.trim().toLowerCase();
        if (key.isEmpty) continue;
        counts.update(key, (v) => v + total, ifAbsent: () => total);
      }
    }
    return counts;
  }

  Future<Map<String, DateTime>> getLastTrained() async {
    if (_lastTrained == null ||
        DateTime.now().difference(_metaTime) > const Duration(hours: 6)) {
      await computeMastery(force: true);
    }
    return _lastTrained ?? {};
  }

  Future<Map<String, double>> getLastAccuracy() async {
    if (_lastAccuracy == null ||
        DateTime.now().difference(_metaTime) > const Duration(hours: 6)) {
      await computeMastery(force: true);
    }
    return _lastAccuracy ?? {};
  }
}
