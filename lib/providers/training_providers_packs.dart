import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../services/training_pack_storage_service.dart';
import '../services/training_pack_cloud_sync_service.dart';
import '../services/mistake_pack_cloud_service.dart';
import '../services/goal_sync_service.dart';
import '../services/template_storage_service.dart';
import '../services/hand_analysis_history_service.dart';
import '../services/smart_review_service.dart';
import '../services/adaptive_training_service.dart';
import '../services/mistake_review_pack_service.dart';
import '../services/saved_hand_manager_service.dart';
import '../services/xp_tracker_service.dart';
import '../services/progress_forecast_service.dart';
import '../services/player_style_service.dart';
import '../services/player_style_forecast_service.dart';
import '../services/training_pack_template_storage_service.dart';
import '../services/favorite_pack_service.dart';
import '../services/pack_favorite_service.dart';
import '../services/pack_rating_service.dart';
import '../services/pinned_pack_service.dart';
import '../services/category_usage_service.dart';
import 'provider_globals.dart';

/// Providers supporting training pack features.
List<SingleChildWidget> buildTrainingPackProviders() {
  return [
    ChangeNotifierProvider<TrainingPackStorageService>.value(
      value: packStorage,
    ),
    Provider<TrainingPackCloudSyncService>.value(value: packCloud),
    Provider<MistakePackCloudService>.value(value: mistakeCloud),
    Provider<GoalSyncService>.value(value: goalSync),
    ChangeNotifierProvider(create: (_) => TemplateStorageService()..init()),
    ChangeNotifierProvider(create: (_) => HandAnalysisHistoryService()..init()),
    Provider(create: (_) => SmartReviewService.instance..init()),
    ChangeNotifierProvider(
      create: (context) => AdaptiveTrainingService(
        templates: context.read<TemplateStorageService>(),
        mistakes: context.read<MistakeReviewPackService>(),
        hands: context.read<SavedHandManagerService>(),
        history: context.read<HandAnalysisHistoryService>(),
        xp: context.read<XPTrackerService>(),
        forecast: context.read<ProgressForecastService>(),
        style: context.read<PlayerStyleService>(),
        styleForecast: context.read<PlayerStyleForecastService>(),
      ),
    ),
    ChangeNotifierProvider<TrainingPackTemplateStorageService>.value(
      value: templateStorage,
    ),
    Provider<FavoritePackService>.value(value: FavoritePackService.instance),
    Provider<PackFavoriteService>.value(value: PackFavoriteService.instance),
    Provider<PackRatingService>.value(value: PackRatingService.instance),
    Provider<PinnedPackService>.value(value: PinnedPackService.instance),
    ChangeNotifierProvider(
      create: (context) => CategoryUsageService(
        templates: context.read<TemplateStorageService>(),
        packs: context.read<TrainingPackStorageService>(),
      ),
    ),
  ];
}
