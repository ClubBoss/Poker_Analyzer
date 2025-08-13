import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/daily_focus_recap_service.dart';
import '../services/training_session_service.dart';
import '../screens/training_session_screen.dart';

class DailyFocusRecapCard extends StatelessWidget {
  const DailyFocusRecapCard({super.key});

  @override
  Widget build(BuildContext context) {
    final service = context.watch<DailyFocusRecapService>();
    if (!service.show) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(service.summary, style: const TextStyle(color: Colors.white)),
          const SizedBox(height: 8),
          Row(
            children: [
              OutlinedButton(
                onPressed: () => service.markShown(),
                child: const Text('Позже'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () async {
                  final tpl = await service.recommendedPack();
                  await service.markShown();
                  if (tpl == null || !context.mounted) return;
                  await context
                      .read<TrainingSessionService>()
                      .startSession(tpl);
                  if (context.mounted) {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const TrainingSessionScreen()),
                    );
                  }
                },
                child: const Text('Тренировать'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
