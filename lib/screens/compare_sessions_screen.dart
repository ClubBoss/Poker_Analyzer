import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/saved_hand.dart';
import '../services/saved_hand_manager_service.dart';
import '../services/session_note_service.dart';
import '../widgets/sync_status_widget.dart';

class CompareSessionsScreen extends StatelessWidget {
  final int firstId;
  final int secondId;

  const CompareSessionsScreen({super.key, required this.firstId, required this.secondId});

  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    final parts = <String>[];
    if (hours > 0) parts.add('${hours}ч');
    parts.add('${minutes}м');
    return parts.join(' ');
  }

  _SessionStats _statsFor(int id, Map<int, List<SavedHand>> grouped, SessionNoteService notes) {
    final hands = List<SavedHand>.from(grouped[id] ?? [])
      ..sort((a, b) => a.savedAt.compareTo(b.savedAt));
    if (hands.isEmpty) {
      return _SessionStats.empty(id);
    }
    final start = hands.first.savedAt;
    final end = hands.last.savedAt;
    final duration = end.difference(start);
    int correct = 0;
    int incorrect = 0;
    for (final h in hands) {
      final expected = h.expectedAction;
      final gto = h.gtoAction;
      if (expected != null && gto != null) {
        if (expected.trim().toLowerCase() == gto.trim().toLowerCase()) {
          correct++;
        } else {
          incorrect++;
        }
      }
    }
    final total = correct + incorrect;
    final winrate = total > 0 ? (correct / total * 100) : null;
    final note = notes.noteFor(id);
    return _SessionStats(
      id: id,
      duration: duration,
      hands: hands.length,
      correct: correct,
      incorrect: incorrect,
      accuracy: winrate,
      note: note,
    );
  }

  Widget _buildRow(String label, String left, String right) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(label, style: const TextStyle(color: Colors.white70)),
          ),
          Expanded(
            child: Text(left, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white)),
          ),
          Expanded(
            child: Text(right, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final manager = context.watch<SavedHandManagerService>();
    final notes = context.watch<SessionNoteService>();
    final grouped = manager.handsBySession();
    final first = _statsFor(firstId, grouped, notes);
    final second = _statsFor(secondId, grouped, notes);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Сравнение сессий'),
        centerTitle: true,
        actions: [SyncStatusIcon.of(context)],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(child: SizedBox()),
                Expanded(
                  child: Text('Сессия ${first.id}', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white)),
                ),
                Expanded(
                  child: Text('Сессия ${second.id}', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildRow('Раздач', first.hands.toString(), second.hands.toString()),
            _buildRow('Длительность', _formatDuration(first.duration), _formatDuration(second.duration)),
            _buildRow(
              'Точность',
              first.accuracy != null ? '${first.accuracy!.toStringAsFixed(1)}%' : '-',
              second.accuracy != null ? '${second.accuracy!.toStringAsFixed(1)}%' : '-',
            ),
            _buildRow('Ошибки', first.incorrect.toString(), second.incorrect.toString()),
            _buildRow('Заметка', first.note.isNotEmpty ? first.note : '-', second.note.isNotEmpty ? second.note : '-'),
          ],
        ),
      ),
    );
  }
}

class _SessionStats {
  final int id;
  final Duration duration;
  final int hands;
  final int correct;
  final int incorrect;
  final double? accuracy;
  final String note;

  const _SessionStats({
    required this.id,
    required this.duration,
    required this.hands,
    required this.correct,
    required this.incorrect,
    required this.accuracy,
    required this.note,
  });

  factory _SessionStats.empty(int id) => _SessionStats(
        id: id,
        duration: Duration.zero,
        hands: 0,
        correct: 0,
        incorrect: 0,
        accuracy: null,
        note: '',
      );
}
