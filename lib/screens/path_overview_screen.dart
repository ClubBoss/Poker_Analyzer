import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/learning_path_stage_model.dart';
import '../models/learning_path_template_v2.dart';
import '../services/learning_path_registry_service.dart';
import '../services/learning_path_progress_engine.dart' as engine_v1;
import '../services/pack_library_service.dart';
import '../services/session_log_service.dart';
import '../services/training_session_service.dart';

/// Detailed overview of a learning path with progress and list of stages.
class PathOverviewScreen extends StatefulWidget {
  final String pathId;
  const PathOverviewScreen({super.key, required this.pathId});

  @override
  State<PathOverviewScreen> createState() => _PathOverviewScreenState();
}

class _PathOverviewScreenState extends State<PathOverviewScreen> {
  LearningPathTemplateV2? _template;
  double _progress = 0.0;
  Map<String, int> _handsByPack = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final registry = LearningPathRegistryService.instance;
    final logs = context.read<SessionLogService>();
    await logs.load();
    await registry.loadAll();
    final template = registry.findById(widget.pathId);
    double prog = 0.0;
    if (template != null) {
      final engine = engine_v1.LearningPathProgressEngine(
        logs: logs,
      );
      prog = await engine.getPathProgress(template.id);
    }
    final hands = <String, int>{};
    for (final log in logs.logs) {
      final count = log.correctCount + log.mistakeCount;
      hands.update(log.templateId, (v) => v + count, ifAbsent: () => count);
    }
    if (mounted) {
      setState(() {
        _template = template;
        _progress = prog;
        _handsByPack = hands;
        _loading = false;
      });
    }
  }

  int _stageHands(LearningPathStageModel stage) {
    if (stage.subStages.isEmpty) {
      return _handsByPack[stage.packId] ?? 0;
    }
    var total = 0;
    for (final s in stage.subStages) {
      total += _handsByPack[s.packId] ?? 0;
    }
    return total;
  }

  bool _stageCompleted(LearningPathStageModel stage) {
    if (stage.subStages.isEmpty) {
      final hands = _handsByPack[stage.packId] ?? 0;
      return hands >= stage.minHands;
    }
    for (final sub in stage.subStages) {
      final hands = _handsByPack[sub.packId] ?? 0;
      if (hands < sub.minHands) return false;
    }
    return true;
  }

  LearningPathStageModel? get _nextStage {
    final tpl = _template;
    if (tpl == null) return null;
    for (final stage in tpl.stages) {
      if (!_stageCompleted(stage)) return stage;
    }
    return null;
  }

  Future<void> _startLearning() async {
    final stage = _nextStage;
    if (stage == null) return;
    final pack = await PackLibraryService.instance.getById(stage.packId);
    if (pack == null) return;
    await context.read<TrainingSessionService>().startSession(pack);
  }

  @override
  Widget build(BuildContext context) {
    final tpl = _template;
    final accent = Theme.of(context).colorScheme.secondary;
    return Scaffold(
      appBar: AppBar(title: Text(tpl?.title ?? 'Path')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : tpl == null
              ? const Center(child: Text('Path not found'))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (tpl.coverAsset != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(
                          tpl.coverAsset!,
                          fit: BoxFit.cover,
                        ),
                      ),
                    if (tpl.description.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        tpl.description,
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: _progress.clamp(0.0, 1.0),
                        backgroundColor: Colors.white24,
                        valueColor: AlwaysStoppedAnimation<Color>(accent),
                        minHeight: 6,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text('${(_progress * 100).round()}%',
                        style: const TextStyle(color: Colors.white70)),
                    const SizedBox(height: 12),
                    for (int i = 0; i < tpl.stages.length; i++)
                      _buildStageTile(tpl.stages[i], i + 1),
                    const SizedBox(height: 20),
                    Align(
                      alignment: Alignment.center,
                      child: ElevatedButton(
                        onPressed: _startLearning,
                        child: Text(
                            _progress > 0 ? 'Продолжить обучение' : 'Начать'),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildStageTile(LearningPathStageModel stage, int index) {
    final hands = _stageHands(stage);
    final done = _stageCompleted(stage);
    IconData icon;
    Color color;
    if (done) {
      icon = Icons.check_circle;
      color = Colors.green;
    } else if (hands > 0) {
      icon = Icons.play_arrow;
      color = Theme.of(context).colorScheme.secondary;
    } else {
      icon = Icons.radio_button_unchecked;
      color = Colors.grey;
    }
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text('$index. ${stage.title}'),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (stage.description.isNotEmpty) Text(stage.description),
          if (stage.objectives.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Навыки: ${stage.objectives.join(', ')}',
                style: const TextStyle(fontSize: 12, color: Colors.white70),
              ),
            ),
        ],
      ),
      trailing: Text('$hands / ${stage.minHands}'),
    );
  }
}
