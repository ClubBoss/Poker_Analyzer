import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/achievement_service.dart';
import '../screens/achievements_catalog_screen.dart';

class AchievementsCard extends StatelessWidget {
  const AchievementsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final service = context.watch<AchievementService>();
    final unlocked = service.achievements.where((a) => a.unlocked).length;
    final total = service.achievements.length;
    final accent = Theme.of(context).colorScheme.secondary;
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AchievementsCatalogScreen()),
        );
      },
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[850],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.emoji_events, color: accent),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Achievements',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Text(
              '$unlocked/$total',
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}
