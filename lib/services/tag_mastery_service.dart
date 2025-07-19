import 'dart:math';
import 'pack_library_loader_service.dart';
import 'session_log_service.dart';
import 'training_pack_stats_service.dart';

class TagMasteryService {
  final SessionLogService logs;
  TagMasteryService({required this.logs});

  static Map<String, double>? _cache;
  static DateTime _cacheTime = DateTime.fromMillisecondsSinceEpoch(0);

  Future<Map<String, double>> computeMastery({bool force = false}) async {
    if (!force && _cache != null &&
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
}

