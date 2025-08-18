import 'package:flutter/services.dart' show rootBundle;

import '../asset_manifest.dart';
import '../core/training/generation/yaml_reader.dart';
import '../models/v3/lesson_track.dart';
import '../models/v3/track_unlock_condition.dart';
import 'lesson_loader_service.dart';

class YamlLessonTrackLoader {
  YamlLessonTrackLoader._();
  static final instance = YamlLessonTrackLoader._();

  static const _dir = 'assets/lesson_tracks/';

  Future<List<LessonTrack>> loadTracksFromAssets() async {
    final manifest = await AssetManifest.instance;
    final paths = manifest.keys
        .where((p) => p.startsWith(_dir) && p.endsWith('.yaml'))
        .toList();
    final lessons = await LessonLoaderService.instance.loadAllLessons();
    final ids = {for (final s in lessons) s.id};
    final tracks = <LessonTrack>[];
    for (final path in paths) {
      try {
        final raw = await rootBundle.loadString(path);
        final map = const YamlReader().read(raw);
        final meta = map['meta'] as Map?;
        final schema = meta?['track_schema']?.toString() ?? '1.0.0';
        if (schema != '1.0.0') continue;
        final stepList = map['stepIds'];
        if (stepList is! List) continue;
        final steps = [for (final v in stepList) v.toString()];
        if (steps.any((id) => !ids.contains(id))) continue;
        final id = map['id']?.toString() ?? '';
        final title = map['title']?.toString() ?? '';
        final desc = map['description']?.toString() ?? '';
        TrackUnlockCondition? condition;
        final condYaml = map['unlockCondition'];
        if (condYaml is Map) {
          condition = TrackUnlockCondition.fromYaml(
            Map<String, dynamic>.from(condYaml),
          );
        }
        if (id.isEmpty || title.isEmpty) continue;
        tracks.add(
          LessonTrack(
            id: id,
            title: title,
            description: desc,
            stepIds: steps,
            unlockCondition: condition,
          ),
        );
      } catch (_) {}
    }
    return tracks;
  }
}
