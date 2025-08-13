import 'package:flutter/material.dart';
import '../../helpers/date_utils.dart';
import '../../helpers/accuracy_utils.dart';
import '../../models/training_pack.dart';

class SessionListItem extends StatelessWidget {
  final String packName;
  final String description;
  final TrainingSessionResult result;
  final VoidCallback onTap;
  final VoidCallback onShowOptions;

  const SessionListItem({
    super.key,
    required this.packName,
    required this.description,
    required this.result,
    required this.onTap,
    required this.onShowOptions,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF2A2B2E),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onLongPress: onShowOptions,
                          child: Text(
                            packName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onLongPress: onShowOptions,
                        child: const Icon(
                          Icons.edit,
                          color: Colors.white70,
                          size: 16,
                        ),
                      ),
                    ],
                  ),
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    formatDateTime(result.date),
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${result.correct}/${result.total}',
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 4),
                Text(
                  result.total > 0
                      ? '${calculateAccuracy(result.correct, result.total).toStringAsFixed(0)}%'
                      : '0%',
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
