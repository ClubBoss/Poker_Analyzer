import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../services/png_exporter.dart';
import 'package:flutter/rendering.dart';
import '../widgets/combined_progress_bar.dart';
import '../widgets/combined_progress_change_bar.dart';
import '../widgets/ev_icm_history_chart.dart';
import '../widgets/ev_icm_improvement_row.dart';
import '../models/v2/training_pack_spot.dart';
import '../models/v2/training_pack_template.dart';
import '../models/v2/training_session.dart';
import '../services/training_session_service.dart';
import '../services/adaptive_training_service.dart';
import '../services/weak_spot_recommendation_service.dart';
import '../services/mistake_review_pack_service.dart';
import '../services/daily_tip_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../helpers/mistake_advice.dart';
import '../helpers/poker_street_helper.dart';
import '../services/session_log_service.dart';
import '../services/training_path_progress_service_v2.dart';
import '../services/learning_path_registry_service.dart';
import '../services/tag_mastery_service.dart';
import 'stage_completed_screen.dart';
import 'package:collection/collection.dart';
import '../widgets/spot_viewer_dialog.dart';
import '../theme/app_colors.dart';
import 'training_session_screen.dart';
import 'v2/training_pack_play_screen.dart';
import '../services/next_step_engine.dart';
import 'mistake_repeat_screen.dart';
import 'goals_overview_screen.dart';
import 'spot_of_the_day_screen.dart';
import 'weakness_overview_screen.dart';
import '../services/training_path_progress_tracker_service.dart';
import '../services/training_path_node_definition_service.dart';
import 'next_step_suggestion_dialog.dart';
import '../widgets/mistake_review_button.dart';
import '../services/streak_tracker_service.dart';
import '../services/streak_milestone_queue_service.dart';
import '../widgets/confetti_overlay.dart';
import '../services/overlay_booster_manager.dart';
import '../widgets/decay_recall_stats_card.dart';
import '../widgets/decay_review_recap_banner.dart';
import '../services/decay_session_tag_impact_recorder.dart';
import '../widgets/booster_completion_banner.dart';
import '../models/training_pack.dart';

class TrainingSessionSummaryScreen extends StatefulWidget {
  final TrainingSession session;
  final TrainingPackTemplate template;
  final double preEvPct;
  final double preIcmPct;
  final int xpEarned;
  final double xpMultiplier;
  final double streakMultiplier;
  final Map<String, double> tagDeltas;
  const TrainingSessionSummaryScreen({
    super.key,
    required this.session,
    required this.template,
    required this.preEvPct,
    required this.preIcmPct,
    required this.xpEarned,
    required this.xpMultiplier,
    this.streakMultiplier = 1.0,
    this.tagDeltas = const {},
  });

  @override
  State<TrainingSessionSummaryScreen> createState() =>
      _TrainingSessionSummaryScreenState();
}

class _TrainingSessionSummaryScreenState
    extends State<TrainingSessionSummaryScreen> {
  final _shareBoundaryKey = GlobalKey();
  TrainingPackTemplate? _weakPack;
  bool _autoReview = true;

  /// Computes aggregate hands played and accuracy for [packId].
  _StageStats _computeStats(String packId, List<SessionLog> logs) {
    var hands = 0;
    var correct = 0;
    for (final l in logs) {
      if (l.templateId == packId) {
        hands += l.correctCount + l.mistakeCount;
        correct += l.correctCount;
      }
    }
    final acc = hands == 0 ? 0.0 : correct * 100 / hands;
    return _StageStats(hands: hands, accuracy: acc);
  }

  Future<void> _finish() async {
    final tracker = const TrainingPathProgressTrackerService();
    final node = const TrainingPathNodeDefinitionService()
        .getPath()
        .firstWhereOrNull((n) => n.packIds.contains(widget.template.id));
    if (node != null) {
      await tracker.markCompleted(node.id);
    }

    final registry = LearningPathRegistryService.instance;
    final templates = await registry.loadAll();
    final logs = context.read<SessionLogService>();
    await logs.load();
    for (final path in templates) {
      final stage = path.stages.firstWhereOrNull(
        (s) => s.packId == widget.template.id,
      );
      if (stage == null) continue;
      final progress = TrainingPathProgressServiceV2(logs: logs);
      await progress.loadProgress(path.id);
      final before = progress.getStageCompletion(stage.id);
      final stats = _computeStats(stage.packId, logs.logs);
      await progress.markStageCompleted(stage.id, stats.accuracy);
      final after = progress.getStageCompletion(stage.id);
      if (!before && after) {
        final mastery = context.read<TagMasteryService>();
        await mastery.updateWithSession(
          template: widget.template,
          results: widget.session.results,
          dryRun: false,
          applyCompletionBonus: true,
          requiredHands: stage.minHands,
          requiredAccuracy: stage.requiredAccuracy,
        );
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => StageCompletedScreen(
              pathId: path.id,
              stageTitle: stage.title,
              accuracy: stats.accuracy,
              hands: stats.hands,
            ),
          ),
        );
        return;
      }
    }
    if (mounted) {
      Navigator.of(context).popUntil((r) => r.isFirst);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await StreakTrackerService.instance.markActiveToday(context);
      final s = context.read<NextStepEngine>().suggestion;
      if (s != null) _showNextStep(s);
      await NextStepSuggestionDialog.show(context);
      await StreakMilestoneQueueService.instance
          .showNextMilestoneCelebrationIfAny(context);
      await context.read<OverlayBoosterManager>().onAfterXpScreen();
      if (widget.template.tags.contains('decayBooster') &&
          widget.tagDeltas.isNotEmpty) {
        unawaited(
          DecaySessionTagImpactRecorder.instance.recordSession(
            widget.tagDeltas,
            DateTime.now(),
          ),
        );
      }
      if (widget.template.tags.any((t) => t.contains('booster'))) {
        final result = TrainingSessionResult(
          date: DateTime.now(),
          total: widget.session.results.length,
          correct: widget.session.results.values.where((e) => e).length,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          BoosterCompletionBanner(
            context: context,
            template: widget.template,
            result: result,
          ),
        );
      }
    });
    _loadWeakPack();
  }

  Future<void> _loadWeakPack() async {
    final service = context.read<WeakSpotRecommendationService>();
    final tpl = await service.buildPack();
    if (!mounted) return;
    setState(() => _weakPack = tpl);
    await _maybeShowPackTip(service);
  }

  Future<void> _maybeShowPackTip(WeakSpotRecommendationService service) async {
    if (_weakPack == null) return;
    final total = widget.session.results.length;
    if (total < 10) return;
    final correct = widget.session.results.values.where((e) => e).length;
    final accuracy = total == 0 ? 0.0 : correct * 100 / total;
    if (accuracy >= 90) return;
    final rec = service.recommendation;
    if (rec == null) return;
    final prefs = await SharedPreferences.getInstance();
    final key = 'weak_tip_${rec.position.name}';
    final lastStr = prefs.getString(key);
    if (lastStr != null) {
      final last = DateTime.tryParse(lastStr);
      if (last != null &&
          DateTime.now().difference(last) < const Duration(days: 1)) {
        return;
      }
    }
    await prefs.setString(key, DateTime.now().toIso8601String());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Want to improve your ${rec.position.label}? Try ${_weakPack!.name}.',
          ),
          action: SnackBarAction(
            label: 'Train',
            onPressed: () async {
              await context.read<TrainingSessionService>().startSession(
                _weakPack!,
                persist: false,
              );
              if (!context.mounted) return;
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => const TrainingSessionScreen(),
                ),
              );
            },
          ),
          duration: const Duration(seconds: 6),
        ),
      );
    });
  }

  void _open(String route) {
    switch (route) {
      case '/mistake_repeat':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MistakeRepeatScreen()),
        );
        break;
      case '/goals':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const GoalsOverviewScreen()),
        );
        break;
      case '/spot_of_the_day':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SpotOfTheDayScreen()),
        );
        break;
    }
  }

  void _showNextStep(NextStepSuggestion s) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Row(
          children: [
            Icon(s.icon, color: Theme.of(context).colorScheme.secondary),
            const SizedBox(width: 8),
            Text(s.title),
          ],
        ),
        content: Text(s.message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Later'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _open(s.targetRoute);
            },
            child: const Text('Go'),
          ),
        ],
      ),
    );
  }

  Future<void> _share(BuildContext context) async {
    final boundary =
        _shareBoundaryKey.currentContext?.findRenderObject()
            as RenderRepaintBoundary?;
    if (boundary == null) return;
    final bytes = await PngExporter.captureBoundary(boundary);
    if (bytes == null) return;
    final dir = await getTemporaryDirectory();
    final file = File(
      '${dir.path}/summary_${DateTime.now().millisecondsSinceEpoch}.png',
    );
    await file.writeAsBytes(bytes, flush: true);
    await Share.shareXFiles([XFile(file.path)]);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final tip = context.watch<DailyTipService>().tip;
    final total = widget.session.results.length;
    final correct = widget.session.results.values.where((e) => e).length;
    final accuracy = total == 0 ? 0.0 : correct * 100 / total;
    final tTotal = widget.template.spots.length;
    final evPct = tTotal == 0 ? 0.0 : widget.template.evCovered * 100 / tTotal;
    final icmPct = tTotal == 0
        ? 0.0
        : widget.template.icmCovered * 100 / tTotal;
    final mistakes = [
      for (final id in widget.session.results.keys)
        if (widget.session.results[id] == false)
          widget.template.spots.firstWhere(
            (s) => s.id == id,
            orElse: () => TrainingPackSpot(id: ''),
          ),
    ].where((s) => s.id.isNotEmpty).toList();
    return RepaintBoundary(
      key: _shareBoundaryKey,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l.trainingSummary),
          actions: [
            IconButton(
              onPressed: () => _share(context),
              icon: const Icon(Icons.share),
            ),
          ],
        ),
        backgroundColor: AppColors.background,
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  '${accuracy.toStringAsFixed(1)}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              CombinedProgressBar(widget.preEvPct, widget.preIcmPct),
              const SizedBox(height: 4),
              CombinedProgressChangeBar(
                prevEvPct: widget.preEvPct,
                prevIcmPct: widget.preIcmPct,
                evPct: evPct,
                icmPct: icmPct,
              ),
              const SizedBox(height: 12),
              const EvIcmHistoryChart(),
              const EvIcmImprovementRow(),
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (widget.xpMultiplier > 1.0)
                      const Text('🔥', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 4),
                    Text(
                      'XP +${widget.xpEarned}',
                      style: const TextStyle(color: Colors.orange),
                    ),
                    if (widget.xpMultiplier > 1.0)
                      Text(
                        ' x${widget.xpMultiplier.toStringAsFixed(1)}',
                        style: const TextStyle(color: Colors.orange),
                      ),
                  ],
                ),
              ),
              if (widget.streakMultiplier > 1.0)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '🔥 Бонус за стрик: +${((widget.streakMultiplier - 1) * 100).round()}% XP',
                    style: const TextStyle(color: Colors.orange),
                  ),
                ),
              if (widget.template.tags.contains('decayBooster'))
                DecayRecallStatsCard(
                  tagDeltas: widget.tagDeltas,
                  spotCount: widget.session.results.length,
                ),
              const DecayReviewRecapBanner(),
              const SizedBox(height: 16),
              if (widget.tagDeltas.isNotEmpty) ...[
                const Text(
                  'Skill Gains',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                for (final e
                    in (widget.tagDeltas.entries.toList()
                      ..sort((a, b) => b.value.abs().compareTo(a.value.abs()))))
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          e.key,
                          style: const TextStyle(color: Colors.white70),
                        ),
                        Text(
                          '${e.value >= 0 ? '+' : '-'}${(e.value.abs() * 100).toStringAsFixed(2)}%',
                          style: TextStyle(
                            color: e.value > 0
                                ? Colors.green
                                : (e.value < 0 ? Colors.red : Colors.grey),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),
              ],
              Builder(
                builder: (context) {
                  final adv = <String>{};
                  for (final m in mistakes) {
                    for (final t in m.tags) {
                      final a = kMistakeAdvice[t];
                      if (a != null) adv.add(a);
                    }
                    final pos = m.hand.position.label;
                    final pAdv = kMistakeAdvice[pos];
                    if (pAdv != null) adv.add(pAdv);
                    int street = 0;
                    final b = m.hand.board.length;
                    if (b >= 5) {
                      street = 3;
                    } else if (b == 4)
                      street = 2;
                    else if (b == 3)
                      street = 1;
                    final sAdv = kMistakeAdvice[streetName(street)];
                    if (sAdv != null) adv.add(sAdv);
                  }
                  final deltaEv = evPct - widget.preEvPct;
                  final deltaIcm = icmPct - widget.preIcmPct;
                  adv.add(
                    'Прогресс EV ${deltaEv >= 0 ? '+' : ''}${deltaEv.toStringAsFixed(1)}%, ICM ${deltaIcm >= 0 ? '+' : ''}${deltaIcm.toStringAsFixed(1)}%',
                  );
                  final packs = context
                      .watch<AdaptiveTrainingService>()
                      .recommended;
                  final list = <TrainingPackTemplate>[];
                  if (_weakPack != null) list.add(_weakPack!);
                  for (final p in packs) {
                    if (list.length >= 3) break;
                    list.add(p);
                  }
                  if (adv.isEmpty && list.isEmpty)
                    return const SizedBox.shrink();
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[850],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final a in adv)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              a,
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        if (list.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            l.recommendedPacks,
                            style: const TextStyle(color: Colors.white),
                          ),
                          const SizedBox(height: 4),
                          for (final p in list)
                            Text(
                              p.name,
                              style: const TextStyle(color: Colors.white70),
                            ),
                        ],
                      ],
                    ),
                  );
                },
              ),
              Builder(
                builder: (context) {
                  final service = context.watch<MistakeReviewPackService>();
                  if (!service.hasMistakes()) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: ElevatedButton(
                      onPressed: () async {
                        final tpl = await service.buildPack(context);
                        if (tpl == null) return;
                        await context
                            .read<TrainingSessionService>()
                            .startSession(tpl, persist: false);
                        if (!context.mounted) return;
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const TrainingSessionScreen(),
                          ),
                        );
                      },
                      child: Text(l.repeatMistakes),
                    ),
                  );
                },
              ),
              if (tip.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Dismissible(
                    key: const ValueKey('dailyTip'),
                    direction: DismissDirection.up,
                    onDismissed: (_) =>
                        context.read<DailyTipService>().ensureTodayTip(),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[850],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.lightbulb,
                            color: Colors.greenAccent,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              tip,
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              if (mistakes.isNotEmpty)
                Expanded(
                  child: ListView.builder(
                    itemCount: mistakes.length,
                    itemBuilder: (context, index) {
                      final s = mistakes[index];
                      return ListTile(
                        title: Text(
                          s.title,
                          style: const TextStyle(color: Colors.white),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.replay, color: Colors.orange),
                          onPressed: () => showSpotViewerDialog(context, s),
                        ),
                      );
                    },
                  ),
                )
              else
                Expanded(
                  child: Center(
                    child: Text(
                      l.noMistakes,
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              if (mistakes.isNotEmpty) ...[
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TrainingPackPlayScreen(
                          template: MistakeReviewPackService.cachedTemplate!,
                          original: null,
                        ),
                      ),
                    );
                  },
                  child: Text(l.reviewMistakes),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  value: _autoReview,
                  onChanged: (v) => setState(() => _autoReview = v),
                  title: const Text(
                    'Auto review mistakes',
                    style: TextStyle(color: Colors.white),
                  ),
                  activeColor: Colors.orange,
                  contentPadding: EdgeInsets.zero,
                ),
              ],
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        final service = context.read<TrainingSessionService>();
                        final newSession = await service.startFromMistakes();
                        if (!context.mounted) return;
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                TrainingSessionScreen(session: newSession),
                          ),
                        );
                      },
                      child: Text(l.repeatMistakes),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        final reviewService = context
                            .read<MistakeReviewPackService>();
                        if (_autoReview && reviewService.hasMistakes()) {
                          final tpl = await reviewService.buildPack(context);
                          if (tpl != null) {
                            await context
                                .read<TrainingSessionService>()
                                .startSession(tpl, persist: false);
                            if (!context.mounted) return;
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const TrainingSessionScreen(),
                              ),
                            );
                            return;
                          }
                        }
                        await _finish();
                      },
                      child: const Text('Finish'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const WeaknessOverviewScreen(),
                    ),
                  );
                },
                child: Text(l.exportWeaknessReport),
              ),
              MistakeReviewButton(
                session: widget.session,
                template: widget.template,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StageStats {
  final int hands;
  final double accuracy;
  const _StageStats({required this.hands, required this.accuracy});
}
