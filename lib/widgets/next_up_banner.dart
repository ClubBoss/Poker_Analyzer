import 'package:flutter/material.dart';

import '../controllers/learning_path_controller.dart';
import '../models/learning_path_stage_model.dart';
import '../screens/pack_run_screen.dart';

/// Floating banner that deep-links to the current stage.
class NextUpBanner extends StatelessWidget {
  final LearningPathController controller;
  const NextUpBanner({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final stageId = controller.currentStageId;
        if (stageId == null) return const SizedBox.shrink();
        LearningPathStageModel? stage;
        try {
          stage = controller.path?.stages.firstWhere((s) => s.id == stageId);
        } catch (_) {
          stage = null;
        }
        if (stage == null) return const SizedBox.shrink();
        return SafeArea(
          child: Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: FloatingActionButton.extended(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          PackRunScreen(controller: controller, stage: stage!),
                    ),
                  );
                },
                icon: const Icon(Icons.play_arrow),
                label: Text('Next: ' + stage.title),
              ),
            ),
          ),
        );
      },
    );
  }
}
