import 'package:flutter/material.dart';

import '../helpers/date_utils.dart';
import '../models/training_result.dart';
import '../theme/app_colors.dart';

class TrainingDetailScreen extends StatelessWidget {
  final TrainingResult result;
  final Future<void> Function() onDelete;
  final Future<void> Function(BuildContext) onEditTags;

  const TrainingDetailScreen({
    super.key,
    required this.result,
    required this.onDelete,
    required this.onEditTags,
  });

  Future<void> _confirmDelete(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Session?'),
          content: const Text('Are you sure you want to delete this session?'),
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
    if (confirm ?? false) {
      await onDelete();
      // ignore: use_build_context_synchronously
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final accuracy = result.accuracy.toStringAsFixed(1);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Session Details'),
        centerTitle: true,
      ),
      backgroundColor: AppColors.background,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Date: ${formatDateTime(result.date)}',
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              'Total hands: ${result.total}',
              style: const TextStyle(color: Colors.white),
            ),
            Text(
              'Correct answers: ${result.correct}',
              style: const TextStyle(color: Colors.white),
            ),
            Text(
              'Accuracy: $accuracy%',
              style: const TextStyle(color: Colors.greenAccent),
            ),
            const SizedBox(height: 16),
            const Text('Tags:', style: TextStyle(color: Colors.white)),
            const SizedBox(height: 8),
            if (result.tags.isEmpty)
              const Text('No tags', style: TextStyle(color: Colors.white70))
            else
              Wrap(
                spacing: 4,
                children: [
                  for (final tag in result.tags)
                    Chip(
                      label: Text(tag),
                    ),
                ],
              ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      await onEditTags(context);
                      // ignore: use_build_context_synchronously
                      Navigator.pop(context);
                    },
                    child: const Text('Edit Tags'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    onPressed: () => _confirmDelete(context),
                    child: const Text('Delete'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
