import 'dart:math' as math;

import '../models/decay_tag_reinforcement_event.dart';
import 'decay_session_tag_impact_recorder.dart';

class TagDecayStats {
  final String tag;
  final DateTime? lastTrained;
  final Duration timeSinceLast;
  final Duration averageInterval;
  final double intervalStd;
  final DateTime? nextReview;

  const TagDecayStats({
    required this.tag,
    this.lastTrained,
    this.timeSinceLast = Duration.zero,
    this.averageInterval = Duration.zero,
    this.intervalStd = 0,
    this.nextReview,
  });
}

class TagDecayForecastService {
  const TagDecayForecastService();

  Future<Map<String, TagDecayStats>> summarize({DateTime? now}) async {
    final events = await DecaySessionTagImpactRecorder.instance.loadAllEvents();
    final current = now ?? DateTime.now();
    final grouped = <String, List<DateTime>>{};
    for (final e in events) {
      grouped.putIfAbsent(e.tag, () => []).add(e.timestamp);
    }
    final result = <String, TagDecayStats>{};
    for (final entry in grouped.entries) {
      final times = entry.value..sort();
      final last = times.isNotEmpty ? times.last : null;
      final intervals = <double>[];
      for (var i = 1; i < times.length; i++) {
        intervals.add(times[i].difference(times[i - 1]).inMilliseconds / 86400000);
      }
      final avg = intervals.isEmpty
          ? 0.0
          : intervals.reduce((a, b) => a + b) / intervals.length;
      final std = intervals.isEmpty
          ? 0.0
          : math.sqrt(intervals
                  .map((d) => math.pow(d - avg, 2))
                  .reduce((a, b) => a + b) /
              intervals.length);
      final next = last != null ? last.add(Duration(days: avg.round())) : null;
      final sinceLast = last != null ? current.difference(last) : Duration.zero;
      result[entry.key] = TagDecayStats(
        tag: entry.key,
        lastTrained: last,
        timeSinceLast: sinceLast,
        averageInterval: Duration(days: avg.round()),
        intervalStd: std,
        nextReview: next,
      );
    }
    return result;
  }
}
