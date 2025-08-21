import 'dart:math';
import 'dart:io';

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

  final int? minUniqueTagsOverride;
  final double? minCoveragePctOverride;

  SkillTagCoverageGuardService({
    this.mode = CoverageGuardMode.soft,
    this.minUniqueTagsOverride,
    this.minCoveragePctOverride,
  });

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
    final th = (minUniqueTagsOverride != null || minCoveragePctOverride != null)
        ? _Thresholds(
            minUniqueTags: minUniqueTagsOverride ?? _defaultMinUniqueTags,
            minCoveragePct: minCoveragePctOverride ?? _defaultMinCoveragePct,
          )
        : await getThresholds(audience: audience);
    var passes = unique >= th.minUniqueTags && pct >= th.minCoveragePct;
    if (!passes) {
      AppLogger.warn(
        'skill_tag_coverage_guard: pack=${pack.id} unique=$unique coverage=${pct.toStringAsFixed(2)}',
      );
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

  static SkillTagCoverageGuardService? fromEnv([Map<String, String>? env]) {
    final e = env ?? Platform.environment;
    final modeStr = e['COVERAGE_MODE'];
    final uniqueStr = e['COVERAGE_MIN_UNIQUE_TAGS'];
    final pctStr = e['COVERAGE_MIN_PCT'];
    if (modeStr == null && uniqueStr == null && pctStr == null) {
      return null;
    }
    final mode =
        modeStr == 'strict' ? CoverageGuardMode.strict : CoverageGuardMode.soft;
    int? minUnique;
    double? minPct;
    if (uniqueStr != null) {
      minUnique = int.tryParse(uniqueStr);
      if (minUnique == null) {
        AppLogger.warn('Invalid COVERAGE_MIN_UNIQUE_TAGS: $uniqueStr');
      }
    }
    if (pctStr != null) {
      minPct = double.tryParse(pctStr);
      if (minPct == null) {
        AppLogger.warn('Invalid COVERAGE_MIN_PCT: $pctStr');
      }
    }
    final effectiveUnique = minUnique ?? _defaultMinUniqueTags;
    final effectivePct = minPct ?? _defaultMinCoveragePct;
    AppLogger.info(
      'coverage_guard_env: mode=$mode unique=$effectiveUnique pct=${effectivePct.toStringAsFixed(2)}',
    );
    return SkillTagCoverageGuardService(
      mode: mode,
      minUniqueTagsOverride: minUnique,
      minCoveragePctOverride: minPct,
    );
  }

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
