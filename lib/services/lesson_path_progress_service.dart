import 'package:shared_preferences/shared_preferences.dart';

import '../models/v3/lesson_track.dart';
import 'learning_track_engine.dart';
import 'lesson_progress_service.dart';
import 'lesson_progress_tracker_service.dart';
import 'yaml_lesson_track_loader.dart';

class LessonPathProgress {
  final int completed;
  final int total;
  final double percent;
  final List<String> completedIds;
  final List<String> remainingIds;

  LessonPathProgress({
    required this.completed,
    required this.total,
    required this.percent,
    required this.completedIds,
    required this.remainingIds,
  });
}

class LessonPathProgressService {
  LessonPathProgressService._();
  static final instance = LessonPathProgressService._();

  /// Returns all built-in lesson tracks.
  List<LessonTrack> getTracks() {
    return const LearningTrackEngine().getTracks();
  }

  /// Returns map of lessonId -> completed step ids.
  Future<Map<String, Set<String>>> getCompletedStepMap() async {
    await LessonProgressTrackerService.instance.load();
    final flat = await LessonProgressTrackerService.instance
        .getCompletedStepsFlat();
    return {'default': flat.keys.toSet()};
  }

  Future<LessonPathProgress> computeProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final trackId = prefs.getString('lesson_selected_track');
    if (trackId == null) {
      return LessonPathProgress(
        completed: 0,
        total: 0,
        percent: 0,
        completedIds: const [],
        remainingIds: const [],
      );
    }

    final track = const LearningTrackEngine().getTracks().firstWhere(
      (t) => t.id == trackId,
      orElse: () =>
          LessonTrack(id: '', title: '', description: '', stepIds: []),
    );

    final stepIds = track.stepIds;
    final completed = await LessonProgressService.instance.getCompletedSteps();
    final completedIds = [
      for (final id in stepIds)
        if (completed.contains(id)) id,
    ];
    final remainingIds = [
      for (final id in stepIds)
        if (!completed.contains(id)) id,
    ];
    final total = stepIds.length;
    final percent = total == 0 ? 0.0 : completedIds.length / total * 100;

    return LessonPathProgress(
      completed: completedIds.length,
      total: total,
      percent: percent,
      completedIds: completedIds,
      remainingIds: remainingIds,
    );
  }

  /// Computes completion percentage for all available lesson tracks.
  ///
  /// Returns a map of `trackId` to progress percentage (0-100).
  Future<Map<String, double>> computeTrackProgress() async {
    final builtIn = const LearningTrackEngine().getTracks();
    final yaml = await YamlLessonTrackLoader.instance.loadTracksFromAssets();
    final tracks = [...builtIn, ...yaml];
    final completed = await LessonProgressTrackerService.instance
        .getCompletedStepsFlat();

    final Map<String, double> progress = {};
    for (final track in tracks) {
      final ids = track.stepIds;
      if (ids.isEmpty) {
        progress[track.id] = 0;
        continue;
      }
      final doneCount = ids.where((id) => completed[id] == true).length;
      progress[track.id] = doneCount / ids.length * 100;
    }
    return progress;
  }
}
