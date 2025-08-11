import 'dart:io';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../models/autogen_stats_model.dart';
import '../models/skill_tag_stats.dart';
import '../models/autogen_preset.dart';

/// Centralized logger aggregating key metrics during hyperscale autogeneration.
class AutogenStatsDashboardService extends ChangeNotifier {
  AutogenStatsDashboardService._({String logPath = 'autogen_report.log'})
    : _logFile = File(logPath);

  static final AutogenStatsDashboardService _instance =
      AutogenStatsDashboardService._();

  factory AutogenStatsDashboardService() => _instance;
  static AutogenStatsDashboardService get instance => _instance;

  final File _logFile;
  final AutogenStatsModel stats = AutogenStatsModel();
  SkillTagStats coverage = const SkillTagStats(
    tagCounts: {},
    totalTags: 0,
    unusedTags: [],
    overloadedTags: [],
  );
  Map<String, double> categoryCoverage = {};
  Map<String, int> categoryCounts = {};
  Map<String, int> textureCounts = {};
  Map<String, int> textureRejects = {};
  Map<String, double> targetTextureMix = {};
  int theoryLinked = 0;
  int theoryRejectedLowScore = 0;
  int uniqueTheoryUsed = 0;
  double avgTheoryScore = 0;
  final Set<String> _theoryIds = {};
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
    coverage = const SkillTagStats(
      tagCounts: {},
      totalTags: 0,
      unusedTags: [],
      overloadedTags: [],
    );
    categoryCoverage = {};
    categoryCounts = {};
    textureCounts = {};
    textureRejects = {};
    targetTextureMix = {};
    theoryLinked = 0;
    theoryRejectedLowScore = 0;
    uniqueTheoryUsed = 0;
    avgTheoryScore = 0;
    _theoryIds.clear();
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

  void setTargetTextureMix(Map<String, double> mix) {
    targetTextureMix = Map.from(mix);
    notifyListeners();
  }

  void recordTexture(String tex) {
    textureCounts[tex] = (textureCounts[tex] ?? 0) + 1;
    notifyListeners();
  }

  void recordRejectedTexture(String tex) {
    textureRejects[tex] = (textureRejects[tex] ?? 0) + 1;
  }

  /// Records theory linking statistics for dashboard preview and logs.
  void recordTheoryLinking({
    required int linked,
    required int rejectedLowScore,
    required Set<String> ids,
    required double avgScore,
  }) {
    theoryLinked += linked;
    theoryRejectedLowScore += rejectedLowScore;
    _theoryIds.addAll(ids);
    uniqueTheoryUsed = _theoryIds.length;
    if (theoryLinked > 0) {
      avgTheoryScore =
          ((avgTheoryScore * (theoryLinked - linked)) + avgScore * linked) /
              theoryLinked;
    }
    _logFile.writeAsString(
      'Theory linked: $linked avg:${avgScore.toStringAsFixed(2)} '
      'unique:${ids.length} rejected:$rejectedLowScore\n',
      mode: FileMode.append,
    );
    notifyListeners();
  }

  /// Updates coverage statistics for dashboard preview.
  void recordCoverage(SkillTagStats report) {
    coverage = report;
    categoryCoverage = Map.from(report.categoryCoverage);
    categoryCounts = Map.from(report.categoryCounts);
    notifyListeners();
  }

  void logPreset(AutogenPreset preset) {
    _logFile.writeAsString(
      'Preset: ${preset.id} ${jsonEncode(preset.toJson())}\n',
      mode: FileMode.append,
    );
  }

  /// Logs final aggregated statistics to console and to a log file.
  Future<void> logFinalStats(SkillTagStats coverage, {int? yamlFiles}) async {
    final end = DateTime.now();
    final start = _start ?? end;
    categoryCoverage = Map.from(coverage.categoryCoverage);
    categoryCounts = Map.from(coverage.categoryCounts);
    final buffer = StringBuffer()
      ..writeln('=== Autogen Stats Report ===')
      ..writeln('Start: $start')
      ..writeln('End:   $end')
      ..writeln('Duration: ${end.difference(start)}')
      ..writeln('Packs generated: ${stats.totalPacks}')
      ..writeln('Unique spots: ${stats.totalSpots}')
      ..writeln('Duplicates skipped: ${stats.skippedSpots}')
      ..writeln('YAML files: ${yamlFiles ?? _yamlFiles}')
      ..writeln('Top 10 tags:');

    final sorted = coverage.tagCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    for (final entry in sorted.take(10)) {
      buffer.writeln('  ${entry.key}: ${entry.value}');
    }

    if (targetTextureMix.isNotEmpty) {
      buffer.writeln('Texture target: $targetTextureMix');
      buffer.writeln('Texture achieved: $textureCounts');
      buffer.writeln('Texture rejects: $textureRejects');
    }

    if (categoryCoverage.isNotEmpty) {
      buffer.writeln('Category coverage:');
      final cats = categoryCoverage.entries.toList()
        ..sort((a, b) => a.key.compareTo(b.key));
      for (final entry in cats) {
        final pct = (entry.value * 100).toStringAsFixed(1);
        final count = categoryCounts[entry.key] ?? 0;
        buffer.writeln('  ${entry.key}: $pct% ($count)');
      }
      final under = underrepresentedCategories();
      if (under.isNotEmpty) {
        buffer.writeln('Underrepresented: '
            '${under.map((e) => e.key).join(', ')}');
      }
    }

    final report = buffer.toString();
    // Output to console for immediate visibility.
    print(report);
    // Persist to log file.
    await _logFile.writeAsString(report);
  }

  List<MapEntry<String, double>> underrepresentedCategories(
      [double threshold = 0.6]) {
    final entries = categoryCoverage.entries
        .where((e) => e.value < threshold)
        .toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    return entries;
  }
}
