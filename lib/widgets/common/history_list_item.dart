import 'package:flutter/material.dart';
import '../../models/training_result.dart';
import '../../helpers/date_utils.dart';
import '../../theme/app_colors.dart';
import '../../services/tag_service.dart';
import '../../helpers/color_utils.dart';
import 'package:provider/provider.dart';

class HistoryListItem extends StatelessWidget {
  final TrainingResult result;
  final VoidCallback? onLongPress;
  final VoidCallback? onTap;
  final VoidCallback? onTagTap;
  final VoidCallback? onDelete;

  const HistoryListItem({
    super.key,
    required this.result,
    this.onLongPress,
    this.onTap,
    this.onTagTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final accuracy = result.accuracy.toStringAsFixed(1);
    final notes = result.notes;
    final comment = result.comment;
    final tags = result.tags;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        title: Text(
          formatDateTime(result.date),
          style: const TextStyle(color: Colors.white),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Correct: ${result.correct} / ${result.total}',
              style: const TextStyle(color: Colors.white70),
            ),
            if (comment != null && comment.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  comment,
                  style: const TextStyle(color: Colors.white60),
                ),
              ),
            if (tags.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Wrap(
                  spacing: 4,
                  children: [
                    for (final t in tags)
                      Consumer<TagService>(
                        builder: (context, service, _) => Chip(
                          label: Text(t),
                          backgroundColor: colorFromHex(service.colorOf(t)),
                        ),
                      )
                  ],
                ),
              ),
            if (notes != null && notes.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  notes,
                  style: const TextStyle(color: Colors.white54),
                ),
              ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$accuracy%',
              style: const TextStyle(color: Colors.greenAccent),
            ),
            IconButton(
              icon: const Icon(Icons.label_outline, color: Colors.white70),
              tooltip: 'Edit Tags',
              onPressed: onTagTap,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.white70),
              tooltip: 'Delete Session',
              onPressed: onDelete,
            ),
          ],
        ),
        onLongPress: onLongPress,
        onTap: onTap,
      ),
    );
  }
}
