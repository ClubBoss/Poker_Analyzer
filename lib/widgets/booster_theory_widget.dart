import 'package:flutter/material.dart';

import '../models/theory_mini_lesson_node.dart';
import '../services/booster_slot_allocator.dart';
import '../theme/app_colors.dart';
import 'tag_badge.dart';

/// Universal card widget displaying a theory booster suggestion.
class BoosterTheoryWidget extends StatelessWidget {
  /// Lesson to show.
  final TheoryMiniLessonNode lesson;

  /// Delivery context for this booster.
  final BoosterSlot slot;

  /// Callback when the card is tapped.
  final VoidCallback? onTap;

  /// Callback when the action button is pressed.
  final VoidCallback? onActionTap;

  /// Label for the action button.
  final String actionLabel;

  const BoosterTheoryWidget({
    super.key,
    required this.lesson,
    required this.slot,
    this.onTap,
    this.onActionTap,
    this.actionLabel = 'Пройти',
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

  String _slotLabel() {
    switch (slot) {
      case BoosterSlot.inbox:
        return 'Inbox';
      case BoosterSlot.recap:
        return 'Recap';
      case BoosterSlot.goal:
        return 'Goal';
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

  Color _cardColor(BuildContext context) {
    final base = Theme.of(context).brightness == Brightness.dark
        ? AppColors.darkCard
        : AppColors.lightCard;
    switch (slot) {
      case BoosterSlot.recap:
        return Colors.amber.withValues(alpha: 0.15);
      default:
        return base;
    }
  }

  Border? _cardBorder() {
    switch (slot) {
      case BoosterSlot.inbox:
        return Border.all(color: Colors.blueAccent, width: 2);
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = _accent(context);
    final icon = _icon();
    final slotLabel = _slotLabel();
    final tag = lesson.tags.isNotEmpty ? lesson.tags.first : null;
    final preview = _shortPreview(lesson.resolvedContent);
    final width = MediaQuery.of(context).size.width;
    final vertical = width < 350;

    final actions = [
      if (onActionTap != null)
        ElevatedButton(
          onPressed: onActionTap,
          style: ElevatedButton.styleFrom(backgroundColor: accent),
          child: Text(actionLabel),
        ),
    ];

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      color: _cardColor(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: _cardBorder() ?? BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (slot != BoosterSlot.none)
                Text('$icon $slotLabel',
                    style: TextStyle(color: accent, fontWeight: FontWeight.bold)),
              if (slot != BoosterSlot.none) const SizedBox(width: 4),
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
        ),
      ),
    );
  }
}
