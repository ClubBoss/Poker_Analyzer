import 'skill_tree_track_progress_service.dart';

/// Arranges skill tree tracks into a 2D grid layout for the learning map.
class SkillTreeLearningMapLayoutService {
  final SkillTreeTrackProgressService tracks;

  SkillTreeLearningMapLayoutService({SkillTreeTrackProgressService? tracks})
    : tracks = tracks ?? SkillTreeTrackProgressService();

  /// Returns a grid of [TrackProgressEntry] items laid out in [columns] per row.
  Future<List<List<TrackProgressEntry>>> buildLayout({int columns = 2}) async {
    if (columns <= 0) return [];
    final list = await tracks.getAllTrackProgress();
    if (list.isEmpty) return [];

    // Incomplete tracks first, then alphabetical by category.
    list.sort((a, b) {
      if (a.isCompleted != b.isCompleted) {
        return a.isCompleted ? 1 : -1;
      }
      final catA = a.tree.nodes.values.first.category;
      final catB = b.tree.nodes.values.first.category;
      return catA.compareTo(catB);
    });

    final grid = <List<TrackProgressEntry>>[];
    for (var i = 0; i < list.length; i += columns) {
      final end = i + columns < list.length ? i + columns : list.length;
      grid.add(list.sublist(i, end));
    }
    return grid;
  }
}
