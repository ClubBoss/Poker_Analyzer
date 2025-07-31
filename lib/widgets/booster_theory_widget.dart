import 'package:flutter/material.dart';

import '../models/theory_mini_lesson_node.dart';
import '../services/booster_slot_allocator.dart';
import 'tag_badge.dart';

/// Universal card widget displaying a theory booster suggestion.
class BoosterTheoryWidget extends StatelessWidget {
  /// Lesson to show.
  final TheoryMiniLessonNode lesson;

  /// Delivery context for this booster.
  final BoosterSlot slot;

  /// Callback when the primary action is tapped.
  final VoidCallback? onStart;

  /// Callback when the reminder action is tapped.
  final VoidCallback? onLater;

  const BoosterTheoryWidget({
    super.key,
    required this.lesson,
    required this.slot,
    this.onStart,
    this.onLater,
  });

  String _shortPreview(String text, {int max = 80}) {
    final clean = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (clean.length <= max) return clean;
    return '${clean.substring(0, max)}…';
  }

  String _icon() {
    switch (slot) {
      case BoosterSlot.recap:
        return '🔁';
      case BoosterSlot.inbox:
        return '📬';
      case BoosterSlot.goal:
        return '🎯';
      case BoosterSlot.none:
        return '';
    }
  }

  Color _accent(BuildContext context) {
    switch (slot) {
      case BoosterSlot.recap:
        return Colors.orangeAccent;
      case BoosterSlot.inbox:
        return Colors.blueAccent;
      case BoosterSlot.goal:
        return Colors.greenAccent;
      case BoosterSlot.none:
        return Theme.of(context).colorScheme.secondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = _accent(context);
    final icon = _icon();
    final tag = lesson.tags.isNotEmpty ? lesson.tags.first : null;
    final preview = _shortPreview(lesson.resolvedContent);
    final width = MediaQuery.of(context).size.width;
    final vertical = width < 350;

    final actions = [
      if (onLater != null)
        OutlinedButton(
          onPressed: onLater,
          style: OutlinedButton.styleFrom(foregroundColor: accent),
          child: const Text('Напомнить позже'),
        ),
      if (onStart != null)
        ElevatedButton(
          onPressed: onStart,
          style: ElevatedButton.styleFrom(backgroundColor: accent),
          child: const Text('Пройти сейчас'),
        ),
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (icon.isNotEmpty) Text(icon),
              if (icon.isNotEmpty) const SizedBox(width: 4),
              Expanded(
                child: Text(
                  lesson.resolvedTitle,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          if (tag != null) ...[
            const SizedBox(height: 4),
            TagBadge(tag),
          ],
          if (preview.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              preview,
              style: const TextStyle(color: Colors.white70),
            ),
          ],
          const SizedBox(height: 8),
          vertical
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (int i = 0; i < actions.length; i++) ...[
                      actions[i],
                      if (i != actions.length - 1) const SizedBox(height: 4),
                    ],
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    for (int i = 0; i < actions.length; i++) ...[
                      actions[i],
                      if (i != actions.length - 1) const SizedBox(width: 8),
                    ],
                  ],
                ),
        ],
      ),
    );
  }
}
