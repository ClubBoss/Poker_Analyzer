import 'package:flutter/material.dart';

import '../services/booster_queue_service.dart';
import '../services/decay_booster_training_launcher.dart';

/// Small badge showing when decay boosters are queued.
class DecayBoosterQueueIndicator extends StatelessWidget {
  final BoosterQueueService queue;
  final DecayBoosterTrainingLauncher launcher;

  const DecayBoosterQueueIndicator({
    super.key,
    this.queue = BoosterQueueService.instance,
    this.launcher = const DecayBoosterTrainingLauncher(),
  });

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.secondary;
    return ValueListenableBuilder<int>(
      valueListenable: queue.queueLength,
      builder: (context, value, _) {
        if (value == 0) return const SizedBox.shrink();
        return GestureDetector(
          onTap: launcher.launch,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              '\uD83D\uDD25 Booster Ready',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
    );
  }
}
