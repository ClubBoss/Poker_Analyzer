import 'package:flutter/material.dart';

import '../controllers/learning_path_controller.dart';
import '../models/learning_path_stage_model.dart';
import 'pack_run_screen.dart';

/// Displays stages of a learning path and allows launching a stage run.
class LearningPathScreen extends StatefulWidget {
  final String pathId;
  final LearningPathController? controller;
  const LearningPathScreen({super.key, this.pathId = 'default', this.controller});

  @override
  State<LearningPathScreen> createState() => _LearningPathScreenState();
}

class _LearningPathScreenState extends State<LearningPathScreen> {
  late final LearningPathController controller;

  @override
  void initState() {
    super.initState();
    controller = widget.controller ?? LearningPathController();
    controller.addListener(_onUpdate);
    controller.load(widget.pathId);
  }

  @override
  void dispose() {
    controller.removeListener(_onUpdate);
    if (widget.controller == null) {
      controller.dispose();
    }
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
    final pct = stage.requiredHands == 0
        ? 0.0
        : (progress.handsPlayed / stage.requiredHands).clamp(0.0, 1.0);
    String status;
    if (progress.completed) {
      status = 'Done';
    } else if (!unlocked) {
      status = 'Locked';
    } else if (progress.handsPlayed > 0) {
      status = 'In Progress';
    } else {
      status = 'Not Started';
    }
    final icon = progress.completed
        ? const Icon(Icons.check, color: Colors.green)
        : !unlocked
            ? const Icon(Icons.lock)
            : controller.currentStageId == stage.id
                ? const Icon(Icons.play_arrow)
                : const SizedBox.shrink();
    return ListTile(
      title: Text(stage.title),
      subtitle: Text('${(pct * 100).toStringAsFixed(0)}% · $status'),
      trailing: icon,
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

