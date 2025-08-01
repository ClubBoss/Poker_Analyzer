import '../services/skill_tree_track_progress_service.dart';
import 'skill_tree_category_visual.dart';
import 'skill_tree_track_summary.dart';

/// Combined data for a skill tree completion banner.
class SkillTreeCompletionBannerModel {
  final SkillTreeCategoryVisual visual;
  final SkillTreeTrackSummary summary;
  final TrackProgressEntry? nextTrack;

  const SkillTreeCompletionBannerModel({
    required this.visual,
    required this.summary,
    required this.nextTrack,
  });
}
