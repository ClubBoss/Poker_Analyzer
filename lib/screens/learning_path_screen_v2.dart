import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/learning_path_template_v2.dart';
import '../models/learning_path_stage_model.dart';
import '../services/pack_library_service.dart';
import '../services/session_log_service.dart';
import '../services/training_session_launcher.dart';
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
  late Future<void> _future;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _logs = context.read<SessionLogService>();
    _future = Future.value();
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
    if (mounted) setState(() {});
  }

  Widget _buildStageTile(LearningPathStageModel stage) {
    final hands = _handsPlayed(stage.packId);
    final ratio = stage.minHands == 0 ? 1.0 : hands / stage.minHands;
    return LearningPathStageWidget(
      stage: stage,
      progress: ratio.clamp(0.0, 1.0),
      onPressed: () => _startStage(stage),
    );
  }

  @override
  Widget build(BuildContext context) {
    final template = widget.template;
    final tags = template.tags;
    return FutureBuilder(
      future: _future,
      builder: (context, snapshot) {
        return Scaffold(
          appBar: AppBar(title: Text(template.title)),
          body: snapshot.connectionState != ConnectionState.done
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  children: [
                    if (template.description.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: Text(
                          template.description,
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ),
                    for (final stage in template.stages) _buildStageTile(stage),
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
      },
    );
  }
}
