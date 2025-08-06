import 'dart:io';

import '../models/v2/training_pack_spot.dart';

/// Tracks how often skill tags appear across generated spots.
class SkillTagCoverageTracker {
  final Map<String, int> _counts = <String, int>{};

  /// Records tags from a single [spot].
  void track(TrainingPackSpot spot) {
    for (final tag in spot.tags) {
      _counts[tag] = (_counts[tag] ?? 0) + 1;
    }
  }

  /// Convenience method to record tags from multiple [spots].
  void trackAll(Iterable<TrainingPackSpot> spots) {
    for (final s in spots) {
      track(s);
    }
  }

  /// Returns the current tag coverage counts.
  Map<String, int> get counts => _counts;

  /// Logs the coverage summary to [sink] or a default file.
  Future<void> logSummary([IOSink? sink]) async {
    final out = sink ??
        File('skill_tag_coverage.log').openWrite(mode: FileMode.append);
    for (final entry in _counts.entries) {
      out.writeln('${entry.key}: ${entry.value}');
    }
    await out.flush();
    if (sink == null) {
      await out.close();
    }
  }
}

