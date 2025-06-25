import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/achievement_engine.dart';
import '../theme/app_colors.dart';

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final data = context.watch<AchievementEngine>().achievements;
    final accent = Theme.of(context).colorScheme.secondary;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Достижения'),
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: data.length,
        itemBuilder: (context, index) {
          final item = data[index];
          final unlocked = item.completed;
          final color = unlocked ? Colors.white : Colors.white54;
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListTile(
              leading: Icon(item.icon, color: accent),
              title: Text(
                item.title,
                style: TextStyle(color: color, fontWeight: FontWeight.bold),
              ),
              trailing: Icon(
                unlocked ? Icons.check_circle : Icons.lock,
                color: unlocked ? Colors.green : Colors.grey,
              ),
              subtitle: LinearProgressIndicator(
                value: (item.progress / item.target).clamp(0.0, 1.0),
                backgroundColor: Colors.white24,
                valueColor: AlwaysStoppedAnimation<Color>(accent),
              ),
            ),
          );
        },
      ),
    );
  }
}
