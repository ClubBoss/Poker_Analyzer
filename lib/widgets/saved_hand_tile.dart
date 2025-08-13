import 'package:flutter/material.dart';

import '../models/saved_hand.dart';
import '../services/goals_service.dart';
import 'package:provider/provider.dart';

class SavedHandTile extends StatelessWidget {
  final SavedHand hand;
  final VoidCallback onTap;
  final VoidCallback? onFavoriteToggle;
  final VoidCallback? onRename;

  const SavedHandTile({
    super.key,
    required this.hand,
    required this.onTap,
    this.onFavoriteToggle,
    this.onRename,
  });

  String _formatDate(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    final y = date.year.toString();
    return '$d.$m.$y';
  }

  Widget? _buildActionWidget() {
    final action = hand.expectedAction;
    if (action == null || action.isEmpty) return null;
    final gto = hand.gtoAction;
    final isMistake = gto != null &&
        gto.isNotEmpty &&
        action.trim().toLowerCase() != gto.trim().toLowerCase();

    final row = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          action,
          style: TextStyle(
            color: isMistake ? Colors.redAccent : Colors.white70,
          ),
        ),
        if (isMistake) ...[
          const SizedBox(width: 4),
          const Icon(Icons.warning, color: Colors.redAccent, size: 16),
        ],
      ],
    );

    return isMistake
        ? Tooltip(
            message: 'Ошибка: действие не совпадает с GTO.',
            child: row,
          )
        : row;
  }

  Widget? _buildGoalProgress(BuildContext context) {
    final service = context.watch<GoalsService>();
    if (service.dailyGoalIndex != 0) return null;
    final goal = service.dailyGoal;
    if (goal == null) return null;
    final action = hand.expectedAction?.trim().toLowerCase();
    final gto = hand.gtoAction?.trim().toLowerCase();
    if (action == null || gto == null || action == gto) return null;
    final accent = Theme.of(context).colorScheme.secondary;
    final value = (goal.progress / goal.target).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Expanded(
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: value),
              duration: const Duration(milliseconds: 300),
              builder: (context, v, _) => ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: v,
                  backgroundColor: Colors.white24,
                  valueColor: AlwaysStoppedAnimation<Color>(accent),
                  minHeight: 4,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${goal.progress}/${goal.target}',
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final actionWidget = _buildActionWidget();
    return Card(
      color: const Color(0xFF2A2B2E),
      child: ListTile(
        onTap: onTap,
        leading: IconButton(
          icon: Icon(hand.isFavorite ? Icons.star : Icons.star_border),
          color: hand.isFavorite ? Colors.amber : Colors.white54,
          onPressed: onFavoriteToggle,
        ),
        title: Text(hand.name, style: const TextStyle(color: Colors.white)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${hand.heroPosition} • ${_formatDate(hand.date)}',
              style: const TextStyle(color: Colors.white70),
            ),
            if (actionWidget != null) ...[
              const SizedBox(height: 4),
              actionWidget,
            ],
            if (_buildGoalProgress(context) != null) ...[
              const SizedBox(height: 4),
              _buildGoalProgress(context)!,
            ],
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onRename != null)
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.white),
                onPressed: onRename,
              ),
            const Icon(Icons.chevron_right, color: Colors.white),
          ],
        ),
      ),
    );
  }
}
