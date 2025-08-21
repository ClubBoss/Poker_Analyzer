import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/booster_queue_service.dart';
import '../services/decay_booster_training_launcher.dart';
import '../services/training_session_service.dart';
import '../screens/v2/training_pack_play_screen.dart';

/// Consolidates all decay booster reminders into a single entry point.
class DecayBoosterShortcutConsolidatorWidget extends StatelessWidget {
  final BoosterQueueService queue;
  final DecayBoosterTrainingLauncher launcher;

  const DecayBoosterShortcutConsolidatorWidget({
    super.key,
    this.queue = BoosterQueueService.instance,
    this.launcher = const DecayBoosterTrainingLauncher(),
  });

  @override
  Widget build(BuildContext context) {
    final sessionService = context.watch<TrainingSessionService>();
    return ValueListenableBuilder<int>(
      valueListenable: queue.queueLength,
      builder: (context, count, _) {
        final session = sessionService.session;
        final template = sessionService.template;
        final isBoosterActive = session != null &&
            session.completedAt == null &&
            (template?.tags.contains('decayBooster') ?? false);
        if (isBoosterActive) {
          return _buildButton(
            context,
            label: 'Resume Booster Session',
            onPressed: () async {
              final tpl = sessionService.template;
              if (tpl == null) return;
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      TrainingPackPlayScreen(template: tpl, original: tpl),
                ),
              );
            },
          );
        }
        if (count > 0) {
          return _buildButton(
            context,
            label: 'Review Decayed Tags',
            onPressed: () async {
              await launcher.launch();
            },
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildButton(
    BuildContext context, {
    required String label,
    required VoidCallback onPressed,
  }) {
    final accent = Theme.of(context).colorScheme.secondary;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        child: Text(label),
      ),
    );
  }
}
