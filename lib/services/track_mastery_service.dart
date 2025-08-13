import 'dart:math';

import '../models/v3/lesson_track.dart';
import 'lesson_loader_service.dart';
import 'learning_track_engine.dart';
import 'yaml_lesson_track_loader.dart';
import 'lesson_step_tag_service.dart';
import 'tag_mastery_service.dart';

class TrackMasteryService {
  final TagMasteryService mastery;
  final LessonStepTagProvider tagProvider;

  TrackMasteryService(
      {required this.mastery, LessonStepTagProvider? tagProvider})
      : tagProvider = tagProvider ?? LessonStepTagService.instance;

  static Map<String, double>? _cache;
  static DateTime _cacheTime = DateTime.fromMillisecondsSinceEpoch(0);

  Future<Map<String, double>> computeTrackMastery({bool force = false}) async {
    final now = DateTime.now();
    if (!force &&
        _cache != null &&
        now.difference(_cacheTime) < const Duration(hours: 6)) {
      return _cache!;
    }

    final builtIn = const LearningTrackEngine().getTracks();
    final yaml = await YamlLessonTrackLoader.instance.loadTracksFromAssets();
    final tracks = <LessonTrack>[...builtIn, ...yaml];

    await LessonLoaderService.instance.loadAllLessons();
    final tagsByStep = await tagProvider.getTagsByStepId();
    final tagSkill = await mastery.computeMastery();

    final raw = <String, double>{};
    for (final track in tracks) {
      final tags = <String>{};
      for (final id in track.stepIds) {
        final stepTags = tagsByStep[id] ?? const <String>[];
        tags.addAll(stepTags.map((t) => t.trim().toLowerCase()));
      }
      final values = [
        for (final tag in tags)
          if (tagSkill.containsKey(tag)) tagSkill[tag]!
      ];
      if (values.isEmpty) continue;
      final avg = values.reduce((a, b) => a + b) / values.length;
      raw[track.id] = avg.clamp(0.0, 1.0);
    }

    if (raw.isEmpty) {
      _cache = {};
      _cacheTime = now;
      return _cache!;
    }

    final values = raw.values.toList();
    final minVal = values.reduce(min);
    final maxVal = values.reduce(max);
    final normalized = <String, double>{};

    if (maxVal > minVal) {
      raw.forEach((k, v) {
        normalized[k] = (v - minVal) / (maxVal - minVal);
      });
    } else {
      for (final k in raw.keys) {
        normalized[k] = 1.0;
      }
    }

    _cache = normalized;
    _cacheTime = now;
    return normalized;
  }
}
