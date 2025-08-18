import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/next_step_engine.dart';
import '../screens/mistake_repeat_screen.dart';
import '../screens/goals_overview_screen.dart';
import '../screens/spot_of_the_day_screen.dart';

class NextStepCard extends StatelessWidget {
  const NextStepCard({super.key});

  void _open(BuildContext context, String route) {
    switch (route) {
      case '/mistake_repeat':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MistakeRepeatScreen()),
        );
        break;
      case '/goals':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const GoalsOverviewScreen()),
        );
        break;
      case '/spot_of_the_day':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SpotOfTheDayScreen()),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final suggestion = context.watch<NextStepEngine>().suggestion;
    if (suggestion == null) return const SizedBox.shrink();
    final accent = Theme.of(context).colorScheme.secondary;
    return GestureDetector(
      onTap: () => _open(context, suggestion.targetRoute),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[850],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(suggestion.icon, color: accent),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    suggestion.title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    suggestion.message,
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white70),
          ],
        ),
      ),
    );
  }
}
