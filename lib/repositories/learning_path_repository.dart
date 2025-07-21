import 'package:collection/collection.dart';

import '../models/learning_path_track_model.dart';
import '../models/learning_path_template_v2.dart';
import '../services/learning_path_registry_service.dart';
import '../services/learning_path_track_library_service.dart';

/// Provides helpers to load learning path tracks and their templates.
class LearningPathRepository {
  final LearningPathRegistryService registry;
  final LearningPathTrackLibraryService tracks;

  LearningPathRepository({
    LearningPathRegistryService? registry,
    LearningPathTrackLibraryService? trackLibrary,
  })  : registry = registry ?? LearningPathRegistryService.instance,
        tracks = trackLibrary ?? LearningPathTrackLibraryService.instance;

  /// Loads all tracks and their learning paths.
  Future<Map<LearningPathTrackModel, List<LearningPathTemplateV2>>>
      loadAllTracksWithPaths() async {
    await tracks.reload();
    final templates = await registry.loadAll();
    final result = <LearningPathTrackModel, List<LearningPathTemplateV2>>{};
    for (final track in tracks.tracks) {
      final list = <LearningPathTemplateV2>[];
      for (final id in track.pathIds) {
        final tpl = templates.firstWhereOrNull((t) => t.id == id);
        if (tpl != null) list.add(tpl);
      }
      result[track] = list;
    }
    return result;
  }
}
