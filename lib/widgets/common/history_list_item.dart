import 'package:flutter/material.dart';
import '../../models/training_result.dart';
import '../../helpers/date_utils.dart';
import '../../theme/app_colors.dart';

class HistoryListItem extends StatelessWidget {
  final TrainingResult result;
  final VoidCallback? onLongPress;
  final VoidCallback? onTap;

  const HistoryListItem({
    super.key,
    required this.result,
    this.onLongPress,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accuracy = result.accuracy.toStringAsFixed(1);
    final notes = result.notes;
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
            if (notes != null && notes.isNotEmpty)
              Text(
                notes,
                style: const TextStyle(color: Colors.white54),
              ),
          ],
        ),
        trailing: Text(
          '$accuracy%',
          style: const TextStyle(color: Colors.greenAccent),
        ),
        onLongPress: onLongPress,
        onTap: onTap,
      ),
    );
  }
}
