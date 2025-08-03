import '../models/theory_mini_lesson_node.dart';
import 'package:poker_analyzer/services/preferences_service.dart';
import '../models/v2/training_spot_v2.dart';
import 'booster_cooldown_service.dart';
import 'mini_lesson_progress_tracker.dart';
import 'booster_completion_tracker.dart';
import 'mini_lesson_library_service.dart';
import 'pack_library_loader_service.dart';
import 'training_pack_stats_service.dart';
import 'package:collection/collection.dart';

/// Scores theory lessons for recall based on relevance and recency.
class TheoryRecallEvaluator {
  final BoosterCooldownService cooldown;
  final MiniLessonProgressTracker progress;
  final double tagWeight;
  final double stageWeight;
  final double recencyWeight;
  final double cooldownPenalty;
  final double completionPenalty;

  const TheoryRecallEvaluator({
    BoosterCooldownService? cooldown,
    MiniLessonProgressTracker? progress,
    this.tagWeight = 1.0,
    this.stageWeight = 1.0,
    this.recencyWeight = 0.1,
    this.cooldownPenalty = 1.0,
    this.completionPenalty = 2.0,
  })  : cooldown = cooldown ?? BoosterCooldownService.instance,
        progress = progress ?? MiniLessonProgressTracker.instance;

  static final RegExp _stageRe = RegExp(r'^level\\d+\$', caseSensitive: false);

  String? _extractStage(Iterable<String> tags) {
    for (final t in tags) {
      final lc = t.trim().toLowerCase();
      if (_stageRe.hasMatch(lc)) return lc;
    }
    return null;
  }

  /// Returns [candidates] ordered by descending score for [spot].
  Future<List<TheoryMiniLessonNode>> rank(
    List<TheoryMiniLessonNode> candidates,
    TrainingSpotV2 spot,
  ) async {
    if (candidates.isEmpty) return [];
    final now = DateTime.now();
    final spotTags = {for (final t in spot.tags) t.trim().toLowerCase()};
    final spotStage = _extractStage(spot.tags);

    final entries = <_Entry>[];

    for (final lesson in candidates) {
      final lessonTags = {for (final t in lesson.tags) t.trim().toLowerCase()};
      final overlap = lessonTags.intersection(spotTags).length;

      double score = overlap * tagWeight;

      final lessonStage = lesson.stage?.toLowerCase() ?? _extractStage(lesson.tags);
      if (spotStage != null && lessonStage != null && spotStage == lessonStage) {
        score += stageWeight;
      }

      final last = await progress.lastViewed(lesson.id);
      if (last != null) {
        final days = now.difference(last).inDays.toDouble();
        score += days * recencyWeight;
      }

      if (await progress.isCompleted(lesson.id)) {
        score -= completionPenalty;
      }

      for (final tag in lessonTags.intersection(spotTags)) {
        final next = await cooldown.nextEligibleAt(lesson.id, tag);
        if (next != null && next.isAfter(now)) {
          final days = next.difference(now).inDays + 1;
          score -= days * cooldownPenalty;
        }
      }

      entries.add(_Entry(lesson, score));
    }

    entries.sort((a, b) => b.score.compareTo(a.score));
    return [for (final e in entries) e.lesson];
  }

  /// Returns theory lessons to recall based on recent low-accuracy boosters.
  Future<List<TheoryMiniLessonNode>> recallSuggestions({
    int limit = 3,
    double accuracyThreshold = 70.0,
    int days = 7,
    List<TrainingPackTemplateV2>? boosterLibrary,
    MiniLessonLibraryService? library,
  }) async {
    if (limit <= 0) return [];
    final packs = boosterLibrary ?? await PackLibraryLoaderService.instance.loadLibrary();
    final lessons = library ?? MiniLessonLibraryService.instance;
    await lessons.loadAll();
    final prefs = await PreferencesService.getInstance();
    final cutoff = DateTime.now().subtract(Duration(days: days));

    final completed = await BoosterCompletionTracker.instance.getAllCompletedBoosters();
    final tagScores = <String, double>{};
    for (final pack in packs) {
      if (!completed.contains(pack.id)) continue;
      if ((pack.meta['type']?.toString().toLowerCase() ?? '') != 'booster') {
        continue;
      }
      final lastStr = prefs.getString('completed_at_tpl_${pack.id}');
      if (lastStr == null) continue;
      final last = DateTime.tryParse(lastStr);
      if (last == null || last.isBefore(cutoff)) continue;
      final acc = prefs.getDouble('last_accuracy_tpl_${pack.id}_0') ??
          prefs.getDouble('last_accuracy_tpl_${pack.id}') ??
          100.0;
      if (acc >= accuracyThreshold) continue;
      final tags = <String>{
        ...pack.tags.map((e) => e.toLowerCase()),
      };
      final metaTags = pack.meta['tags'];
      if (metaTags is List) {
        tags.addAll(metaTags.map((e) => e.toString().toLowerCase()));
      }
      for (final t in tags) {
        if (t.isEmpty) continue;
        final score = 100 - acc;
        tagScores.update(t, (v) => v + score, ifAbsent: () => score);
      }
    }

    if (tagScores.isEmpty) return [];

    final now = DateTime.now();
    final tagEntries = <_TagEntry>[];
    for (final entry in tagScores.entries) {
      final tag = entry.key;
      final lessonList = lessons.findByTags([tag]);
      if (lessonList.isEmpty) continue;
      DateTime? last;
      for (final l in lessonList) {
        final ts = await progress.lastViewed(l.id);
        if (ts != null && (last == null || ts.isAfter(last))) {
          last = ts;
        }
      }
      final since = last == null ? days.toDouble() : now.difference(last).inDays.toDouble();
      final score = entry.value * (1 + since / days);
      tagEntries.add(_TagEntry(tag, score));
    }

    tagEntries.sort((a, b) => b.score.compareTo(a.score));

    final result = <TheoryMiniLessonNode>[];
    final seen = <String>{};
    for (final entry in tagEntries) {
      for (final lesson in lessons.findByTags([entry.tag])) {
        if (seen.add(lesson.id)) {
          result.add(lesson);
          if (result.length >= limit) return result;
        }
      }
    }
    return result;
  }
}

class _Entry {
  final TheoryMiniLessonNode lesson;
  final double score;
  _Entry(this.lesson, this.score);
}

class _TagEntry {
  final String tag;
  final double score;
  _TagEntry(this.tag, this.score);
}
