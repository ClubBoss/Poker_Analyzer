import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/v2/training_action.dart';
import '../services/training_session_service.dart';
import '../widgets/player_note_button.dart';
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
            ? const Center(
                child: Text(
                  'No actions',
                  style: TextStyle(color: Colors.white70),
                ),
              )
            : ListView.builder(
                itemCount: actions.length,
                itemBuilder: (context, index) {
                  final a = actions[index];
                  final color = a.isCorrect
                      ? AppColors.cardBackground
                      : AppColors.errorBg;
                  final time = DateFormat(
                    'HH:mm:ss',
                    Intl.getCurrentLocale(),
                  ).format(a.timestamp);
                  TrainingPackSpot? spot;
                  try {
                    spot = context
                        .read<TrainingSessionService>()
                        .spots
                        .firstWhere((s) => s.id == a.spotId);
                  } catch (_) {}
                  if (spot == null) return const SizedBox.shrink();
                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Text(
                          '${index + 1}',
                          style: const TextStyle(color: Colors.white),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            a.chosenAction,
                            style: TextStyle(
                              color: a.isCorrect ? Colors.white : Colors.red,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          a.isCorrect ? Icons.check : Icons.close,
                          color: a.isCorrect ? Colors.green : Colors.red,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          time,
                          style: const TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(width: 8),
                        PlayerNoteButton(
                          note: spot.note,
                          onPressed: () async {
                            final res = await showDialog<String>(
                              context: context,
                              builder: (ctx) {
                                final c = TextEditingController(
                                  text: spot!.note,
                                );
                                return AlertDialog(
                                  backgroundColor: Colors.black.withValues(
                                    alpha: 0.8,
                                  ),
                                  title: const Text(
                                    'Note',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  content: TextField(
                                    controller: c,
                                    autofocus: true,
                                    maxLines: 3,
                                    style: const TextStyle(color: Colors.white),
                                    decoration: InputDecoration(
                                      filled: true,
                                      fillColor: Colors.white10,
                                      hintText: 'Enter notes',
                                      hintStyle: const TextStyle(
                                        color: Colors.white54,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(ctx, c.text),
                                      child: const Text('Save'),
                                    ),
                                  ],
                                );
                              },
                            );
                            if (res != null) {
                              final updated = spot!.copyWith(
                                note: res.trim(),
                                editedAt: DateTime.now(),
                              );
                              await context
                                  .read<TrainingSessionService>()
                                  .updateSpot(updated);
                            }
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

Future<void> showTrainingActionLogDialog(
  BuildContext context,
  List<TrainingAction> actions,
) {
  return showDialog(
    context: context,
    builder: (_) => TrainingActionLogDialog(actions: actions),
  );
}
