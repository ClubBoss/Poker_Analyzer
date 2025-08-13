import 'package:flutter/material.dart';
import '../models/achievement_info.dart';
import '../screens/achievement_detail_screen.dart';

class AchievementTile extends StatelessWidget {
  final AchievementInfo achievement;
  final String heroTag;

  const AchievementTile({
    super.key,
    required this.achievement,
    required this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    final levelColor = achievement.level.color;
    final completed = achievement.completed;
    Widget icon = Icon(achievement.icon, size: 40, color: levelColor);
    if (!completed) {
      icon = ColorFiltered(
        colorFilter: const ColorFilter.mode(Colors.grey, BlendMode.saturation),
        child: icon,
      );
    }
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AchievementDetailScreen(
              achievement: achievement,
              heroTag: heroTag,
            ),
          ),
        );
      },
      child: Hero(
        tag: heroTag,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[850],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              icon,
              const SizedBox(height: 8),
              Text(
                achievement.title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value:
                      (achievement.progressInLevel / achievement.targetInLevel)
                          .clamp(0.0, 1.0),
                  backgroundColor: Colors.white24,
                  valueColor: AlwaysStoppedAnimation<Color>(levelColor),
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${achievement.progressInLevel}/${achievement.targetInLevel}',
                    ),
                  ),
                  if (completed)
                    const Icon(Icons.check_circle, color: Colors.green),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
