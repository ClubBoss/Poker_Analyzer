import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../helpers/color_utils.dart';
import '../models/tag_goal_progress.dart';
import '../services/tag_goal_tracker_service.dart';
import '../services/tag_service.dart';
import '../services/user_preferences_service.dart';

class ActiveTagGoalBanner extends StatefulWidget {
  final String tagId;
  const ActiveTagGoalBanner({super.key, required this.tagId});

  @override
  State<ActiveTagGoalBanner> createState() => _ActiveTagGoalBannerState();
}

class _ActiveTagGoalBannerState extends State<ActiveTagGoalBanner> {
  late Future<TagGoalProgress> _progress;

  @override
  void initState() {
    super.initState();
    _progress = TagGoalTrackerService.instance.getProgress(widget.tagId);
  }

  @override
  Widget build(BuildContext context) {
    if (!context.watch<UserPreferencesService>().showTagGoalBanner) {
      return const SizedBox.shrink();
    }
    final tagService = context.read<TagService>();
    final color = colorFromHex(tagService.colorOf(widget.tagId));
    return FutureBuilder<TagGoalProgress>(
      future: _progress,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final p = snapshot.data!;
        final hasProgress = p.trainings > 0 || p.xp > 0;
        if (!hasProgress) return const SizedBox.shrink();
        // Use XP goal if XP progress exists, otherwise trainings goal.
        final bool useXp = p.xp > 0;
        final int target = useXp ? 100 : 10;
        final int current = useXp ? p.xp : p.trainings;
        final double pct = (current / target).clamp(0.0, 1.0);
        final goalText = useXp ? '$target XP' : '$target тренировок';
        return Container(
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '#${widget.tagId}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (p.streak > 2) const Text('🔥'),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Цель: $goalText',
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: pct,
                  backgroundColor: Colors.white24,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '$current/$target',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
