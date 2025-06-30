import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/v2/training_action.dart';
import '../theme/app_colors.dart';

class TrainingActionLogDialog extends StatelessWidget {
  final List<TrainingAction> actions;
  const TrainingActionLogDialog({super.key, required this.actions});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Session Actions'),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: actions.isEmpty
            ? const Center(child: Text('No actions', style: TextStyle(color: Colors.white70)))
            : ListView.builder(
                itemCount: actions.length,
                itemBuilder: (context, index) {
                  final a = actions[index];
                  final color = a.isCorrect ? AppColors.cardBackground : AppColors.errorBg;
                  final time = DateFormat('HH:mm:ss', Intl.getCurrentLocale()).format(a.timestamp);
                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Text('${index + 1}', style: const TextStyle(color: Colors.white)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(a.chosenAction,
                              style: TextStyle(color: a.isCorrect ? Colors.white : Colors.red)),
                        ),
                        const SizedBox(width: 8),
                        Icon(a.isCorrect ? Icons.check : Icons.close,
                            color: a.isCorrect ? Colors.green : Colors.red, size: 16),
                        const SizedBox(width: 8),
                        Text(time, style: const TextStyle(color: Colors.white70)),
                      ],
                    ),
                  );
                },
              ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
      ],
    );
  }
}

Future<void> showTrainingActionLogDialog(BuildContext context, List<TrainingAction> actions) {
  return showDialog(
    context: context,
    builder: (_) => TrainingActionLogDialog(actions: actions),
  );
}
