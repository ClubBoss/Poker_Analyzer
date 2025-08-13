import 'package:collection/collection.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/v3/lesson_step.dart';
import '../models/v3/lesson_track.dart';
import 'lesson_progress_tracker_service.dart';
import 'learning_track_engine.dart';
import 'lesson_loader_service.dart';
import 'lesson_step_tag_service.dart';
import 'tag_coverage_service.dart';

class AdaptiveNextStepEngine {
  final LessonProgressTrackerService progress;
  final LearningTrackEngine trackEngine;
  final LessonLoaderService loader;
  final LessonStepTagProvider tagProvider;
  final TagCoverageService coverageService;
  final List<LessonStep>? _stepsOverride;
  final List<LessonTrack>? _tracksOverride;

  AdaptiveNextStepEngine({
    LessonProgressTrackerService? progress,
    LearningTrackEngine trackEngine = const LearningTrackEngine(),
    LessonLoaderService? loader,
    LessonStepTagProvider? tagProvider,
    TagCoverageService? coverage,
    List<LessonStep>? steps,
    List<LessonTrack>? tracks,
  })  : progress = progress ?? LessonProgressTrackerService.instance,
        trackEngine = trackEngine,
        loader = loader ?? LessonLoaderService.instance,
        tagProvider = tagProvider ?? LessonStepTagService.instance,
        coverageService = coverage ??
            TagCoverageService(
                provider: tagProvider ?? LessonStepTagService.instance),
        _stepsOverride = steps,
        _tracksOverride = tracks;

  static const _recentKey = 'lesson_recent_steps';

  Future<List<LessonStep>> _loadSteps() async {
    return _stepsOverride ?? await loader.loadAllLessons();
  }

  List<LessonTrack> _loadTracks() {
    return _tracksOverride ?? trackEngine.getTracks();
  }

  Future<String?> suggestNextStep() async {
    final completed = await progress.getCompletedSteps();
    final steps = await _loadSteps();
    final tagsByStep = await tagProvider.getTagsByStepId();
    final coverage = await coverageService.computeTagCoverage();

    final prefs = await SharedPreferences.getInstance();
    final trackId = prefs.getString('lesson_selected_track');
    final trackSteps = <String>{};
    if (trackId != null) {
      final track = _loadTracks().firstWhereOrNull((t) => t.id == trackId);
      if (track != null) trackSteps.addAll(track.stepIds);
    }

    final recent = prefs.getStringList(_recentKey) ?? <String>[];
    final recentSet = recent.toSet();

    String? bestId;
    double bestScore = double.negativeInfinity;

    for (final step in steps) {
      if (completed[step.id] == true) continue;
      final tags = tagsByStep[step.id] ?? const <String>[];
      if (tags.isEmpty) continue;
      if (recentSet.contains(step.id)) continue;

      double score = 0;
      for (final tag in tags) {
        final c = coverage[tag] ?? 0;
        score -= c.toDouble();
      }
      if (trackSteps.contains(step.id)) score += 1000;
      if (score > bestScore) {
        bestScore = score;
        bestId = step.id;
      }
    }

    if (bestId != null) {
      recent.add(bestId);
      while (recent.length > 5) {
        recent.removeAt(0);
      }
      await prefs.setStringList(_recentKey, recent);
    }

    return bestId;
  }
}
