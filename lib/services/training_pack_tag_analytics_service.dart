import 'package:flutter/foundation.dart';

import 'pack_library_loader_service.dart';
import 'training_stats_service.dart';

class TagAnalytics {
  final String tag;
  final int launches;
  final int totalTrained;
  final int mistakes;
  const TagAnalytics({
    required this.tag,
    required this.launches,
    required this.totalTrained,
    required this.mistakes,
  });

  double get valueScore =>
      (launches * 2 + totalTrained - mistakes * 3).toDouble();
}

class TrainingPackTagAnalyticsService extends ChangeNotifier {
  final Map<String, _TagStat> _stats = {};
  bool _loaded = false;

  Future<void> loadStats() async {
    if (_loaded) return;
    _loaded = true;
    await PackLibraryLoaderService.instance.loadLibrary();
    final packs = PackLibraryLoaderService.instance.library;
    final statsService = TrainingStatsService.instance;
    if (statsService == null) return;
    for (final p in packs) {
      final stats = await statsService.getStatsForPack(p.id);
      if (stats.launches == 0 &&
          stats.totalTrained == 0 &&
          stats.mistakes == 0) {
        continue;
      }
      final tags = <String>{for (final t in p.tags) t.trim().toLowerCase()}
        ..removeWhere((e) => e.isEmpty);
      for (final t in tags) {
        final s = _stats.putIfAbsent(t, () => _TagStat());
        s.launches += stats.launches;
        s.total += stats.totalTrained;
        s.mistakes += stats.mistakes;
      }
    }
    notifyListeners();
  }

  List<TagAnalytics> getPopularTags() {
    final list = [
      for (final e in _stats.entries)
        TagAnalytics(
          tag: e.key,
          launches: e.value.launches,
          totalTrained: e.value.total,
          mistakes: e.value.mistakes,
        ),
    ]..sort((a, b) => b.valueScore.compareTo(a.valueScore));
    return list;
  }
}

class _TagStat {
  int launches = 0;
  int total = 0;
  int mistakes = 0;
}
