import 'dart:io';
import 'dart:math';

import '../models/training_pack_model.dart';
import '../models/skill_tag_coverage_report.dart';

/// Tracks how often skill tags appear across generated packs.
class SkillTagCoverageTracker {
  final Map<String, int> _aggregateCounts = <String, int>{};
  int _totalSpots = 0;

  /// Analyzes [pack] and updates global coverage counts.
  SkillTagCoverageReport analyze(TrainingPackModel pack) {
    final counts = <String, int>{};
    for (final spot in pack.spots) {
      _totalSpots++;
      for (final tag in spot.tags) {
        counts[tag] = (counts[tag] ?? 0) + 1;
        _aggregateCounts[tag] = (_aggregateCounts[tag] ?? 0) + 1;
      }
    }
    return _buildReport(counts, pack.spots.length);
  }

  /// Returns the aggregated coverage across all analyzed packs.
  SkillTagCoverageReport get aggregateReport =>
      _buildReport(_aggregateCounts, _totalSpots);

  SkillTagCoverageReport _buildReport(
    Map<String, int> counts,
    int totalSpots,
  ) {
    final values = counts.values.toList();
    final minCount = values.isEmpty ? 0 : values.reduce(min);
    final maxCount = values.isEmpty ? 0 : values.reduce(max);
    return SkillTagCoverageReport(
      tagCounts: Map<String, int>.from(counts),
      totalSpots: totalSpots,
      minCount: minCount,
      maxCount: maxCount,
    );
  }

  /// Logs the aggregate coverage summary to [sink] or a default file.
  Future<void> logSummary([IOSink? sink]) async {
    final report = aggregateReport;
    final out = sink ??
        File('skill_tag_coverage.log').openWrite(mode: FileMode.append);
    for (final entry in report.tagCounts.entries) {
      out.writeln('${entry.key}: ${entry.value}');
    }
    await out.flush();
    if (sink == null) {
      await out.close();
    }
  }
}
