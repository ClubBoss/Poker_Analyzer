import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../widgets/goal_reminder_banner.dart';
import '../widgets/auto_mistake_drill_banner_widget.dart';
import '../widgets/decay_boosted_banner.dart';
import '../widgets/broken_streak_banner.dart';

import '../models/goal_progress.dart';
import '../models/goal_engagement.dart';
import '../models/mistake_history_entry.dart';
import '../models/v2/training_pack_spot.dart';

import 'session_log_service.dart';
import 'smart_goal_reminder_engine.dart';
import 'smart_goal_tracking_service.dart';
import 'pack_library_loader_service.dart';
import 'goal_engagement_tracker.dart';
import 'learning_path_service.dart';
import 'mistake_drill_launcher_service.dart';
import 'mistake_driven_drill_pack_generator.dart';
import 'mistake_review_pack_service.dart';
import 'template_storage_service.dart';
import 'decay_booster_reminder_engine.dart';
import 'review_streak_evaluator_service.dart';

class ReminderBanner {
  final Widget widget;
  const ReminderBanner(this.widget);
}

abstract class ReminderSource {
  String get id;
  int get priority;
  Duration get cooldown;
  Future<bool> canShow();
  ReminderBanner build();
}

class TrainingReminderBannerEngine {
  final List<ReminderSource> sources;
  TrainingReminderBannerEngine({required this.sources});

  Future<ReminderBanner?> getNextReminderBanner() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final ordered = [...sources]
      ..sort((a, b) => b.priority.compareTo(a.priority));
    for (final src in ordered) {
      final lastStr = prefs.getString('trb_${src.id}');
      final last = lastStr != null ? DateTime.tryParse(lastStr) : null;
      if (last != null && now.difference(last) < src.cooldown) continue;
      if (await src.canShow()) {
        await prefs.setString('trb_${src.id}', now.toIso8601String());
        return src.build();
      }
    }
    return null;
  }
}

class DailyGoalReminder implements ReminderSource {
  DailyGoalReminder({required this.logs});

  final SessionLogService logs;

  @override
  String get id => 'daily_goal';

  @override
  int get priority => 4;

  @override
  Duration get cooldown => const Duration(hours: 12);

  @override
  ReminderBanner build() => const ReminderBanner(GoalReminderBanner());

  @override
  Future<bool> canShow() async {
    if (!LearningPathService.instance.smartMode) return false;
    await PackLibraryLoaderService.instance.loadLibrary();
    final packs = PackLibraryLoaderService.instance.library;
    final tags = <String>{};
    for (final p in packs) {
      tags.addAll(p.tags.map((e) => e.trim().toLowerCase()));
    }
    final tracker = SmartGoalTrackingService(logs: logs);
    final goals = <GoalProgress>[];
    for (final t in tags) {
      final g = await tracker.getGoalProgress(t);
      goals.add(g);
    }
    final log = await GoalEngagementTracker.instance.getAll();
    const engine = SmartGoalReminderEngine();
    final stale = await engine.getStaleGoalTags(
      allGoals: goals,
      engagementLog: log,
    );
    return stale.isNotEmpty;
  }
}

class AutoMistakeDrillReminder implements ReminderSource {
  AutoMistakeDrillReminder({required this.review, required this.templates});

  final MistakeReviewPackService review;
  final TemplateStorageService templates;

  @override
  String get id => 'auto_mistake_drill';

  @override
  int get priority => 3;

  @override
  Duration get cooldown => const Duration(days: 1);

  @override
  ReminderBanner build() =>
      const ReminderBanner(AutoMistakeDrillBannerWidget());

  @override
  Future<bool> canShow() async {
    final generator = MistakeDrivenDrillPackGenerator(
      history: _MistakePackHistory(review),
      loadSpot: (id) async {
        for (final t in templates.templates) {
          for (final s in t.spots) {
            if (s.id == id) {
              return TrainingPackSpot.fromJson(s.toJson());
            }
          }
        }
        return null;
      },
    );
    final launcher = MistakeDrillLauncherService(generator: generator);
    if (!await launcher.shouldTriggerAutoDrill()) return false;
    final pack = await generator.generate(limit: 5);
    return pack != null && pack.spots.isNotEmpty;
  }
}

class DecayBoosterReminder implements ReminderSource {
  DecayBoosterReminder({DecayBoosterReminderEngine? engine})
    : engine = engine ?? DecayBoosterReminderEngine();

  final DecayBoosterReminderEngine engine;

  @override
  String get id => 'decay_booster';

  @override
  int get priority => 2;

  @override
  Duration get cooldown => const Duration(days: 1);

  @override
  ReminderBanner build() => const ReminderBanner(DecayBoostedBanner());

  @override
  Future<bool> canShow() => engine.shouldShowReminder();
}

class StreakBrokenReminder implements ReminderSource {
  StreakBrokenReminder({ReviewStreakEvaluatorService? evaluator})
    : evaluator = evaluator ?? const ReviewStreakEvaluatorService();

  final ReviewStreakEvaluatorService evaluator;

  @override
  String get id => 'streak_broken';

  @override
  int get priority => 1;

  @override
  Duration get cooldown => const Duration(days: 1);

  @override
  ReminderBanner build() => const ReminderBanner(BrokenStreakBanner());

  @override
  Future<bool> canShow() async {
    final list = await evaluator.packsWithBrokenStreaks();
    return list.isNotEmpty;
  }
}

class _MistakePackHistory extends MistakeHistoryQueryService {
  _MistakePackHistory(this._source)
    : super(
        loadSpottings: () async => [],
        resolveTags: (_) async => [],
        resolveStreet: (_) async => null,
      );

  final MistakeReviewPackService _source;

  @override
  Future<List<MistakeHistoryEntry>> queryMistakes({
    String? tag,
    String? street,
    String? spotIdPattern,
    int limit = 20,
  }) async {
    final entries = <MistakeHistoryEntry>[];
    for (final pack in _source.packs) {
      for (final id in pack.spotIds) {
        entries.add(
          MistakeHistoryEntry(
            spotId: id,
            timestamp: pack.createdAt,
            decayStage: '',
            tag: '',
            wasRecovered: false,
          ),
        );
      }
    }
    entries.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return entries.take(limit).toList();
  }
}
