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

  @override
  Widget build(BuildContext context) {
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
        subtitle: Text(
          '${hand.heroPosition} • ${_formatDate(hand.date)}',
          style: const TextStyle(color: Colors.white70),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.white),
      ),
    );
  }
}
