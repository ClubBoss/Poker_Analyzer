import 'package:collection/collection.dart';
import 'package:poker_analyzer/services/preferences_service.dart';
import 'learning_path_orchestrator.dart';
import 'pack_library_loader_service.dart';

import '../models/training_attempt.dart';
import '../models/v2/training_pack_template_v2.dart';
import 'training_pack_template_service.dart';

/// Summary of a player's overall training progress.
class TrainingProgress {
  final double completionRate;
  final List<String> mostImprovedTags;
  final int streakDays;

  const TrainingProgress({
    required this.completionRate,
    required this.mostImprovedTags,
    required this.streakDays,
  });
}

class TrainingProgressService {
  TrainingProgressService._();
  static final instance = TrainingProgressService._();

  /// Cached progress values for stage -> subStage pairs.
  final Map<String, Map<String, double>> subStageProgress = {};
  Map<String, double>? _tagCache;
  DateTime _tagCacheTime = DateTime.fromMillisecondsSinceEpoch(0);

  Future<double> getProgress(String templateId) async {
    final prefs = await PreferencesService.getInstance();
    final idx = prefs.getInt('tpl_prog_$templateId') ??
        prefs.getInt('progress_tpl_$templateId');
    if (idx == null) return 0.0;
    final tpl = TrainingPackTemplateService.getById(templateId);
    if (tpl == null) return 0.0;
    final count = tpl.spots.isNotEmpty ? tpl.spots.length : tpl.spotCount;
    if (count == 0) return 0.0;
    return ((idx + 1) / count).clamp(0.0, 1.0);
  }

  /// Returns progress for [subStageId] within [stageId].
  ///
  /// Progress values are cached in [subStageProgress]. The calculation is
  /// delegated to [getProgress] using the subStage's pack id.
  Future<double> getSubStageProgress(String stageId, String subStageId) async {
    final cached = subStageProgress[stageId]?[subStageId];
    if (cached != null) return cached;
    final prog = await getProgress(subStageId);
    final byStage = subStageProgress.putIfAbsent(stageId, () => {});
    byStage[subStageId] = prog;
    return prog;
  }

  /// Computes average progress for all packs containing [tag].
  Future<double> getTagProgress(String tag) async {
    final now = DateTime.now();
    final lc = tag.trim().toLowerCase();
    if (_tagCache != null &&
        now.difference(_tagCacheTime) < const Duration(minutes: 5) &&
        _tagCache!.containsKey(lc)) {
      return _tagCache![lc]!;
    }

    await PackLibraryLoaderService.instance.loadLibrary();
    final packs = PackLibraryLoaderService.instance.library;

    var sum = 0.0;
    var count = 0;

    for (final p in packs) {
      final tags = <String>{
        ...p.tags.map((e) => e.trim().toLowerCase()),
        for (final s in p.spots) ...s.tags.map((e) => e.trim().toLowerCase()),
      }..removeWhere((e) => e.isEmpty);
      if (!tags.contains(lc)) continue;
      sum += await getProgress(p.id);
      count++;
    }

    final value = count == 0 ? 0.0 : sum / count;
    final cache = _tagCache ??= {};
    cache[lc] = value;
    _tagCacheTime = now;
    return value;
  }

  /// Computes high-level training stats from [attempts] and [allPacks].
  ///
  /// Packs with average accuracy of 90% or higher are considered completed.
  /// Tag improvements are measured by comparing average tag accuracy of the
  /// last 7 days versus all earlier attempts. Only the top three tags with
  /// positive improvement are returned.
  TrainingProgress computeOverallProgress({
    required List<TrainingAttempt> attempts,
    required List<TrainingPackTemplateV2> allPacks,
  }) {
    if (allPacks.isEmpty) {
      return const TrainingProgress(
        completionRate: 0,
        mostImprovedTags: [],
        streakDays: 0,
      );
    }

    // Index tags by pack and spot for quick lookup.
    final tagsByPack = <String, Map<String, List<String>>>{};
    for (final p in allPacks) {
      tagsByPack[p.id] = {
        for (final s in p.spots)
          s.id: [for (final t in s.tags) t.trim().toLowerCase()]
      };
    }

    // Determine the latest attempt per pack/spot.
    final latest = <String, Map<String, TrainingAttempt>>{};
    for (final a in attempts) {
      final bySpot = latest.putIfAbsent(a.packId, () => {});
      final prev = bySpot[a.spotId];
      if (prev == null || a.timestamp.isAfter(prev.timestamp)) {
        bySpot[a.spotId] = a;
      }
    }

    // Compute pack completion rate.
    var completed = 0;
    for (final p in allPacks) {
      final map = latest[p.id];
      final spotCount = p.spots.isNotEmpty ? p.spots.length : p.spotCount;
      if (map == null || spotCount == 0) continue;
      if (map.length < spotCount) continue;
      final avg = map.values
              .map((a) => a.accuracy)
              .sum /
          spotCount;
      if (avg >= 0.9) completed += 1;
    }
    final completionRate = completed / allPacks.length;

    final now = DateTime.now();
    final cutoff = now.subtract(const Duration(days: 7));

    final recent = <String, List<double>>{};
    final earlier = <String, List<double>>{};

    void collect(TrainingAttempt a, Map<String, List<double>> target) {
      final tags = tagsByPack[a.packId]?[a.spotId];
      if (tags == null) return;
      for (final t in tags) {
        if (t.isEmpty) continue;
        target.putIfAbsent(t, () => []).add(a.accuracy);
      }
    }

    for (final a in attempts) {
      if (a.timestamp.isAfter(cutoff)) {
        collect(a, recent);
      } else {
        collect(a, earlier);
      }
    }

    double avg(List<double> l) => l.isNotEmpty ? l.sum / l.length : 0;

    final improvements = <String, double>{};
    final allTags = {...recent.keys, ...earlier.keys};
    for (final t in allTags) {
      final delta = avg(recent[t] ?? []) - avg(earlier[t] ?? []);
      improvements[t] = delta;
    }

    final mostImprovedTags = improvements.entries
        .where((e) => e.value > 0)
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final improved = [for (final e in mostImprovedTags.take(3)) e.key];

    // Compute streak based on attempts per day.
    final days = attempts
        .map((a) => DateTime(a.timestamp.year, a.timestamp.month, a.timestamp.day))
        .toSet();
    var streak = 0;
    for (var i = 0; ; i++) {
      final day = DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
      if (days.contains(day)) {
        streak += 1;
      } else {
        break;
      }
    }

    return TrainingProgress(
      completionRate: completionRate,
      mostImprovedTags: improved,
      streakDays: streak,
    );
  }

  /// Returns average progress for the stage with [stageId]. If the stage
  /// contains sub-stages the progress is averaged across them.
  Future<double> getStageProgress(String stageId) async {
    final path = await LearningPathOrchestrator.instance.resolve();
    final stage = path.stages.firstWhereOrNull((s) => s.id == stageId);
    if (stage == null) return 0.0;
    if (stage.subStages.isEmpty) {
      return getProgress(stage.packId);
    }
    double sum = 0.0;
    for (final sub in stage.subStages) {
      sum += await getSubStageProgress(stage.id, sub.packId);
    }
    return sum / stage.subStages.length;
  }
}
