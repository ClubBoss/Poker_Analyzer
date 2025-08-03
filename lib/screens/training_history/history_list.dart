import 'package:flutter/material.dart';

import '../../models/training_result.dart';
import '../../widgets/common/history_list_item.dart';

class HistoryList extends StatelessWidget {
  final List<TrainingResult> sessions;
  final Future<void> Function(TrainingResult result) onDelete;
  final void Function(TrainingResult result) onLongPress;
  final void Function(TrainingResult result) onTap;
  final void Function(TrainingResult result) onTagTap;

  const HistoryList({
    super.key,
    required this.sessions,
    required this.onDelete,
    required this.onLongPress,
    required this.onTap,
    required this.onTagTap,
  });

  Future<bool?> _confirmDelete(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Session?'),
          content:
              const Text('Are you sure you want to delete this session?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final result = sessions[index];
        return Dismissible(
          key: ValueKey(result.date.toIso8601String()),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            color: Colors.red,
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          confirmDismiss: (_) => _confirmDelete(context),
          onDismissed: (_) => onDelete(result),
          child: HistoryListItem(
            result: result,
            onLongPress: () => onLongPress(result),
            onTap: () => onTap(result),
            onTagTap: () => onTagTap(result),
            onDelete: () async {
              final confirm = await _confirmDelete(context);
              if (confirm ?? false) {
                await onDelete(result);
              }
            },
          ),
        );
      },
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemCount: sessions.length,
    );
  }
}
