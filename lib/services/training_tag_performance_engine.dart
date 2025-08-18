import 'package:hive_flutter/hive_flutter.dart';
import '../models/session_log.dart';
import 'pack_library_loader_service.dart';

class TagPerformance {
  final String tag;
  final int totalAttempts;
  final int correct;
  final double accuracy;
  final DateTime? lastTrained;

  const TagPerformance({
    required this.tag,
    required this.totalAttempts,
    required this.correct,
    required this.accuracy,
    required this.lastTrained,
  });
}

class TrainingTagPerformanceEngine {
  static Map<String, TagPerformance>? _cache;
  static DateTime _cacheTime = DateTime.fromMillisecondsSinceEpoch(0);

  static Future<Map<String, TagPerformance>> computeTagStats({
    bool force = false,
  }) async {
    if (!force &&
        _cache != null &&
        DateTime.now().difference(_cacheTime) < const Duration(hours: 1)) {
      return _cache!;
    }

    await PackLibraryLoaderService.instance.loadLibrary();
    final library = PackLibraryLoaderService.instance.library;
    final byId = {for (final t in library) t.id: t};

    if (!Hive.isBoxOpen('session_logs')) {
      await Hive.initFlutter();
      await Hive.openBox('session_logs');
    }
    final box = Hive.box('session_logs');

    final stats = <String, _MutableStat>{};

    for (final v in box.values.whereType<Map>()) {
      final log = SessionLog.fromJson(Map<String, dynamic>.from(v));
      final tpl = byId[log.templateId];
      if (tpl == null) continue;
      final tags = <String>{
        ...tpl.tags.map((e) => e.trim().toLowerCase()),
        ...tpl.focusTags.map((e) => e.trim().toLowerCase()),
      }..removeWhere((e) => e.isEmpty);
      if (tags.isEmpty) continue;
      final total = log.correctCount + log.mistakeCount;
      for (final t in tags) {
        final s = stats.putIfAbsent(t, () => _MutableStat());
        s.total += total;
        s.correct += log.correctCount;
        if (s.lastTrained == null || log.completedAt.isAfter(s.lastTrained!)) {
          s.lastTrained = log.completedAt;
        }
      }
    }

    final entries = [
      for (final e in stats.entries)
        MapEntry(e.key, e.value.toPerformance(e.key)),
    ]..sort((a, b) => b.value.totalAttempts.compareTo(a.value.totalAttempts));

    final result = <String, TagPerformance>{};
    for (final e in entries) {
      result[e.key] = e.value;
    }

    _cache = result;
    _cacheTime = DateTime.now();
    return result;
  }
}

class _MutableStat {
  int total = 0;
  int correct = 0;
  DateTime? lastTrained;

  TagPerformance toPerformance(String tag) => TagPerformance(
    tag: tag,
    totalAttempts: total,
    correct: correct,
    accuracy: total > 0 ? correct / total : 0,
    lastTrained: lastTrained,
  );
}
