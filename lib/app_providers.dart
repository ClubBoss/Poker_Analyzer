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
import 'services/saved_hand_stats_service.dart';
import 'services/saved_hand_export_service.dart';
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
import 'services/pack_favorite_service.dart';
import 'services/pack_rating_service.dart';
import 'services/pinned_pack_service.dart';
import 'services/category_usage_service.dart';
import 'services/daily_hand_service.dart';
import 'services/daily_target_service.dart';
import 'services/daily_tip_service.dart';
import 'services/xp_tracker_service.dart';
import 'widgets/player_zone_widget.dart';
import 'services/reward_service.dart';
import 'services/reward_system_service.dart';
import 'services/coins_service.dart';
import 'services/goal_engine.dart';
import 'services/daily_challenge_service.dart';
import 'services/daily_spotlight_service.dart';
import 'services/daily_pack_service.dart';
import 'services/weekly_challenge_service.dart';
import 'services/streak_counter_service.dart';
import 'services/spot_of_the_day_service.dart';
import 'services/daily_goals_service.dart';
import 'services/daily_learning_goal_service.dart';
import 'services/all_in_players_service.dart';
import 'services/folded_players_service.dart';
import 'services/action_sync_service.dart';
import 'services/user_preferences_service.dart';
import 'services/tag_service.dart';
import 'services/tag_cache_service.dart';
import 'services/training_pack_tag_analytics_service.dart';
import 'services/ignored_mistake_service.dart';
import 'services/goals_service.dart';
import 'services/streak_service.dart';
import 'services/streak_tracker_service.dart';
import 'services/achievement_service.dart';
import 'services/achievement_engine.dart';
import 'services/achievements_engine.dart';
import 'services/user_goal_engine.dart';
import 'services/goal_toast_service.dart';
import 'services/personal_recommendation_service.dart';
import 'services/reminder_service.dart';
import 'services/daily_reminder_service.dart';
import 'services/streak_reminder_service.dart';
import 'services/next_step_engine.dart';
import 'services/drill_suggestion_engine.dart';
import 'services/weak_spot_recommendation_service.dart';
import 'services/daily_focus_recap_service.dart';
import 'services/daily_focus_service.dart';
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
import 'services/suggestion_banner_engine.dart';
import 'services/suggested_next_pack_engine.dart';
import 'services/smart_review_service.dart';
import 'services/evaluation_executor_service.dart';
import 'services/session_analysis_service.dart';
import 'services/user_action_logger.dart';
import 'services/hand_analyzer_service.dart';
import 'services/tag_mastery_service.dart';
import 'services/tag_retention_tracker.dart';
import 'services/decay_tag_retention_tracker_service.dart';
import 'services/goal_suggestion_engine.dart';
import 'services/goal_sync_service.dart';
import 'services/tag_coverage_service.dart';
import 'services/recap_opportunity_detector.dart';
import 'services/tag_mastery_history_service.dart';
import 'services/tag_insight_reminder_engine.dart';
import 'services/learning_path_prefs.dart';
import 'services/scheduled_training_queue_service.dart';
import 'services/auto_recovery_trigger_service.dart';
import 'services/scheduled_training_launcher.dart';
import 'services/daily_training_reminder_service.dart';
import 'services/goal_reengagement_service.dart';
import 'services/smart_push_scheduler_service.dart';
import 'services/lesson_progress_tracker_service.dart';
import 'services/lesson_path_progress_service.dart';
import 'services/training_path_progress_service.dart';
import 'services/learning_path_registry_service.dart';
import 'services/learning_path_summary_cache.dart';
import 'services/learning_path_reminder_engine.dart';
import 'services/daily_app_check_service.dart';
import 'services/skill_loss_overlay_prompt_service.dart';
import 'services/gift_drop_service.dart';
import 'services/decay_badge_banner_controller.dart';
import 'services/session_streak_overlay_prompt_service.dart';
import 'services/decay_streak_overlay_prompt_service.dart';
import 'services/overlay_decay_booster_orchestrator.dart';
import 'services/smart_recap_auto_injector.dart';
import 'services/smart_recap_banner_controller.dart';
import 'services/theory_inbox_banner_controller.dart';
import 'services/smart_recap_banner_reinjection_service.dart';
import 'services/recap_to_drill_launcher.dart';
import 'services/smart_booster_unlock_scheduler.dart';
import 'services/overlay_booster_manager.dart';
import 'services/booster_exhaustion_overlay_manager.dart';
import 'services/theory_recall_overlay_scheduler.dart';
import 'services/theory_recall_inbox_reinjection_service.dart';
import 'services/booster_recall_banner_engine.dart';
import 'services/adaptive_next_step_engine.dart';
import 'services/suggested_next_step_engine.dart';

late final AuthService auth;
late final RemoteConfigService rc;
late final AbTestEngine ab;
late final TrainingPackStorageService packStorage;
late final TrainingPackCloudSyncService packCloud;
late final MistakePackCloudService mistakeCloud;
late final GoalProgressCloudService goalCloud;
late final GoalSyncService goalSync;
late final TrainingPackTemplateStorageService templateStorage;
late final TagCacheService tagCache;

List<SingleChildWidget> buildCoreProviders(CloudSyncService cloud) {
  return [
    ChangeNotifierProvider<AuthService>.value(value: auth),
    ChangeNotifierProvider<RemoteConfigService>.value(value: rc),
    ChangeNotifierProvider<AbTestEngine>.value(value: ab),
    ChangeNotifierProvider(create: (_) => ThemeService()..load()),
    Provider<CloudSyncService>.value(value: cloud),
    Provider(create: (_) => PlayerZoneRegistry()),
  ];
}

List<SingleChildWidget> buildTrainingProviders() {
  return [
    Provider(create: (_) => CloudTrainingHistoryService()..init()),
    ChangeNotifierProvider(
      create: (context) =>
          TrainingSpotStorageService(cloud: context.read<CloudSyncService>()),
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
      create: (context) => SavedHandStatsService(
        manager: context.read<SavedHandManagerService>(),
      ),
    ),
    Provider(
      create: (context) => SavedHandExportService(
        manager: context.read<SavedHandManagerService>(),
        stats: context.read<SavedHandStatsService>(),
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
        hands: context.read<SavedHandManagerService>(),
      ),
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
    ChangeNotifierProvider(create: (_) => MistakeStreakService()..load()),
    ChangeNotifierProvider(
      create: (context) =>
          SessionNoteService(cloud: context.read<CloudSyncService>())..load(),
    ),
    ChangeNotifierProvider(
      create: (context) =>
          SessionPinService(cloud: context.read<CloudSyncService>())..load(),
    ),
    ChangeNotifierProvider<TrainingPackStorageService>.value(
      value: packStorage,
    ),
    Provider<TrainingPackCloudSyncService>.value(value: packCloud),
    Provider<MistakePackCloudService>.value(value: mistakeCloud),
    Provider<GoalSyncService>.value(value: goalSync),
    ChangeNotifierProvider(create: (_) => TemplateStorageService()..load()),
    ChangeNotifierProvider(create: (_) => HandAnalysisHistoryService()..load()),
    Provider(create: (_) => SmartReviewService.instance..load()),
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
    ChangeNotifierProvider(create: (_) => DailyHandService()..load()),
    ChangeNotifierProvider(create: (_) => DailyTargetService()..load()),
    ChangeNotifierProvider(create: (_) => DailyTipService()..load()),
    ChangeNotifierProvider(
      create: (context) =>
          XPTrackerService(cloud: context.read<CloudSyncService>())..load(),
    ),
    ChangeNotifierProvider(create: (_) => RewardService()..load()),
    ChangeNotifierProvider(create: (_) => RewardSystemService()..load()),
    ChangeNotifierProvider(create: (_) => CoinsService()..load()),
    ChangeNotifierProvider(create: (_) => GoalEngine.instance),
    ChangeNotifierProvider(create: (_) => DailyChallengeService()),
    ChangeNotifierProvider(
      create: (context) => DailySpotlightService(
        templates: context.read<TemplateStorageService>(),
      )..load(),
    ),
    ChangeNotifierProvider(
      create: (context) =>
          DailyPackService(templates: context.read<TemplateStorageService>())
            ..load(),
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
    ChangeNotifierProvider(create: (_) => DailyLearningGoalService()..load()),
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
    ChangeNotifierProvider(
      create: (_) => TrainingPackTagAnalyticsService()..loadStats(),
    ),
    ChangeNotifierProvider(create: (_) => IgnoredMistakeService()..load()),
    ChangeNotifierProvider(create: (_) => GoalsService()..load()),
    ChangeNotifierProvider(
      create: (context) => StreakService(
        cloud: context.read<CloudSyncService>(),
        xp: context.read<XPTrackerService>(),
      )..load(),
    ),
    Provider(create: (_) => StreakTrackerService()),
    ChangeNotifierProvider(
      create: (context) => AchievementService(
        stats: context.read<TrainingStatsService>(),
        hands: context.read<SavedHandManagerService>(),
        streak: context.read<StreakService>(),
        dailyGoal: context.read<DailyLearningGoalService>(),
        mastery: context.read<TagMasteryService>(),
        xp: context.read<XPTrackerService>(),
      ),
    ),
    ChangeNotifierProvider(
      create: (context) => AchievementsEngine(
        xp: context.read<XPTrackerService>(),
        stats: context.read<TrainingStatsService>(),
        streak: context.read<StreakTrackerService>(),
      ),
    ),
    ChangeNotifierProvider(
      create: (context) => AchievementEngine(
        stats: context.read<TrainingStatsService>(),
        goals: context.read<GoalsService>(),
      ),
    ),
    ChangeNotifierProvider(
      create: (context) => UserGoalEngine(
        stats: context.read<TrainingStatsService>(),
        sync: goalSync,
      ),
    ),
    Provider(create: (_) => GoalToastService()),
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
      create: (context) => StreakReminderService(
        logs: context.read<SessionLogService>(),
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
      create: (context) => DailyFocusService(
        mastery: context.read<TagMasteryService>(),
        streak: context.read<StreakService>(),
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
    ChangeNotifierProvider(create: (_) => MixedDrillHistoryService()..load()),
    ChangeNotifierProvider(
      create: (context) => WeeklyDrillStatsService(
        history: context.read<MixedDrillHistoryService>(),
      )..load(),
    ),
    Provider(create: (_) => const HandAnalyzerService()),
    ChangeNotifierProvider(create: (_) => TrainingPackPlayController()..load()),
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
        stats: context.read<SavedHandStatsService>(),
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
    Provider(
      create: (context) =>
          SmartSuggestionEngine(logs: context.read<SessionLogService>()),
    ),
    Provider(
      create: (context) => SuggestionBannerEngine(
        logs: context.read<SessionLogService>(),
      ),
    ),
    Provider(create: (_) => BoosterRecallBannerEngine()),
    Provider(
      create: (context) =>
          TagMasteryService(logs: context.read<SessionLogService>()),
    ),
    Provider(
      create: (context) =>
          TagRetentionTracker(mastery: context.read<TagMasteryService>()),
    ),
    Provider(create: (_) => const DecayTagRetentionTrackerService()),
    Provider(create: (_) => LearningPathPrefs()..load()),
    Provider(create: (_) => TagCoverageService()),
    Provider(create: (_) => TagMasteryHistoryService()),
    Provider(
      create: (context) => SkillTagDecayTracker(
        logs: context.read<SessionLogService>(),
        history: context.read<TagMasteryHistoryService>(),
      ),
    ),
    Provider(
      create: (context) =>
          RecapTagAnalyticsService(logs: context.read<SessionLogService>()),
    ),
    Provider(
      create: (context) => TagInsightReminderEngine(
        history: context.read<TagMasteryHistoryService>(),
      ),
    ),
    ChangeNotifierProvider<ScheduledTrainingQueueService>.value(
      value: ScheduledTrainingQueueService.instance..load(),
    ),
    Provider(
      create: (context) => AutoRecoveryTriggerService(
        reminder: context.read<TagInsightReminderEngine>(),
        queue: ScheduledTrainingQueueService.instance,
      )..run(),
    ),
    Provider(create: (_) => const ScheduledTrainingLauncher()),
    Provider(create: (_) => DailyTrainingReminderService()),
    Provider(
      create: (context) => GoalReengagementService(
        logs: context.read<SessionLogService>(),
      ),
    ),
    Provider(
      create: (context) => SmartPushSchedulerService(
        reengagement: context.read<GoalReengagementService>(),
        reminder: context.read<DailyTrainingReminderService>(),
      ),
    ),
    Provider(
      create: (context) => GoalSuggestionEngine(
        mastery: context.read<TagMasteryService>(),
        logs: context.read<SessionLogService>(),
      ),
    ),
    Provider(create: (_) => LessonProgressTrackerService()..load()),
    Provider(create: (_) => LessonPathProgressService()),
    Provider(create: (_) => TrainingPathProgressService()),
    Provider<LearningPathRegistryService>.value(
      value: LearningPathRegistryService.instance,
    ),
    Provider(
      create: (context) => LearningPathSummaryCache(
        path: context.read<TrainingPathProgressService>(),
        mastery: context.read<TagMasteryService>(),
      )..refresh(),
    ),
    Provider(create: (_) => AdaptiveNextStepEngine()),
    Provider(create: (_) => const SmartPackSuggestionEngine()),
    Provider(
      create: (context) => SuggestedNextPackEngine(
        mastery: context.read<TagMasteryService>(),
      ),
    ),
    Provider(
      create: (context) => SuggestedNextStepEngine(
        path: context.read<TrainingPathProgressService>(),
        mastery: context.read<TagMasteryService>(),
        storage: context.read<TemplateStorageService>(),
      ),
    ),
    Provider(
      create: (context) => LearningPathReminderEngine(
        cache: context.read<LearningPathSummaryCache>(),
      ),
    ),
    Provider(
      create: (context) => DailyAppCheckService(
        reminder: context.read<LearningPathReminderEngine>(),
      ),
    ),
    Provider(
      create: (context) => SkillLossOverlayPromptService(
        logs: context.read<SessionLogService>(),
      ),
    ),
    ChangeNotifierProvider(
      create: (_) => TheoryInboxBannerController()..start(),
    ),
    Provider(create: (_) => GiftDropService()),
    Provider(create: (_) => DecayBadgeBannerController()..start()),
    Provider(create: (_) => SessionStreakOverlayPromptService()),
    Provider(create: (_) => DecayStreakOverlayPromptService()),
    Provider(create: (_) => OverlayDecayBoosterOrchestrator()),
    Provider(
      create: (context) => RecapOpportunityDetector(
        retention: context.read<TagRetentionTracker>(),
      )..start(),
    ),
    ChangeNotifierProvider(
      create: (context) => SmartRecapBannerController(
        sessions: context.read<TrainingSessionService>(),
      )..start(),
    ),
    Provider(
      create: (context) => SmartRecapScheduler(
        decay: context.read<SkillTagDecayTracker>(),
        analytics: context.read<RecapTagAnalyticsService>(),
        controller: context.read<SmartRecapBannerController>(),
      )..start(),
    ),
    Provider(
      create: (_) => SmartRecapAutoInjector()..start(),
    ),
    Provider(
      create: (context) => SmartRecapBannerReinjectionService(
        controller: context.read<SmartRecapBannerController>(),
      )..start(),
    ),
    Provider(
      create: (context) => SmartBoosterUnlockScheduler(
        sessions: context.read<TrainingSessionService>(),
      )..start(),
    ),
    Provider(
      create: (context) => RecapToDrillLauncher(
        banner: context.read<SmartRecapBannerController>(),
        sessions: context.read<TrainingSessionService>(),
      ),
    ),
    Provider(
      create: (_) => OverlayBoosterManager()..start(),
    ),
    Provider(
      create: (_) => BoosterExhaustionOverlayManager()..start(),
    ),
    Provider(
      create: (_) => TheoryRecallOverlayScheduler()..start(),
    ),
    Provider(
      create: (_) => TheoryRecallInboxReinjectionService()..start(),
    ),
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
