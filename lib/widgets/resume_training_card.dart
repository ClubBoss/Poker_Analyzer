import 'package:flutter/material.dart';
import '../services/training_pack_play_controller.dart';

class ResumeTrainingCard extends StatelessWidget {
  final TrainingPackPlayController controller;
  const ResumeTrainingCard({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final tpl = controller.template;
    if (tpl == null) return const SizedBox.shrink();
    final accent = Theme.of(context).colorScheme.secondary;
    return GestureDetector(
      onTap: () => controller.resume(context),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[850],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          '🔥 Continue training: ${tpl.name} · ${controller.progress}%',
          style: TextStyle(color: accent, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
