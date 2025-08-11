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
          stage = controller.path?.stages
              .firstWhere((s) => s.id == stageId);
        } catch (_) {
          stage = null;
        }
        if (stage == null) return const SizedBox.shrink();
        final progress = controller.stageProgress(stage.id);
        final pct = stage.requiredHands == 0
            ? 0.0
            : (progress.handsPlayed / stage.requiredHands)
                .clamp(0.0, 1.0);
        final btnLabel = progress.handsPlayed > 0 ? 'Resume' : 'Start';
        return SafeArea(
          child: Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Material(
                elevation: 6,
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(stage.title,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold)),
                          Text('${(pct * 100).toStringAsFixed(0)}%'),
                        ],
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).push(MaterialPageRoute(
                              builder: (_) => PackRunScreen(
                                    controller: controller,
                                    stage: stage!,
                                  )));
                        },
                        child: Text(btnLabel),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

