import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:url_launcher/url_launcher.dart';
import '../helpers/category_translations.dart';
import '../models/v2/training_pack_template.dart';
import '../services/training_session_service.dart';
import '../services/template_storage_service.dart';
import '../services/training_pack_stats_service.dart';
import '../services/adaptive_training_service.dart';
import '../services/mistake_review_pack_service.dart';
import '../services/dynamic_pack_adjustment_service.dart';
import 'training_session_screen.dart';
import '../services/weak_spot_recommendation_service.dart';
import '../services/daily_spotlight_service.dart';

import '../widgets/booster_suggestion_block.dart';
import '../widgets/theory_booster_suggestion_block.dart';

import '../services/spot_of_the_day_service.dart';
import '../widgets/spot_of_the_day_card.dart';
import '../widgets/streak_chart.dart';
import '../widgets/daily_goals_card.dart';
import '../widgets/daily_progress_ring.dart';
import '../widgets/goals_card.dart';
import '../widgets/goal_dashboard_widget.dart';
import '../widgets/repeat_mistakes_card.dart';
import '../widgets/weekly_challenge_card.dart';
import '../widgets/daily_challenge_card.dart';
import '../widgets/xp_progress_bar.dart';
import '../widgets/quick_continue_card.dart';
import '../widgets/resume_training_card.dart';
import '../widgets/resume_lesson_card.dart';
import '../widgets/next_learning_step_card.dart';
import '../widgets/pinned_learning_section.dart';
import '../widgets/pinned_top_pick_card.dart';
import '../widgets/next_up_banner.dart';
import '../widgets/smart_recap_preview_widget.dart';
import '../widgets/theory_inbox_banner.dart';
import '../widgets/training_recommender_banner.dart';
import '../widgets/leak_insight_banner.dart';
import '../widgets/theory_lesson_progress_widget.dart';
import '../widgets/daily_focus_recap_card.dart';
import '../widgets/daily_focus_card.dart';
import '../widgets/progress_summary_box.dart';
import '../widgets/progress_summary_card.dart';
import '../widgets/starter_path_card.dart';
import '../widgets/position_progress_card.dart';
import '../widgets/progress_forecast_card.dart';
import '../widgets/player_style_card.dart';
import '../widgets/skill_progress_card.dart';
import '../widgets/training_progress_card.dart';
import '../widgets/booster_progress_card.dart';
import '../widgets/recommended_drill_tile.dart';
import '../widgets/tag_progress_history_card.dart';
import '../widgets/weak_area_spotlight_block.dart';
import '../widgets/refresh_skills_block.dart';
import '../widgets/track_unlock_preview_card.dart';
import '../widgets/recommended_next_pack_card.dart';
import '../widgets/adaptive_theory_reminder_banner.dart';
import '../widgets/review_past_mistakes_card.dart';
import '../widgets/weak_spot_card.dart';
import '../widgets/achievements_card.dart';
import '../widgets/daily_spotlight_card.dart';
import '../widgets/streak_banner_widget.dart';
import '../widgets/streak_analytics_card.dart';
import '../widgets/decay_memory_health_banner.dart';
import 'booster_library_screen.dart';
import 'booster_archive_screen.dart';
import 'training_progress_analytics_screen.dart';
import 'training_recommendation_screen.dart';
import '../helpers/training_onboarding.dart';
import '../widgets/sync_status_widget.dart';
import '../tutorial/tutorial_flow.dart';
import '../widgets/suggestion_card_weak_spots.dart';
import '../widgets/tag_progress_card.dart';
import '../widgets/weekly_summary_card.dart';
import '../widgets/continue_learning_card.dart';

class TrainingHomeScreen extends StatefulWidget {
  final TutorialFlow? tutorial;
  static final GlobalKey recommendationsKey = GlobalKey();
  const TrainingHomeScreen({super.key, this.tutorial});

  @override
  State<TrainingHomeScreen> createState() => _TrainingHomeScreenState();
}

class _TrainingHomeScreenState extends State<TrainingHomeScreen> {
  @override
  void initState() {
    super.initState();
    context.read<SpotOfTheDayService>().ensureTodaySpot();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => widget.tutorial?.showCurrentStep(context),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final narrow = width < 400;
    final tablet = width >= 600;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Training'),
        actions: [
          SyncStatusIcon.of(context),
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const TrainingProgressAnalyticsScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.star),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const TrainingRecommendationScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.local_fire_department),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BoosterLibraryScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BoosterArchiveScreen()),
              );
            },
          ),
        ],
      ),
      body: ListView(
        children: [
          const StarterPathCard(),
          const NextUpBanner(),
          const SmartRecapPreviewWidget(),
          const TheoryInboxBanner(),
          const LeakInsightBanner(),
          const TrainingRecommenderBanner(),
          TheoryLessonProgressWidget(),
          const TrackUnlockPreviewCard(),
          const RecommendedNextPackCard(),
          const AdaptiveTheoryReminderBanner(),
          const NextLearningStepCard(),
          const PinnedTopPickCard(),
          const PinnedLearningSection(),
          const ContinueLearningCard(),
          const ResumeLessonCard(),
          const DecayMemoryHealthBanner(),
          const StreakBannerWidget(),
          if (tablet) const DailySpotlightCard(),
          _RecommendedCarousel(
            key: TrainingHomeScreen.recommendationsKey,
            narrow: narrow,
          ),
          const ProgressSummaryCard(),
          const TrainingProgressCard(),
          const WeakAreaSpotlightBlock(),
          const BoosterProgressCard(),
          const RefreshSkillsBlock(),
          const RecommendedDrillTile(),
          const TagProgressHistoryCard(),
          const BoosterSuggestionBlock(),
          const TheoryBoosterSuggestionBlock(),
          if (!tablet) const DailySpotlightCard(),
          if (narrow) ...[
            const QuickContinueCard(),
            const ResumeTrainingCard(),
            const DailyProgressRing(),
            const GoalsCard(),
            const GoalDashboardWidget(),
            const DailyGoalsCard(),
            const DailyChallengeCard(),
            const DailyFocusCard(),
            const SpotOfTheDayCard(),
            const ProgressSummaryBox(),
            const XPProgressBar(),
            const SuggestionCardWeakSpots(),
            const TagProgressCard(),
            const WeeklySummaryCard(),
          ] else ...[
            const QuickContinueCard(),
            const ResumeTrainingCard(),
            const DailyFocusRecapCard(),
            const DailyFocusCard(),
            const SpotOfTheDayCard(),
            const ProgressSummaryBox(),
            const PositionProgressCard(),
            const SkillProgressCard(),
            const ProgressForecastCard(),
            const PlayerStyleCard(),
            const StreakChart(),
            const StreakAnalyticsCard(),
            const DailyProgressRing(),
            const GoalsCard(),
            const GoalDashboardWidget(),
            const DailyGoalsCard(),
            const DailyChallengeCard(),
            const WeeklyChallengeCard(),
            const XPProgressBar(),
            const SuggestionCardWeakSpots(),
            const TagProgressCard(),
            const WeeklySummaryCard(),
            const AchievementsCard(),
            const WeakSpotCard(),
            const ReviewPastMistakesCard(),
            const RepeatMistakesCard(),
          ],
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => openTrainingTemplates(context),
        child: const Icon(Icons.auto_awesome_motion),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(8),
        child: TextButton.icon(
          onPressed: () => launchUrl(
            Uri.parse('https://www.youtube.com/watch?v=6H8YJYyK3n8'),
          ),
          icon: const Icon(Icons.music_note),
          label: const Text('Play Chill Mix'),
        ),
      ),
    );
  }
}

class _RecommendedCarousel extends StatefulWidget {
  final bool narrow;
  const _RecommendedCarousel({super.key, required this.narrow});

  @override
  State<_RecommendedCarousel> createState() => _RecommendedCarouselState();
}

class _RecommendedCarouselState extends State<_RecommendedCarousel> {
  List<TrainingPackTemplate> _tpls = [];
  final Map<String, TrainingPackStat?> _stats = {};
  final Map<String, double?> _delta = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final service = context.read<AdaptiveTrainingService>();
    await service.refresh();
    final list = service.recommended.toList();
    final weak = await context
        .read<WeakSpotRecommendationService>()
        .buildPack();
    if (weak != null) list.insert(0, weak);
    final review = await MistakeReviewPackService.latestTemplate(context);
    if (review != null) list.insert(0, review);
    final adjust = context.read<DynamicPackAdjustmentService>();
    final stats = <String, TrainingPackStat?>{};
    final delta = <String, double?>{};
    final adjusted = <TrainingPackTemplate>[];
    for (final t in list) {
      stats[t.id] =
          service.statFor(t.id) ??
          await TrainingPackStatsService.getStats(t.id);
      final hist = await TrainingPackStatsService.history(t.id);
      if (hist.length >= 2) {
        delta[t.id] =
            (hist.last.accuracy - hist[hist.length - 2].accuracy) * 100;
      }
      adjusted.add(await adjust.adjust(t));
    }
    _stats
      ..clear()
      ..addAll(stats);
    _delta
      ..clear()
      ..addAll(delta);
    setState(() {
      _tpls = adjusted;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _tpls.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            'Рекомендуем для старта',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(
          height: widget.narrow ? 110 : 140,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemBuilder: (_, i) => _PackCard(
              key: ValueKey(_tpls[i].id),
              template: _tpls[i],
              stat: _stats[_tpls[i].id],
              delta: _delta[_tpls[i].id],
              onDone: _load,
              small: widget.narrow,
            ),
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemCount: _tpls.length,
          ),
        ),
      ],
    );
  }
}

class _PackCard extends StatelessWidget {
  final TrainingPackTemplate template;
  final TrainingPackStat? stat;
  final double? delta;
  final VoidCallback onDone;
  final bool small;
  const _PackCard({
    super.key,
    required this.template,
    required this.stat,
    required this.delta,
    required this.onDone,
    this.small = false,
  });

  Future<void> _onDone(BuildContext context) async {
    onDone();
    final prefs = await SharedPreferences.getInstance();
    final done = prefs.getBool('completed_tpl_${template.id}') ?? false;
    if (!done || !context.mounted) return;
    final templates = context.read<TemplateStorageService>().templates;
    final next = templates
        .where(
          (t) =>
              t.isBuiltIn &&
              t.category == template.category &&
              t.id != template.id &&
              !(prefs.getBool('completed_tpl_${t.id}') ?? false),
        )
        .sortedByPriority()
        .firstOrNull;
    if (next == null) return;
    final snoozeKey = 'snooze_tpl_${next.id}';
    final snooze = prefs.getString(snoozeKey);
    if (snooze != null) {
      final savedAt = DateTime.tryParse(snooze);
      if (savedAt != null &&
          DateTime.now().difference(savedAt) < const Duration(hours: 12)) {
        return;
      }
    }
    final start = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Следующий пак «${next.name}» готов!'),
        content: Text(
          'Категория: ${translateCategory(next.category)}. Начать прямо сейчас?',
        ),
        actions: [
          Semantics(
            label: 'Начать ${next.name}',
            button: true,
            child: TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Начать'),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Позже'),
          ),
        ],
      ),
    );
    if (start == true && context.mounted) {
      await context.read<TrainingSessionService>().startSession(next);
      if (context.mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const TrainingSessionScreen()),
        );
      }
      onDone();
    } else if (start == false) {
      await prefs.setString(snoozeKey, DateTime.now().toIso8601String());
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = stat?.accuracy ?? 0;
    final completed = progress >= 0.8;
    final label = completed
        ? 'Пройдено'
        : progress > 0
        ? 'Продолжить'
        : 'Начать';
    final color = completed ? Colors.green : Colors.orange;
    final spotlight =
        context.watch<DailySpotlightService>().template?.id == template.id;
    final hasMistakes = context.read<MistakeReviewPackService>().hasMistakes(
      template.id,
    );
    final ev = stat?.postEvPct ?? 0;
    final icm = stat?.postIcmPct ?? 0;
    final rating = ((stat?.accuracy ?? 0) * 5).clamp(1, 5).round();
    final focus = template.handTypeSummary();
    final rangePct = ((template.heroRange?.length ?? 0) * 100 / 169).round();
    return Container(
      width: small ? 100 : 120,
      height: small ? 100 : 120,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (spotlight)
            const Text(
              '🎯 Пак дня',
              style: TextStyle(color: Colors.amber, fontSize: 12),
            ),
          Icon(hasMistakes ? Icons.error : Icons.shield, color: color),
          const Spacer(),
          Text(template.name, maxLines: 2, overflow: TextOverflow.ellipsis),
          Text(
            'Stack ${template.heroBbStack}bb • R $rangePct%',
            style: const TextStyle(fontSize: 10, color: Colors.white70),
          ),
          if (focus.isNotEmpty)
            Text(
              focus,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          Row(
            children: [
              for (var i = 0; i < rating; i++)
                const Icon(Icons.star, color: Colors.amber, size: 12),
            ],
          ),
          const SizedBox(height: 4),
          TweenAnimationBuilder<double>(
            curve: Curves.easeOutCubic,
            duration: const Duration(milliseconds: 600),
            tween: Tween(begin: 0.0, end: progress),
            builder: (_, value, __) => Semantics(
              label: 'Прогресс ${(value * 100).round()} %',
              value: '${(value * 100).round()}',
              child: LinearProgressIndicator(
                value: value,
                backgroundColor: Colors.white12,
                color: color,
                minHeight: 6,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Text(
                'EV ${ev.toStringAsFixed(0)}%  ICM ${icm.toStringAsFixed(0)}%',
                style: const TextStyle(fontSize: 10, color: Colors.white70),
              ),
              if (delta != null) ...[
                const SizedBox(width: 4),
                Icon(
                  delta! >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
                  size: 12,
                  color: delta! >= 0 ? Colors.green : Colors.red,
                ),
                Text(
                  '${delta!.abs().toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 10,
                    color: delta! >= 0 ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          ElevatedButton.icon(
            onPressed: completed
                ? null
                : () async {
                    await context.read<TrainingSessionService>().startSession(
                      template,
                    );
                    if (context.mounted) {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const TrainingSessionScreen(),
                        ),
                      );
                    }
                    await _onDone(context);
                  },
            icon: Icon(
              completed ? Icons.check : Icons.play_arrow,
              color: completed ? Colors.green : null,
              size: 16,
            ),
            label: Text(label),
          ),
          if (hasMistakes)
            OutlinedButton(
              onPressed: () async {
                final review = await context
                    .read<MistakeReviewPackService>()
                    .review(context, template.id);
                if (review != null && context.mounted) {
                  await context.read<TrainingSessionService>().startSession(
                    review,
                  );
                  if (context.mounted) {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const TrainingSessionScreen(),
                      ),
                    );
                  }
                }
              },
              child: const Text('Ошибки', style: TextStyle(fontSize: 12)),
            ),
        ],
      ),
    );
  }
}
