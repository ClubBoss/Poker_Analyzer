import '../models/training_track.dart';
import '../models/training_result.dart';
import '../models/training_track_summary.dart';

class TrainingTrackSummarizer {
  const TrainingTrackSummarizer();

  TrainingTrackSummary summarizeTrack({
    required TrainingTrack track,
    required List<TrainingResult> results,
  }) {
    final spotIds = {for (final s in track.spots) s.id};
    final spotsById = {for (final s in track.spots) s.id: s};

    int total = 0;
    int correct = 0;
    double evBeforeSum = 0;
    int evBeforeCount = 0;
    double evAfterSum = 0;
    int evAfterCount = 0;

    final tagTotal = <String, int>{};
    final tagCorrect = <String, int>{};
    final tagEvBeforeSum = <String, double>{};
    final tagEvBeforeCount = <String, int>{};
    final tagEvAfterSum = <String, double>{};
    final tagEvAfterCount = <String, int>{};

    String? spotId(dynamic r) {
      try {
        final id = r.spotId;
        if (id is String) return id;
      } catch (_) {}
      return null;
    }

    bool isCorrect(dynamic r) {
      try {
        final v = r.isCorrect;
        if (v is bool) return v;
      } catch (_) {}
      try {
        final v = r.correct;
        if (v is bool) return v;
        if (v is num) return v > 0;
      } catch (_) {}
      return false;
    }

    double? evAfter0(dynamic r) {
      try {
        final v = r.ev;
        if (v is num) return v.toDouble();
      } catch (_) {}
      try {
        final v = r.heroEv;
        if (v is num) return v.toDouble();
      } catch (_) {}
      return null;
    }

    for (final r in results) {
      final id = spotId(r);
      if (id == null || !spotIds.contains(id)) continue;
      final spot = spotsById[id];
      total += 1;
      final correctFlag = isCorrect(r);
      if (correctFlag) correct++;
      final before = spot?.heroEv;
      if (before != null) {
        evBeforeSum += before;
        evBeforeCount++;
      }
      final after = evAfter0(r);
      if (after != null) {
        evAfterSum += after;
        evAfterCount++;
      }
      final tags = <String>{
        ...?spot?.tags,
        ...?spot?.categories,
      }..removeWhere((e) => e.trim().isEmpty);
      for (final t in tags) {
        final tag = t.trim().toLowerCase();
        if (tag.isEmpty) continue;
        tagTotal.update(tag, (v) => v + 1, ifAbsent: () => 1);
        if (correctFlag)
          tagCorrect.update(tag, (v) => v + 1, ifAbsent: () => 1);
        if (before != null) {
          tagEvBeforeSum.update(tag, (v) => v + before, ifAbsent: () => before);
          tagEvBeforeCount.update(tag, (v) => v + 1, ifAbsent: () => 1);
        }
        if (after != null) {
          tagEvAfterSum.update(tag, (v) => v + after, ifAbsent: () => after);
          tagEvAfterCount.update(tag, (v) => v + 1, ifAbsent: () => 1);
        }
      }
    }

    final breakdown = <String, TagSummary>{};
    for (final tag in tagTotal.keys) {
      final tot = tagTotal[tag] ?? 0;
      final corr = tagCorrect[tag] ?? 0;
      final acc = tot == 0 ? 0 : corr * 100 / tot;
      final before = tagEvBeforeCount.containsKey(tag)
          ? tagEvBeforeSum[tag]! / tagEvBeforeCount[tag]!
          : null;
      final after = tagEvAfterCount.containsKey(tag)
          ? tagEvAfterSum[tag]! / tagEvAfterCount[tag]!
          : null;
      breakdown[tag] = TagSummary(
        total: tot,
        correct: corr,
        accuracy: acc,
        evBefore: before,
        evAfter: after,
      );
    }

    final trackAcc = total == 0 ? 0 : correct * 100 / total;
    final evBefore = evBeforeCount > 0 ? evBeforeSum / evBeforeCount : null;
    final evAfter = evAfterCount > 0 ? evAfterSum / evAfterCount : null;

    return TrainingTrackSummary(
      goalId: track.goalId,
      accuracy: trackAcc,
      mistakeCount: total - correct,
      evBefore: evBefore,
      evAfter: evAfter,
      tagBreakdown: breakdown,
    );
  }
}
