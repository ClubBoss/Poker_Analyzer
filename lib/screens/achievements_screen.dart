import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/achievement_engine.dart';
import '../services/user_action_logger.dart';
import '../widgets/sync_status_widget.dart';

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  @override
  void initState() {
    super.initState();
    UserActionLogger.instance.log('viewed_achievements');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AchievementEngine>().markSeen();
    });
  }

  @override
  Widget build(BuildContext context) {
    final engine = context.watch<AchievementEngine>();
    final accent = Theme.of(context).colorScheme.secondary;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Achievements'),
        centerTitle: true,
        actions: [SyncStatusIcon.of(context)],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: engine.achievements.length,
        itemBuilder: (context, index) {
          final a = engine.achievements[index];
          final done = a.completed;
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[850],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(a.icon, color: accent),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(a.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(a.description, style: const TextStyle(color: Colors.white70)),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: (a.progress / a.target).clamp(0.0, 1.0),
                          backgroundColor: Colors.white24,
                          valueColor: AlwaysStoppedAnimation<Color>(accent),
                          minHeight: 6,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  children: [
                    Text(done ? '✅' : '⏳'),
                    const SizedBox(height: 4),
                    Text('${a.progress}/${a.target}')
                  ],
                )
              ],
            ),
          );
        },
      ),
    );
  }
}
