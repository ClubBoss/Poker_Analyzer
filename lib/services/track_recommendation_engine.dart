import '../models/skill_tree_build_result.dart';
import 'skill_tree_library_service.dart';

/// Provides next track recommendations after completing a track.
class TrackRecommendationEngine {
  final SkillTreeLibraryService library;

  TrackRecommendationEngine({SkillTreeLibraryService? library})
      : library = library ?? SkillTreeLibraryService.instance;

  static TrackRecommendationEngine instance = TrackRecommendationEngine();

  /// Returns the next recommended track after [trackId], or `null` if none.
  String? _getNextTrack(String trackId) {
    final tracks = library.getAllTracks();
    if (tracks.isEmpty) return null;
    final ids = tracks
        .map((SkillTreeBuildResult r) => r.tree.nodes.values.first.category)
        .toList()
      ..sort();
    final index = ids.indexOf(trackId);
    if (index == -1 || index + 1 >= ids.length) return null;
    return ids[index + 1];
  }

  /// Convenience static access.
  static String? getNextTrack(String trackId) =>
      instance._getNextTrack(trackId);
}
