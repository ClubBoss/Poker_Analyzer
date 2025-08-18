import 'package:flutter/material.dart';
import '../models/achievement_basic.dart';
import 'confetti_overlay.dart';

class AchievementDialog extends StatelessWidget {
  final AchievementBasic achievement;
  const AchievementDialog({super.key, required this.achievement});

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showConfettiOverlay(context);
    });
    return AlertDialog(
      backgroundColor: Colors.black87,
      title: const Text(
        'Achievement unlocked!',
        style: TextStyle(color: Colors.white),
      ),
      content: Text(
        achievement.title,
        style: const TextStyle(color: Colors.white),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('OK'),
        ),
      ],
    );
  }
}

Future<void> showAchievementDialog(
  BuildContext context,
  AchievementBasic achievement,
) {
  return showDialog(
    context: context,
    builder: (_) => AchievementDialog(achievement: achievement),
  );
}
