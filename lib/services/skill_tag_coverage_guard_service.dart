import 'dart:math';

import '../models/coverage_report.dart';
import '../models/v2/training_pack_template_v2.dart';
import '../models/v2/training_pack_spot.dart';
import 'preferences_service.dart';
import '../utils/app_logger.dart';

enum CoverageGuardMode { soft, strict }

class _Thresholds {
  final int minUniqueTags;
  final double minCoveragePct;
  const _Thresholds({
    required this.minUniqueTags,
    required this.minCoveragePct,
  });
}

class SkillTagCoverageGuardService {
  static const _defaultMinUniqueTags = 5;
  static const _defaultMinCoveragePct = 0.35;
  static const _uniqueKey = 'coverage.minUniqueTags';
  static const _pctKey = 'coverage.minCoveragePct';

  final CoverageGuardMode mode;
  int rejectedCount = 0;

  SkillTagCoverageGuardService({this.mode = CoverageGuardMode.soft});

  Future<CoverageReport> evaluate(TrainingPackTemplateV2 pack) async {
    final tags = <String>[];
    for (final TrainingPackSpot s in pack.spots) {
      for (final t in s.tags) {
        final norm = t.trim().toLowerCase();
        if (norm.isEmpty) continue;
        tags.add(norm);
      }
    }
    final counts = <String, int>{};
    for (final t in tags) {
      counts[t] = (counts[t] ?? 0) + 1;
    }
    final total = counts.values.fold(0, (a, b) => a + b);
    final unique = counts.length;
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topTags = [for (final e in sorted.take(5)) e.key];
    final pct = total == 0 ? 0.0 : unique / total;
    final audience = pack.audience ?? pack.meta['audience']?.toString();
    final th = await getThresholds(audience: audience);
    var passes = unique >= th.minUniqueTags && pct >= th.minCoveragePct;
    if (!passes) {
      AppLogger.warn(
          'skill_tag_coverage_guard: pack=${pack.id} unique=$unique coverage=${pct.toStringAsFixed(2)}');
      if (mode == CoverageGuardMode.strict) {
        rejectedCount++;
      } else {
        passes = true;
      }
    }
    return CoverageReport(
      totalTags: total,
      uniqueTags: unique,
      topTags: topTags,
      coveragePct: pct,
      passes: passes,
    );
  }

  static String _audKey(String base, String audience) => '$base.$audience';

  static Future<void> setThresholds({
    int? minUniqueTags,
    double? minCoveragePct,
    String? audience,
  }) async {
    final prefs = await PreferencesService.getInstance();
    final keyUnique =
        audience == null ? _uniqueKey : _audKey(_uniqueKey, audience);
    final keyPct = audience == null ? _pctKey : _audKey(_pctKey, audience);
    if (minUniqueTags != null) {
      await prefs.setInt(keyUnique, minUniqueTags);
    }
    if (minCoveragePct != null) {
      await prefs.setDouble(keyPct, minCoveragePct);
    }
  }

  static Future<_Thresholds> getThresholds({String? audience}) async {
    final prefs = await PreferencesService.getInstance();
    final unique = prefs.getInt(
          audience == null ? _uniqueKey : _audKey(_uniqueKey, audience),
        ) ??
        prefs.getInt(_uniqueKey) ??
        _defaultMinUniqueTags;
    final pct = prefs.getDouble(
          audience == null ? _pctKey : _audKey(_pctKey, audience),
        ) ??
        prefs.getDouble(_pctKey) ??
        _defaultMinCoveragePct;
    return _Thresholds(minUniqueTags: unique, minCoveragePct: pct);
  }
}
