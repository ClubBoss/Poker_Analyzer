import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/training/engine/training_type_engine.dart';
import '../models/v2/training_pack_template.dart';
import '../services/training_session_service.dart';
import '../screens/training_session_screen.dart';

/// Banner suggesting a training pack for the player's weakest [TrainingType].
///
/// Displays the type label and the first available pack in the library for that
/// type, offering a quick start button to launch a session.
class TrainingTypeGapPromptBanner extends StatelessWidget {
  /// Weak training type that should be improved.
  final TrainingType type;

  /// Pack matching the [type] that will be used to start the session.
  final TrainingPackTemplate pack;

  const TrainingTypeGapPromptBanner({super.key, required this.type, required this.pack});

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.secondary;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.redAccent),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('📉 Слабый тип: ${type.label}',
              style: const TextStyle(color: Colors.white)),
          const SizedBox(height: 4),
          Text('🃏 Пак: ${pack.name}',
              style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: () async {
                await context.read<TrainingSessionService>().startSession(pack);
                if (context.mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const TrainingSessionScreen()),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: accent),
              child: const Text('Начать тренировку'),
            ),
          ),
        ],
      ),
    );
  }
}
