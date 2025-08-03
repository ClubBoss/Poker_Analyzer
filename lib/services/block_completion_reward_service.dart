import 'learning_path_progress_service.dart';
import 'package:poker_analyzer/services/preferences_service.dart';

class BlockCompletionRewardService {
  BlockCompletionRewardService._();
  static final instance = BlockCompletionRewardService._();

  static String _completedKey(String title) =>
      'stage_completed_${title.toLowerCase()}';
  static String _bannerKey(String title) =>
      'stage_banner_${title.toLowerCase()}';

  Future<bool> isStageCompleted(String stageTitle) async {
    final stages =
        await LearningPathProgressService.instance.getCurrentStageState();
    final stage = stages.firstWhere(
      (s) => s.title.toLowerCase() == stageTitle.toLowerCase(),
      orElse: () => null,
    );
    final completed =
        stage.items.every((i) => i.status == LearningItemStatus.completed);
    if (!completed) return false;
    final prefs = await PreferencesService.getInstance();
    await prefs.setBool(_completedKey(stageTitle), true);
    return !(prefs.getBool(_bannerKey(stageTitle)) ?? false);
  }

  Future<void> markBannerShown(String stageTitle) async {
    final prefs = await PreferencesService.getInstance();
    await prefs.setBool(_bannerKey(stageTitle), true);
  }
}
