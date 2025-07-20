import '../models/v3/lesson_track.dart';
import 'learning_track_engine.dart';
import 'track_mastery_service.dart';
import 'yaml_lesson_track_loader.dart';
import 'lesson_track_meta_service.dart';

/// Recommends lesson tracks based on mastery levels.
class LearningTrackRecommendationEngine {
  final TrackMasteryService masteryService;
  final LessonTrackMetaService metaService;
  final LearningTrackEngine trackEngine;
  final YamlLessonTrackLoader yamlLoader;

  const LearningTrackRecommendationEngine({
    required this.masteryService,
    LessonTrackMetaService? metaService,
    LearningTrackEngine trackEngine = const LearningTrackEngine(),
    YamlLessonTrackLoader? yamlLoader,
  })  : metaService = metaService ?? LessonTrackMetaService.instance,
        trackEngine = trackEngine,
        yamlLoader = yamlLoader ?? YamlLessonTrackLoader.instance;

  /// Returns up to [limit] recommended tracks sorted by lowest mastery.
  Future<List<LessonTrack>> getRecommendedTracks({int limit = 3}) async {
    final builtIn = trackEngine.getTracks();
    final yaml = await yamlLoader.loadTracksFromAssets();
    final tracks = <LessonTrack>[...builtIn, ...yaml];

    final mastery = await masteryService.computeTrackMastery();
    final entries = <MapEntry<LessonTrack, double>>[];
    for (final t in tracks) {
      entries.add(MapEntry(t, mastery[t.id] ?? 0.0));
    }
    entries.sort((a, b) => a.value.compareTo(b.value));

    final result = <LessonTrack>[];
    for (final e in entries) {
      final meta = await metaService.load(e.key.id);
      if (meta?.completedAt != null) continue;
      result.add(e.key);
      if (result.length >= limit) break;
    }
    return result;
  }

  /// Returns textual explanation for a recommendation.
  Future<String> getRecommendationReason(LessonTrack track) async {
    final mastery = await masteryService.computeTrackMastery();
    final value = mastery[track.id] ?? 0.0;
    final pct = (value * 100).round();
    return 'Mastery $pct%';
  }
}
