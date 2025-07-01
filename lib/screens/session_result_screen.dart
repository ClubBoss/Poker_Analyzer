import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../services/training_session_service.dart';
import '../widgets/training_action_log_dialog.dart';
import '../widgets/spot_viewer_dialog.dart';
import '../widgets/common/action_accuracy_chart.dart';
import '../theme/app_colors.dart';
import '../widgets/player_note_button.dart';
import '../models/v2/training_pack_template.dart';
import 'training_session_screen.dart';
import 'package:uuid/uuid.dart';

class SessionResultScreen extends StatefulWidget {
  final int total;
  final int correct;
  final Duration elapsed;
  final bool authorPreview;
  const SessionResultScreen({
    super.key,
    required this.total,
    required this.correct,
    required this.elapsed,
    this.authorPreview = false,
  });

  @override
  State<SessionResultScreen> createState() => _SessionResultScreenState();
}

class _SessionResultScreenState extends State<SessionResultScreen> {

  Future<void> _retryMistakes() async {
    final service = context.read<TrainingSessionService>();
    final missed = service.actionLog
        .where((e) => !e.isCorrect)
        .map((e) => e.spotId)
        .toSet();
    if (missed.isEmpty) return;
    final spots = service.spots.where((s) => missed.contains(s.id)).toList();
    if (spots.isEmpty) return;
    final t = TrainingPackTemplate(
      id: const Uuid().v4(),
      name: 'Retry mistakes',
      spots: spots,
    );
    await service.startSession(t);
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const TrainingSessionScreen()),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final actions = context.read<TrainingSessionService>().actionLog;
      if (actions.isNotEmpty) {
        showTrainingActionLogDialog(context, actions);
      }
    });
  }

  String _format(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  Future<void> _editSpotNote(TrainingPackSpot spot) async {
    final c = TextEditingController(text: spot.note);
    final res = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.black.withOpacity(0.8),
        title: const Text('Note', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: c,
          autofocus: true,
          maxLines: 3,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white10,
            hintText: 'Enter notes',
            hintStyle: const TextStyle(color: Colors.white54),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, c.text), child: const Text('Save')),
        ],
      ),
    );
    if (res != null) {
      final updated =
          spot.copyWith(note: res.trim(), editedAt: DateTime.now());
      await context.read<TrainingSessionService>().updateSpot(updated);
    }
  }

  @override
  Widget build(BuildContext context) {
    final rate = widget.total == 0 ? 0 : widget.correct * 100 / widget.total;
    final service = context.watch<TrainingSessionService>();
    final actions = service.actionLog;
    return Scaffold(
      appBar: AppBar(title: const Text('Session Result')),
      backgroundColor: const Color(0xFF1B1C1E),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('${widget.correct} / ${widget.total}',
                      style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('Accuracy: ${rate.toStringAsFixed(1)}%',
                      style: const TextStyle(color: Colors.white70)),
                  const SizedBox(height: 8),
                  Text('Time: ${_format(widget.elapsed)}',
                      style: const TextStyle(color: Colors.white70)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ActionAccuracyChart(actions: actions),
            const SizedBox(height: 16),
            Expanded(
              child: actions.isEmpty
                  ? const Center(
                      child: Text('No actions recorded', style: TextStyle(color: Colors.white70)),
                    )
                  : ListView.builder(
                      itemCount: actions.length,
                      itemBuilder: (context, index) {
                        final a = actions[index];
                        final color = a.isCorrect ? AppColors.cardBackground : AppColors.errorBg;
                        final time = DateFormat('HH:mm:ss', Intl.getCurrentLocale()).format(a.timestamp);
                        TrainingPackSpot? spot;
                        try {
                          spot = service.spots.firstWhere((s) => s.id == a.spotId);
                        } catch (_) {}
                        if (spot == null) return const SizedBox.shrink();
                        return InkWell(
                          onTap: () {
                            showSpotViewerDialog(context, spot);
                          },
                          child: Container(
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
                                const SizedBox(width: 8),
                                PlayerNoteButton(
                                  note: spot.note,
                                  onPressed: () => _editSpotNote(spot),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton(
                    onPressed: _retryMistakes,
                    child: const Text('Retry mistakes'),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => widget.authorPreview
                        ? Navigator.pop(context)
                        : Navigator.of(context).popUntil((r) => r.isFirst),
                    child: const Text('Done'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
