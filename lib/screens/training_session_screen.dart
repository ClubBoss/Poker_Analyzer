import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/training_session_service.dart';
import '../widgets/spot_quiz_widget.dart';
import '../widgets/style_hint_bar.dart';
import '../widgets/stack_range_bar.dart';
import '../widgets/dynamic_progress_row.dart';
import '../widgets/active_tag_goal_banner.dart';
import 'session_result_screen.dart';
import '../services/training_pack_stats_service.dart';
import '../services/cloud_sync_service.dart';
import '../services/achievement_service.dart';
import '../services/achievement_trigger_engine.dart';
import '../services/smart_review_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/tag_review_history_service.dart';
import '../services/skill_boost_log_service.dart';
import '../models/skill_boost_log_entry.dart';
import '../models/v2/training_session.dart';
import '../services/pack_library_completion_service.dart';
import '../models/v2/training_pack_v2.dart';
import '../models/v2/training_pack_template.dart';
import '../models/v2/training_pack_template_v2.dart';
import '../services/training_history_service_v2.dart';
import '../core/training/engine/training_type_engine.dart';
import '../models/v2/training_pack_spot.dart';
import '../models/v2/hero_position.dart';
import '../services/tag_mastery_service.dart';
import '../services/user_goal_engine.dart';
import '../services/goal_toast_service.dart';
import '../services/learning_path_progress_service.dart';
import '../services/daily_learning_goal_service.dart';
import '../services/pack_dependency_map.dart';
import '../services/pack_library_loader_service.dart';
import '../services/smart_stage_unlock_engine.dart';
import '../models/decay_tag_reinforcement_event.dart';
import '../services/theory_completion_event_dispatcher.dart';
import '../services/training_milestone_engine.dart';
import '../widgets/confetti_overlay.dart';
import '../widgets/booster_progress_overlay.dart';
import 'package:collection/collection.dart';
import 'dart:math';
import '../services/mistake_tag_history_service.dart';
import '../services/auto_mistake_tagger_engine.dart';
import '../models/training_spot_attempt.dart';
import '../services/booster_completion_tracker.dart';
import '../services/user_action_logger.dart';
import '../services/booster_auto_retry_suggester.dart';
import '../services/mistake_booster_progress_tracker.dart';
import '../services/training_progress_logger.dart';
import 'training_session_completion_screen.dart';
import '../services/inline_theory_linker_service.dart';
import '../widgets/theory_quick_access_banner.dart';
import '../widgets/inline_theory_recall_banner.dart';
import '../widgets/inline_theory_booster_display.dart';
import '../infra/telemetry.dart';

class _EndlessStats {
  int total = 0;
  int correct = 0;
  Duration elapsed = Duration.zero;
  void add(bool ok) {
    total += 1;
    if (ok) correct += 1;
  }

  void addDuration(Duration d) {
    elapsed += d;
  }

  double get accuracy => total == 0 ? 0 : correct / total;

  void reset() {
    total = 0;
    correct = 0;
    elapsed = Duration.zero;
  }
}

class TrainingSessionScreen extends StatefulWidget {
  static const route = '/training_session';
  final VoidCallback? onSessionEnd;
  final TrainingSession? session;
  final TrainingPackV2? pack;
  final int startIndex;
  final String? source;
  const TrainingSessionScreen({
    super.key,
    this.onSessionEnd,
    this.session,
    this.pack,
    this.startIndex = 0,
    this.source,
  });

  @override
  State<TrainingSessionScreen> createState() => _TrainingSessionScreenState();
}

class _TrainingSessionScreenState extends State<TrainingSessionScreen> {
  static final _EndlessStats _endlessStats = _EndlessStats();
  final _linker = InlineTheoryLinkerService();
  final String _sessionId = DateTime.now().millisecondsSinceEpoch.toString();
  String? _selected;
  bool? _correct;
  Timer? _timer;
  bool _continue = false;
  bool _summaryShown = false;
  bool _boosterRecapShown = false;

  void _restart() {
    final pack = widget.pack;
    if (pack == null) return;
    final tpl = _fromPack(pack);
    context.read<TrainingSessionService>().startSession(
      tpl,
      persist: false,
      startIndex: 0,
      source: widget.source ?? 'manual',
    );
    if (widget.onSessionEnd != null) _endlessStats.reset();
    setState(() {
      _selected = null;
      _correct = null;
      _continue = false;
      _summaryShown = false;
      _boosterRecapShown = false;
    });
  }

  TrainingPackTemplate _fromPack(TrainingPackV2 p) => TrainingPackTemplate(
    id: p.id,
    name: p.name,
    description: p.description,
    gameType: p.gameType,
    spots: List<TrainingPackSpot>.from(p.spots),
    tags: List<String>.from(p.tags),
    heroBbStack: p.bb,
    heroPos: p.positions.isNotEmpty
        ? parseHeroPosition(p.positions.first)
        : HeroPosition.sb,
    spotCount: p.spotCount,
    meta: Map<String, dynamic>.from(p.meta),
    isBuiltIn: true,
  );

  @override
  void initState() {
    super.initState();
    unawaited(Telemetry.logEvent('session_start', {'sessionId': _sessionId}));
    if (widget.pack != null) {
      final tpl = _fromPack(widget.pack!);
      Future.microtask(
        () => context.read<TrainingSessionService>().startSession(
          tpl,
          persist: false,
          startIndex: widget.startIndex,
          source: widget.source ?? 'manual',
        ),
      );
    }
    if (widget.onSessionEnd != null &&
        _endlessStats.total == 0 &&
        _endlessStats.elapsed == Duration.zero) {
      _endlessStats.reset();
    }
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    unawaited(Telemetry.logEvent('session_end', {'sessionId': _sessionId}));
    if (widget.onSessionEnd != null && !_continue) {
      _endlessStats.reset();
    }
    super.dispose();
  }

  String _format(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  String? _expectedAction(spot) {
    final acts = spot.hand.actions[0] ?? [];
    for (final a in acts) {
      if (a.playerIndex == spot.hand.heroIndex) return a.action;
    }
    return null;
  }

  double? _actionEv(TrainingPackSpot spot, String action) {
    for (final a in spot.hand.actions[0] ?? []) {
      if (a.playerIndex == spot.hand.heroIndex &&
          a.action.toLowerCase() == action.toLowerCase()) {
        return a.ev;
      }
    }
    return null;
  }

  double? _bestEv(TrainingPackSpot spot) {
    double? best;
    for (final a in spot.hand.actions[0] ?? []) {
      if (a.playerIndex == spot.hand.heroIndex && a.ev != null) {
        best = best == null ? a.ev! : max(best, a.ev!);
      }
    }
    return best;
  }

  Widget _linkedText(
    String text,
    TrainingPackSpot spot,
    TrainingPackTemplate tpl,
  ) {
    final tags = spot.tags.isNotEmpty ? spot.tags : tpl.tags;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 80),
      child: SingleChildScrollView(
        child: _linker
            .link(text, contextTags: tags)
            .toRichText(
              style: const TextStyle(color: Colors.white, fontSize: 12),
              linkStyle: const TextStyle(color: Colors.lightBlueAccent),
            ),
      ),
    );
  }

  double? _calcEvDiff(
    double? heroEv,
    double? bestEv,
    String user,
    String correct,
  ) {
    if (heroEv == null || bestEv == null) return null;
    final c = correct.toLowerCase();
    if (c == 'push' || c == 'call' || c == 'raise') {
      return bestEv - heroEv;
    }
    return heroEv - bestEv;
  }

  void _choose(String action, service, spot) {
    if (_selected != null) return;
    final expected = _expectedAction(spot);
    final ok =
        expected != null && action.toLowerCase() == expected.toLowerCase();
    service.submitResult(spot.id, action, ok);
    if (widget.onSessionEnd != null) _endlessStats.add(ok);
    setState(() {
      _selected = action;
      _correct = ok;
    });
  }

  Future<void> _next(service) async {
    final next = service.nextSpot();
    await _checkGoalProgress();
    final tpl = service.template;
    if (tpl != null) {
      final prefs = await SharedPreferences.getInstance();
      if (next == null) {
        await prefs.remove('progress_tpl_${tpl.id}');
        await prefs.setBool('completed_tpl_${tpl.id}', true);
        await prefs.setString(
          'completed_at_tpl_${tpl.id}',
          DateTime.now().toIso8601String(),
        );
        unawaited(
          TrainingHistoryServiceV2.logCompletion(
            TrainingPackTemplateV2.fromTemplate(
              tpl,
              type: TrainingType.pushFold,
            ),
          ),
        );
        unawaited(context.read<DailyLearningGoalService>().markCompleted());
        return;
      } else {
        await prefs.setInt(
          'progress_tpl_${tpl.id}',
          service.session?.index ?? 0,
        );
      }
    }
    if (!mounted) return;
    if (next == null) {
      if (widget.onSessionEnd != null) {
        _endlessStats.addDuration(service.elapsedTime);
        _continue = true;
        Navigator.pop(context);
        widget.onSessionEnd!();
      }
      return;
    } else {
      setState(() {
        _selected = null;
        _correct = null;
      });
    }
  }

  void _prev(service) {
    final prev = service.prevSpot();
    if (prev != null) {
      final res = service.results[prev.id];
      setState(() {
        if (res != null) {
          _selected = '';
          _correct = res;
        } else {
          _selected = null;
          _correct = null;
        }
      });
    }
  }

  Future<void> _showSummary(TrainingSessionService service) async {
    final tpl = service.template;
    if (tpl != null) {
      final isBooster = tpl.meta['type']?.toString().toLowerCase() == 'booster';
      if (isBooster && _boosterRecapShown) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Booster recap already shown')),
          );
        }
        return;
      }
      double? accBefore;
      String? boosterTag;
      if (isBooster) {
        boosterTag =
            tpl.meta['tag']?.toString() ??
            (tpl.tags.isNotEmpty ? tpl.tags.first : null);
        if (boosterTag != null) {
          final mastery = context.read<TagMasteryService>();
          final map = await mastery.computeMastery(force: true);
          accBefore = map[boosterTag.toLowerCase()] ?? 0.0;
        }
      }
      final correct = service.correctCount;
      final total = service.totalCount;
      final totalSpots = tpl.totalWeight;
      final evAfter = totalSpots == 0 ? 0.0 : tpl.evCovered * 100 / totalSpots;
      final icmAfter = totalSpots == 0
          ? 0.0
          : tpl.icmCovered * 100 / totalSpots;
      unawaited(
        TrainingPackStatsService.recordSession(
          tpl.id,
          correct,
          total,
          preEvPct: service.preEvPct,
          preIcmPct: service.preIcmPct,
          postEvPct: evAfter,
          postIcmPct: icmAfter,
          evSum: 0,
          icmSum: 0,
        ),
      );
      unawaited(
        SmartReviewService.instance.registerCompletion(
          total == 0 ? 0.0 : correct / total,
          evAfter / 100,
          icmAfter / 100,
          context: context,
        ),
      );
      for (final tag in tpl.tags) {
        unawaited(
          TagReviewHistoryService.instance.logReview(
            tag,
            total == 0 ? 0.0 : correct / total,
          ),
        );
      }
      final prefs = await SharedPreferences.getInstance();
      final acc = total == 0 ? 0.0 : correct * 100 / total;
      await prefs.setBool('completed_tpl_${tpl.id}', true);
      await LearningPathProgressService.instance.markCompleted(tpl.id);
      await SmartStageUnlockEngine.instance.checkAndUnlockNextStage();
      final newly = await PackDependencyMap.instance.getUnlockedAfter(tpl.id);
      if (newly.isNotEmpty && mounted) {
        final lib = PackLibraryLoaderService.instance.library;
        for (final id in newly) {
          final pack = lib.firstWhereOrNull((p) => p.id == id);
          if (pack != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '\uD83D\uDD13 Новый пак разблокирован: ${pack.name}',
                ),
              ),
            );
          }
        }
      }
      await prefs.setString(
        'completed_at_tpl_${tpl.id}',
        DateTime.now().toIso8601String(),
      );
      unawaited(context.read<DailyLearningGoalService>().markCompleted());
      await prefs.setString(
        'last_trained_tpl_${tpl.id}',
        DateTime.now().toIso8601String(),
      );
      await prefs.setDouble('last_accuracy_tpl_${tpl.id}', acc);
      for (var i = 2; i > 0; i--) {
        final prev = prefs.getDouble('last_accuracy_tpl_${tpl.id}_${i - 1}');
        if (prev != null) {
          await prefs.setDouble('last_accuracy_tpl_${tpl.id}_$i', prev);
        }
      }
      await prefs.setDouble('last_accuracy_tpl_${tpl.id}_0', acc);
      final cloud = context.read<CloudSyncService?>();
      if (cloud != null) {
        unawaited(cloud.save('completed_tpl_${tpl.id}', '1'));
      }
      final elapsed = service.elapsedTime;
      unawaited(
        PackLibraryCompletionService.instance.registerCompletion(
          tpl.id,
          correct: correct,
          total: total,
          elapsed: elapsed,
        ),
      );
      for (final action in service.actionLog.where((a) => !a.isCorrect)) {
        final spot = service.spots.firstWhereOrNull(
          (s) => s.id == action.spotId,
        );
        if (spot == null) continue;
        final exp = _expectedAction(spot) ?? spot.correctAction ?? '';
        final heroEv = _actionEv(spot, action.chosenAction);
        final bestEv = _bestEv(spot);
        final diff = _calcEvDiff(heroEv, bestEv, action.chosenAction, exp) ?? 0;
        final attempt = TrainingSpotAttempt(
          spot: spot,
          userAction: action.chosenAction,
          correctAction: exp,
          evDiff: diff,
        );
        final tags = const AutoMistakeTaggerEngine().tag(attempt);
        unawaited(MistakeTagHistoryService.logTags(tpl.id, attempt, tags));
      }
      Map<String, double> deltas = {};
      TrainingPackTemplateV2? boosterTpl;
      double? boosterAccuracy;
      if (isBooster) {
        deltas = await context.read<TagMasteryService>().updateWithSession(
          template: tpl,
          results: service.session?.results ?? const {},
          dryRun: true,
        );
        final tmp = TrainingPackTemplateV2.fromTemplate(
          tpl,
          type: TrainingType.pushFold,
        );
        final type = const TrainingTypeEngine().detectTrainingType(tmp);
        boosterTpl = TrainingPackTemplateV2.fromTemplate(tpl, type: type);
        final accuracy = total == 0 ? 0.0 : correct * 100 / total;
        boosterAccuracy = accuracy;
        final required =
            (tpl.meta['requiredAccuracy'] as num?)?.toDouble() ?? 80.0;
        if (accuracy >= required) {
          await BoosterCompletionTracker.instance.markBoosterCompleted(tpl.id);
          unawaited(
            UserActionLogger.instance.logEvent({
              'event': 'booster_completed',
              'id': tpl.id,
              if (boosterTag != null) 'tag': boosterTag,
              'accuracy': accuracy,
            }),
          );
        }
      }

      final reinforcements = [
        for (final e in deltas.entries)
          DecayTagReinforcementEvent(
            tag: e.key,
            delta: e.value,
            timestamp: DateTime.now(),
          ),
      ];

      unawaited(
        TrainingProgressLogger.finishSession(
          tpl.id,
          total,
          evPercent: evAfter,
          requiredAccuracy: tpl.requiredAccuracy,
          minHands: tpl.minHands,
        ),
      );
      await service.complete(
        context,
        resultBuilder: (_) =>
            TrainingSessionCompletionScreen(template: tpl, hands: total),
      );
      if (isBooster) {
        _boosterRecapShown = true;
        if (boosterAccuracy != null && boosterTpl != null) {
          await BoosterAutoRetrySuggester.instance.maybeSuggestRetry(
            boosterTpl,
            boosterAccuracy,
          );
        }
      }

      if (isBooster && boosterTag != null) {
        final mastery = context.read<TagMasteryService>();
        final after = await mastery.computeMastery(force: true);
        final accAfter = after[boosterTag.toLowerCase()] ?? accBefore ?? 0.0;
        await SkillBoostLogService.instance.add(
          SkillBoostLogEntry(
            tag: boosterTag,
            packId: tpl.id,
            timestamp: DateTime.now(),
            accuracyBefore: accBefore ?? 0.0,
            accuracyAfter: accAfter,
            handsPlayed: service.totalCount,
          ),
        );
        unawaited(
          MistakeBoosterProgressTracker.instance.recordProgress(deltas),
        );
      }
      AchievementService.instance.checkAll();
      await AchievementTriggerEngine.instance.checkAndTriggerAchievements();
      await _checkGoalProgress();
      final stats = await TrainingPackStatsService.getGlobalStats(force: true);
      final milestone = await TrainingMilestoneEngine.instance.checkAndTrigger(
        completedPacks: stats.packsCompleted,
      );
      if (milestone.triggered && mounted) {
        showConfettiOverlay(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(milestone.message)));
      }
      TheoryCompletionEventDispatcher.instance.dispatch(
        TheoryCompletionEvent(
          lessonId: tpl.id,
          wasSuccessful: total == 0 ? true : correct / total >= 0.5,
        ),
      );
    }
  }

  void _showEndlessSummary() {
    final service = context.read<TrainingSessionService>();
    _endlessStats.addDuration(service.elapsedTime);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => SessionResultScreen(
          total: _endlessStats.total,
          correct: _endlessStats.correct,
          elapsed: _endlessStats.elapsed,
          authorPreview: false,
        ),
      ),
    );
    _endlessStats.reset();
  }

  Future<void> _checkGoalProgress() async {
    final engine = context.read<UserGoalEngine>();
    final toast = context.read<GoalToastService>();
    final mastery = await context.read<TagMasteryService>().computeMastery();
    for (final g in engine.goals) {
      if (g.completed) continue;
      double pct;
      if (g.tag != null && g.targetAccuracy != null) {
        final current = (mastery[g.tag] ?? 0.0) * 100;
        final base = g.base.toDouble();
        final target = g.targetAccuracy!;
        pct = target <= base
            ? 100.0
            : ((current - base) / (target - base)) * 100;
      } else {
        final prog = engine.progress(g);
        pct = g.target > 0 ? prog * 100 / g.target : 0.0;
      }
      toast.maybeShowToast(g, pct);
    }
  }

  Widget _progressBar(TrainingSessionService service) {
    final total = service.template?.spots.length ?? 0;
    if (total == 0) return const SizedBox(height: 4);
    final index = service.session?.index ?? 0;
    final correct = service.results.values.where((e) => e).length;
    final incorrect = service.results.values.where((e) => !e).length;
    final remaining = (total - index).clamp(0, total);
    final segments = <Widget>[];
    if (correct > 0) {
      segments.add(
        Expanded(
          flex: correct,
          child: Container(height: 4, color: Colors.green),
        ),
      );
    }
    if (incorrect > 0) {
      segments.add(
        Expanded(
          flex: incorrect,
          child: Container(height: 4, color: Colors.red),
        ),
      );
    }
    if (remaining > 0) {
      segments.add(
        Expanded(
          flex: remaining,
          child: Container(height: 4, color: Colors.grey),
        ),
      );
    }
    return Row(children: segments);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        final service = context.read<TrainingSessionService>();
        if (service.session?.completedAt != null) return true;
        final confirm = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Exit training? Unsaved progress will be lost.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Exit'),
              ),
            ],
          ),
        );
        return confirm ?? false;
      },
      child: Consumer<TrainingSessionService>(
        builder: (context, service, _) {
          if (!_summaryShown &&
              service.session != null &&
              service.template != null &&
              service.session!.index >= service.template!.spots.length) {
            _summaryShown = true;
          }
          final spot = service.currentSpot;
          if (spot == null) {
            return const Scaffold(
              backgroundColor: Color(0xFF1B1C1E),
              body: Center(child: CircularProgressIndicator()),
            );
          }
          final expected = _expectedAction(spot);
          final tag = spot.tags.firstWhere(
            (t) => t.startsWith('cat:'),
            orElse: () => '',
          );
          final categoryName = tag.isNotEmpty ? tag.substring(4) : null;
          final showCategory =
              service.template?.id == 'suggested_weekly' &&
              categoryName != null;
          final tpl = service.template;
          final isBooster =
              tpl?.meta['type']?.toString().toLowerCase() == 'booster';
          return Scaffold(
            appBar: AppBar(
              title: const Text('Training'),
              actions: [
                if (widget.pack != null)
                  IconButton(
                    onPressed: _restart,
                    icon: const Icon(Icons.replay),
                  ),
                IconButton(
                  onPressed: service.isPaused ? service.resume : service.pause,
                  icon: Icon(service.isPaused ? Icons.play_arrow : Icons.pause),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF1B1C1E),
            body: Stack(
              children: [
                if (isBooster && tpl != null) const BoosterProgressOverlay(),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      if (service.session != null && tpl != null) ...[
                        Text(
                          tpl.name,
                          style: const TextStyle(color: Colors.white70),
                          textAlign: TextAlign.center,
                        ),
                        if (tpl.meta['samplePreview'] == true)
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            padding: const EdgeInsets.symmetric(
                              vertical: 4,
                              horizontal: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              "Preview mode: You're training with a sample",
                              style: TextStyle(color: Colors.orangeAccent),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        if (tpl.description.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          _linkedText(tpl.description, spot, tpl),
                        ],
                        if (tpl.goal.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          _linkedText(tpl.goal, spot, tpl),
                        ],
                        const SizedBox(height: 4),
                        _progressBar(service),
                        const SizedBox(height: 4),
                        Text(
                          'Accuracy ${(service.results.isEmpty ? 0 : service.results.values.where((e) => e).length * 100 / service.results.length).toStringAsFixed(0)}%',
                          style: const TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'EV ${service.evAverage.toStringAsFixed(2)} • ICM ${service.icmAverage.toStringAsFixed(2)}',
                          style: const TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${service.session!.index + 1} / ${tpl.spots.length}',
                          style: const TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(height: 4),
                        if (spot.tags.isNotEmpty)
                          ActiveTagGoalBanner(
                            tagId: spot.tags.firstWhere(
                              (t) => !t.startsWith('cat:'),
                              orElse: () => spot.tags.first,
                            ),
                          ),
                        InlineTheoryRecallBanner(spot: spot),
                        TheoryQuickAccessBannerWidget(tags: spot.tags),
                      ],
                      Text(
                        'Elapsed: ${_format(service.elapsedTime)}',
                        style: const TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 8),
                      const StyleHintBar(),
                      const StackRangeBar(),
                      const DynamicProgressRow(),
                      if (tpl != null && spot.note.trim().isNotEmpty) ...[
                        const SizedBox(height: 8),
                        _linkedText(spot.note, spot, tpl),
                      ],
                      Expanded(child: SpotQuizWidget(spot: spot)),
                      if (service.focusHandTypes.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              for (final g in service.focusHandTypes)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: LinearProgressIndicator(
                                          value:
                                              service.handGoalTotal[g.label] !=
                                                      null &&
                                                  service.handGoalTotal[g
                                                          .label]! >
                                                      0
                                              ? (service.handGoalCount[g.label]
                                                            ?.clamp(
                                                              0,
                                                              service
                                                                  .handGoalTotal[g
                                                                  .label]!,
                                                            ) ??
                                                        0) /
                                                    service.handGoalTotal[g
                                                        .label]!
                                              : 0,
                                          color: Colors.purpleAccent,
                                          backgroundColor: Colors.purpleAccent
                                              .withValues(alpha: 0.3),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '${g.label} ${service.handGoalCount[g.label] ?? 0}/${service.handGoalTotal[g.label] ?? 0}',
                                        style: const TextStyle(
                                          color: Colors.white70,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      if (service.isPaused) ...[
                        const SizedBox(height: 16),
                        const Text(
                          'Сессия на паузе',
                          style: TextStyle(color: Colors.white54),
                        ),
                      ] else if (_selected == null) ...[
                        const SizedBox(height: 16),
                        const Text(
                          'Ваше действие?',
                          style: TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          alignment: WrapAlignment.center,
                          children: [
                            for (final a in [
                              'fold',
                              'call',
                              'raise',
                              'check',
                              'bet',
                            ])
                              ElevatedButton(
                                onPressed: () => _choose(a, service, spot),
                                child: Text(a.toUpperCase()),
                              ),
                          ],
                        ),
                        if (service.session?.index != null &&
                            service.session!.index > 0)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: ElevatedButton(
                                onPressed: () => _prev(service),
                                child: const Text('Prev'),
                              ),
                            ),
                          ),
                      ] else ...[
                        const SizedBox(height: 16),
                        Text(
                          _correct!
                              ? 'Верно!'
                              : 'Неверно. Надо ${expected ?? '-'}',
                          style: TextStyle(
                            color: _correct! ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            if (service.session?.index != null &&
                                service.session!.index > 0)
                              ElevatedButton(
                                onPressed: () => _prev(service),
                                child: const Text('Prev'),
                              ),
                            ElevatedButton(
                              onPressed: () => _next(service),
                              child: const Text('Next'),
                            ),
                          ],
                        ),
                        Builder(
                          builder: (context) {
                            final tag = spot.tags.firstWhere(
                              (t) => !t.startsWith('cat:'),
                              orElse: () => '',
                            );
                            if (tag.isEmpty) return const SizedBox.shrink();
                            return InlineTheoryBoosterDisplay(tag: tag);
                          },
                        ),
                        if (showCategory)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              categoryName,
                              style: const TextStyle(color: Colors.white70),
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
                if (widget.onSessionEnd != null)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      color: Colors.black54,
                      padding: const EdgeInsets.all(8),
                      child: Text(
                        'Total: ${_endlessStats.total}  ${(_endlessStats.accuracy * 100).toStringAsFixed(0)}%  ${_format(_endlessStats.elapsed + service.elapsedTime)}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ),
                  ),
              ],
            ),
            floatingActionButton: widget.onSessionEnd != null
                ? FloatingActionButton(
                    heroTag: 'stopDrillFab',
                    tooltip: 'Stop Drill & show summary',
                    onPressed: _showEndlessSummary,
                    child: const Icon(Icons.stop),
                  )
                : null,
          );
        },
      ),
    );
  }
}
