import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/tag_insight_reminder_engine.dart';
import '../services/skill_loss_detector.dart';
import '../screens/tag_insight_screen.dart';

/// Card widget showing decaying skill tags with quick review action.
class TagInsightReminderCard extends StatefulWidget {
  const TagInsightReminderCard({super.key});

  @override
  State<TagInsightReminderCard> createState() => _TagInsightReminderCardState();
}

class _TagInsightReminderCardState extends State<TagInsightReminderCard> {
  late Future<List<SkillLoss>> _future;

  @override
  void initState() {
    super.initState();
    _future = context.read<TagInsightReminderEngine>().loadLosses();
  }

  void _open(String tag) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TagInsightScreen(tag: tag)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.secondary;
    return FutureBuilder<List<SkillLoss>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const SizedBox.shrink();
        }
        final losses = snapshot.data ?? [];
        if (losses.isEmpty) return const SizedBox.shrink();
        final display = losses.take(2).toList();
        return Container(
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[850],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: accent),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '⚠ Skill Loss Alert',
                style: TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              for (final l in display)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _open(l.tag),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '⚠ Skill drop on ${l.tag}: ↓${(l.drop * 100).toStringAsFixed(1)}%',
                                style: const TextStyle(color: Colors.white),
                              ),
                              if (l.trend.isNotEmpty)
                                Text(
                                  l.trend,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () => _open(l.tag),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accent,
                        ),
                        child: const Text('Review now'),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
