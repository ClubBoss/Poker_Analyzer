import '../models/skill_tree_completion_badge.dart';
import 'skill_tree_library_service.dart';
import 'skill_tree_track_progress_service.dart';

/// Provides completion badge data for skill tree tracks.
class SkillTreeCompletionBadgeService {
  final SkillTreeTrackProgressService progressService;
  final SkillTreeLibraryService libraryService;

  SkillTreeCompletionBadgeService({
    SkillTreeTrackProgressService? progressService,
    SkillTreeLibraryService? libraryService,
  }) : progressService = progressService ?? SkillTreeTrackProgressService(),
       libraryService = libraryService ?? SkillTreeLibraryService.instance;

  /// Returns completion badges for all skill tree tracks.
  Future<List<SkillTreeCompletionBadge>> getBadges() async {
    if (libraryService.getAllTracks().isEmpty) {
      await libraryService.reload();
    }
    final tracks = libraryService.getAllTracks();
    final result = <SkillTreeCompletionBadge>[];
    for (final t in tracks) {
      final trackId = t.tree.nodes.values.first.category;
      final nodes = t.tree.nodes.values
          .where((n) => (n as dynamic).isOptional != true)
          .toList();
      final completed = await progressService.getCompletedNodeIds(trackId);
      final done = completed.length;
      final total = nodes.length;
      final percent = total > 0 ? done / total : 0.0;
      final complete = done >= total && total > 0;
      result.add(
        SkillTreeCompletionBadge(
          trackId: trackId,
          percentComplete: percent,
          isComplete: complete,
        ),
      );
    }
    return result;
  }
}
