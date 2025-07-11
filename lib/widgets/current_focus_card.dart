import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/adaptive_focus_service.dart';
import '../services/weak_spot_recommendation_service.dart';
import '../services/training_session_service.dart';
import '../screens/training_session_screen.dart';

class CurrentFocusCard extends StatelessWidget {
  const CurrentFocusCard({super.key});

  @override
  Widget build(BuildContext context) {
    final focus = context.watch<AdaptiveFocusService>().current;
    if (focus == null) return const SizedBox.shrink();
    final loss = focus.evShort < 0 ? -focus.evShort : 0;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.flag, color: Colors.purpleAccent),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Фокус: ${focus.position.label} – минус ${loss.toStringAsFixed(2)}bb на спот',
              style: const TextStyle(color: Colors.white),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () async {
              final tpl = await context
                  .read<WeakSpotRecommendationService>()
                  .buildPack(focus.position);
              if (tpl == null) return;
              await context.read<TrainingSessionService>().startSession(tpl);
              if (context.mounted) {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const TrainingSessionScreen()),
                );
              }
            },
            child: const Text('Тренировать'),
          )
        ],
      ),
    );
  }
}
