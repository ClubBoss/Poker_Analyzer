import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/achievement_service.dart';
import '../models/achievement_info.dart';
import '../widgets/sync_status_widget.dart';
import '../widgets/xp_progress_card.dart';

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = context.watch<AchievementService>();
    final data = service.allAchievements();
    final Map<String, List<AchievementInfo>> grouped = {};
    for (final a in data) {
      grouped.putIfAbsent(a.category, () => []).add(a);
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Achievements'),
        centerTitle: true,
        actions: [SyncStatusIcon.of(context)],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const XPProgressCard(),
          for (final entry in grouped.entries)
            ExpansionTile(
              initiallyExpanded: true,
              title: Text(entry.key,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              children: [
                for (final a in entry.value) _Item(a),
              ],
            ),
        ],
      ),
    );
  }
}

class _Item extends StatelessWidget {
  final AchievementInfo ach;
  const _Item(this.ach);

  @override
  Widget build(BuildContext context) {
    final done = ach.completed;
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
          Icon(ach.icon, color: ach.level.color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(ach.title,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(ach.description,
                    style: const TextStyle(color: Colors.white70)),
                const SizedBox(height: 4),
                Text(
                  ach.level.label,
                  style: TextStyle(
                    color: ach.level.color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (ach.progressInLevel / ach.targetInLevel)
                        .clamp(0.0, 1.0),
                    backgroundColor: Colors.white24,
                    valueColor: AlwaysStoppedAnimation<Color>(ach.level.color),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            children: [
              if (done) const Icon(Icons.check_circle, color: Colors.green),
              Text('${ach.progressInLevel}/${ach.targetInLevel}')
            ],
          )
        ],
      ),
    );
  }
}
