import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/learning_path_template_v2.dart';
import '../models/learning_path_stage_model.dart';
import '../services/pack_library_service.dart';
import '../services/session_log_service.dart';
import '../services/training_session_launcher.dart';
import '../services/learning_path_stage_ui_status_engine.dart';
import '../services/learning_path_completion_engine.dart';
import '../models/session_log.dart';
import '../services/learning_path_progress_tracker_service.dart';
import 'learning_path_celebration_screen.dart';

/// Displays all stages of a learning path and allows launching each pack.
class LearningPathScreen extends StatefulWidget {
  final LearningPathTemplateV2 template;

  const LearningPathScreen({super.key, required this.template});

  @override
  State<LearningPathScreen> createState() => _LearningPathScreenState();
}

class _LearningPathScreenState extends State<LearningPathScreen> {
  late SessionLogService _logs;
  final _uiEngine = const LearningPathStageUIStatusEngine();
  final _progressTracker = const LearningPathProgressTrackerService();

  bool _loading = true;
  Map<String, LearningStageUIState> _stageStates = {};
  Map<String, String> _stageProgress = {};
  bool _celebrationShown = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _logs = context.read<SessionLogService>();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final aggregated = _progressTracker.aggregateLogsByPack(_logs.logs);
    final progress =
        _progressTracker.computeProgressStrings(widget.template, _logs.logs);
    final completed = <String>{};
    for (final stage in widget.template.stages) {
      final log = aggregated[stage.packId];
      final hands = (log?.correctCount ?? 0) + (log?.mistakeCount ?? 0);
      final correct = log?.correctCount ?? 0;
      final acc = hands == 0 ? 0.0 : correct / hands * 100;
      if (hands >= stage.minHands && acc >= stage.requiredAccuracy) {
        completed.add(stage.id);
      }
    }
    final states = _uiEngine.computeStageUIStates(widget.template, completed);
    setState(() {
      _stageStates = states;
      _stageProgress = progress;
      _loading = false;
    });

    final completedAll = const LearningPathCompletionEngine()
        .isCompleted(widget.template, aggregated);
    if (completedAll && !_celebrationShown && mounted) {
      _celebrationShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => LearningPathCelebrationScreen(
              path: widget.template,
            ),
          ),
        );
      });
    }
  }

  Future<void> _startStage(LearningPathStageModel stage) async {
    final template = await PackLibraryService.instance.getById(stage.packId);
    if (template == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Training pack not found')),
      );
      return;
    }
    await const TrainingSessionLauncher().launch(template);
    if (mounted) _load();
  }

  Widget _buildStageTile(LearningPathStageModel stage, int index) {
    final state = _stageStates[stage.id] ?? LearningStageUIState.locked;
    final accent = Theme.of(context).colorScheme.secondary;
    late final IconData icon;
    late final Color color;
    late final String label;
    switch (state) {
      case LearningStageUIState.done:
        icon = Icons.check_circle;
        color = Colors.green;
        label = 'Завершено';
        break;
      case LearningStageUIState.active:
        icon = Icons.lock_open;
        color = accent;
        label = 'Доступно';
        break;
      case LearningStageUIState.locked:
      default:
        icon = Icons.lock;
        color = Colors.grey;
        label = 'Заблокировано';
        break;
    }
    final grey = state == LearningStageUIState.locked ? Colors.white60 : null;
    final border = state == LearningStageUIState.active
        ? RoundedRectangleBorder(
            side: BorderSide(color: accent, width: 2),
            borderRadius: BorderRadius.circular(4),
          )
        : null;
    final progress = _stageProgress[stage.id];
    Widget? subtitle;
    if (stage.description.isNotEmpty) {
      subtitle = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(stage.description, style: TextStyle(color: grey)),
          if (progress != null)
            Text(progress, style: TextStyle(color: grey ?? Colors.white70)),
        ],
      );
    } else if (progress != null) {
      subtitle = Text(progress, style: TextStyle(color: grey));
    }
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: border,
      color:
          state == LearningStageUIState.locked ? Colors.grey.shade800 : null,
      child: ListTile(
        leading: Text('${index + 1}.', style: TextStyle(color: grey)),
        title: Text(stage.title, style: TextStyle(color: grey)),
        subtitle: subtitle,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(color: color)),
          ],
        ),
        onTap: state == LearningStageUIState.locked
            ? null
            : () => _startStage(stage),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final template = widget.template;
    final tags = template.tags;
    return Scaffold(
      appBar: AppBar(
        title: Text(template.title),
        leading: BackButton(onPressed: () => Navigator.pop(context)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.symmetric(vertical: 16),
              children: [
                if (template.description.isNotEmpty)
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      template.description,
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ),
                for (int i = 0; i < template.stages.length; i++)
                  _buildStageTile(template.stages[i], i),
                if (tags.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Wrap(
                      spacing: 8,
                      children: [
                        for (final t in tags) Chip(label: Text(t)),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}
