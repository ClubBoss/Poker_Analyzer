import 'package:flutter/material.dart';

import '../models/saved_hand.dart';

class SavedHandTile extends StatelessWidget {
  final SavedHand hand;
  final VoidCallback onTap;
  final VoidCallback? onFavoriteToggle;

  const SavedHandTile({
    super.key,
    required this.hand,
    required this.onTap,
    this.onFavoriteToggle,
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
    final isMistake = gto != null && gto.isNotEmpty &&
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
          ],
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.white),
      ),
    );
  }
}
