import 'package:flutter/material.dart';

import '../models/learning_path_stage_model.dart';
import '../models/learning_track_progress_model.dart';
import 'tag_badge.dart';

/// Tile representing a stage of a learning path.
class LearningStageTile extends StatelessWidget {
  final LearningPathStageModel stage;
  final StageStatus status;
  final String subtitle;
  final VoidCallback? onTap;

  const LearningStageTile({
    super.key,
    required this.stage,
    required this.status,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final locked = status == StageStatus.locked;
    final completed = status == StageStatus.completed;

    Widget trailing;
    if (completed) {
      trailing = const Icon(Icons.check_circle, color: Colors.green);
    } else if (locked) {
      trailing = const Icon(Icons.lock, color: Colors.grey);
    } else {
      trailing = ElevatedButton(
        onPressed: onTap,
        child: const Text('Начать'),
      );
    }

    final grey = locked ? Colors.white60 : null;

    return Card(
      color: locked ? Colors.grey.shade800 : null,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        title: Text(stage.title, style: TextStyle(color: grey)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (stage.description.isNotEmpty)
              Text(stage.description, style: TextStyle(color: grey)),
            Text(subtitle, style: TextStyle(color: grey, fontSize: 12)),
            if (stage.tags.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Wrap(
                  spacing: 4,
                  runSpacing: -4,
                  children: [for (final t in stage.tags.take(3)) TagBadge(t)],
                ),
              ),
          ],
        ),
        trailing: trailing,
        onTap: locked ? null : onTap,
      ),
    );
  }
}

