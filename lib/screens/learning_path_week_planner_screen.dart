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
import '../widgets/learning_path_stage_progress_card.dart';
import '../widgets/tag_badge.dart';
import 'learning_path_stage_preview_screen.dart';
import 'training_pack_preview_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _load();
    _loadBadge();
    _boosterFeed.refresh();
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
    final ids = await LearningPathPlannerEngine.instance.getPlannedStageIds();
    if (!mounted) return;
    setState(() {
      _remaining = ids.length;
      _badgeLoading = false;
    });
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
              padding: const EdgeInsets.all(16),
              children: [
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
