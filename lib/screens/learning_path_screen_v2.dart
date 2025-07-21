import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/learning_path_template_v2.dart';
import '../models/learning_path_stage_model.dart';
import '../services/pack_library_service.dart';
import '../services/session_log_service.dart';
import '../services/training_session_launcher.dart';
import '../services/learning_path_stage_progress_engine.dart';
import '../services/learning_path_stage_unlock_engine.dart';
import '../widgets/learning_path_stage_widget.dart';

/// Displays all stages of a learning path and allows launching each pack.
class LearningPathScreen extends StatefulWidget {
  final LearningPathTemplateV2 template;

  const LearningPathScreen({super.key, required this.template});

  @override
  State<LearningPathScreen> createState() => _LearningPathScreenState();
}

class _LearningPathScreenState extends State<LearningPathScreen> {
  late SessionLogService _logs;
  late LearningPathStageProgressEngine _progressEngine;
  final _unlockEngine = const LearningPathStageUnlockEngine();

  bool _loading = true;
  Map<String, double> _progress = {};
  Set<String> _unlocked = {};
  Set<String> _completed = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _logs = context.read<SessionLogService>();
    _progressEngine = LearningPathStageProgressEngine(logs: _logs);
    _load();
  }

  int _handsPlayed(String packId) {
    var hands = 0;
    for (final log in _logs.logs) {
      if (log.templateId == packId) {
        hands += log.correctCount + log.mistakeCount;
      }
    }
    return hands;
  }

  double _accuracy(String packId) {
    var hands = 0;
    var correct = 0;
    for (final log in _logs.logs) {
      if (log.templateId == packId) {
        hands += log.correctCount + log.mistakeCount;
        correct += log.correctCount;
      }
    }
    if (hands == 0) return 0.0;
    return correct / hands * 100;
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final map = await _progressEngine.getStageProgress(widget.template);
    final completed = <String>{};
    for (final stage in widget.template.stages) {
      final hands = _handsPlayed(stage.packId);
      final acc = _accuracy(stage.packId);
      if (hands >= stage.minHands && acc >= stage.requiredAccuracy) {
        completed.add(stage.id);
      }
    }
    final unlocked = <String>{};
    for (final stage in widget.template.stages) {
      if (_unlockEngine.isStageUnlocked(widget.template, stage.id, completed)) {
        unlocked.add(stage.id);
      }
    }
    setState(() {
      _progress = {
        for (final stage in widget.template.stages)
          stage.id: map[stage.packId] ?? 0.0
      };
      _completed = completed;
      _unlocked = unlocked;
      _loading = false;
    });
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

  Widget _buildStageTile(LearningPathStageModel stage, bool recommended) {
    final hands = _handsPlayed(stage.packId);
    final ratio = _progress[stage.id] ??
        (stage.minHands == 0 ? 1.0 : hands / stage.minHands);
    final unlocked = _unlocked.contains(stage.id);
    return LearningPathStageWidget(
      stage: stage,
      progress: ratio.clamp(0.0, 1.0),
      handsPlayed: hands,
      unlocked: unlocked,
      recommended: recommended,
      onPressed: () => _startStage(stage),
    );
  }

  @override
  Widget build(BuildContext context) {
    final template = widget.template;
    final tags = template.tags;
    String? recommended;
    for (final s in template.stages) {
      if (_unlocked.contains(s.id) && !_completed.contains(s.id)) {
        recommended = s.id;
        break;
      }
    }
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
                for (final stage in template.stages)
                  _buildStageTile(stage, stage.id == recommended),
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
