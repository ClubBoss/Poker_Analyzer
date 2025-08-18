import 'package:flutter/material.dart';
import '../models/achievement_info.dart';

class AchievementDetailScreen extends StatelessWidget {
  final AchievementInfo achievement;
  final String heroTag;

  const AchievementDetailScreen({
    super.key,
    required this.achievement,
    required this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    final color = achievement.level.color;
    return Scaffold(
      appBar: AppBar(title: Text(achievement.title), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Hero(
                tag: heroTag,
                child: Icon(achievement.icon, size: 80, color: color),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              achievement.description,
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 24),
            Text(
              achievement.level.label,
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (achievement.progressInLevel / achievement.targetInLevel)
                    .clamp(0.0, 1.0),
                backgroundColor: Colors.white24,
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 8),
            Text('${achievement.progressInLevel}/${achievement.targetInLevel}'),
          ],
        ),
      ),
    );
  }
}
