import 'dart:io';

import 'skill_tag_coverage_tracker.dart';

/// Centralized logger aggregating key metrics during hyperscale autogeneration.
class AutogenStatusDashboardService {
  AutogenStatusDashboardService({String logPath = 'autogen_report.log'})
      : _logFile = File(logPath);

  final File _logFile;
  DateTime? _start;
  int _totalPacks = 0;
  int _totalSpots = 0;
  int _skippedSpots = 0;
  int _fingerprintCount = 0;
  int _yamlFiles = 0;

  /// Marks the beginning of tracking.
  void start() => _start = DateTime.now();

  /// Records a generated pack and its [spotCount].
  void recordPack(int spotCount) {
    _totalPacks++;
    _yamlFiles++;
    _totalSpots += spotCount;
  }

  /// Records the number of skipped duplicate spots.
  void recordSkipped(int count) => _skippedSpots = count;

  /// Records that a fingerprint was generated.
  void recordFingerprint(String _) => _fingerprintCount++;

  /// Logs final aggregated statistics to console and to a log file.
  Future<void> logFinalStats(
    SkillTagCoverageTracker coverage, {
    int? yamlFiles,
  }) async {
    final end = DateTime.now();
    final start = _start ?? end;
    final buffer = StringBuffer()
      ..writeln('=== Autogen Status Report ===')
      ..writeln('Start: $start')
      ..writeln('End:   $end')
      ..writeln('Duration: ${end.difference(start)}')
      ..writeln('Packs generated: $_totalPacks')
      ..writeln('Unique spots: $_totalSpots')
      ..writeln('Duplicates skipped: $_skippedSpots')
      ..writeln('YAML files: ${yamlFiles ?? _yamlFiles}')
      ..writeln('Top 10 tags:');

    final sorted = coverage.counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    for (final entry in sorted.take(10)) {
      buffer.writeln('  ${entry.key}: ${entry.value}');
    }

    final report = buffer.toString();
    // Output to console for immediate visibility.
    print(report);
    // Persist to log file.
    await _logFile.writeAsString(report);
  }
}
