import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import 'services/auth_service.dart';
import 'services/remote_config_service.dart';
import 'services/ab_test_engine.dart';
import 'services/theme_service.dart';
import 'services/cloud_sync_service.dart';
import 'services/cloud_training_history_service.dart';
import 'services/training_spot_storage_service.dart';
import 'services/training_stats_service.dart';
import 'services/saved_hand_storage_service.dart';
import 'services/saved_hand_manager_service.dart';
import 'services/training_pack_suggestion_service.dart';
import 'services/player_progress_service.dart';
import 'services/player_style_service.dart';
import 'services/player_style_forecast_service.dart';
import 'services/real_time_stack_range_service.dart';
import 'services/progress_forecast_service.dart';
import 'services/mistake_review_pack_service.dart';
import 'services/dynamic_pack_adjustment_service.dart';
import 'services/mistake_streak_service.dart';
import 'services/session_note_service.dart';
import 'services/session_pin_service.dart';
import 'services/training_pack_storage_service.dart';
import 'services/training_pack_cloud_sync_service.dart';
import 'services/mistake_pack_cloud_service.dart';
import 'services/template_storage_service.dart';
import 'services/hand_analysis_history_service.dart';
import 'services/adaptive_training_service.dart';
import 'services/training_pack_template_storage_service.dart';
import 'services/favorite_pack_service.dart';
import 'services/pinned_pack_service.dart';
import 'services/category_usage_service.dart';
import 'services/daily_hand_service.dart';
import 'services/daily_target_service.dart';
import 'services/daily_tip_service.dart';
import 'services/xp_tracker_service.dart';
import 'services/reward_service.dart';
import 'services/goal_engine.dart';
import 'services/daily_challenge_service.dart';
import 'services/daily_spotlight_service.dart';
import 'services/daily_pack_service.dart';
import 'services/weekly_challenge_service.dart';
import 'services/streak_counter_service.dart';
import 'services/spot_of_the_day_service.dart';
import 'services/daily_goals_service.dart';
import 'services/all_in_players_service.dart';
import 'services/folded_players_service.dart';
import 'services/action_sync_service.dart';
import 'services/user_preferences_service.dart';
import 'services/tag_service.dart';
import 'services/tag_cache_service.dart';
import 'services/ignored_mistake_service.dart';
import 'services/goals_service.dart';
import 'services/streak_service.dart';
import 'services/achievement_service.dart';
import 'services/achievement_engine.dart';
import 'services/user_goal_engine.dart';
import 'services/personal_recommendation_service.dart';
import 'services/reminder_service.dart';
import 'services/daily_reminder_service.dart';
import 'services/next_step_engine.dart';
import 'services/drill_suggestion_engine.dart';
import 'services/weak_spot_recommendation_service.dart';
import 'services/daily_focus_recap_service.dart';
import 'services/feedback_service.dart';
import 'services/drill_history_service.dart';
import 'services/mixed_drill_history_service.dart';
import 'services/weekly_drill_stats_service.dart';
import 'services/training_pack_play_controller.dart';
import 'services/training_session_service.dart';
import 'services/session_manager.dart';
import 'services/session_log_service.dart';
import 'services/suggested_pack_service.dart';
import 'services/recommended_pack_service.dart';
import 'services/smart_suggestion_service.dart';
import 'services/training_gap_detector_service.dart';
import 'services/smart_suggestion_engine.dart';
import 'services/smart_pack_suggestion_engine.dart';
import 'services/evaluation_executor_service.dart';
import 'services/session_analysis_service.dart';
import 'services/user_action_logger.dart';
import 'services/hand_analyzer_service.dart';

late final AuthService auth;
late final RemoteConfigService rc;
late final AbTestEngine ab;
late final TrainingPackStorageService packStorage;
late final TrainingPackCloudSyncService packCloud;
late final MistakePackCloudService mistakeCloud;
late final GoalProgressCloudService goalCloud;
late final TrainingPackTemplateStorageService templateStorage;
late final TagCacheService tagCache;

List<SingleChildWidget> buildCoreProviders(CloudSyncService cloud) {
  return [
    ChangeNotifierProvider<AuthService>.value(value: auth),
    ChangeNotifierProvider<RemoteConfigService>.value(value: rc),
    ChangeNotifierProvider<AbTestEngine>.value(value: ab),
    ChangeNotifierProvider(create: (_) => ThemeService()..load()),
    Provider<CloudSyncService>.value(value: cloud),
  ];
}

List<SingleChildWidget> buildTrainingProviders() {
  return [
    Provider(create: (_) => CloudTrainingHistoryService()..init()),
    ChangeNotifierProvider(
      create: (context) => TrainingSpotStorageService(
        cloud: context.read<CloudSyncService>(),
      ),
    ),
    ChangeNotifierProvider(
      create: (context) =>
          TrainingStatsService(cloud: context.read<CloudSyncService>())..load(),
    ),
    ChangeNotifierProvider(
      create: (context) =>
          SavedHandStorageService(cloud: context.read<CloudSyncService>())
            ..load(),
    ),
    ChangeNotifierProvider(
      create: (context) => SavedHandManagerService(
        storage: context.read<SavedHandStorageService>(),
        cloud: context.read<CloudSyncService>(),
        stats: context.read<TrainingStatsService>(),
      ),
    ),
    ChangeNotifierProvider(
      create: (context) =>
          PlayerProgressService(hands: context.read<SavedHandManagerService>()),
    ),
    ChangeNotifierProvider(
      create: (context) =>
          PlayerStyleService(hands: context.read<SavedHandManagerService>()),
    ),
    ChangeNotifierProvider(
      create: (context) => PlayerStyleForecastService(
          hands: context.read<SavedHandManagerService>()),
    ),
    ChangeNotifierProvider(
      create: (context) => RealTimeStackRangeService(
        forecast: context.read<PlayerStyleForecastService>(),
      ),
    ),
    ChangeNotifierProvider(
      create: (context) => ProgressForecastService(
        hands: context.read<SavedHandManagerService>(),
        style: context.read<PlayerStyleService>(),
      ),
    ),
    ChangeNotifierProvider(
      create: (context) => MistakeReviewPackService(
        hands: context.read<SavedHandManagerService>(),
        cloud: mistakeCloud,
      )..load(),
    ),
    Provider(
      create: (context) => DynamicPackAdjustmentService(
        mistakes: context.read<MistakeReviewPackService>(),
        eval: EvaluationExecutorService(),
        hands: context.read<SavedHandManagerService>(),
        progress: context.read<PlayerProgressService>(),
        forecast: context.read<PlayerStyleForecastService>(),
        style: context.read<PlayerStyleService>(),
      ),
    ),
    ChangeNotifierProvider(
      create: (_) => MistakeStreakService()..load(),
    ),
    ChangeNotifierProvider(
        create: (context) =>
            SessionNoteService(cloud: context.read<CloudSyncService>())
              ..load()),
    ChangeNotifierProvider(
        create: (context) =>
            SessionPinService(cloud: context.read<CloudSyncService>())..load()),
    ChangeNotifierProvider<TrainingPackStorageService>.value(
      value: packStorage,
    ),
    Provider<TrainingPackCloudSyncService>.value(value: packCloud),
    Provider<MistakePackCloudService>.value(value: mistakeCloud),
    ChangeNotifierProvider(create: (_) => TemplateStorageService()..load()),
    ChangeNotifierProvider(create: (_) => HandAnalysisHistoryService()..load()),
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
    Provider<PinnedPackService>.value(value: PinnedPackService.instance),
    ChangeNotifierProvider(
      create: (context) => CategoryUsageService(
        templates: context.read<TemplateStorageService>(),
        packs: context.read<TrainingPackStorageService>(),
      ),
    ),
    ChangeNotifierProvider(create: (_) => DailyHandService()..load()),
    ChangeNotifierProvider(create: (_) => DailyTargetService()..load()),
    ChangeNotifierProvider(create: (_) => DailyTipService()..load()),
    ChangeNotifierProvider(
        create: (context) =>
            XPTrackerService(cloud: context.read<CloudSyncService>())..load()),
    ChangeNotifierProvider(create: (_) => RewardService()..load()),
    ChangeNotifierProvider(create: (_) => GoalEngine()),
    ChangeNotifierProvider(
      create: (context) => DailyChallengeService(
        adaptive: context.read<AdaptiveTrainingService>(),
        templates: context.read<TemplateStorageService>(),
        xp: context.read<XPTrackerService>(),
      )..load(),
    ),
    ChangeNotifierProvider(
      create: (context) => DailySpotlightService(
        templates: context.read<TemplateStorageService>(),
      )..load(),
    ),
    ChangeNotifierProvider(
      create: (context) => DailyPackService(
        templates: context.read<TemplateStorageService>(),
      )..load(),
    ),
    ChangeNotifierProvider(
      create: (context) => WeeklyChallengeService(
        stats: context.read<TrainingStatsService>(),
        xp: context.read<XPTrackerService>(),
        packs: context.read<TrainingPackStorageService>(),
      )..load(),
    ),
    ChangeNotifierProvider(
      create: (context) => StreakCounterService(
        stats: context.read<TrainingStatsService>(),
        target: context.read<DailyTargetService>(),
        xp: context.read<XPTrackerService>(),
      ),
    ),
    ChangeNotifierProvider(create: (_) => SpotOfTheDayService()..load()),
    ChangeNotifierProvider(
      create: (context) => DailyGoalsService(
        stats: context.read<TrainingStatsService>(),
        hands: context.read<SavedHandManagerService>(),
      )..load(),
    ),
    ChangeNotifierProvider(create: (_) => AllInPlayersService()),
    ChangeNotifierProvider(create: (_) => FoldedPlayersService()),
    ChangeNotifierProvider(
      create: (context) => ActionSyncService(
        foldedPlayers: context.read<FoldedPlayersService>(),
        allInPlayers: context.read<AllInPlayersService>(),
      ),
    ),
    ChangeNotifierProvider(
      create: (context) {
        final service = UserPreferencesService(
          cloud: context.read<CloudSyncService>(),
        );
        UserPreferences.init(service, context.read<ThemeService>());
        service.load();
        return service;
      },
    ),
    ChangeNotifierProvider(create: (_) => TagService()..load()),
    ChangeNotifierProvider<TagCacheService>.value(value: tagCache),
    ChangeNotifierProvider(create: (_) => IgnoredMistakeService()..load()),
    ChangeNotifierProvider(create: (_) => GoalsService()..load()),
    ChangeNotifierProvider(
      create: (context) => StreakService(
        cloud: context.read<CloudSyncService>(),
        xp: context.read<XPTrackerService>(),
      )..load(),
    ),
    ChangeNotifierProvider(
      create: (context) => AchievementService(
        stats: context.read<TrainingStatsService>(),
        hands: context.read<SavedHandManagerService>(),
        streak: context.read<StreakService>(),
        xp: context.read<XPTrackerService>(),
      ),
    ),
    ChangeNotifierProvider(
      create: (context) => AchievementEngine(
        stats: context.read<TrainingStatsService>(),
        goals: context.read<GoalsService>(),
      ),
    ),
    ChangeNotifierProvider(
      create: (context) =>
          UserGoalEngine(stats: context.read<TrainingStatsService>()),
    ),
    ChangeNotifierProvider(
      create: (context) => PersonalRecommendationService(
        achievements: context.read<AchievementEngine>(),
        adaptive: context.read<AdaptiveTrainingService>(),
        weak: context.read<WeakSpotRecommendationService>(),
        style: context.read<PlayerStyleService>(),
        forecast: context.read<PlayerStyleForecastService>(),
      ),
    ),
    ChangeNotifierProvider(
      create: (context) => ReminderService(
        context: context,
        spotService: context.read<SpotOfTheDayService>(),
        goalEngine: context.read<UserGoalEngine>(),
        streakService: context.read<StreakService>(),
      )..load(),
    ),
    ChangeNotifierProvider(
      create: (context) => DailyReminderService(
        spot: context.read<SpotOfTheDayService>(),
        target: context.read<DailyTargetService>(),
        stats: context.read<TrainingStatsService>(),
        goals: context.read<DailyGoalsService>(),
      )..load(),
    ),
    ChangeNotifierProvider(
      create: (context) => NextStepEngine(
        hands: context.read<SavedHandManagerService>(),
        goals: context.read<UserGoalEngine>(),
        streak: context.read<StreakService>(),
      ),
    ),
    ChangeNotifierProvider(
      create: (context) => DrillSuggestionEngine(
        hands: context.read<SavedHandManagerService>(),
        packs: context.read<TrainingPackStorageService>(),
      ),
    ),
    ChangeNotifierProvider(
      create: (context) => WeakSpotRecommendationService(
        hands: context.read<SavedHandManagerService>(),
        progress: context.read<PlayerProgressService>(),
      ),
    ),
    ChangeNotifierProvider(
      create: (context) => DailyFocusRecapService(
        hands: context.read<SavedHandManagerService>(),
        weak: context.read<WeakSpotRecommendationService>(),
      )..load(),
    ),
    ChangeNotifierProvider(
      create: (context) => FeedbackService(
        achievements: context.read<AchievementEngine>(),
        progress: context.read<PlayerProgressService>(),
        next: context.read<NextStepEngine>(),
      ),
    ),
    ChangeNotifierProvider(create: (_) => DrillHistoryService()..load()),
    ChangeNotifierProvider(
      create: (_) => MixedDrillHistoryService()..load(),
    ),
    ChangeNotifierProvider(
      create: (context) => WeeklyDrillStatsService(
        history: context.read<MixedDrillHistoryService>(),
      )..load(),
    ),
    Provider(create: (_) => const HandAnalyzerService()),
    ChangeNotifierProvider(
      create: (_) => TrainingPackPlayController()..load(),
    ),
    ChangeNotifierProvider(create: (_) => TrainingSessionService()..load()),
    Provider(
      create: (context) => SessionManager(
        hands: context.read<SavedHandManagerService>(),
        notes: context.read<SessionNoteService>(),
        sessions: context.read<TrainingSessionService>(),
      ),
    ),
    ChangeNotifierProvider(
      create: (context) => SessionLogService(
        sessions: context.read<TrainingSessionService>(),
        cloud: context.read<CloudSyncService>(),
      )..load(),
    ),
    ChangeNotifierProvider(
      create: (context) => SuggestedPackService(
        logs: context.read<SessionLogService>(),
        hands: context.read<SavedHandManagerService>(),
      )..load(),
    ),
    ChangeNotifierProvider(
      create: (context) => RecommendedPackService(
        hands: context.read<SavedHandManagerService>(),
      ),
    ),
    Provider(
      create: (context) => TrainingPackSuggestionService(
        history: context.read<SessionLogService>(),
      ),
    ),
    Provider(
      create: (context) => SmartSuggestionService(
        storage: context.read<TrainingPackStorageService>(),
        templates: context.read<TemplateStorageService>(),
      ),
    ),
    Provider(create: (_) => const TrainingGapDetectorService()),
    Provider(create: (_) => const SmartSuggestionEngine()),
    Provider(create: (_) => const SmartPackSuggestionEngine()),
  ];
}

List<SingleChildWidget> buildAnalyticsProviders() {
  return [
    Provider(create: (_) => EvaluationExecutorService()),
    Provider(
      create: (context) =>
          SessionAnalysisService(context.read<EvaluationExecutorService>()),
    ),
    ChangeNotifierProvider(create: (_) => UserActionLogger()..load()),
  ];
}

List<SingleChildWidget> buildAppProviders(CloudSyncService cloud) {
  return [
    ...buildCoreProviders(cloud),
    ...buildTrainingProviders(),
    ...buildAnalyticsProviders(),
  ];
}
