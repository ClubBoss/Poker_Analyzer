import 'package:flutter/material.dart';

import '../models/learning_path_node_v2.dart';
import '../models/v2/training_pack_template_v2.dart';
import '../services/mini_lesson_library_service.dart';

/// Reusable tile displaying a learning path node.
class PathNodeTile extends StatelessWidget {
  final LearningPathNodeV2 node;
  final bool isCurrent;
  final bool isCompleted;
  final bool isBlocked;
  final TrainingPackTemplateV2? pack;
  final VoidCallback onTap;

  const PathNodeTile({
    super.key,
    required this.node,
    required this.isCurrent,
    required this.isCompleted,
    required this.isBlocked,
    this.pack,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    String title;
    Widget icon;
    if (node.type == LearningPathNodeType.theory) {
      final lesson =
          MiniLessonLibraryService.instance.getById(node.miniLessonId ?? '');
      title = lesson?.resolvedTitle ?? node.miniLessonId ?? '';
      icon = const Text('📘', style: TextStyle(fontSize: 24));
    } else {
      title = pack?.name ??
          node.trainingPackTemplateId ??
          node.dynamicPackId ??
          '';
      icon = const Text('🃏', style: TextStyle(fontSize: 24));
    }

    String? subtitle;
    if (isCompleted) {
      subtitle = 'Completed';
    } else if (isCurrent) {
      subtitle = 'Current';
    } else if (isBlocked) {
      subtitle = 'Locked';
    }

    final border = isCurrent
        ? Border.all(color: Theme.of(context).colorScheme.primary, width: 2)
        : null;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: border ?? BorderSide.none,
      ),
      child: ListTile(
        leading: icon,
        title: Text(title),
        subtitle: subtitle != null ? Text(subtitle) : null,
        onTap: onTap,
      ),
    );
  }
}

