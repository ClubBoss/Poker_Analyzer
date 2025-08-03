import 'package:flutter/material.dart';

import '../models/learning_path_stage_model.dart';
import '../models/learning_path_template_v2.dart';
import '../models/v2/training_pack_template_v2.dart';
import '../models/theory_pack_model.dart';
import '../services/learning_path_orchestrator.dart';
import '../services/training_progress_service.dart';
import '../services/pack_library_service.dart';
import '../services/theory_pack_library_service.dart';
import '../services/learning_path_planner_engine.dart';
import '../services/weekly_planner_booster_feed.dart';
import '../services/session_storage_service.dart';
import '../services/learning_path_progress_tracker.dart';
import '../widgets/learning_path_stage_progress_card.dart';
import '../widgets/tag_badge.dart';
import 'learning_path_stage_preview_screen.dart';
import 'training_pack_preview_screen.dart';
import '../constants/app_constants.dart';

class LearningPathWeekPlannerScreen extends StatefulWidget {
  const LearningPathWeekPlannerScreen({super.key});

  @override
  State<LearningPathWeekPlannerScreen> createState() =>
      _LearningPathWeekPlannerScreenState();
}

class _LearningPathWeekPlannerScreenState
    extends State<LearningPathWeekPlannerScreen> {
  bool _loading = true;
  LearningPathTemplateV2? _path;
  final List<_StageInfo> _stages = [];
  bool _badgeLoading = true;
  int _remaining = 0;
  final WeeklyPlannerBoosterFeed _boosterFeed = WeeklyPlannerBoosterFeed();
  final ValueNotifier<double> _overallProgress = ValueNotifier<double>(0.0);
  Map<String, Map<String, double>>? _tagProgress;

  @override
  void initState() {
    super.initState();
    _load();
    _loadBadge();
    _boosterFeed.refresh();
    _loadOverallProgress();
    _loadTagProgress();
  }

  Future<void> _load() async {
    final path = await LearningPathOrchestrator.instance.resolve();
    await TheoryPackLibraryService.instance.loadAll();
    final list = <_StageInfo>[];
    for (final stage in path.stages) {
      if (list.length >= 7) break;
      final prog =
          await TrainingProgressService.instance.getStageProgress(stage.id);
      if (prog >= 1.0) continue;
      final pack = await PackLibraryService.instance.getById(stage.packId);
      final theory = stage.theoryPackId == null
          ? null
          : TheoryPackLibraryService.instance.getById(stage.theoryPackId!);
      list.add(_StageInfo(stage, prog, pack, theory));
    }
    if (!mounted) return;
    setState(() {
      _path = path;
      _stages
        ..clear()
        ..addAll(list);
      _loading = false;
    });
  }

  Future<void> _loadBadge() async {
    final storage = SessionStorageService.instance;
    final cached = await storage.getInt('planner_remaining');
    final time = await storage.getTimestamp('planner_remaining');
    final now = DateTime.now();
    if (cached != null &&
        time != null &&
        now.difference(time) < const Duration(minutes: 5)) {
      if (!mounted) return;
      setState(() {
        _remaining = cached;
        _badgeLoading = false;
      });
      return;
    }

    final ids = await LearningPathPlannerEngine.instance.getPlannedStageIds();
    await storage.setInt('planner_remaining', ids.length);
    if (!mounted) return;
    setState(() {
      _remaining = ids.length;
      _badgeLoading = false;
    });
  }

  Future<void> _loadOverallProgress() async {
    final tracker = LearningPathProgressTracker();
    final value = await tracker.getOverallProgress();
    if (mounted) _overallProgress.value = value;
  }

  Future<void> _loadTagProgress() async {
    final tracker = LearningPathProgressTracker();
    final map = await tracker.getTagProgressPerStage();
    if (!mounted) return;
    setState(() => _tagProgress = map);
  }

  Future<void> _open(LearningPathStageModel stage) async {
    final path = _path;
    if (path == null) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LearningPathStagePreviewScreen(path: path, stage: stage),
      ),
    );
    await _load();
    await _loadBadge();
    await _loadOverallProgress();
    await _loadTagProgress();
  }

  Future<void> _openBooster(String packId) async {
    final tpl = await PackLibraryService.instance.getById(packId);
    if (tpl == null || !mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TrainingPackPreviewScreen(template: tpl),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('План на неделю'),
            const SizedBox(width: 8),
            if (!_badgeLoading && _remaining > 0)
              Chip(
                label: Text(
                  Localizations.localeOf(context).languageCode == 'ru'
                      ? '$_remaining осталось'
                      : '$_remaining left',
                  style: const TextStyle(color: Colors.white),
                ),
                backgroundColor: Theme.of(context).colorScheme.secondary,
              ),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
              children: [
                ValueListenableBuilder<double>(
                  valueListenable: _overallProgress,
                  builder: (context, value, _) {
                    final accent = Theme.of(context).colorScheme.secondary;
                    final pct = (value.clamp(0.0, 1.0) * 100).round();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TweenAnimationBuilder<double>(
                          tween: Tween<double>(begin: 0, end: value.clamp(0.0, 1.0)),
                          duration: AppConstants.fadeDuration,
                          builder: (context, val, __) {
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: val,
                                backgroundColor: Colors.white24,
                                valueColor: AlwaysStoppedAnimation<Color>(accent),
                                minHeight: 6,
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$pct% завершено',
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        const SizedBox(height: 16),
                      ],
                    );
                  },
                ),
                const Text(
                  'План на неделю',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Вот этапы, которые стоит пройти в ближайшие дни.',
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Удачи и приятных тренировок!',
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 16),
                for (final info in _stages)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        LearningPathStageProgressCard(
                          stage: info.stage,
                          progress: info.progress,
                          pack: info.pack,
                          theoryPack: info.theoryPack,
                          tagProgress: _tagProgress?[info.stage.id],
                          onTap: () => _open(info.stage),
                        ),
                        ValueListenableBuilder<Map<String, List<BoosterSuggestion>>>(
                          valueListenable: _boosterFeed.boosters,
                          builder: (_, map, __) {
                            final list = map[info.stage.id] ?? const [];
                            if (list.isEmpty) return const SizedBox.shrink();
                            return Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Wrap(
                                spacing: 4,
                                runSpacing: -4,
                                children: [
                                  for (final b in list)
                                    TagBadge(b.tag, onTap: () => _openBooster(b.packId)),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}

class _StageInfo {
  final LearningPathStageModel stage;
  final double progress;
  final TrainingPackTemplateV2? pack;
  final TheoryPackModel? theoryPack;
  _StageInfo(this.stage, this.progress, this.pack, this.theoryPack);
}
