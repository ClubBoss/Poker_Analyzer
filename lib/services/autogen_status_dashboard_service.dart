import 'dart:io';

import 'package:flutter/foundation.dart';

import '../models/autogen_stats_model.dart';
import 'skill_tag_coverage_tracker.dart';

/// Centralized logger aggregating key metrics during hyperscale autogeneration.
class AutogenStatusDashboardService extends ChangeNotifier {
  AutogenStatusDashboardService._({String logPath = 'autogen_report.log'})
      : _logFile = File(logPath);

  static final AutogenStatusDashboardService _instance =
      AutogenStatusDashboardService._();

  factory AutogenStatusDashboardService() => _instance;
  static AutogenStatusDashboardService get instance => _instance;

  final File _logFile;
  final AutogenStatsModel stats = AutogenStatsModel();
  DateTime? _start;
  int _yamlFiles = 0;

  /// Marks the beginning of tracking.
  void start() {
    _start = DateTime.now();
    stats
      ..totalPacks = 0
      ..totalSpots = 0
      ..skippedSpots = 0
      ..fingerprintCount = 0;
    _yamlFiles = 0;
    notifyListeners();
  }

  /// Records a generated pack and its [spotCount].
  void recordPack(int spotCount) {
    stats.totalPacks++;
    _yamlFiles++;
    stats.totalSpots += spotCount;
    notifyListeners();
  }

  /// Records the number of skipped duplicate spots.
  void recordSkipped(int count) {
    stats.skippedSpots = count;
    notifyListeners();
  }

  /// Records that a fingerprint was generated.
  void recordFingerprint(String _) {
    stats.fingerprintCount++;
    notifyListeners();
  }

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
      ..writeln('Packs generated: ${stats.totalPacks}')
      ..writeln('Unique spots: ${stats.totalSpots}')
      ..writeln('Duplicates skipped: ${stats.skippedSpots}')
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
