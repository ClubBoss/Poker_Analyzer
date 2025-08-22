import '../models/v3/lesson_step.dart';
import '../models/v3/lesson_track.dart';
import '../models/mistake_profile.dart';

class LearningPathAdvisor {
  final List<LessonStep> steps;

  LearningPathAdvisor({required this.steps});

  LessonStep? recommendNextStep({
    required List<LessonTrack> availableTracks,
    required Map<String, Set<String>> completedSteps,
    required MistakeProfile profile,
  }) {
    final stepMap = {for (final s in steps) s.id: s};
    final done = <String>{};
    for (final set in completedSteps.values) {
      done.addAll(set);
    }

    LessonStep? best;
    double bestScore = double.negativeInfinity;

    for (final track in availableTracks) {
      final ids = track.stepIds;
      final started = ids.any(done.contains);
      final finished = ids.every(done.contains);

      for (final id in ids) {
        if (done.contains(id)) continue;
        final step = stepMap[id];
        if (step == null) continue;

        double score = 0;
        if (started && !finished) score += 2;
        final tags =
            (step.meta['tags'] as List?)?.map((e) => e.toString()).toSet() ??
            const <String>{};
        for (final tag in tags) {
          if (profile.weakTags.contains(tag)) score += 1;
        }
        if (score > bestScore) {
          bestScore = score;
          best = step;
        }
      }
    }

    return best;
  }
}
