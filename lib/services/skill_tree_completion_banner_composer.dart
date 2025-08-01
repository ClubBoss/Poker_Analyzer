import '../models/skill_tree.dart';
import '../models/skill_tree_completion_banner_model.dart';
import 'skill_tree_category_banner_service.dart';
import 'skill_tree_track_progress_service.dart';
import 'skill_tree_track_summary_builder.dart';

/// Assembles final UI data for a completed skill tree track.
class SkillTreeCompletionBannerComposer {
  final SkillTreeTrackSummaryBuilder summaryBuilder;
  final SkillTreeCategoryBannerService bannerService;
  final SkillTreeTrackProgressService progressService;

  SkillTreeCompletionBannerComposer({
    SkillTreeTrackSummaryBuilder? summaryBuilder,
    SkillTreeCategoryBannerService? bannerService,
    SkillTreeTrackProgressService? progressService,
  })  : summaryBuilder = summaryBuilder ?? SkillTreeTrackSummaryBuilder(),
        bannerService = bannerService ?? const SkillTreeCategoryBannerService(),
        progressService = progressService ?? SkillTreeTrackProgressService();

  /// Builds the completion banner model for [tree].
  Future<SkillTreeCompletionBannerModel> compose(SkillTree tree) async {
    final summary = await summaryBuilder.build(tree);
    final visual = bannerService.getVisual(summary.title);
    final nextTrack = await progressService.getNextTrack();
    return SkillTreeCompletionBannerModel(
      visual: visual,
      summary: summary,
      nextTrack: nextTrack,
    );
  }
}
