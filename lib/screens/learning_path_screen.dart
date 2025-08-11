import 'package:flutter/material.dart';

import '../controllers/learning_path_controller.dart';
import '../models/learning_path_stage_model.dart';
import 'pack_run_screen.dart';

/// Displays stages of a learning path and allows launching a stage run.
class LearningPathScreen extends StatefulWidget {
  final String pathId;
  const LearningPathScreen({super.key, required this.pathId});

  @override
  State<LearningPathScreen> createState() => _LearningPathScreenState();
}

class _LearningPathScreenState extends State<LearningPathScreen> {
  late final LearningPathController controller;

  @override
  void initState() {
    super.initState();
    controller = LearningPathController();
    controller.addListener(_onUpdate);
    controller.load(widget.pathId);
  }

  @override
  void dispose() {
    controller.removeListener(_onUpdate);
    controller.dispose();
    super.dispose();
  }

  void _onUpdate() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final path = controller.path;
    return Scaffold(
      appBar: AppBar(title: Text(path?.title ?? 'Learning Path')),
      body: path == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                for (final stage in path.stages) _buildStageTile(stage),
              ],
            ),
    );
  }

  Widget _buildStageTile(LearningPathStageModel stage) {
    final progress = controller.stageProgress(stage.id);
    final unlocked = controller.isStageUnlocked(stage.id);
    final statusIcon = progress.completed
        ? const Icon(Icons.check, color: Colors.green)
        : unlocked
            ? controller.currentStageId == stage.id
                ? const Icon(Icons.play_arrow)
                : const SizedBox.shrink()
            : const Icon(Icons.lock);
    return ListTile(
      title: Text(stage.title),
      subtitle: Text(
          'Hands ${progress.handsPlayed}/${stage.requiredHands} · Acc ${(progress.accuracy * 100).toStringAsFixed(0)}%'),
      trailing: statusIcon,
      onTap: unlocked
          ? () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => PackRunScreen(
                  controller: controller,
                  stage: stage,
                ),
              ));
            }
          : null,
    );
  }
}

