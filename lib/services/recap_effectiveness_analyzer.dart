import 'recap_completion_tracker.dart';

/// Evaluates recap tag effectiveness based on completion analytics.
class RecapEffectivenessAnalyzer {
  final RecapCompletionTracker tracker;

  RecapEffectivenessAnalyzer({RecapCompletionTracker? tracker})
    : tracker = tracker ?? RecapCompletionTracker.instance;

  static final RecapEffectivenessAnalyzer instance =
      RecapEffectivenessAnalyzer();

  Map<String, TagEffectiveness> _stats = {};

  /// Most recent effectiveness stats keyed by tag.
  Map<String, TagEffectiveness> get stats => _stats;

  /// Recomputes effectiveness metrics from recent completions.
  Future<void> refresh({Duration window = const Duration(days: 14)}) async {
    final completions = await tracker.getRecentCompletions(window: window);
    final map = <String, _MutableTagStats>{};
    for (final c in completions) {
      final tag = c.tag.trim().toLowerCase();
      if (tag.isEmpty) continue;
      final stat = map.putIfAbsent(tag, () => _MutableTagStats());
      stat.count++;
      stat.totalDuration += c.duration;
      stat.timestamps.add(c.timestamp);
    }
    _stats = {
      for (final e in map.entries) e.key: e.value.toEffectiveness(e.key),
    };
  }

  /// Returns true if [tag] appears to be underperforming.
  bool isUnderperforming(
    String tag, {
    int minCompletions = 3,
    Duration minAvgDuration = const Duration(seconds: 5),
    double minRepeatRate = 0.25,
  }) {
    final s = _stats[tag];
    if (s == null) return true;
    if (s.count < minCompletions) return true;
    if (s.averageDuration < minAvgDuration) return true;
    if (s.repeatRate < minRepeatRate) return true;
    return false;
  }

  /// List of tags that should be suppressed in rotation.
  List<String> suppressedTags({
    int minCompletions = 3,
    Duration minAvgDuration = const Duration(seconds: 5),
    double minRepeatRate = 0.25,
  }) {
    return [
      for (final t in _stats.keys)
        if (isUnderperforming(
          t,
          minCompletions: minCompletions,
          minAvgDuration: minAvgDuration,
          minRepeatRate: minRepeatRate,
        ))
          t,
    ];
  }
}

/// Computed effectiveness metrics for a recap [tag].
class TagEffectiveness {
  final String tag;
  final int count;
  final Duration averageDuration;
  final double repeatRate;

  TagEffectiveness({
    required this.tag,
    required this.count,
    required this.averageDuration,
    required this.repeatRate,
  });
}

class _MutableTagStats {
  int count = 0;
  Duration totalDuration = Duration.zero;
  final List<DateTime> timestamps = [];

  TagEffectiveness toEffectiveness(String tag) {
    timestamps.sort();
    var repeats = 0;
    for (var i = 1; i < timestamps.length; i++) {
      final diff = timestamps[i].difference(timestamps[i - 1]).inDays;
      if (diff <= 5) repeats++;
    }
    final repeatRate = timestamps.length > 1
        ? repeats / (timestamps.length - 1)
        : 0.0;
    final avg = count > 0
        ? Duration(milliseconds: totalDuration.inMilliseconds ~/ count)
        : Duration.zero;
    return TagEffectiveness(
      tag: tag,
      count: count,
      averageDuration: avg,
      repeatRate: repeatRate,
    );
  }
}
